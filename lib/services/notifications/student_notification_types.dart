// lib/services/notifications/student_notification_types.dart
// 🔔 TIPOS Y CONFIGURACIONES ESPECÍFICAS PARA NOTIFICACIONES DE ESTUDIANTES
import 'package:flutter/services.dart';
import '../../models/student_notification_model.dart';

/// Factory para crear notificaciones específicas de estudiantes
class StudentNotificationFactory {
  /// 🎯 NOTIFICACIONES DE EVENTOS DEL PROFESOR

  static StudentNotification eventStarted({
    required String eventTitle,
    required String eventId,
    String? professorName,
  }) {
    return StudentNotification.local(
      type: StudentNotificationType.eventStarted,
      message: professorName != null
          ? '$professorName ha iniciado "$eventTitle"'
          : 'El evento "$eventTitle" ha comenzado',
      priority: NotificationPriority.high,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 8),
      actionButtonText: 'Unirse',
    );
  }

  static StudentNotification breakStarted({
    required String eventTitle,
    required String eventId,
    int? breakDurationMinutes,
  }) {
    final durationText =
        breakDurationMinutes != null ? ' (${breakDurationMinutes} min)' : '';

    return StudentNotification.local(
      type: StudentNotificationType.breakStarted,
      message: 'Receso iniciado en "$eventTitle"$durationText. '
          'Puedes salir del área temporalmente',
      priority: NotificationPriority.high,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 6),
    );
  }

  static StudentNotification breakEnded({
    required String eventTitle,
    required String eventId,
  }) {
    return StudentNotification.local(
      type: StudentNotificationType.breakEnded,
      message: 'Receso terminado en "$eventTitle". '
          'Regresa al área del evento para continuar',
      priority: NotificationPriority.high,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 6),
      actionButtonText: 'Verificar Ubicación',
    );
  }

  static StudentNotification eventFinalized({
    required String eventTitle,
    required String eventId,
    bool attendanceRegistered = false,
  }) {
    final attendanceText = attendanceRegistered
        ? 'Tu asistencia fue registrada exitosamente.'
        : 'Verifica tu asistencia en el historial.';

    return StudentNotification.local(
      type: StudentNotificationType.eventFinalized,
      message: 'El evento "$eventTitle" ha finalizado. $attendanceText',
      priority: NotificationPriority.high,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 10),
      actionButtonText: 'Ver Historial',
    );
  }

  static StudentNotification professorAnnouncement({
    required String message,
    required String eventTitle,
    required String eventId,
    String? professorName,
  }) {
    final prefix = professorName != null
        ? 'Anuncio de $professorName: '
        : 'Anuncio del profesor: ';

    return StudentNotification.local(
      type: StudentNotificationType.professorAnnouncement,
      message: '$prefix$message',
      priority: NotificationPriority.high,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 12),
      isPersistent: true,
    );
  }

  /// 📍 NOTIFICACIONES DE GEOFENCE/UBICACIÓN

  static StudentNotification joinedEvent({
    required String eventTitle,
    required String eventId,
  }) {
    return StudentNotification.local(
      type: StudentNotificationType.joinedEvent,
      message: 'Te has unido exitosamente a "$eventTitle". '
          'El tracking de asistencia está activo',
      priority: NotificationPriority.normal,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 5),
    );
  }

  static StudentNotification enteredArea({
    required String eventTitle,
    required String eventId,
    double? accuracy,
  }) {
    final accuracyText =
        accuracy != null ? ' (precisión: ${accuracy.toStringAsFixed(1)}m)' : '';

    return StudentNotification.local(
      type: StudentNotificationType.enteredArea,
      message: 'Has entrado al área de "$eventTitle"$accuracyText. '
          'Tu asistencia está siendo registrada',
      priority: NotificationPriority.normal,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 4),
    );
  }

  static StudentNotification exitedArea({
    required String eventTitle,
    required String eventId,
    int? gracePeriodSeconds,
  }) {
    final graceText = gracePeriodSeconds != null
        ? ' Tienes ${gracePeriodSeconds}s para regresar'
        : ' Regresa pronto al área';

    return StudentNotification.local(
      type: StudentNotificationType.exitedArea,
      message: '⚠️ Has salido del área de "$eventTitle".$graceText '
          'o tu asistencia podría verse afectada',
      priority: NotificationPriority.high,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 8),
      actionButtonText: 'Verificar Ubicación',
    );
  }

  /// 💓 NOTIFICACIONES DE ESTADO/TRACKING

  static StudentNotification trackingActive({
    required String eventTitle,
    required String eventId,
  }) {
    return StudentNotification.local(
      type: StudentNotificationType.trackingActive,
      message: 'Tracking activo para "$eventTitle". '
          'Mantén la app abierta durante el evento',
      priority: NotificationPriority.normal,
      eventId: eventId,
      eventTitle: eventTitle,
      isPersistent: true,
    );
  }

  static StudentNotification attendanceRegistered({
    required String eventTitle,
    required String eventId,
    DateTime? registrationTime,
  }) {
    final timeText = registrationTime != null
        ? ' a las ${registrationTime.hour.toString().padLeft(2, '0')}:'
            '${registrationTime.minute.toString().padLeft(2, '0')}'
        : '';

    return StudentNotification.local(
      type: StudentNotificationType.attendanceRegistered,
      message: '✅ Tu asistencia a "$eventTitle" ha sido registrada$timeText',
      priority: NotificationPriority.normal,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 5),
    );
  }

  /// 🚨 NOTIFICACIONES DE ADVERTENCIA/ERROR

  static StudentNotification connectivityLost({
    String? eventTitle,
    String? eventId,
    int? retryAttempts,
  }) {
    final eventText = eventTitle != null ? ' durante "$eventTitle"' : '';
    final retryText = retryAttempts != null ? ' (intento $retryAttempts)' : '';

    return StudentNotification.local(
      type: StudentNotificationType.connectivityLost,
      message: '🚨 Conectividad perdida$eventText$retryText. '
          'Verificando conexión automáticamente...',
      priority: NotificationPriority.critical,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 10),
      actionButtonText: 'Reintentar',
    );
  }

  static StudentNotification appClosedWarning({
    required String eventTitle,
    required String eventId,
    required int secondsRemaining,
  }) {
    return StudentNotification.local(
      type: StudentNotificationType.appClosedWarning,
      message: '🚨 REABRE LA APP YA - ${secondsRemaining}s restantes '
          'o perderás la asistencia a "$eventTitle"',
      priority: NotificationPriority.critical,
      eventId: eventId,
      eventTitle: eventTitle,
      isPersistent: true,
      actionButtonText: 'Abrir App',
    );
  }

  /// ℹ️ NOTIFICACIONES INFORMATIVAS

  static StudentNotification eventAvailable({
    required String eventTitle,
    required String eventId,
    String? professorName,
    DateTime? startTime,
  }) {
    final professorText = professorName != null ? ' de $professorName' : '';
    final timeText = startTime != null
        ? ' (inicia a las ${startTime.hour.toString().padLeft(2, '0')}:'
            '${startTime.minute.toString().padLeft(2, '0')})'
        : '';

    return StudentNotification.local(
      type: StudentNotificationType.eventAvailable,
      message: 'Nuevo evento disponible: "$eventTitle"$professorText$timeText',
      priority: NotificationPriority.normal,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 8),
      actionButtonText: 'Ver Evento',
    );
  }

  static StudentNotification eventUpdated({
    required String eventTitle,
    required String eventId,
    required String updateType, // 'time', 'location', 'details'
  }) {
    final updateText = _getUpdateText(updateType);

    return StudentNotification.local(
      type: StudentNotificationType.eventUpdated,
      message: 'El evento "$eventTitle" ha sido actualizado: $updateText',
      priority: NotificationPriority.normal,
      eventId: eventId,
      eventTitle: eventTitle,
      autoCloseDelay: const Duration(seconds: 6),
      actionButtonText: 'Ver Cambios',
    );
  }

  /// Helper para obtener texto de actualización
  static String _getUpdateText(String updateType) {
    switch (updateType.toLowerCase()) {
      case 'time':
        return 'cambio de horario';
      case 'location':
        return 'cambio de ubicación';
      case 'details':
        return 'actualización de detalles';
      case 'capacity':
        return 'cambio de capacidad';
      case 'requirements':
        return 'nuevos requisitos';
      default:
        return 'información actualizada';
    }
  }
}

/// Configurador de vibraciones específicas para estudiantes
class StudentNotificationVibration {
  /// Patrones de vibración por tipo de notificación
  static const Map<StudentNotificationType, List<int>> vibrationPatterns = {
    // Eventos del profesor - Patrones distintivos
    StudentNotificationType.eventStarted: [0, 100, 50, 100, 50, 200],
    StudentNotificationType.breakStarted: [0, 200, 100, 200],
    StudentNotificationType.breakEnded: [0, 100, 50, 100, 50, 100],
    StudentNotificationType.eventFinalized: [0, 300, 100, 150],
    StudentNotificationType.professorAnnouncement: [0, 150, 75, 150, 75, 150],

    // Geofence - Patrones suaves
    StudentNotificationType.enteredArea: [0, 50, 25, 50],
    StudentNotificationType.exitedArea: [0, 200, 100, 200, 100],
    StudentNotificationType.joinedEvent: [0, 100, 50, 100],

    // Tracking - Patrones informativos
    StudentNotificationType.trackingActive: [0, 75],
    StudentNotificationType.attendanceRegistered: [0, 50, 25, 50, 25, 50],

    // Críticas - Patrones intensos
    StudentNotificationType.appClosedWarning: [0, 300, 100, 300, 100, 300],
    StudentNotificationType.connectivityLost: [0, 500, 200, 500],

    // Informativas - Patrones ligeros
    StudentNotificationType.eventAvailable: [0, 100],
    StudentNotificationType.eventUpdated: [0, 75, 50, 75],
  };

  /// Obtener patrón de vibración para un tipo
  static List<int> getPatternForType(StudentNotificationType type) {
    return vibrationPatterns[type] ?? [0, 100];
  }

  /// Ejecutar vibración para una notificación
  static Future<void> vibrateForNotification(
      StudentNotification notification) async {
    try {
      if (!notification.isCritical) {
        // Para notificaciones normales, vibración ligera
        await HapticFeedback.lightImpact();
      } else {
        // Para notificaciones críticas, vibración intensa
        await HapticFeedback.heavyImpact();

        // Vibración adicional personalizada si está disponible
        final pattern = getPatternForType(notification.type);
        await _executeVibrationPattern(pattern);
      }
    } catch (e) {
      // Fallback en caso de error
      await HapticFeedback.selectionClick();
    }
  }

  /// Ejecutar patrón de vibración personalizado
  static Future<void> _executeVibrationPattern(List<int> pattern) async {
    try {
      // En Android se puede usar SystemSound.vibration
      // pero en Flutter básico usamos HapticFeedback
      for (int i = 0; i < pattern.length; i += 2) {
        if (i + 1 < pattern.length) {
          final delay = pattern[i];
          final duration = pattern[i + 1];

          if (delay > 0) {
            await Future.delayed(Duration(milliseconds: delay));
          }

          if (duration > 0) {
            await HapticFeedback.mediumImpact();
            await Future.delayed(Duration(milliseconds: duration));
          }
        }
      }
    } catch (e) {
      // Fallback silencioso
    }
  }
}

/// Configurador de sonidos para notificaciones (placeholder para futuras implementaciones)
class StudentNotificationSound {
  /// Tipos de sonidos por notificación
  static const Map<StudentNotificationType, String> soundFiles = {
    StudentNotificationType.eventStarted: 'event_start.mp3',
    StudentNotificationType.breakStarted: 'break_start.mp3',
    StudentNotificationType.breakEnded: 'break_end.mp3',
    StudentNotificationType.appClosedWarning: 'critical_warning.mp3',
    StudentNotificationType.connectivityLost: 'connection_lost.mp3',
    // ... más sonidos según necesidad
  };

  /// Reproducir sonido para notificación (placeholder)
  static Future<void> playSound(StudentNotification notification) async {
    // Implementación futura con package de audio
    // Por ahora usar SystemSound básico
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silencioso en caso de error
    }
  }

  /// Verificar si el sonido está habilitado
  static bool isSoundEnabled() {
    // Implementación futura con SharedPreferences
    return true; // Por ahora siempre habilitado
  }
}

/// Helper para formatear mensajes de notificación
class NotificationMessageFormatter {
  /// Formatear mensaje para mostrar en diferentes contextos
  static String formatForContext(
    StudentNotification notification,
    NotificationContext context,
  ) {
    switch (context) {
      case NotificationContext.overlay:
        return _formatForOverlay(notification);
      case NotificationContext.list:
        return _formatForList(notification);
      case NotificationContext.banner:
        return _formatForBanner(notification);
      case NotificationContext.push:
        return _formatForPush(notification);
    }
  }

  static String _formatForOverlay(StudentNotification notification) {
    // Formato para overlay flotante - más conciso
    return notification.message.length > 80
        ? '${notification.message.substring(0, 77)}...'
        : notification.message;
  }

  static String _formatForList(StudentNotification notification) {
    // Formato para lista - incluir contexto de tiempo
    return '${notification.formattedTime} - ${notification.message}';
  }

  static String _formatForBanner(StudentNotification notification) {
    // Formato para banner - muy conciso
    return notification.message.length > 50
        ? '${notification.message.substring(0, 47)}...'
        : notification.message;
  }

  static String _formatForPush(StudentNotification notification) {
    // Formato para notificación push del sistema
    final eventText =
        notification.eventTitle != null ? ' (${notification.eventTitle})' : '';
    return '${notification.title}$eventText: ${notification.message}';
  }
}

/// Contextos donde se muestran las notificaciones
enum NotificationContext {
  overlay, // Overlay flotante en la app
  list, // Lista de notificaciones
  banner, // Banner superior
  push, // Notificación push del sistema
}
