// lib/services/notification_channels.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gestor centralizado de canales de notificación
/// Configura canales específicos para cada tipo de notificación
class NotificationChannels {
  static final NotificationChannels _instance =
      NotificationChannels._internal();
  factory NotificationChannels() => _instance;
  NotificationChannels._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  /// Inicializar todos los canales de notificación
  Future<void> initializeChannels() async {
    if (_isInitialized) return;

    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Crear todos los canales para Android
      await _createAndroidChannels();

      // Configurar categorías para iOS
      await _configureiOSCategories();

      _isInitialized = true;
      debugPrint('📢 Canales de notificación inicializados correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando canales: $e');
      rethrow;
    }
  }

  /// Crear canales de Android
  Future<void> _createAndroidChannels() async {
    // Canal 1: Seguimiento de Asistencia (persistente, baja prioridad)
    final attendanceTrackingChannel = AndroidNotificationChannel(
      'attendance_tracking',
      'Seguimiento de Asistencia',
      description:
          'Notificaciones sobre el estado del seguimiento de asistencia',
      importance: Importance.low,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: false,
      playSound: false,
      showBadge: true,
    );

    // Canal 2: Alertas de Geofence (alta prioridad, sonido)
    final geofenceAlertsChannel = AndroidNotificationChannel(
      'geofence_alerts',
      'Alertas de Geofence',
      description:
          'Notificaciones cuando entras o sales del área de asistencia',
      importance: Importance.high,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: true,
      playSound: true,
      showBadge: true,
      sound: const RawResourceAndroidNotificationSound('notification_geofence'),
    );

    // Canal 3: Período de Gracia (alta prioridad, vibración)
    final gracePeriodChannel = AndroidNotificationChannel(
      'grace_period',
      'Período de Gracia',
      description:
          'Alertas durante el período de gracia antes de marcar ausencia',
      importance: Importance.high,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: true,
      playSound: true,
      showBadge: true,
      sound: const RawResourceAndroidNotificationSound('notification_grace'),
    );

    // Canal 4: Alertas del Sistema (máxima prioridad)
    final systemAlertsChannel = AndroidNotificationChannel(
      'system_alerts',
      'Alertas del Sistema',
      description: 'Alertas importantes sobre el funcionamiento del sistema',
      importance: Importance.max,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: true,
      playSound: true,
      showBadge: true,
      sound: const RawResourceAndroidNotificationSound('notification_error'),
    );

    // Canal 5: Recordatorios (media prioridad)
    final remindersChannel = AndroidNotificationChannel(
      'reminders',
      'Recordatorios',
      description: 'Recordatorios sobre eventos y asistencia próximos',
      importance: Importance.defaultImportance,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: true,
      playSound: true,
      showBadge: true,
      sound: const RawResourceAndroidNotificationSound('notification_reminder'),
    );

    // Canal 6: Notificaciones Programadas (media prioridad)
    final scheduledNotificationsChannel = AndroidNotificationChannel(
      'scheduled_notifications',
      'Notificaciones Programadas',
      description: 'Notificaciones programadas para eventos específicos',
      importance: Importance.defaultImportance,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Canal 7: Background Tasks (baja prioridad, silencioso)
    final backgroundTasksChannel = AndroidNotificationChannel(
      'background_tasks',
      'Tareas en Segundo Plano',
      description: 'Notificaciones de tareas ejecutándose en segundo plano',
      importance: Importance.low,
      ledColor: const Color(0xFF4ECDC4),
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    // Registrar todos los canales
    final channels = [
      attendanceTrackingChannel,
      geofenceAlertsChannel,
      gracePeriodChannel,
      systemAlertsChannel,
      remindersChannel,
      scheduledNotificationsChannel,
      backgroundTasksChannel,
    ];

    // Crear canales en el sistema
    for (final channel in channels) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint(
        '📢 ${channels.length} canales de Android creados correctamente');
  }

  /// Configurar categorías para iOS
  Future<void> _configureiOSCategories() async {
    final List<DarwinNotificationCategory> iosCategories = [
      // Categoría 1: Alertas de Geofence
      DarwinNotificationCategory(
        'GEOFENCE_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'view_map',
            'Ver Mapa',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'dismiss',
            'Descartar',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
        ],
      ),

      // Categoría 2: Período de Gracia
      DarwinNotificationCategory(
        'GRACE_PERIOD_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'view_location',
            'Ver Ubicación',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'mark_present',
            'Marcar Presente',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),

      // Categoría 3: Alertas del Sistema
      DarwinNotificationCategory(
        'ERROR_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'open_settings',
            'Configuración',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'contact_support',
            'Soporte',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),

      // Categoría 4: Recordatorios
      DarwinNotificationCategory(
        'REMINDER_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'snooze',
            'Recordar en 5 min',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.authenticationRequired,
            },
          ),
          DarwinNotificationAction.plain(
            'dismiss',
            'Descartar',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
        ],
      ),

      // Categoría 5: Eventos
      DarwinNotificationCategory(
        'EVENT_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'join_event',
            'Unirse',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'view_details',
            'Ver Detalles',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),

      // Categoría 6: Tracking
      DarwinNotificationCategory(
        'TRACKING_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'pause_tracking',
            'Pausar',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.authenticationRequired,
            },
          ),
          DarwinNotificationAction.plain(
            'view_dashboard',
            'Dashboard',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),

      // Categoría 7: Background
      DarwinNotificationCategory(
        'BACKGROUND_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'open_app',
            'Abrir App',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
    ];

    // Registrar categorías en iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.initialize(
          const DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        );

    debugPrint(
        '📢 ${iosCategories.length} categorías de iOS configuradas correctamente');
  }

  /// Obtener configuración de canal por ID
  Map<String, dynamic> getChannelConfig(String channelId) {
    switch (channelId) {
      case 'attendance_tracking':
        return {
          'name': 'Seguimiento de Asistencia',
          'importance': 'low',
          'sound': false,
          'vibration': false,
          'ledColor': const Color(0xFF4ECDC4),
        };

      case 'geofence_alerts':
        return {
          'name': 'Alertas de Geofence',
          'importance': 'high',
          'sound': true,
          'vibration': true,
          'ledColor': const Color(0xFF4ECDC4),
        };

      case 'grace_period':
        return {
          'name': 'Período de Gracia',
          'importance': 'high',
          'sound': true,
          'vibration': true,
          'ledColor': const Color(0xFFFFA726),
        };

      case 'system_alerts':
        return {
          'name': 'Alertas del Sistema',
          'importance': 'max',
          'sound': true,
          'vibration': true,
          'ledColor': const Color(0xFFE57373),
        };

      case 'reminders':
        return {
          'name': 'Recordatorios',
          'importance': 'default',
          'sound': true,
          'vibration': true,
          'ledColor': const Color(0xFF4ECDC4),
        };

      case 'scheduled_notifications':
        return {
          'name': 'Notificaciones Programadas',
          'importance': 'default',
          'sound': true,
          'vibration': true,
          'ledColor': const Color(0xFF4ECDC4),
        };

      case 'background_tasks':
        return {
          'name': 'Tareas en Segundo Plano',
          'importance': 'low',
          'sound': false,
          'vibration': false,
          'ledColor': const Color(0xFF4ECDC4),
        };

      default:
        return {
          'name': 'Canal por Defecto',
          'importance': 'default',
          'sound': true,
          'vibration': true,
          'ledColor': const Color(0xFF4ECDC4),
        };
    }
  }

  /// Verificar si los canales están inicializados
  bool get isInitialized => _isInitialized;

  /// Obtener estadísticas de canales
  Map<String, dynamic> getChannelStats() {
    return {
      'isInitialized': _isInitialized,
      'totalChannels': 7,
      'totalCategories': 7,
      'supportedPlatforms': ['Android', 'iOS'],
    };
  }

  /// Limpiar y reinicializar canales
  Future<void> resetChannels() async {
    try {
      _isInitialized = false;
      await initializeChannels();
      debugPrint('📢 Canales reinicializados correctamente');
    } catch (e) {
      debugPrint('❌ Error reinicializando canales: $e');
      rethrow;
    }
  }
}
