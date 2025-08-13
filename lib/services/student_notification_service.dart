// lib/services/student_notification_service.dart
// 🔔 SERVICIO ESPECIALIZADO PARA GESTIÓN DE NOTIFICACIONES DE ESTUDIANTES
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  final StorageService _storageService = StorageService(); // ✅ AHORA SE USA

  // 🎯 ESTADO DEL SERVICIO
  bool _isInitialized = false;
  bool _isListening = false;
  String? _currentEventId;
  String? _currentUserId; // ✅ YA SE USABA

  // 🎯 ALMACENAMIENTO DE NOTIFICACIONES
  final List<StudentNotification> _notifications = [];
  final List<StudentNotification> _activeNotifications = [];
  static const int _maxStoredNotifications = 50;

  // ✅ NUEVAS CONSTANTES PARA STORAGE KEYS
  static const String _notificationsKey = 'student_notifications';
  static const String _configNotificationsEnabledKey = 'notifications_enabled';
  static const String _configSoundEnabledKey = 'sound_enabled';
  static const String _configVibrationEnabledKey = 'vibration_enabled';
  static const String _configPersistentEnabledKey =
      'persistent_notifications_enabled';
  static const String _userPreferencesKey = 'user_notification_preferences';

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

  /// Usuario actual
  String? get currentUserId => _currentUserId;

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Inicializando StudentNotificationService');

      // Inicializar servicios dependientes
      await _webSocketService.initialize();
      await _notificationManager.initialize();

      // ✅ USAR STORAGESERVICE: Cargar configuración
      await _loadConfigurationFromStorage();

      // ✅ USAR STORAGESERVICE: Cargar notificaciones almacenadas
      await _loadStoredNotificationsFromStorage();

      // Configurar listeners
      _setupWebSocketListener();

      _isInitialized = true;
      debugPrint('✅ StudentNotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando StudentNotificationService: $e');
      rethrow;
    }
  }

  /// ✅ NUEVA IMPLEMENTACIÓN: Configurar usuario actual
  Future<void> setCurrentUser(String userId) async {
    if (_currentUserId != userId) {
      debugPrint('👤 Configurando usuario actual: $userId');
      _currentUserId = userId;

      // Cargar preferencias específicas del usuario
      await _loadUserSpecificPreferences(userId);

      // Guardar en storage para persistencia
      await _storageService.saveData('current_notification_user_id', userId);
    }
  }

  /// ✅ NUEVA IMPLEMENTACIÓN: Cargar preferencias específicas del usuario
  Future<void> _loadUserSpecificPreferences(String userId) async {
    try {
      debugPrint('📋 Cargando preferencias específicas para usuario: $userId');

      final userPrefsKey = '${_userPreferencesKey}_$userId';
      final userPrefsJson = await _storageService.getData(userPrefsKey);

      if (userPrefsJson != null) {
        final userPrefs = jsonDecode(userPrefsJson);

        _notificationsEnabled = userPrefs['notificationsEnabled'] ?? true;
        _soundEnabled = userPrefs['soundEnabled'] ?? true;
        _vibrationEnabled = userPrefs['vibrationEnabled'] ?? true;
        _persistentNotificationsEnabled =
            userPrefs['persistentEnabled'] ?? true;

        debugPrint('✅ Preferencias de usuario cargadas para: $userId');
      } else {
        debugPrint('ℹ️ No hay preferencias específicas para usuario: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error cargando preferencias de usuario: $e');
    }
  }

  /// ✅ NUEVA IMPLEMENTACIÓN: Guardar preferencias específicas del usuario
  Future<void> _saveUserSpecificPreferences() async {
    if (_currentUserId == null) return;

    try {
      debugPrint(
          '💾 Guardando preferencias específicas para usuario: $_currentUserId');

      final userPrefsKey = '${_userPreferencesKey}_$_currentUserId';
      final userPrefs = {
        'notificationsEnabled': _notificationsEnabled,
        'soundEnabled': _soundEnabled,
        'vibrationEnabled': _vibrationEnabled,
        'persistentEnabled': _persistentNotificationsEnabled,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _storageService.saveData(userPrefsKey, jsonEncode(userPrefs));
      debugPrint('✅ Preferencias de usuario guardadas');
    } catch (e) {
      debugPrint('❌ Error guardando preferencias de usuario: $e');
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
      await setCurrentUser(userId); // ✅ USAR MÉTODO QUE USA STORAGESERVICE

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

    // ✅ USAR STORAGESERVICE: Guardar notificaciones actualizadas
    _saveNotificationsToStorage();
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
      case WebSocketConnectionState.connecting:
        // No hacer nada especial durante conexión/reconexión
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
      await _saveNotificationsToStorage(); // ✅ USAR STORAGESERVICE

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
    await _saveNotificationsToStorage(); // ✅ USAR STORAGESERVICE

    debugPrint('✅ Todas las notificaciones marcadas como leídas');
  }

  /// Eliminar notificación
  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _activeNotifications.removeWhere((n) => n.id == notificationId);

    _notificationsController.add(List.unmodifiable(_notifications));
    await _saveNotificationsToStorage(); // ✅ USAR STORAGESERVICE

    debugPrint('🗑️ Notificación eliminada: $notificationId');
  }

  /// Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _activeNotifications.clear();

    _notificationsController.add(List.unmodifiable(_notifications));
    await _saveNotificationsToStorage(); // ✅ USAR STORAGESERVICE

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

  /// ✅ NUEVA IMPLEMENTACIÓN: Obtener notificaciones por usuario
  List<StudentNotification> getNotificationsByUser(String userId) {
    // Filtrar notificaciones que sean relevantes para este usuario
    return _notifications
        .where((n) =>
                n.eventId != null || // Notificaciones de eventos
                n.type ==
                    StudentNotificationType
                        .connectivityLost || // Errores de conectividad
                n.type ==
                    StudentNotificationType.appClosedWarning // Warnings de app
            )
        .toList();
  }

  // 🎯 CONFIGURACIÓN DE NOTIFICACIONES CON STORAGESERVICE

  /// Habilitar/deshabilitar notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveConfigurationToStorage(); // ✅ USAR STORAGESERVICE
    await _saveUserSpecificPreferences(); // ✅ PREFERENCIAS POR USUARIO
    debugPrint(
        '🔔 Notificaciones ${enabled ? 'habilitadas' : 'deshabilitadas'}');
  }

  /// Habilitar/deshabilitar sonido
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveConfigurationToStorage(); // ✅ USAR STORAGESERVICE
    await _saveUserSpecificPreferences(); // ✅ PREFERENCIAS POR USUARIO
    debugPrint('🔊 Sonido ${enabled ? 'habilitado' : 'deshabilitado'}');
  }

  /// Habilitar/deshabilitar vibración
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveConfigurationToStorage(); // ✅ USAR STORAGESERVICE
    await _saveUserSpecificPreferences(); // ✅ PREFERENCIAS POR USUARIO
    debugPrint('📳 Vibración ${enabled ? 'habilitada' : 'deshabilitada'}');
  }

  /// ✅ NUEVA FUNCIONALIDAD: Configurar todas las preferencias a la vez
  Future<void> updateAllPreferences({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? persistentEnabled,
  }) async {
    bool changed = false;

    if (notificationsEnabled != null &&
        _notificationsEnabled != notificationsEnabled) {
      _notificationsEnabled = notificationsEnabled;
      changed = true;
    }

    if (soundEnabled != null && _soundEnabled != soundEnabled) {
      _soundEnabled = soundEnabled;
      changed = true;
    }

    if (vibrationEnabled != null && _vibrationEnabled != vibrationEnabled) {
      _vibrationEnabled = vibrationEnabled;
      changed = true;
    }

    if (persistentEnabled != null &&
        _persistentNotificationsEnabled != persistentEnabled) {
      _persistentNotificationsEnabled = persistentEnabled;
      changed = true;
    }

    if (changed) {
      await _saveConfigurationToStorage();
      await _saveUserSpecificPreferences();
      debugPrint('✅ Preferencias actualizadas en lote');
    }
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

  // 🎯 MÉTODOS REFACTORIZADOS PARA USAR STORAGESERVICE

  /// ✅ REFACTORIZADO: Cargar configuración usando StorageService
  Future<void> _loadConfigurationFromStorage() async {
    try {
      debugPrint('📋 Cargando configuración desde StorageService');

      // Cargar configuración global
      final notificationsEnabledStr =
          await _storageService.getData(_configNotificationsEnabledKey);
      final soundEnabledStr =
          await _storageService.getData(_configSoundEnabledKey);
      final vibrationEnabledStr =
          await _storageService.getData(_configVibrationEnabledKey);
      final persistentEnabledStr =
          await _storageService.getData(_configPersistentEnabledKey);

      _notificationsEnabled = notificationsEnabledStr?.toLowerCase() == 'true'
          ? true
          : notificationsEnabledStr?.toLowerCase() == 'false'
              ? false
              : true;

      _soundEnabled = soundEnabledStr?.toLowerCase() == 'true'
          ? true
          : soundEnabledStr?.toLowerCase() == 'false'
              ? false
              : true;

      _vibrationEnabled = vibrationEnabledStr?.toLowerCase() == 'true'
          ? true
          : vibrationEnabledStr?.toLowerCase() == 'false'
              ? false
              : true;

      _persistentNotificationsEnabled =
          persistentEnabledStr?.toLowerCase() == 'true'
              ? true
              : persistentEnabledStr?.toLowerCase() == 'false'
                  ? false
                  : true;

      // Cargar usuario actual si existe
      final currentUserId =
          await _storageService.getData('current_notification_user_id');
      if (currentUserId != null) {
        _currentUserId = currentUserId;
        await _loadUserSpecificPreferences(currentUserId);
      }

      debugPrint('✅ Configuración cargada desde StorageService');
    } catch (e) {
      debugPrint('❌ Error cargando configuración desde StorageService: $e');
      // Usar valores por defecto
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _persistentNotificationsEnabled = true;
    }
  }

  /// ✅ REFACTORIZADO: Guardar configuración usando StorageService
  Future<void> _saveConfigurationToStorage() async {
    try {
      debugPrint('💾 Guardando configuración en StorageService');

      await _storageService.saveData(
          _configNotificationsEnabledKey, _notificationsEnabled.toString());
      await _storageService.saveData(
          _configSoundEnabledKey, _soundEnabled.toString());
      await _storageService.saveData(
          _configVibrationEnabledKey, _vibrationEnabled.toString());
      await _storageService.saveData(_configPersistentEnabledKey,
          _persistentNotificationsEnabled.toString());

      debugPrint('✅ Configuración guardada en StorageService');
    } catch (e) {
      debugPrint('❌ Error guardando configuración en StorageService: $e');
    }
  }

  /// ✅ REFACTORIZADO: Cargar notificaciones usando StorageService
  Future<void> _loadStoredNotificationsFromStorage() async {
    try {
      debugPrint('📋 Cargando notificaciones desde StorageService');

      final notificationsJson =
          await _storageService.getData(_notificationsKey);

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
        debugPrint(
            '✅ ${_notifications.length} notificaciones cargadas desde StorageService');
      } else {
        debugPrint('ℹ️ No hay notificaciones almacenadas en StorageService');
      }
    } catch (e) {
      debugPrint('❌ Error cargando notificaciones desde StorageService: $e');
    }
  }

  /// ✅ REFACTORIZADO: Guardar notificaciones usando StorageService
  Future<void> _saveNotificationsToStorage() async {
    try {
      debugPrint('💾 Guardando notificaciones en StorageService');

      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );

      await _storageService.saveData(_notificationsKey, notificationsJson);
      debugPrint('✅ Notificaciones guardadas en StorageService');
    } catch (e) {
      debugPrint('❌ Error guardando notificaciones en StorageService: $e');
    }
  }

  /// ✅ NUEVA FUNCIONALIDAD: Exportar configuración para backup
  Future<Map<String, dynamic>> exportConfiguration() async {
    return {
      'configuration': getConfiguration(),
      'userSpecificPreferences': _currentUserId != null
          ? {
              'userId': _currentUserId,
              'preferences': getConfiguration(),
            }
          : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// ✅ NUEVA FUNCIONALIDAD: Importar configuración desde backup
  Future<void> importConfiguration(Map<String, dynamic> config) async {
    try {
      debugPrint('📥 Importando configuración desde backup');

      final configuration = config['configuration'] as Map<String, dynamic>?;
      if (configuration != null) {
        await updateAllPreferences(
          notificationsEnabled: configuration['notificationsEnabled'] as bool?,
          soundEnabled: configuration['soundEnabled'] as bool?,
          vibrationEnabled: configuration['vibrationEnabled'] as bool?,
          persistentEnabled:
              configuration['persistentNotificationsEnabled'] as bool?,
        );
      }

      debugPrint('✅ Configuración importada exitosamente');
    } catch (e) {
      debugPrint('❌ Error importando configuración: $e');
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
      'currentUserId': _currentUserId, // ✅ AGREGAR USUARIO ACTUAL
      'webSocketConnected': _webSocketService.isConnected,
      'configuration': getConfiguration(),
      'storageKeys': {
        'notifications': _notificationsKey,
        'configEnabled': _configNotificationsEnabledKey,
        'userPreferences': _currentUserId != null
            ? '${_userPreferencesKey}_$_currentUserId'
            : null,
      },
    };
  }

  /// ✅ NUEVA FUNCIONALIDAD: Limpiar datos específicos del usuario
  Future<void> clearUserData(String userId) async {
    try {
      debugPrint('🧹 Limpiando datos del usuario: $userId');

      // Remover preferencias específicas del usuario
      final userPrefsKey = '${_userPreferencesKey}_$userId';
      await _storageService.removeData(userPrefsKey);

      // Si es el usuario actual, resetear configuración
      if (_currentUserId == userId) {
        _currentUserId = null;
        await _storageService.removeData('current_notification_user_id');

        // Resetear a configuración por defecto
        _notificationsEnabled = true;
        _soundEnabled = true;
        _vibrationEnabled = true;
        _persistentNotificationsEnabled = true;
      }

      debugPrint('✅ Datos del usuario limpiados: $userId');
    } catch (e) {
      debugPrint('❌ Error limpiando datos del usuario: $e');
    }
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
