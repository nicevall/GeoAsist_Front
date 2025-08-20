// lib/models/teacher_notification_model.dart
// 🔔 MODELO COMPLETO DE NOTIFICACIONES PARA DOCENTES
import 'package:flutter/material.dart';

/// Prioridad de las notificaciones
enum NotificationPriority {
  low('low', 'Baja', Icons.info_outline, Colors.grey),
  normal('normal', 'Normal', Icons.notifications, Colors.blue),
  high('high', 'Alta', Icons.priority_high, Colors.orange),
  critical('critical', 'Crítica', Icons.warning, Colors.red);

  const NotificationPriority(this.id, this.name, this.icon, this.color);
  
  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

/// Tipos de notificaciones para docentes
enum TeacherNotificationType {
  // ⏰ NOTIFICACIONES TEMPORALES/PROGRAMADAS
  eventStartingSoon('event_starting_soon', 'Evento Próximo', Icons.access_time, Color(0xFFFF6B35), NotificationPriority.high),
  eventEndingSoon('event_ending_soon', 'Evento Terminando', Icons.timer_off, Color(0xFFE74C3C), NotificationPriority.high),
  eventReminder('event_reminder', 'Recordatorio', Icons.notification_important, Color(0xFF3498DB), NotificationPriority.normal),
  dayBeforeEvent('day_before_event', 'Evento Mañana', Icons.today, Color(0xFF9B59B6), NotificationPriority.normal),
  
  // 👥 ASISTENCIA EN TIEMPO REAL  
  studentJoined('student_joined', 'Estudiante Registrado', Icons.person_add, Color(0xFF27AE60), NotificationPriority.normal),
  multipleStudentsJoined('multiple_students_joined', 'Varios Estudiantes', Icons.group_add, Color(0xFF27AE60), NotificationPriority.normal),
  attendanceUpdate('attendance_update', 'Actualización Asistencia', Icons.analytics, Color(0xFF4ECDC4), NotificationPriority.normal),
  attendanceMilestone('attendance_milestone', 'Meta de Asistencia', Icons.emoji_events, Color(0xFFF39C12), NotificationPriority.normal),
  
  // 🚨 ALERTAS DE PROBLEMAS
  studentLeftArea('student_left_area', 'Estudiante Salió', Icons.location_off, Color(0xFFE67E22), NotificationPriority.high),
  multipleStudentsLeft('multiple_students_left', 'Varios Estudiantes Salieron', Icons.group_remove, Color(0xFFE74C3C), NotificationPriority.critical),
  connectivityIssues('connectivity_issues', 'Problemas Conexión', Icons.wifi_off, Color(0xFFE74C3C), NotificationPriority.high),
  lowAttendance('low_attendance', 'Asistencia Baja', Icons.trending_down, Color(0xFFE74C3C), NotificationPriority.high),
  studentInDistress('student_in_distress', 'Estudiante en Problemas', Icons.help_outline, Color(0xFFE74C3C), NotificationPriority.critical),
  
  // 🎛️ SUGERENCIAS DE GESTIÓN
  suggestBreak('suggest_break', 'Sugerir Receso', Icons.pause_circle_outline, Color(0xFF9B59B6), NotificationPriority.normal),
  studentsWaiting('students_waiting', 'Estudiantes Esperando', Icons.hourglass_empty, Color(0xFFE67E22), NotificationPriority.normal),
  remindStudents('remind_students', 'Recordar Estudiantes', Icons.campaign, Color(0xFF3498DB), NotificationPriority.normal),
  suggestEndEvent('suggest_end_event', 'Sugerir Finalizar', Icons.stop_circle, Color(0xFFE67E22), NotificationPriority.normal),
  
  // 📊 MÉTRICAS Y REPORTES  
  weeklyReport('weekly_report', 'Reporte Semanal', Icons.summarize, Color(0xFF34495E), NotificationPriority.low),
  monthlyReport('monthly_report', 'Reporte Mensual', Icons.assessment, Color(0xFF34495E), NotificationPriority.low),
  justificationsPending('justifications_pending', 'Justificaciones Pendientes', Icons.pending_actions, Color(0xFFE67E22), NotificationPriority.normal),
  reportGenerated('report_generated', 'Reporte Generado', Icons.description, Color(0xFF27AE60), NotificationPriority.low),
  
  // 🏆 RECONOCIMIENTOS Y LOGROS
  highAttendanceAchieved('high_attendance_achieved', 'Excelente Asistencia', Icons.star, Color(0xFFF39C12), NotificationPriority.normal),
  perfectAttendance('perfect_attendance', 'Asistencia Perfecta', Icons.emoji_events, Color(0xFFF39C12), NotificationPriority.normal),
  teachingMilestone('teaching_milestone', 'Hito Docente', Icons.school, Color(0xFF9B59B6), NotificationPriority.normal);

  const TeacherNotificationType(this.id, this.name, this.icon, this.color, this.priority);
  
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final NotificationPriority priority;
}

/// Modelo de notificación para docentes
class TeacherNotification {
  final String id;
  final String title;
  final String message;
  final String? subtitle;
  final TeacherNotificationType type;
  final DateTime timestamp;
  final DateTime? scheduledFor;
  final bool isRead;
  final bool isPersistent;
  final Duration? autoCloseAfter;
  final VoidCallback? onAction;
  final String? actionText;
  final Map<String, dynamic>? metadata;
  final List<int>? vibrationPattern;

  TeacherNotification({
    required this.id,
    required this.title,
    required this.message,
    this.subtitle,
    required this.type,
    DateTime? timestamp,
    this.scheduledFor,
    this.isRead = false,
    this.isPersistent = false,
    this.autoCloseAfter,
    this.onAction,
    this.actionText,
    this.metadata,
    this.vibrationPattern,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory para notificaciones de eventos próximos
  factory TeacherNotification.eventStartingSoon({
    required String eventTitle,
    required int minutesUntilStart,
    required String eventId,
    VoidCallback? onStartEvent,
  }) {
    return TeacherNotification(
      id: 'event_starting_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '📅 Evento Próximo',
      message: '"$eventTitle" inicia en $minutesUntilStart minutos',
      subtitle: 'Prepárate para comenzar la clase',
      type: TeacherNotificationType.eventStartingSoon,
      autoCloseAfter: Duration(minutes: 5),
      onAction: onStartEvent,
      actionText: 'Iniciar Ahora',
      metadata: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'minutesUntilStart': minutesUntilStart,
      },
      vibrationPattern: [0, 250, 100, 250],
    );
  }

  /// Factory para estudiante registrado
  factory TeacherNotification.studentJoined({
    required String studentName,
    required String eventTitle,
    required int currentAttendance,
    required int totalStudents,
    required String eventId,
  }) {
    final percentage = ((currentAttendance / totalStudents) * 100).round();
    
    return TeacherNotification(
      id: 'student_joined_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Estudiante Registrado',
      message: '$studentName se registró en "$eventTitle"',
      subtitle: 'Asistencia actual: $currentAttendance/$totalStudents ($percentage%)',
      type: TeacherNotificationType.studentJoined,
      autoCloseAfter: Duration(seconds: 4),
      metadata: {
        'eventId': eventId,
        'studentName': studentName,
        'currentAttendance': currentAttendance,
        'totalStudents': totalStudents,
        'percentage': percentage,
      },
      vibrationPattern: [0, 100],
    );
  }

  /// Factory para estudiante que salió del área
  factory TeacherNotification.studentLeftArea({
    required String studentName,
    required String eventTitle,
    required String eventId,
    String? timeOutside,
    VoidCallback? onContactStudent,
  }) {
    return TeacherNotification(
      id: 'student_left_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '⚠️ Estudiante Salió del Área',
      message: '$studentName salió de "$eventTitle"',
      subtitle: timeOutside != null ? 'Tiempo afuera: $timeOutside' : 'Acabó de salir del área',
      type: TeacherNotificationType.studentLeftArea,
      isPersistent: true,
      onAction: onContactStudent,
      actionText: 'Contactar',
      metadata: {
        'eventId': eventId,
        'studentName': studentName,
        'timeOutside': timeOutside,
      },
      vibrationPattern: [0, 200, 100, 200],
    );
  }

  /// Factory para actualización de asistencia
  factory TeacherNotification.attendanceUpdate({
    required String eventTitle,
    required int presentStudents,
    required int totalStudents,
    required String eventId,
    String? trend,
  }) {
    final percentage = ((presentStudents / totalStudents) * 100).round();
    final priority = percentage < 60 ? NotificationPriority.high : NotificationPriority.normal;
    
    return TeacherNotification(
      id: 'attendance_update_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '📊 Asistencia: $presentStudents/$totalStudents ($percentage%)',
      message: 'Evento: "$eventTitle"',
      subtitle: trend != null ? 'Tendencia: $trend' : null,
      type: TeacherNotificationType.attendanceUpdate,
      autoCloseAfter: Duration(seconds: 6),
      metadata: {
        'eventId': eventId,
        'presentStudents': presentStudents,
        'totalStudents': totalStudents,
        'percentage': percentage,
        'trend': trend,
      },
    );
  }

  /// Factory para sugerencia de receso
  factory TeacherNotification.suggestBreak({
    required String eventTitle,
    required String eventId,
    required int minutesRunning,
    VoidCallback? onStartBreak,
  }) {
    return TeacherNotification(
      id: 'suggest_break_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎮 ¿Iniciar Receso?',
      message: '"$eventTitle" lleva $minutesRunning minutos',
      subtitle: 'Sugerencia: receso de 15 minutos',
      type: TeacherNotificationType.suggestBreak,
      onAction: onStartBreak,
      actionText: 'Iniciar Receso',
      metadata: {
        'eventId': eventId,
        'minutesRunning': minutesRunning,
      },
    );
  }

  /// Crear copia con modificaciones
  TeacherNotification copyWith({
    String? title,
    String? message,
    String? subtitle,
    bool? isRead,
    bool? isPersistent,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return TeacherNotification(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      subtitle: subtitle ?? this.subtitle,
      type: type,
      timestamp: timestamp,
      scheduledFor: scheduledFor,
      isRead: isRead ?? this.isRead,
      isPersistent: isPersistent ?? this.isPersistent,
      autoCloseAfter: autoCloseAfter,
      onAction: onAction ?? this.onAction,
      actionText: actionText ?? this.actionText,
      metadata: metadata,
      vibrationPattern: vibrationPattern,
    );
  }

  /// Verificar si tiene acción disponible
  bool get hasAction => onAction != null && actionText != null;

  /// Verificar si la notificación está expirada
  bool get isExpired {
    if (autoCloseAfter == null) return false;
    return DateTime.now().difference(timestamp) > autoCloseAfter!;
  }

  /// Verificar si es una notificación crítica
  bool get isCritical => type.priority == NotificationPriority.critical;

  /// Verificar si es una notificación de alta prioridad
  bool get isHighPriority => 
      type.priority == NotificationPriority.high || 
      type.priority == NotificationPriority.critical;

  /// Convertir a JSON para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'subtitle': subtitle,
      'type': type.id,
      'timestamp': timestamp.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isRead': isRead,
      'isPersistent': isPersistent,
      'autoCloseAfter': autoCloseAfter?.inMilliseconds,
      'actionText': actionText,
      'metadata': metadata,
      'vibrationPattern': vibrationPattern,
    };
  }

  /// Crear desde JSON
  static TeacherNotification fromJson(Map<String, dynamic> json) {
    return TeacherNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      subtitle: json['subtitle'],
      type: TeacherNotificationType.values.firstWhere(
        (type) => type.id == json['type'],
        orElse: () => TeacherNotificationType.eventReminder,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      scheduledFor: json['scheduledFor'] != null 
          ? DateTime.parse(json['scheduledFor']) 
          : null,
      isRead: json['isRead'] ?? false,
      isPersistent: json['isPersistent'] ?? false,
      autoCloseAfter: json['autoCloseAfter'] != null 
          ? Duration(milliseconds: json['autoCloseAfter']) 
          : null,
      actionText: json['actionText'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      vibrationPattern: json['vibrationPattern']?.cast<int>(),
    );
  }

  @override
  String toString() {
    return 'TeacherNotification(id: $id, title: $title, type: ${type.name}, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeacherNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Configuración de notificaciones para docentes
class TeacherNotificationSettings {
  final bool enableEventReminders;
  final bool enableAttendanceUpdates;
  final bool enableStudentAlerts;
  final bool enableReports;
  final int reminderMinutesBefore;
  final int attendanceUpdateInterval;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final Set<TeacherNotificationType> disabledTypes;

  const TeacherNotificationSettings({
    this.enableEventReminders = true,
    this.enableAttendanceUpdates = true,
    this.enableStudentAlerts = true,
    this.enableReports = true,
    this.reminderMinutesBefore = 15,
    this.attendanceUpdateInterval = 15,
    this.vibrationEnabled = true,
    this.soundEnabled = true,
    this.disabledTypes = const {},
  });

  /// Verificar si un tipo de notificación está habilitado
  bool isTypeEnabled(TeacherNotificationType type) {
    return !disabledTypes.contains(type);
  }

  /// Configuración por defecto
  static const TeacherNotificationSettings defaultSettings = TeacherNotificationSettings();

  /// Crear copia con modificaciones
  TeacherNotificationSettings copyWith({
    bool? enableEventReminders,
    bool? enableAttendanceUpdates,
    bool? enableStudentAlerts,
    bool? enableReports,
    int? reminderMinutesBefore,
    int? attendanceUpdateInterval,
    bool? vibrationEnabled,
    bool? soundEnabled,
    Set<TeacherNotificationType>? disabledTypes,
  }) {
    return TeacherNotificationSettings(
      enableEventReminders: enableEventReminders ?? this.enableEventReminders,
      enableAttendanceUpdates: enableAttendanceUpdates ?? this.enableAttendanceUpdates,
      enableStudentAlerts: enableStudentAlerts ?? this.enableStudentAlerts,
      enableReports: enableReports ?? this.enableReports,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      attendanceUpdateInterval: attendanceUpdateInterval ?? this.attendanceUpdateInterval,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      disabledTypes: disabledTypes ?? this.disabledTypes,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'enableEventReminders': enableEventReminders,
      'enableAttendanceUpdates': enableAttendanceUpdates,
      'enableStudentAlerts': enableStudentAlerts,
      'enableReports': enableReports,
      'reminderMinutesBefore': reminderMinutesBefore,
      'attendanceUpdateInterval': attendanceUpdateInterval,
      'vibrationEnabled': vibrationEnabled,
      'soundEnabled': soundEnabled,
      'disabledTypes': disabledTypes.map((type) => type.id).toList(),
    };
  }

  /// Crear desde JSON
  static TeacherNotificationSettings fromJson(Map<String, dynamic> json) {
    final disabledTypeIds = (json['disabledTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    final disabledTypes = disabledTypeIds
        .map((id) => TeacherNotificationType.values.firstWhere(
              (type) => type.id == id,
              orElse: () => TeacherNotificationType.eventReminder,
            ))
        .toSet();

    return TeacherNotificationSettings(
      enableEventReminders: json['enableEventReminders'] ?? true,
      enableAttendanceUpdates: json['enableAttendanceUpdates'] ?? true,
      enableStudentAlerts: json['enableStudentAlerts'] ?? true,
      enableReports: json['enableReports'] ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'] ?? 15,
      attendanceUpdateInterval: json['attendanceUpdateInterval'] ?? 15,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      disabledTypes: disabledTypes,
    );
  }
}