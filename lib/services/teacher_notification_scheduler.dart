import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/teacher_notification_scheduler.dart
// ⏰ PROGRAMADOR DE NOTIFICACIONES TEMPORALES PARA DOCENTES
import 'dart:async';
import 'dart:convert';
import '../models/teacher_notification_model.dart';
import '../models/evento_model.dart';
import '../services/storage_service.dart';
import '../services/teacher_notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Programador inteligente de notificaciones para profesors
/// Maneja todas las notificaciones programadas basadas en tiempo
class TeacherNotificationScheduler {
  static final TeacherNotificationScheduler _instance = TeacherNotificationScheduler._internal();
  factory TeacherNotificationScheduler() => _instance;
  TeacherNotificationScheduler._internal();

  final TeacherNotificationService _notificationService = TeacherNotificationService();
  final StorageService _storageService = StorageService();
  
  // 🎯 GESTIÓN DE TAREAS PROGRAMADAS
  final Map<String, Timer> _scheduledTasks = {};
  final Map<String, List<ScheduledNotification>> _eventSchedules = {};
  final List<ScheduledNotification> _activeSchedules = [];
  
  // 🎯 CONTROLADORES DE STREAMS
  final StreamController<List<ScheduledNotification>> _scheduleStreamController =
      StreamController<List<ScheduledNotification>>.broadcast();

  /// Stream de notificaciones programadas activas
  Stream<List<ScheduledNotification>> get scheduleStream => _scheduleStreamController.stream;
  
  /// Lista de programaciones activas
  List<ScheduledNotification> get activeSchedules => List.unmodifiable(_activeSchedules);

  // ===========================================
  // 🚀 INICIALIZACIÓN
  // ===========================================

  /// Inicializar el programador de notificaciones
  Future<void> initialize() async {
    try {
      logger.d('⏰ Inicializando TeacherNotificationScheduler');
      
      // Inicializar zonas horarias
      tz_data.initializeTimeZones();
      
      // Cargar programaciones guardadas
      await _loadPersistedSchedules();
      
      // Reactivar programaciones pendientes
      await _reactivatePendingSchedules();
      
      logger.d('✅ TeacherNotificationScheduler inicializado');
    } catch (e) {
      logger.d('❌ Error inicializando TeacherNotificationScheduler: $e');
      rethrow;
    }
  }

  // ===========================================
  // 📅 PROGRAMACIÓN DE EVENTOS
  // ===========================================

  /// Programar todas las notificaciones para un evento
  Future<void> scheduleEventNotifications(Evento evento) async {
    try {
      logger.d('📅 Programando notificaciones para: ${evento.titulo}');
      
      final now = DateTime.now();
      final eventStart = evento.horaInicio;
      final eventEnd = evento.horaFinal;
      
      // Solo programar eventos futuros
      if (eventStart.isBefore(now)) {
        logger.d('⚠️ Evento ya comenzó, omitiendo programación');
        return;
      }

      final schedules = <ScheduledNotification>[];

      // 1. 📅 DÍA ANTES DEL EVENTO
      final dayBeforeTime = eventStart.subtract(Duration(days: 1));
      if (dayBeforeTime.isAfter(now)) {
        final dayBeforeSchedule = ScheduledNotification(
          id: 'day_before_${evento.id}',
          eventId: evento.id!,
          scheduledTime: dayBeforeTime,
          type: TeacherNotificationType.dayBeforeEvent,
          title: '📅 Evento Mañana',
          message: '"${evento.titulo}" mañana a las ${_formatTime(eventStart)}',
          metadata: {
            'eventTitle': evento.titulo,
            'eventStart': eventStart.toIso8601String(),
            'eventLocation': evento.lugar ?? 'Sin ubicación',
          },
        );
        schedules.add(dayBeforeSchedule);
        await _scheduleNotification(dayBeforeSchedule);
      }

      // 2. ⏰ 15 MINUTOS ANTES (CONFIGURABLE)
      final reminderTime = eventStart.subtract(Duration(minutes: 15));
      if (reminderTime.isAfter(now)) {
        final reminderSchedule = ScheduledNotification(
          id: 'reminder_15_${evento.id}',
          eventId: evento.id!,
          scheduledTime: reminderTime,
          type: TeacherNotificationType.eventStartingSoon,
          title: '📅 Evento Próximo',
          message: '"${evento.titulo}" inicia en 15 minutos',
          metadata: {
            'eventTitle': evento.titulo,
            'minutesUntilStart': 15,
            'eventId': evento.id,
          },
          actionText: 'Iniciar Ahora',
          requiresAction: true,
        );
        schedules.add(reminderSchedule);
        await _scheduleNotification(reminderSchedule);
      }

      // 3. ⚡ AL INICIO DEL EVENTO
      if (eventStart.isAfter(now)) {
        final startSchedule = ScheduledNotification(
          id: 'event_start_${evento.id}',
          eventId: evento.id!,
          scheduledTime: eventStart,
          type: TeacherNotificationType.eventReminder,
          title: '🎯 ¡Evento Iniciando!',
          message: '"${evento.titulo}" debe comenzar ahora',
          metadata: {
            'eventTitle': evento.titulo,
            'eventId': evento.id,
          },
          actionText: 'Comenzar Evento',
          requiresAction: true,
          isPriority: true,
        );
        schedules.add(startSchedule);
        await _scheduleNotification(startSchedule);
      }

      // 4. ⏰ 10 MINUTOS ANTES DEL FIN
      final endWarningTime = eventEnd.subtract(Duration(minutes: 10));
      if (endWarningTime.isAfter(now)) {
        final endWarningSchedule = ScheduledNotification(
          id: 'end_warning_${evento.id}',
          eventId: evento.id!,
          scheduledTime: endWarningTime,
          type: TeacherNotificationType.eventEndingSoon,
          title: '⏰ Evento Terminando',
          message: '"${evento.titulo}" termina en 10 minutos',
          metadata: {
            'eventTitle': evento.titulo,
            'eventId': evento.id,
          },
          actionText: 'Finalizar Ahora',
          requiresAction: true,
        );
        schedules.add(endWarningSchedule);
        await _scheduleNotification(endWarningSchedule);
      }

      // 5. 🏁 AL FINAL DEL EVENTO
      if (eventEnd.isAfter(now)) {
        final endSchedule = ScheduledNotification(
          id: 'event_end_${evento.id}',
          eventId: evento.id!,
          scheduledTime: eventEnd,
          type: TeacherNotificationType.suggestEndEvent,
          title: '🏁 Evento Debe Terminar',
          message: '"${evento.titulo}" llegó a su hora de finalización',
          metadata: {
            'eventTitle': evento.titulo,
            'eventId': evento.id,
          },
          actionText: 'Terminar Evento',
          requiresAction: true,
          isPriority: true,
        );
        schedules.add(endSchedule);
        await _scheduleNotification(endSchedule);
      }

      // Guardar programaciones del evento
      _eventSchedules[evento.id!] = schedules;
      _activeSchedules.addAll(schedules);
      _notifyListeners();
      
      // Persistir programaciones
      await _persistSchedules();
      
      logger.d('✅ ${schedules.length} notificaciones programadas para: ${evento.titulo}');
      
    } catch (e) {
      logger.d('❌ Error programando notificaciones: $e');
    }
  }

  // ===========================================
  // ⏰ PROGRAMACIÓN AVANZADA
  // ===========================================

  /// Programar notificación recurrente (sugerencias cada X minutos durante evento)
  Future<void> scheduleRecurringNotification({
    required String eventId,
    required DateTime eventStart,
    required DateTime eventEnd,
    required Duration interval,
    required TeacherNotificationType type,
    required String title,
    required String message,
  }) async {
    try {
      logger.d('🔄 Programando notificación recurrente cada ${interval.inMinutes} min');
      
      final schedules = <ScheduledNotification>[];
      var currentTime = eventStart.add(interval);
      var count = 1;

      while (currentTime.isBefore(eventEnd)) {
        final schedule = ScheduledNotification(
          id: '${type.id}_recurring_${eventId}_$count',
          eventId: eventId,
          scheduledTime: currentTime,
          type: type,
          title: title,
          message: '$message ($count)',
          isRecurring: true,
          recurringInterval: interval,
        );

        schedules.add(schedule);
        await _scheduleNotification(schedule);
        
        currentTime = currentTime.add(interval);
        count++;
      }

      _activeSchedules.addAll(schedules);
      _notifyListeners();
      await _persistSchedules();
      
      logger.d('✅ ${schedules.length} notificaciones recurrentes programadas');
    } catch (e) {
      logger.d('❌ Error programando notificación recurrente: $e');
    }
  }

  /// Programar sugerencia de receso cada 90 minutos
  Future<void> scheduleBreakSuggestions(Evento evento) async {
    if (evento.duracionMinutos < 90) return; // Solo para eventos largos

    await scheduleRecurringNotification(
      eventId: evento.id!,
      eventStart: evento.horaInicio.add(Duration(minutes: 90)),
      eventEnd: evento.horaFinal.subtract(Duration(minutes: 15)),
      interval: Duration(minutes: 90),
      type: TeacherNotificationType.suggestBreak,
      title: '☕ ¿Iniciar Receso?',
      message: 'El evento lleva tiempo prolongado - sugerencia de pausa',
    );
  }

  /// Programar recordatorios de reportes semanales
  Future<void> scheduleWeeklyReportReminder() async {
    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final reportTime = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);

    final schedule = ScheduledNotification(
      id: 'weekly_report_${reportTime.millisecondsSinceEpoch}',
      eventId: 'system',
      scheduledTime: reportTime,
      type: TeacherNotificationType.weeklyReport,
      title: '📊 Reporte Semanal Disponible',
      message: 'Tu reporte semanal de asistencia está listo para revisar',
      isRecurring: true,
      recurringInterval: Duration(days: 7),
    );

    await _scheduleNotification(schedule);
    _activeSchedules.add(schedule);
    _notifyListeners();
    await _persistSchedules();
    
    logger.d('✅ Reporte semanal programado para: ${_formatDateTime(reportTime)}');
  }

  // ===========================================
  // 🎯 EJECUCIÓN DE PROGRAMACIONES
  // ===========================================

  /// Programar una notificación específica
  Future<void> _scheduleNotification(ScheduledNotification schedule) async {
    final delay = schedule.scheduledTime.difference(DateTime.now());
    
    if (delay.isNegative) {
      logger.d('⚠️ Programación en el pasado ignorada: ${schedule.id}');
      return;
    }

    logger.d('⏰ Programando ${schedule.id} para: ${_formatDateTime(schedule.scheduledTime)}');

    final timer = Timer(delay, () async {
      await _executeScheduledNotification(schedule);
    });

    _scheduledTasks[schedule.id] = timer;
  }

  /// Ejecutar una notificación programada
  Future<void> _executeScheduledNotification(ScheduledNotification schedule) async {
    try {
      logger.d('🔔 Ejecutando notificación programada: ${schedule.id}');

      // Crear notificación TeacherNotification
      final notification = TeacherNotification(
        id: '${schedule.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: schedule.title,
        message: schedule.message,
        type: schedule.type,
        scheduledFor: schedule.scheduledTime,
        onAction: schedule.requiresAction ? () => _handleScheduledAction(schedule) : null,
        actionText: schedule.actionText,
        metadata: schedule.metadata,
        isPersistent: schedule.isPriority,
        vibrationPattern: schedule.isPriority ? [0, 300, 100, 300] : [0, 200],
      );

      // Enviar a TeacherNotificationService
      await _notificationService.showNotification(notification);

      // Marcar como ejecutada
      schedule.markAsExecuted();

      // Si es recurrente, programar la siguiente
      if (schedule.isRecurring) {
        await _scheduleNextRecurrence(schedule);
      } else {
        // Remover de activas
        _activeSchedules.removeWhere((s) => s.id == schedule.id);
      }

      // Limpiar timer
      _scheduledTasks.remove(schedule.id);
      
      _notifyListeners();
      await _persistSchedules();
      
    } catch (e) {
      logger.d('❌ Error ejecutando notificación programada: $e');
    }
  }

  /// Programar siguiente ocurrencia recurrente
  Future<void> _scheduleNextRecurrence(ScheduledNotification schedule) async {
    if (!schedule.isRecurring || schedule.recurringInterval == null) return;

    final nextSchedule = schedule.copyWith(
      id: '${schedule.id.replaceAll(RegExp(r'_\d+$'), '')}_${DateTime.now().millisecondsSinceEpoch}',
      scheduledTime: schedule.scheduledTime.add(schedule.recurringInterval!),
      hasExecuted: false,
      executedAt: null,
    );

    await _scheduleNotification(nextSchedule);
    
    // Reemplazar en lista activa
    final index = _activeSchedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _activeSchedules[index] = nextSchedule;
    } else {
      _activeSchedules.add(nextSchedule);
    }
  }

  /// Manejar acción de notificación programada
  void _handleScheduledAction(ScheduledNotification schedule) {
    logger.d('🎮 Acción solicitada para: ${schedule.id}');
    
    // Aquí se conectaría con el sistema principal para ejecutar acciones
    // Por ejemplo: iniciar evento, finalizar evento, generar reporte, etc.
    
    switch (schedule.type) {
      case TeacherNotificationType.eventStartingSoon:
      case TeacherNotificationType.eventReminder:
        logger.d('🎯 Solicitud de iniciar evento: ${schedule.eventId}');
        // TODO: Integrar con EventService para iniciar evento
        break;
        
      case TeacherNotificationType.eventEndingSoon:
      case TeacherNotificationType.suggestEndEvent:
        logger.d('🏁 Solicitud de finalizar evento: ${schedule.eventId}');
        // TODO: Integrar con EventService para finalizar evento
        break;
        
      case TeacherNotificationType.suggestBreak:
        logger.d('☕ Solicitud de iniciar receso: ${schedule.eventId}');
        // TODO: Integrar con EventService para iniciar receso
        break;
        
      case TeacherNotificationType.weeklyReport:
      case TeacherNotificationType.monthlyReport:
        logger.d('📊 Solicitud de abrir reporte');
        // TODO: Integrar con ReportService para abrir reporte
        break;
        
      default:
        logger.d('⚠️ Acción no definida para tipo: ${schedule.type.name}');
    }
  }

  // ===========================================
  // 🗂️ GESTIÓN DE PROGRAMACIONES
  // ===========================================

  /// Cancelar todas las programaciones de un evento
  Future<void> cancelEventSchedules(String eventId) async {
    try {
      logger.d('🗑️ Cancelando programaciones para evento: $eventId');
      
      final eventSchedules = _eventSchedules[eventId] ?? [];
      var cancelledCount = 0;

      for (final schedule in eventSchedules) {
        final timer = _scheduledTasks[schedule.id];
        if (timer != null) {
          timer.cancel();
          _scheduledTasks.remove(schedule.id);
          cancelledCount++;
        }
      }

      // Remover de listas activas
      _activeSchedules.removeWhere((s) => s.eventId == eventId);
      _eventSchedules.remove(eventId);
      
      _notifyListeners();
      await _persistSchedules();
      
      logger.d('✅ $cancelledCount programaciones canceladas para evento: $eventId');
    } catch (e) {
      logger.d('❌ Error cancelando programaciones: $e');
    }
  }

  /// Cancelar una programación específica
  Future<void> cancelSchedule(String scheduleId) async {
    try {
      final timer = _scheduledTasks[scheduleId];
      if (timer != null) {
        timer.cancel();
        _scheduledTasks.remove(scheduleId);
        
        _activeSchedules.removeWhere((s) => s.id == scheduleId);
        
        // Remover de event schedules
        for (final eventSchedules in _eventSchedules.values) {
          eventSchedules.removeWhere((s) => s.id == scheduleId);
        }
        
        _notifyListeners();
        await _persistSchedules();
        
        logger.d('✅ Programación cancelada: $scheduleId');
      }
    } catch (e) {
      logger.d('❌ Error cancelando programación: $e');
    }
  }

  /// Obtener programaciones de un evento
  List<ScheduledNotification> getEventSchedules(String eventId) {
    return _eventSchedules[eventId] ?? [];
  }

  /// Obtener próximas programaciones
  List<ScheduledNotification> getUpcomingSchedules({int limit = 10}) {
    final upcoming = _activeSchedules
        .where((s) => !s.hasExecuted && s.scheduledTime.isAfter(DateTime.now()))
        .toList();
    
    upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    
    return upcoming.take(limit).toList();
  }

  // ===========================================
  // 💾 PERSISTENCIA
  // ===========================================

  /// Guardar programaciones en almacenamiento local
  Future<void> _persistSchedules() async {
    try {
      final data = {
        'activeSchedules': _activeSchedules.map((s) => s.toJson()).toList(),
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      final json = jsonEncode(data);
      await _storageService.saveData('teacher_notification_schedules', json);
    } catch (e) {
      logger.d('❌ Error persistiendo programaciones: $e');
    }
  }

  /// Cargar programaciones guardadas
  Future<void> _loadPersistedSchedules() async {
    try {
      final data = await _storageService.getData('teacher_notification_schedules');
      if (data == null) return;

      final json = jsonDecode(data);
      final schedules = (json['activeSchedules'] as List<dynamic>)
          .map((s) => ScheduledNotification.fromJson(s))
          .toList();

      _activeSchedules.clear();
      _activeSchedules.addAll(schedules);
      
      // Reagrupar por eventos
      _eventSchedules.clear();
      for (final schedule in schedules) {
        _eventSchedules.putIfAbsent(schedule.eventId, () => []).add(schedule);
      }
      
      logger.d('✅ ${schedules.length} programaciones cargadas desde almacenamiento');
    } catch (e) {
      logger.d('❌ Error cargando programaciones: $e');
    }
  }

  /// Reactivar programaciones pendientes después de reinicio
  Future<void> _reactivatePendingSchedules() async {
    try {
      final now = DateTime.now();
      var reactivatedCount = 0;

      for (final schedule in _activeSchedules) {
        if (!schedule.hasExecuted && schedule.scheduledTime.isAfter(now)) {
          await _scheduleNotification(schedule);
          reactivatedCount++;
        }
      }
      
      // Limpiar programaciones expiradas
      _activeSchedules.removeWhere((s) => 
          s.hasExecuted || s.scheduledTime.isBefore(now));
      
      _notifyListeners();
      await _persistSchedules();
      
      logger.d('✅ $reactivatedCount programaciones reactivadas');
    } catch (e) {
      logger.d('❌ Error reactivando programaciones: $e');
    }
  }

  // ===========================================
  // 🛠️ UTILIDADES
  // ===========================================

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
  }

  void _notifyListeners() {
    if (!_scheduleStreamController.isClosed) {
      _scheduleStreamController.add(List.from(_activeSchedules));
    }
  }

  // ===========================================
  // 🧹 LIMPIEZA
  // ===========================================

  /// Limpiar recursos del scheduler
  Future<void> dispose() async {
    try {
      logger.d('🧹 Limpiando TeacherNotificationScheduler');
      
      // Cancelar todos los timers
      for (final timer in _scheduledTasks.values) {
        timer.cancel();
      }
      _scheduledTasks.clear();
      
      // Cerrar streams
      if (!_scheduleStreamController.isClosed) {
        await _scheduleStreamController.close();
      }
      
      // Limpiar datos
      _activeSchedules.clear();
      _eventSchedules.clear();
      
      logger.d('✅ TeacherNotificationScheduler disposed');
    } catch (e) {
      logger.d('❌ Error disposing scheduler: $e');
    }
  }
}

/// Modelo para notificación programada
class ScheduledNotification {
  final String id;
  final String eventId;
  final DateTime scheduledTime;
  final TeacherNotificationType type;
  final String title;
  final String message;
  final String? actionText;
  final bool requiresAction;
  final bool isPriority;
  final bool isRecurring;
  final Duration? recurringInterval;
  final Map<String, dynamic>? metadata;
  final bool hasExecuted;
  final DateTime? executedAt;

  const ScheduledNotification({
    required this.id,
    required this.eventId,
    required this.scheduledTime,
    required this.type,
    required this.title,
    required this.message,
    this.actionText,
    this.requiresAction = false,
    this.isPriority = false,
    this.isRecurring = false,
    this.recurringInterval,
    this.metadata,
    this.hasExecuted = false,
    this.executedAt,
  });

  /// Marcar como ejecutada
  ScheduledNotification markAsExecuted() {
    return copyWith(
      hasExecuted: true,
      executedAt: DateTime.now(),
    );
  }

  /// Crear copia con modificaciones
  ScheduledNotification copyWith({
    String? id,
    String? eventId,
    DateTime? scheduledTime,
    TeacherNotificationType? type,
    String? title,
    String? message,
    String? actionText,
    bool? requiresAction,
    bool? isPriority,
    bool? isRecurring,
    Duration? recurringInterval,
    Map<String, dynamic>? metadata,
    bool? hasExecuted,
    DateTime? executedAt,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actionText: actionText ?? this.actionText,
      requiresAction: requiresAction ?? this.requiresAction,
      isPriority: isPriority ?? this.isPriority,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      metadata: metadata ?? this.metadata,
      hasExecuted: hasExecuted ?? this.hasExecuted,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'type': type.id,
      'title': title,
      'message': message,
      'actionText': actionText,
      'requiresAction': requiresAction,
      'isPriority': isPriority,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval?.inMilliseconds,
      'metadata': metadata,
      'hasExecuted': hasExecuted,
      'executedAt': executedAt?.toIso8601String(),
    };
  }

  /// Crear desde JSON
  static ScheduledNotification fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'],
      eventId: json['eventId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      type: TeacherNotificationType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => TeacherNotificationType.eventReminder,
      ),
      title: json['title'],
      message: json['message'],
      actionText: json['actionText'],
      requiresAction: json['requiresAction'] ?? false,
      isPriority: json['isPriority'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      recurringInterval: json['recurringInterval'] != null
          ? Duration(milliseconds: json['recurringInterval'])
          : null,
      metadata: json['metadata']?.cast<String, dynamic>(),
      hasExecuted: json['hasExecuted'] ?? false,
      executedAt: json['executedAt'] != null 
          ? DateTime.parse(json['executedAt']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'ScheduledNotification(id: $id, eventId: $eventId, scheduledTime: $scheduledTime, type: ${type.name})';
  }
}