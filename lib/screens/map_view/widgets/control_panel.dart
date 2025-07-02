// lib/screens/widgets/control_panel.dart
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../models/evento_model.dart';
import 'attendance_status_cards.dart';

class ControlPanel extends StatelessWidget {
  final bool isAdminMode;
  final bool isOnBreak;
  final bool isAttendanceActive;
  final bool isInsideGeofence;
  final Evento? currentEvento;
  final VoidCallback onStartBreak;
  final VoidCallback onEndBreak;
  final VoidCallback onRegisterAttendance;
  final VoidCallback onRefreshData;

  const ControlPanel({
    super.key,
    required this.isAdminMode,
    required this.isOnBreak,
    required this.isAttendanceActive,
    required this.isInsideGeofence,
    required this.currentEvento,
    required this.onStartBreak,
    required this.onEndBreak,
    required this.onRegisterAttendance,
    required this.onRefreshData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: isAdminMode ? _buildAdminControls() : _buildAttendeeControls(),
    );
  }

  Widget _buildAdminControls() {
    return Column(
      children: [
        const Text(
          '🔧 Controles de Administrador',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: isOnBreak ? 'Terminar Descanso' : 'Iniciar Descanso',
                onPressed: isOnBreak ? onEndBreak : onStartBreak,
                isPrimary: !isOnBreak,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: 'Registrar Asistencia',
                onPressed: currentEvento != null ? onRegisterAttendance : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CustomButton(
          text: 'Actualizar Eventos',
          onPressed: onRefreshData,
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildAttendeeControls() {
    return Column(
      children: [
        const Text(
          '📱 Estado de Asistencia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 15),
        AttendanceStatusCards(
          isAttendanceActive: isAttendanceActive,
          isInsideGeofence: isInsideGeofence,
        ),
        const SizedBox(height: 15),
        if (currentEvento != null && isInsideGeofence && !isOnBreak)
          CustomButton(
            text: 'Registrar Mi Asistencia',
            onPressed: onRegisterAttendance,
          ),
      ],
    );
  }
}
