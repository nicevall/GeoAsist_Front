// lib/widgets/attendance_button_widget.dart
// 🎯 ACTUALIZADO PARA FASE A1.2 - Compatible con AttendanceState y LocationResponseModel
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/attendance_state_model.dart';
import '../models/location_response_model.dart';

class AttendanceButtonWidget extends StatefulWidget {
  final AttendanceState attendanceState;
  final LocationResponseModel? locationResponse;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AttendanceButtonWidget({
    super.key,
    required this.attendanceState,
    this.locationResponse,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<AttendanceButtonWidget> createState() => _AttendanceButtonWidgetState();
}

class _AttendanceButtonWidgetState extends State<AttendanceButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Solo animar cuando puede registrar asistencia
    if (_shouldShowButton()) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AttendanceButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controlar animación según estado
    if (_shouldShowButton() &&
        !_shouldShowButtonForState(oldWidget.attendanceState)) {
      _pulseController.repeat(reverse: true);
    } else if (!_shouldShowButton() &&
        _shouldShowButtonForState(oldWidget.attendanceState)) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  bool _shouldShowButton() {
    return _shouldShowButtonForState(widget.attendanceState);
  }

  bool _shouldShowButtonForState(AttendanceState state) {
    return state.canRegisterAttendance && !state.hasRegisteredAttendance;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No mostrar si no hay evento activo
    if (widget.attendanceState.currentEvent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información de estado
          _buildStatusInfo(),

          const SizedBox(height: 12),

          // Botón principal
          _buildMainButton(),

          // Información adicional
          if (widget.locationResponse != null) ...[
            const SizedBox(height: 8),
            _buildDistanceInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusBackgroundColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusBackgroundColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.attendanceState.statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusBackgroundColor(),
                  ),
                ),
                if (widget.attendanceState.isInGracePeriod) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tiempo restante: ${_formatGracePeriod()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final bool isButtonEnabled = _shouldShowButton() && !widget.isLoading;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _shouldShowButton() ? _pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: isButtonEnabled
                  ? [
                      BoxShadow(
                        color: _getButtonColor().withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: isButtonEnabled ? widget.onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.lightGray,
                disabledForegroundColor: AppColors.textGray,
                elevation: isButtonEnabled ? 8 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getButtonIcon(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getButtonText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDistanceInfo() {
    final distance = widget.attendanceState.distanceToEvent;
    final distanceText = distance < 1000
        ? '${distance.toStringAsFixed(0)}m del evento'
        : '${(distance / 1000).toStringAsFixed(1)}km del evento';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 16,
            color: AppColors.textGray,
          ),
          const SizedBox(width: 4),
          Text(
            distanceText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.locationResponse != null) ...[
            const SizedBox(width: 8),
            Text(
              '• ${widget.locationResponse!.formattedDistance}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🎯 MÉTODOS AUXILIARES - ADAPTADOS A AttendanceState

  Color _getStatusBackgroundColor() {
    if (widget.attendanceState.hasRegisteredAttendance) {
      return Colors.green;
    }

    switch (widget.attendanceState.attendanceStatus) {
      case AttendanceStatus.canRegister:
        return widget.attendanceState.isInsideGeofence
            ? Colors.green
            : Colors.orange;
      case AttendanceStatus.registered:
        return Colors.green;
      case AttendanceStatus.gracePeriod:
        return Colors.orange;
      case AttendanceStatus.outsideGeofence:
        return AppColors.primaryOrange;
      case AttendanceStatus.violation:
        return Colors.red;
      case AttendanceStatus.notStarted:
        return AppColors.secondaryTeal;
    }
  }

  Color _getButtonColor() {
    if (widget.attendanceState.hasRegisteredAttendance) {
      return Colors.green;
    }

    if (!widget.attendanceState.canRegisterAttendance) {
      return AppColors.lightGray;
    }

    switch (widget.attendanceState.attendanceStatus) {
      case AttendanceStatus.canRegister:
        return AppColors.secondaryTeal;
      case AttendanceStatus.gracePeriod:
        return Colors.orange;
      default:
        return AppColors.lightGray;
    }
  }

  IconData _getStatusIcon() {
    if (widget.attendanceState.hasRegisteredAttendance) {
      return Icons.check_circle;
    }

    switch (widget.attendanceState.attendanceStatus) {
      case AttendanceStatus.canRegister:
        return widget.attendanceState.isInsideGeofence
            ? Icons.location_on
            : Icons.near_me;
      case AttendanceStatus.registered:
        return Icons.check_circle;
      case AttendanceStatus.gracePeriod:
        return Icons.warning_amber;
      case AttendanceStatus.outsideGeofence:
        return Icons.location_off;
      case AttendanceStatus.violation:
        return Icons.error;
      case AttendanceStatus.notStarted:
        return Icons.schedule;
    }
  }

  IconData _getButtonIcon() {
    if (widget.attendanceState.hasRegisteredAttendance) {
      return Icons.check_circle;
    }

    if (widget.attendanceState.isInGracePeriod) {
      return Icons.directions_run;
    }

    return Icons.how_to_reg;
  }

  String _getButtonText() {
    if (widget.attendanceState.hasRegisteredAttendance) {
      return 'Asistencia Registrada';
    }

    if (widget.attendanceState.isInGracePeriod) {
      return 'Registrar Ahora';
    }

    if (!widget.attendanceState.canRegisterAttendance) {
      return 'No Disponible';
    }

    return 'Registrar Mi Asistencia';
  }

  String _formatGracePeriod() {
    final minutes = widget.attendanceState.gracePeriodRemaining ~/ 60;
    final seconds = widget.attendanceState.gracePeriodRemaining % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
