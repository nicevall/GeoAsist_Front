// lib/services/websocket_service.dart
// ✅ WEBSOCKET ROBUSTO CON HEARTBEAT Y FILTRADO DE MENSAJES
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../core/app_constants.dart';
import 'storage_service.dart';
import 'notifications/notification_manager.dart';

/// Estado de conexión WebSocket robusto
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
  heartbeatMissing
}

/// Servicio WebSocket unificado y robusto
class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._internal();
  
  WebSocketChannel? _wsChannel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _heartbeatTimer;
  Timer? _heartbeatResponseTimer;
  Timer? _reconnectTimer;
  
  // ✅ ESTADO DE CONEXIÓN ROBUSTO
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentEventId;
  String? _currentUserId;
  String? _currentUserRole;
  DateTime? _lastHeartbeat;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration heartbeatTimeout = Duration(seconds: 60);
  
  // ✅ SERVICIOS
  final StorageService _storageService = StorageService();
  final NotificationManager _notificationManager = NotificationManager();
  
  // ✅ FILTRADO Y CONTROL DE DUPLICADAS
  final Set<String> _processedMessages = <String>{};
  Timer? _messageCleanupTimer;
  
  WebSocketService._internal();
  
  /// Stream público para mensajes WebSocket
  Stream<Map<String, dynamic>> get messageStream =>
      _messageController?.stream ?? const Stream.empty();
  
  /// Estado actual de conexión
  WebSocketConnectionState get connectionState {
    if (!_isConnected && _isConnecting) return WebSocketConnectionState.connecting;
    if (!_isConnected && _reconnectAttempts > 0) return WebSocketConnectionState.reconnecting;
    if (_isConnected && _lastHeartbeat != null &&
        DateTime.now().difference(_lastHeartbeat!).inSeconds > 90) {
      return WebSocketConnectionState.heartbeatMissing;
    }
    if (_isConnected) return WebSocketConnectionState.connected;
    if (_reconnectAttempts >= maxReconnectAttempts) return WebSocketConnectionState.error;
    return WebSocketConnectionState.disconnected;
  }
  
  /// ✅ CONEXIÓN CON VALIDACIÓN Y FILTRADO
  // Simple connect method for compatibility
  Future<bool> connect() async {
    // Default connection attempt - requires currentEventId and currentUserId to be set
    if (_currentEventId != null && _currentUserId != null) {
      return await connectToEvent(
        eventId: _currentEventId!,
        userId: _currentUserId!,
        userRole: _currentUserRole,
      );
    }
    debugPrint('❌ Cannot connect: eventId or userId not set');
    return false;
  }

  Future<bool> connectToEvent({
    required String eventId,
    required String userId,
    String? userRole,
  }) async {
    if (_isConnecting) {
      debugPrint('⚠️ Ya hay una conexión en progreso');
      return false;
    }
    
    try {
      _isConnecting = true;
      _currentEventId = eventId;
      _currentUserId = userId;
      _currentUserRole = userRole ?? 'student';
      
      debugPrint('🔌 Conectando WebSocket al evento: $eventId');
      debugPrint('👤 Usuario: $userId (rol: $_currentUserRole)');
      
      // Obtener token
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      
      // Construir URL con parámetros específicos
      final wsUrl = '${AppConstants.baseUrlWebSocket}?eventId=$eventId&userId=$userId&role=$_currentUserRole&token=$token';
      
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // ✅ CONFIGURAR LISTENERS CON FILTRADO
      _setupMessageListener();
      _setupErrorHandling();
      
      // ✅ INICIALIZAR CONTROLADOR DE MENSAJES
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      // ✅ INICIAR HEARTBEAT INMEDIATAMENTE
      _startHeartbeat();
      
      // ✅ ENVIAR MENSAJE DE CONEXIÓN
      await _sendConnectionMessage(eventId, userId, _currentUserRole);
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _lastHeartbeat = DateTime.now();
      
      // ✅ INICIAR CLEANUP DE MENSAJES
      _startMessageCleanup();
      
      debugPrint('✅ WebSocket conectado exitosamente');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error conectando WebSocket: $e');
      _isConnecting = false;
      _isConnected = false;
      _scheduleReconnect();
      return false;
    }
  }
  
  void _setupMessageListener() {
    _wsChannel?.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          _lastHeartbeat = DateTime.now();
          
          // ✅ FILTRAR MENSAJES POR EVENTO Y USUARIO
          if (_shouldProcessMessage(data)) {
            _processIncomingMessage(data);
            _messageController?.add(data);
          }
          
        } catch (e) {
          debugPrint('❌ Error procesando mensaje WebSocket: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ WebSocket error: $error');
        _handleConnectionError();
      },
      onDone: () {
        debugPrint('📪 WebSocket conexión cerrada');
        _handleConnectionClosed();
      },
    );
  }
  
  void _setupErrorHandling() {
    // Configurar manejo de errores adicional si es necesario
  }
  
  /// ✅ FILTRADO DE MENSAJES ESPECÍFICO
  bool _shouldProcessMessage(Map<String, dynamic> data) {
    final messageEventId = data['eventId'] as String?;
    final messageUserId = data['userId'] as String?;
    final messageType = data['type'] as String?;
    final messageId = data['id'] as String? ?? '${messageType}_${DateTime.now().millisecondsSinceEpoch}';
    
    // ✅ EVITAR DUPLICADAS
    if (_processedMessages.contains(messageId)) {
      debugPrint('⚠️ Mensaje duplicado evitado: $messageId');
      return false;
    }
    _processedMessages.add(messageId);
    
    // Mensajes globales (siempre procesar)
    // ⚠️ Solo procesar mensajes que el backend soporta
    if (['event-status', 'error'].contains(messageType)) {
      return true;
    }
    
    // Mensajes específicos del evento
    if (messageEventId != null && messageEventId != _currentEventId) {
      debugPrint('⚠️ Mensaje para evento diferente: $messageEventId vs $_currentEventId');
      return false;
    }
    
    // Mensajes específicos del usuario (opcional)
    if (messageUserId != null && messageUserId != _currentUserId) {
      // Algunos mensajes son para otros usuarios (ej: actualizaciones de asistencia)
      // Solo filtrar si es un mensaje personal
      if (['personal_notification', 'private_message'].contains(messageType)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// ⚠️ HEARTBEAT COMPLETAMENTE DESHABILITADO
  void _startHeartbeat() {
    // ⚠️ Backend solo maneja 'change-event-status', no heartbeat
    debugPrint('⚠️ WebSocket Heartbeat DISABLED - Backend no compatible');
    // No iniciar timer - backend no soporta heartbeats
  }
  
  // Unused method _checkHeartbeatResponse removed
  
  void _processIncomingMessage(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    debugPrint('📨 Procesando mensaje: $messageType');
    
    switch (messageType) {
      case 'connection_established':
        debugPrint('✅ Conexión WebSocket establecida');
        break;
        
      case 'attendance_update':
        _handleAttendanceUpdate(data);
        break;
        
      case 'event-status':
        _handleEventStatusChanged(data);
        break;
        
      case 'geofence_violation':
        _handleGeofenceViolation(data);
        break;
        
      case 'heartbeat_response':
        _lastHeartbeat = DateTime.now();
        debugPrint('💓 Heartbeat response recibido');
        break;
        
      case 'student_joined':
        _handleStudentJoined(data);
        break;
        
      case 'student_location_update':
        _handleLocationUpdate(data);
        break;
        
      case 'metrics_update':
        _handleMetricsUpdate(data);
        break;
        
      case 'grace_period_started':
        _handleGracePeriodStarted(data);
        break;
        
      case 'forced_attendance_check':
        _handleForcedAttendanceCheck(data);
        break;
        
      case 'error':
        _handleServerError(data);
        break;
        
      default:
        debugPrint('📋 Mensaje no manejado: $messageType');
    }
  }
  
  /// ✅ MANEJO ESPECÍFICO DE MENSAJES
  void _handleAttendanceUpdate(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    final attendanceStatus = data['attendanceStatus'] as String? ?? 'presente';
    final timestamp = data['timestamp'] as String?;
    
    debugPrint('📝 Actualización de asistencia: $studentName -> $attendanceStatus (${timestamp ?? 'now'})');
    
    // Mostrar notificación para profesores
    if (_currentUserRole == 'teacher' || _currentUserRole == 'admin') {
      _notificationManager.showAttendanceRegisteredNotification(
        eventName: data['eventName'] as String?,
        status: attendanceStatus,
      );
    }
  }
  
  void _handleEventStatusChanged(Map<String, dynamic> data) {
    // ✅ CORREGIDO: Usar los campos que el backend realmente envía
    final newStatus = data['estado'] as String? ?? 'unknown';
    final eventId = data['evento'] as String?;
    
    debugPrint('📢 Estado de evento cambiado: ID $eventId -> $newStatus');
    
    // ✅ LÓGICA AUTOMÁTICA DE ASISTENCIA SEGÚN ESTADO
    switch (newStatus) {
      case 'En proceso':
        debugPrint('🟢 Evento iniciado automáticamente - Estudiantes pueden registrar asistencia');
        _notificationManager.showEventStartedNotification('El evento ha iniciado');
        break;
      case 'finalizado':
        debugPrint('🔴 Evento finalizado automáticamente - No más asistencias');
        _notificationManager.showEventEndedNotification('El evento ha finalizado');
        break;
      case 'En espera':
        debugPrint('⏸️ Evento pausado - Continuará mañana');
        break;
    }
    
    _notificationManager.showEventStatusChangedNotification(
      eventName: 'Evento ID: $eventId',
      newStatus: newStatus,
    );
  }
  
  void _handleGeofenceViolation(Map<String, dynamic> data) {
    final gracePeriodSeconds = data['gracePeriodSeconds'] as int? ?? 60;
    final eventName = data['eventName'] as String?;
    
    debugPrint('⚠️ Violación de geofence: $gracePeriodSeconds segundos de gracia');
    
    _notificationManager.showGeofenceViolationNotification(
      gracePeriodSeconds: gracePeriodSeconds,
      eventName: eventName,
    );
  }
  
  void _handleStudentJoined(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    debugPrint('👋 Estudiante se unió: $studentName');
  }
  
  void _handleLocationUpdate(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;
    
    debugPrint('📍 Actualización de ubicación: $studentName ($latitude, $longitude)');
  }
  
  void _handleMetricsUpdate(Map<String, dynamic> data) {
    final totalStudents = data['totalStudents'] as int? ?? 0;
    final presentStudents = data['presentStudents'] as int? ?? 0;
    
    debugPrint('📊 Métricas actualizadas: $presentStudents/$totalStudents estudiantes');
  }
  
  void _handleGracePeriodStarted(Map<String, dynamic> data) {
    final gracePeriodSeconds = data['gracePeriodSeconds'] as int? ?? 60;
    debugPrint('⏰ Período de gracia iniciado: ${gracePeriodSeconds}s');
  }
  
  void _handleForcedAttendanceCheck(Map<String, dynamic> data) {
    debugPrint('🔍 Verificación forzada de asistencia solicitada');
  }
  
  void _handleServerError(Map<String, dynamic> data) {
    final errorMessage = data['message'] as String? ?? 'Error del servidor';
    debugPrint('❌ Error del servidor: $errorMessage');
    
    _notificationManager.showConnectionErrorNotification();
  }
  
  /// ✅ MANEJO DE RECONEXIÓN ROBUSTO
  void _handleConnectionError() {
    _isConnected = false;
    _stopHeartbeat();
    
    if (_reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      debugPrint('❌ Máximo de reconexiones alcanzado');
      _notifyConnectionFailed();
    }
  }
  
  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: math.pow(2, _reconnectAttempts).toInt().clamp(1, 30));
    
    debugPrint('🔄 Reintentando conexión en ${delay.inSeconds}s (intento $_reconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_currentEventId != null && _currentUserId != null) {
        connectToEvent(
          eventId: _currentEventId!,
          userId: _currentUserId!,
          userRole: _currentUserRole,
        );
      }
    });
  }
  
  void _handleConnectionClosed() {
    debugPrint('📪 Conexión WebSocket cerrada');
    if (_isConnected) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }
  
  void _notifyConnectionFailed() {
    debugPrint('❌ Conexión WebSocket falló definitivamente');
    _notificationManager.showConnectionErrorNotification();
  }
  
  /// ✅ ENVIAR MENSAJES CON VALIDACIÓN
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _wsChannel == null) {
      debugPrint('⚠️ No conectado - mensaje no enviado: ${message['type']}');
      return false;
    }
    
    try {
      // Agregar metadatos
      message['timestamp'] = DateTime.now().toIso8601String();
      message['eventId'] = _currentEventId;
      message['userId'] = _currentUserId;
      message['id'] = message['id'] ?? '${message['type']}_${DateTime.now().millisecondsSinceEpoch}';
      
      _wsChannel!.sink.add(jsonEncode(message));
      debugPrint('📤 Mensaje enviado: ${message['type']}');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error enviando mensaje: $e');
      return false;
    }
  }
  
  /// ✅ MENSAJES DE CONEXIÓN
  Future<void> _sendConnectionMessage(String eventId, String userId, String? userRole) async {
    final connectionMessage = {
      'type': 'connection_request',
      'action': 'join_event',
      'eventId': eventId,
      'userId': userId,
      'userRole': userRole ?? 'student',
      'platform': 'flutter',
      'version': '1.0.0',
    };
    
    await sendMessage(connectionMessage);
  }
  
  /// ✅ CLEANUP Y GESTIÓN DE RECURSOS
  void _startMessageCleanup() {
    _messageCleanupTimer?.cancel();
    _messageCleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _processedMessages.clear();
      debugPrint('🧹 Cache de mensajes limpiado');
    });
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatResponseTimer?.cancel();
    _heartbeatTimer = null;
    _heartbeatResponseTimer = null;
  }
  
  /// ✅ DESCONEXIÓN LIMPIA
  Future<void> disconnect() async {
    debugPrint('🔌 Desconectando WebSocket');
    
    _isConnected = false;
    _stopHeartbeat();
    
    _reconnectTimer?.cancel();
    _messageCleanupTimer?.cancel();
    
    if (_wsChannel != null) {
      try {
        await _wsChannel!.sink.close(status.normalClosure);
      } catch (e) {
        debugPrint('❌ Error cerrando WebSocket: $e');
      }
    }
    
    await _messageController?.close();
    _messageController = null;
    _wsChannel = null;
    
    _currentEventId = null;
    _currentUserId = null;
    _currentUserRole = null;
    _reconnectAttempts = 0;
    _processedMessages.clear();
    
    debugPrint('✅ WebSocket desconectado completamente');
  }
  
  /// ✅ INFORMACIÓN DE ESTADO
  Map<String, dynamic> getConnectionInfo() {
    return {
      'state': connectionState.toString(),
      'isConnected': _isConnected,
      'currentEventId': _currentEventId,
      'currentUserId': _currentUserId,
      'currentUserRole': _currentUserRole,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': maxReconnectAttempts,
      'lastHeartbeat': _lastHeartbeat?.toIso8601String(),
      'processedMessages': _processedMessages.length,
    };
  }
  
  /// ✅ FORZAR RECONEXIÓN
  Future<void> forceReconnect() async {
    debugPrint('🔄 Forzando reconexión manual');
    
    await disconnect();
    
    if (_currentEventId != null && _currentUserId != null) {
      await Future.delayed(const Duration(seconds: 1));
      await connectToEvent(
        eventId: _currentEventId!,
        userId: _currentUserId!,
        userRole: _currentUserRole,
      );
    }
  }
}