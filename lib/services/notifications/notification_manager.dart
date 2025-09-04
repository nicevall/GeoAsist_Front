// lib/services/notifications/notification_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/student_notification_model.dart';

/// Sistema de notificaciones inteligente y sincronizado con WebSocket
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
  static const int _connectionErrorId = 1009;
  static const int _attendanceLostId = 1010;
  static const int _eventEndedId = 1011;
  static const int _backgroundTrackingId = 1012;
  static const int _trackingResumedId = 1013;

  // 🎯 PLUGIN DE NOTIFICACIONES
  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;
  
  // ✅ CONTROL INTELIGENTE DE DUPLICADAS
  final Set<String> _sentNotifications = <String>{};
  Timer? _notificationCleanupTimer;

  /// Inicializar el sistema de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Inicializando NotificationManager');

      _notifications = FlutterLocalNotificationsPlugin();

      await _configureNotificationChannels();
      await _requestPermissions();
      
      // ✅ INICIAR CLEANUP DE NOTIFICACIONES
      _startNotificationCleanup();

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
  
  /// ✅ NUEVO: Iniciar cleanup automático de notificaciones
  void _startNotificationCleanup() {
    _notificationCleanupTimer?.cancel();
    _notificationCleanupTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _cleanupSentNotifications(),
    );
  }
  
  /// ✅ NUEVO: Método inteligente para evitar duplicadas
  Future<void> _showNotificationSafe({
    required int id,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final notificationKey = '$type:$title:$body';
    
    // Evitar duplicadas en los últimos 5 minutos
    if (_sentNotifications.contains(notificationKey)) {
      debugPrint('⚠️ Notificación duplicada evitada: $title');
      return;
    }
    
    _sentNotifications.add(notificationKey);
    
    await _showNotification(id, title, body, type, data);
    
    // Auto-limpiar después de 5 minutos
    Timer(const Duration(minutes: 5), () {
      _sentNotifications.remove(notificationKey);
    });
  }
  
  /// ✅ NUEVO: Método auxiliar para mostrar notificación
  Future<void> _showNotification(int id, String title, String body, String type, Map<String, dynamic>? data) async {
    try {
      AndroidNotificationDetails? androidDetails;
      DarwinNotificationDetails? iosDetails;
      
      switch (type) {
        case 'attendance_success':
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Asistencia Registrada',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: const Color(0xFF27AE60),
            icon: '@drawable/ic_success',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound: 'success.aiff',
          );
          break;
          
        case 'geofence_violation':
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Violación de Área',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: const Color(0xFFF39C12),
            icon: '@drawable/ic_warning',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound: 'warning.aiff',
          );
          break;
          
        case 'event_status_change':
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Estado de Evento',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
            enableVibration: true,
            color: const Color(0xFF3498DB),
            icon: '@drawable/ic_info',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          );
          break;
          
        default:
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Notificaciones Generales',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: false,
          );
      }
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(id, title, body, details);
      
    } catch (e) {
      debugPrint('❌ Error mostrando notificación: $e');
    }
  }
  
  void _cleanupSentNotifications() {
    _sentNotifications.clear();
    debugPrint('🧹 Cache de notificaciones limpiado');
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

  // ✅ NUEVO DÍA 4: Notificación de background tracking normal (SIN penalización)
  Future<void> showBackgroundTrackingNotification() async {
    try {
      debugPrint('📱 Mostrando notificación - Background tracking normal');

      await _showAlertNotification(
        _backgroundTrackingId,
        '📱 Tracking en Background',
        'Tu asistencia sigue activa. Usa tu teléfono normalmente.',
        'info',
        autoCloseAfter: 3000, // Auto-close en 3 segundos
      );

      // Vibración suave para confirmar
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ Error notificación background tracking: $e');
    }
  }

  // ✅ NUEVO DÍA 4: Notificación cuando se reanuda después de grace period
  Future<void> showTrackingResumedNotification() async {
    try {
      debugPrint('✅ Mostrando notificación - Tracking reanudado');

      await _showAlertNotification(
        _trackingResumedId,
        '✅ Tracking Reactivado',
        'Tu asistencia se mantiene segura. ¡Bien hecho!',
        'success',
        autoCloseAfter: 4000, // Auto-close en 4 segundos
      );

      // Vibración de confirmación (doble)
      await HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ Error notificación tracking reanudado: $e');
    }
  }

  // 🎯 NOTIFICACIONES DE GEOFENCE

  /// Notificación al entrar al geofence
  Future<void> showGeofenceEnteredNotification(String eventName) async {
    try {
      debugPrint('✅ Mostrando notificación - Entraste al área');

      await _showAlertNotification(
        _geofenceEnteredId,
        '✅ Entraste al Área',
        'Área de "$eventName" detectada. Ya puedes registrar asistencia.',
        'success',
        autoCloseAfter: 5000,
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
      debugPrint('⚠️ Mostrando notificación - Saliste del área');

      await _showAlertNotification(
        _geofenceExitedId,
        '⚠️ Saliste del Área',
        'Has salido del área de "$eventName". ¡Regresa pronto!',
        'warning',
        autoCloseAfter: 0, // No auto-close, importante que lo vean
      );

      // Vibración de warning
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('❌ Error notificación geofence salida: $e');
    }
  }

  // ✅ NUEVO DÍA 4: Notificación de evento iniciado
  Future<void> showEventStartedNotification(String eventName) async {
    try {
      debugPrint('🎯 Mostrando notificación - Evento iniciado');

      await _showAlertNotification(
        _eventStartedId,
        '🎯 Evento Iniciado',
        '"$eventName" ha comenzado. Únete ahora para registrar asistencia.',
        'info',
        autoCloseAfter: 8000,
      );

      // Vibración informativa
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('❌ Error notificación evento iniciado: $e');
    }
  }

  // 🎯 NOTIFICACIONES DE EVENTOS

  /// ✅ NUEVO: Notificación de evento finalizado
  Future<void> showEventEndedNotification(String eventId) async {
    try {
      debugPrint('📢 Mostrando notificación: Evento Finalizado');

      await _notifications.show(
        _eventEndedId,
        '🏁 Evento Finalizado',
        'El evento ha terminado. Gracias por participar.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alerts',
            'Alertas Críticas',
            channelDescription: 'Notificaciones importantes del sistema',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 100, 100, 100, 100, 100]),
            playSound: true,
          ),
        ),
      );

      // Vibración háptica diferenciada
      HapticFeedback.lightImpact();

      debugPrint('✅ Notificación "Evento Finalizado" mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación evento finalizado: $e');
    }
  }

  /// Notificación cuando inicia un receso
  Future<void> showBreakStartedNotification([String? eventId]) async {
    try {
      debugPrint('📢 Mostrando notificación: Receso Iniciado');

      await _notifications.show(
        _breakStartedId,
        '⏸️ Receso Iniciado',
        'El profesor ha iniciado un receso. Puedes salir del área temporalmente.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alerts',
            'Alertas Críticas',
            channelDescription: 'Notificaciones importantes del sistema',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
            playSound: true,
          ),
        ),
      );

      // Vibración háptica diferenciada
      HapticFeedback.mediumImpact();

      debugPrint('✅ Notificación "Receso Iniciado" mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación receso iniciado: $e');
    }
  }

  /// Notificación cuando termina un receso
  Future<void> showBreakEndedNotification([String? eventId]) async {
    try {
      debugPrint('📢 Mostrando notificación: Receso Terminado');

      await _notifications.show(
        _breakEndedId, // ID único para receso terminado
        '▶️ Receso Terminado',
        'El receso ha terminado. Regresa al área del evento para continuar con tu asistencia.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alerts',
            'Alertas Críticas',
            channelDescription: 'Notificaciones importantes del sistema',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 150, 50, 150, 50, 150]),
            playSound: true,
          ),
        ),
      );

      // Vibración háptica diferenciada
      HapticFeedback.heavyImpact();

      debugPrint('✅ Notificación "Receso Terminado" mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación receso terminado: $e');
    }
  }

  // 🎯 NOTIFICACIONES DE ASISTENCIA

  /// Notificación cuando se registra asistencia (método legado)
  Future<void> showAttendanceRegisteredNotificationLegacy() async {
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

  // 🎯 NOTIFICACIONES DE GRACE PERIOD

  /// Notificación crítica de período de gracia iniciado
  Future<void> showGracePeriodStartedNotification({
    required int remainingSeconds,
    String? eventName,
  }) async {
    try {
      debugPrint('⏰ Mostrando notificación - Período de gracia iniciado: ${remainingSeconds}s');

      await _showAlertNotification(
        1020, // ID único para grace period started
        '⏰ Período de Gracia Iniciado',
        'Tienes $remainingSeconds segundos para regresar al área del evento.',
        'warning',
        autoCloseAfter: 0, // No auto-close para alertas críticas
      );

      // Vibración háptica doble para urgencia
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ Error notificación período de gracia iniciado: $e');
    }
  }

  /// Notificación crítica de período de gracia expirado
  Future<void> showGracePeriodExpiredNotification({
    String? eventName,
  }) async {
    try {
      debugPrint('🚨 Mostrando notificación - Período de gracia expirado');

      await _showAlertNotification(
        1021, // ID único para grace period expired
        '🚨 Período de Gracia Expirado',
        'El tiempo ha terminado. Regresa al evento lo antes posible o tu asistencia se verá afectada.',
        'error',
        autoCloseAfter: 0, // No auto-close para alertas críticas
      );

      // Vibración háptica crítica (triple)
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      debugPrint('❌ Error notificación período de gracia expirado: $e');
    }
  }

  // 🎯 NOTIFICACIONES CRÍTICAS DE APP LIFECYCLE

  /// Advertencia crítica cuando la app se cierra
  Future<void> showAppClosedWarningNotification(int secondsRemaining) async {
    try {
      debugPrint(
          '🚨 Mostrando advertencia crítica - App cerrada ($secondsRemaining s)');

      // Diferentes niveles de urgencia según el tiempo restante
      final bool isUrgent = secondsRemaining <= 10;
      final bool isCritical = secondsRemaining <= 5;

      String title;
      String body;
      AndroidNotificationDetails androidDetails;

      if (isCritical) {
        title = '🚨 CRÍTICO - ${secondsRemaining}s';
        body = '¡REABRE GEOASIST AHORA O PERDERÁS TU ASISTENCIA!';
        androidDetails = const AndroidNotificationDetails(
          _alertsChannelId,
          'Alertas Críticas',
          importance: Importance.max,
          priority: Priority.max,
          ongoing: false,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          ticker: 'CRÍTICO: Reabre la app YA',
          sound: RawResourceAndroidNotificationSound('alarm_critical'),
        );
      } else if (isUrgent) {
        title = '⚠️ URGENTE - ${secondsRemaining}s';
        body =
            'Reabre GeoAsist en $secondsRemaining segundos o perderás tu asistencia';
        androidDetails = const AndroidNotificationDetails(
          _alertsChannelId,
          'Alertas Urgentes',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
          ticker: 'Reabre la app urgente',
        );
      } else {
        title = '📱 Reabre GeoAsist - ${secondsRemaining}s';
        body = 'Tienes $secondsRemaining segundos para reabrir la app';
        androidDetails = const AndroidNotificationDetails(
          _alertsChannelId,
          'Alertas de App',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        );
      }

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        sound: 'alarm_critical.aiff',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _appClosedWarningId,
        title,
        body,
        details,
      );

      // Vibración escalada según urgencia
      if (isCritical) {
        // Vibración crítica intensa (3 veces)
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
      } else if (isUrgent) {
        // Vibración urgente (2 veces)
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
      } else {
        // Vibración normal de warning
        await HapticFeedback.mediumImpact();
      }
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

  // ✅ MEJORADO DÍA 4: Método helper para mostrar alertas con auto-close
  Future<void> _showAlertNotification(
    int id,
    String title,
    String body,
    String type, {
    int autoCloseAfter =
        0, // 0 = no auto-close, >0 = milliseconds to auto-close
  }) async {
    try {
      // Configuración según tipo
      AndroidNotificationDetails androidDetails;
      Color? notificationColor;
      DarwinNotificationDetails iosDetails;

      switch (type) {
        case 'success':
          notificationColor = const Color(0xFF27AE60); // Verde
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Alertas de Éxito',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
            enableVibration: true,
            color: notificationColor,
            icon: '@drawable/ic_success',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound: 'success.aiff',
          );
          break;

        case 'warning':
          notificationColor = const Color(0xFFF39C12); // Naranja
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Alertas de Advertencia',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: notificationColor,
            icon: '@drawable/ic_warning',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound: 'warning.aiff',
          );
          break;

        case 'error':
          notificationColor = const Color(0xFFE74C3C); // Rojo
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Alertas de Error',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: notificationColor,
            icon: '@drawable/ic_error',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound: 'error.aiff',
            interruptionLevel: InterruptionLevel.active,
          );
          break;

        case 'info':
        default:
          notificationColor = const Color(0xFF3498DB); // Azul
          androidDetails = AndroidNotificationDetails(
            _alertsChannelId,
            'Alertas Informativas',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: false,
            enableVibration: false,
            color: notificationColor,
            icon: '@drawable/ic_info',
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: false,
          );
          break;
      }

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details);

      // Auto-close si se especifica
      if (autoCloseAfter > 0) {
        Timer(Duration(milliseconds: autoCloseAfter), () async {
          await cancelNotification(id);
        });
      }
    } catch (e) {
      debugPrint('❌ Error mostrando alerta ($type): $e');
    }
  }

  Map<String, dynamic> getImplementedNotifications() {
    return {
      'total_notifications': 14,
      'notifications': [
        {
          'id': _trackingNotificationId,
          'name': 'tracking_active',
          'type': 'persistent'
        },
        {'id': _geofenceEnteredId, 'name': 'geofence_entered', 'type': 'alert'},
        {'id': _geofenceExitedId, 'name': 'geofence_exited', 'type': 'alert'},
        {'id': _breakStartedId, 'name': 'break_started', 'type': 'alert'},
        {'id': _breakEndedId, 'name': 'break_ended', 'type': 'alert'},
        {
          'id': _attendanceRegisteredId,
          'name': 'attendance_registered',
          'type': 'alert'
        },
        {
          'id': _appClosedWarningId,
          'name': 'app_closed_warning',
          'type': 'critical'
        },
        {
          'id': _backgroundTrackingId,
          'name': 'background_tracking',
          'type': 'info'
        },
        {
          'id': _trackingResumedId,
          'name': 'tracking_resumed',
          'type': 'success'
        },
        {
          'id': _attendanceLostId,
          'name': 'attendance_lost',
          'type': 'critical'
        },
        {'id': _eventStartedId, 'name': 'event_started', 'type': 'info'},
        {
          'id': _connectionErrorId,
          'name': 'connection_error',
          'type': 'warning'
        },
        {
          'id': _criticalWarningId,
          'name': 'critical_lifecycle_warning',
          'type': 'critical'
        },
      ],
      'channels': [
        {'id': _trackingChannelId, 'name': 'tracking', 'importance': 'low'},
        {'id': _alertsChannelId, 'name': 'alerts', 'importance': 'high'},
      ],
    };
  }

  // ✅ NOTIFICACIONES ESPECÍFICAS SINCRONIZADAS CON WEBSOCKET
  
  /// ✅ NUEVO: Notificación inteligente de asistencia registrada
  Future<void> showAttendanceRegisteredNotification({
    String? eventName,
    String? status,
  }) async {
    await _showNotificationSafe(
      id: 1001,
      title: '✅ Asistencia Registrada',
      body: 'Tu asistencia para ${eventName ?? "el evento"} ha sido registrada como ${status ?? "presente"}',
      type: 'attendance_success',
    );
  }
  
  /// ✅ NUEVO: Notificación inteligente de violación de geofence
  Future<void> showGeofenceViolationNotification({
    required int gracePeriodSeconds,
    String? eventName,
  }) async {
    await _showNotificationSafe(
      id: 1002,
      title: '⚠️ Fuera del Área',
      body: 'Has salido del área de ${eventName ?? "el evento"}. Tienes ${gracePeriodSeconds}s para regresar.',
      type: 'geofence_violation',
    );
  }
  
  /// ✅ NUEVO: Notificación inteligente de cambio de estado de evento
  Future<void> showEventStatusChangedNotification({
    required String eventName,
    required String newStatus,
  }) async {
    String title;
    String emoji;
    
    switch (newStatus.toLowerCase()) {
      case 'en proceso':
        title = 'Evento Iniciado';
        emoji = '🚀';
        break;
      case 'finalizado':
        title = 'Evento Finalizado';
        emoji = '🏁';
        break;
      case 'cancelado':
        title = 'Evento Cancelado';
        emoji = '❌';
        break;
      default:
        title = 'Estado de Evento Cambiado';
        emoji = '📢';
    }
    
    await _showNotificationSafe(
      id: 1003,
      title: '$emoji $title',
      body: 'El evento "$eventName" ahora está $newStatus',
      type: 'event_status_change',
    );
  }
  

  Future<void> testAllNotifications() async {
    if (!kDebugMode) return; // Solo en debug mode

    debugPrint('🧪 TESTING: Probando todas las notificaciones...');

    try {
      await showTrackingActiveNotification();
      await Future.delayed(const Duration(seconds: 2));

      await showBackgroundTrackingNotification();
      await Future.delayed(const Duration(seconds: 2));

      await showGeofenceEnteredNotification('Evento de Prueba');
      await Future.delayed(const Duration(seconds: 2));

      await showGeofenceExitedNotification('Evento de Prueba');
      await Future.delayed(const Duration(seconds: 2));

      await showEventStartedNotification('Evento de Prueba');
      await Future.delayed(const Duration(seconds: 2));

      await showBreakStartedNotification();
      await Future.delayed(const Duration(seconds: 2));

      await showBreakEndedNotification();
      await Future.delayed(const Duration(seconds: 2));

      await showAttendanceRegisteredNotification();
      await Future.delayed(const Duration(seconds: 2));

      await showTrackingResumedNotification();
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('✅ TESTING: Todas las notificaciones probadas');
    } catch (e) {
      debugPrint('❌ TESTING: Error probando notificaciones: $e');
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

  Future<void> showConnectionErrorNotification() async {
    try {
      debugPrint('🔔 Mostrando notificación - Error de conexión');

      await _showAlertNotification(
        _connectionErrorId,
        'Error de Conexión',
        'Problema conectando al servidor. Verificando conexión...',
        'warning',
      );

      // Vibración de advertencia
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ Error notificación de conexión: $e');
    }
  }

  /// Notificación cuando se pierde la asistencia
  Future<void> showAttendanceLostNotification(String reason) async {
    try {
      debugPrint('❌ Mostrando notificación - Asistencia perdida');

      const androidDetails = AndroidNotificationDetails(
        _alertsChannelId,
        'Alertas Críticas',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: false,
        autoCancel: false,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.error,
        ticker: 'Asistencia perdida',
        color: Color(0xFFE74C3C), // Rojo para error
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
        _attendanceLostId,
        '❌ Asistencia Perdida',
        'Motivo: $reason. Contacta a tu profesor.',
        details,
      );

      // Vibración de error (larga)
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('❌ Error notificación asistencia perdida: $e');
    }
  }

  // 🎯 TESTING Y DEBUGGING


  Future<void> showStudentNotification(StudentNotification notification) async {
    try {
      debugPrint(
          '📱 Mostrando notificación para estudiante: ${notification.title}');

      await _showAlertNotification(
        int.tryParse(notification.id) ?? DateTime.now().millisecondsSinceEpoch,
        notification.title,
        notification.message,
        notification.type.toString().split('.').last.toLowerCase(),
      );

      debugPrint('✅ Notificación de estudiante mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de estudiante: $e');
    }
  }

  // ===========================================
  // ✅ NUEVAS NOTIFICACIONES DE ASISTENCIA AUTOMÁTICA
  // ===========================================

  /// ✅ NUEVO: Notificación de asistencia registrada automáticamente
  Future<void> showAttendanceRegisteredAutomaticallyNotification({
    required String eventName,
    required String studentName,
  }) async {
    try {
      debugPrint('✅ Mostrando notificación - Asistencia automática registrada');

      const androidDetails = AndroidNotificationDetails(
        'attendance_alerts',
        'Asistencia Registrada',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.status,
        ticker: 'Asistencia registrada automáticamente',
        color: Color(0xFF27AE60), // Verde éxito
        icon: '@drawable/ic_check',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        sound: 'success.aiff',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1010, // ID específico para asistencia automática
        '✅ ¡ASISTENCIA REGISTRADA!',
        '🎓 $studentName registrado en "$eventName" automáticamente',
        details,
      );

      // Vibración de éxito
      await HapticFeedback.mediumImpact();
      
      // Auto-close después de 5 segundos
      Timer(Duration(seconds: 5), () async {
        await cancelNotification(1010);
      });

    } catch (e) {
      debugPrint('❌ Error notificación asistencia automática: $e');
    }
  }

  /// ✅ NUEVO: Notificación de entrada al geofence con auto-registro
  Future<void> showGeofenceEnteredWithAutoRegistration(String eventName) async {
    try {
      debugPrint('🎯 Mostrando notificación - Entrada al geofence con auto-registro');

      const androidDetails = AndroidNotificationDetails(
        'geofence_alerts',
        'Área de Evento',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.status,
        ticker: 'Entraste al área del evento',
        color: Color(0xFF3498DB), // Azul información
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1011, // ID específico para entrada geofence
        '🎯 ¡Entraste al Área!',
        '📍 Área de "$eventName" - Registrando asistencia...',
        details,
      );

      // Vibración de confirmación
      await HapticFeedback.lightImpact();

    } catch (e) {
      debugPrint('❌ Error notificación entrada geofence: $e');
    }
  }

  // Backward compatibility method for showLocal
  Future<void> showLocal(String title, String body, {String? type, Map<String, dynamic>? data}) async {
    try {
      await _showNotification(
        DateTime.now().millisecondsSinceEpoch % 100000, // Dynamic ID
        title,
        body,
        type ?? 'general',
        data,
      );
    } catch (e) {
      debugPrint('❌ Error in showLocal: $e');
    }
  }

  // Método requerido por battery_optimization_service y demo_verification_service
  Future<void> showTestNotification() async {
    try {
      await _showNotification(
        9999,
        'Notificación de Prueba',
        'Esta es una notificación de prueba del sistema',
        'test',
        {'type': 'test', 'timestamp': DateTime.now().millisecondsSinceEpoch},
      );
      debugPrint('✅ Notificación de prueba mostrada correctamente');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de prueba: $e');
    }
  }

  // Método requerido por local_geofencing_service
  Future<void> showCriticalWarningNotification(String title, String body) async {
    try {
      await _showNotification(
        _criticalWarningId,
        title,
        body,
        'critical_warning',
        {'priority': 'high', 'type': 'warning'},
      );
      debugPrint('✅ Notificación crítica mostrada: $title');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación crítica: $e');
    }
  }

  // Métodos requeridos por local_notifications_only
  Future<void> showAttendanceSuccessNotification(String message) async {
    try {
      await _showNotification(
        _attendanceRegisteredId,
        'Asistencia Registrada',
        message,
        'attendance_success',
        {'type': 'success'},
      );
      debugPrint('✅ Notificación de éxito de asistencia mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de asistencia: $e');
    }
  }

  Future<void> showLocationErrorNotification(String error) async {
    try {
      await _showNotification(
        _connectionErrorId,
        'Error de Ubicación',
        error,
        'location_error',
        {'type': 'error'},
      );
      debugPrint('✅ Notificación de error de ubicación mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de error de ubicación: $e');
    }
  }

  // ✅ NUEVO: Notificación para inicio de evento pre-registrado
  Future<void> showEventStartNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      debugPrint('📢 Mostrando notificación de inicio de evento: $title');

      const androidDetails = AndroidNotificationDetails(
        'event_start_channel',
        'Inicio de Eventos',
        channelDescription: 'Notificaciones cuando un evento pre-registrado está por comenzar',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.event,
        ticker: 'Evento por comenzar',
        color: Color(0xFFE67E22), // Naranja
        icon: '@drawable/ic_event',
        actions: [
          AndroidNotificationAction(
            'join_event',
            'UNIRSE AL EVENTO',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_location'),
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'event_start',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      // Vibración personalizada para evento
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.mediumImpact();

      debugPrint('✅ Notificación de evento mostrada con ID: $id');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de evento: $e');
    }
  }

  /// ✅ NUEVO: Notificación persistente para asistencia activa
  /// Esta notificación se mantiene visible mientras el usuario tiene una sesión de asistencia activa
  Future<void> showPersistentAttendanceNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      debugPrint('🔔 Mostrando notificación persistente de asistencia con ID: $id');

      const androidDetails = AndroidNotificationDetails(
        'attendance_tracking',
        'Tracking de Asistencia',
        channelDescription: 'Notificación persistente para tracking activo de asistencia',
        importance: Importance.low, // Baja importancia para no molestar
        priority: Priority.low,
        ongoing: true, // ✅ CLAVE: Hace que la notificación sea persistente
        autoCancel: false, // No se cancela automáticamente
        playSound: false, // No reproducir sonido
        enableVibration: false, // No vibrar
        showWhen: true,
        usesChronometer: true, // Mostrar cronómetro
        chronometerCountDown: false,
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public,
        ticker: 'Asistencia activa',
        color: Color(0xFF1ABC9C), // Verde teal
        icon: '@drawable/ic_tracking',
        actions: [
          AndroidNotificationAction(
            'open_app',
            'ABRIR APP',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_open'),
            cancelNotification: false, // No cancelar al hacer click
          ),
          AndroidNotificationAction(
            'pause_tracking',
            'PAUSAR',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_pause'),
            cancelNotification: false,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false, // No mostrar alert en iOS para persistente
        presentBadge: true,
        presentSound: false,
        categoryIdentifier: 'attendance_tracking',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('✅ Notificación persistente de asistencia mostrada con ID: $id');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación persistente: $e');
    }
  }


  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✅ Todas las notificaciones canceladas');
    } catch (e) {
      debugPrint('❌ Error cancelando todas las notificaciones: $e');
    }
  }

  /// ✅ NUEVO: Notificación de asistencia recuperada
  /// Se muestra cuando la app detecta una sesión activa al iniciarse
  Future<void> showAttendanceRecoveredNotification(
    String eventTitle,
    String duration,
  ) async {
    try {
      debugPrint('🔄 Mostrando notificación de asistencia recuperada');

      await _notifications.show(
        2001, // ID específico para recuperación
        '🔄 Asistencia Recuperada',
        '✅ "$eventTitle"\n⏱️ Tiempo activo: $duration\n📱 Tu seguimiento continúa automáticamente',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alerts',
            'Alertas de Asistencia',
            channelDescription: 'Alertas importantes sobre eventos y asistencia',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
            playSound: true,
            color: Color(0xFF1ABC9C), // Verde teal para recuperación
            icon: '@drawable/ic_recovery',
            category: AndroidNotificationCategory.status,
            actions: [
              AndroidNotificationAction(
                'view_status',
                'VER ESTADO',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_info'),
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'attendance_recovery',
          ),
        ),
      );

      // Vibración de confirmación
      await HapticFeedback.mediumImpact();
      
      debugPrint('✅ Notificación de recuperación mostrada para: $eventTitle');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de recuperación: $e');
    }
  }

  /// ✅ NUEVO: Notificación de inscripción exitosa al evento
  Future<void> showEventEnrollmentSuccessNotification({
    required String eventName,
  }) async {
    try {
      debugPrint('📝 Mostrando notificación - Inscripción exitosa');

      await _notifications.show(
        2002, // ID específico para inscripción
        '📝 ¡Inscripción Exitosa!',
        '✅ Te has inscrito en "$eventName"\n🔔 Recibirás una notificación 5 minutos antes del inicio',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'enrollment_alerts',
            'Inscripciones de Eventos',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: Color(0xFF27AE60), // Verde éxito
            icon: '@drawable/ic_event_available',
            category: AndroidNotificationCategory.status,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );

      await HapticFeedback.lightImpact();
      debugPrint('✅ Notificación de inscripción mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de inscripción: $e');
    }
  }

  /// ✅ NUEVO: Notificación 5 minutos antes del evento
  Future<void> showEventStartingSoonNotification({
    required String eventName,
    required int minutesLeft,
  }) async {
    try {
      debugPrint('⏰ Mostrando notificación - Evento inicia pronto');

      await _notifications.show(
        2003, // ID específico para evento próximo
        '⏰ ¡Evento Inicia Pronto!',
        '🎓 "$eventName" comenzará en $minutesLeft minutos\n📍 Asegúrate de estar en el área del evento',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders',
            'Recordatorios de Eventos',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            color: Color(0xFFF39C12), // Naranja alerta
            icon: '@drawable/ic_alarm',
            category: AndroidNotificationCategory.alarm,
            actions: [
              AndroidNotificationAction(
                'open_event',
                'IR AL EVENTO',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_location'),
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
            categoryIdentifier: 'event_reminder',
          ),
        ),
      );

      // Vibración de alerta
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      await HapticFeedback.mediumImpact();
      
      debugPrint('✅ Notificación de evento próximo mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de evento próximo: $e');
    }
  }

  /// ✅ NUEVO: Notificación de evento abandonado
  Future<void> showEventAbandonedNotification({
    required String eventName,
  }) async {
    try {
      debugPrint('🚪 Mostrando notificación - Evento abandonado');

      await _notifications.show(
        2004, // ID específico para abandono
        '🚪 Evento Abandonado',
        '❌ Has abandonado "$eventName"\n📝 Tu asistencia se registró como falta',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'event_actions',
            'Acciones de Eventos',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: Color(0xFFE67E22), // Naranja advertencia
            icon: '@drawable/ic_exit',
            category: AndroidNotificationCategory.status,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
      );

      await HapticFeedback.mediumImpact();
      debugPrint('✅ Notificación de abandono mostrada');
    } catch (e) {
      debugPrint('❌ Error mostrando notificación de abandono: $e');
    }
  }


}
