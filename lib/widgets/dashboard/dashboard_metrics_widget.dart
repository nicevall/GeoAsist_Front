// lib/widgets/dashboard/dashboard_metrics_widget.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/dashboard_metric_model.dart';

/// ✅ DASHBOARD METRICS WIDGET: Métricas reutilizables con estética preservada
/// Responsabilidades:
/// - Renderizado de métricas con estilos exactos del dashboard original
/// - Diferentes layouts según tipo de métricas (admin, profesor, estudiante)
/// - Colores y gradientes preservados EXACTAMENTE
/// - Loading states consistentes
/// - Animaciones mantenidas
class DashboardMetricsWidget extends StatelessWidget {
  final List<DashboardMetric> metrics;
  final List<MetricData> customMetrics;
  final bool isLoading;
  final MetricLayout layout;
  final String userRole;

  const DashboardMetricsWidget({
    super.key,
    this.metrics = const [],
    this.customMetrics = const [],
    required this.isLoading,
    this.layout = MetricLayout.grid,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingMetrics();
    }

    final displayMetrics = _getDisplayMetrics();

    switch (layout) {
      case MetricLayout.grid:
        return _buildGridMetrics(displayMetrics);
      case MetricLayout.row:
        return _buildRowMetrics(displayMetrics);
      case MetricLayout.column:
        return _buildColumnMetrics(displayMetrics);
    }
  }

  /// 📊 OBTENER MÉTRICAS PARA MOSTRAR
  List<MetricData> _getDisplayMetrics() {
    List<MetricData> displayMetrics = [];

    // Agregar métricas personalizadas primero
    displayMetrics.addAll(customMetrics);

    // Agregar métricas del backend
    for (final metric in metrics) {
      displayMetrics.add(MetricData(
        title: _getMetricTitle(metric.metric),
        value: metric.value.toString(),
        icon: _getMetricIcon(metric.metric),
        color: _getMetricColor(metric.metric),
      ));
    }

    return displayMetrics;
  }

  /// 🏗️ GRID DE MÉTRICAS (ESTILO ORIGINAL PRESERVADO)
  Widget _buildGridMetrics(List<MetricData> displayMetrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: displayMetrics.length,
      itemBuilder: (context, index) {
        final metric = displayMetrics[index];
        return _buildMetricCard(
          metric.title,
          metric.value,
          metric.icon,
          metric.color,
        );
      },
    );
  }

  /// 📏 ROW DE MÉTRICAS
  Widget _buildRowMetrics(List<MetricData> displayMetrics) {
    return Row(
      children: displayMetrics.asMap().entries.map((entry) {
        final index = entry.key;
        final metric = entry.value;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < displayMetrics.length - 1 ? 12 : 0),
            child: _buildMetricCard(
              metric.title,
              metric.value,
              metric.icon,
              metric.color,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 📄 COLUMN DE MÉTRICAS
  Widget _buildColumnMetrics(List<MetricData> displayMetrics) {
    return Column(
      children: displayMetrics.map((metric) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildMetricCard(
            metric.title,
            metric.value,
            metric.icon,
            metric.color,
          ),
        );
      }).toList(),
    );
  }

  /// ✅ TARJETA DE MÉTRICA REUTILIZABLE (ESTILO EXACTO PRESERVADO)
  /// Este método preserva EXACTAMENTE el estilo del dashboard original
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ✅ TARJETA DE ESTADÍSTICA ALTERNATIVA (ESTILO EXACTO PRESERVADO)
  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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

  /// 🔄 LOADING STATE PARA MÉTRICAS
  Widget _buildLoadingMetrics() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 4, // Mostrar 4 skeletons
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📝 OBTENER TÍTULO DE MÉTRICA
  String _getMetricTitle(String key) {
    const titleMap = {
      'total_usuarios': 'Total Usuarios',
      'eventos_activos': 'Eventos Activos',
      'total_eventos': 'Total Eventos',
      'asistencias_hoy': 'Asistencias Hoy',
      'promedio_asistencia': 'Promedio Asistencia',
      'promedio_asistencia_profesor': 'Promedio Asistencia',
      'estudiantes_unicos': 'Estudiantes Únicos',
      'mis_eventos': 'Mis Eventos',
      'eventos_disponibles': 'Eventos Disponibles',
      'asistencias_totales': 'Asistencias Totales',
      'promedio_personal': 'Promedio Personal',
    };
    return titleMap[key] ?? key;
  }

  /// 🎨 OBTENER ICONO DE MÉTRICA
  IconData _getMetricIcon(String key) {
    const iconMap = {
      'total_usuarios': Icons.people,
      'eventos_activos': Icons.event,
      'total_eventos': Icons.event_note,
      'asistencias_hoy': Icons.assignment_turned_in,
      'promedio_asistencia': Icons.trending_up,
      'promedio_asistencia_profesor': Icons.trending_up,
      'estudiantes_unicos': Icons.people,
      'mis_eventos': Icons.event_note,
      'eventos_disponibles': Icons.event_available,
      'asistencias_totales': Icons.timeline,
      'promedio_personal': Icons.analytics,
    };
    return iconMap[key] ?? Icons.info;
  }

  /// 🌈 OBTENER COLOR DE MÉTRICA (PRESERVANDO COLORES ORIGINALES)
  Color _getMetricColor(String key) {
    const colorMap = {
      'total_usuarios': AppColors.primaryOrange,
      'eventos_activos': AppColors.secondaryTeal,
      'total_eventos': Colors.purple,
      'asistencias_hoy': Colors.green,
      'promedio_asistencia': Colors.green,
      'promedio_asistencia_profesor': Colors.green,
      'estudiantes_unicos': AppColors.secondaryTeal,
      'mis_eventos': AppColors.primaryOrange,
      'eventos_disponibles': AppColors.secondaryTeal,
      'asistencias_totales': Colors.blue,
      'promedio_personal': AppColors.primaryOrange,
    };
    return colorMap[key] ?? AppColors.primaryOrange;
  }
}

/// ✅ DATOS DE MÉTRICA PERSONALIZADA
class MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// ✅ TIPOS DE LAYOUT PARA MÉTRICAS
enum MetricLayout {
  grid,    // Grid 2x2 (dashboard principal)
  row,     // Fila horizontal (sections específicas)
  column,  // Columna vertical (sidebar)
}