// lib/widgets/dashboard_metric_card.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/dashboard_metric_model.dart';

class DashboardMetricCard extends StatelessWidget {
  final DashboardMetric metric;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const DashboardMetricCard({
    super.key,
    required this.metric,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icono de la métrica
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (color ?? _getDefaultColor()).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? _getDefaultIcon(),
                  color: color ?? _getDefaultColor(),
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // Información de la métrica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatValue(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color ?? _getDefaultColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Actualizado: ${_formatDate()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha indicativa (opcional)
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textGray,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDefaultColor() {
    switch (metric.metric.toLowerCase()) {
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

  IconData _getDefaultIcon() {
    switch (metric.metric.toLowerCase()) {
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

  String _getDisplayTitle() {
    switch (metric.metric.toLowerCase()) {
      case 'usuarios':
        return 'Total Usuarios';
      case 'eventos':
        return 'Total Eventos';
      case 'asistencias':
        return 'Total Asistencias';
      case 'locations':
        return 'Ubicaciones Registradas';
      default:
        return metric.metric.toUpperCase();
    }
  }

  String _formatValue() {
    // Si el valor es muy grande, formatearlo con K, M, etc.
    if (metric.value >= 1000000) {
      return '${(metric.value / 1000000).toStringAsFixed(1)}M';
    } else if (metric.value >= 1000) {
      return '${(metric.value / 1000).toStringAsFixed(1)}K';
    } else {
      return metric.value.toInt().toString();
    }
  }

  String _formatDate() {
    final date = metric.updatedAt;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours}h';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
