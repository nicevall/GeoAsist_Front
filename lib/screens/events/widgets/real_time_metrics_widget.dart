// lib/screens/dashboard/widgets/real_time_metrics_widget.dart
// 🎯 WIDGET DE MÉTRICAS EN TIEMPO REAL FASE A1.2 - Dashboard del profesor
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class RealTimeMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final bool isRefreshing;
  final Animation<double> refreshAnimation;

  const RealTimeMetricsWidget({
    super.key,
    required this.metrics,
    required this.isRefreshing,
    required this.refreshAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 HEADER CON TÍTULO Y ESTADO DE ACTUALIZACIÓN
          _buildHeader(),

          // 🎯 GRID DE MÉTRICAS PRINCIPALES
          _buildMetricsGrid(),

          // 🎯 BARRA DE PROGRESO DE ASISTENCIA
          _buildAttendanceProgressBar(),

          // 🎯 ÚLTIMA ACTUALIZACIÓN
          _buildLastUpdateInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Métricas en Tiempo Real',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Indicador de actualización
          AnimatedBuilder(
            animation: refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: refreshAnimation.value * 2 * 3.14159,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white
                        .withValues(alpha: isRefreshing ? 1.0 : 0.6),
                    size: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final totalStudents = metrics['totalStudents'] ?? 0;
    final presentStudents = metrics['presentStudents'] ?? 0;
    final absentStudents = metrics['absentStudents'] ?? 0;
    final outsideStudents = metrics['outsideStudents'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Total',
              value: totalStudents.toString(),
              icon: Icons.people,
              color: AppColors.secondaryTeal,
              subtitle: 'estudiantes',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'Presentes',
              value: presentStudents.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              subtitle: 'asistencias',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'Ausentes',
              value: absentStudents.toString(),
              icon: Icons.cancel,
              color: Colors.red,
              subtitle: 'faltas',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'Fuera',
              value: outsideStudents.toString(),
              icon: Icons.location_off,
              color: Colors.orange,
              subtitle: 'del área',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceProgressBar() {
    final attendanceRate = metrics['attendanceRate'] ?? 0.0;
    final totalStudents = metrics['totalStudents'] ?? 0;

    if (totalStudents == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasa de Asistencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getAttendanceRateColor(attendanceRate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: attendanceRate / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getAttendanceRateColor(attendanceRate),
            ),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            _getAttendanceRateMessage(attendanceRate),
            style: TextStyle(
              fontSize: 12,
              color: _getAttendanceRateColor(attendanceRate),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    final lastUpdate = metrics['lastUpdate'] as DateTime?;

    if (lastUpdate == null) {
      return const SizedBox.shrink();
    }

    final timeAgo = _getTimeAgo(lastUpdate);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: AppColors.textGray,
          ),
          const SizedBox(width: 4),
          Text(
            'Última actualización: $timeAgo',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const Spacer(),
          // Indicador de estado de conexión
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'En línea',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 MÉTODOS AUXILIARES

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getAttendanceRateMessage(double rate) {
    if (rate >= 90) return 'Excelente asistencia';
    if (rate >= 80) return 'Buena asistencia';
    if (rate >= 60) return 'Asistencia regular';
    if (rate >= 40) return 'Asistencia baja';
    return 'Asistencia crítica';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inDays}d';
    }
  }
}
