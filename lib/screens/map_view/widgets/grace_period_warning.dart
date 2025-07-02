// lib/screens/widgets/grace_period_warning.dart
import 'package:flutter/material.dart';

class GracePeriodWarning extends StatelessWidget {
  final int gracePeriodSeconds;
  final Animation<Color?> graceColorAnimation;

  const GracePeriodWarning({
    super.key,
    required this.gracePeriodSeconds,
    required this.graceColorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: graceColorAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: graceColorAnimation.value!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: graceColorAnimation.value!, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: graceColorAnimation.value,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ Período de Gracia Activo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: graceColorAnimation.value,
                      ),
                    ),
                    Text(
                      'Regresa al área en: ${_formatTime(gracePeriodSeconds)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
