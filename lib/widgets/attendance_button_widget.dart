// lib/widgets/attendance_button_widget.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/attendance_state_model.dart';

class AttendanceButtonWidget extends StatefulWidget {
  final StudentAttendanceStatus attendanceStatus;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AttendanceButtonWidget({
    super.key,
    required this.attendanceStatus,
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
    if (widget.attendanceStatus.showAttendanceButton) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AttendanceButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controlar animación según estado
    if (widget.attendanceStatus.showAttendanceButton &&
        !oldWidget.attendanceStatus.showAttendanceButton) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.attendanceStatus.showAttendanceButton &&
        oldWidget.attendanceStatus.showAttendanceButton) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          if (widget.attendanceStatus.distanceToEvent != null) ...[
            const SizedBox(height: 8),
            _buildDistanceInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final status = widget.attendanceStatus;

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
                  status.statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusBackgroundColor(),
                  ),
                ),
                if (status.showGracePeriodWarning) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tiempo restante: ${status.gracePeriodSeconds}s',
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
    final status = widget.attendanceStatus;
    final bool isButtonEnabled =
        status.showAttendanceButton && !widget.isLoading;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: status.showAttendanceButton ? _pulseAnimation.value : 1.0,
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
                          status.buttonText,
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
    final distance = widget.attendanceStatus.distanceToEvent!;
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
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor() {
    switch (widget.attendanceStatus.state) {
      case AttendanceState.insideRange:
        return Colors.green;
      case AttendanceState.registered:
        return Colors.green;
      case AttendanceState.gracePeriod:
        return Colors.orange;
      case AttendanceState.outsideRange:
        return AppColors.primaryOrange;
      case AttendanceState.eventEnded:
        return AppColors.textGray;
      case AttendanceState.eventNotStarted:
        return AppColors.secondaryTeal;
      case AttendanceState.loading:
        return AppColors.primaryOrange;
      case AttendanceState.error:
        return Colors.red;
    }
  }

  Color _getButtonColor() {
    switch (widget.attendanceStatus.state) {
      case AttendanceState.insideRange:
        return widget.attendanceStatus.hasRegistered
            ? Colors.green
            : AppColors.secondaryTeal;
      case AttendanceState.registered:
        return Colors.green;
      case AttendanceState.gracePeriod:
        return Colors.orange;
      case AttendanceState.eventEnded:
        return AppColors.textGray;
      case AttendanceState.eventNotStarted:
        return AppColors.textGray;
      default:
        return AppColors.lightGray;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.attendanceStatus.state) {
      case AttendanceState.insideRange:
        return widget.attendanceStatus.hasRegistered
            ? Icons.check_circle
            : Icons.location_on;
      case AttendanceState.registered:
        return Icons.check_circle;
      case AttendanceState.gracePeriod:
        return Icons.warning_amber;
      case AttendanceState.outsideRange:
        return Icons.near_me;
      case AttendanceState.eventEnded:
        return Icons.event_busy;
      case AttendanceState.eventNotStarted:
        return Icons.schedule;
      case AttendanceState.loading:
        return Icons.sync;
      case AttendanceState.error:
        return Icons.error;
    }
  }

  IconData _getButtonIcon() {
    switch (widget.attendanceStatus.state) {
      case AttendanceState.insideRange:
        return widget.attendanceStatus.hasRegistered
            ? Icons.check_circle
            : Icons.how_to_reg;
      case AttendanceState.registered:
        return Icons.check_circle;
      case AttendanceState.gracePeriod:
        return Icons.directions_run;
      case AttendanceState.eventEnded:
        return Icons.event_busy;
      case AttendanceState.eventNotStarted:
        return Icons.schedule;
      default:
        return Icons.location_searching;
    }
  }
}
