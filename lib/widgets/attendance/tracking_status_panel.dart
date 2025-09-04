// lib/widgets/attendance/tracking_status_panel.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';

/// ✅ TRACKING STATUS PANEL: Panel de estado del tracking preservado
/// Responsabilidades:
/// - Visualización de estados con colores contextuales
/// - Grace periods duales (geofence + app closed)
/// - Animaciones de estado preservadas
/// - Contadores independientes sin conflictos
/// - Panel de instrucciones dinámico
class TrackingStatusPanel extends StatelessWidget {
  final bool isTrackingActive;
  final bool isInGeofence;
  final String trackingStatus;
  final int geofenceSecondsRemaining;
  final int appClosedSecondsRemaining;
  final Duration timeInEvent;
  final int exitWarningCount;
  final double distanceFromCenter;
  final Animation<double> trackingAnimation;
  final VoidCallback? onStatusTap;

  const TrackingStatusPanel({
    super.key,
    required this.isTrackingActive,
    required this.isInGeofence,
    required this.trackingStatus,
    required this.geofenceSecondsRemaining,
    required this.appClosedSecondsRemaining,
    required this.timeInEvent,
    required this.exitWarningCount,
    required this.distanceFromCenter,
    required this.trackingAnimation,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Panel de instrucciones dinámico
        _buildInstructionsPanel(),
        const SizedBox(height: 16),
        
        // Panel principal de estado
        _buildMainStatusPanel(),
      ],
    );
  }

  /// 🎯 PANEL DE INSTRUCCIONES PARA EL USUARIO (UI PRESERVADA)
  Widget _buildInstructionsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isTrackingActive ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            isTrackingActive ? Colors.green.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTrackingActive ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTrackingActive ? Icons.check_circle : Icons.info_outline,
                color: isTrackingActive ? Colors.green : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isTrackingActive ? '¡Tracking Activo!' : 'Cómo funciona',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isTrackingActive ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isTrackingActive) ...[
            _buildInstructionStep(
              '1.',
              'Presiona "Iniciar" para activar el tracking GPS',
              Icons.play_arrow,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '2.',
              'Dirígete hacia el área del evento',
              Icons.directions_walk,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '3.',
              'Tu asistencia se registrará automáticamente al entrar',
              Icons.check_circle,
              Colors.green,
            ),
          ] else ...[
            Text(
              '• GPS monitoreando tu ubicación cada 5 segundos\n'
              '• Distancia al evento: ${distanceFromCenter.toStringAsFixed(0)}m\n'
              '• Tu asistencia se registrará automáticamente al entrar al área',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📊 PANEL PRINCIPAL DE ESTADO DEL TRACKING (UI PRESERVADA)
  Widget _buildMainStatusPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: trackingAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onStatusTap != null)
                  IconButton(
                    icon: Icon(Icons.info_outline, color: _getStatusColor()),
                    onPressed: onStatusTap,
                  ),
              ],
            ),
            
            // ✅ DUAL GRACE PERIODS DISPLAY (SIN CONFLICTOS)
            if (geofenceSecondsRemaining > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Geofence Grace Period: ${geofenceSecondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (appClosedSecondsRemaining > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'App Closed Grace Period: ${appClosedSecondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Estadísticas cuando tracking está activo
            if (isTrackingActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Tiempo en Evento',
                      _formatDuration(timeInEvent),
                      Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Salidas del Área',
                      '$exitWarningCount',
                      Icons.exit_to_app,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📝 PASO DE INSTRUCCIÓN (UI PRESERVADA)
  Widget _buildInstructionStep(String number, String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// 📊 ITEM DE ESTADÍSTICA (UI PRESERVADA)
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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
    );
  }

  /// 🎨 OBTENER COLOR DE ESTADO CONTEXTUAL
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

  /// 📝 OBTENER TEXTO DE ESTADO
  String _getStatusText() {
    switch (trackingStatus) {
      case 'active':
        return 'Tracking Activo';
      case 'paused':
        return 'Tracking Pausado';
      case 'warning':
        return 'Advertencia - App en Background';
      case 'error':
        return 'Error en Tracking';
      default:
        return 'Tracking Inactivo';
    }
  }

  /// ⏱️ FORMATEAR DURACIÓN
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}