// lib/screens/map_view/widgets/status_panel.dart - ARCHIVO CORREGIDO
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/evento_model.dart';
import 'grace_period_warning.dart';
import 'break_timer.dart';

class StatusPanel extends StatelessWidget {
  final String userName;
  final bool isAttendanceActive;
  final bool isInsideGeofence;
  final bool isOnBreak;
  final int gracePeriodSeconds;
  final int breakTimeRemaining;
  final Evento? currentEvento;
  final Animation<Color?> graceColorAnimation;

  const StatusPanel({
    super.key,
    required this.userName,
    required this.isAttendanceActive,
    required this.isInsideGeofence,
    required this.isOnBreak,
    required this.gracePeriodSeconds,
    required this.breakTimeRemaining,
    required this.currentEvento,
    required this.graceColorAnimation,
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
            // ✅ CORREGIDO: withOpacity -> withValues (línea 41)
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildUserStatus(),
          if (!isInsideGeofence && isAttendanceActive && !isOnBreak) ...[
            const SizedBox(height: 15),
            GracePeriodWarning(
              gracePeriodSeconds: gracePeriodSeconds,
              graceColorAnimation: graceColorAnimation,
            ),
          ],
          if (isOnBreak) ...[
            const SizedBox(height: 15),
            BreakTimer(breakTimeRemaining: breakTimeRemaining),
          ],
        ],
      ),
    );
  }

  Widget _buildUserStatus() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isAttendanceActive ? AppColors.secondaryTeal : Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAttendanceActive ? Icons.check : Icons.close,
            color: AppColors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 15),
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
                _getStatusMessage(),
                style: TextStyle(
                  fontSize: 14,
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (currentEvento != null)
                Text(
                  'Evento: ${currentEvento!.titulo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusMessage() {
    if (isOnBreak) return '☕ En período de descanso';
    if (!isAttendanceActive) return '❌ Asistencia perdida';
    if (!isInsideGeofence) return '⚠️ Fuera del área permitida';
    return '✅ Asistencia activa';
  }

  Color _getStatusColor() {
    if (isOnBreak) return AppColors.secondaryTeal;
    if (!isAttendanceActive) return Colors.red;
    if (!isInsideGeofence) return Colors.orange;
    return Colors.green;
  }
}
