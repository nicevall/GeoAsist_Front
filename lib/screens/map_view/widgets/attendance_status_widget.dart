// lib/screens/map_view/widgets/attendance_status_widget.dart
// 🎯 WIDGET ESPECIALIZADO FASE A1.2 - Estado de asistencia con datos reales
import 'package:flutter/material.dart';
import '../../../models/attendance_state_model.dart';
import '../../../models/location_response_model.dart';
import '../../../models/evento_model.dart';
import '../../../utils/colors.dart';

class AttendanceStatusWidget extends StatelessWidget {
  final AttendanceState attendanceState;
  final LocationResponseModel? locationResponse;
  final String userName;
  final Evento? currentEvento;

  const AttendanceStatusWidget({
    super.key,
    required this.attendanceState,
    this.locationResponse,
    required this.userName,
    this.currentEvento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
          // 🎯 HEADER CON USUARIO Y ESTADO PRINCIPAL
          _buildUserHeader(),

          const SizedBox(height: 16),

          // 🎯 INFORMACIÓN DEL EVENTO ACTUAL
          if (currentEvento != null) _buildEventInfo(),

          if (currentEvento != null) const SizedBox(height: 12),

          // 🎯 MÉTRICAS EN TIEMPO REAL
          _buildRealtimeMetrics(),

          const SizedBox(height: 12),

          // 🎯 INDICADORES DE ESTADO
          _buildStatusIndicators(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        // Avatar con estado visual
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStatusColorFromString(attendanceState.statusColor),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStatusIcon(),
            color: AppColors.white,
            size: 28,
          ),
        ),

        const SizedBox(width: 16),

        // Información del usuario
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $userName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                attendanceState.statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: _getStatusColorFromString(attendanceState.statusColor),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Indicador de tracking activo
        if (attendanceState.trackingStatus == TrackingStatus.active)
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radio_button_checked,
              size: 8,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event,
            color: AppColors.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentEvento!.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (currentEvento!.descripcion?.isNotEmpty == true)
                  Text(
                    currentEvento!.descripcion!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeMetrics() {
    return Row(
      children: [
        // Distancia al evento
        Expanded(
          child: _buildMetricCard(
            icon: Icons.location_on,
            label: 'Distancia',
            value: locationResponse?.formattedDistance ??
                '${attendanceState.distanceToEvent.toStringAsFixed(1)}m',
            color:
                attendanceState.isInsideGeofence ? Colors.green : Colors.orange,
          ),
        ),

        const SizedBox(width: 12),

        // Estado de geofence
        Expanded(
          child: _buildMetricCard(
            icon: attendanceState.isInsideGeofence
                ? Icons.check_circle
                : Icons.warning,
            label: 'Ubicación',
            value: attendanceState.isInsideGeofence ? 'Dentro' : 'Fuera',
            color: attendanceState.isInsideGeofence ? Colors.green : Colors.red,
          ),
        ),

        const SizedBox(width: 12),

        // Tiempo de tracking
        Expanded(
          child: _buildMetricCard(
            icon: Icons.timer,
            label: 'Tracking',
            value: _getTrackingDuration(),
            color: AppColors.secondaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Indicador de registro de asistencia
        if (attendanceState.hasRegisteredAttendance)
          _buildStatusChip(
            label: 'Asistencia Registrada',
            icon: Icons.check_circle,
            color: Colors.green,
          ),

        // Indicador de período de gracia
        if (attendanceState.isInGracePeriod)
          _buildStatusChip(
            label: 'Período de Gracia: ${_formatGracePeriod()}',
            icon: Icons.access_time,
            color: Colors.orange,
          ),

        // Indicador de violación de límites
        if (attendanceState.hasViolatedBoundary)
          _buildStatusChip(
            label: 'Límites Violados',
            icon: Icons.warning,
            color: Colors.red,
          ),

        // Indicador de tracking pausado
        if (attendanceState.trackingStatus == TrackingStatus.paused)
          _buildStatusChip(
            label: 'En Receso',
            icon: Icons.pause_circle,
            color: AppColors.secondaryTeal,
          ),

        // Indicador de error
        if (attendanceState.lastError != null)
          _buildStatusChip(
            label: 'Error de conexión',
            icon: Icons.error,
            color: Colors.red,
          ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 MÉTODOS AUXILIARES

  /// Convierte el string de color hexadecimal a Color
  Color _getStatusColorFromString(String colorString) {
    try {
      // Remover el # si está presente
      String hexColor = colorString.replaceAll('#', '');
      // Agregar FF para opacidad si es necesario
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Color por defecto si hay error
      return AppColors.textGray;
    }
  }

  IconData _getStatusIcon() {
    switch (attendanceState.attendanceStatus) {
      case AttendanceStatus.registered:
        return Icons.check;
      case AttendanceStatus.canRegister:
        return Icons.how_to_reg;
      case AttendanceStatus.outsideGeofence:
        return Icons.location_off;
      case AttendanceStatus.gracePeriod:
        return Icons.access_time;
      case AttendanceStatus.violation:
        return Icons.warning;
      case AttendanceStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  String _getTrackingDuration() {
    if (attendanceState.trackingStartTime == null) {
      return '0m';
    }

    final duration =
        DateTime.now().difference(attendanceState.trackingStartTime!);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatGracePeriod() {
    final minutes = attendanceState.gracePeriodRemaining ~/ 60;
    final seconds = attendanceState.gracePeriodRemaining % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
