// lib/services/student_notification_service.dart
// 🔔 SERVICIO ESPECIALIZADO PARA GESTIÓN DE NOTIFICACIONES DE ESTUDIANTES
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_notification_model.dart';
import '../services/websocket_student_service.dart';
import '../services/notifications/notification_manager.dart';
import '../services/notifications/student_notification_types.dart';
import '../services/storage_service.dart';

/// Servicio centralizado para manejar todas las notificaciones de estudiantes
class StudentNotificationService {
  static final StudentNotificationService _instance =
      StudentNotificationService._internal();
  factory StudentNotificationService() => _instance;
  StudentNotificationService._internal();

  // 🎯 SERVICIOS DEPENDIENTES
  final WebSocketStudentService _webSocketService = WebSocketStudentService();
  final NotificationManager _notificationManager = NotificationManager();
  final StorageService _storageService = StorageService();

  // 🎯 ESTADO DEL SERVICIO
  bool _isInitialized = false;
  bool _isListening = false;
  String? _currentEventId;
  String? _currentUserId;

  // 🎯 ALMACENAMIENTO DE NOTIFICACIONES
  final List<StudentNotification> _notifications = [];
  final List<StudentNotification> _activeNotifications = [];
  static const int _maxStoredNotifications = 50;
  static const String _notificationsKey = 'student_notifications';

  // 🎯 CONTROLLERS PARA STREAMS
  final StreamController<List<StudentNotification>> _notificationsController =
      StreamController<List<StudentNotification>>.broadcast();
  final StreamController<StudentNotification> _newNotificationController =
      StreamController<StudentNotification>.broadcast();

  // 🎯 CONFIGURACIÓN
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _persistentNotificationsEnabled = true;

  /// Stream de todas las notificaciones
  Stream<List<StudentNotification>> get notificationsStream =>
      _notificationsController.stream;

  /// Stream de nuevas notificaciones individuales
  Stream<StudentNotification> get newNotificationStream =>
      _newNotificationController.stream;

  /// Lista actual de notificaciones
  List<StudentNotification> get notifications =>
      List.unmodifiable(_notifications);

  /// Lista de notificaciones activas (no leídas)
  List<StudentNotification> get activeNotifications =>
      List.unmodifiable(_activeNotifications);

  /// Cantidad de notificaciones no leídas
  int get unreadCount => _activeNotifications.length;

  /// Verificar si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Verificar si está escuchando WebSocket
  bool get isListening => _isListening;

  /// Evento actual
  String? get currentEventId => _currentEventId;

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Inicializando StudentNotificationService');

      // Inicializar servicios dependientes
      await _webSocketService.initialize();
      await _notificationManager.initialize();

      // Cargar configuración
      await _loadConfiguration();

      // Cargar notificaciones almacenadas
      await _loadStoredNotifications();

      // Configurar listeners
      _setupWebSocketListener();

      _isInitialized = true;
      debugPrint('✅ StudentNotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando StudentNotificationService: $e');
      rethrow;
    }
  }

  /// Comenzar a escuchar notificaciones para un evento
  Future<void> startListeningForEvent({
    required String eventId,
    required String userId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('👂 Iniciando escucha para evento: $eventId');

      _currentEventId = eventId;
      _currentUserId = userId;

      // Conectar WebSocket
      await _webSocketService.connectToEvent(
        eventId: eventId,
        userId: userId,
      );

      _isListening = true;
      debugPrint('✅ Escuchando notificaciones para evento: $eventId');
    } catch (e) {
      debugPrint('❌ Error iniciando escucha: $e');
      rethrow;
    }
  }

  /// Detener escucha de notificaciones
  Future<void> stopListening() async {
    try {
      debugPrint('🛑 Deteniendo escucha de notificaciones');

      await _webSocketService.disconnect();

      _isListening = false;
      _currentEventId = null;
      _currentUserId = null;

      debugPrint('✅ Escucha detenida');
    } catch (e) {
      debugPrint('❌ Error deteniendo escucha: $e');
    }
  }

  /// Configurar listener del WebSocket
  void _setupWebSocketListener() {
    _webSocketService.notificationStream.listen(
      _handleWebSocketNotification,
      onError: (error) {
        debugPrint('❌ Error en stream de notificaciones: $error');
        _handleWebSocketError(error);
      },
    );

    _webSocketService.connectionStateStream.listen(
      _handleConnectionStateChange,
    );
  }

  /// Manejar notificación recibida del WebSocket
  void _handleWebSocketNotification(StudentNotification notification) {
    debugPrint('📨 Notificación recibida: ${notification.type.key}');

    if (!_notificationsEnabled) {
      debugPrint('🔇 Notificaciones deshabilitadas - ignorando');
      return;
    }

    // Agregar a la lista de notificaciones
    _addNotification(notification);

    // Mostrar notificación si está habilitado
    _showNotification(notification);

    // Emitir en stream para listeners
    _newNotificationController.add(notification);

    // Guardar notificaciones actualizadas
    _saveNotifications();
  }

  /// Manejar error del WebSocket
  void _handleWebSocketError(dynamic error) {
    final errorNotification = StudentNotificationFactory.connectivityLost(
      eventTitle: _currentEventId != null ? 'Evento $_currentEventId' : null,
      eventId: _currentEventId,
    );

    _handleWebSocketNotification(errorNotification);
  }

  /// Manejar cambio de estado de conexión
  void _handleConnectionStateChange(WebSocketConnectionState state) {
    debugPrint('🔄 Estado de conexión WebSocket: $state');

    switch (state) {
      case WebSocketConnectionState.connected:
        _removeConnectionErrorNotifications();
        break;
      case WebSocketConnectionState.error:
      case WebSocketConnectionState.disconnected:
        if (_isListening) {
          final errorNotification = StudentNotificationFactory.connectivityLost(
            eventTitle:
                _currentEventId != null ? 'Evento $_currentEventId' : null,
            eventId: _currentEventId,
          );
          _handleWebSocketNotification(errorNotification);
        }
        break;
      case WebSocketConnectionState.reconnecting:
        // No hacer nada especial durante reconexión
        break;
      case WebSocketConnectionState.connecting:
        // No hacer nada especial durante conexión inicial
        break;
    }
  }

  /// Agregar notificación a la lista
  void _addNotification(StudentNotification notification) {
    // Agregar a la lista principal
    _notifications.insert(0, notification);

    // Agregar a activas si no está leída
    if (!notification.isRead) {
      _activeNotifications.insert(0, notification);
    }

    // Mantener límite de notificaciones almacenadas
    if (_notifications.length > _maxStoredNotifications) {
      _notifications.removeRange(
          _maxStoredNotifications, _notifications.length);
    }

    // Emitir lista actualizada
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  /// Mostrar notificación en la UI
  void _showNotification(StudentNotification notification) {
    // Mostrar notificación local del sistema
    _notificationManager.showStudentNotification(notification);

    // Ejecutar vibración si está habilitado
    if (_vibrationEnabled) {
      StudentNotificationVibration.vibrateForNotification(notification);
    }

    // Reproducir sonido si está habilitado
    if (_soundEnabled) {
      StudentNotificationSound.playSound(notification);
    }
  }

  /// Remover notificaciones de error de conexión cuando se reconecta
  void _removeConnectionErrorNotifications() {
    _notifications
        .removeWhere((n) => n.type == StudentNotificationType.connectivityLost);
    _activeNotifications
        .removeWhere((n) => n.type == StudentNotificationType.connectivityLost);

    _notificationsController.add(List.unmodifiable(_notifications));
  }

  /// Enviar notificación local (no del WebSocket)
  Future<void> sendLocalNotification(StudentNotification notification) async {
    debugPrint('📱 Enviando notificación local: ${notification.type.key}');

    _handleWebSocketNotification(notification);
  }

  /// Crear y enviar notificación de geofence
  Future<void> sendGeofenceNotification({
    required bool entered,
    required String eventTitle,
    required String eventId,
    double? accuracy,
    int? gracePeriodSeconds,
  }) async {
    final notification = entered
        ? StudentNotificationFactory.enteredArea(
            eventTitle: eventTitle,
            eventId: eventId,
            accuracy: accuracy,
          )
        : StudentNotificationFactory.exitedArea(
            eventTitle: eventTitle,
            eventId: eventId,
            gracePeriodSeconds: gracePeriodSeconds,
          );

    await sendLocalNotification(notification);
  }

  /// Crear y enviar notificación de asistencia registrada
  Future<void> sendAttendanceRegisteredNotification({
    required String eventTitle,
    required String eventId,
    DateTime? registrationTime,
  }) async {
    final notification = StudentNotificationFactory.attendanceRegistered(
      eventTitle: eventTitle,
      eventId: eventId,
      registrationTime: registrationTime,
    );

    await sendLocalNotification(notification);
  }

  /// Crear y enviar notificación de advertencia por cierre de app
  Future<void> sendAppClosedWarning({
    required String eventTitle,
    required String eventId,
    required int secondsRemaining,
  }) async {
    final notification = StudentNotificationFactory.appClosedWarning(
      eventTitle: eventTitle,
      eventId: eventId,
      secondsRemaining: secondsRemaining,
    );

    await sendLocalNotification(notification);
  }

  /// Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _activeNotifications.removeWhere((n) => n.id == notificationId);

      _notificationsController.add(List.unmodifiable(_notifications));
      await _saveNotifications();

      debugPrint('✅ Notificación marcada como leída: $notificationId');
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }

    _activeNotifications.clear();
    _notificationsController.add(List.unmodifiable(_notifications));
    await _saveNotifications();

    debugPrint('✅ Todas las notificaciones marcadas como leídas');
  }

  /// Eliminar notificación
  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _activeNotifications.removeWhere((n) => n.id == notificationId);

    _notificationsController.add(List.unmodifiable(_notifications));
    await _saveNotifications();

    debugPrint('🗑️ Notificación eliminada: $notificationId');
  }

  /// Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _activeNotifications.clear();

    _notificationsController.add(List.unmodifiable(_notifications));
    await _saveNotifications();

    debugPrint('🧹 Todas las notificaciones eliminadas');
  }

  /// Obtener notificaciones por tipo
  List<StudentNotification> getNotificationsByType(
      StudentNotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Obtener notificaciones por evento
  List<StudentNotification> getNotificationsByEvent(String eventId) {
    return _notifications.where((n) => n.eventId == eventId).toList();
  }

  /// Configuración de notificaciones

  /// Habilitar/deshabilitar notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveConfiguration();
    debugPrint(
        '🔔 Notificaciones ${enabled ? 'habilitadas' : 'deshabilitadas'}');
  }

  /// Habilitar/deshabilitar sonido
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveConfiguration();
    debugPrint('🔊 Sonido ${enabled ? 'habilitado' : 'deshabilitado'}');
  }

  /// Habilitar/deshabilitar vibración
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveConfiguration();
    debugPrint('📳 Vibración ${enabled ? 'habilitada' : 'deshabilitada'}');
  }

  /// Obtener configuración actual
  Map<String, bool> getConfiguration() {
    return {
      'notificationsEnabled': _notificationsEnabled,
      'soundEnabled': _soundEnabled,
      'vibrationEnabled': _vibrationEnabled,
      'persistentNotificationsEnabled': _persistentNotificationsEnabled,
    };
  }

  /// Cargar configuración guardada
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _persistentNotificationsEnabled =
          prefs.getBool('persistent_notifications_enabled') ?? true;

      debugPrint('✅ Configuración cargada');
    } catch (e) {
      debugPrint('❌ Error cargando configuración: $e');
    }
  }

  /// Guardar configuración
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setBool(
          'persistent_notifications_enabled', _persistentNotificationsEnabled);

      debugPrint('✅ Configuración guardada');
    } catch (e) {
      debugPrint('❌ Error guardando configuración: $e');
    }
  }

  /// Cargar notificaciones almacenadas
  Future<void> _loadStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);

      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);

        for (final notificationData in notificationsList) {
          try {
            final notification = StudentNotification.fromJson(notificationData);
            _notifications.add(notification);

            if (!notification.isRead) {
              _activeNotifications.add(notification);
            }
          } catch (e) {
            debugPrint('⚠️ Error cargando notificación individual: $e');
          }
        }

        _notificationsController.add(List.unmodifiable(_notifications));
        debugPrint('✅ ${_notifications.length} notificaciones cargadas');
      }
    } catch (e) {
      debugPrint('❌ Error cargando notificaciones: $e');
    }
  }

  /// Guardar notificaciones
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );

      await prefs.setString(_notificationsKey, notificationsJson);
      debugPrint('✅ Notificaciones guardadas');
    } catch (e) {
      debugPrint('❌ Error guardando notificaciones: $e');
    }
  }

  /// Obtener estadísticas de notificaciones
  Map<String, dynamic> getStatistics() {
    final typeCount = <String, int>{};

    for (final notification in _notifications) {
      final typeKey = notification.type.key;
      typeCount[typeKey] = (typeCount[typeKey] ?? 0) + 1;
    }

    return {
      'total': _notifications.length,
      'unread': _activeNotifications.length,
      'read': _notifications.length - _activeNotifications.length,
      'byType': typeCount,
      'isListening': _isListening,
      'currentEventId': _currentEventId,
      'webSocketConnected': _webSocketService.isConnected,
    };
  }

  /// Limpiar recursos y cerrar streams
  Future<void> dispose() async {
    debugPrint('🧹 Limpiando StudentNotificationService');

    await stopListening();
    await _webSocketService.dispose();

    await _notificationsController.close();
    await _newNotificationController.close();

    _notifications.clear();
    _activeNotifications.clear();

    _isInitialized = false;

    debugPrint('✅ StudentNotificationService limpiado');
  }
}
