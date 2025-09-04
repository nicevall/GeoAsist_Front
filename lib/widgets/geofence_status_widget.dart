// lib/widgets/geofence_status_widget.dart
// 🎯 WIDGET PARA MOSTRAR ESTADO DE GEOFENCING
import 'package:flutter/material.dart';
import '../services/local_geofencing_service.dart';

class GeofenceStatusWidget extends StatelessWidget {
  final GeofenceResult? result;
  final String eventName;
  final double eventRadius;

  const GeofenceStatusWidget({
    super.key,
    required this.result,
    required this.eventName,
    required this.eventRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Verificando ubicación...'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor().withValues(alpha: 0.1),
        border: Border.all(color: _getStatusColor(), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 28,
                ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    result!.isInside ? 'DENTRO' : 'FUERA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailsRow(context),
            if (result!.status == GeofenceStatus.inside) ...[
              const SizedBox(height: 12),
              _buildProximityBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildDetailItem(
          context,
          'Distancia',
          LocalGeofencingService.formatDistance(result!.distance),
          Icons.straighten,
        ),
        _buildDetailItem(
          context,
          'Precisión',
          '±${result!.accuracy.round()}m',
          Icons.gps_fixed,
        ),
        _buildDetailItem(
          context,
          'Radio',
          '${eventRadius.round()}m',
          Icons.radio_button_unchecked,
        ),
        _buildDetailItem(
          context,
          'Actualizado',
          _formatTime(result!.timestamp),
          Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

  Widget _buildProximityBar() {
    final proximity = LocalGeofencingService.calculateProximityPercentage(
      result!.distance, 
      eventRadius,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Proximidad al centro:', style: TextStyle(fontSize: 12)),
            Text('${proximity.round()}%', 
                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: proximity / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          minHeight: 6,
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (result!.status) {
      case GeofenceStatus.inside:
        return Icons.check_circle;
      case GeofenceStatus.outside:
        return Icons.cancel;
      case GeofenceStatus.approaching:
        return Icons.trending_up;
      case GeofenceStatus.leaving:
        return Icons.trending_down;
      default:
        return Icons.help;
    }
  }

  String _getStatusTitle() {
    switch (result!.status) {
      case GeofenceStatus.inside:
        return 'Dentro del área';
      case GeofenceStatus.outside:
        return 'Fuera del área';
      case GeofenceStatus.approaching:
        return 'Acercándose';
      case GeofenceStatus.leaving:
        return 'Alejándose';
      default:
        return 'Estado desconocido';
    }
  }

  String _getStatusDescription() {
    switch (result!.status) {
      case GeofenceStatus.inside:
        return 'Tu ubicación está dentro del área del evento $eventName';
      case GeofenceStatus.outside:
        return 'Necesitas acercarte al área del evento $eventName';
      case GeofenceStatus.approaching:
        return 'Te estás acercando al área del evento $eventName';
      case GeofenceStatus.leaving:
        return 'Te estás alejando del área del evento $eventName';
      default:
        return 'Verificando tu ubicación respecto al evento';
    }
  }

  Color _getStatusColor() {
    switch (result!.status) {
      case GeofenceStatus.inside:
        return Colors.green;
      case GeofenceStatus.outside:
        return Colors.red;
      case GeofenceStatus.approaching:
        return Colors.orange;
      case GeofenceStatus.leaving:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Color _getBackgroundColor() {
    return _getStatusColor().withValues(alpha: 0.1);
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Ahora';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 🎯 WIDGET COMPACTO PARA MOSTRAR EN AppBar
class CompactGeofenceIndicator extends StatelessWidget {
  final GeofenceResult? result;

  const CompactGeofenceIndicator({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 6),
            Text('GPS', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            LocalGeofencingService.formatDistance(result!.distance),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    return result!.isInside ? Icons.check_circle : Icons.cancel;
  }

  Color _getStatusColor() {
    return result!.isInside ? Colors.green : Colors.red;
  }
}