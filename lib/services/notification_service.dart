// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio completo de notificaciones contextuales
/// Maneja notificaciones específicas por contexto de asistencia
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Estado interno
  bool _isInitialized = false;
  final Map<String, DateTime> _lastNotificationTimes = {};

  // TODO: En futuras versiones integrar con flutter_local_notifications

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: Configurar flutter_local_notifications cuando sea necesario
      _isInitialized = true;
      debugPrint('📢 NotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationService: $e');
    }
  }

  /// Notificación persistente de evento activo
  Future<void> showEventActiveNotification({
    required String eventName,
    required String eventId,
  }) async {
    try {
      debugPrint('📢 Mostrando notificación: Evento $eventName activo');

      // Vibración háptica suave para evento iniciado
      await _triggerHapticFeedback('light');

      // TODO: Mostrar notificación persistente
      _logNotification(
          'event_active', 'Evento $eventName iniciado - Tracking activo');
    } catch (e) {
      debugPrint('❌ Error en showEventActiveNotification: $e');
    }
  }

  /// Alerta inmediata de entrada al geofence
  Future<void> showGeofenceEnteredNotification({
    required String eventName,
  }) async {
    if (_shouldThrottleNotification('geofence_entered', seconds: 10)) return;

    try {
      debugPrint('📢 Entrada al geofence: $eventName');

      // Vibración háptica de éxito
      await _triggerHapticFeedback('medium');

      // TODO: Notificación con sonido personalizado
      _logNotification('geofence_entered', '✅ Llegaste al área de $eventName');
    } catch (e) {
      debugPrint('❌ Error en showGeofenceEnteredNotification: $e');
    }
  }

  /// Alerta inmediata de salida del geofence
  Future<void> showGeofenceExitedNotification({
    required String eventName,
    double? distance,
  }) async {
    if (_shouldThrottleNotification('geofence_exited', seconds: 15)) return;

    try {
      final distanceText = distance != null
          ? ' (${distance.toStringAsFixed(0)}m del evento)'
          : '';

      debugPrint('📢 Salida del geofence: $eventName$distanceText');

      // Vibración háptica de advertencia
      await _triggerHapticFeedback('heavy');

      _logNotification(
          'geofence_exited', '⚠️ Saliste del área de $eventName$distanceText');
    } catch (e) {
      debugPrint('❌ Error en showGeofenceExitedNotification: $e');
    }
  }

  /// Notificación crítica de período de gracia iniciado
  Future<void> showGracePeriodStartedNotification({
    required int remainingSeconds,
  }) async {
    try {
      debugPrint(
          '📢 Período de gracia iniciado: ${remainingSeconds}s restantes');

      // Vibración háptica doble para urgencia
      await _triggerHapticFeedback('heavy');
      await Future.delayed(const Duration(milliseconds: 200));
      await _triggerHapticFeedback('heavy');

      _logNotification('grace_period_started',
          '⏰ Período de gracia: ${remainingSeconds}s para regresar');
    } catch (e) {
      debugPrint('❌ Error en showGracePeriodStartedNotification: $e');
    }
  }

  /// Notificación crítica de período de gracia expirado
  Future<void> showGracePeriodExpiredNotification() async {
    try {
      debugPrint('📢 Período de gracia expirado');

      // Vibración háptica crítica
      for (int i = 0; i < 3; i++) {
        await _triggerHapticFeedback('heavy');
        await Future.delayed(const Duration(milliseconds: 150));
      }

      _logNotification('grace_period_expired',
          '❌ Tiempo agotado - Regresa al evento lo antes posible');
    } catch (e) {
      debugPrint('❌ Error en showGracePeriodExpiredNotification: $e');
    }
  }

  /// Confirmación de asistencia registrada
  Future<void> showAttendanceRegisteredNotification({
    required String eventName,
  }) async {
    try {
      debugPrint('📢 Asistencia registrada para: $eventName');

      // Vibración de confirmación exitosa
      await _triggerHapticFeedback('selection');

      _logNotification(
          'attendance_registered', '✅ Asistencia registrada en $eventName');
    } catch (e) {
      debugPrint('❌ Error en showAttendanceRegisteredNotification: $e');
    }
  }

  /// Notificación de tracking pausado durante receso
  Future<void> showTrackingPausedNotification() async {
    try {
      debugPrint('📢 Tracking pausado - Receso activo');

      await _triggerHapticFeedback('light');

      _logNotification(
          'tracking_paused', '⏸️ Tracking pausado - Disfruta tu receso');
    } catch (e) {
      debugPrint('❌ Error en showTrackingPausedNotification: $e');
    }
  }

  /// Notificación de tracking reanudado después de receso
  Future<void> showTrackingResumedNotification() async {
    try {
      debugPrint('📢 Tracking reanudado - Receso terminado');

      await _triggerHapticFeedback('medium');

      _logNotification(
          'tracking_resumed', '▶️ Tracking reanudado - Regresa al evento');
    } catch (e) {
      debugPrint('❌ Error en showTrackingResumedNotification: $e');
    }
  }

  /// Limpiar todas las notificaciones al finalizar evento
  Future<void> clearAllNotifications() async {
    try {
      // TODO: Implementar cancelación de todas las notificaciones
      debugPrint('🧹 Limpiando todas las notificaciones');
      _lastNotificationTimes.clear();
    } catch (e) {
      debugPrint('❌ Error en clearAllNotifications: $e');
    }
  }

  /// Cancelar notificación específica por ID
  Future<void> cancelNotification(String notificationId) async {
    try {
      // TODO: Integrar con flutter_local_notifications
      debugPrint('🗑️ Cancelando notificación: $notificationId');
      _lastNotificationTimes.remove(notificationId);
    } catch (e) {
      debugPrint('❌ Error cancelando notificación: $e');
    }
  }

  /// Log interno de notificaciones (para debugging)
  void _logNotification(String type, String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugPrint('📢 [$timestamp] $type: $message');
    debugPrint('📢 [$timestamp] $type: $message');
    debugPrint('📢 [$timestamp] $type: $message');
    debugPrint('📢 [$timestamp] $type: $message');
    debugPrint('📢 [$timestamp] $type: $message');
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

  /// Configurar tipos de notificación personalizados
  Future<void> _setupNotificationChannels() async {
    // TODO: Implementar canales de notificación cuando se integre flutter_local_notifications
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    // TODO: Verificar permisos cuando se integre flutter_local_notifications
    return true;
  }

  /// Solicitar permisos de notificación
  Future<bool> requestNotificationPermissions() async {
    // TODO: Solicitar permisos cuando se integre flutter_local_notifications
    return true;
  }

  /// Dispose de recursos
  void dispose() {
    _lastNotificationTimes.clear();
    debugPrint('🧹 NotificationService disposed');
  }
}
