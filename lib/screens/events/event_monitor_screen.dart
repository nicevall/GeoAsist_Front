// lib/screens/events/event_monitor_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart'; // ✅ NUEVO para backend real
import '../../models/evento_model.dart';
import '../../models/asistencia_model.dart'; // ✅ NUEVO para datos reales
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../services/notifications/notification_manager.dart';
import '../../services/storage_service.dart';
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
  final StorageService _storageService = StorageService();
  
  // 🔔 SERVICIOS DE NOTIFICACIONES PARA DOCENTES
  final TeacherNotificationService _teacherNotificationService = TeacherNotificationService();
  final TeacherNotificationScheduler _teacherScheduler = TeacherNotificationScheduler();

  // 🎯 ESTADO DEL RECESO
  bool _isBreakActive = false;
  DateTime? _breakStartTime;
  Timer? _breakDurationTimer;

  // 🎯 WEBSOCKET REAL - ENHANCED CONNECTION MANAGEMENT
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectionTimer;
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

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
  DateTime? _lastAttendanceUpdate;

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
    
    // Stop reconnection attempts
    _shouldReconnect = false;
    
    // Cancel all timers
    _refreshController.dispose();
    _pulseController.dispose();
    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = null;
    _breakDurationTimer?.cancel();
    _breakDurationTimer = null;
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    // ✅ ENHANCED: Clean WebSocket with proper error handling
    _cleanupWebSocket();
    
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
      
      // 4. ✅ ENHANCED: Connect WebSocket with improved error handling
      await _connectWebSocketWithRetry();
      
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
      _lastAttendanceUpdate = DateTime.now();
      
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
      _lastAttendanceUpdate = DateTime.now();
      
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

  /// ✅ ENHANCED: Connect WebSocket with retry mechanism
  Future<void> _connectWebSocketWithRetry() async {
    if (_isConnecting || !_shouldReconnect) {
      debugPrint('🔌 WebSocket connection already in progress or stopped');
      return;
    }

    _isConnecting = true;
    
    try {
      await _connectWebSocket();
      _reconnectionAttempts = 0; // Reset on successful connection
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _scheduleReconnection();
    } finally {
      _isConnecting = false;
    }
  }

  /// ✅ ENHANCED: Core WebSocket connection logic
  Future<void> _connectWebSocket() async {
    debugPrint('🔌 Connecting WebSocket with enhanced stability');

    // ✅ ENHANCED: Validate prerequisites
    final token = await _storageService.getToken();
    if (token == null) {
      debugPrint('❌ No JWT token available for WebSocket authentication');
      throw Exception('No authentication token available');
    }

    if (widget.eventId.isEmpty) {
      debugPrint('❌ No eventId provided for WebSocket connection');
      throw Exception('Invalid event ID');
    }

    // ✅ ENHANCED: Build WebSocket URL with proper authentication
    final wsUrl = 'ws://44.211.171.188?token=$token&eventId=${widget.eventId}&role=docente';
    debugPrint('📡 Connecting to WebSocket: ws://44.211.171.188?token=***&eventId=${widget.eventId}&role=docente');

    // ✅ ENHANCED: Connect with timeout
    _wsChannel = WebSocketChannel.connect(
      Uri.parse(wsUrl),
      protocols: ['chat'], // Optional: specify protocols if needed
    );

    // ✅ ENHANCED: Send subscription message with additional metadata
    final user = await _storageService.getUser();
    final subscriptionMessage = jsonEncode({
      'action': 'subscribe_event_monitor',
      'eventId': widget.eventId,
      'userRole': 'docente',
      'userId': user?.id ?? 'unknown',
      'teacherName': widget.teacherName,
      'timestamp': DateTime.now().toIso8601String(),
      'clientType': 'flutter_event_monitor',
      'version': '1.0.0',
      'capabilities': ['attendance_updates', 'event_control', 'metrics', 'break_management'],
    });

    _wsChannel!.sink.add(subscriptionMessage);
    debugPrint('📤 Enhanced subscription message sent');

    // ✅ ENHANCED: Setup message handling with robust error handling
    _wsSubscription = _wsChannel!.stream.listen(
      _handleWebSocketMessage,
      onError: _handleWebSocketError,
      onDone: _handleWebSocketClosed,
      cancelOnError: false, // Keep connection alive on individual message errors
    );

    // ✅ ENHANCED: Start heartbeat to maintain connection
    _startHeartbeat();

    // ✅ ENHANCED: Show connection success with more info
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📡 Conexión tiempo real activada',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Evento: ${_monitoredEvent?.titulo ?? widget.eventId}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    debugPrint('✅ WebSocket connected successfully with enhanced features');
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

  /// ✅ ENHANCED: WebSocket message handling with validation and acknowledgment
  void _handleWebSocketMessage(dynamic message) {
    try {
      // ✅ ENHANCED: Validate message format
      if (message == null || message.toString().isEmpty) {
        debugPrint('⚠️ Received empty WebSocket message');
        return;
      }

      final Map<String, dynamic> data = jsonDecode(message);
      final String messageType = data['type'] ?? 'unknown';
      final String messageId = data['id'] ?? '';
      
      debugPrint('📨 WebSocket message received: $messageType${messageId.isNotEmpty ? ' (ID: $messageId)' : ''}');

      // ✅ ENHANCED: Validate event ID matches current monitoring
      if (data.containsKey('eventId') && data['eventId'] != widget.eventId) {
        debugPrint('⚠️ Message for different event: ${data['eventId']}, current: ${widget.eventId}');
        return;
      }

      // ✅ ENHANCED: Handle different message types with enhanced processing
      switch (messageType) {
        case 'connection_established':
          _handleConnectionEstablished(data);
          break;
        case 'attendance_update':
          _handleAttendanceUpdate(data);
          break;
        case 'event_status_changed':
          _handleEventStatusChanged(data);
          break;
        case 'break_status_changed':
          _handleBreakStatusChanged(data);
          break;
        case 'metrics_update':
          _handleMetricsUpdate(data);
          break;
        case 'heartbeat_response':
          _handleHeartbeatResponse(data);
          break;
        case 'error':
          _handleServerError(data);
          break;
        default:
          debugPrint('📋 Unhandled message type: $messageType');
          // ✅ ENHANCED: Send acknowledgment for unknown messages
          _sendAcknowledgment(messageId, false, 'Unknown message type');
      }

      // ✅ ENHANCED: Send acknowledgment for processed messages
      if (messageId.isNotEmpty && messageType != 'heartbeat_response') {
        _sendAcknowledgment(messageId, true);
      }

    } catch (e) {
      debugPrint('❌ Error processing WebSocket message: $e');
      debugPrint('🔍 Raw message: $message');
      
      // ✅ ENHANCED: Don't let message processing errors break the connection
      // The connection should remain stable even if individual messages fail
    }
  }

  void _handleAttendanceUpdate(Map<String, dynamic> data) async {
    debugPrint('👥 Actualización de asistencia recibida');
    
    // ✅ NUEVO: Procesar datos específicos de la actualización para notificaciones
    try {
      final String updateType = data['updateType'] ?? 'general';
      final String studentName = data['studentName'] ?? 'Estudiante';
      final String? studentId = data['studentId'];
      final String action = data['action'] ?? 'unknown';
      
      debugPrint('📊 Tipo de actualización: $updateType, Acción: $action, Estudiante: $studentName');
      
      // Procesar diferentes tipos de actualizaciones
      switch (updateType) {
        case 'student_joined':
          // Un estudiante se registró
          await _handleStudentJoinedNotification(studentName, data);
          break;
          
        case 'student_left_area':
          // Un estudiante salió del área geográfica
          await _handleStudentLeftAreaNotification(studentName, data);
          break;
          
        case 'multiple_students':
          // Múltiples estudiantes realizaron alguna acción
          await _handleMultipleStudentsUpdate(data);
          break;
          
        case 'attendance_count':
          // Solo actualización de conteo
          await _handleAttendanceCountUpdate(data);
          break;
          
        default:
          debugPrint('📋 Tipo de actualización no manejado: $updateType');
      }
      
    } catch (e) {
      debugPrint('❌ Error procesando actualización de asistencia: $e');
    }
    
    // Recargar datos de asistencia
    await _loadEventAttendances();
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

  void _handleEventStatusChanged(Map<String, dynamic> data) {
    final newStatus = data['isActive'] ?? false;
    debugPrint('🎯 Estado del evento cambió: $newStatus');

    setState(() {
      _isEventActive = newStatus;
      if (_monitoredEvent != null) {
        _monitoredEvent = _monitoredEvent!.copyWith(isActive: newStatus);
      }
    });

    if (newStatus) {
      _showNotification('Evento Activado', 'El evento ahora está activo');
    }
  }

  void _handleBreakStatusChanged(Map<String, dynamic> data) {
    final isBreakActive = data['breakActive'] ?? false;
    debugPrint('⏸️ Estado del receso cambió: $isBreakActive');

    if (isBreakActive) {
      _showNotification(
          'Receso Iniciado', 'Los estudiantes han sido notificados');
    } else {
      _showNotification('Receso Terminado', 'Tracking reanudado');
    }
  }

  void _handleMetricsUpdate(Map<String, dynamic> data) {
    debugPrint('📊 Métricas actualizadas en tiempo real');
    _loadRealtimeMetrics();
  }

  /// ✅ ENHANCED: WebSocket error handling with detailed analysis
  void _handleWebSocketError(dynamic error) {
    debugPrint('❌ WebSocket error occurred: $error');

    // ✅ ENHANCED: Categorize error types
    String errorMessage = 'Conexión tiempo real perdida';
    String errorDetail = '';
    
    if (error.toString().contains('WebSocketChannelException')) {
      errorMessage = 'Error de conexión WebSocket';
      errorDetail = 'Verificando conectividad...';
    } else if (error.toString().contains('TimeoutException')) {
      errorMessage = 'Timeout de conexión';
      errorDetail = 'Reintentando automáticamente...';
    } else if (error.toString().contains('SocketException')) {
      errorMessage = 'Error de red';
      errorDetail = 'Verifique su conexión a internet';
    }

    // ✅ ENHANCED: Schedule reconnection on recoverable errors
    if (_shouldReconnect) {
      _scheduleReconnection();
      errorDetail = errorDetail.isEmpty ? 'Reintentando automáticamente...' : errorDetail;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (errorDetail.isNotEmpty)
                Text(errorDetail, style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () {
              _reconnectionAttempts = 0;
              _connectWebSocketWithRetry();
            },
          ),
        ),
      );
    }
  }

  /// ✅ ENHANCED: WebSocket closed handling with intelligent reconnection
  void _handleWebSocketClosed() {
    debugPrint('🔌 WebSocket connection closed');
    
    // ✅ ENHANCED: Stop heartbeat when connection is closed
    _stopHeartbeat();
    
    // ✅ ENHANCED: Only reconnect if we should and component is still mounted
    if (_shouldReconnect && mounted) {
      debugPrint('🔄 Scheduling WebSocket reconnection...');
      _scheduleReconnection();
    } else {
      debugPrint('⏹️ WebSocket reconnection disabled');
    }
  }

  /// ✅ ENHANCED: Comprehensive WebSocket cleanup
  void _cleanupWebSocket() {
    try {
      debugPrint('🧹 Cleaning up WebSocket resources');

      // Stop reconnection attempts
      _shouldReconnect = false;
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;
      
      // Stop heartbeat
      _stopHeartbeat();

      // Cancel subscription
      _wsSubscription?.cancel();
      _wsSubscription = null;
      
      // Close WebSocket channel
      try {
        _wsChannel?.sink.close(1000, 'Client disconnecting'); // Normal closure
      } catch (e) {
        debugPrint('⚠️ Error closing WebSocket sink: $e');
      }
      _wsChannel = null;

      // Reset connection state
      _isConnecting = false;
      _reconnectionAttempts = 0;

      debugPrint('✅ WebSocket cleanup completed successfully');
    } catch (e) {
      debugPrint('❌ Error during WebSocket cleanup: $e');
    }
  }

  /// Método auxiliar para notificaciones rápidas
  void _showNotification(String title, String message) {
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
          backgroundColor: AppColors.primaryOrange,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ ENHANCED: WebSocket helper methods for connection management

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnection() {
    if (!_shouldReconnect || _reconnectionAttempts >= _maxReconnectionAttempts) {
      debugPrint('🚫 Max reconnection attempts reached or reconnection disabled');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Conexión tiempo real no disponible - usando actualización manual'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    _reconnectionTimer?.cancel();
    
    final delay = Duration(
      seconds: _reconnectionDelay.inSeconds * (_reconnectionAttempts + 1),
    );
    
    debugPrint('🔄 Scheduling reconnection attempt ${_reconnectionAttempts + 1} in ${delay.inSeconds}s');
    
    _reconnectionTimer = Timer(delay, () {
      _reconnectionAttempts++;
      _connectWebSocketWithRetry();
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _stopHeartbeat(); // Stop existing heartbeat first
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_wsChannel != null && !_isConnecting) {
        _sendHeartbeat();
      }
    });
    
    debugPrint('💓 WebSocket heartbeat started (${_heartbeatInterval.inSeconds}s interval)');
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    debugPrint('💓 WebSocket heartbeat stopped');
  }

  /// Send heartbeat message to server
  void _sendHeartbeat() {
    try {
      final heartbeatMessage = jsonEncode({
        'type': 'heartbeat',
        'eventId': widget.eventId,
        'timestamp': DateTime.now().toIso8601String(),
        'clientId': widget.teacherName,
      });

      _wsChannel?.sink.add(heartbeatMessage);
      debugPrint('💓 Heartbeat sent');
    } catch (e) {
      debugPrint('❌ Error sending heartbeat: $e');
    }
  }

  /// Send acknowledgment for received messages
  void _sendAcknowledgment(String messageId, bool success, [String? error]) {
    if (messageId.isEmpty || _wsChannel == null) return;

    try {
      final ackMessage = jsonEncode({
        'type': 'acknowledgment',
        'messageId': messageId,
        'success': success,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _wsChannel!.sink.add(ackMessage);
      debugPrint('✅ Acknowledgment sent for message: $messageId');
    } catch (e) {
      debugPrint('❌ Error sending acknowledgment: $e');
    }
  }

  // ✅ ENHANCED: Message handlers for new message types

  /// Handle connection established confirmation
  void _handleConnectionEstablished(Map<String, dynamic> data) {
    debugPrint('🔗 WebSocket connection established');
    
    final serverInfo = data['serverInfo'] ?? {};
    debugPrint('📡 Server info: $serverInfo');
    
    // Reset reconnection attempts on successful connection
    _reconnectionAttempts = 0;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conexión tiempo real establecida'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle heartbeat response from server
  void _handleHeartbeatResponse(Map<String, dynamic> data) {
    debugPrint('💓 Heartbeat response received');
    
    // Connection is alive, reset reconnection attempts
    _reconnectionAttempts = 0;
    
    // Process any server-side data in heartbeat response
    if (data.containsKey('serverTime')) {
      debugPrint('🕐 Server time: ${data['serverTime']}');
    }
  }

  /// Handle server error messages
  void _handleServerError(Map<String, dynamic> data) {
    final errorMessage = data['message'] ?? 'Unknown server error';
    final errorCode = data['code'] ?? 'UNKNOWN';
    
    debugPrint('🚨 Server error: $errorCode - $errorMessage');
    
    // Handle specific error codes
    switch (errorCode) {
      case 'AUTH_EXPIRED':
        debugPrint('🔑 Authentication expired - attempting to refresh');
        _handleAuthExpired();
        break;
      case 'EVENT_NOT_FOUND':
        debugPrint('❌ Event not found - stopping monitoring');
        _handleEventNotFound();
        break;
      case 'PERMISSION_DENIED':
        debugPrint('🚫 Permission denied for this event');
        _handlePermissionDenied();
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error del servidor: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
    }
  }

  /// Handle authentication expiration
  void _handleAuthExpired() async {
    debugPrint('🔑 Handling authentication expiration');
    
    try {
      // Attempt to refresh token
      final newToken = await _storageService.getToken();
      if (newToken != null) {
        // Reconnect with new token
        _cleanupWebSocket();
        await Future.delayed(const Duration(seconds: 1));
        await _connectWebSocketWithRetry();
      } else {
        _handlePermissionDenied();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing authentication: $e');
      _handlePermissionDenied();
    }
  }

  /// Handle event not found error
  void _handleEventNotFound() {
    _cleanupWebSocket();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Evento no encontrado - regresando al dashboard'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  /// Handle permission denied error
  void _handlePermissionDenied() {
    _cleanupWebSocket();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚫 Sin permisos para monitorear este evento'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
