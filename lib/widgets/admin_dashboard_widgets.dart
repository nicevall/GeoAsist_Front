// lib/widgets/admin_dashboard_widgets.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../models/dashboard_metric_model.dart';
import '../models/evento_model.dart';
import 'dashboard_metric_card.dart' as metric_card;
import 'event_card.dart' as event_card;

class AdminDashboardWidgets {
  /// Widget de bienvenida para administrador
  static Widget buildWelcomeHeader(String userName) {
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
              Icons.admin_panel_settings,
              color: AppColors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bienvenido, $userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const Text(
            'Panel de Administración',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de métricas del sistema para admin
  static Widget buildSystemMetrics(List<DashboardMetric> metrics) {
    if (metrics.isEmpty) {
      return _buildEmptyMetrics();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas del Sistema',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        ...metrics.map((metric) => metric_card.DashboardMetricCard(
              metric: metric,
              onTap: () => _handleMetricTap(metric),
            )),
      ],
    );
  }

  /// Sección de acciones rápidas para admin
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
                icon: Icons.person_add,
                title: 'Crear Docente',
                subtitle: 'Registrar nuevo docente',
                color: Colors.green,
                onTap: () => AppRouter.goToCreateProfessor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.manage_accounts,
                title: 'Gestionar Docentes',
                subtitle: 'Ver y editar docentes',
                color: AppColors.secondaryTeal,
                onTap: () => AppRouter.goToProfessorManagement(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event_note,
                title: 'Eventos del Sistema',
                subtitle: 'Ver todos los eventos',
                color: AppColors.primaryOrange,
                onTap: () {
                  // TODO: Navegar a gestión de eventos cuando esté implementada
                  AppRouter.showSnackBar('Próximamente: Gestión de eventos');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Reportes',
                subtitle: 'Generar reportes',
                color: Colors.purple,
                onTap: () {
                  // TODO: Navegar a reportes cuando esté implementado
                  AppRouter.showSnackBar('Próximamente: Sistema de reportes');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Resumen de eventos recientes para admin (ve TODOS los eventos)
  static Widget buildRecentEvents(List<Evento> eventos) {
    if (eventos.isEmpty) {
      return _buildEmptyEvents();
    }

    // Mostrar solo los 3 más recientes
    final recentEvents = eventos.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Eventos Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navegar a lista completa de eventos
                AppRouter.showSnackBar(
                    'Próximamente: Lista completa de eventos');
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentEvents.map((evento) => event_card.EventCard(
              evento: evento,
              showActions: true, // Admin puede editar/eliminar cualquier evento
              onTap: () => _handleEventTap(evento),
              onEdit: () => _handleEventEdit(evento),
              onDelete: () => _handleEventDelete(evento),
            )),
      ],
    );
  }

  /// Widget de resumen de actividad del sistema
  static Widget buildSystemActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.trending_up,
                color: AppColors.secondaryTeal,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Actividad del Sistema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Sistema funcionando correctamente\n'
            '• Última sincronización: hace 2 minutos\n'
            '• Usuarios activos: en tiempo real\n'
            '• Base de datos: estable',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.5,
            ),
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

  static Widget _buildEmptyMetrics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics,
            size: 48,
            color: AppColors.textGray,
          ),
          SizedBox(height: 12),
          Text(
            'No hay métricas disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          Text(
            'Las métricas aparecerán cuando haya actividad en el sistema',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      child: const Column(
        children: [
          Icon(
            Icons.event_note,
            size: 48,
            color: AppColors.textGray,
          ),
          SizedBox(height: 12),
          Text(
            'No hay eventos registrados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          Text(
            'Los eventos creados por docentes aparecerán aquí',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Manejadores de eventos
  static void _handleMetricTap(DashboardMetric metric) {
    // TODO: Implementar navegación a detalles de métrica
    AppRouter.showSnackBar('Próximamente: Detalles de ${metric.metric}');
  }

  static void _handleEventTap(Evento evento) {
    // TODO: Implementar navegación a detalles de evento
    AppRouter.showSnackBar(
        'Próximamente: Detalles del evento ${evento.titulo}');
  }

  static void _handleEventEdit(Evento evento) {
    // TODO: Implementar edición de evento
    AppRouter.showSnackBar('Próximamente: Editar evento ${evento.titulo}');
  }

  static void _handleEventDelete(Evento evento) {
    // TODO: Implementar confirmación y eliminación
    AppRouter.showSnackBar('Próximamente: Eliminar evento ${evento.titulo}');
  }
}
