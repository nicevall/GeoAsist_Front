// lib/widgets/dashboard/student_dashboard_section.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/dashboard_metric_model.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import '../../widgets/custom_button.dart';
import 'dashboard_metrics_widget.dart';
import 'dashboard_events_widget.dart';
import '../attendance/attendance_recovery_widget.dart';
import '../../services/attendance_recovery_service.dart';

/// ✅ STUDENT DASHBOARD SECTION: Panel completo para estudiante
/// Responsabilidades:
/// - Panel completo para estudiante con estética preservada
/// - Eventos disponibles para unirse
/// - Estado actual de asistencia si hay evento activo
/// - Botones de justificaciones
/// - Historial personal
/// - Navegación a tracking preservada
class StudentDashboardSection extends StatefulWidget {
  final Usuario currentUser;
  final List<DashboardMetric> metrics;
  final List<Evento> availableEvents;
  final Evento? activeEvent;
  final bool isLoadingMetrics;
  final bool isLoadingEvents;
  final VoidCallback? onJoinEvent;
  final VoidCallback? onPreRegisterEvents; // ✅ NUEVO: Pre-registro
  final Function(Evento)? onJoinSpecificEvent; // ✅ NUEVO: Registro específico por evento
  final VoidCallback? onViewJustifications;
  final VoidCallback? onViewHistory;
  final VoidCallback? onLogout;
  final Function(Evento)? onEventTap;
  final VoidCallback? onStartTracking;

  const StudentDashboardSection({
    super.key,
    required this.currentUser,
    required this.metrics,
    required this.availableEvents,
    this.activeEvent,
    required this.isLoadingMetrics,
    required this.isLoadingEvents,
    this.onJoinEvent,
    this.onPreRegisterEvents, // ✅ NUEVO: Pre-registro
    this.onJoinSpecificEvent,
    this.onViewJustifications,
    this.onViewHistory,
    this.onLogout,
    this.onEventTap,
    this.onStartTracking,
  });

  @override
  State<StudentDashboardSection> createState() => _StudentDashboardSectionState();
}

class _StudentDashboardSectionState extends State<StudentDashboardSection> {
  final AttendanceRecoveryService _recoveryService = AttendanceRecoveryService();
  List<MissedAttendance> _missedAttendances = [];
  bool _isLoadingRecovery = true;

  @override
  void initState() {
    super.initState();
    _loadMissedAttendances();
  }

  Future<void> _loadMissedAttendances() async {
    setState(() {
      _isLoadingRecovery = true;
    });

    try {
      final response = await _recoveryService.detectMissedAttendances(widget.currentUser.id);
      if (response.success && mounted) {
        setState(() {
          _missedAttendances = response.data!;
          _isLoadingRecovery = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecovery = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida (preservando estilo original)
          _buildWelcomeHeader(widget.currentUser.nombre),

          const SizedBox(height: 16),

          // Sistema de recuperación de asistencia
          if (_missedAttendances.isNotEmpty && !_isLoadingRecovery)
            AttendanceRecoveryWidget(
              userId: widget.currentUser.id,
              missedEvents: _missedAttendances.map((m) => m.event).toList(),
              isCompact: true,
              onRecoveryComplete: _loadMissedAttendances,
            ),

          // Estado actual del estudiante
          if (widget.activeEvent != null) _buildActiveEventSection(),

          SizedBox(height: widget.activeEvent != null ? 24 : 0),

          // Estadísticas del estudiante
          _buildStudentStatsSection(),

          const SizedBox(height: 24),

          // Eventos disponibles
          _buildAvailableEventsSection(),

          const SizedBox(height: 24),

          // Acciones rápidas del estudiante
          _buildStudentQuickActions(),

          const SizedBox(height: 32),

          // Botón de logout
          if (widget.onLogout != null) _buildLogoutButton(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 🎯 SECCIÓN DE EVENTO ACTIVO
  Widget _buildActiveEventSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryTeal.withValues(alpha: 0.1),
            AppColors.primaryOrange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryTeal.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, color: AppColors.secondaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Evento Activo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            widget.activeEvent!.titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          
          Text(
            'Tipo: ${widget.activeEvent!.tipo ?? 'No especificado'}',
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          if (widget.onStartTracking != null)
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Iniciar Seguimiento',
                onPressed: widget.onStartTracking ?? () {},
                backgroundColor: AppColors.secondaryTeal,
              ),
            ),
        ],
      ),
    );
  }

  /// 📊 SECCIÓN DE ESTADÍSTICAS DEL ESTUDIANTE
  Widget _buildStudentStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            const Text(
              'Mi Rendimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Métricas en fila horizontal
        DashboardMetricsWidget(
          metrics: widget.metrics.where((m) => m.metric.contains('estudiante')).toList(),
          customMetrics: _getStudentMetrics(),
          isLoading: widget.isLoadingMetrics,
          layout: MetricLayout.row,
          userRole: 'estudiante',
        ),
      ],
    );
  }

  /// 📚 SECCIÓN DE EVENTOS DISPONIBLES
  Widget _buildAvailableEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.event_note, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                const Text(
                  'Eventos Disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(width: 8),
                if (!widget.isLoadingEvents)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.availableEvents.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.onViewHistory != null)
              TextButton(
                onPressed: widget.onViewHistory,
                child: const Text('Ver Historial'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de eventos disponibles para el estudiante
        DashboardEventsWidget(
          eventos: widget.availableEvents,
          isLoading: widget.isLoadingEvents,
          userRole: 'estudiante',
          currentUserId: widget.currentUser.id,
          onEventTap: widget.onEventTap,
          onJoinEvent: widget.onJoinSpecificEvent,
          displayMode: EventsDisplayMode.list,
        ),

        // Mensaje si no hay eventos disponibles
        if (!widget.isLoadingEvents && widget.availableEvents.isEmpty) ...[ 
          const SizedBox(height: 16),
          _buildNoEventsCard(),
        ],
      ],
    );
  }

  /// ⚡ ACCIONES RÁPIDAS DEL ESTUDIANTE
  Widget _buildStudentQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),

        // Botones de acciones
        Row(
          children: [
            if (widget.onViewJustifications != null)
              Expanded(
                child: CustomButton(
                  text: 'Justificaciones',
                  onPressed: widget.onViewJustifications ?? () {},
                  backgroundColor: AppColors.secondaryTeal,
                ),
              ),
            if (widget.onViewJustifications != null && widget.onViewHistory != null)
              const SizedBox(width: 12),
            if (widget.onViewHistory != null)
              Expanded(
                child: CustomButton(
                  text: 'Mi Historial',
                  onPressed: widget.onViewHistory ?? () {},
                  backgroundColor: Colors.purple,
                ),
              ),
          ],
        ),

        // ✅ SIMPLIFICADO: Botón único para eventos disponibles
        if (widget.onJoinEvent != null) ...[ 
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Ver Todos los Eventos',
              onPressed: widget.onJoinEvent ?? () {},
              backgroundColor: AppColors.primaryOrange,
            ),
          ),
        ],
      ],
    );
  }

  /// 📭 TARJETA PARA CUANDO NO HAY EVENTOS
  Widget _buildNoEventsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightGray.withValues(alpha: 0.3),
            AppColors.textGray.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textGray.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Actualmente no hay eventos a los que puedas unirte. Los eventos aparecerán aquí cuando estén disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚪 BOTÓN DE LOGOUT (ESTILO PRESERVADO)
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Cerrar Sesión',
        onPressed: widget.onLogout ?? () {},
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  /// Widget de bienvenida para estudiante
  Widget _buildWelcomeHeader(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrange.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Bienvenido/a',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 MÉTRICAS ESPECÍFICAS DEL ESTUDIANTE
  List<MetricData> _getStudentMetrics() {
    final eventosDisponibles = widget.availableEvents.length;
    final tieneEventoActivo = widget.activeEvent != null;
    
    return [
      MetricData(
        title: 'Eventos Disponibles',
        value: eventosDisponibles.toString(),
        icon: Icons.event_available,
        color: AppColors.secondaryTeal,
      ),
      MetricData(
        title: 'Estado Actual',
        value: tieneEventoActivo ? 'Activo' : 'Libre',
        icon: tieneEventoActivo ? Icons.event : Icons.event_busy,
        color: tieneEventoActivo ? Colors.green : AppColors.textGray,
      ),
    ];
  }
}

