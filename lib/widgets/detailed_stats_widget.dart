// 🎯 WIDGET PARA MOSTRAR ESTADÍSTICAS DETALLADAS EN DASHBOARDS
import 'package:flutter/material.dart';
import '../services/asistencia_service.dart';
import '../services/dashboard_service.dart';
import '../utils/colors.dart';

class DetailedStatsWidget extends StatefulWidget {
  final String? eventoId; // null = estadísticas generales
  final bool isDocente;

  const DetailedStatsWidget({
    super.key,
    this.eventoId,
    this.isDocente = false,
  });

  @override
  State<DetailedStatsWidget> createState() => _DetailedStatsWidgetState();
}

class _DetailedStatsWidgetState extends State<DetailedStatsWidget> {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final DashboardService _dashboardService = DashboardService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _isLoading ? _buildLoading() : _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: AppColors.secondaryTeal,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          widget.eventoId != null
              ? 'Estadísticas del Evento'
              : 'Estadísticas Generales',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadStats,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildContent() {
    if (_stats.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildMetricsGrid(),
        const SizedBox(height: 16),
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final present = _stats['presentStudents'] ?? 0;
    final absent = _stats['absentStudents'] ?? 0;
    final total = _stats['totalStudents'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Presentes',
            present.toString(),
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Ausentes',
            absent.toString(),
            Colors.red,
            Icons.cancel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Total',
            total.toString(),
            AppColors.secondaryTeal,
            Icons.group,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final rate = _stats['assistanceRate'] ?? 0.0;
    final percentage = (rate is int) ? rate.toDouble() : rate as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Porcentaje de Asistencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: percentage >= 75
                    ? Colors.green
                    : percentage >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.lightGray,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 75
                ? Colors.green
                : percentage >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay datos disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las estadísticas aparecerán cuando haya actividad',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? data;

      if (widget.eventoId != null) {
        // Estadísticas específicas del evento
        final result =
            await _asistenciaService.obtenerMetricasEvento(widget.eventoId!);
        if (result.success) {
          data = result.data;
        }
      } else {
        // Estadísticas generales
        data = await _dashboardService.getDashboardOverview();
      }

      if (mounted) {
        setState(() {
          _stats = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      if (mounted) {
        setState(() {
          _stats = {};
          _isLoading = false;
        });
      }
    }
  }
}
