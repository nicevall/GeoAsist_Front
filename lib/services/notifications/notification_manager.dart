// lib/services/notifications/notification_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

/// Sistema de notificaciones simple y funcional para Fase C
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  // 🎯 CONFIGURACIÓN DE CANALES
  static const String _trackingChannelId = 'tracking_channel';
  static const String _alertsChannelId = 'alerts_channel';

  // 🎯 IDs DE NOTIFICACIONES
  static const int _trackingNotificationId = 1000;
  static const int _geofenceEnteredId = 1001;
  static const int _geofenceExitedId = 1002;
  static const int _eventStartedId = 1003;
  static const int _breakStartedId = 1004;
  static const int _breakEndedId = 1005;
  static const int _attendanceRegisteredId = 1006;
  static const int _appClosedWarningId = 1007;
  static const int _criticalWarningId = 1008;

  // 🎯 PLUGIN DE NOTIFICACIONES
  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  /// Inicializar el sistema de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Inicializando NotificationManager');

      _notifications = FlutterLocalNotificationsPlugin();

      await _configureNotificationChannels();
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ NotificationManager inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationManager: $e');
      rethrow;
    }
  }

  Future<void> _configureNotificationChannels() async {
    // Configuración Android
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración iOS
    const iosInitSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notifications.initialize(initSettings);

    // Crear canales para Android
    if (Platform.isAndroid) {
      await _createAndroidChannels();
    }

    debugPrint('✅ Canales de notificación configurados');
  }

  Future<void> _createAndroidChannels() async {
    // Canal para tracking persistente (baja importancia, sin sonido)
    const trackingChannel = AndroidNotificationChannel(
      _trackingChannelId,
      'Tracking de Asistencia',
      description: 'Notificación persistente durante eventos activos',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // Canal para alertas importantes (alta importancia, con sonido)
    const alertsChannel = AndroidNotificationChannel(
      _alertsChannelId,
      'Alertas de Asistencia',
      description: 'Alertas importantes sobre eventos y asistencia',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(trackingChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertsChannel);

    debugPrint('✅ Canales Android creados');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } else if (Platform.isIOS) {
      final iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }

    debugPrint('✅ Permisos de notificación solicitados');
  }

  // 🎯 NOTIFICACIÓN PERSISTENTE DE TRACKING

  /// Mostrar notificación persistente durante tracking
  Future<void> showTrackingActiveNotification() async {
    try {
      debugPrint('📱 Mostrando notificación de tracking activo');

      const androidDetails = AndroidNotificationDetails(
        _trackingChannelId,
        'Tracking de Asistencia',
        channelDescription: 'Tracking activo para evento',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // No se puede deslizar para quitar
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _trackingNotificationId,
        'GeoAsist - Tracking Activo',
        'Mantén la app abierta para conservar tu asistencia',
        details,
      );

      debugPrint('✅ Notificación de tracking mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de tracking: $e');
    }
  }

  /// Actualizar estado de la notificación de tracking
  Future<void> updateTrackingNotificationStatus(String status) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _trackingChannelId,
        'Tracking de Asistencia',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _trackingNotificationId,
        'GeoAsist - $status',
        'Estado actualizado: ${DateTime.now().toString().substring(11, 19)}',
        details,
      );
    } catch (e) {
      debugPrint('❌ Error actualizando notificación: $e');
    }
  }

  // 🎯 NOTIFICACIONES DE GEOFENCE

  /// Notificación al entrar al geofence
  Future<void> showGeofenceEnteredNotification(String eventName) async {
    try {
      debugPrint('✅ Mostrando notificación - Entró al área');

      await _showAlertNotification(
        _geofenceEnteredId,
        'Entraste al Área',
        'Ahora estás dentro del área del evento: $eventName',
        'success',
      );

      // Vibración de éxito
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('❌ Error notificación geofence entrada: $e');
    }
  }

  /// Notificación al salir del geofence
  Future<void> showGeofenceExitedNotification(String eventName) async {
    try {
      debugPrint('⚠️ Mostrando notificación - Salió del área');

      await _showAlertNotification(
        _geofenceExitedId,
        'Saliste del Área',
        'Tienes 1 minuto para regresar al área del evento: $eventName',
        'warning',
      );

      // Vibración de advertencia
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ Error notificación geofence salida: $e');
    }
  }

  // 🎯 NOTIFICACIONES DE EVENTOS

  /// Notificación cuando el profesor inicia un evento
  Future<void> showEventStartedNotification(String eventName) async {
    try {
      debugPrint('🎯 Mostrando notificación - Evento iniciado');

      await _showAlertNotification(
        _eventStartedId,
        'Evento Iniciado',
        'El evento "$eventName" ha comenzado. Puedes unirte ahora.',
        'info',
      );
    } catch (e) {
      debugPrint('❌ Error notificación evento iniciado: $e');
    }
  }

  /// Notificación cuando inicia un receso
  Future<void> showBreakStartedNotification() async {
    try {
      debugPrint('⏸️ Mostrando notificación - Receso iniciado');

      await _showAlertNotification(
        _breakStartedId,
        'Receso Iniciado',
        'El tracking se ha pausado temporalmente durante el receso.',
        'info',
      );
    } catch (e) {
      debugPrint('❌ Error notificación receso iniciado: $e');
    }
  }

  /// Notificación cuando termina un receso
  Future<void> showBreakEndedNotification() async {
    try {
      debugPrint('▶️ Mostrando notificación - Receso terminado');

      await _showAlertNotification(
        _breakEndedId,
        'Receso Terminado',
        'El tracking se ha reanudado. Asegúrate de estar en el área.',
        'success',
      );
    } catch (e) {
      debugPrint('❌ Error notificación receso terminado: $e');
    }
  }

  // 🎯 NOTIFICACIONES DE ASISTENCIA

  /// Notificación cuando se registra asistencia
  Future<void> showAttendanceRegisteredNotification() async {
    try {
      debugPrint('✅ Mostrando notificación - Asistencia registrada');

      await _showAlertNotification(
        _attendanceRegisteredId,
        'Asistencia Registrada',
        'Tu asistencia ha sido registrada exitosamente.',
        'success',
      );

      // Vibración suave de confirmación
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ Error notificación asistencia registrada: $e');
    }
  }

  // 🎯 NOTIFICACIONES CRÍTICAS DE APP LIFECYCLE

  /// Advertencia crítica cuando la app se cierra
  Future<void> showAppClosedWarningNotification(int secondsRemaining) async {
    try {
      debugPrint('🚨 Mostrando advertencia crítica - App cerrada');

      const androidDetails = AndroidNotificationDetails(
        _alertsChannelId,
        'Alertas de Asistencia',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: false,
        autoCancel: false,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true, // Mostrar sobre otras apps
        category: AndroidNotificationCategory.alarm,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _appClosedWarningId,
        '🚨 REABRE GEOASIST YA',
        'Tienes ${secondsRemaining}s para reabrir la app o perderás tu asistencia',
        details,
      );

      // Vibración intensa de emergencia
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ Error notificación app cerrada: $e');
    }
  }

  /// Advertencia crítica general de lifecycle
  Future<void> showCriticalAppLifecycleWarning() async {
    try {
      debugPrint('🚨 Mostrando advertencia crítica de lifecycle');

      await _showAlertNotification(
        _criticalWarningId,
        'Advertencia Crítica',
        'Mantén GeoAsist abierto para conservar tu asistencia.',
        'critical',
      );
    } catch (e) {
      debugPrint('❌ Error advertencia crítica: $e');
    }
  }

  // 🎯 MÉTODO AUXILIAR PARA ALERTAS

  Future<void> _showAlertNotification(
    int id,
    String title,
    String body,
    String type, // 'success', 'warning', 'info', 'critical'
  ) async {
    try {
      // Configurar según el tipo de alerta
      final config = _getAlertConfig(type);

      final androidDetails = AndroidNotificationDetails(
        _alertsChannelId,
        'Alertas de Asistencia',
        importance: config['importance'],
        priority: config['priority'],
        playSound: config['playSound'],
        enableVibration: config['enableVibration'],
        autoCancel: true,
        icon: config['icon'],
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: config['playSound'],
        interruptionLevel: config['interruptionLevel'],
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);
    } catch (e) {
      debugPrint('❌ Error mostrando alerta: $e');
    }
  }

  Map<String, dynamic> _getAlertConfig(String type) {
    switch (type) {
      case 'success':
        return {
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
          'playSound': false,
          'enableVibration': true,
          'icon': '@mipmap/ic_launcher',
          'interruptionLevel': InterruptionLevel.active,
        };
      case 'warning':
        return {
          'importance': Importance.high,
          'priority': Priority.high,
          'playSound': true,
          'enableVibration': true,
          'icon': '@mipmap/ic_launcher',
          'interruptionLevel': InterruptionLevel.timeSensitive,
        };
      case 'critical':
        return {
          'importance': Importance.max,
          'priority': Priority.max,
          'playSound': true,
          'enableVibration': true,
          'icon': '@mipmap/ic_launcher',
          'interruptionLevel': InterruptionLevel.critical,
        };
      default: // 'info'
        return {
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
          'playSound': false,
          'enableVibration': false,
          'icon': '@mipmap/ic_launcher',
          'interruptionLevel': InterruptionLevel.active,
        };
    }
  }

  // 🎯 GESTIÓN DE NOTIFICACIONES

  /// Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    try {
      debugPrint('🧹 Limpiando todas las notificaciones');

      await _notifications.cancelAll();

      debugPrint('✅ Notificaciones limpiadas');
    } catch (e) {
      debugPrint('❌ Error limpiando notificaciones: $e');
    }
  }

  /// Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('✅ Notificación $id cancelada');
    } catch (e) {
      debugPrint('❌ Error cancelando notificación $id: $e');
    }
  }

  /// Cancelar notificación de tracking persistente
  Future<void> clearTrackingNotification() async {
    await cancelNotification(_trackingNotificationId);
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          return await androidImplementation.areNotificationsEnabled() ?? false;
        }
      }
      return true; // Asumir habilitadas en iOS
    } catch (e) {
      debugPrint('❌ Error verificando notificaciones: $e');
      return false;
    }
  }

  // 🎯 INFORMACIÓN Y DEBUGGING

  /// Obtener estado del sistema de notificaciones
  Map<String, dynamic> getNotificationStatus() {
    return {
      'initialized': _isInitialized,
      'tracking_channel_id': _trackingChannelId,
      'alerts_channel_id': _alertsChannelId,
      'tracking_notification_id': _trackingNotificationId,
      'platform': Platform.operatingSystem,
    };
  }

  /// Verificar configuración
  Future<Map<String, dynamic>> getSystemConfiguration() async {
    try {
      return {
        'notifications_enabled': await areNotificationsEnabled(),
        'channels_created': _isInitialized,
        'platform_support': Platform.isAndroid || Platform.isIOS,
        'initialization_status': _isInitialized,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // 🎯 TESTING Y DEBUGGING

  /// Mostrar notificación de prueba
  Future<void> showTestNotification() async {
    try {
      debugPrint('🧪 Mostrando notificación de prueba');

      await _showAlertNotification(
        999,
        'Prueba de Notificación',
        'Esta es una notificación de prueba del sistema GeoAsist',
        'info',
      );
    } catch (e) {
      debugPrint('❌ Error en notificación de prueba: $e');
    }
  }
}
