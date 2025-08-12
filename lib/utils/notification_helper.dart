// lib/utils/notification_helper.dart
// 🎯 HELPER DE NOTIFICACIONES FASE A1.2 - Preparado para flutter_local_notifications
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  // 🎯 CONFIGURACIÓN DE NOTIFICACIONES
  static const String channelId = 'geo_asist_attendance';
  static const String channelName = 'Asistencia Geolocalizada';
  static const String channelDescription =
      'Notificaciones del sistema de asistencia';

  // Estado de inicialización
  bool _isInitialized = false;
  final bool _hasPermissions = false;

  // 🎯 INICIALIZACIÓN
  Future<void> initialize() async {
    debugPrint('🔔 Inicializando NotificationHelper');

    try {
      // TODO: Integrar flutter_local_notifications en A1.3
      // await _initializeLocalNotifications();
      // await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ NotificationHelper inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  // 🎯 MÉTODOS PÚBLICOS PARA NOTIFICACIONES

  Future<void> showEventActiveNotification({
    required String eventName,
    required String eventId,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ NotificationHelper no inicializado');
      return;
    }

    debugPrint('🔔 Mostrando notificación de evento activo: $eventName');

    // Vibración háptica
    _triggerHapticFeedback(HapticFeedbackType.medium);

    // TODO: Implementar notificación real en A1.3
    _logNotification('Evento Activo', 'Tracking iniciado para: $eventName');
  }

  Future<void> showGeofenceEnteredNotification({
    required String eventName,
  }) async {
    if (!_isInitialized) return;

    debugPrint('🔔 Usuario ingresó al geofence: $eventName');

    _triggerHapticFeedback(HapticFeedbackType.medium);
    _logNotification('Área del Evento', 'Has ingresado al área de $eventName');
  }

  Future<void> showGeofenceExitedNotification({
    required String eventName,
    required double distanceMeters,
  }) async {
    if (!_isInitialized) return;

    debugPrint('🔔 Usuario salió del geofence: $eventName');

    _triggerHapticFeedback(HapticFeedbackType.heavy);
    _logNotification(
      'Fuera del Área',
      'Has salido del área de $eventName (${distanceMeters.toStringAsFixed(0)}m)',
    );
  }

  Future<void> showGracePeriodStartedNotification({
    required String eventName,
    required int gracePeriodSeconds,
  }) async {
    if (!_isInitialized) return;

    debugPrint('🔔 Período de gracia iniciado: ${gracePeriodSeconds}s');

    _triggerHapticFeedback(HapticFeedbackType.heavy);
    _logNotification(
      'Período de Gracia',
      'Tienes ${gracePeriodSeconds}s para regresar al área de $eventName',
    );
  }

  Future<void> showGracePeriodExpiredNotification({
    required String eventName,
  }) async {
    if (!_isInitialized) return;

    debugPrint('🔔 Período de gracia expirado: $eventName');

    _triggerHapticFeedback(HapticFeedbackType.error);
    _logNotification(
      'Gracia Expirada',
      'El período de gracia ha terminado para $eventName',
    );
  }

  Future<void> showTrackingPausedNotification() async {
    if (!_isInitialized) return;

    debugPrint('🔔 Tracking pausado para receso');

    _triggerHapticFeedback(HapticFeedbackType.light);
    _logNotification('Receso Iniciado', 'El tracking ha sido pausado');
  }

  Future<void> showTrackingResumedNotification() async {
    if (!_isInitialized) return;

    debugPrint('🔔 Tracking reanudado después del receso');

    _triggerHapticFeedback(HapticFeedbackType.light);
    _logNotification('Receso Terminado', 'El tracking ha sido reanudado');
  }

  Future<void> showAttendanceRegisteredNotification({
    required String eventName,
  }) async {
    if (!_isInitialized) return;

    debugPrint('🔔 Asistencia registrada: $eventName');

    _triggerHapticFeedback(HapticFeedbackType.success);
    _logNotification(
      'Asistencia Registrada',
      'Tu asistencia ha sido registrada para $eventName',
    );
  }

  Future<void> showConnectionErrorNotification() async {
    if (!_isInitialized) return;

    debugPrint('🔔 Error de conexión detectado');

    _triggerHapticFeedback(HapticFeedbackType.error);
    _logNotification('Error de Conexión', 'Problema conectando al servidor');
  }

  // 🎯 LIMPIEZA DE NOTIFICACIONES

  Future<void> clearAllNotifications() async {
    debugPrint('🧹 Limpiando todas las notificaciones');

    // TODO: Implementar en A1.3 con flutter_local_notifications
    // await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> clearNotification(int notificationId) async {
    debugPrint('🧹 Limpiando notificación: $notificationId');

    // TODO: Implementar en A1.3
    // await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  // 🎯 MÉTODOS PRIVADOS

  void _triggerHapticFeedback(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.success:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
        });
        break;
      case HapticFeedbackType.error:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.mediumImpact();
        });
        break;
    }
  }

  void _logNotification(String title, String body) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📱 [$timestamp] $title: $body');
  }

  // 🎯 MÉTODOS PARA FUTURAS INTEGRACIONES (A1.3)

  // TODO: Implementar en A1.3
  // Future<void> _initializeLocalNotifications() async {
  //   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const iosSettings = DarwinInitializationSettings();
  //   const initSettings = InitializationSettings(
  //     android: androidSettings,
  //     iOS: iosSettings,
  //   );
  //
  //   await flutterLocalNotificationsPlugin.initialize(initSettings);
  //   await _createNotificationChannel();
  // }

  // TODO: Implementar en A1.3
  // Future<void> _requestPermissions() async {
  //   if (Platform.isAndroid) {
  //     final hasPermissions = await flutterLocalNotificationsPlugin
  //         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //         ?.requestNotificationsPermission();
  //     _hasPermissions = hasPermissions ?? false;
  //   }
  // }

  // TODO: Implementar en A1.3
  // Future<void> _createNotificationChannel() async {
  //   const androidChannel = AndroidNotificationChannel(
  //     channelId,
  //     channelName,
  //     description: channelDescription,
  //     importance: Importance.high,
  //     enableVibration: true,
  //     playSound: true,
  //   );
  //
  //   await flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(androidChannel);
  // }

  // 🎯 GETTERS PÚBLICOS

  bool get isInitialized => _isInitialized;
  bool get hasPermissions => _hasPermissions;
}

// 🎯 ENUM PARA TIPOS DE VIBRACIÓN HÁPTICA
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  success,
  error,
}
