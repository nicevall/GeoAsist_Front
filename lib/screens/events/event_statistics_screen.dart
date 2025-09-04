// lib/screens/events/event_statistics_screen.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/evento_service.dart';
import '../../models/event_statistics_model.dart';
import '../../models/api_response_model.dart';
import '../../widgets/custom_button.dart';

class EventStatisticsScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventStatisticsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventStatisticsScreen> createState() => _EventStatisticsScreenState();
}

class _EventStatisticsScreenState extends State<EventStatisticsScreen>
    with SingleTickerProviderStateMixin {
  final EventoService _eventoService = EventoService();
  
  bool _isLoading = true;
  EventStatistics? _statistics;
  List<StudentAttendanceStat>? _students;
  String? _errorMessage;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load both statistics and student list in parallel
      final results = await Future.wait([
        _eventoService.getEventStatistics(widget.eventId),
        _eventoService.getEventStudents(widget.eventId),
      ]);
      
      final statsResponse = results[0] as ApiResponse<EventStatistics>;
      final studentsResponse = results[1] as ApiResponse<List<StudentAttendanceStat>>;
      
      if (mounted) {
        setState(() {
          if (statsResponse.success) {
            _statistics = statsResponse.data;
          }
          
          if (studentsResponse.success) {
            _students = studentsResponse.data;
          }
          
          if (!statsResponse.success && !studentsResponse.success) {
            _errorMessage = 'Error cargando datos del evento';
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Estadísticas: ${widget.eventName}'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Actualizar datos',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Resumen'),
            Tab(icon: Icon(Icons.people), text: 'Estudiantes'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildStudentsTab(),
                    _buildTimelineTab(),
                  ],
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryOrange),
          SizedBox(height: 20),
          Text(
            'Cargando estadísticas del evento...',
            style: TextStyle(fontSize: 16, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textGray),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Reintentar',
              onPressed: _loadStatistics,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_statistics == null) {
      return const Center(
        child: Text('No hay datos estadísticos disponibles'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildAttendanceChart(),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _statistics!;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Estudiantes',
            stats.totalStudents.toString(),
            Icons.people,
            AppColors.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Presentes',
            stats.presentStudents.toString(),
            Icons.check_circle,
            AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ausentes',
            stats.absentStudents.toString(),
            Icons.cancel,
            AppColors.errorRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          Text(
            title,
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

  Widget _buildAttendanceChart() {
    final stats = _statistics!;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Asistencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          // Simple progress bars as chart placeholders
          _buildProgressBar('Presentes', stats.presentStudents, stats.totalStudents, AppColors.successGreen),
          const SizedBox(height: 8),
          _buildProgressBar('Llegadas Tarde', stats.lateStudents, stats.totalStudents, AppColors.warningOrange),
          const SizedBox(height: 8),
          _buildProgressBar('Ausentes', stats.absentStudents, stats.totalStudents, AppColors.errorRed),
          const SizedBox(height: 16),
          Text(
            'Tasa de Asistencia: ${stats.attendanceRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? value / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('$value', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final stats = _statistics!;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas Adicionales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Tiempo Promedio de Llegada',
                  '${stats.averageArrivalTime.toInt()} min',
                  Icons.schedule,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Última Actualización',
                  _formatDateTime(stats.lastUpdate),
                  Icons.update,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    if (_students == null || _students!.isEmpty) {
      return const Center(
        child: Text('No hay estudiantes registrados en este evento'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students!.length,
      itemBuilder: (context, index) {
        final student = _students![index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(StudentAttendanceStat student) {
    Color statusColor;
    IconData statusIcon;
    
    switch (student.status) {
      case 'present':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'late':
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.schedule;
        break;
      case 'absent':
      default:
        statusColor = AppColors.errorRed;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      student.studentEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (student.isPresent && student.arrivalTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Llegada: ${_formatTime(student.arrivalTime!)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGray),
            ),
            if (student.minutesLate > 0)
              Text(
                '${student.minutesLate} minutos tarde',
                style: const TextStyle(fontSize: 12, color: AppColors.warningOrange),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: AppColors.textGray),
          SizedBox(height: 16),
          Text(
            'Timeline de Asistencia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Funcionalidad en desarrollo',
            style: TextStyle(color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}