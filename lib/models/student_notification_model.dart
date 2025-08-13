// lib/models/student_notification_model.dart
// 🔔 MODELO PARA NOTIFICACIONES DE ESTUDIANTES
import 'package:flutter/material.dart';

/// Tipos de notificaciones para estudiantes
enum StudentNotificationType {
  // 🎯 NOTIFICACIONES DE EVENTOS DEL PROFESOR
  eventStarted(
      'event_started', 'Evento Iniciado', Icons.play_circle_fill, Colors.green),
  breakStarted('break_started', 'Receso Iniciado', Icons.pause_circle_filled,
      Colors.orange),
  breakEnded(
      'break_ended', 'Receso Terminado', Icons.play_circle_fill, Colors.blue),
  eventFinalized(
      'event_finalized', 'Evento Finalizado', Icons.stop_circle, Colors.red),
  professorAnnouncement('professor_announcement', 'Anuncio del Profesor',
      Icons.campaign, Colors.purple),

  // 📍 NOTIFICACIONES DE GEOFENCE/UBICACIÓN
  joinedEvent(
      'joined_event', 'Unido al Evento', Icons.check_circle, Colors.green),
  enteredArea(
      'entered_area', 'Entraste al Área', Icons.location_on, Colors.green),
  exitedArea('exited_area', 'Saliste del Área', Icons.location_off, Colors.red),

  // 💓 NOTIFICACIONES DE ESTADO/TRACKING
  trackingActive(
      'tracking_active', 'Tracking Activo', Icons.my_location, Colors.blue),
  attendanceRegistered('attendance_registered', 'Asistencia Registrada',
      Icons.check, Colors.green),

  // 🚨 NOTIFICACIONES DE ADVERTENCIA/ERROR
  connectivityLost(
      'connectivity_lost', 'Conectividad Perdida', Icons.wifi_off, Colors.red),
  appClosedWarning('app_closed_warning', 'App Cerrada - Reabre Ya',
      Icons.warning, Colors.red),

  // ℹ️ NOTIFICACIONES INFORMATIVAS
  eventAvailable(
      'event_available', 'Nuevo Evento Disponible', Icons.event, Colors.blue),
  eventUpdated(
      'event_updated', 'Evento Actualizado', Icons.update, Colors.orange);

  const StudentNotificationType(this.key, this.title, this.icon, this.color);

  final String key;
  final String title;
  final IconData icon;
  final Color color;

  /// Obtener tipo por clave
  static StudentNotificationType? fromKey(String key) {
    for (final type in StudentNotificationType.values) {
      if (type.key == key) return type;
    }
    return null;
  }
}

/// Prioridad de las notificaciones
enum NotificationPriority {
  low(1, 'Baja'),
  normal(2, 'Normal'),
  high(3, 'Alta'),
  critical(4, 'Crítica');

  const NotificationPriority(this.level, this.label);

  final int level;
  final String label;
}

/// Modelo para notificaciones de estudiantes
class StudentNotification {
  final String id;
  final StudentNotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? eventId;
  final String? eventTitle;
  final Map<String, dynamic>? additionalData;
  final bool isRead;
  final bool isPersistent;
  final Duration? autoCloseDelay;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;

  const StudentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.priority = NotificationPriority.normal,
    required this.timestamp,
    this.eventId,
    this.eventTitle,
    this.additionalData,
    this.isRead = false,
    this.isPersistent = false,
    this.autoCloseDelay,
    this.actionButtonText,
    this.onActionPressed,
  });

  /// Factory constructor para crear desde WebSocket
  factory StudentNotification.fromWebSocket(Map<String, dynamic> data) {
    final typeKey = data['type'] as String? ?? 'unknown';
    final type = StudentNotificationType.fromKey(typeKey) ??
        StudentNotificationType.professorAnnouncement;

    return StudentNotification(
      id: data['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: data['title'] as String? ?? type.title,
      message: data['message'] as String? ?? 'Sin mensaje',
      priority: _parsePriority(data['priority'] as String?),
      timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ??
          DateTime.now(),
      eventId: data['eventId'] as String?,
      eventTitle: data['eventTitle'] as String?,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
      isPersistent: data['persistent'] as bool? ?? false,
      autoCloseDelay: _parseDelay(data['autoCloseSeconds'] as int?),
    );
  }

  /// Factory constructor para crear notificación local
  factory StudentNotification.local({
    required StudentNotificationType type,
    required String message,
    String? customTitle,
    NotificationPriority priority = NotificationPriority.normal,
    String? eventId,
    String? eventTitle,
    bool isPersistent = false,
    Duration? autoCloseDelay,
    String? actionButtonText,
    VoidCallback? onActionPressed,
  }) {
    return StudentNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: customTitle ?? type.title,
      message: message,
      priority: priority,
      timestamp: DateTime.now(),
      eventId: eventId,
      eventTitle: eventTitle,
      isPersistent: isPersistent,
      autoCloseDelay: autoCloseDelay,
      actionButtonText: actionButtonText,
      onActionPressed: onActionPressed,
    );
  }

  /// Crear copia con cambios
  StudentNotification copyWith({
    String? id,
    StudentNotificationType? type,
    String? title,
    String? message,
    NotificationPriority? priority,
    DateTime? timestamp,
    String? eventId,
    String? eventTitle,
    Map<String, dynamic>? additionalData,
    bool? isRead,
    bool? isPersistent,
    Duration? autoCloseDelay,
    String? actionButtonText,
    VoidCallback? onActionPressed,
  }) {
    return StudentNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      additionalData: additionalData ?? this.additionalData,
      isRead: isRead ?? this.isRead,
      isPersistent: isPersistent ?? this.isPersistent,
      autoCloseDelay: autoCloseDelay ?? this.autoCloseDelay,
      actionButtonText: actionButtonText ?? this.actionButtonText,
      onActionPressed: onActionPressed ?? this.onActionPressed,
    );
  }

  /// Convertir a JSON para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.key,
      'title': title,
      'message': message,
      'priority': priority.label,
      'timestamp': timestamp.toIso8601String(),
      'eventId': eventId,
      'eventTitle': eventTitle,
      'additionalData': additionalData,
      'isRead': isRead,
      'isPersistent': isPersistent,
      'autoCloseSeconds': autoCloseDelay?.inSeconds,
      'actionButtonText': actionButtonText,
    };
  }

  /// Crear desde JSON almacenado
  factory StudentNotification.fromJson(Map<String, dynamic> json) {
    final type =
        StudentNotificationType.fromKey(json['type'] as String? ?? '') ??
            StudentNotificationType.professorAnnouncement;

    return StudentNotification(
      id: json['id'] as String? ?? '',
      type: type,
      title: json['title'] as String? ?? type.title,
      message: json['message'] as String? ?? '',
      priority: _parsePriority(json['priority'] as String?),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      eventId: json['eventId'] as String?,
      eventTitle: json['eventTitle'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      isPersistent: json['isPersistent'] as bool? ?? false,
      autoCloseDelay: _parseDelay(json['autoCloseSeconds'] as int?),
      actionButtonText: json['actionButtonText'] as String?,
    );
  }

  /// Helper para parsear prioridad
  static NotificationPriority _parsePriority(String? priorityStr) {
    switch (priorityStr?.toLowerCase()) {
      case 'low':
      case 'baja':
        return NotificationPriority.low;
      case 'high':
      case 'alta':
        return NotificationPriority.high;
      case 'critical':
      case 'crítica':
        return NotificationPriority.critical;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Helper para parsear delay
  static Duration? _parseDelay(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }

  /// Verificar si es una notificación crítica
  bool get isCritical =>
      priority == NotificationPriority.critical ||
      type == StudentNotificationType.appClosedWarning ||
      type == StudentNotificationType.connectivityLost;

  /// Verificar si requiere acción del usuario
  bool get requiresAction =>
      type == StudentNotificationType.appClosedWarning ||
      type == StudentNotificationType.exitedArea ||
      actionButtonText != null;

  /// Obtener color para la UI
  Color get displayColor => type.color;

  /// Obtener icono para la UI
  IconData get displayIcon => type.icon;

  /// Obtener descripción del evento si está disponible
  String get eventDescription {
    if (eventTitle != null) {
      return 'Evento: $eventTitle';
    } else if (eventId != null) {
      return 'Evento ID: $eventId';
    }
    return '';
  }

  /// Tiempo transcurrido desde la notificación
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  /// Formatear timestamp para display
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'StudentNotification(id: $id, type: ${type.key}, title: $title, '
        'message: $message, priority: ${priority.label}, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class para manejar configuraciones de notificaciones
class NotificationConfig {
  static const Duration defaultAutoCloseDelay = Duration(seconds: 5);
  static const Duration criticalAutoCloseDelay = Duration(seconds: 10);
  static const Duration persistentCheckInterval = Duration(seconds: 30);

  /// Configuraciones por tipo de notificación
  static Map<StudentNotificationType, NotificationSettings> get typeSettings =>
      {
        // Eventos del profesor - Alta prioridad, auto-close lento
        StudentNotificationType.eventStarted: const NotificationSettings(
          priority: NotificationPriority.high,
          autoCloseDelay: Duration(seconds: 8),
          showInOverlay: true,
          vibrationPattern: [100, 50, 100],
        ),

        StudentNotificationType.breakStarted: const NotificationSettings(
          priority: NotificationPriority.high,
          autoCloseDelay: Duration(seconds: 6),
          showInOverlay: true,
          vibrationPattern: [200, 100, 200],
        ),

        StudentNotificationType.breakEnded: const NotificationSettings(
          priority: NotificationPriority.high,
          autoCloseDelay: Duration(seconds: 6),
          showInOverlay: true,
          vibrationPattern: [100, 50, 100, 50, 100],
        ),

        // Notificaciones críticas - Prioridad crítica, persistente
        StudentNotificationType.appClosedWarning: const NotificationSettings(
          priority: NotificationPriority.critical,
          isPersistent: true,
          showInOverlay: true,
          vibrationPattern: [300, 100, 300, 100, 300],
        ),

        StudentNotificationType.connectivityLost: const NotificationSettings(
          priority: NotificationPriority.critical,
          autoCloseDelay: Duration(seconds: 10),
          showInOverlay: true,
          vibrationPattern: [500, 200, 500],
        ),

        // Geofence - Normal, auto-close rápido
        StudentNotificationType.enteredArea: const NotificationSettings(
          priority: NotificationPriority.normal,
          autoCloseDelay: Duration(seconds: 4),
          vibrationPattern: [50, 50, 50],
        ),

        StudentNotificationType.exitedArea: const NotificationSettings(
          priority: NotificationPriority.high,
          autoCloseDelay: Duration(seconds: 8),
          showInOverlay: true,
          vibrationPattern: [200, 100, 200, 100],
        ),
      };

  /// Obtener configuración para un tipo específico
  static NotificationSettings getSettingsForType(StudentNotificationType type) {
    return typeSettings[type] ?? const NotificationSettings();
  }
}

/// Configuraciones específicas para tipos de notificación
class NotificationSettings {
  final NotificationPriority priority;
  final Duration? autoCloseDelay;
  final bool isPersistent;
  final bool showInOverlay;
  final List<int> vibrationPattern;
  final bool playSound;

  const NotificationSettings({
    this.priority = NotificationPriority.normal,
    this.autoCloseDelay = const Duration(seconds: 5),
    this.isPersistent = false,
    this.showInOverlay = false,
    this.vibrationPattern = const [100],
    this.playSound = true,
  });
}
