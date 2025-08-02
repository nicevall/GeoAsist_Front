// lib/widgets/event_attendance_card.dart
import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../utils/colors.dart';

class EventAttendanceCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback onGoToLocation;

  const EventAttendanceCard({
    super.key,
    required this.evento,
    required this.onGoToLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado del evento
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: evento.isActive
                        ? Colors.green
                        : AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
                if (evento.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Descripción si existe
            if (evento.descripcion?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                evento.descripcion!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Información del evento
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  _formatDate(evento.fecha),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRange(evento.horaInicio, evento.horaFinal),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Ubicación y rango
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                const Text(
                  'UIDE Campus Principal',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const SizedBox(width: 16),
                Icon(Icons.radio_button_checked,
                    size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  'Precisión: ${evento.rangoPermitido.toInt()}m',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botón principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGoToLocation,
                icon: const Icon(Icons.location_on, size: 20),
                label: const Text(
                  'Ir a Ubicación del Evento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: evento.isActive
                      ? AppColors.secondaryTeal
                      : AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
