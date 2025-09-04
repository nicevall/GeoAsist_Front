// lib/widgets/attendance/attendance_stats_panel.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/asistencia_model.dart';

/// ✅ ATTENDANCE STATS PANEL: Panel de estadísticas tiempo real preservado
/// Responsabilidades:
/// - Estadísticas de conectividad en tiempo real
/// - Estado actual detallado del tracking
/// - Historial reciente de asistencias
/// - Métricas de precisión GPS
/// - Indicadores visuales de calidad
class AttendanceStatsPanel extends StatelessWidget {
  final List<Asistencia> attendanceHistory;
  final String trackingStatus;
  final double currentAccuracy;
  final String lastUpdateTime;
  final bool isTrackingActive;
  final bool isInGeofence;
  final VoidCallback? onViewFullHistory;

  const AttendanceStatsPanel({
    super.key,
    required this.attendanceHistory,
    required this.trackingStatus,
    required this.currentAccuracy,
    required this.lastUpdateTime,
    required this.isTrackingActive,
    required this.isInGeofence,
    this.onViewFullHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Panel de estadísticas en tiempo real
        _buildRealTimeStatsPanel(),
        
        const SizedBox(height: 16),
        
        // Panel de historial reciente
        _buildRecentHistoryPanel(),
      ],
    );
  }

  /// 📊 PANEL DE ESTADÍSTICAS EN TIEMPO REAL (UI PRESERVADA)
  Widget _buildRealTimeStatsPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Estadísticas en Tiempo Real',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Primera fila de métricas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Estado Actual',
                    _getDetailedStatus(),
                    _getStatusIcon(),
                    _getStatusColor(),
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Asistencias Total',
                    '${attendanceHistory.length}',
                    Icons.assignment_turned_in,
                    AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Segunda fila de métricas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Precisión GPS',
                    currentAccuracy > 0
                        ? '${currentAccuracy.toStringAsFixed(1)}m'
                        : 'N/A',
                    Icons.gps_fixed,
                    _getAccuracyColor(),
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Conectividad',
                    lastUpdateTime.isNotEmpty ? 'Activa' : 'Sin datos',
                    Icons.signal_cellular_alt,
                    lastUpdateTime.isNotEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Tercera fila - Métricas adicionales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Asistencias Hoy',
                    '${_getTodayAttendanceCount()}',
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Última Actividad',
                    _getLastActivityTime(),
                    Icons.access_time,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📚 PANEL DE HISTORIAL RECIENTE (UI PRESERVADA)
  Widget _buildRecentHistoryPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: AppColors.textGray),
                    SizedBox(width: 8),
                    Text(
                      'Historial Reciente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
                if (attendanceHistory.length > 5 && onViewFullHistory != null)
                  TextButton(
                    onPressed: onViewFullHistory,
                    child: const Text('Ver completo'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (attendanceHistory.isNotEmpty) ...[
              ...attendanceHistory
                  .take(5)
                  .map((asistencia) => _buildHistoryItem(asistencia)),
              
              if (attendanceHistory.length > 5) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${attendanceHistory.length - 5} asistencias más en el historial',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 48,
                      color: AppColors.textGray,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No hay historial de asistencias',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Las asistencias aparecerán aquí cuando participes en eventos',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📊 TARJETA DE ESTADÍSTICA (UI PRESERVADA)
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
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

  /// 📝 ITEM DE HISTORIAL (UI PRESERVADA)
  Widget _buildHistoryItem(Asistencia asistencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getEstadoColor(asistencia.estado),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getEstadoIcon(asistencia.estado),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEstado(asistencia.estado),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${asistencia.hora.day}/${asistencia.hora.month} - ${asistencia.hora.hour.toString().padLeft(2, '0')}:${asistencia.hora.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getEstadoColor(asistencia.estado),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              asistencia.estado.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 OBTENER ESTADO DETALLADO
  String _getDetailedStatus() {
    if (isTrackingActive) {
      if (isInGeofence) {
        return 'Presente';
      } else {
        return 'Fuera del Área';
      }
    }
    return 'Inactivo';
  }

  /// 🎨 OBTENER COLOR DE ESTADO
  Color _getStatusColor() {
    switch (trackingStatus) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'warning':
        return Colors.red;
      case 'error':
        return Colors.red;
      default:
        return AppColors.textGray;
    }
  }

  /// 🎯 OBTENER ICONO DE ESTADO
  IconData _getStatusIcon() {
    switch (trackingStatus) {
      case 'active':
        return Icons.track_changes;
      case 'paused':
        return Icons.pause;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.location_off;
    }
  }

  /// 📍 OBTENER COLOR DE PRECISIÓN
  Color _getAccuracyColor() {
    if (currentAccuracy <= 10) return Colors.green;
    if (currentAccuracy <= 20) return Colors.orange;
    return Colors.red;
  }

  /// 📅 OBTENER ASISTENCIAS DE HOY
  int _getTodayAttendanceCount() {
    final today = DateTime.now();
    return attendanceHistory.where((asistencia) {
      final asistenciaDate = asistencia.hora;
      return asistenciaDate.year == today.year &&
             asistenciaDate.month == today.month &&
             asistenciaDate.day == today.day;
    }).length;
  }

  /// ⏰ OBTENER TIEMPO DE ÚLTIMA ACTIVIDAD
  String _getLastActivityTime() {
    if (attendanceHistory.isEmpty) return 'N/A';
    
    final lastAttendance = attendanceHistory.first;
    final now = DateTime.now();
    final difference = now.difference(lastAttendance.hora);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  /// 🎨 OBTENER COLOR DE ESTADO DE ASISTENCIA
  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Colors.green;
      case 'tarde':
        return Colors.orange;
      case 'ausente':
        return Colors.red;
      case 'justificado':
        return Colors.blue;
      default:
        return AppColors.textGray;
    }
  }

  /// 🎯 OBTENER ICONO DE ESTADO DE ASISTENCIA
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Icons.check_circle;
      case 'tarde':
        return Icons.schedule;
      case 'ausente':
        return Icons.cancel;
      case 'justificado':
        return Icons.description;
      default:
        return Icons.help;
    }
  }

  /// 📝 FORMATEAR ESTADO
  String _formatEstado(String estado) {
    return estado[0].toUpperCase() + estado.substring(1);
  }
}