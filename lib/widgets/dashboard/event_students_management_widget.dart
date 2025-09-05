// lib/widgets/dashboard/event_students_management_widget.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../models/evento_model.dart';
import '../../models/asistencia_model.dart';
import '../../services/asistencia_service.dart';
import '../../utils/app_router.dart';
import '../custom_button.dart';

/// ✅ EVENT STUDENTS MANAGEMENT WIDGET: Enhanced dashboard for event student management
/// 
/// Features:
/// - Real-time student attendance tracking
/// - Event status management (start/pause/end)
/// - Student list with attendance status
/// - Quick actions for attendance management
/// - Export functionality
/// - Statistics overview
class EventStudentsManagementWidget extends StatefulWidget {
  final Evento evento;
  final String currentUserId;
  final bool isCompact; // For dashboard vs full screen mode
  final VoidCallback? onExpand;
  final Function(Evento)? onEventUpdate;

  const EventStudentsManagementWidget({
    super.key,
    required this.evento,
    required this.currentUserId,
    this.isCompact = false,
    this.onExpand,
    this.onEventUpdate,
  });

  @override
  State<EventStudentsManagementWidget> createState() => _EventStudentsManagementWidgetState();
}

class _EventStudentsManagementWidgetState extends State<EventStudentsManagementWidget>
    with TickerProviderStateMixin {
  
  // Services
  final AsistenciaService _asistenciaService = AsistenciaService();

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;

  // State
  bool _isLoading = true;
  bool _isUpdating = false;
  List<Asistencia> _attendances = [];
  Timer? _refreshTimer;

  // Statistics
  int _totalStudents = 0;
  int _presentStudents = 0;
  int _absentStudents = 0;
  double _attendanceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEventStudentsData();
    
    if (!widget.isCompact) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController.forward();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _refreshStudentsData();
      }
    });
  }

  Future<void> _loadEventStudentsData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      logger.d('📚 Loading students data for event: ${widget.evento.id}');
      
      // ✅ VALIDAR que el evento tenga ID antes de hacer la petición
      if (widget.evento.id == null || widget.evento.id!.isEmpty) {
        logger.d('❌ Event ID is null or empty, cannot load attendances');
        if (mounted) {
          setState(() {
            _attendances = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      // Load attendance records for this event
      final attendances = await _asistenciaService.obtenerAsistenciasEvento(widget.evento.id!);
      
      // Calculate statistics
      _calculateStatistics(attendances);
      
      if (mounted) {
        setState(() {
          _attendances = attendances;
          _isLoading = false;
        });
      }

      logger.d('✅ Students data loaded: ${attendances.length} records');
    } catch (e) {
      logger.d('❌ Error loading students data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStudentsData() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // ✅ VALIDAR ID antes de hacer petición de actualización
      if (widget.evento.id == null || widget.evento.id!.isEmpty) {
        logger.d('❌ Event ID is null or empty, cannot refresh attendances');
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
        return;
      }
      
      final attendances = await _asistenciaService.obtenerAsistenciasEvento(widget.evento.id!);
      _calculateStatistics(attendances);
      
      if (mounted) {
        setState(() {
          _attendances = attendances;
          _isUpdating = false;
        });
      }
    } catch (e) {
      logger.d('❌ Error refreshing data: $e');
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _calculateStatistics(List<Asistencia> attendances) {
    _totalStudents = attendances.length;
    _presentStudents = attendances.where((a) => a.estado == 'presente').length;
    _absentStudents = _totalStudents - _presentStudents;
    _attendanceRate = _totalStudents > 0 ? (_presentStudents / _totalStudents) * 100 : 0;
    
    logger.d('📊 Statistics: Total: $_totalStudents, Present: $_presentStudents, Rate: ${_attendanceRate.toStringAsFixed(1)}%');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    } else {
      return _buildFullView();
    }
  }

  /// Compact view for dashboard integration
  Widget _buildCompactView() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isCompact: true),
          const SizedBox(height: 12),
          _buildQuickStats(),
          const SizedBox(height: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  /// Full view for expanded management
  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isCompact: false),
          const SizedBox(height: 20),
          _buildEventControls(),
          const SizedBox(height: 20),
          _buildDetailedStats(),
          const SizedBox(height: 20),
          _buildStudentsList(),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.people,
            color: AppColors.primaryOrange,
            size: isCompact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompact ? 'Gestión de Estudiantes' : 'Gestión de Estudiantes del Evento',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 4),
                Text(
                  widget.evento.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (isCompact && widget.onExpand != null)
          IconButton(
            onPressed: widget.onExpand,
            icon: const Icon(
              Icons.open_in_full,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
        if (_isUpdating)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + 0.2 * _pulseController.value,
                child: Icon(
                  Icons.sync,
                  color: AppColors.primaryOrange,
                  size: isCompact ? 16 : 18,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    if (_isLoading) {
      return _buildLoadingStats();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            _totalStudents.toString(),
            Icons.people,
            AppColors.primaryOrange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Presentes',
            _presentStudents.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Asistencia',
            '${_attendanceRate.toStringAsFixed(0)}%',
            Icons.analytics,
            AppColors.secondaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Ver Detalle',
            onPressed: widget.onExpand,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomButton(
            text: 'Monitor',
            onPressed: () => _navigateToEventMonitor(),
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEventControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control de Evento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  'Iniciar Evento',
                  Icons.play_arrow,
                  Colors.green,
                  _isEventActive() ? null : () => _toggleEventStatus('iniciar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  'Pausar',
                  Icons.pause,
                  Colors.orange,
                  _isEventActive() ? () => _toggleEventStatus('pausar') : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  'Finalizar',
                  Icons.stop,
                  Colors.red,
                  _isEventActive() ? () => _toggleEventStatus('finalizar') : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEventStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildControlButton(String text, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey[300],
        foregroundColor: onPressed != null ? Colors.white : Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );
  }

  Widget _buildEventStatusIndicator() {
    final status = _getEventStatusInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status['color'].withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Estado: ${status['text']}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: status['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getEventStatusInfo() {
    switch (widget.evento.estado.toLowerCase()) {
      case 'en proceso':
        return {'text': 'En Proceso', 'color': Colors.green};
      case 'en espera':
        return {'text': 'En Pausa', 'color': Colors.orange};
      case 'activo':
        return {'text': 'Programado', 'color': AppColors.secondaryTeal};
      case 'finalizado':
        return {'text': 'Finalizado', 'color': Colors.grey};
      default:
        return {'text': 'Inactivo', 'color': Colors.grey};
    }
  }

  Widget _buildDetailedStats() {
    if (_isLoading) return _buildLoadingStats();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Detalladas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailedStatCard(
                  'Estudiantes Registrados',
                  _totalStudents.toString(),
                  Icons.group,
                  AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedStatCard(
                  'Presentes',
                  _presentStudents.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailedStatCard(
                  'Ausentes',
                  _absentStudents.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedStatCard(
                  'Tasa de Asistencia',
                  '${_attendanceRate.toStringAsFixed(1)}%',
                  Icons.analytics,
                  AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_isLoading) {
      return _buildLoadingList();
    }

    if (_attendances.isEmpty) {
      return _buildEmptyStudentsList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Lista de Estudiantes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _refreshStudentsData,
                  icon: Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  label: Text(
                    'Actualizar',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attendances.length,
            itemBuilder: (context, index) {
              final attendance = _attendances[index];
              return _buildStudentItem(attendance, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(Asistencia attendance, int index) {
    final isPresent = attendance.estado == 'presente';
    final isLate = attendance.estado == 'tarde';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGray,
            width: index == _attendances.length - 1 ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isPresent 
                ? Colors.green.withValues(alpha: 0.1) 
                : isLate 
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
            child: Icon(
              isPresent 
                  ? Icons.check_circle 
                  : isLate
                      ? Icons.schedule
                      : Icons.cancel,
              color: isPresent 
                  ? Colors.green 
                  : isLate
                      ? Colors.orange
                      : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.nombreUsuario ?? 'Usuario ${attendance.usuarioId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${attendance.usuarioId}',  // Using available field
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
                if (attendance.fechaRegistro != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Registrado: ${_formatTime(attendance.fechaRegistro!)}',  // Using fechaRegistro
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent 
                  ? Colors.green.withValues(alpha: 0.1) 
                  : isLate
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPresent 
                    ? Colors.green.withValues(alpha: 0.3) 
                    : isLate
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getAttendanceStatusText(attendance.estado),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPresent 
                    ? Colors.green 
                    : isLate
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAttendanceStatusText(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return 'Presente';
      case 'tarde':
        return 'Tardanza';
      case 'ausente':
        return 'Ausente';
      default:
        return 'Sin Registro';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyStudentsList() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay estudiantes registrados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los estudiantes aparecerán aquí cuando se registren al evento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isEventActive() {
    return widget.evento.estado.toLowerCase() == 'en proceso';
  }

  Future<void> _toggleEventStatus(String action) async {
    // Implementation for event status management
    logger.d('Event $action requested for ${widget.evento.id}');
    AppRouter.showSnackBar('Funcionalidad en desarrollo: $action evento');
  }

  void _navigateToEventMonitor() {
    // ✅ VALIDAR ID antes de navegar
    if (widget.evento.id == null || widget.evento.id!.isEmpty) {
      logger.d('❌ Event ID is null or empty, cannot navigate to monitor');
      AppRouter.showSnackBar('Error: El evento no tiene ID válido');
      return;
    }
    
    AppRouter.goToEventMonitor(
      eventId: widget.evento.id!,
      teacherName: widget.currentUserId,
    );
  }
}