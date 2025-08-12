// lib/services/platform_notifications.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Gestión de notificaciones específicas por plataforma
/// Maneja permisos, programación y configuraciones avanzadas
class PlatformNotifications {
  static final PlatformNotifications _instance =
      PlatformNotifications._internal();
  factory PlatformNotifications() => _instance;
  PlatformNotifications._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _hasPermissions = false;

  /// Inicializar configuraciones específicas por plataforma
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Inicializar zona horaria para notificaciones programadas
      tz.initializeTimeZones();

      // Configuraciones específicas por plataforma
      await _initializeAndroid();
      await _initializeiOS();

      _isInitialized = true;
      debugPrint('📢 PlatformNotifications inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando PlatformNotifications: $e');
      rethrow;
    }
  }

  /// Configuración específica para Android
  Future<void> _initializeAndroid() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
        '@drawable/ic_notification',
      );

      // Configuración de notificaciones Android
      await _flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: androidSettings),
      );

      debugPrint('📢 Configuración Android inicializada');
    } catch (e) {
      debugPrint('❌ Error configurando Android: $e');
    }
  }

  /// Configuración específica para iOS
  Future<void> _initializeiOS() async {
    try {
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(iOS: iosSettings),
      );

      debugPrint('📢 Configuración iOS inicializada');
    } catch (e) {
      debugPrint('❌ Error configurando iOS: $e');
    }
  }

  /// Solicitar permisos de notificación
  Future<bool> requestPermissions() async {
    try {
      // Permisos para Android
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? grantedAndroid =
            await androidPlugin.requestNotificationsPermission();
        if (grantedAndroid == true) {
          debugPrint('📢 Permisos Android concedidos');
        }
      }

      // Permisos para iOS
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final bool? grantediOS = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: false,
        );
        if (grantediOS == true) {
          debugPrint('📢 Permisos iOS concedidos');
        }
      }

      _hasPermissions = true;
      return true;
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
      _hasPermissions = false;
      return false;
    }
  }

  /// Verificar permisos actuales
  Future<bool> checkPermissions() async {
    try {
      // Verificar permisos Android
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? hasAndroidPermission =
            await androidPlugin.areNotificationsEnabled();
        if (hasAndroidPermission == false) {
          debugPrint('⚠️ Permisos Android denegados');
          return false;
        }
      }

      // Para iOS, asumimos que están concedidos si no hay error
      _hasPermissions = true;
      return true;
    } catch (e) {
      debugPrint('❌ Error verificando permisos: $e');
      return false;
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
    if (!_isInitialized || !_hasPermissions) {
      debugPrint('⚠️ PlatformNotifications no inicializado o sin permisos');
      return;
    }

    try {
      // Convertir DateTime a TZDateTime
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.from(scheduledTime, tz.local);

      // Configuración Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'scheduled_notifications',
        'Notificaciones Programadas',
        channelDescription:
            'Notificaciones programadas para eventos específicos',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_notification',
        color: Color(0xFF4ECDC4),
        enableVibration: true,
        playSound: true,
      );

      // Configuración iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Programar notificación
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('📢 Notificación programada: $title para $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error programando notificación: $e');
    }
  }

  /// Cancelar notificación programada
  Future<void> cancelScheduledNotification(int id) async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('📢 Notificación programada cancelada: ID $id');
    } catch (e) {
      debugPrint('❌ Error cancelando notificación programada: $e');
    }
  }

  /// Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];

    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pendingNotifications;
    } catch (e) {
      debugPrint('❌ Error obteniendo notificaciones pendientes: $e');
      return [];
    }
  }

  /// Crear notificación con configuración avanzada
  Future<void> showAdvancedNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
    String? icon,
    Color? color,
    List<AndroidNotificationAction>? actions,
    String? sound,
    bool? vibration,
    bool? ongoing,
    bool? autoCancel,
  }) async {
    if (!_isInitialized || !_hasPermissions) return;

    try {
      // Configuración Android avanzada
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: _getImportance(channelId),
        priority: _getPriority(channelId),
        icon: icon ?? '@drawable/ic_notification',
        color: color ?? const Color(0xFF4ECDC4),
        enableVibration: vibration ?? true,
        playSound: sound != null,
        sound:
            sound != null ? RawResourceAndroidNotificationSound(sound) : null,
        actions: actions,
        ongoing: ongoing ?? false,
        autoCancel: autoCancel ?? true,
      );

      // Configuración iOS avanzada
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: sound != null ? '$sound.wav' : null,
        categoryIdentifier: _getiOSCategory(channelId),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostrar notificación
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('📢 Notificación avanzada mostrada: $title');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación avanzada: $e');
    }
  }

  /// Mostrar notificación periódica
  Future<void> showPeriodicNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String channelId = 'reminders',
    String? payload,
  }) async {
    if (!_isInitialized || !_hasPermissions) return;

    try {
      // Configuración Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'reminders',
        'Recordatorios Periódicos',
        channelDescription: 'Recordatorios que se repiten automáticamente',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_notification',
        color: Color(0xFF4ECDC4),
      );

      // Configuración iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'REMINDER_CATEGORY',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Programar notificación periódica
      await _flutterLocalNotificationsPlugin.periodicallyShow(
        id,
        title,
        body,
        repeatInterval,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('📢 Notificación periódica programada: $title');
    } catch (e) {
      debugPrint('❌ Error programando notificación periódica: $e');
    }
  }

  /// Obtener configuración de canal
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'attendance_tracking':
        return 'Seguimiento de Asistencia';
      case 'geofence_alerts':
        return 'Alertas de Geofence';
      case 'grace_period':
        return 'Período de Gracia';
      case 'system_alerts':
        return 'Alertas del Sistema';
      case 'reminders':
        return 'Recordatorios';
      case 'scheduled_notifications':
        return 'Notificaciones Programadas';
      case 'background_tasks':
        return 'Tareas en Segundo Plano';
      default:
        return 'Notificaciones';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'attendance_tracking':
        return 'Notificaciones sobre el estado del seguimiento de asistencia';
      case 'geofence_alerts':
        return 'Notificaciones cuando entras o sales del área de asistencia';
      case 'grace_period':
        return 'Alertas durante el período de gracia antes de marcar ausencia';
      case 'system_alerts':
        return 'Alertas importantes sobre el funcionamiento del sistema';
      case 'reminders':
        return 'Recordatorios sobre eventos y asistencia próximos';
      case 'scheduled_notifications':
        return 'Notificaciones programadas para eventos específicos';
      case 'background_tasks':
        return 'Notificaciones de tareas ejecutándose en segundo plano';
      default:
        return 'Notificaciones generales';
    }
  }

  Importance _getImportance(String channelId) {
    switch (channelId) {
      case 'system_alerts':
        return Importance.max;
      case 'geofence_alerts':
      case 'grace_period':
        return Importance.high;
      case 'reminders':
      case 'scheduled_notifications':
        return Importance.defaultImportance;
      case 'attendance_tracking':
      case 'background_tasks':
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _getPriority(String channelId) {
    switch (channelId) {
      case 'system_alerts':
        return Priority.max;
      case 'geofence_alerts':
      case 'grace_period':
        return Priority.high;
      case 'reminders':
      case 'scheduled_notifications':
        return Priority.defaultPriority;
      case 'attendance_tracking':
      case 'background_tasks':
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  String _getiOSCategory(String channelId) {
    switch (channelId) {
      case 'geofence_alerts':
        return 'GEOFENCE_CATEGORY';
      case 'grace_period':
        return 'GRACE_PERIOD_CATEGORY';
      case 'system_alerts':
        return 'ERROR_CATEGORY';
      case 'reminders':
        return 'REMINDER_CATEGORY';
      case 'attendance_tracking':
        return 'TRACKING_CATEGORY';
      case 'scheduled_notifications':
        return 'EVENT_CATEGORY';
      case 'background_tasks':
        return 'BACKGROUND_CATEGORY';
      default:
        return 'DEFAULT_CATEGORY';
    }
  }

  /// Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('📢 Todas las notificaciones limpiadas');
    } catch (e) {
      debugPrint('❌ Error limpiando notificaciones: $e');
    }
  }

  /// Verificar estado de inicialización
  bool get isInitialized => _isInitialized;

  /// Verificar permisos
  bool get hasPermissions => _hasPermissions;

  /// Obtener estadísticas de notificaciones
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      final activeNotifications =
          await _flutterLocalNotificationsPlugin.getActiveNotifications();

      return {
        'isInitialized': _isInitialized,
        'hasPermissions': _hasPermissions,
        'pendingCount': pendingNotifications.length,
        'activeCount': activeNotifications.length,
        'supportedFeatures': {
          'scheduling': true,
          'actions': true,
          'sounds': true,
          'vibration': true,
          'icons': true,
        },
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return {
        'isInitialized': _isInitialized,
        'hasPermissions': _hasPermissions,
        'error': e.toString(),
      };
    }
  }

  /// Verificar configuración de canal
  Future<bool> isChannelEnabled(String channelId) async {
    try {
      // En Android, verificar si el canal está habilitado
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Verificar configuración del canal (simulado)
        return true; // En implementación real, verificar canal específico
      }

      return true; // Para iOS, asumir habilitado
    } catch (e) {
      debugPrint('❌ Error verificando canal $channelId: $e');
      return false;
    }
  }

  /// Reinicializar servicio
  Future<void> reset() async {
    try {
      _isInitialized = false;
      _hasPermissions = false;
      await initialize();
      await requestPermissions();
      debugPrint('📢 PlatformNotifications reinicializado');
    } catch (e) {
      debugPrint('❌ Error reinicializando PlatformNotifications: $e');
      rethrow;
    }
  }

  /// Health check del servicio
  Future<Map<String, dynamic>> healthCheck() async {
    final Map<String, dynamic> health = {
      'service': 'PlatformNotifications',
      'status': 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
      'checks': <String, dynamic>{},
    };

    try {
      // Verificar inicialización
      health['checks']['initialization'] = _isInitialized ? 'passed' : 'failed';

      // Verificar permisos
      final hasPerms = await checkPermissions();
      health['checks']['permissions'] = hasPerms ? 'passed' : 'failed';

      // Verificar notificaciones pendientes
      final pending = await getPendingNotifications();
      health['checks']['pending_notifications'] = {
        'status': 'passed',
        'count': pending.length,
      };

      // Estado general
      final allPassed = _isInitialized && hasPerms;
      health['status'] = allPassed ? 'healthy' : 'degraded';

      debugPrint('📊 Health check completado: ${health['status']}');
    } catch (e) {
      health['status'] = 'unhealthy';
      health['error'] = e.toString();
      debugPrint('❌ Health check falló: $e');
    }

    return health;
  }
}
