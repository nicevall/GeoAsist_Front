// lib/screens/map_view/widgets/notification_overlay_widget.dart
// 🎯 WIDGET ESPECIALIZADO FASE A1.2 - Overlay de notificaciones visuales
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/attendance_state_model.dart';
import '../../../utils/colors.dart';

class NotificationOverlayWidget extends StatefulWidget {
  final AttendanceState attendanceState;

  const NotificationOverlayWidget({
    super.key,
    required this.attendanceState,
  });

  @override
  State<NotificationOverlayWidget> createState() =>
      _NotificationOverlayWidgetState();
}

class _NotificationOverlayWidgetState extends State<NotificationOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  AttendanceState? _previousState;
  String? _currentNotificationMessage;
  Color _currentNotificationColor = Colors.blue;
  IconData _currentNotificationIcon = Icons.info;
  bool _isShowingNotification = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(NotificationOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detectar cambios de estado y mostrar notificaciones apropiadas
    if (_shouldShowNotification(
        oldWidget.attendanceState, widget.attendanceState)) {
      _showStateChangeNotification(
          oldWidget.attendanceState, widget.attendanceState);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool _shouldShowNotification(
      AttendanceState oldState, AttendanceState newState) {
    // No mostrar en el primer load
    if (_previousState == null) {
      _previousState = newState;
      return false;
    }

    // Detectar cambios significativos
    return _hasSignificantChange(oldState, newState);
  }

  bool _hasSignificantChange(
      AttendanceState oldState, AttendanceState newState) {
    // Cambio en geofence
    if (oldState.isInsideGeofence != newState.isInsideGeofence) return true;

    // Cambio en estado de tracking
    if (oldState.trackingStatus != newState.trackingStatus) return true;

    // Cambio en período de gracia
    if (oldState.isInGracePeriod != newState.isInGracePeriod) return true;

    // Cambio en registro de asistencia
    if (oldState.hasRegisteredAttendance != newState.hasRegisteredAttendance) {
      return true;
    }

    // Cambio en violación de límites
    if (oldState.hasViolatedBoundary != newState.hasViolatedBoundary) {
      return true;
    }

    // Nuevo error
    if (oldState.lastError != newState.lastError &&
        newState.lastError != null) {
      return true;
    }

    return false;
  }

  void _showStateChangeNotification(
      AttendanceState oldState, AttendanceState newState) {
    String message;
    Color color;
    IconData icon;
    VibrationPattern vibrationPattern = VibrationPattern.light;

    // Determinar el tipo de notificación basado en el cambio
    if (oldState.isInsideGeofence != newState.isInsideGeofence) {
      if (newState.isInsideGeofence) {
        message = '✅ Has ingresado al área del evento';
        color = Colors.green;
        icon = Icons.check_circle;
        vibrationPattern = VibrationPattern.medium;
      } else {
        message = '⚠️ Has salido del área permitida';
        color = Colors.orange;
        icon = Icons.warning;
        vibrationPattern = VibrationPattern.heavy;
      }
    } else if (oldState.isInGracePeriod != newState.isInGracePeriod) {
      if (newState.isInGracePeriod) {
        message = '⏰ Período de gracia iniciado';
        color = Colors.orange;
        icon = Icons.access_time;
        vibrationPattern = VibrationPattern.heavy;
      } else {
        message = '❌ Período de gracia terminado';
        color = Colors.red;
        icon = Icons.timer_off;
        vibrationPattern = VibrationPattern.error;
      }
    } else if (oldState.trackingStatus != newState.trackingStatus) {
      switch (newState.trackingStatus) {
        case TrackingStatus.active:
          message = '▶️ Tracking reanudado';
          color = Colors.green;
          icon = Icons.play_circle;
          vibrationPattern = VibrationPattern.light;
          break;
        case TrackingStatus.paused:
          message = '⏸️ Tracking pausado - En receso';
          color = AppColors.secondaryTeal;
          icon = Icons.pause_circle;
          vibrationPattern = VibrationPattern.medium;
          break;
        case TrackingStatus.stopped:
          message = '⏹️ Tracking detenido';
          color = Colors.grey;
          icon = Icons.stop_circle;
          vibrationPattern = VibrationPattern.light;
          break;
        case TrackingStatus.error:
          message = '❌ Error en el tracking';
          color = Colors.red;
          icon = Icons.error;
          vibrationPattern = VibrationPattern.error;
          break;
        default:
          return; // No mostrar notificación para otros estados
      }
    } else if (oldState.hasRegisteredAttendance !=
        newState.hasRegisteredAttendance) {
      if (newState.hasRegisteredAttendance) {
        message = '🎉 Asistencia registrada exitosamente';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        vibrationPattern = VibrationPattern.success;
      } else {
        return; // No deberían poder "des-registrar" asistencia
      }
    } else if (oldState.hasViolatedBoundary != newState.hasViolatedBoundary) {
      if (newState.hasViolatedBoundary) {
        message = '🚨 Límites de asistencia violados';
        color = Colors.red;
        icon = Icons.gpp_bad;
        vibrationPattern = VibrationPattern.error;
      } else {
        return; // Raramente se revertiría una violación
      }
    } else if (newState.lastError != null &&
        oldState.lastError != newState.lastError) {
      message = '⚠️ Error de conexión';
      color = Colors.red;
      icon = Icons.signal_wifi_connected_no_internet_4;
      vibrationPattern = VibrationPattern.error;
    } else {
      return; // No hay cambio significativo para notificar
    }

    _displayNotification(message, color, icon, vibrationPattern);
  }

  void _displayNotification(String message, Color color, IconData icon,
      VibrationPattern vibrationPattern) {
    // Actualizar estado de la notificación
    setState(() {
      _currentNotificationMessage = message;
      _currentNotificationColor = color;
      _currentNotificationIcon = icon;
      _isShowingNotification = true;
    });

    // Vibración háptica
    _triggerHapticFeedback(vibrationPattern);

    // Mostrar animación
    _slideController.forward();
    _fadeController.forward();

    // Ocultar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hideNotification();
      }
    });
  }

  void _hideNotification() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isShowingNotification = false;
          _currentNotificationMessage = null;
        });
      }
    });
    _fadeController.reverse();
  }

  void _triggerHapticFeedback(VibrationPattern pattern) {
    switch (pattern) {
      case VibrationPattern.light:
        HapticFeedback.lightImpact();
        break;
      case VibrationPattern.medium:
        HapticFeedback.mediumImpact();
        break;
      case VibrationPattern.heavy:
        HapticFeedback.heavyImpact();
        break;
      case VibrationPattern.success:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
        });
        break;
      case VibrationPattern.error:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.mediumImpact();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isShowingNotification || _currentNotificationMessage == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentNotificationColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _currentNotificationColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _hideNotification,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentNotificationIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentNotificationMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _hideNotification,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 🎯 ENUM PARA PATRONES DE VIBRACIÓN
enum VibrationPattern {
  light,
  medium,
  heavy,
  success,
  error,
}
