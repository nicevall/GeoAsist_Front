// lib/screens/attendance/widgets/attendance_tracking_stats.dart
import 'package:flutter/material.dart';
import '../../../models/evento_model.dart';
import '../../../models/asistencia_model.dart';

class AttendanceTrackingStats extends StatelessWidget {
  final Evento? activeEvent;
  final List<Asistencia> attendanceHistory;
  final double distanceFromCenter;
  final double currentAccuracy;
  final String lastUpdateTime;
  final Duration timeInEvent;
  final int exitWarningCount;

  const AttendanceTrackingStats({
    super.key,
    required this.activeEvent,
    required this.attendanceHistory,
    required this.distanceFromCenter,
    required this.currentAccuracy,
    required this.lastUpdateTime,
    required this.timeInEvent,
    required this.exitWarningCount,
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
            Text(
              'Estadísticas en Tiempo Real',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(context),
            if (activeEvent != null) ...[
              const SizedBox(height: 16),
              _buildEventInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Distancia',
          '${distanceFromCenter.toStringAsFixed(1)}m',
          Icons.straighten,
          _getDistanceColor(),
        ),
        _buildStatCard(
          context,
          'Precisión GPS',
          '±${currentAccuracy.toStringAsFixed(1)}m',
          Icons.gps_fixed,
          _getAccuracyColor(),
        ),
        _buildStatCard(
          context,
          'Tiempo en Evento',
          _formatDuration(timeInEvent),
          Icons.timer,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Alertas de Salida',
          exitWarningCount.toString(),
          Icons.warning_amber,
          exitWarningCount > 0 ? Colors.orange : Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeEvent!.titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEventDetail('Ubicación', activeEvent!.lugar ?? 'No especificada'),
          _buildEventDetail('Radio', '${activeEvent!.rangoPermitido.toInt()}m'),
          _buildEventDetail(
            'Horario', 
            '${activeEvent!.horaInicioFormatted} - ${activeEvent!.horaFinalFormatted}'
          ),
          if (lastUpdateTime.isNotEmpty)
            _buildEventDetail('Última actualización', lastUpdateTime),
        ],
      ),
    );
  }

  Widget _buildEventDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDistanceColor() {
    if (activeEvent == null) return Colors.grey;
    
    final radius = activeEvent!.rangoPermitido;
    if (distanceFromCenter <= radius) {
      return Colors.green;
    } else if (distanceFromCenter <= radius * 1.2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getAccuracyColor() {
    if (currentAccuracy <= 5) {
      return Colors.green;
    } else if (currentAccuracy <= 15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}

class AttendanceHistoryWidget extends StatelessWidget {
  final List<Asistencia> attendanceHistory;

  const AttendanceHistoryWidget({
    super.key,
    required this.attendanceHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (attendanceHistory.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay historial de asistencias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Asistencias',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceHistory.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final asistencia = attendanceHistory[index];
                return _buildAttendanceItem(context, asistencia);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(BuildContext context, Asistencia asistencia) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(asistencia.estado),
        child: Icon(
          _getStatusIcon(asistencia.estado),
          color: Colors.white,
        ),
      ),
      title: Text(asistencia.eventoTitulo),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado: ${_getStatusLabel(asistencia.estado)}'),
          Text('Fecha: ${_formatDateTime(asistencia.timestamp)}'),
        ],
      ),
      trailing: _buildStatusChip(asistencia.estado),
    );
  }

  Widget _buildStatusChip(String estado) {
    return Chip(
      label: Text(
        _getStatusLabel(estado),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getStatusColor(estado),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
      case 'presente_a_tiempo':
        return Colors.green;
      case 'presente_tarde':
        return Colors.orange;
      case 'ausente':
        return Colors.red;
      case 'justificado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
      case 'presente_a_tiempo':
        return Icons.check_circle;
      case 'presente_tarde':
        return Icons.schedule;
      case 'ausente':
        return Icons.cancel;
      case 'justificado':
        return Icons.assignment_turned_in;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
      case 'presente_a_tiempo':
        return 'Presente';
      case 'presente_tarde':
        return 'Llegada tardía';
      case 'ausente':
        return 'Ausente';
      case 'justificado':
        return 'Justificado';
      default:
        return estado;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}