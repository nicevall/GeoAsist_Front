// lib/services/notifications/local_notifications_only.dart
// 🔔 NOTIFICACIONES QUE FUNCIONAN SIN BACKEND
import '../notifications/notification_manager.dart';

class LocalNotificationsOnly {
  static final NotificationManager _notificationManager = NotificationManager();

  /// ✅ NOTIFICACIONES QUE FUNCIONAN PERFECTAMENTE:

  // 1. Estado de presencia local
  static Future<void> showPresenceUpdate(String status, String eventName) async {
    switch (status) {
      case 'present':
        await _notificationManager.showGeofenceEnteredNotification(eventName);
        break;
      case 'absent':
        await _notificationManager.showGeofenceExitedNotification(eventName);
        break;
      case 'warning':
        await _notificationManager.showCriticalWarningNotification(
          'Advertencia',
          'Estás cerca del límite del evento $eventName'
        );
        break;
    }
  }

  // 2. Eventos locales
  static Future<void> showEventStarted(String eventName) async {
    await _notificationManager.showEventStartedNotification(eventName);
    await _notificationManager.showTrackingActiveNotification();
  }

  // 3. Asistencia registrada
  static Future<void> showAttendanceSuccess(String eventName) async {
    await _notificationManager.showAttendanceSuccessNotification('Asistencia registrada para $eventName');
  }

  // 4. Problemas técnicos
  static Future<void> showLocationError() async {
    await _notificationManager.showLocationErrorNotification('Error obteniendo la ubicación');
  }

  // 5. Grace periods (pausas)
  static Future<void> showGracePeriodStarted(int minutes) async {
    await _notificationManager.showBreakStartedNotification(
      'Período de gracia iniciado ($minutes min)'
    );
  }

  static Future<void> showGracePeriodEnded() async {
    await _notificationManager.showBreakEndedNotification();
  }

  // 6. App lifecycle
  static Future<void> showAppClosedWarning() async {
    await _notificationManager.showAppClosedWarningNotification(30);
  }

  // 7. Background tracking
  static Future<void> showBackgroundTracking(String eventName) async {
    await _notificationManager.showBackgroundTrackingNotification();
  }

  /// ❌ NOTIFICACIONES QUE NO FUNCIONAN (requieren backend):
  
  // - WebSocket del profesor
  // - Push notifications remotas  
  // - Notificaciones colaborativas
  // - Sincronización cross-device
}

/// 🎯 INTEGRACIÓN CON LOCAL PRESENCE MANAGER
class PresenceNotifications {
  
  /// Conectar LocalPresenceManager con notificaciones
  static void setupPresenceNotifications() {
    // Importar el LocalPresenceManager cuando esté listo
    // LocalPresenceManager().statusStream.listen((status) {
    //   switch (status) {
    //     case LocalPresenceStatus.present:
    //       LocalNotificationsOnly.showPresenceUpdate('present', 'Evento Actual');
    //       break;
    //     case LocalPresenceStatus.absent:
    //       LocalNotificationsOnly.showPresenceUpdate('absent', 'Evento Actual');
    //       break;
    //     case LocalPresenceStatus.warning:
    //       LocalNotificationsOnly.showPresenceUpdate('warning', 'Evento Actual');
    //       break;
    //     case LocalPresenceStatus.disconnected:
    //       LocalNotificationsOnly.showLocationError();
    //       break;
    //   }
    // });
  }
}