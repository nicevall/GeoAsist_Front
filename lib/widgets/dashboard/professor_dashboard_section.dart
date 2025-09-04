// lib/widgets/dashboard/professor_dashboard_section.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/dashboard_metric_model.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import '../../widgets/professor_dashboard_widgets.dart';
import '../../widgets/custom_button.dart';
import 'dashboard_metrics_widget.dart';
import 'dashboard_events_widget.dart';
import 'event_students_management_widget.dart';

/// ✅ PROFESSOR DASHBOARD SECTION: Panel completo para profesor
/// Responsabilidades:
/// - Panel completo para profesor con estética preservada
/// - Solo eventos creados por él
/// - Botón "Crear Evento" funcional
/// - Navegación a event_monitor  
/// - Estadísticas de sus eventos
class ProfessorDashboardSection extends StatelessWidget {
  final Usuario currentUser;
  final List<DashboardMetric> metrics;
  final List<Evento> userEvents;
  final bool isLoadingMetrics;
  final bool isLoadingEvents;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onManageEvents;
  final VoidCallback? onViewReports;
  final VoidCallback? onLogout;
  final Function(Evento)? onEventTap;

  const ProfessorDashboardSection({
    super.key,
    required this.currentUser,
    required this.metrics,
    required this.userEvents,
    required this.isLoadingMetrics,
    required this.isLoadingEvents,
    this.onCreateEvent,
    this.onManageEvents,
    this.onViewReports,
    this.onLogout,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida (preservando estilo original)
          ProfessorDashboardWidgets.buildWelcomeHeader(currentUser.nombre),

          const SizedBox(height: 16),

          // Estadísticas del profesor
          _buildProfessorStatsSection(),

          const SizedBox(height: 24),

          // Mis eventos con controles
          _buildMyEventsSection(),

          const SizedBox(height: 24),

          // Gestión de estudiantes para eventos activos
          _buildActiveEventsStudentsManagement(),

          const SizedBox(height: 24),

          // Acciones rápidas del profesor
          _buildProfessorQuickActions(),

          const SizedBox(height: 32),

          // Botón de logout
          if (onLogout != null) _buildLogoutButton(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 📊 SECCIÓN DE ESTADÍSTICAS DEL PROFESOR
  Widget _buildProfessorStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            const Text(
              'Mis Estadísticas',
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
          metrics: metrics.where((m) => m.metric.contains('profesor')).toList(),
          customMetrics: _getProfessorMetrics(),
          isLoading: isLoadingMetrics,
          layout: MetricLayout.row,
          userRole: 'profesor',
        ),
      ],
    );
  }

  /// 📚 SECCIÓN DE MIS EVENTOS
  Widget _buildMyEventsSection() {
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
                  'Mis Eventos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isLoadingEvents)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${userEvents.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (onManageEvents != null)
              TextButton(
                onPressed: onManageEvents,
                child: const Text('Gestionar'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de eventos del profesor con controles
        DashboardEventsWidget(
          eventos: userEvents,
          isLoading: isLoadingEvents,
          userRole: 'profesor',
          currentUserId: currentUser.id,
          onEventTap: onEventTap,
          displayMode: EventsDisplayMode.list,
        ),

        // Botón para crear evento si no hay eventos
        if (!isLoadingEvents && userEvents.isEmpty && onCreateEvent != null) ...[
          const SizedBox(height: 16),
          _buildCreateFirstEventCard(),
        ],
      ],
    );
  }

  /// 👥 GESTIÓN DE ESTUDIANTES PARA EVENTOS ACTIVOS
  Widget _buildActiveEventsStudentsManagement() {
    final activeEvents = userEvents.where((e) => e.isActive).toList();
    
    if (activeEvents.isEmpty) {
      return const SizedBox.shrink(); // No mostrar si no hay eventos activos
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: AppColors.secondaryTeal),
            const SizedBox(width: 8),
            const Text(
              'Gestión de Estudiantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${activeEvents.length} activo${activeEvents.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Mostrar widget de gestión para cada evento activo (compacto)
        ...activeEvents.map((evento) => EventStudentsManagementWidget(
          evento: evento,
          currentUserId: currentUser.id,
          isCompact: true,
          onExpand: () => _showExpandedStudentsManagement(evento),
        )),
      ],
    );
  }

  /// 🔍 Mostrar gestión expandida de estudiantes
  void _showExpandedStudentsManagement(Evento evento) {
    // En el futuro, esto podría abrir una página completa
    // Por ahora, navegar al monitor de eventos que tiene funcionalidad similar
    if (onEventTap != null) {
      onEventTap!(evento);
    }
  }

  /// ⚡ ACCIONES RÁPIDAS DEL PROFESOR
  Widget _buildProfessorQuickActions() {
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

        // Botón principal: Crear Evento
        if (onCreateEvent != null) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Crear Nuevo Evento',
              onPressed: onCreateEvent ?? () {},
              backgroundColor: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botones secundarios
        Row(
          children: [
            if (onManageEvents != null)
              Expanded(
                child: CustomButton(
                  text: 'Gestionar Eventos',
                  onPressed: onManageEvents ?? () {},
                  backgroundColor: AppColors.secondaryTeal,
                ),
              ),
            if (onManageEvents != null && onViewReports != null)
              const SizedBox(width: 12),
            if (onViewReports != null)
              Expanded(
                child: CustomButton(
                  text: 'Ver Reportes',
                  onPressed: onViewReports ?? () {},
                  backgroundColor: Colors.purple,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 🎯 TARJETA PARA CREAR PRIMER EVENTO
  Widget _buildCreateFirstEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange.withValues(alpha: 0.1),
            AppColors.secondaryTeal.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 12),
          const Text(
            '¡Crea tu primer evento!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comienza a gestionar la asistencia de tus estudiantes creando tu primer evento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Crear Evento',
            onPressed: onCreateEvent ?? () {},
            backgroundColor: AppColors.primaryOrange,
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
        onPressed: onLogout ?? () {},
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  /// 📊 MÉTRICAS ESPECÍFICAS DEL PROFESOR
  List<MetricData> _getProfessorMetrics() {
    final eventosActivos = userEvents.where((e) => e.isActive).length;
    final eventosInactivos = userEvents.length - eventosActivos;
    
    return [
      MetricData(
        title: 'Total Eventos',
        value: userEvents.length.toString(),
        icon: Icons.event_note,
        color: AppColors.primaryOrange,
      ),
      MetricData(
        title: 'Activos',
        value: eventosActivos.toString(),
        icon: Icons.event_available,
        color: Colors.green,
      ),
      if (eventosInactivos > 0)
        MetricData(
          title: 'Inactivos',
          value: eventosInactivos.toString(),
          icon: Icons.event_busy,
          color: Colors.grey,
        ),
    ];
  }
}

