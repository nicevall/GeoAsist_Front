// lib/widgets/event_card.dart
import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../utils/colors.dart';

class EventCard extends StatelessWidget {
  final Evento evento;
  final bool showActions;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.evento,
    this.showActions = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                  if (showActions) ...[
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      color: AppColors.secondaryTeal,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (evento.descripcion?.isNotEmpty == true) ...[
                Text(
                  evento.descripcion!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(evento.fecha),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(evento.horaInicio),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  const Spacer(),
                  if (evento.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
