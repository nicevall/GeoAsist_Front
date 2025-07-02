// lib/screens/map_view/widgets/attendance_status_cards.dart - ARCHIVO CORREGIDO
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class AttendanceStatusCards extends StatelessWidget {
  final bool isAttendanceActive;
  final bool isInsideGeofence;

  const AttendanceStatusCards({
    super.key,
    required this.isAttendanceActive,
    required this.isInsideGeofence,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildAttendanceCard()),
        const SizedBox(width: 15),
        Expanded(child: _buildLocationCard()),
      ],
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ✅ CORREGIDO: withOpacity -> withValues
        color: isAttendanceActive
            ? AppColors.secondaryTeal.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isAttendanceActive ? AppColors.secondaryTeal : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isAttendanceActive ? Icons.check_circle : Icons.cancel,
            color: isAttendanceActive ? AppColors.secondaryTeal : Colors.red,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            isAttendanceActive ? 'Presente' : 'Ausente',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAttendanceActive ? AppColors.secondaryTeal : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ✅ CORREGIDO: withOpacity -> withValues
        color: isInsideGeofence
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isInsideGeofence ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isInsideGeofence ? Icons.location_on : Icons.location_off,
            color: isInsideGeofence ? Colors.green : Colors.orange,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            isInsideGeofence ? 'En Área' : 'Fuera de Área',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isInsideGeofence ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
