import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/teacher_notification_service.dart
// 🔔 SERVICIO COMPLETO DE NOTIFICACIONES PARA DOCENTES
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/teacher_notification_model.dart';
import '../models/evento_model.dart';
import '../services/storage_service.dart';
import '../services/notifications/notification_manager.dart';

class TeacherNotificationService {
  static final TeacherNotificationService _instance = TeacherNotificationService._internal();
  factory TeacherNotificationService() => _instance;
  TeacherNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NotificationManager _notificationManager = NotificationManager();
  final StorageService _storageService = StorageService();
  
  // 🎯 GESTIÓN DE NOTIFICACIONES
  final List<TeacherNotification> _activeNotifications = [];
  final StreamController<List<TeacherNotification>> _notificationStreamController = 
      StreamController<List<TeacherNotification>>.broadcast();
  final Map<String, Timer> _scheduledTimers = {};
  
  // ⚙️ CONFIGURACIÓN
  TeacherNotificationSettings _settings = TeacherNotificationSettings.defaultSettings;
  
  // 📊 CONTADORES PARA AGRUPACIÓN
  final Map<String, Timer> _attendanceTimers = {};
  final Map<String, List<String>> _studentsLeftBuffer = {};

  /// Stream de notificaciones activas
  Stream<List<TeacherNotification>> get notificationStream => _notificationStreamController.stream;
  
  /// Lista de notificaciones activas
  List<TeacherNotification> get activeNotifications => List.unmodifiable(_activeNotifications);
  
  /// Configuración actual
  TeacherNotificationSettings get settings => _settings;

  // ===========================================
  // 🚀 INICIALIZACIÓN Y CONFIGURACIÓN
  // ===========================================

  /// Inicializar servicio de notificaciones para profesors
  Future<void> initialize() async {
    try {
      logger.d('🔔 Inicializando TeacherNotificationService');
      
      // Inicializar notificaciones base
      await _notificationManager.initialize();
      
      // Cargar configuración guardada
      await _loadSettings();
      
      // Cargar notificaciones persistentes
      await _loadPersistedNotifications();
      
      // Configurar canales específicos para profesors
      await _setupTeacherNotificationChannels();
      
      logger.d('✅ TeacherNotificationService inicializado');
    } catch (e) {
      logger.d('❌ Error inicializando TeacherNotificationService: $e');
      rethrow;
    }
  }

  /// Configurar canales de notificación específicos para profesors
  Future<void> _setupTeacherNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      // Canal para eventos próximos
      AndroidNotificationChannel(
        'teacher_event_reminders',
        'Recordatorios de Eventos',
        description: 'Notificaciones sobre eventos próximos',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('event_reminder'),
      ),
      
      // Canal para asistencia en tiempo real
      AndroidNotificationChannel(
        'teacher_attendance_updates',
        'Actualizaciones de Asistencia',
        description: 'Registros de estudiantes y cambios de asistencia',
        importance: Importance.defaultImportance,
      ),
      
      // Canal para alertas críticas
      AndroidNotificationChannel(
        'teacher_critical_alerts',
        'Alertas Críticas',
        description: 'Alertas importantes que requieren atención inmediata',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('critical_alert'),
        enableVibration: true,
        vibrationPattern: null,
      ),
      
      // Canal para sugerencias
      AndroidNotificationChannel(
        'teacher_suggestions',
        'Sugerencias de Gestión',
        description: 'Sugerencias para mejorar la gestión de eventos',
        importance: Importance.low,
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // ===========================================
  // ⏰ NOTIFICACIONES PROGRAMADAS
  // ===========================================

  /// Programar todas las notificaciones para un evento
  Future<void> scheduleEventNotifications(Evento evento) async {
    if (!_settings.enableEventReminders) return;
    
    try {
      logger.d('📅 Programando notificaciones para evento: ${evento.titulo}');
      
      final now = DateTime.now();
      final eventStart = evento.horaInicio;
      final eventEnd = evento.horaFinal;
      
      // Solo programar para eventos futuros
      if (eventStart.isBefore(now)) return;
      
      // 🔔 15 minutos antes (o configurado)
      final reminderTime = eventStart.subtract(Duration(minutes: _settings.reminderMinutesBefore));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
          reminderTime,
          TeacherNotification.eventStartingSoon(
            eventTitle: evento.titulo,
            minutesUntilStart: _settings.reminderMinutesBefore,
            eventId: evento.id!,
            onStartEvent: () => _handleStartEventNow(evento.id!),
          ),
        );
      }
      
      // 🔔 1 día antes
      final dayBeforeTime = eventStart.subtract(Duration(days: 1));
      if (dayBeforeTime.isAfter(now)) {
        await _scheduleNotification(
          dayBeforeTime,
          TeacherNotification(
            id: 'day_before_${evento.id}_${dayBeforeTime.millisecondsSinceEpoch}',
            title: '📅 Evento Mañana',
            message: '"${evento.titulo}" mañana a las ${_formatTime(eventStart)}',
            subtitle: 'Lugar: ${evento.lugar ?? "Sin ubicación"}',
            type: TeacherNotificationType.dayBeforeEvent,
            scheduledFor: dayBeforeTime,
            metadata: {
              'eventId': evento.id,
              'eventTitle': evento.titulo,
              'eventStart': eventStart.toIso8601String(),
            },
          ),
        );
      }
      
      // 🔔 10 minutos antes del fin
      final endWarningTime = eventEnd.subtract(Duration(minutes: 10));
      if (endWarningTime.isAfter(now)) {
        await _scheduleNotification(
          endWarningTime,
          TeacherNotification(
            id: 'event_ending_${evento.id}_${endWarningTime.millisecondsSinceEpoch}',
            title: '⏰ Evento Terminando',
            message: '"${evento.titulo}" termina en 10 minutos',
            subtitle: '¿Finalizar evento ahora?',
            type: TeacherNotificationType.eventEndingSoon,
            scheduledFor: endWarningTime,
            onAction: () => _handleEndEventNow(evento.id!),
            actionText: 'Finalizar',
            metadata: {
              'eventId': evento.id,
              'eventTitle': evento.titulo,
            },
          ),
        );
      }
      
      logger.d('✅ Notificaciones programadas para: ${evento.titulo}');
    } catch (e) {
      logger.d('❌ Error programando notificaciones: $e');
    }
  }

  /// Programar una notificación específica
  Future<void> _scheduleNotification(DateTime scheduledTime, TeacherNotification notification) async {
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;
    
    final timer = Timer(delay, () async {
      await showNotification(notification);
      _scheduledTimers.remove(notification.id);
    });
    
    _scheduledTimers[notification.id] = timer;
    logger.d('⏰ Notificación programada para: ${_formatDateTime(scheduledTime)}');
  }

  // ===========================================
  // 👥 NOTIFICACIONES DE ASISTENCIA EN TIEMPO REAL
  // ===========================================

  /// Notificar que un estudiante se registró
  Future<void> notifyStudentJoined({
    required String studentName,
    required String eventTitle,
    required String eventId,
    required int currentAttendance,
    required int totalStudents,
  }) async {
    if (!_settings.enableAttendanceUpdates) return;
    
    try {
      logger.d('👥 Notificando estudiante registrado: $studentName');
      
      final notification = TeacherNotification.studentJoined(
        studentName: studentName,
        eventTitle: eventTitle,
        eventId: eventId,
        currentAttendance: currentAttendance,
        totalStudents: totalStudents,
      );
      
      await showNotification(notification);
      
      // Verificar si se alcanzó algún hito de asistencia
      await _checkAttendanceMilestones(eventId, currentAttendance, totalStudents);
      
    } catch (e) {
      logger.d('❌ Error notificando estudiante registrado: $e');
    }
  }

  /// Notificar múltiples estudiantes registrados (agrupado)
  Future<void> notifyMultipleStudentsJoined({
    required List<String> studentNames,
    required String eventTitle,
    required String eventId,
    required int currentAttendance,
    required int totalStudents,
  }) async {
    if (!_settings.enableAttendanceUpdates) return;
    
    try {
      final count = studentNames.length;
      final notification = TeacherNotification(
        id: 'multiple_students_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        title: '👥 $count Estudiantes Registrados',
        message: 'Se unieron a "$eventTitle"',
        subtitle: 'Asistencia: $currentAttendance/$totalStudents (${((currentAttendance/totalStudents)*100).round()}%)',
        type: TeacherNotificationType.multipleStudentsJoined,
        autoCloseAfter: Duration(seconds: 6),
        metadata: {
          'eventId': eventId,
          'studentNames': studentNames,
          'count': count,
          'currentAttendance': currentAttendance,
          'totalStudents': totalStudents,
        },
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error notificando múltiples estudiantes: $e');
    }
  }

  /// Actualización periódica de asistencia
  Future<void> notifyAttendanceUpdate({
    required String eventTitle,
    required String eventId,
    required int presentStudents,
    required int totalStudents,
    String? trend,
  }) async {
    if (!_settings.enableAttendanceUpdates) return;
    
    try {
      final notification = TeacherNotification.attendanceUpdate(
        eventTitle: eventTitle,
        eventId: eventId,
        presentStudents: presentStudents,
        totalStudents: totalStudents,
        trend: trend,
      );
      
      await showNotification(notification);
      
      // Verificar si la asistencia es preocupantemente baja
      final percentage = (presentStudents / totalStudents) * 100;
      if (percentage < 50) {
        await _notifyLowAttendance(eventTitle, eventId, percentage.round());
      }
      
    } catch (e) {
      logger.d('❌ Error en actualización de asistencia: $e');
    }
  }

  // ===========================================
  // 🚨 ALERTAS CRÍTICAS
  // ===========================================

  /// Notificar que un estudiante salió del área
  Future<void> notifyStudentLeftArea({
    required String studentName,
    required String eventTitle,
    required String eventId,
    String? timeOutside,
  }) async {
    if (!_settings.enableStudentAlerts) return;
    
    try {
      logger.d('🚨 Estudiante salió del área: $studentName');
      
      // Agregar al buffer para posible agrupación
      _studentsLeftBuffer.putIfAbsent(eventId, () => []).add(studentName);
      
      // Si hay múltiples estudiantes que salieron, agrupar
      if (_studentsLeftBuffer[eventId]!.length >= 3) {
        await _notifyMultipleStudentsLeft(eventId, eventTitle);
        _studentsLeftBuffer[eventId]!.clear();
        return;
      }
      
      final notification = TeacherNotification.studentLeftArea(
        studentName: studentName,
        eventTitle: eventTitle,
        eventId: eventId,
        timeOutside: timeOutside,
        onContactStudent: () => _handleContactStudent(studentName, eventId),
      );
      
      await showNotification(notification);
      
      // Limpiar buffer después de 2 minutos
      Timer(Duration(minutes: 2), () {
        _studentsLeftBuffer[eventId]?.remove(studentName);
      });
      
    } catch (e) {
      logger.d('❌ Error notificando estudiante que salió: $e');
    }
  }

  /// Notificar múltiples estudiantes que salieron
  Future<void> _notifyMultipleStudentsLeft(String eventId, String eventTitle) async {
    try {
      final students = _studentsLeftBuffer[eventId] ?? [];
      if (students.isEmpty) return;
      
      final notification = TeacherNotification(
        id: 'multiple_left_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        title: '🚨 ${students.length} Estudiantes Salieron',
        message: 'Varios estudiantes salieron de "$eventTitle"',
        subtitle: 'Revisar: ${students.take(3).join(", ")}${students.length > 3 ? "..." : ""}',
        type: TeacherNotificationType.multipleStudentsLeft,
        isPersistent: true,
        onAction: () => _handleMultipleStudentsLeftAction(eventId),
        actionText: 'Ver Detalles',
        metadata: {
          'eventId': eventId,
          'studentNames': students,
          'count': students.length,
        },
        vibrationPattern: [0, 300, 100, 300, 100, 300],
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error notificando múltiples estudiantes: $e');
    }
  }

  // ===========================================
  // 🎛️ SUGERENCIAS INTELIGENTES
  // ===========================================

  /// Sugerir receso después de tiempo prolongado
  Future<void> suggestBreak({
    required String eventTitle,
    required String eventId,
    required int minutesRunning,
  }) async {
    try {
      final notification = TeacherNotification.suggestBreak(
        eventTitle: eventTitle,
        eventId: eventId,
        minutesRunning: minutesRunning,
        onStartBreak: () => _handleStartBreak(eventId),
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error sugiriendo receso: $e');
    }
  }

  /// Notificar estudiantes esperando
  Future<void> notifyStudentsWaiting({
    required String eventTitle,
    required String eventId,
    required int waitingCount,
  }) async {
    try {
      final notification = TeacherNotification(
        id: 'students_waiting_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        title: '⏳ $waitingCount Estudiantes Esperando',
        message: 'Esperan que inicies "$eventTitle"',
        subtitle: '¿Iniciar evento ahora?',
        type: TeacherNotificationType.studentsWaiting,
        onAction: () => _handleStartEventNow(eventId),
        actionText: 'Iniciar',
        metadata: {
          'eventId': eventId,
          'waitingCount': waitingCount,
        },
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error notificando estudiantes esperando: $e');
    }
  }

  // ===========================================
  // 📊 REPORTES Y MÉTRICAS
  // ===========================================

  /// Notificar reporte generado
  Future<void> notifyReportGenerated({
    required String reportTitle,
    required String eventTitle,
    required String eventId,
    VoidCallback? onOpenReport,
  }) async {
    if (!_settings.enableReports) return;
    
    try {
      final notification = TeacherNotification(
        id: 'report_generated_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        title: '📊 Reporte Generado',
        message: '$reportTitle para "$eventTitle"',
        subtitle: 'Toca para abrir',
        type: TeacherNotificationType.reportGenerated,
        onAction: onOpenReport,
        actionText: 'Abrir',
        metadata: {
          'eventId': eventId,
          'reportTitle': reportTitle,
        },
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error notificando reporte: $e');
    }
  }

  // ===========================================
  // 🔔 GESTIÓN DE NOTIFICACIONES
  // ===========================================

  /// Mostrar notificación
  Future<void> showNotification(TeacherNotification notification) async {
    try {
      // Verificar si el tipo está habilitado
      if (!_settings.isTypeEnabled(notification.type)) {
        logger.d('🚫 Tipo de notificación deshabilitado: ${notification.type.name}');
        return;
      }
      
      // Agregar a la lista activa
      _activeNotifications.add(notification);
      _notifyListeners();
      
      // Mostrar notificación del sistema
      await _showSystemNotification(notification);
      
      // Aplicar vibración si está habilitada
      if (_settings.vibrationEnabled && notification.vibrationPattern != null) {
        await HapticFeedback.vibrate();
      }
      
      // Programar auto-close si es necesario
      if (notification.autoCloseAfter != null) {
        Timer(notification.autoCloseAfter!, () {
          dismissNotification(notification.id);
        });
      }
      
      // Guardar notificación persistente
      if (notification.isPersistent) {
        await _savePersistedNotification(notification);
      }
      
      logger.d('✅ Notificación mostrada: ${notification.title}');
    } catch (e) {
      logger.d('❌ Error mostrando notificación: $e');
    }
  }

  /// Mostrar notificación del sistema
  Future<void> _showSystemNotification(TeacherNotification notification) async {
    try {
      final channelId = _getChannelForType(notification.type);
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        importance: _getImportanceForPriority(notification.type.priority),
        priority: _getPriorityForType(notification.type.priority),
        color: notification.type.color,
        icon: '@drawable/ic_teacher',
        ongoing: notification.isPersistent,
        autoCancel: !notification.isPersistent,
        playSound: _settings.soundEnabled,
        enableVibration: _settings.vibrationEnabled,
        vibrationPattern: notification.vibrationPattern != null 
            ? Int64List.fromList(notification.vibrationPattern!) 
            : null,
        actions: notification.hasAction 
            ? [AndroidNotificationAction(
                'action_${notification.id}',
                notification.actionText!,
                showsUserInterface: true,
              )]
            : null,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notification.id.hashCode, // Usar hash como ID numérico
        notification.title,
        '${notification.message}${notification.subtitle != null ? "\n${notification.subtitle}" : ""}',
        details,
      );
    } catch (e) {
      logger.d('❌ Error en notificación del sistema: $e');
    }
  }

  /// Descartar notificación
  void dismissNotification(String notificationId) {
    try {
      _activeNotifications.removeWhere((n) => n.id == notificationId);
      _notifyListeners();
      
      // Cancelar notificación del sistema
      _notifications.cancel(notificationId.hashCode);
      
      logger.d('✅ Notificación descartada: $notificationId');
    } catch (e) {
      logger.d('❌ Error descartando notificación: $e');
    }
  }

  /// Marcar notificación como leída
  void markAsRead(String notificationId) {
    try {
      final index = _activeNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _activeNotifications[index] = _activeNotifications[index].copyWith(isRead: true);
        _notifyListeners();
      }
    } catch (e) {
      logger.d('❌ Error marcando como leída: $e');
    }
  }

  /// Limpiar todas las notificaciones
  void clearAllNotifications() {
    try {
      _activeNotifications.clear();
      _notifyListeners();
      _notifications.cancelAll();
      logger.d('✅ Todas las notificaciones limpiadas');
    } catch (e) {
      logger.d('❌ Error limpiando notificaciones: $e');
    }
  }

  // ===========================================
  // ⚙️ CONFIGURACIÓN Y UTILIDADES
  // ===========================================

  /// Actualizar configuración
  Future<void> updateSettings(TeacherNotificationSettings newSettings) async {
    try {
      _settings = newSettings;
      await _saveSettings();
      logger.d('✅ Configuración de notificaciones actualizada');
    } catch (e) {
      logger.d('❌ Error actualizando configuración: $e');
    }
  }

  /// Cargar configuración guardada
  Future<void> _loadSettings() async {
    try {
      final data = await _storageService.getData('teacher_notification_settings');
      if (data != null) {
        final json = jsonDecode(data);
        _settings = TeacherNotificationSettings.fromJson(json);
      }
    } catch (e) {
      logger.d('❌ Error cargando configuración: $e');
      _settings = TeacherNotificationSettings.defaultSettings;
    }
  }

  /// Guardar configuración
  Future<void> _saveSettings() async {
    try {
      final json = jsonEncode(_settings.toJson());
      await _storageService.saveData('teacher_notification_settings', json);
    } catch (e) {
      logger.d('❌ Error guardando configuración: $e');
    }
  }

  /// Notificar cambios a listeners
  void _notifyListeners() {
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.add(List.from(_activeNotifications));
    }
  }

  // ===========================================
  // 🎯 MÉTODOS AUXILIARES
  // ===========================================

  String _getChannelForType(TeacherNotificationType type) {
    switch (type) {
      case TeacherNotificationType.eventStartingSoon:
      case TeacherNotificationType.eventEndingSoon:
      case TeacherNotificationType.eventReminder:
      case TeacherNotificationType.dayBeforeEvent:
        return 'teacher_event_reminders';
      
      case TeacherNotificationType.studentJoined:
      case TeacherNotificationType.multipleStudentsJoined:
      case TeacherNotificationType.attendanceUpdate:
      case TeacherNotificationType.attendanceMilestone:
        return 'teacher_attendance_updates';
      
      case TeacherNotificationType.studentLeftArea:
      case TeacherNotificationType.multipleStudentsLeft:
      case TeacherNotificationType.connectivityIssues:
      case TeacherNotificationType.lowAttendance:
      case TeacherNotificationType.studentInDistress:
        return 'teacher_critical_alerts';
      
      default:
        return 'teacher_suggestions';
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'teacher_event_reminders':
        return 'Recordatorios de Eventos';
      case 'teacher_attendance_updates':
        return 'Actualizaciones de Asistencia';
      case 'teacher_critical_alerts':
        return 'Alertas Críticas';
      case 'teacher_suggestions':
        return 'Sugerencias de Gestión';
      default:
        return 'Notificaciones';
    }
  }

  Importance _getImportanceForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.critical:
        return Importance.max;
    }
  }

  Priority _getPriorityForType(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.critical:
        return Priority.max;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
  }

  // ===========================================
  // 🎯 HANDLERS DE ACCIONES
  // ===========================================

  void _handleStartEventNow(String eventId) {
    logger.d('🎮 Iniciar evento ahora: $eventId');
    // Integración con EventService para iniciar evento
    _performEventAction('start_event', eventId, {
      'action': 'manual_start',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleEndEventNow(String eventId) {
    logger.d('🏁 Finalizar evento ahora: $eventId');
    // Integración con EventService para finalizar evento
    _performEventAction('end_event', eventId, {
      'action': 'manual_end',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleStartBreak(String eventId) {
    logger.d('⏸️ Iniciar receso: $eventId');
    // Integración con EventService para iniciar receso
    _performEventAction('start_break', eventId, {
      'action': 'start_break',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleContactStudent(String studentName, String eventId) {
    logger.d('📞 Contactar estudiante: $studentName');
    // Integración con comunicación de estudiantes
    _performEventAction('contact_student', eventId, {
      'student_name': studentName,
      'contact_method': 'notification',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Enviar notificación al estudiante
    _sendStudentNotification(studentName, eventId);
  }

  void _handleMultipleStudentsLeftAction(String eventId) {
    logger.d('👥 Ver detalles de estudiantes que salieron: $eventId');
    // Integración con navegación a detalles
    _performEventAction('view_left_students', eventId, {
      'action': 'navigate_to_details',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Realizar acción de evento
  void _performEventAction(String actionType, String eventId, Map<String, dynamic> data) {
    try {
      // En producción, esto se integraría con los servicios correspondientes
      logger.d('TeacherNotificationService: Performing $actionType for event $eventId');
      logger.d('TeacherNotificationService: Action data: $data');
      
      // Registrar acción para analytics (implementar cuando esté disponible)
      // AnalyticsService.trackEvent(...)
      
    } catch (e) {
      logger.d('TeacherNotificationService: Error performing event action $actionType: $e');
    }
  }

  /// Enviar notificación a estudiante específico
  void _sendStudentNotification(String studentName, String eventId) {
    try {
      // En producción, esto se integraría con el servicio de notificaciones de estudiantes
      logger.d('TeacherNotificationService: Sending notification to student: $studentName for event: $eventId');
      
      // Placeholder para envío de notificación
      final notificationData = {
        'type': 'teacher_contact',
        'event_id': eventId,
        'teacher_message': 'Por favor revisa tu asistencia al evento',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      logger.d('TeacherNotificationService: Student notification data: $notificationData');
    } catch (e) {
      logger.d('TeacherNotificationService: Error sending student notification: $e');
    }
  }

  // ===========================================
  // 💾 PERSISTENCIA
  // ===========================================

  Future<void> _savePersistedNotification(TeacherNotification notification) async {
    try {
      final key = 'persisted_teacher_notification_${notification.id}';
      final json = jsonEncode(notification.toJson());
      await _storageService.saveData(key, json);
    } catch (e) {
      logger.d('❌ Error guardando notificación persistente: $e');
    }
  }

  Future<void> _loadPersistedNotifications() async {
    try {
      // TODO: Implementar carga de notificaciones persistentes
      logger.d('📱 Cargando notificaciones persistentes...');
    } catch (e) {
      logger.d('❌ Error cargando notificaciones persistentes: $e');
    }
  }

  // ===========================================
  // 🧮 LÓGICA DE MÉTRICAS
  // ===========================================

  Future<void> _checkAttendanceMilestones(String eventId, int current, int total) async {
    final percentage = (current / total) * 100;
    
    // Hitos importantes: 50%, 75%, 90%, 100%
    final milestones = [50, 75, 90, 100];
    
    for (final milestone in milestones) {
      if (percentage >= milestone && !_hasReachedMilestone(eventId, milestone)) {
        await _notifyAttendanceMilestone(eventId, milestone, current, total);
        _markMilestoneReached(eventId, milestone);
      }
    }
  }

  bool _hasReachedMilestone(String eventId, int milestone) {
    // TODO: Implementar verificación de hitos alcanzados
    return false;
  }

  void _markMilestoneReached(String eventId, int milestone) {
    // TODO: Implementar marcado de hitos
  }

  Future<void> _notifyAttendanceMilestone(String eventId, int milestone, int current, int total) async {
    try {
      String title;
      String message;
      
      switch (milestone) {
        case 50:
          title = '📊 ¡50% de Asistencia!';
          message = 'Buen comienzo con $current/$total estudiantes';
          break;
        case 75:
          title = '📈 ¡75% de Asistencia!';
          message = 'Excelente participación: $current/$total';
          break;
        case 90:
          title = '🌟 ¡90% de Asistencia!';
          message = 'Casi perfecto: $current/$total estudiantes';
          break;
        case 100:
          title = '🏆 ¡ASISTENCIA PERFECTA!';
          message = 'Todos los estudiantes presentes: $current/$total';
          break;
        default:
          return;
      }
      
      final notification = TeacherNotification(
        id: 'milestone_${eventId}_$milestone',
        title: title,
        message: message,
        type: TeacherNotificationType.attendanceMilestone,
        autoCloseAfter: Duration(seconds: 8),
        metadata: {
          'eventId': eventId,
          'milestone': milestone,
          'current': current,
          'total': total,
        },
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error notificando hito: $e');
    }
  }

  Future<void> _notifyLowAttendance(String eventTitle, String eventId, int percentage) async {
    try {
      final notification = TeacherNotification(
        id: 'low_attendance_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        title: '📉 Asistencia Baja ($percentage%)',
        message: 'Pocos estudiantes en "$eventTitle"',
        subtitle: '¿Enviar recordatorio a estudiantes?',
        type: TeacherNotificationType.lowAttendance,
        onAction: () => _handleRemindStudents(eventId),
        actionText: 'Recordar',
        metadata: {
          'eventId': eventId,
          'percentage': percentage,
        },
      );
      
      await showNotification(notification);
    } catch (e) {
      logger.d('❌ Error notificando asistencia baja: $e');
    }
  }

  void _handleRemindStudents(String eventId) {
    logger.d('📢 Recordar estudiantes: $eventId');
    // TODO: Implementar lógica para enviar recordatorios
  }

  /// Limpiar recursos
  void dispose() {
    try {
      _notificationStreamController.close();
      
      // Cancelar todos los timers programados
      for (final timer in _scheduledTimers.values) {
        timer.cancel();
      }
      _scheduledTimers.clear();
      
      // Cancelar timers de asistencia
      for (final timer in _attendanceTimers.values) {
        timer.cancel();
      }
      _attendanceTimers.clear();
      
      logger.d('✅ TeacherNotificationService disposed');
    } catch (e) {
      logger.d('❌ Error disposing TeacherNotificationService: $e');
    }
  }
}