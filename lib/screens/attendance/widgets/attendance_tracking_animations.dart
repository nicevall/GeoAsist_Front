// lib/screens/attendance/widgets/attendance_tracking_animations.dart
import 'package:flutter/material.dart';

class AttendanceTrackingAnimations {
  late AnimationController trackingController;
  late AnimationController pulseController;
  late Animation<double> trackingAnimation;
  late Animation<double> pulseAnimation;

  void initializeAnimations(TickerProvider tickerProvider) {
    // Animación principal de tracking
    trackingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: tickerProvider,
    );

    pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: tickerProvider,
    );

    trackingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: trackingController,
      curve: Curves.easeInOut,
    ));

    pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeInOut,
    ));

    pulseController.repeat(reverse: true);
  }

  void startTrackingAnimation() {
    trackingController.forward();
  }

  void stopTrackingAnimation() {
    trackingController.reverse();
  }

  void startPulseAnimation() {
    if (!pulseController.isAnimating) {
      pulseController.repeat(reverse: true);
    }
  }

  void stopPulseAnimation() {
    pulseController.stop();
  }

  void dispose() {
    trackingController.dispose();
    pulseController.dispose();
  }
}

class TrackingStatusIndicator extends StatelessWidget {
  final Animation<double> trackingAnimation;
  final Animation<double> pulseAnimation;
  final bool isTrackingActive;
  final bool isInGeofence;
  final String trackingStatus;

  const TrackingStatusIndicator({
    super.key,
    required this.trackingAnimation,
    required this.pulseAnimation,
    required this.isTrackingActive,
    required this.isInGeofence,
    required this.trackingStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([trackingAnimation, pulseAnimation]),
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: _getStatusColors(),
              stops: const [0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _getStatusColors()[0].withValues(alpha: 0.3),
                spreadRadius: 5 * pulseAnimation.value,
                blurRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Icon(
                _getStatusIcon(),
                key: ValueKey(trackingStatus),
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getStatusColors() {
    if (!isTrackingActive) {
      return [Colors.grey.shade600, Colors.grey.shade800];
    } else if (isInGeofence) {
      return [Colors.green.shade400, Colors.green.shade700];
    } else {
      return [Colors.orange.shade400, Colors.orange.shade700];
    }
  }

  IconData _getStatusIcon() {
    switch (trackingStatus) {
      case 'active':
        return isInGeofence ? Icons.check_circle : Icons.location_searching;
      case 'violation':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.location_off;
    }
  }
}