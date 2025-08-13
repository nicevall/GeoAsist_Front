// lib/screens/events/event_monitor_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart'; // ✅ NUEVO para backend real
import '../../models/evento_model.dart';
import '../../models/asistencia_model.dart'; // ✅ NUEVO para datos reales

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
    _initializeEventMonitor();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _pulseController.dispose();
    _realtimeUpdateTimer?.cancel();
    super.dispose();
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

  Future<void> _initializeEventMonitor() async {
    debugPrint('🎯 Inicializando EventMonitor para evento: ${widget.eventId}');

    try {
      // 1. Cargar evento específico a monitorear
      await _loadMonitoredEvent();

      // 2. Cargar asistencias del evento en tiempo real
      await _loadEventAttendances();

      // 3. Iniciar actualización en tiempo real cada 30 segundos
      _startRealtimeUpdates();
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

      // ✅ CORREGIDO: EventoService retorna bool directamente
      final result = await _eventoService.terminarReceso(widget.eventId);

      if (result) {
        await _refreshData();

        if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receso terminado - Tracking reanudado'),
            backgroundColor: Colors.green,
          ),
        );

        debugPrint('✅ Receso terminado exitosamente');
      } else {
        if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error terminando receso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error terminando receso: $e');
      if (!mounted) return; // ✅ CORREGIDO: Verificar mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error terminando receso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // ✅ CORREGIDO: Color básico
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildEventMonitorContent(),
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _endBreak,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Fin Receso'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
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
}
