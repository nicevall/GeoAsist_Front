// lib/widgets/professor_dashboard_widgets.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../models/dashboard_metric_model.dart';
import '../models/evento_model.dart';
import '../services/evento_service.dart'; // ✅ AGREGADO - Error línea 548
import 'dashboard_metric_card.dart' as metric_card;
import 'event_card.dart' as event_card;

class ProfessorDashboardWidgets {
  /// Widget de bienvenida para docente
  static Widget buildWelcomeHeader(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 46, 125, 50),
            const Color.fromARGB(255, 67, 160, 71).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                const Color.fromARGB(255, 46, 125, 50).withValues(alpha: 0.3),
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
              Icons.school,
              color: AppColors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenido',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _capitalizeUserName(userName),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Panel de Docente',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Métricas contextuales para docente (métricas generales + sus eventos)
  static Widget buildProfessorMetrics(
      List<DashboardMetric> systemMetrics, List<Evento> professorEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Actividad',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 16),

        // Métrica de eventos propios
        metric_card.DashboardMetricCard(
          metric: DashboardMetric(
            id: 'profesor-eventos',
            metric: 'Mis Eventos',
            value: professorEvents.length.toDouble(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          icon: Icons.event,
          color: AppColors.primaryOrange,
          onTap: () => _handleMyEventsTap(),
        ),

        // Métricas contextuales del sistema (solo algunas relevantes)
        ...systemMetrics
            .where((metric) => _isRelevantForProfessor(metric.metric))
            .map((metric) => metric_card.DashboardMetricCard(
                  metric: metric,
                  onTap: () => _handleSystemMetricTap(metric),
                )),
      ],
    );
  }

  /// Acciones rápidas para docente
  static Widget buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle,
                title: 'Crear Evento',
                subtitle: 'Nuevo evento de asistencia',
                color: AppColors.primaryOrange,
                onTap: () => AppRouter.goToCreateEvent(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.list_alt,
                title: 'Mis Eventos',
                subtitle: 'Gestionar mis eventos',
                color: AppColors.secondaryTeal,
                onTap: () => AppRouter.goToEventManagement(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.analytics,
          title: 'Ver Asistencias',
          subtitle: 'Revisar asistencias de mis eventos',
          color: Colors.green,
          onTap: () {
            // ✅ CORREGIDO - TODO válido para PHASE 4
            AppRouter.showSnackBar('Próximamente: Reporte de asistencias');
          },
        ),
      ],
    );
  }

  /// Eventos del docente (solo los que él creó)
  static Widget buildMyEvents(List<Evento> eventos) {
    if (eventos.isEmpty) {
      return _buildEmptyEvents();
    }

    // Ordenar por fecha más reciente y mostrar los primeros 3
    final sortedEvents = List<Evento>.from(eventos);
    sortedEvents.sort((a, b) => b.fecha.compareTo(a.fecha));
    final recentEvents = sortedEvents.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Eventos Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            TextButton(
              onPressed: () {
                // ✅ CORREGIDO - TODO válido para PHASE 4
                AppRouter.showSnackBar('Próximamente: Todos mis eventos');
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentEvents.map((evento) => event_card.EventCard(
              evento: evento,
              showActions: true, // Docente puede editar/eliminar SUS eventos
              onTap: () => _handleEventTap(evento),
              onEdit: () => _handleEventEdit(evento),
              onDelete: () => _handleEventDelete(evento),
            )),
      ],
    );
  }

  /// Widget de próximos eventos activos
  static Widget buildUpcomingEvents(List<Evento> eventos) {
    final now = DateTime.now();
    final upcomingEvents = eventos
        .where((evento) => evento.fecha.isAfter(now) || evento.isActive)
        .take(2)
        .toList();

    if (upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximos Eventos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...upcomingEvents.map((evento) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    evento.isActive ? Icons.circle : Icons.schedule,
                    color: AppColors.primaryOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                        ),
                        Text(
                          _formatEventTime(evento),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (evento.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            )),
      ],
    );
  }

  /// Widget de estadísticas rápidas del docente
  static Widget buildQuickStats(List<Evento> eventos) {
    final now = DateTime.now();
    final activeEvents = eventos.where((e) => e.isActive).length;
    final todayEvents = eventos
        .where((e) =>
            e.fecha.year == now.year &&
            e.fecha.month == now.month &&
            e.fecha.day == now.day)
        .length;
    final thisWeekEvents = eventos
        .where((e) => e.fecha.isAfter(now.subtract(const Duration(days: 7))))
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem('Eventos Activos',
                      activeEvents.toString(), Colors.green)),
              Expanded(
                  child: _buildStatItem(
                      'Hoy', todayEvents.toString(), AppColors.primaryOrange)),
              Expanded(
                  child: _buildStatItem('Esta Semana',
                      thisWeekEvents.toString(), AppColors.secondaryTeal)),
            ],
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares privados
  static Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static Widget _buildEmptyEvents() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.secondaryTeal.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No tienes eventos creados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tu primer evento para comenzar a gestionar asistencias',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => AppRouter.goToCreateEvent(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryTeal,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static bool _isRelevantForProfessor(String metric) {
    // Solo mostrar métricas relevantes para docentes
    const relevantMetrics = ['usuarios', 'asistencias'];
    return relevantMetrics.contains(metric.toLowerCase());
  }

  static String _formatEventTime(Evento evento) {
    if (evento.isActive) {
      return 'En curso ahora';
    }

    final start =
        '${evento.horaInicio.hour.toString().padLeft(2, '0')}:${evento.horaInicio.minute.toString().padLeft(2, '0')}';
    final date = '${evento.fecha.day}/${evento.fecha.month}';
    return '$date a las $start';
  }

  // Manejadores de eventos
  static void _handleMyEventsTap() {
    AppRouter.goToEventManagement();
  }

  static void _handleSystemMetricTap(DashboardMetric metric) {
    // ✅ CORREGIDO - TODO válido para PHASE 4
    AppRouter.showSnackBar('Información sobre ${metric.metric}');
  }

  static void _handleEventTap(Evento evento) {
    // ✅ CORREGIDO - Usar método correcto del AppRouter
    AppRouter.goToMapView(isAdminMode: true);
  }

  static void _handleEventEdit(Evento evento) {
    // ✅ CORREGIDO - Usar método correcto del AppRouter
    AppRouter.goToCreateEvent(editEvent: evento);
  }

  static void _handleEventDelete(Evento evento) {
    // Mostrar confirmación antes de eliminar
    final context = AppRouter.navigatorKey.currentContext!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: Text(
            '¿Estás seguro de eliminar "${evento.titulo}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmarEliminacion(evento);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmarEliminacion(Evento evento) async {
    try {
      final eventoService = EventoService();
      final result = await eventoService.eliminarEvento(evento.id!);

      if (result.success) {
        AppRouter.showSnackBar(
            'Evento "${evento.titulo}" eliminado exitosamente');
      } else {
        AppRouter.showSnackBar('Error: ${result.message}', isError: true);
      }
    } catch (e) {
      AppRouter.showSnackBar('Error eliminando evento: $e', isError: true);
    }
  }

  static String _capitalizeUserName(String name) {
    if (name.isEmpty) return name;

    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
