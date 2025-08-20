// lib/screens/events/event_monitor_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart'; // ✅ NUEVO para backend real
import '../../models/evento_model.dart';
import '../../models/asistencia_model.dart'; // ✅ NUEVO para datos reales
import '../../services/websocket_service.dart';
import '../../services/notifications/notification_manager.dart';
import '../../services/teacher_notification_service.dart'; // ✅ NUEVO para notificaciones docente
import '../../services/teacher_notification_scheduler.dart'; // ✅ NUEVO para programaciones

class EventMonitorScreen extends StatefulWidget {
  final String teacherName;
  final String eventId; // ✅ OBLIGATORIO - evento específico a monitorear

  const EventMonitorScreen({
    super.key,
    required this.teacherName,
    required this.eventId,
  });

  @override
  State<EventMonitorScreen> createState() => _EventMonitorScreenState();
}

class _EventMonitorScreenState extends State<EventMonitorScreen>
    with TickerProviderStateMixin {
  // 🎯 SERVICIOS CON BACKEND REAL
  final EventoService _eventoService = EventoService();
  final AsistenciaService _asistenciaService = AsistenciaService(); // ✅ REAL

  // 🎯 SERVICIOS ADICIONALES PARA NOTIFICACIONES
  final NotificationManager _notificationManager = NotificationManager();
  
  // 🔔 SERVICIOS DE NOTIFICACIONES PARA DOCENTES
  final TeacherNotificationService _teacherNotificationService = TeacherNotificationService();
  final TeacherNotificationScheduler _teacherScheduler = TeacherNotificationScheduler();

  // 🎯 ESTADO DEL RECESO
  bool _isBreakActive = false;
  DateTime? _breakStartTime;
  Timer? _breakDurationTimer;

  // ✅ NUEVO WEBSOCKET ROBUSTO
  late StreamSubscription<Map<String, dynamic>> _wsSubscription;

  // 🎯 CONTROLADORES DE ANIMACIÓN
  late AnimationController _refreshController;
  late AnimationController _pulseController;

  // 🎯 ESTADO DE LA PANTALLA
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // 🎯 DATOS DEL EVENTO EN TIEMPO REAL
  Evento? _monitoredEvent;
  List<Asistencia> _studentActivities = []; // ✅ REAL desde backend
  
  // 📊 MÉTRICAS DE ASISTENCIA PARA NOTIFICACIONES
  int _totalStudentsExpected = 0;
  int _studentsPresent = 0;
  int _previousAttendanceCount = 0;

  // 🎯 TIMER PARA ACTUALIZACIÓN EN TIEMPO REAL
  Timer? _realtimeUpdateTimer;

  // 🎯 FILTROS Y CONFIGURACIÓN DE MONITOREO
  String _selectedFilter = 'all';
  bool _autoRefreshEnabled = true;
  bool _isEventActive = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNotificationManager();
    _initializeEventMonitor();
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing EventMonitorScreen resources');
    
    // Cancel all timers
    _refreshController.dispose();
    _pulseController.dispose();
    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = null;
    _breakDurationTimer?.cancel();
    _breakDurationTimer = null;

    // ✅ NUEVO: Limpiar WebSocket robusto
    _cleanupWebSocketConnection();
    
    // ✅ NUEVO: Limpiar servicios de notificaciones docentes
    _disposeTeacherNotificationServices();

    super.dispose();
    debugPrint('✅ EventMonitorScreen disposed successfully');
  }
  
  /// ✅ NUEVO: Limpiar servicios de notificaciones docentes
  Future<void> _disposeTeacherNotificationServices() async {
    try {
      debugPrint('🔔 Limpiando servicios de notificaciones docentes');
      
      // Cancelar programaciones del evento actual
      await _teacherScheduler.cancelEventSchedules(widget.eventId);
      
      // Limpiar scheduler
      await _teacherScheduler.dispose();
      
      // Limpiar servicio de notificaciones (sin dispose completo para no afectar otros usos)
      // El TeacherNotificationService se mantiene activo para otros eventos
      
      debugPrint('✅ Servicios de notificaciones docentes limpiados');
    } catch (e) {
      debugPrint('❌ Error limpiando servicios de notificaciones: $e');
    }
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeNotificationManager() async {
    try {
      await _notificationManager.initialize();
      debugPrint('✅ NotificationManager inicializado para EventMonitor');
      
      // ✅ NUEVO: Inicializar sistema de notificaciones para docentes
      await _initializeTeacherNotificationSystem();
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationManager: $e');
    }
  }
  
  /// ✅ NUEVO: Inicializar sistema completo de notificaciones para docentes
  Future<void> _initializeTeacherNotificationSystem() async {
    try {
      debugPrint('🔔 Inicializando sistema de notificaciones para docentes');
      
      // Inicializar TeacherNotificationService
      await _teacherNotificationService.initialize();
      
      // Inicializar TeacherNotificationScheduler
      await _teacherScheduler.initialize();
      
      // Si hay evento cargado, programar notificaciones
      if (_monitoredEvent != null) {
        await _scheduleEventTeacherNotifications(_monitoredEvent!);
      }
      
      debugPrint('✅ Sistema de notificaciones para docentes inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones docentes: $e');
    }
  }

  Future<void> _initializeEventMonitor() async {
    debugPrint('🎯 Inicializando EventMonitor para evento: ${widget.eventId}');

    try {
      // 1. Cargar evento específico a monitorear
      await _loadMonitoredEvent();

      // 2. Cargar asistencias del evento en tiempo real
      await _loadEventAttendances();

      // 3. Iniciar actualización en tiempo real cada 30 segundos
      _startRealtimeUpdates();
      
      // 4. ✅ NUEVO: Conectar WebSocket robusto
      await _initializeWebSocketConnection();
      
      // 5. ✅ NUEVO: Iniciar actualización periódica de asistencia (cada 15 min)
      _startAttendanceUpdateNotifications();
    } catch (e) {
      debugPrint('❌ Error inicializando event monitor: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error inicializando monitoreo: $e';
        });
      }
    }
  }

  Future<void> _loadMonitoredEvent() async {
    try {
      debugPrint('📊 Cargando evento para monitoreo: ${widget.eventId}');

      // ✅ CORREGIDO: EventoService retorna List<Evento> directamente
      final eventos = await _eventoService.obtenerEventos();

      final event = eventos.firstWhere(
        (e) => e.id == widget.eventId,
        orElse: () => throw Exception('Evento no encontrado'),
      );

      if (mounted) {
        setState(() {
          _monitoredEvent = event;
          _isEventActive = event.isActive;
        });
      }
      
      // ✅ NUEVO: Programar notificaciones para el evento
      await _scheduleEventTeacherNotifications(event);
      
      // ✅ NUEVO: Establecer métricas iniciales
      await _initializeEventMetrics(event);

      debugPrint(
          '✅ Evento cargado: ${event.titulo}, activo: ${event.isActive}');
    } catch (e) {
      debugPrint('❌ Error cargando evento: $e');
      rethrow; // ✅ CORREGIDO: usar rethrow
    }
  }

  Future<void> _loadEventAttendances() async {
    try {
      debugPrint('👥 Cargando asistencias del evento: ${widget.eventId}');

      // ✅ CORREGIDO: AsistenciaService retorna List<Asistencia> directamente
      final asistencias =
          await _asistenciaService.obtenerAsistenciasEvento(widget.eventId);

      if (mounted) {
        setState(() {
          _studentActivities = asistencias;
        });
      }
      
      // ✅ NUEVO: Actualizar métricas y enviar notificaciones si hay cambios
      await _updateAttendanceMetrics(asistencias);

      debugPrint('✅ Asistencias cargadas: ${asistencias.length} registros');
    } catch (e) {
      debugPrint('❌ Error cargando asistencias: $e');
      // No interrumpir el flujo si falla las asistencias
    }
  }

  Future<void> _loadRealtimeMetrics() async {
    try {
      debugPrint(
          '📊 Cargando métricas en tiempo real del evento: ${widget.eventId}');

      // ✅ CORREGIDO: EventoService retorna Map<String, dynamic> directamente
      final metrics =
          await _eventoService.obtenerMetricasEvento(widget.eventId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      debugPrint('✅ Métricas cargadas: $metrics');
    } catch (e) {
      debugPrint('❌ Error cargando métricas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// ✅ NUEVO: Programar notificaciones para el evento
  Future<void> _scheduleEventTeacherNotifications(Evento event) async {
    try {
      debugPrint('📅 Programando notificaciones para docente: ${event.titulo}');
      
      // Programar notificaciones temporales
      await _teacherScheduler.scheduleEventNotifications(event);
      
      // Programar sugerencias de receso para eventos largos
      if (event.duracionMinutos >= 90) {
        await _teacherScheduler.scheduleBreakSuggestions(event);
      }
      
      debugPrint('✅ Notificaciones programadas para: ${event.titulo}');
    } catch (e) {
      debugPrint('❌ Error programando notificaciones: $e');
    }
  }
  
  /// ✅ NUEVO: Inicializar métricas del evento
  Future<void> _initializeEventMetrics(Evento event) async {
    try {
      // Obtener cantidad esperada de estudiantes (esto podría venir del backend)
      // Por ahora, usar un valor estimado o configurado
      _totalStudentsExpected = 30; // TODO: Obtener del backend
      
      // Contar estudiantes actuales presentes
      _studentsPresent = _studentActivities
          .where((a) => a.estado == 'presente')
          .length;
      
      _previousAttendanceCount = _studentsPresent;
      
      debugPrint('📊 Métricas inicializadas - Esperados: $_totalStudentsExpected, Presentes: $_studentsPresent');
    } catch (e) {
      debugPrint('❌ Error inicializando métricas: $e');
    }
  }
  
  /// ✅ NUEVO: Actualizar métricas y enviar notificaciones de cambios de asistencia
  Future<void> _updateAttendanceMetrics(List<Asistencia> asistencias) async {
    try {
      final newStudentsPresent = asistencias
          .where((a) => a.estado == 'presente')
          .length;
      
      // Verificar si hay nuevos estudiantes registrados
      if (newStudentsPresent > _studentsPresent) {
        final newStudents = newStudentsPresent - _studentsPresent;
        
        // Obtener nombres de nuevos estudiantes registrados
        final recentStudents = asistencias
            .where((a) => a.estado == 'presente')
            .toList()
            ..sort((a, b) => (b.fechaRegistro ?? DateTime.now())
                .compareTo(a.fechaRegistro ?? DateTime.now()));
        
        // Notificar estudiante(s) registrado(s)
        if (newStudents == 1 && recentStudents.isNotEmpty) {
          // Un estudiante individual
          await _teacherNotificationService.notifyStudentJoined(
            studentName: recentStudents.first.nombreUsuario ?? 'Estudiante',
            eventTitle: _monitoredEvent?.titulo ?? 'Evento',
            eventId: widget.eventId,
            currentAttendance: newStudentsPresent,
            totalStudents: _totalStudentsExpected,
          );
        } else if (newStudents > 1) {
          // Múltiples estudiantes
          final studentNames = recentStudents
              .take(newStudents)
              .map((a) => a.nombreUsuario ?? 'Estudiante')
              .toList();
          
          await _teacherNotificationService.notifyMultipleStudentsJoined(
            studentNames: studentNames,
            eventTitle: _monitoredEvent?.titulo ?? 'Evento',
            eventId: widget.eventId,
            currentAttendance: newStudentsPresent,
            totalStudents: _totalStudentsExpected,
          );
        }
      }
      
      // Actualizar métricas
      _studentsPresent = newStudentsPresent;
      
      debugPrint('📊 Métricas actualizadas - Presentes: $_studentsPresent/$_totalStudentsExpected');
    } catch (e) {
      debugPrint('❌ Error actualizando métricas de asistencia: $e');
    }
  }

  void _startRealtimeUpdates() {
    if (!_autoRefreshEnabled) return;

    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (mounted && _autoRefreshEnabled) {
          debugPrint('🔄 Actualizando datos en tiempo real...');
          await _refreshData();
        }
      },
    );

    debugPrint('✅ Auto-actualización iniciada cada 30 segundos');
  }
  
  /// ✅ NUEVO: Iniciar notificaciones de actualización de asistencia cada 15 minutos
  void _startAttendanceUpdateNotifications() {
    // Timer para enviar actualizaciones periódicas de asistencia al docente
    Timer.periodic(Duration(minutes: 15), (timer) async {
      if (!mounted || _monitoredEvent == null) {
        timer.cancel();
        return;
      }
      
      try {
        // Enviar notificación de actualización de asistencia
        await _teacherNotificationService.notifyAttendanceUpdate(
          eventTitle: _monitoredEvent!.titulo,
          eventId: widget.eventId,
          presentStudents: _studentsPresent,
          totalStudents: _totalStudentsExpected,
          trend: _getAttendanceTrend(),
        );
        
        debugPrint('📊 Notificación de asistencia enviada: $_studentsPresent/$_totalStudentsExpected');
      } catch (e) {
        debugPrint('❌ Error enviando actualización de asistencia: $e');
      }
    });
    
    debugPrint('📊 Notificaciones de asistencia cada 15 min iniciadas');
  }
  
  /// ✅ NUEVO: Calcular tendencia de asistencia
  String? _getAttendanceTrend() {
    if (_previousAttendanceCount == _studentsPresent) {
      return 'estable';
    } else if (_studentsPresent > _previousAttendanceCount) {
      return 'creciente ↗️';
    } else {
      return 'decreciente ↘️';
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();

    try {
      await Future.wait([
        _loadEventAttendances(),
        _loadRealtimeMetrics(),
        _loadMonitoredEvent(), // Verificar cambios en el evento
      ]);
    } catch (e) {
      debugPrint('❌ Error actualizando datos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
      _refreshController.reset();
    }
  }

  void _manualRefresh() {
    debugPrint('🔄 Actualización manual solicitada');
    _refreshData();
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _startRealtimeUpdates();
      debugPrint('✅ Auto-actualización activada');
    } else {
      _realtimeUpdateTimer?.cancel();
      debugPrint('⏸️ Auto-actualización pausada');
    }
  }

  // 🎯 CONTROL DE EVENTOS EN TIEMPO REAL
  Future<void> _activateEvent() async {
    try {
      debugPrint('▶️ Activando evento: ${widget.eventId}');

      // ✅ CORREGIDO: EventoService retorna bool directamente
      final result = await _eventoService.activarEvento(widget.eventId);

      if (result) {
        setState(() {
          _isEventActive = true;
          if (_monitoredEvent != null) {
            _monitoredEvent = _monitoredEvent!.copyWith(isActive: true);
          }
        });

        // Actualizar datos inmediatamente
        await _refreshData();

        if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento activado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        debugPrint('✅ Evento activado exitosamente');
      } else {
        if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error activando evento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error activando evento: $e');
      if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error activando evento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateEvent() async {
    try {
      debugPrint('⏹️ Desactivando evento: ${widget.eventId}');

      // ✅ CORREGIDO: EventoService retorna bool directamente
      final result = await _eventoService.desactivarEvento(widget.eventId);

      if (result) {
        setState(() {
          _isEventActive = false;
          if (_monitoredEvent != null) {
            _monitoredEvent = _monitoredEvent!.copyWith(isActive: false);
          }
        });

        await _refreshData();

        if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento desactivado exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );

        debugPrint('✅ Evento desactivado exitosamente');
      } else {
        if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error desactivando evento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error desactivando evento: $e');
      if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error desactivando evento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endBreak() async {
    try {
      debugPrint('▶️ Terminando receso para evento: ${widget.eventId}');

      // 1. Obtener duración como texto ANTES de limpiar _breakStartTime
      final breakDurationText = _getBreakDurationText();

      // 2. Llamar al backend para terminar receso
      final result = await _eventoService.terminarReceso(widget.eventId);

      if (result) {
        // 3. Limpiar timers ANTES de actualizar estado
        _stopBreakDurationTimer();

        // 4. Actualizar estado local
        setState(() {
          _isBreakActive = false;
          _breakStartTime = null;
        });

        // 5. Notificar a estudiantes automáticamente
        await _notificationManager.showBreakEndedNotification(widget.eventId);

        // 6. Refrescar datos para sincronizar con backend
        await _refreshData();

        // 7. Mostrar confirmación al profesor con duración
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.play_circle_filled, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('▶️ Receso terminado'),
                      Text(
                        'Duración: $breakDurationText - Estudiantes notificados',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white
                              .withValues(alpha: 0.8), // ✅ CORREGIDO
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        debugPrint(
            '✅ Receso terminado exitosamente. Duración: $breakDurationText');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error terminando receso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error terminando receso: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error terminando receso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startBreak() async {
    try {
      debugPrint('⏸️ Iniciando receso para evento: ${widget.eventId}');

      final result = await _eventoService.iniciarReceso(widget.eventId);

      if (result) {
        setState(() {
          _isBreakActive = true;
          _breakStartTime = DateTime.now();
        });

        _startBreakDurationTimer();
        await _notificationManager.showBreakStartedNotification(widget.eventId);
        await _refreshData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.pause_circle_filled, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⏸️ Receso iniciado'),
                      Text(
                        'Estudiantes notificados automáticamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white
                              .withValues(alpha: 0.8), // ✅ CORREGIDO
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Terminar',
              textColor: Colors.white,
              onPressed: _endBreak,
            ),
          ),
        );

        debugPrint(
            '✅ Receso iniciado exitosamente a las ${_formatTime(_breakStartTime!)}');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error iniciando receso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error iniciando receso: $e');

      setState(() {
        _isBreakActive = false;
        _breakStartTime = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error iniciando receso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Iniciar timer para actualizar duración del receso en tiempo real
  void _startBreakDurationTimer() {
    _breakDurationTimer?.cancel(); // Cancelar timer previo si existe

    _breakDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isBreakActive && _breakStartTime != null) {
        setState(() {}); // Trigger rebuild para actualizar UI
      } else {
        timer.cancel(); // Auto-cancelar si no cumple condiciones
      }
    });

    debugPrint('⏰ Timer de duración de receso iniciado');
  }

  /// Detener timer de duración del receso
  void _stopBreakDurationTimer() {
    _breakDurationTimer?.cancel();
    _breakDurationTimer = null;
    debugPrint('⏰ Timer de duración de receso detenido');
  }

  /// Obtener duración actual del receso como Duration
  Duration _getBreakDuration() {
    if (_breakStartTime == null) return Duration.zero;
    return DateTime.now().difference(_breakStartTime!);
  }

  /// Obtener duración del receso como texto formateado
  String _getBreakDurationText() {
    if (_breakStartTime == null) return '00:00';

    final duration = _getBreakDuration();
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatear DateTime a texto legible
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // ✅ WIDGET PARA MOSTRAR ESTADO DEL RECESO (OPCIONAL - AGREGAR A TU UI)
  Widget _buildBreakStatusWidget() {
    if (!_isBreakActive || _breakStartTime == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1), // ✅ CORREGIDO
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_circle_filled, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Receso Activo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Duración: ${_getBreakDurationText()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _endBreak,
            icon: const Icon(Icons.play_circle_filled, size: 18),
            label: const Text('Terminar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Column(
        // ✅ CAMBIAR DE body directo a Column
        children: [
          // ✅ AGREGAR: Widget de estado del receso
          _buildBreakStatusWidget(),

          // ✅ MODIFICAR: Tu contenido existente pero expandido
          Expanded(
            child:
                _isLoading ? _buildLoadingState() : _buildEventMonitorContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white, // ✅ CORREGIDO: Usar color básico
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitor de Evento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_monitoredEvent != null)
            Text(
              _monitoredEvent!.titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      actions: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualRefresh,
            tooltip: 'Actualizar datos',
          ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'auto_refresh',
              child: Row(
                children: [
                  Icon(
                    _autoRefreshEnabled ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(_autoRefreshEnabled
                      ? 'Pausar actualización'
                      : 'Activar actualización'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Configuración'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Ayuda'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando monitor de evento...',
            style: TextStyle(
              color: Colors.grey, // ✅ CORREGIDO: Color básico
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMonitorContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control del evento
            _buildEventControlPanel(),
            const SizedBox(height: 16),

            // Métricas en tiempo real
            _buildRealTimeMetrics(),
            const SizedBox(height: 16),

            // Lista de actividad de estudiantes
            _buildStudentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red, // ✅ CORREGIDO: Usar color básico
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red, // ✅ CORREGIDO: Usar color básico
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _initializeEventMonitor();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventControlPanel() {
    if (_monitoredEvent == null) {
      return const SizedBox.shrink();
    }

    // ✅ CORREGIDO: Widget personalizado en lugar de EventControlPanelWidget
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control del Evento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEventActive ? _deactivateEvent : _activateEvent,
                  icon: Icon(_isEventActive ? Icons.stop : Icons.play_arrow),
                  label: Text(_isEventActive ? 'Desactivar' : 'Activar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEventActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_isEventActive) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBreakActive ? _endBreak : _startBreak,
                    icon: Icon(_isBreakActive ? Icons.play_arrow : Icons.pause),
                    label: Text(
                        _isBreakActive ? 'Terminar Receso' : 'Iniciar Receso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isBreakActive ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: SizedBox(), // Espaciador cuando evento no está activo
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics() {
    // ✅ CORREGIDO: Widget personalizado en lugar de RealTimeMetricsWidget
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Métricas en Tiempo Real',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Estudiantes Activos',
                  '${_studentActivities.length}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Presentes',
                  '${_studentActivities.where((a) => a.estado == 'presente').length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentActivityList() {
    // ✅ CORREGIDO: Widget personalizado en lugar de StudentActivityListWidget
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad de Estudiantes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_studentActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay actividad de estudiantes',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _studentActivities.length,
              itemBuilder: (context, index) {
                final activity = _studentActivities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(activity.estado),
                    child: Icon(
                      _getStatusIcon(activity.estado),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(activity.usuario),
                  subtitle: Text('Estado: ${activity.estado}'),
                  trailing: Text(
                    '${activity.hora.hour}:${activity.hora.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Colors.green;
      case 'ausente':
        return Colors.red;
      case 'tarde':
        return Colors.orange;
      case 'receso':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Icons.check;
      case 'ausente':
        return Icons.close;
      case 'tarde':
        return Icons.access_time;
      case 'receso':
        return Icons.pause;
      default:
        return Icons.help;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'auto_refresh':
        _toggleAutoRefresh();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración del Monitor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-actualización'),
              subtitle: const Text('Actualizar datos cada 30 segundos'),
              value: _autoRefreshEnabled,
              onChanged: (_) => _toggleAutoRefresh(),
            ),
            ListTile(
              title: const Text('Filtros de estudiantes'),
              subtitle: Text('Actual: $_selectedFilter'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pop();
                _showFilterDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Estudiantes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Presentes'),
              leading: Radio<String>(
                value: 'present',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Ausentes'),
              leading: Radio<String>(
                value: 'absent',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monitor de Evento'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Características del Monitor:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Monitoreo en tiempo real de asistencia'),
              Text('• Control de activación/desactivación de eventos'),
              Text('• Gestión de recesos durante la clase'),
              Text('• Actualización automática cada 30 segundos'),
              Text('• Filtros de estudiantes por estado'),
              Text('• Métricas de participación en vivo'),
              SizedBox(height: 16),
              Text(
                'Controles Disponibles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Activar/Desactivar: Permite unirse al evento'),
              Text('• Iniciar Receso: Pausa el tracking temporal'),
              Text('• Terminar Receso: Reanuda el tracking'),
              Text('• Actualización Manual: Fuerza actualización'),
              SizedBox(height: 16),
              Text(
                'Desarrollado para el sistema de asistencia por geolocalización.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }


  
  /// ✅ NUEVO: Manejar notificación de estudiante que se registró
  Future<void> _handleStudentJoinedNotification(String studentName, Map<String, dynamic> data) async {
    try {
      final int currentAttendance = data['currentAttendance'] ?? _studentsPresent;
      
      await _teacherNotificationService.notifyStudentJoined(
        studentName: studentName,
        eventTitle: _monitoredEvent?.titulo ?? 'Evento',
        eventId: widget.eventId,
        currentAttendance: currentAttendance,
        totalStudents: _totalStudentsExpected,
      );
      
      debugPrint('✅ Notificación enviada: estudiante $studentName se registró');
    } catch (e) {
      debugPrint('❌ Error enviando notificación de estudiante registrado: $e');
    }
  }
  
  /// ✅ NUEVO: Manejar notificación de estudiante que salió del área
  Future<void> _handleStudentLeftAreaNotification(String studentName, Map<String, dynamic> data) async {
    try {
      final String? timeOutside = data['timeOutside'];
      
      await _teacherNotificationService.notifyStudentLeftArea(
        studentName: studentName,
        eventTitle: _monitoredEvent?.titulo ?? 'Evento',
        eventId: widget.eventId,
        timeOutside: timeOutside,
      );
      
      debugPrint('🚨 Notificación enviada: estudiante $studentName salió del área');
    } catch (e) {
      debugPrint('❌ Error enviando notificación de estudiante que salió: $e');
    }
  }
  
  /// ✅ NUEVO: Manejar actualizaciones de múltiples estudiantes
  Future<void> _handleMultipleStudentsUpdate(Map<String, dynamic> data) async {
    try {
      final List<String> studentNames = List<String>.from(data['studentNames'] ?? []);
      final String actionType = data['actionType'] ?? 'unknown';
      final int currentAttendance = data['currentAttendance'] ?? _studentsPresent;
      
      if (actionType == 'joined' && studentNames.isNotEmpty) {
        await _teacherNotificationService.notifyMultipleStudentsJoined(
          studentNames: studentNames,
          eventTitle: _monitoredEvent?.titulo ?? 'Evento',
          eventId: widget.eventId,
          currentAttendance: currentAttendance,
          totalStudents: _totalStudentsExpected,
        );
        
        debugPrint('✅ Notificación enviada: ${studentNames.length} estudiantes se registraron');
      }
    } catch (e) {
      debugPrint('❌ Error enviando notificación de múltiples estudiantes: $e');
    }
  }
  
  /// ✅ NUEVO: Manejar actualización de conteo de asistencia
  Future<void> _handleAttendanceCountUpdate(Map<String, dynamic> data) async {
    try {
      final int newCount = data['presentCount'] ?? _studentsPresent;
      final String? trend = data['trend'];
      
      // Solo enviar notificación si hay cambios significativos
      if ((newCount - _studentsPresent).abs() >= 3) {
        await _teacherNotificationService.notifyAttendanceUpdate(
          eventTitle: _monitoredEvent?.titulo ?? 'Evento',
          eventId: widget.eventId,
          presentStudents: newCount,
          totalStudents: _totalStudentsExpected,
          trend: trend,
        );
        
        debugPrint('📊 Notificación de conteo enviada: $newCount/$_totalStudentsExpected');
      }
      
      // Actualizar métricas locales
      _previousAttendanceCount = _studentsPresent;
      _studentsPresent = newCount;
    } catch (e) {
      debugPrint('❌ Error enviando actualización de conteo: $e');
    }
  }







  /// Método auxiliar para notificaciones rápidas
  void _showNotification(String title, String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message),
            ],
          ),
          backgroundColor: backgroundColor ?? AppColors.primaryOrange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ ENHANCED: WebSocket helper methods for connection management






  // ✅ ENHANCED: Message handlers for new message types







  /// ✅ NUEVO: Inicializar conexión WebSocket robusta
  Future<void> _initializeWebSocketConnection() async {
    try {
      debugPrint('📊 Iniciando conexión WebSocket para monitoreo del evento: ${widget.eventId}');
      
      // ✅ CONECTAR WEBSOCKET ESPECÍFICO PARA MONITOREO
      final connected = await WebSocketService.instance.connectToEvent(
        eventId: widget.eventId,
        userId: widget.teacherName, // O ID del profesor
        userRole: 'teacher',
      );
      
      if (connected) {
        // ✅ ESCUCHAR MENSAJES EN TIEMPO REAL
        _wsSubscription = WebSocketService.instance.messageStream.listen(
          _handleRealtimeUpdate,
          onError: (error) {
            debugPrint('❌ Error en stream WebSocket: $error');
            _showConnectionError();
          },
        );
        
        debugPrint('✅ Monitoreo WebSocket iniciado');
      } else {
        _showConnectionError();
      }
      
    } catch (e) {
      debugPrint('❌ Error inicializando WebSocket: $e');
      _showConnectionError();
    }
  }

  /// ✅ NUEVO: Manejar actualizaciones en tiempo real
  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    
    setState(() {
      switch (messageType) {
        case 'attendance_update':
          _handleWebSocketAttendanceUpdate(data);
          break;
          
        case 'student_location_update':
          _handleStudentLocationUpdate(data);
          break;
          
        case 'geofence_violation':
          _handleWebSocketGeofenceViolation(data);
          break;
          
        case 'metrics_update':
          _handleWebSocketMetricsUpdate(data);
          break;
      }
    });
    
    // ✅ MOSTRAR NOTIFICACIÓN AL PROFESOR
    _showTeacherNotification(data);
  }

  /// ✅ NUEVO: Manejar actualización de asistencia via WebSocket
  void _handleWebSocketAttendanceUpdate(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    final attendanceStatus = data['attendanceStatus'] as String?;
    final timestamp = data['timestamp'] as String?;
    
    debugPrint('📝 Actualización de asistencia via WebSocket: $studentName -> $attendanceStatus');
    
    // ✅ USAR MÉTODOS DE NOTIFICACIÓN PARA PROFESORES
    if (attendanceStatus == 'presente') {
      _handleStudentJoinedNotification(studentName, data);
    }
    
    // Actualizar lista de asistencia en tiempo real
    if (attendanceStatus != null) {
      _updateAttendanceList(studentName, attendanceStatus, timestamp);
    }
  }

  /// ✅ NUEVO: Actualizar lista de asistencia en tiempo real
  void _updateAttendanceList(String studentName, String status, String? timestamp) {
    // Aquí se actualizaría la lista de asistencias en tiempo real
    // Por ahora, recargar los datos
    _loadEventAttendances();
  }

  /// ✅ NUEVO: Manejar actualización de ubicación de estudiante
  void _handleStudentLocationUpdate(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;
    
    debugPrint('📍 Actualización de ubicación: $studentName ($latitude, $longitude)');
  }

  /// ✅ NUEVO: Manejar violación de geofence via WebSocket
  void _handleWebSocketGeofenceViolation(Map<String, dynamic> data) {
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    final gracePeriodSeconds = data['gracePeriodSeconds'] as int? ?? 60;
    
    debugPrint('⚠️ Violación de geofence: $studentName (${gracePeriodSeconds}s de gracia)');
    
    // ✅ USAR MÉTODO DE NOTIFICACIÓN PARA PROFESORES
    _handleStudentLeftAreaNotification(studentName, data);
  }

  /// ✅ NUEVO: Manejar actualización de métricas via WebSocket
  void _handleWebSocketMetricsUpdate(Map<String, dynamic> data) {
    final totalStudents = data['totalStudents'] as int? ?? 0;
    final presentStudents = data['presentStudents'] as int? ?? 0;
    
    debugPrint('📊 Métricas actualizadas via WebSocket: $presentStudents/$totalStudents estudiantes');
    
    // ✅ USAR MÉTODO DE NOTIFICACIÓN PARA ACTUALIZACIONES DE ASISTENCIA
    _handleAttendanceCountUpdate(data);
    
    setState(() {
      _totalStudentsExpected = totalStudents;
      _studentsPresent = presentStudents;
    });
  }

  /// ✅ NUEVO: Mostrar notificación al profesor
  void _showTeacherNotification(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    final studentName = data['studentName'] as String? ?? 'Estudiante';
    
    String message = '';
    Color color = Colors.orange;
    
    switch (messageType) {
      case 'attendance_update':
        message = '$studentName registró asistencia';
        color = Colors.green;
        break;
      case 'geofence_violation':
        message = '$studentName salió del área del evento';
        color = Colors.orange;
        break;
      case 'student_joined':
        message = '$studentName se unió al evento';
        color = Colors.blue;
        break;
      case 'multiple_students':
        final count = data['count'] as int? ?? 2;
        message = '$count estudiantes realizaron acciones';
        color = Colors.blue;
        // ✅ USAR MÉTODO PARA MÚLTIPLES ESTUDIANTES
        _handleMultipleStudentsUpdate(data);
        break;
    }
    
    if (message.isNotEmpty && mounted) {
      // ✅ USAR MÉTODO UNIFICADO DE NOTIFICACIONES CON COLOR
      _showNotification('Actualización del Evento', message, backgroundColor: color);
    }
  }

  /// ✅ NUEVO: Mostrar error de conexión
  void _showConnectionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error de conexión WebSocket'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  /// ✅ NUEVO: Limpiar conexión WebSocket
  void _cleanupWebSocketConnection() async {
    try {
      await _wsSubscription.cancel();
      await WebSocketService.instance.disconnect();
      debugPrint('✅ WebSocket connection cleaned up');
    } catch (e) {
      debugPrint('❌ Error cleaning up WebSocket: $e');
    }
  }
}
