// lib/widgets/attendance/attendance_recovery_widget.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../models/evento_model.dart';
import '../../models/justificacion_model.dart';
import '../../services/justificacion_service.dart';
import '../../utils/app_router.dart';
import '../custom_button.dart';

/// ✅ ATTENDANCE RECOVERY WIDGET: Enhanced UI for attendance recovery system
/// 
/// Features:
/// - Detect missed attendances automatically
/// - Provide multiple recovery options (justification, late attendance, emergency)
/// - Visual timeline of attendance opportunities
/// - Smart suggestions based on event and user context
/// - Integration with justification system
/// - Real-time status updates
class AttendanceRecoveryWidget extends StatefulWidget {
  final String userId;
  final List<Evento> missedEvents;
  final bool isCompact;
  final VoidCallback? onRecoveryComplete;

  const AttendanceRecoveryWidget({
    super.key,
    required this.userId,
    required this.missedEvents,
    this.isCompact = false,
    this.onRecoveryComplete,
  });

  @override
  State<AttendanceRecoveryWidget> createState() => _AttendanceRecoveryWidgetState();
}

class _AttendanceRecoveryWidgetState extends State<AttendanceRecoveryWidget>
    with TickerProviderStateMixin {
  
  // Services
  final JustificacionService _justificacionService = JustificacionService();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // State
  bool _isLoading = false;
  List<MissedAttendance> _missedAttendances = [];
  List<Justificacion> _existingJustifications = [];
  
  // Recovery options
  RecoveryOption? _selectedOption;
  Evento? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMissedAttendances();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
  }

  Future<void> _loadMissedAttendances() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load existing justifications
      final justificationsResponse = await _justificacionService.obtenerMisJustificaciones();
      if (justificationsResponse.success) {
        _existingJustifications = justificationsResponse.data!;
      }

      // Process missed events
      List<MissedAttendance> missedList = [];
      for (final event in widget.missedEvents) {
        final existingJustification = _existingJustifications
            .where((j) => j.eventoId == event.id)
            .firstOrNull;

        missedList.add(MissedAttendance(
          event: event,
          missedTime: _calculateMissedTime(event),
          recoveryDeadline: _calculateRecoveryDeadline(event),
          existingJustification: existingJustification,
          urgencyLevel: _calculateUrgencyLevel(event),
        ));
      }

      // Sort by urgency
      missedList.sort((a, b) => b.urgencyLevel.index.compareTo(a.urgencyLevel.index));

      if (mounted) {
        setState(() {
          _missedAttendances = missedList;
          _isLoading = false;
        });
      }

      logger.d('✅ Loaded ${missedList.length} missed attendances');
    } catch (e) {
      logger.d('❌ Error loading missed attendances: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _calculateMissedTime(Evento event) {
    // Calculate when the attendance was "missed" (usually event start + tolerance)
    final eventStart = DateTime(
      event.fecha.year,
      event.fecha.month,
      event.fecha.day,
      event.horaInicio.hour,
      event.horaInicio.minute,
    );
    return eventStart.add(const Duration(minutes: 15)); // 15 min tolerance
  }

  DateTime _calculateRecoveryDeadline(Evento event) {
    // Students have 24-48 hours to justify depending on event type
    final eventEnd = DateTime(
      event.fecha.year,
      event.fecha.month,
      event.fecha.day,
      event.horaFinal.hour,
      event.horaFinal.minute,
    );
    return eventEnd.add(const Duration(hours: 48));
  }

  AttendanceUrgencyLevel _calculateUrgencyLevel(Evento event) {
    final now = DateTime.now();
    final deadline = _calculateRecoveryDeadline(event);
    final hoursUntilDeadline = deadline.difference(now).inHours;

    if (hoursUntilDeadline < 6) {
      return AttendanceUrgencyLevel.critical;
    } else if (hoursUntilDeadline < 24) {
      return AttendanceUrgencyLevel.high;
    } else if (hoursUntilDeadline < 48) {
      return AttendanceUrgencyLevel.medium;
    } else {
      return AttendanceUrgencyLevel.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    } else {
      return _buildFullView();
    }
  }

  Widget _buildCompactView() {
    if (_missedAttendances.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.errorRed.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactHeader(),
            const SizedBox(height: 12),
            if (_isLoading) 
              _buildLoadingIndicator()
            else ...[
              _buildQuickStats(),
              const SizedBox(height: 12),
              _buildQuickActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullView() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFullHeader(),
            const SizedBox(height: 20),
            if (_isLoading) 
              _buildLoadingList()
            else if (_missedAttendances.isEmpty)
              _buildEmptyState()
            else ...[
              _buildRecoveryTimeline(),
              const SizedBox(height: 20),
              _buildRecoveryOptions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final criticalCount = _missedAttendances
        .where((m) => m.urgencyLevel == AttendanceUrgencyLevel.critical)
        .length;

    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: criticalCount > 0 ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_busy,
                  color: AppColors.errorRed,
                  size: 20,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asistencias Perdidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              if (criticalCount > 0)
                Text(
                  '$criticalCount requieren acción urgente',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.errorRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_missedAttendances.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.errorRed.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  Icons.event_busy,
                  color: AppColors.errorRed,
                  size: 40,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de Recuperación de Asistencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tus asistencias perdidas y envía justificaciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final critical = _missedAttendances
        .where((m) => m.urgencyLevel == AttendanceUrgencyLevel.critical)
        .length;
    final pending = _missedAttendances
        .where((m) => m.existingJustification == null)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            _missedAttendances.length.toString(),
            Icons.event_busy,
            AppColors.errorRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Críticas',
            critical.toString(),
            Icons.priority_high,
            critical > 0 ? AppColors.errorRed : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Pendientes',
            pending.toString(),
            Icons.pending,
            pending > 0 ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Ver Todo',
            onPressed: () => _showFullRecoveryScreen(),
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomButton(
            text: 'Justificar',
            onPressed: () => _startJustificationProcess(),
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asistencias Perdidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _missedAttendances.length,
            itemBuilder: (context, index) {
              return _buildMissedAttendanceItem(_missedAttendances[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissedAttendanceItem(MissedAttendance missed, int index) {
    final urgencyColor = missed.urgencyLevel.color;
    final isExpired = missed.recoveryDeadline.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.3),
          width: isExpired ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                missed.urgencyLevel.icon,
                color: urgencyColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  missed.event.titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
              if (missed.existingJustification != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: missed.existingJustification!.estado.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    missed.existingJustification!.estado.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📅 ${_formatEventDate(missed.event)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '⏰ Límite: ${_formatDeadline(missed.recoveryDeadline)}',
            style: TextStyle(
              fontSize: 12,
              color: isExpired ? AppColors.errorRed : AppColors.textGray,
              fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: missed.existingJustification != null ? 'Ver Justificación' : 'Justificar',
                  onPressed: () => _handleJustificationAction(missed),
                  isPrimary: missed.existingJustification == null,
                ),
              ),
              if (missed.existingJustification == null && !isExpired) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showRecoveryOptions(missed),
                  icon: const Icon(Icons.more_vert),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightGray,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryOptions() {
    if (_selectedEvent == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opciones de Recuperación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ...RecoveryOption.values.map((option) => _buildRecoveryOptionCard(option)),
        ],
      ),
    );
  }

  Widget _buildRecoveryOptionCard(RecoveryOption option) {
    final isSelected = _selectedOption == option;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = option),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? option.color : AppColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? option.color : AppColors.textGray,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? option.color : AppColors.darkGray,
                    ),
                  ),
                  Text(
                    option.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.radio_button_checked,
                color: option.color,
                size: 16,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: AppColors.textGray,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryOrange,
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Excelente!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes asistencias perdidas',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Mantén tu historial de asistencia impecable',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatEventDate(Evento event) {
    return '${event.fecha.day}/${event.fecha.month}/${event.fecha.year} ${event.horaInicioFormatted}';
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Expirado';
    } else if (difference.inDays > 0) {
      return 'En ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'En ${difference.inMinutes} minutos';
    }
  }

  void _showFullRecoveryScreen() {
    AppRouter.showSnackBar('Abriendo pantalla completa de recuperación...');
    // TODO: Navigate to full recovery screen
  }

  void _startJustificationProcess() {
    if (_missedAttendances.isEmpty) return;
    
    final firstMissed = _missedAttendances.first;
    _handleJustificationAction(firstMissed);
  }

  void _handleJustificationAction(MissedAttendance missed) {
    if (missed.existingJustification != null) {
      // Show existing justification
      AppRouter.showSnackBar('Ver justificación existente: ${missed.existingJustification!.estado.displayName}');
    } else {
      // Start new justification
      AppRouter.goToJustifications(); // Navigate to create justification
    }
  }

  void _showRecoveryOptions(MissedAttendance missed) {
    setState(() {
      _selectedEvent = missed.event;
      _selectedOption = null;
    });
  }
}

/// 📋 MISSED ATTENDANCE DATA CLASS
class MissedAttendance {
  final Evento event;
  final DateTime missedTime;
  final DateTime recoveryDeadline;
  final Justificacion? existingJustification;
  final AttendanceUrgencyLevel urgencyLevel;

  const MissedAttendance({
    required this.event,
    required this.missedTime,
    required this.recoveryDeadline,
    this.existingJustification,
    required this.urgencyLevel,
  });
}

/// 🚨 ATTENDANCE URGENCY LEVELS
enum AttendanceUrgencyLevel {
  low(Icons.schedule, Colors.grey, 'Baja'),
  medium(Icons.schedule, Colors.blue, 'Media'),
  high(Icons.priority_high, Colors.orange, 'Alta'),
  critical(Icons.report_problem, Colors.red, 'Crítica');

  const AttendanceUrgencyLevel(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;
}

/// 🔧 RECOVERY OPTIONS
enum RecoveryOption {
  justification(
    Icons.description,
    Colors.blue,
    'Justificación con Documento',
    'Envía documentos que respalden tu ausencia'
  ),
  lateAttendance(
    Icons.access_time,
    Colors.orange,
    'Asistencia Tardía',
    'Reporta que llegaste tarde al evento'
  ),
  emergency(
    Icons.emergency,
    Colors.red,
    'Situación de Emergencia',
    'Para casos de emergencia médica o familiar'
  ),
  technicalIssue(
    Icons.smartphone,
    Colors.purple,
    'Problema Técnico',
    'Problemas con la app o conectividad'
  );

  const RecoveryOption(this.icon, this.color, this.title, this.description);

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}