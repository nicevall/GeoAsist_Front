// lib/widgets/presence_status_widget.dart
// 🎯 WIDGET PARA MOSTRAR ESTADO DE PRESENCIA LOCAL
import 'package:flutter/material.dart';
import '../services/local_presence_manager.dart';

class PresenceStatusWidget extends StatelessWidget {
  final LocalPresenceStatus status;
  final PresenceStats? stats;
  final VoidCallback? onActivateGracePeriod;

  const PresenceStatusWidget({
    super.key,
    required this.status,
    this.stats,
    this.onActivateGracePeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (status == LocalPresenceStatus.warning || status == LocalPresenceStatus.absent)
                  _buildGracePeriodButton(context),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 16),
              _buildStatsRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color color;

    switch (status) {
      case LocalPresenceStatus.present:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case LocalPresenceStatus.warning:
        iconData = Icons.warning;
        color = Colors.orange;
        break;
      case LocalPresenceStatus.absent:
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case LocalPresenceStatus.disconnected:
        iconData = Icons.signal_wifi_off;
        color = Colors.grey;
        break;
      case LocalPresenceStatus.gracePeriod:
        iconData = Icons.pause_circle;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.help;
        color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 32);
  }

  String _getStatusTitle() {
    switch (status) {
      case LocalPresenceStatus.present:
        return 'Presente';
      case LocalPresenceStatus.warning:
        return 'Advertencia';
      case LocalPresenceStatus.absent:
        return 'Ausente';
      case LocalPresenceStatus.disconnected:
        return 'Sin conexión';
      case LocalPresenceStatus.gracePeriod:
        return 'Período de gracia';
      default:
        return 'Sin iniciar';
    }
  }

  String _getStatusDescription() {
    switch (status) {
      case LocalPresenceStatus.present:
        return 'Estás dentro del área del evento';
      case LocalPresenceStatus.warning:
        return 'Estás cerca del límite del área';
      case LocalPresenceStatus.absent:
        return 'Estás fuera del área del evento';
      case LocalPresenceStatus.disconnected:
        return 'No se puede verificar tu ubicación';
      case LocalPresenceStatus.gracePeriod:
        return 'Puedes salir temporalmente sin penalización';
      default:
        return 'Monitoreo no iniciado';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case LocalPresenceStatus.present:
        return Colors.green;
      case LocalPresenceStatus.warning:
        return Colors.orange;
      case LocalPresenceStatus.absent:
        return Colors.red;
      case LocalPresenceStatus.disconnected:
        return Colors.grey;
      case LocalPresenceStatus.gracePeriod:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGracePeriodButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onActivateGracePeriod,
      icon: const Icon(Icons.pause, size: 16),
      label: const Text('Pausa'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(80, 36),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Sesión',
            stats!.sessionDurationFormatted,
            Icons.timer,
          ),
          _buildStatItem(
            context,
            'Presente',
            stats!.presenceTimeFormatted,
            Icons.location_on,
          ),
          _buildStatItem(
            context,
            'Precisión',
            '${stats!.presencePercentage}%',
            Icons.analytics,
          ),
          _buildStatItem(
            context,
            'Verificaciones',
            '${stats!.successfulChecks}/${stats!.totalChecks}',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// 🎯 WIDGET SIMPLIFICADO PARA MOSTRAR SOLO EL ESTADO
class SimplePresenceIndicator extends StatelessWidget {
  final LocalPresenceStatus status;
  final bool compact;

  const SimplePresenceIndicator({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusTitle(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        border: Border.all(color: _getStatusColor(), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusTitle(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (status) {
      case LocalPresenceStatus.present:
        return Icons.check_circle;
      case LocalPresenceStatus.warning:
        return Icons.warning;
      case LocalPresenceStatus.absent:
        return Icons.cancel;
      case LocalPresenceStatus.disconnected:
        return Icons.signal_wifi_off;
      case LocalPresenceStatus.gracePeriod:
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case LocalPresenceStatus.present:
        return 'Presente';
      case LocalPresenceStatus.warning:
        return 'Advertencia';
      case LocalPresenceStatus.absent:
        return 'Ausente';
      case LocalPresenceStatus.disconnected:
        return 'Sin GPS';
      case LocalPresenceStatus.gracePeriod:
        return 'Pausa';
      default:
        return 'Inactivo';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case LocalPresenceStatus.present:
        return Colors.green;
      case LocalPresenceStatus.warning:
        return Colors.orange;
      case LocalPresenceStatus.absent:
        return Colors.red;
      case LocalPresenceStatus.disconnected:
        return Colors.grey;
      case LocalPresenceStatus.gracePeriod:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}