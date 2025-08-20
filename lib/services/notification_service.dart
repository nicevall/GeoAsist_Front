// lib/services/notification_service.dart
// 🔄 WRAPPER MIGRATED - Este servicio ahora delega al NotificationManager unificado
// ✅ FASE 1.2: Sistema de notificaciones unificado - Wrapper de compatibilidad
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'notifications/notification_manager.dart';

/// Wrapper de compatibilidad que delega al NotificationManager unificado
/// DEPRECATED: Use NotificationManager directly for new implementations
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 🎯 DELEGACIÓN AL NOTIFICATION MANAGER UNIFICADO
  final NotificationManager _notificationManager = NotificationManager();

  // Estado interno para compatibilidad
  bool _isInitialized = false;
  final Map<String, DateTime> _lastNotificationTimes = {};

  /// Inicializar el servicio de notificaciones - DELEGADO
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.initialize();
      _isInitialized = true;
      debugPrint('📢 NotificationService (wrapper) inicializado - delegando a NotificationManager');
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationService wrapper: $e');
      rethrow;
    }
  }

  /// Notificación persistente de evento activo - DELEGADO
  Future<void> showEventActiveNotification({
    required String eventName,
    required String eventId,
  }) async {
    try {
      debugPrint('📢 [WRAPPER] Delegando evento activo: $eventName');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showEventStartedNotification(eventName);
      await _notificationManager.showTrackingActiveNotification();
      
      await _triggerHapticFeedback('light');
      _logNotification('event_active', 'Evento $eventName iniciado - Tracking activo');
    } catch (e) {
      debugPrint('❌ Error en showEventActiveNotification wrapper: $e');
    }
  }

  /// Alerta inmediata de entrada al geofence - DELEGADO
  Future<void> showGeofenceEnteredNotification({
    required String eventName,
  }) async {
    if (_shouldThrottleNotification('geofence_entered', seconds: 10)) return;

    try {
      debugPrint('📢 [WRAPPER] Delegando entrada al geofence: $eventName');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showGeofenceEnteredNotification(eventName);
      
      await _triggerHapticFeedback('medium');
      _logNotification('geofence_entered', '✅ Llegaste al área de $eventName');
    } catch (e) {
      debugPrint('❌ Error en showGeofenceEnteredNotification wrapper: $e');
    }
  }

  /// Alerta inmediata de salida del geofence - DELEGADO
  Future<void> showGeofenceExitedNotification({
    required String eventName,
    double? distance,
  }) async {
    if (_shouldThrottleNotification('geofence_exited', seconds: 15)) return;

    try {
      final distanceText = distance != null
          ? ' (${distance.toStringAsFixed(0)}m del evento)'
          : '';

      debugPrint('📢 [WRAPPER] Delegando salida del geofence: $eventName$distanceText');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showGeofenceExitedNotification(eventName);
      
      await _triggerHapticFeedback('heavy');
      _logNotification('geofence_exited', '⚠️ Saliste del área de $eventName$distanceText');
    } catch (e) {
      debugPrint('❌ Error en showGeofenceExitedNotification wrapper: $e');
    }
  }

  /// Notificación crítica de período de gracia iniciado - DELEGADO
  Future<void> showGracePeriodStartedNotification({
    required int remainingSeconds,
  }) async {
    try {
      debugPrint('📢 [WRAPPER] Delegando período de gracia iniciado: ${remainingSeconds}s');

      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showGracePeriodStartedNotification(
        remainingSeconds: remainingSeconds,
      );

      await _triggerHapticFeedback('heavy');
      await Future.delayed(const Duration(milliseconds: 200));
      await _triggerHapticFeedback('heavy');

      _logNotification('grace_period_started',
          '⏰ Período de gracia: ${remainingSeconds}s para regresar');
    } catch (e) {
      debugPrint('❌ Error en showGracePeriodStartedNotification wrapper: $e');
    }
  }

  /// Notificación crítica de período de gracia expirado - DELEGADO
  Future<void> showGracePeriodExpiredNotification() async {
    try {
      debugPrint('📢 [WRAPPER] Delegando período de gracia expirado');

      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showGracePeriodExpiredNotification();

      // Vibración háptica crítica
      for (int i = 0; i < 3; i++) {
        await _triggerHapticFeedback('heavy');
        await Future.delayed(const Duration(milliseconds: 150));
      }

      _logNotification('grace_period_expired',
          '❌ Tiempo agotado - Regresa al evento lo antes posible');
    } catch (e) {
      debugPrint('❌ Error en showGracePeriodExpiredNotification wrapper: $e');
    }
  }

  /// Confirmación de asistencia registrada - DELEGADO
  Future<void> showAttendanceRegisteredNotification({
    required String eventName,
  }) async {
    try {
      debugPrint('📢 [WRAPPER] Delegando asistencia registrada: $eventName');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showAttendanceRegisteredNotification();
      
      await _triggerHapticFeedback('selection');
      _logNotification('attendance_registered', '✅ Asistencia registrada en $eventName');
    } catch (e) {
      debugPrint('❌ Error en showAttendanceRegisteredNotification wrapper: $e');
    }
  }

  /// Notificación de tracking pausado durante receso - DELEGADO
  Future<void> showTrackingPausedNotification() async {
    try {
      debugPrint('📢 [WRAPPER] Delegando tracking pausado');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showBreakStartedNotification();
      
      await _triggerHapticFeedback('light');
      _logNotification('tracking_paused', '⏸️ Tracking pausado - Disfruta tu receso');
    } catch (e) {
      debugPrint('❌ Error en showTrackingPausedNotification wrapper: $e');
    }
  }

  /// Notificación de tracking reanudado después de receso - DELEGADO
  Future<void> showTrackingResumedNotification() async {
    try {
      debugPrint('📢 [WRAPPER] Delegando tracking reanudado');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.showBreakEndedNotification();
      await _notificationManager.showTrackingResumedNotification();
      
      await _triggerHapticFeedback('medium');
      _logNotification('tracking_resumed', '▶️ Tracking reanudado - Regresa al evento');
    } catch (e) {
      debugPrint('❌ Error en showTrackingResumedNotification wrapper: $e');
    }
  }

  /// Limpiar todas las notificaciones al finalizar evento - DELEGADO
  Future<void> clearAllNotifications() async {
    try {
      debugPrint('🧹 [WRAPPER] Delegando limpieza de notificaciones');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      await _notificationManager.clearAllNotifications();
      
      _lastNotificationTimes.clear();
    } catch (e) {
      debugPrint('❌ Error en clearAllNotifications wrapper: $e');
    }
  }

  /// Cancelar notificación específica por ID - DELEGADO
  Future<void> cancelNotification(String notificationId) async {
    try {
      debugPrint('🗑️ [WRAPPER] Delegando cancelación: $notificationId');
      
      // ✅ DELEGAR AL NOTIFICATION MANAGER
      final notificationIdInt = int.tryParse(notificationId) ?? 0;
      await _notificationManager.cancelNotification(notificationIdInt);
      
      _lastNotificationTimes.remove(notificationId);
    } catch (e) {
      debugPrint('❌ Error cancelando notificación wrapper: $e');
    }
  }

  /// Log interno de notificaciones (para debugging) - CORREGIDO
  void _logNotification(String type, String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugPrint('📢 [$timestamp] $type: $message');
  }

  /// Verificar si se debe hacer throttling de la notificación
  bool _shouldThrottleNotification(String type, {required int seconds}) {
    final now = DateTime.now();
    final lastTime = _lastNotificationTimes[type];

    if (lastTime != null && now.difference(lastTime).inSeconds < seconds) {
      return true; // Throttle - no mostrar
    }

    _lastNotificationTimes[type] = now;
    return false; // No throttle - mostrar
  }

  /// Método interno: vibración háptica
  Future<void> _triggerHapticFeedback(String type) async {
    try {
      switch (type.toLowerCase()) {
        case 'light':
          await HapticFeedback.lightImpact();
          break;
        case 'medium':
          await HapticFeedback.mediumImpact();
          break;
        case 'heavy':
          await HapticFeedback.heavyImpact();
          break;
        case 'selection':
          await HapticFeedback.selectionClick();
          break;
        default:
          await HapticFeedback.lightImpact();
      }
      debugPrint('🔊 Vibración háptica ejecutada: $type');
    } catch (e) {
      debugPrint('❌ Error en vibración háptica: $e');
    }
  }

  /// Dispose de recursos - WRAPPER
  void dispose() {
    _lastNotificationTimes.clear();
    debugPrint('🧹 NotificationService (wrapper) disposed');
    // Nota: No disposamos el NotificationManager ya que puede ser usado por otros servicios
  }

  /// Verificar si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtener estadísticas de notificaciones (para debugging) - WRAPPER + DELEGADO
  Map<String, dynamic> getNotificationStats() {
    final managerStatus = _notificationManager.getNotificationStatus();
    return {
      'wrapper_initialized': _isInitialized,
      'manager_initialized': managerStatus['initialized'],
      'lastNotificationTimes': _lastNotificationTimes,
      'manager_status': managerStatus,
      'delegation_note': 'This service is now a compatibility wrapper for NotificationManager',
    };
  }
}
