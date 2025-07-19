// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import '../utils/colors.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_metric_model.dart';
import '../widgets/custom_button.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({
    super.key,
    this.userName = 'Usuario',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  List<DashboardMetric> _metrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final metrics = await _dashboardService.getMetrics();
      if (metrics != null) {
        setState(() => _metrics = metrics);
      }
    } catch (e) {
      debugPrint('Error cargando métricas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AppRouter.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard,
              size: 64,
              color: AppColors.textGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay métricas disponibles',
              style: TextStyle(fontSize: 18, color: AppColors.textGray),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Recargar',
              onPressed: _loadMetrics,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Métricas del Sistema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 20),
          ..._metrics.map((metric) => _buildMetricCard(metric)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(DashboardMetric metric) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getMetricColor(metric.metric).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMetricIcon(metric.metric),
                color: _getMetricColor(metric.metric),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMetricTitle(metric.metric),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    metric.value.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getMetricColor(metric.metric),
                    ),
                  ),
                  Text(
                    'Actualizado: ${_formatDate(metric.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMetricColor(String metric) {
    switch (metric.toLowerCase()) {
      case 'usuarios':
        return Colors.blue;
      case 'eventos':
        return AppColors.primaryOrange;
      case 'asistencias':
        return Colors.green;
      case 'locations':
        return AppColors.secondaryTeal;
      default:
        return AppColors.darkGray;
    }
  }

  IconData _getMetricIcon(String metric) {
    switch (metric.toLowerCase()) {
      case 'usuarios':
        return Icons.people;
      case 'eventos':
        return Icons.event;
      case 'asistencias':
        return Icons.check_circle;
      case 'locations':
        return Icons.location_on;
      default:
        return Icons.analytics;
    }
  }

  String _getMetricTitle(String metric) {
    switch (metric.toLowerCase()) {
      case 'usuarios':
        return 'Total Usuarios';
      case 'eventos':
        return 'Total Eventos';
      case 'asistencias':
        return 'Total Asistencias';
      case 'locations':
        return 'Ubicaciones Registradas';
      default:
        return metric.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
