// lib/services/websocket_student_service.dart
// 🔔 SERVICIO WEBSOCKET PARA NOTIFICACIONES A ESTUDIANTES
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../services/notifications/notification_manager.dart';
import '../services/storage_service.dart';
import '../models/student_notification_model.dart';
import 'notifications/student_notification_types.dart';
import '../utils/connectivity_manager.dart';

/// Estado de conexión WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

/// Servicio WebSocket especializado para estudiantes recibir notificaciones de eventos
class WebSocketStudentService {
  static final WebSocketStudentService _instance =
      WebSocketStudentService._internal();
  factory WebSocketStudentService() => _instance;
  WebSocketStudentService._internal();

  // 🎯 PROPIEDADES DEL WEBSOCKET
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<StudentNotification> _notificationController =
      StreamController<StudentNotification>.broadcast();
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();

  // 🎯 ESTADO DE CONEXIÓN
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  bool _isConnecting = false;
  String? _currentEventId;
  String? _currentUserId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);

  // 🎯 SERVICIOS
  late NotificationManager _notificationManager;
  final StorageService _storageService = StorageService();
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  // 🎯 TIMERS
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;

  // 🎯 CONFIGURACIÓN
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const String _wsBaseUrl = 'ws://44.211.171.188';

  /// Stream público para escuchar notificaciones
  Stream<StudentNotification> get notificationStream =>
      _notificationController.stream;

  /// Stream para el estado de conexión
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Estado actual de conexión
  WebSocketConnectionState get connectionState => _connectionState;

  /// Verificar si está conectado
  bool get isConnected =>
      _connectionState == WebSocketConnectionState.connected;

  /// Obtener evento actual
  String? get currentEventId => _currentEventId;

  /// Obtener usuario actual
  String? get currentUserId => _currentUserId;

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      debugPrint('🚀 Inicializando WebSocketStudentService');

      _notificationManager = NotificationManager();
      await _notificationManager.initialize();

      debugPrint('✅ WebSocketStudentService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando WebSocketStudentService: $e');
      rethrow;
    }
  }

  /// Conectar a WebSocket para un evento específico
  Future<void> connectToEvent({
    required String eventId,
    required String userId,
  }) async {
    if (_isConnecting) {
      debugPrint('⏳ Ya se está conectando al WebSocket');
      return;
    }

    debugPrint('🔌 Conectando a WebSocket para evento: $eventId');

    _currentEventId = eventId;
    _currentUserId = userId;
    _reconnectAttempts = 0;

    await _connect();
  }

  /// Desconectar del WebSocket
  Future<void> disconnect() async {
    debugPrint('🔌 Desconectando WebSocket');

    _cancelTimers();
    await _closeConnection();

    _currentEventId = null;
    _currentUserId = null;
    _reconnectAttempts = 0;

    _updateConnectionState(WebSocketConnectionState.disconnected);

    debugPrint('✅ WebSocket desconectado');
  }

  /// Conectar al WebSocket
  Future<void> _connect() async {
    if (_isConnecting) return;

    try {
      _isConnecting = true;
      _updateConnectionState(WebSocketConnectionState.connecting);

      // Configurar timeout de conexión
      _connectionTimeoutTimer = Timer(_connectionTimeout, () {
        debugPrint('⏰ Timeout de conexión WebSocket');
        _handleConnectionTimeout();
      });

      // Obtener token de autenticación
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Construir URL con parámetros
      final wsUrl =
          '$_wsBaseUrl?token=$token&eventId=$_currentEventId&userId=$_currentUserId&type=student';
      debugPrint('📡 Conectando a: $wsUrl');

      // Crear conexión WebSocket
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Configurar listener de mensajes
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );

      // Enviar mensaje de autenticación/suscripción
      await _sendSubscriptionMessage();

      // Cancelar timeout si la conexión es exitosa
      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = null;

      _updateConnectionState(WebSocketConnectionState.connected);
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Iniciar heartbeat
      _startHeartbeat();

      debugPrint('✅ WebSocket conectado exitosamente');

      // Enviar notificación de conexión exitosa
      _emitLocalNotification(
        StudentNotificationFactory.trackingActive(
          eventTitle: 'Evento $_currentEventId',
          eventId: _currentEventId!,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error conectando WebSocket: $e');
      _isConnecting = false;
      _connectionTimeoutTimer?.cancel();
      _updateConnectionState(WebSocketConnectionState.error);
      await _handleConnectionError(e);
    }
  }

  /// Enviar mensaje de suscripción al evento
  Future<void> _sendSubscriptionMessage() async {
    try {
      final subscriptionMessage = {
        'action': 'subscribe_student',
        'eventId': _currentEventId,
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'flutter',
        'version': '1.0.0',
      };

      _channel?.sink.add(jsonEncode(subscriptionMessage));
      debugPrint('📤 Mensaje de suscripción enviado');
    } catch (e) {
      debugPrint('❌ Error enviando suscripción: $e');
      rethrow;
    }
  }

  /// Manejar mensajes recibidos del WebSocket
  void _handleMessage(dynamic message) {
    try {
      debugPrint('📨 Mensaje WebSocket recibido: $message');

      final data = jsonDecode(message as String);
      final messageType = data['type'] as String?;

      switch (messageType) {
        case 'event_started':
          _handleEventStarted(data);
          break;
        case 'break_started':
          _handleBreakStarted(data);
          break;
        case 'break_ended':
          _handleBreakEnded(data);
          break;
        case 'event_finalized':
          _handleEventFinalized(data);
          break;
        case 'professor_announcement':
          _handleProfessorAnnouncement(data);
          break;
        case 'event_updated':
          _handleEventUpdated(data);
          break;
        case 'connection_ack':
          _handleConnectionAck(data);
          break;
        case 'heartbeat_response':
          _handleHeartbeatResponse(data);
          break;
        case 'error':
          _handleServerError(data);
          break;
        default:
          debugPrint('📋 Tipo de mensaje no manejado: $messageType');
      }
    } catch (e) {
      debugPrint('❌ Error procesando mensaje WebSocket: $e');
    }
  }

  /// Manejar evento iniciado
  void _handleEventStarted(Map<String, dynamic> data) {
    debugPrint('🎯 Evento iniciado recibido');

    final notification = StudentNotificationFactory.eventStarted(
      eventTitle: data['eventTitle'] as String? ?? 'Evento',
      eventId: data['eventId'] as String? ?? _currentEventId!,
      professorName: data['professorName'] as String?,
    );

    _emitLocalNotification(notification);
  }

  /// Manejar receso iniciado
  void _handleBreakStarted(Map<String, dynamic> data) {
    debugPrint('⏸️ Receso iniciado recibido');

    final notification = StudentNotificationFactory.breakStarted(
      eventTitle: data['eventTitle'] as String? ?? 'Evento',
      eventId: data['eventId'] as String? ?? _currentEventId!,
      breakDurationMinutes: data['breakDurationMinutes'] as int?,
    );

    _emitLocalNotification(notification);
  }

  /// Manejar receso terminado
  void _handleBreakEnded(Map<String, dynamic> data) {
    debugPrint('▶️ Receso terminado recibido');

    final notification = StudentNotificationFactory.breakEnded(
      eventTitle: data['eventTitle'] as String? ?? 'Evento',
      eventId: data['eventId'] as String? ?? _currentEventId!,
    );

    _emitLocalNotification(notification);
  }

  /// Manejar evento finalizado
  void _handleEventFinalized(Map<String, dynamic> data) {
    debugPrint('🏁 Evento finalizado recibido');

    final notification = StudentNotificationFactory.eventFinalized(
      eventTitle: data['eventTitle'] as String? ?? 'Evento',
      eventId: data['eventId'] as String? ?? _currentEventId!,
      attendanceRegistered: data['attendanceRegistered'] as bool? ?? false,
    );

    _emitLocalNotification(notification);

    // Desconectar automáticamente cuando el evento termine
    Timer(const Duration(seconds: 5), () async {
      await disconnect();
    });
  }

  /// Manejar anuncio del profesor
  void _handleProfessorAnnouncement(Map<String, dynamic> data) {
    debugPrint('📢 Anuncio del profesor recibido');

    final notification = StudentNotificationFactory.professorAnnouncement(
      message: data['message'] as String? ?? 'Sin mensaje',
      eventTitle: data['eventTitle'] as String? ?? 'Evento',
      eventId: data['eventId'] as String? ?? _currentEventId!,
      professorName: data['professorName'] as String?,
    );

    _emitLocalNotification(notification);
  }

  /// Manejar evento actualizado
  void _handleEventUpdated(Map<String, dynamic> data) {
    debugPrint('🔄 Evento actualizado recibido');

    final notification = StudentNotificationFactory.eventUpdated(
      eventTitle: data['eventTitle'] as String? ?? 'Evento',
      eventId: data['eventId'] as String? ?? _currentEventId!,
      updateType: data['updateType'] as String? ?? 'details',
    );

    _emitLocalNotification(notification);
  }

  /// Manejar confirmación de conexión
  void _handleConnectionAck(Map<String, dynamic> data) {
    debugPrint('✅ Confirmación de conexión recibida');

    final eventTitle = data['eventTitle'] as String?;
    if (eventTitle != null) {
      final notification = StudentNotificationFactory.joinedEvent(
        eventTitle: eventTitle,
        eventId: _currentEventId!,
      );
      _emitLocalNotification(notification);
    }
  }

  /// Manejar respuesta de heartbeat
  void _handleHeartbeatResponse(Map<String, dynamic> data) {
    debugPrint('💓 Heartbeat response recibido');
    // Heartbeat confirmado - conexión saludable
  }

  /// Manejar error del servidor
  void _handleServerError(Map<String, dynamic> data) {
    final errorMessage = data['message'] as String? ?? 'Error del servidor';
    debugPrint('❌ Error del servidor: $errorMessage');

    final notification = StudentNotificationFactory.connectivityLost(
      eventTitle: 'Evento $_currentEventId',
      eventId: _currentEventId,
    );

    _emitLocalNotification(notification);
  }

  /// Emitir notificación local
  void _emitLocalNotification(StudentNotification notification) {
    // Enviar al stream para listeners
    _notificationController.add(notification);

    // Mostrar notificación local del sistema
    _notificationManager.showStudentNotification(notification);

    // Ejecutar vibración
    StudentNotificationVibration.vibrateForNotification(notification);
  }

  /// Manejar error de conexión
  Future<void> _handleError(dynamic error) async {
    debugPrint('❌ Error en WebSocket: $error');
    _updateConnectionState(WebSocketConnectionState.error);

    // ✅ FIXED: Verificar internet real antes de mostrar error de conectividad
    final hasInternet = await _connectivityManager.hasInternetAccess();
    
    if (hasInternet) {
      // Internet OK - problema del servidor WebSocket
      debugPrint('🌐 Internet OK - problema del servidor WebSocket, no mostrando error de conectividad');
      // No mostrar notificación de conectividad cuando el problema es del servidor
    } else {
      // Sin internet real - mostrar notificación de conectividad
      debugPrint('❌ Sin internet real - mostrando error de conectividad');
      final notification = StudentNotificationFactory.connectivityLost(
        eventTitle: 'Evento $_currentEventId',
        eventId: _currentEventId,
      );
      _emitLocalNotification(notification);
    }

    _scheduleReconnect();
  }

  /// Manejar desconexión
  void _handleDisconnection() {
    debugPrint('🔌 WebSocket desconectado');

    if (_connectionState != WebSocketConnectionState.disconnected) {
      _updateConnectionState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Manejar timeout de conexión
  void _handleConnectionTimeout() {
    debugPrint('⏰ Timeout de conexión WebSocket');
    _isConnecting = false;
    _updateConnectionState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  /// Manejar error de conexión
  Future<void> _handleConnectionError(dynamic error) async {
    debugPrint('❌ Error de conexión: $error');

    // ✅ FIXED: Verificar internet real antes de mostrar error de conectividad
    final hasInternet = await _connectivityManager.hasInternetAccess();
    
    if (!hasInternet) {
      // Solo mostrar error de conectividad si realmente no hay internet
      final notification = StudentNotificationFactory.connectivityLost(
        eventTitle: 'Evento $_currentEventId',
        eventId: _currentEventId,
        retryAttempts: _reconnectAttempts + 1,
      );
      _emitLocalNotification(notification);
    } else {
      debugPrint('🌐 Internet OK - problema del servidor, no mostrando error de conectividad');
    }

    _scheduleReconnect();
  }

  /// Programar reconexión automática
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Máximo de intentos de reconexión alcanzado');
      _updateConnectionState(WebSocketConnectionState.error);
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: _baseReconnectDelay.inSeconds * _reconnectAttempts,
    );

    debugPrint(
        '🔄 Programando reconexión en ${delay.inSeconds}s (intento $_reconnectAttempts)');
    _updateConnectionState(WebSocketConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () async {
      if (_currentEventId != null && _currentUserId != null) {
        await _connect();
      }
    });
  }

  /// Iniciar heartbeat periódico
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }

  /// Enviar heartbeat
  void _sendHeartbeat() {
    try {
      if (!isConnected) return;

      final heartbeatMessage = {
        'action': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
        'eventId': _currentEventId,
        'userId': _currentUserId,
      };

      _channel?.sink.add(jsonEncode(heartbeatMessage));
      debugPrint('💓 Heartbeat enviado');
    } catch (e) {
      debugPrint('❌ Error enviando heartbeat: $e');
    }
  }

  /// Actualizar estado de conexión
  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      debugPrint('🔄 Estado WebSocket: $newState');
    }
  }

  /// Cerrar conexión
  Future<void> _closeConnection() async {
    try {
      _subscription?.cancel();
      await _channel?.sink.close(status.normalClosure);
    } catch (e) {
      debugPrint('❌ Error cerrando conexión: $e');
    } finally {
      _subscription = null;
      _channel = null;
    }
  }

  /// Cancelar timers
  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _connectionTimeoutTimer?.cancel();

    _reconnectTimer = null;
    _heartbeatTimer = null;
    _connectionTimeoutTimer = null;
  }

  /// Enviar mensaje personalizado (para acciones del estudiante)
  Future<bool> sendStudentAction({
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!isConnected) {
        debugPrint('⚠️ No conectado - no se puede enviar acción');
        return false;
      }

      final message = {
        'action': action,
        'eventId': _currentEventId,
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      };

      _channel?.sink.add(jsonEncode(message));
      debugPrint('📤 Acción enviada: $action');
      return true;
    } catch (e) {
      debugPrint('❌ Error enviando acción: $e');
      return false;
    }
  }

  /// Forzar reconexión manual
  Future<void> forceReconnect() async {
    debugPrint('🔄 Forzando reconexión manual');

    await _closeConnection();
    _reconnectAttempts = 0;

    if (_currentEventId != null && _currentUserId != null) {
      await _connect();
    }
  }

  /// Obtener información de estado
  Map<String, dynamic> getConnectionInfo() {
    return {
      'state': _connectionState.toString(),
      'isConnected': isConnected,
      'currentEventId': _currentEventId,
      'currentUserId': _currentUserId,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
    };
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    debugPrint('🧹 Limpiando WebSocketStudentService');

    _cancelTimers();
    await _closeConnection();

    await _notificationController.close();
    await _connectionStateController.close();

    _currentEventId = null;
    _currentUserId = null;
    _reconnectAttempts = 0;

    debugPrint('✅ WebSocketStudentService limpiado');
  }
}
