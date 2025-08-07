// lib/screens/map_view/widgets/grace_period_widget.dart
// 🎯 WIDGET ESPECIALIZADO FASE A1.2 - Período de gracia con countdown
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class GracePeriodWidget extends StatefulWidget {
  final int gracePeriodSeconds;
  final Animation<Color?> graceColorAnimation;

  const GracePeriodWidget({
    super.key,
    required this.gracePeriodSeconds,
    required this.graceColorAnimation,
  });

  @override
  State<GracePeriodWidget> createState() => _GracePeriodWidgetState();
}

class _GracePeriodWidgetState extends State<GracePeriodWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animaciones
    _pulseController.repeat(reverse: true);

    // Shake más intenso cuando quedan menos de 20 segundos
    if (widget.gracePeriodSeconds <= 20) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GracePeriodWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar animaciones basadas en el tiempo restante
    if (widget.gracePeriodSeconds <= 20 && oldWidget.gracePeriodSeconds > 20) {
      _shakeController.repeat(reverse: true);
    } else if (widget.gracePeriodSeconds > 20 &&
        oldWidget.gracePeriodSeconds <= 20) {
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.gracePeriodSeconds ~/ 60;
    final seconds = widget.gracePeriodSeconds % 60;
    final isUrgent = widget.gracePeriodSeconds <= 20;
    final isCritical = widget.gracePeriodSeconds <= 10;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pulseAnimation, _shakeAnimation, widget.graceColorAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.graceColorAnimation.value ?? Colors.orange,
                    (widget.graceColorAnimation.value ?? Colors.orange)
                        .withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (widget.graceColorAnimation.value ?? Colors.orange)
                        .withValues(alpha: 0.3),
                    blurRadius: isUrgent ? 15 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: isCritical ? Colors.red : Colors.orange,
                  width: isCritical ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // 🎯 HEADER CON ICONO Y TÍTULO
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCritical ? Icons.warning : Icons.access_time,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCritical ? '⚠️ URGENTE' : '⏰ Período de Gracia',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Regresa al área permitida',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🎯 COUNTDOWN PRINCIPAL
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Tiempo restante grande
                        Text(
                          minutes > 0
                              ? '$minutes:${seconds.toString().padLeft(2, '0')}'
                              : '$seconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCritical ? 36 : 32,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),

                        // Label del tiempo
                        Text(
                          minutes > 0
                              ? 'minutos restantes'
                              : 'segundos restantes',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Barra de progreso
                        _buildProgressBar(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🎯 MENSAJE DE ACCIÓN
                  _buildActionMessage(isUrgent, isCritical),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    // Asumiendo un período de gracia máximo de 60 segundos por defecto
    const maxGracePeriodSeconds = 60;
    final progress = (maxGracePeriodSeconds - widget.gracePeriodSeconds) /
        maxGracePeriodSeconds;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.gracePeriodSeconds <= 10 ? Colors.red : Colors.white,
          ),
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Text(
          '${(clampedProgress * 100).toInt()}% transcurrido',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionMessage(bool isUrgent, bool isCritical) {
    String message;
    IconData icon;

    if (isCritical) {
      message = '🏃‍♂️ ¡Regresa AHORA o perderás la asistencia!';
      icon = Icons.directions_run;
    } else if (isUrgent) {
      message = '📍 Dirígete rápidamente al área del evento';
      icon = Icons.directions_walk;
    } else {
      message = '🗺️ Tienes tiempo para regresar al área permitida';
      icon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
