// lib/screens/widgets/break_timer.dart
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class BreakTimer extends StatelessWidget {
  final int breakTimeRemaining;

  const BreakTimer({
    super.key,
    required this.breakTimeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryTeal, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.coffee, color: AppColors.secondaryTeal, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '☕ Descanso Activo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                Text(
                  'Tiempo restante: ${_formatTime(breakTimeRemaining)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
