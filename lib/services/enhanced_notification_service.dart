// lib/services/enhanced_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/attendance_state_model.dart';
import 'notification_channels.dart';
import 'platform_notifications.dart';

/// Servicio completo de notificaciones contextuales para asistencia
/// Maneja notificaciones específicas según el contexto y estado del usuario
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  // Instancias de servicios
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late NotificationChannels _channels;
  late PlatformNotifications _platformNotifications;

  // Control de estado y throttling
  bool _isInitialized = false;
  final Map<String, DateTime> _lastNotificationTimes = {};
  final Map<String, int> _notificationCounts = {};

  // Configuración de throttling (evitar spam)
  static const int _maxNotificationsPerHour = 20;
  static const int _throttleSeconds = 30;

  /// Inicializar el servicio completo de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Inicializar plugin principal
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      _channels = NotificationChannels();
      _platformNotifications = PlatformNotifications();

      // Configuración de inicialización
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Inicializar con callback de respuesta
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
          await _handleNotificationResponse(response);
        },
      );

      // Inicializar canales y permisos
      await _channels.initializeChannels();
      await _platformNotifications.requestPermissions();

      _isInitialized = true;
      debugPrint('📢 EnhancedNotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando EnhancedNotificationService: $e');
      rethrow;
    }
  }

  /// Mostrar notificación de entrada al geofence
  Future<void> showGeofenceEnteredNotification({
    required String eventName,
    required String eventId,
  }) async {
    if (!_isInitialized || _shouldThrottleNotification('geofence_entered')) {
      return;
    }

    try {
      const int notificationId = 1001;
      const String channelId = 'geofence_alerts';

      // Configuración Android
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        'Alertas de Geofence',
        channelDescription:
            'Notificaciones cuando entras o sales del área de asistencia',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification_success',
        color: const Color(0xFF4ECDC4),
        ledColor: const Color(0xFF4ECDC4),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 125, 250]),
        playSound: true,
      );

      // Configuración iOS
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_success.wav',
        interruptionLevel: InterruptionLevel.active,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostrar notificación
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        '✅ Llegaste al área',
        'Has ingresado al área de $eventName. ¡Tu asistencia está siendo registrada!',
        platformChannelSpecifics,
        payload: 'geofence_entered|$eventId',
      );

      // Vibración háptica
      await _triggerHapticFeedback('medium');

      _updateNotificationStats('geofence_entered');
      debugPrint(
          '📢 Notificación de entrada al geofence mostrada para: $eventName');
    } catch (e) {
      debugPrint('❌ Error en showGeofenceEnteredNotification: $e');
    }
  }

  /// Mostrar notificación de salida del geofence
  Future<void> showGeofenceExitedNotification({
    required String eventName,
    required String eventId,
    double? distance,
  }) async {
    if (!_isInitialized || _shouldThrottleNotification('geofence_exited')) {
      return;
    }

    try {
      const int notificationId = 1002;
      const String channelId = 'geofence_alerts';

      final distanceText =
          distance != null ? ' (${distance.toStringAsFixed(0)}m)' : '';

      // Configuración Android
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        'Alertas de Geofence',
        channelDescription:
            'Notificaciones cuando entras o sales del área de asistencia',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_notification_alert',
        color: const Color(0xFFFF6B35),
        ledColor: const Color(0xFFFF6B35),
        ledOnMs: 1500,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
        playSound: true,
        ongoing: true, // Notificación persistente
      );

      // Configuración iOS
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_alert.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostrar notificación
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        '🚨 Saliste del área',
        'Has salido del área de $eventName$distanceText. ¡Regresa para mantener tu asistencia!',
        platformChannelSpecifics,
        payload: 'geofence_exited|$eventId',
      );

      // Vibración háptica más intensa
      await _triggerHapticFeedback('heavy');

      _updateNotificationStats('geofence_exited');
      debugPrint(
          '📢 Notificación de salida del geofence mostrada para: $eventName');
    } catch (e) {
      debugPrint('❌ Error en showGeofenceExitedNotification: $e');
    }
  }

  /// Mostrar notificación de período de gracia
  Future<void> showGracePeriodNotification({
    required String eventName,
    required int remainingSeconds,
  }) async {
    if (!_isInitialized ||
        _shouldThrottleNotification('grace_period', seconds: 15)) {
      return;
    }

    try {
      const int notificationId = 1003;
      const String channelId = 'grace_period';

      final minutes = (remainingSeconds / 60).floor();
      final seconds = remainingSeconds % 60;
      final timeText = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

      // Configuración Android con acciones
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        'Período de Gracia',
        channelDescription:
            'Alertas durante el período de gracia antes de marcar ausencia',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: const Color(0xFFFFA726),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
        playSound: true,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'view_map',
            'Ver Ubicación',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'mark_present',
            'Marcar Presente',
            showsUserInterface: true,
          ),
        ],
      );

      // Configuración iOS
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'GRACE_PERIOD_CATEGORY',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostrar notificación
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        '⏰ Período de Gracia: $timeText',
        'Tienes $timeText para regresar al área de $eventName antes de ser marcado como ausente.',
        platformChannelSpecifics,
        payload: 'grace_period|$remainingSeconds',
      );

      // Vibración háptica suave
      await _triggerHapticFeedback('selection');

      _updateNotificationStats('grace_period');
      debugPrint(
          '📢 Notificación de período de gracia mostrada: $timeText restantes');
    } catch (e) {
      debugPrint('❌ Error en showGracePeriodNotification: $e');
    }
  }

  /// Mostrar notificación de seguimiento iniciado
  Future<void> showTrackingStartedNotification({
    required String eventName,
    required String eventId,
  }) async {
    if (!_isInitialized || _shouldThrottleNotification('tracking_started')) {
      return;
    }

    try {
      const int notificationId = 1004;
      const String channelId = 'attendance_tracking';

      // Configuración Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        'Seguimiento de Asistencia',
        channelDescription:
            'Notificaciones sobre el estado del seguimiento de asistencia',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Notificación persistente
        autoCancel: false,
        showWhen: true,
        icon: '@drawable/ic_notification',
        color: Color(0xFF4ECDC4),
        enableVibration:
            false, // Sin vibración para notificaciones persistentes
        playSound: false, // Sin sonido para notificaciones de estado
      );

      // Configuración iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: false, // No mostrar alerta
        presentBadge: true,
        presentSound: false,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostrar notificación
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        '📍 Seguimiento Activo',
        'Tu asistencia está siendo monitoreada para $eventName',
        platformChannelSpecifics,
        payload: 'tracking_started|$eventId',
      );

      // Vibración háptica muy suave
      await _triggerHapticFeedback('selection');

      _updateNotificationStats('tracking_started');
      debugPrint(
          '📢 Notificación de seguimiento iniciado mostrada para: $eventName');
    } catch (e) {
      debugPrint('❌ Error en showTrackingStartedNotification: $e');
    }
  }

  /// Mostrar notificación de error de ubicación
  Future<void> showLocationErrorNotification({
    required String errorMessage,
  }) async {
    if (!_isInitialized ||
        _shouldThrottleNotification('location_error', seconds: 60)) {
      return;
    }

    try {
      const int notificationId = 1005;
      const String channelId = 'system_alerts';

      // Configuración Android
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        'Alertas del Sistema',
        channelDescription:
            'Alertas importantes sobre el funcionamiento del sistema',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification_error',
        color: const Color(0xFFE57373),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 150, 300]),
        playSound: true,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'open_settings',
            'Configurar',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'contact_support',
            'Ayuda',
            showsUserInterface: true,
          ),
        ],
      );

      // Configuración iOS
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'ERROR_CATEGORY',
        interruptionLevel: InterruptionLevel.active,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostrar notificación
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        '⚠️ Error de Ubicación',
        errorMessage,
        platformChannelSpecifics,
        payload: 'location_error|$errorMessage',
      );

      // Vibración háptica de error
      await _triggerHapticFeedback('heavy');

      _updateNotificationStats('location_error');
      debugPrint(
          '📢 Notificación de error de ubicación mostrada: $errorMessage');
    } catch (e) {
      debugPrint('❌ Error en showLocationErrorNotification: $e');
    }
  }

  /// Mostrar notificación contextual basada en el estado de asistencia
  Future<void> showContextualNotification(AttendanceState state) async {
    if (!_isInitialized) {
      return;
    }

    try {
      switch (state.trackingStatus) {
        case TrackingStatus.active:
          if (state.isInsideGeofence) {
            // Usuario dentro del geofence - verificar si hay evento activo
            if (state.currentEvent != null) {
              await showTrackingStartedNotification(
                eventName: state.currentEvent!.titulo,
                eventId: state.currentEvent!.id.toString(),
              );
            }
          } else {
            // Usuario fuera del geofence
            if (state.currentEvent != null) {
              await showGeofenceExitedNotification(
                eventName: state.currentEvent!.titulo,
                eventId: state.currentEvent!.id.toString(),
                distance: state.distanceToEvent,
              );
            }
          }
          break;

        case TrackingStatus.stopped:
          // No mostrar notificaciones cuando está parado
          break;

        default:
          // No mostrar notificaciones para otros estados
          break;
      }
    } catch (e) {
      debugPrint('❌ Error en showContextualNotification: $e');
    }
  }

  /// Mostrar notificación programada
  Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'scheduled_notifications',
  }) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _platformNotifications.showScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
        channelId: channelId,
      );

      debugPrint(
          '📢 Notificación programada creada: $title para ${scheduledTime.toString()}');
    } catch (e) {
      debugPrint('❌ Error en showScheduledNotification: $e');
    }
  }

  /// Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('📢 Notificación cancelada: ID $id');
    } catch (e) {
      debugPrint('❌ Error cancelando notificación $id: $e');
    }
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('📢 Todas las notificaciones canceladas');
    } catch (e) {
      debugPrint('❌ Error cancelando todas las notificaciones: $e');
    }
  }

  /// Obtener notificaciones activas
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      final List<ActiveNotification>? activeNotifications =
          await _flutterLocalNotificationsPlugin.getActiveNotifications();
      return activeNotifications ?? [];
    } catch (e) {
      debugPrint('❌ Error obteniendo notificaciones activas: $e');
      return [];
    }
  }

  /// Manejar vibración háptica según el tipo (simplificado)
  Future<void> _triggerHapticFeedback(String feedbackType) async {
    try {
      switch (feedbackType) {
        case 'selection':
          await HapticFeedback.selectionClick();
          break;
        case 'light':
          await HapticFeedback.lightImpact();
          break;
        case 'medium':
          await HapticFeedback.mediumImpact();
          break;
        case 'heavy':
          await HapticFeedback.heavyImpact();
          break;
        default:
          await HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('❌ Error en vibración háptica: $e');
    }
  }

  /// Verificar si una notificación debe ser throttled (limitada)
  bool _shouldThrottleNotification(String type,
      {int seconds = _throttleSeconds}) {
    final now = DateTime.now();
    final lastTime = _lastNotificationTimes[type];

    // Verificar tiempo desde última notificación
    if (lastTime != null && now.difference(lastTime).inSeconds < seconds) {
      return true;
    }

    // Verificar límite de notificaciones por hora
    final count = _notificationCounts[type] ?? 0;
    if (count >= _maxNotificationsPerHour) {
      return true;
    }

    return false;
  }

  /// Actualizar estadísticas de notificaciones
  void _updateNotificationStats(String type) {
    final now = DateTime.now();
    _lastNotificationTimes[type] = now;
    _notificationCounts[type] = (_notificationCounts[type] ?? 0) + 1;

    // Limpiar contadores cada hora
    _cleanupOldCounts();
  }

  /// Limpiar contadores antiguos (llamado automáticamente)
  void _cleanupOldCounts() {
    _notificationCounts.clear(); // Simplificado: limpiar cada hora
  }

  /// Manejar respuesta a notificaciones (cuando el usuario toca una notificación)
  Future<void> _handleNotificationResponse(
      NotificationResponse response) async {
    try {
      final payload = response.payload;
      if (payload == null) {
        return;
      }

      final parts = payload.split('|');
      if (parts.isEmpty) {
        return;
      }

      final action = parts[0];
      final data = parts.length > 1 ? parts[1] : '';

      debugPrint('📢 Respuesta a notificación: $action con datos: $data');

      switch (action) {
        case 'geofence_entered':
          // TODO: Navegar a MapViewScreen
          break;
        case 'geofence_exited':
          // TODO: Abrir registro de asistencia directo
          break;
        case 'grace_period':
          // TODO: Navegar a dashboard
          break;
        case 'tracking_started':
          // TODO: Implementar lógica de descarte
          break;
        case 'location_error':
          // TODO: Implementar contacto con soporte
          break;
        default:
          // TODO: Implementar pausa de tracking
          break;
      }
    } catch (e) {
      debugPrint('❌ Error manejando respuesta de notificación: $e');
    }
  }

  /// Verificar si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtener estadísticas de notificaciones (para debugging)
  Map<String, dynamic> getNotificationStats() {
    return {
      'isInitialized': _isInitialized,
      'lastNotificationTimes': _lastNotificationTimes,
      'notificationCounts': _notificationCounts,
    };
  }
}
