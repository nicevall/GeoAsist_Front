// lib/models/notification_settings_model.dart
import 'package:flutter/material.dart';

/// ⚙️ MODELO COMPLETO DE CONFIGURACIÓN DE NOTIFICACIONES
/// Sistema avanzado para personalizar notificaciones por usuario y tipo
class NotificationSettings {
  // Configuraciones generales
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool ledEnabled;
  final NotificationPriority defaultPriority;
  final String defaultSound;

  // Configuraciones por categoría
  final EventNotificationSettings eventSettings;
  final AttendanceNotificationSettings attendanceSettings;
  final SystemNotificationSettings systemSettings;
  final JustificationNotificationSettings justificationSettings;
  final TeacherNotificationSettings teacherSettings;

  // Configuraciones de horario
  final QuietHoursSettings quietHours;
  final WeekdaySettings weekdaySettings;

  // Configuraciones avanzadas
  final bool groupSimilarNotifications;
  final int maxNotificationsPerHour;
  final bool showPreview;
  final bool persistentNotifications;

  const NotificationSettings({
    required this.enabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.ledEnabled,
    required this.defaultPriority,
    required this.defaultSound,
    required this.eventSettings,
    required this.attendanceSettings,
    required this.systemSettings,
    required this.justificationSettings,
    required this.teacherSettings,
    required this.quietHours,
    required this.weekdaySettings,
    required this.groupSimilarNotifications,
    required this.maxNotificationsPerHour,
    required this.showPreview,
    required this.persistentNotifications,
  });

  /// Factory desde JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      ledEnabled: json['ledEnabled'] ?? true,
      defaultPriority: NotificationPriority.fromString(json['defaultPriority']),
      defaultSound: json['defaultSound'] ?? 'default',
      eventSettings: EventNotificationSettings.fromJson(
        json['eventSettings'] ?? {},
      ),
      attendanceSettings: AttendanceNotificationSettings.fromJson(
        json['attendanceSettings'] ?? {},
      ),
      systemSettings: SystemNotificationSettings.fromJson(
        json['systemSettings'] ?? {},
      ),
      justificationSettings: JustificationNotificationSettings.fromJson(
        json['justificationSettings'] ?? {},
      ),
      teacherSettings: TeacherNotificationSettings.fromJson(
        json['teacherSettings'] ?? {},
      ),
      quietHours: QuietHoursSettings.fromJson(
        json['quietHours'] ?? {},
      ),
      weekdaySettings: WeekdaySettings.fromJson(
        json['weekdaySettings'] ?? {},
      ),
      groupSimilarNotifications: json['groupSimilarNotifications'] ?? true,
      maxNotificationsPerHour: json['maxNotificationsPerHour'] ?? 10,
      showPreview: json['showPreview'] ?? true,
      persistentNotifications: json['persistentNotifications'] ?? false,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'ledEnabled': ledEnabled,
      'defaultPriority': defaultPriority.value,
      'defaultSound': defaultSound,
      'eventSettings': eventSettings.toJson(),
      'attendanceSettings': attendanceSettings.toJson(),
      'systemSettings': systemSettings.toJson(),
      'justificationSettings': justificationSettings.toJson(),
      'teacherSettings': teacherSettings.toJson(),
      'quietHours': quietHours.toJson(),
      'weekdaySettings': weekdaySettings.toJson(),
      'groupSimilarNotifications': groupSimilarNotifications,
      'maxNotificationsPerHour': maxNotificationsPerHour,
      'showPreview': showPreview,
      'persistentNotifications': persistentNotifications,
    };
  }

  /// Factory para configuración por defecto
  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      enabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      ledEnabled: true,
      defaultPriority: NotificationPriority.normal,
      defaultSound: 'default',
      eventSettings: EventNotificationSettings.defaultSettings(),
      attendanceSettings: AttendanceNotificationSettings.defaultSettings(),
      systemSettings: SystemNotificationSettings.defaultSettings(),
      justificationSettings: JustificationNotificationSettings.defaultSettings(),
      teacherSettings: TeacherNotificationSettings.defaultSettings(),
      quietHours: QuietHoursSettings.defaultSettings(),
      weekdaySettings: WeekdaySettings.defaultSettings(),
      groupSimilarNotifications: true,
      maxNotificationsPerHour: 10,
      showPreview: true,
      persistentNotifications: false,
    );
  }

  /// Copiar con modificaciones
  NotificationSettings copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? ledEnabled,
    NotificationPriority? defaultPriority,
    String? defaultSound,
    EventNotificationSettings? eventSettings,
    AttendanceNotificationSettings? attendanceSettings,
    SystemNotificationSettings? systemSettings,
    JustificationNotificationSettings? justificationSettings,
    TeacherNotificationSettings? teacherSettings,
    QuietHoursSettings? quietHours,
    WeekdaySettings? weekdaySettings,
    bool? groupSimilarNotifications,
    int? maxNotificationsPerHour,
    bool? showPreview,
    bool? persistentNotifications,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      ledEnabled: ledEnabled ?? this.ledEnabled,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultSound: defaultSound ?? this.defaultSound,
      eventSettings: eventSettings ?? this.eventSettings,
      attendanceSettings: attendanceSettings ?? this.attendanceSettings,
      systemSettings: systemSettings ?? this.systemSettings,
      justificationSettings: justificationSettings ?? this.justificationSettings,
      teacherSettings: teacherSettings ?? this.teacherSettings,
      quietHours: quietHours ?? this.quietHours,
      weekdaySettings: weekdaySettings ?? this.weekdaySettings,
      groupSimilarNotifications: groupSimilarNotifications ?? this.groupSimilarNotifications,
      maxNotificationsPerHour: maxNotificationsPerHour ?? this.maxNotificationsPerHour,
      showPreview: showPreview ?? this.showPreview,
      persistentNotifications: persistentNotifications ?? this.persistentNotifications,
    );
  }
}

/// 📅 CONFIGURACIONES DE NOTIFICACIONES DE EVENTOS
class EventNotificationSettings {
  final bool enabled;
  final bool reminderBefore;
  final int reminderMinutes;
  final bool eventStarting;
  final bool eventEnding;
  final bool eventCanceled;
  final bool eventUpdated;
  final NotificationPriority priority;

  const EventNotificationSettings({
    required this.enabled,
    required this.reminderBefore,
    required this.reminderMinutes,
    required this.eventStarting,
    required this.eventEnding,
    required this.eventCanceled,
    required this.eventUpdated,
    required this.priority,
  });

  factory EventNotificationSettings.fromJson(Map<String, dynamic> json) {
    return EventNotificationSettings(
      enabled: json['enabled'] ?? true,
      reminderBefore: json['reminderBefore'] ?? true,
      reminderMinutes: json['reminderMinutes'] ?? 15,
      eventStarting: json['eventStarting'] ?? true,
      eventEnding: json['eventEnding'] ?? false,
      eventCanceled: json['eventCanceled'] ?? true,
      eventUpdated: json['eventUpdated'] ?? true,
      priority: NotificationPriority.fromString(json['priority']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'reminderBefore': reminderBefore,
      'reminderMinutes': reminderMinutes,
      'eventStarting': eventStarting,
      'eventEnding': eventEnding,
      'eventCanceled': eventCanceled,
      'eventUpdated': eventUpdated,
      'priority': priority.value,
    };
  }

  factory EventNotificationSettings.defaultSettings() {
    return const EventNotificationSettings(
      enabled: true,
      reminderBefore: true,
      reminderMinutes: 15,
      eventStarting: true,
      eventEnding: false,
      eventCanceled: true,
      eventUpdated: true,
      priority: NotificationPriority.high,
    );
  }

  EventNotificationSettings copyWith({
    bool? enabled,
    bool? reminderBefore,
    int? reminderMinutes,
    bool? eventStarting,
    bool? eventEnding,
    bool? eventCanceled,
    bool? eventUpdated,
    NotificationPriority? priority,
  }) {
    return EventNotificationSettings(
      enabled: enabled ?? this.enabled,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      eventStarting: eventStarting ?? this.eventStarting,
      eventEnding: eventEnding ?? this.eventEnding,
      eventCanceled: eventCanceled ?? this.eventCanceled,
      eventUpdated: eventUpdated ?? this.eventUpdated,
      priority: priority ?? this.priority,
    );
  }
}

/// 📍 CONFIGURACIONES DE NOTIFICACIONES DE ASISTENCIA
class AttendanceNotificationSettings {
  final bool enabled;
  final bool entryConfirmation;
  final bool exitWarning;
  final bool backInArea;
  final bool lateArrival;
  final bool absenceDetected;
  final bool gpsIssues;
  final NotificationPriority priority;

  const AttendanceNotificationSettings({
    required this.enabled,
    required this.entryConfirmation,
    required this.exitWarning,
    required this.backInArea,
    required this.lateArrival,
    required this.absenceDetected,
    required this.gpsIssues,
    required this.priority,
  });

  factory AttendanceNotificationSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceNotificationSettings(
      enabled: json['enabled'] ?? true,
      entryConfirmation: json['entryConfirmation'] ?? true,
      exitWarning: json['exitWarning'] ?? true,
      backInArea: json['backInArea'] ?? true,
      lateArrival: json['lateArrival'] ?? true,
      absenceDetected: json['absenceDetected'] ?? true,
      gpsIssues: json['gpsIssues'] ?? true,
      priority: NotificationPriority.fromString(json['priority']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'entryConfirmation': entryConfirmation,
      'exitWarning': exitWarning,
      'backInArea': backInArea,
      'lateArrival': lateArrival,
      'absenceDetected': absenceDetected,
      'gpsIssues': gpsIssues,
      'priority': priority.value,
    };
  }

  factory AttendanceNotificationSettings.defaultSettings() {
    return const AttendanceNotificationSettings(
      enabled: true,
      entryConfirmation: true,
      exitWarning: true,
      backInArea: true,
      lateArrival: true,
      absenceDetected: true,
      gpsIssues: true,
      priority: NotificationPriority.high,
    );
  }

  AttendanceNotificationSettings copyWith({
    bool? enabled,
    bool? entryConfirmation,
    bool? exitWarning,
    bool? backInArea,
    bool? lateArrival,
    bool? absenceDetected,
    bool? gpsIssues,
    NotificationPriority? priority,
  }) {
    return AttendanceNotificationSettings(
      enabled: enabled ?? this.enabled,
      entryConfirmation: entryConfirmation ?? this.entryConfirmation,
      exitWarning: exitWarning ?? this.exitWarning,
      backInArea: backInArea ?? this.backInArea,
      lateArrival: lateArrival ?? this.lateArrival,
      absenceDetected: absenceDetected ?? this.absenceDetected,
      gpsIssues: gpsIssues ?? this.gpsIssues,
      priority: priority ?? this.priority,
    );
  }
}

/// 🔧 CONFIGURACIONES DE NOTIFICACIONES DEL SISTEMA
class SystemNotificationSettings {
  final bool enabled;
  final bool appUpdates;
  final bool maintenanceAlerts;
  final bool securityAlerts;
  final bool backupReminders;
  final bool storageWarnings;
  final NotificationPriority priority;

  const SystemNotificationSettings({
    required this.enabled,
    required this.appUpdates,
    required this.maintenanceAlerts,
    required this.securityAlerts,
    required this.backupReminders,
    required this.storageWarnings,
    required this.priority,
  });

  factory SystemNotificationSettings.fromJson(Map<String, dynamic> json) {
    return SystemNotificationSettings(
      enabled: json['enabled'] ?? true,
      appUpdates: json['appUpdates'] ?? true,
      maintenanceAlerts: json['maintenanceAlerts'] ?? true,
      securityAlerts: json['securityAlerts'] ?? true,
      backupReminders: json['backupReminders'] ?? false,
      storageWarnings: json['storageWarnings'] ?? true,
      priority: NotificationPriority.fromString(json['priority']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'appUpdates': appUpdates,
      'maintenanceAlerts': maintenanceAlerts,
      'securityAlerts': securityAlerts,
      'backupReminders': backupReminders,
      'storageWarnings': storageWarnings,
      'priority': priority.value,
    };
  }

  factory SystemNotificationSettings.defaultSettings() {
    return const SystemNotificationSettings(
      enabled: true,
      appUpdates: true,
      maintenanceAlerts: true,
      securityAlerts: true,
      backupReminders: false,
      storageWarnings: true,
      priority: NotificationPriority.normal,
    );
  }

  SystemNotificationSettings copyWith({
    bool? enabled,
    bool? appUpdates,
    bool? maintenanceAlerts,
    bool? securityAlerts,
    bool? backupReminders,
    bool? storageWarnings,
    NotificationPriority? priority,
  }) {
    return SystemNotificationSettings(
      enabled: enabled ?? this.enabled,
      appUpdates: appUpdates ?? this.appUpdates,
      maintenanceAlerts: maintenanceAlerts ?? this.maintenanceAlerts,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      backupReminders: backupReminders ?? this.backupReminders,
      storageWarnings: storageWarnings ?? this.storageWarnings,
      priority: priority ?? this.priority,
    );
  }
}

/// 📄 CONFIGURACIONES DE NOTIFICACIONES DE JUSTIFICACIONES
class JustificationNotificationSettings {
  final bool enabled;
  final bool statusUpdates;
  final bool approvalNotifications;
  final bool rejectionNotifications;
  final bool reminderToSubmit;
  final bool documentReminders;
  final NotificationPriority priority;

  const JustificationNotificationSettings({
    required this.enabled,
    required this.statusUpdates,
    required this.approvalNotifications,
    required this.rejectionNotifications,
    required this.reminderToSubmit,
    required this.documentReminders,
    required this.priority,
  });

  factory JustificationNotificationSettings.fromJson(Map<String, dynamic> json) {
    return JustificationNotificationSettings(
      enabled: json['enabled'] ?? true,
      statusUpdates: json['statusUpdates'] ?? true,
      approvalNotifications: json['approvalNotifications'] ?? true,
      rejectionNotifications: json['rejectionNotifications'] ?? true,
      reminderToSubmit: json['reminderToSubmit'] ?? true,
      documentReminders: json['documentReminders'] ?? true,
      priority: NotificationPriority.fromString(json['priority']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'statusUpdates': statusUpdates,
      'approvalNotifications': approvalNotifications,
      'rejectionNotifications': rejectionNotifications,
      'reminderToSubmit': reminderToSubmit,
      'documentReminders': documentReminders,
      'priority': priority.value,
    };
  }

  factory JustificationNotificationSettings.defaultSettings() {
    return const JustificationNotificationSettings(
      enabled: true,
      statusUpdates: true,
      approvalNotifications: true,
      rejectionNotifications: true,
      reminderToSubmit: true,
      documentReminders: true,
      priority: NotificationPriority.high,
    );
  }

  JustificationNotificationSettings copyWith({
    bool? enabled,
    bool? statusUpdates,
    bool? approvalNotifications,
    bool? rejectionNotifications,
    bool? reminderToSubmit,
    bool? documentReminders,
    NotificationPriority? priority,
  }) {
    return JustificationNotificationSettings(
      enabled: enabled ?? this.enabled,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      approvalNotifications: approvalNotifications ?? this.approvalNotifications,
      rejectionNotifications: rejectionNotifications ?? this.rejectionNotifications,
      reminderToSubmit: reminderToSubmit ?? this.reminderToSubmit,
      documentReminders: documentReminders ?? this.documentReminders,
      priority: priority ?? this.priority,
    );
  }
}

/// 👨‍🏫 CONFIGURACIONES DE NOTIFICACIONES PARA DOCENTES
class TeacherNotificationSettings {
  final bool enabled;
  final bool studentJoinedEvent;
  final bool studentLeftArea;
  final bool lateArrivals;
  final bool absenceAlerts;
  final bool justificationReceived;
  final bool eventMetrics;
  final NotificationPriority priority;

  const TeacherNotificationSettings({
    required this.enabled,
    required this.studentJoinedEvent,
    required this.studentLeftArea,
    required this.lateArrivals,
    required this.absenceAlerts,
    required this.justificationReceived,
    required this.eventMetrics,
    required this.priority,
  });

  factory TeacherNotificationSettings.fromJson(Map<String, dynamic> json) {
    return TeacherNotificationSettings(
      enabled: json['enabled'] ?? true,
      studentJoinedEvent: json['studentJoinedEvent'] ?? true,
      studentLeftArea: json['studentLeftArea'] ?? true,
      lateArrivals: json['lateArrivals'] ?? true,
      absenceAlerts: json['absenceAlerts'] ?? true,
      justificationReceived: json['justificationReceived'] ?? true,
      eventMetrics: json['eventMetrics'] ?? false,
      priority: NotificationPriority.fromString(json['priority']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'studentJoinedEvent': studentJoinedEvent,
      'studentLeftArea': studentLeftArea,
      'lateArrivals': lateArrivals,
      'absenceAlerts': absenceAlerts,
      'justificationReceived': justificationReceived,
      'eventMetrics': eventMetrics,
      'priority': priority.value,
    };
  }

  factory TeacherNotificationSettings.defaultSettings() {
    return const TeacherNotificationSettings(
      enabled: true,
      studentJoinedEvent: true,
      studentLeftArea: true,
      lateArrivals: true,
      absenceAlerts: true,
      justificationReceived: true,
      eventMetrics: false,
      priority: NotificationPriority.normal,
    );
  }

  TeacherNotificationSettings copyWith({
    bool? enabled,
    bool? studentJoinedEvent,
    bool? studentLeftArea,
    bool? lateArrivals,
    bool? absenceAlerts,
    bool? justificationReceived,
    bool? eventMetrics,
    NotificationPriority? priority,
  }) {
    return TeacherNotificationSettings(
      enabled: enabled ?? this.enabled,
      studentJoinedEvent: studentJoinedEvent ?? this.studentJoinedEvent,
      studentLeftArea: studentLeftArea ?? this.studentLeftArea,
      lateArrivals: lateArrivals ?? this.lateArrivals,
      absenceAlerts: absenceAlerts ?? this.absenceAlerts,
      justificationReceived: justificationReceived ?? this.justificationReceived,
      eventMetrics: eventMetrics ?? this.eventMetrics,
      priority: priority ?? this.priority,
    );
  }
}

/// 🔇 CONFIGURACIONES DE HORARIOS SILENCIOSOS
class QuietHoursSettings {
  final bool enabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> activeDays; // 1 = Monday, 7 = Sunday
  final bool allowUrgentNotifications;
  final List<String> urgentCategories;

  const QuietHoursSettings({
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    required this.allowUrgentNotifications,
    required this.urgentCategories,
  });

  factory QuietHoursSettings.fromJson(Map<String, dynamic> json) {
    return QuietHoursSettings(
      enabled: json['enabled'] ?? false,
      startTime: json['startTime'] != null 
          ? TimeOfDay(
              hour: json['startTime']['hour'] ?? 22,
              minute: json['startTime']['minute'] ?? 0,
            )
          : const TimeOfDay(hour: 22, minute: 0),
      endTime: json['endTime'] != null
          ? TimeOfDay(
              hour: json['endTime']['hour'] ?? 7,
              minute: json['endTime']['minute'] ?? 0,
            )
          : const TimeOfDay(hour: 7, minute: 0),
      activeDays: List<int>.from(json['activeDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      allowUrgentNotifications: json['allowUrgentNotifications'] ?? true,
      urgentCategories: List<String>.from(json['urgentCategories'] ?? ['emergency', 'security']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'activeDays': activeDays,
      'allowUrgentNotifications': allowUrgentNotifications,
      'urgentCategories': urgentCategories,
    };
  }

  factory QuietHoursSettings.defaultSettings() {
    return const QuietHoursSettings(
      enabled: false,
      startTime: TimeOfDay(hour: 22, minute: 0),
      endTime: TimeOfDay(hour: 7, minute: 0),
      activeDays: [1, 2, 3, 4, 5, 6, 7],
      allowUrgentNotifications: true,
      urgentCategories: ['emergency', 'security'],
    );
  }

  QuietHoursSettings copyWith({
    bool? enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? activeDays,
    bool? allowUrgentNotifications,
    List<String>? urgentCategories,
  }) {
    return QuietHoursSettings(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activeDays: activeDays ?? this.activeDays,
      allowUrgentNotifications: allowUrgentNotifications ?? this.allowUrgentNotifications,
      urgentCategories: urgentCategories ?? this.urgentCategories,
    );
  }
}

/// 📅 CONFIGURACIONES POR DÍAS DE LA SEMANA
class WeekdaySettings {
  final Map<int, bool> enabledDays; // 1 = Monday, 7 = Sunday
  final Map<int, TimeOfDay> startTimes;
  final Map<int, TimeOfDay> endTimes;

  const WeekdaySettings({
    required this.enabledDays,
    required this.startTimes,
    required this.endTimes,
  });

  factory WeekdaySettings.fromJson(Map<String, dynamic> json) {
    final Map<int, bool> enabledDays = {};
    final Map<int, TimeOfDay> startTimes = {};
    final Map<int, TimeOfDay> endTimes = {};

    for (int i = 1; i <= 7; i++) {
      enabledDays[i] = json['enabledDays']?[i.toString()] ?? true;
      
      final startTimeJson = json['startTimes']?[i.toString()];
      startTimes[i] = startTimeJson != null
          ? TimeOfDay(
              hour: startTimeJson['hour'] ?? 6,
              minute: startTimeJson['minute'] ?? 0,
            )
          : const TimeOfDay(hour: 6, minute: 0);

      final endTimeJson = json['endTimes']?[i.toString()];
      endTimes[i] = endTimeJson != null
          ? TimeOfDay(
              hour: endTimeJson['hour'] ?? 22,
              minute: endTimeJson['minute'] ?? 0,
            )
          : const TimeOfDay(hour: 22, minute: 0);
    }

    return WeekdaySettings(
      enabledDays: enabledDays,
      startTimes: startTimes,
      endTimes: endTimes,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> enabledDaysJson = {};
    final Map<String, dynamic> startTimesJson = {};
    final Map<String, dynamic> endTimesJson = {};

    for (int i = 1; i <= 7; i++) {
      enabledDaysJson[i.toString()] = enabledDays[i];
      startTimesJson[i.toString()] = {
        'hour': startTimes[i]?.hour,
        'minute': startTimes[i]?.minute,
      };
      endTimesJson[i.toString()] = {
        'hour': endTimes[i]?.hour,
        'minute': endTimes[i]?.minute,
      };
    }

    return {
      'enabledDays': enabledDaysJson,
      'startTimes': startTimesJson,
      'endTimes': endTimesJson,
    };
  }

  factory WeekdaySettings.defaultSettings() {
    final Map<int, bool> enabledDays = {};
    final Map<int, TimeOfDay> startTimes = {};
    final Map<int, TimeOfDay> endTimes = {};

    for (int i = 1; i <= 7; i++) {
      enabledDays[i] = true;
      startTimes[i] = const TimeOfDay(hour: 6, minute: 0);
      endTimes[i] = const TimeOfDay(hour: 22, minute: 0);
    }

    return WeekdaySettings(
      enabledDays: enabledDays,
      startTimes: startTimes,
      endTimes: endTimes,
    );
  }

  WeekdaySettings copyWith({
    Map<int, bool>? enabledDays,
    Map<int, TimeOfDay>? startTimes,
    Map<int, TimeOfDay>? endTimes,
  }) {
    return WeekdaySettings(
      enabledDays: enabledDays ?? this.enabledDays,
      startTimes: startTimes ?? this.startTimes,
      endTimes: endTimes ?? this.endTimes,
    );
  }
}

/// 🎚️ PRIORIDADES DE NOTIFICACIÓN
enum NotificationPriority {
  low('low', 'Baja', Icons.keyboard_arrow_down, Color(0xFF9E9E9E)),
  normal('normal', 'Normal', Icons.remove, Color(0xFF2196F3)),
  high('high', 'Alta', Icons.keyboard_arrow_up, Color(0xFFFF9800)),
  urgent('urgent', 'Urgente', Icons.priority_high, Color(0xFFF44336));

  const NotificationPriority(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  static NotificationPriority fromString(String? value) {
    return values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

/// 🔊 SONIDOS DE NOTIFICACIÓN
enum NotificationSound {
  defaultSound('default', 'Por defecto'),
  bell('bell', 'Campana'),
  chime('chime', 'Timbre'),
  alert('alert', 'Alerta'),
  notification('notification', 'Notificación'),
  soft('soft', 'Suave'),
  none('none', 'Sin sonido');

  const NotificationSound(this.value, this.displayName);

  final String value;
  final String displayName;

  static NotificationSound fromString(String? value) {
    return values.firstWhere(
      (sound) => sound.value == value,
      orElse: () => NotificationSound.defaultSound,
    );
  }
}