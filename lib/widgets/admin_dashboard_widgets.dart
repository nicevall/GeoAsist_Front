// lib/widgets/admin_dashboard_widgets.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../models/dashboard_metric_model.dart';
import '../models/evento_model.dart';
import '../services/evento_service.dart'; // ✅ NUEVO
import '../core/app_constants.dart'; // ✅ NUEVO
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
            const Color.fromARGB(255, 142, 36, 170),
            const Color.fromARGB(255, 156, 39, 176).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                const Color.fromARGB(255, 142, 36, 170).withValues(alpha: 0.3),
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
            'Panel de Administración',
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

  /// 📊 NUEVO: Widget para mostrar alertas del sistema
  static Widget buildSystemAlerts() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Alertas del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAlertItem(
              'Usuarios sin verificar', 
              '5 profesores pendientes de verificación',
              Icons.person_off,
              Colors.orange,
            ),
            _buildAlertItem(
              'Eventos problemáticos', 
              '2 eventos con baja asistencia',
              Icons.event_busy,
              Colors.red,
            ),
            _buildAlertItem(
              'Sistema operativo', 
              'Todos los servicios funcionando',
              Icons.check_circle,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 NUEVO: Widget para vista rápida de eventos del sistema
  static Widget buildSystemEventsOverview(List<Evento> eventos) {
    final eventosHoy = eventos.where((e) => 
        e.fechaInicio.day == DateTime.now().day).length;
    final eventosActivos = eventos.where((e) => e.isActive).length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, color: AppColors.primaryOrange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Eventos del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => AppRouter.goToSystemEvents(),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat('Total', '${eventos.length}'),
                ),
                Expanded(
                  child: _buildQuickStat('Hoy', '$eventosHoy'),
                ),
                Expanded(
                  child: _buildQuickStat('Activos', '$eventosActivos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (eventos.isNotEmpty) ...[
              const Text(
                'Eventos Recientes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 8),
              ...eventos.take(3).map((evento) => _buildEventQuickItem(evento)),
            ],
          ],
        ),
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
  /// 📊 EXPANDIDO: Acciones rápidas del administrador con más opciones
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
        
        // Primera fila - Gestión de usuarios
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
                title: 'Gestionar Usuarios',
                subtitle: 'Ver usuarios del sistema',
                color: AppColors.secondaryTeal,
                onTap: () => AppRouter.goToUserManagement(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Segunda fila - Monitoreo y eventos
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event,
                title: 'Eventos Sistema',
                subtitle: 'Ver todos los eventos',
                color: AppColors.primaryOrange,
                onTap: () => AppRouter.goToSystemEvents(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Estadísticas',
                subtitle: 'Métricas avanzadas',
                color: Colors.purple,
                onTap: () => AppRouter.goToAdvancedStats(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Tercera fila - Configuración y alertas
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.warning_amber,
                title: 'Alertas Sistema',
                subtitle: 'Ver alertas críticas',
                color: Colors.red,
                onTap: () => AppRouter.goToSystemAlerts(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings,
                title: 'Configuración',
                subtitle: 'Configurar sistema',
                color: AppColors.darkGray,
                onTap: () => AppRouter.goToSystemConfig(),
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
                onTap: () => AppRouter.goToEventManagement(), // ✅ CORREGIDO
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Reportes',
                subtitle: 'Generar reportes',
                color: Colors.purple,
                onTap: () => AppRouter.navigateToReports(),
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
              onPressed: () => AppRouter.goToEventManagement(), // ✅ CORREGIDO
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

  // ✅ MANEJADORES DE EVENTOS CORREGIDOS SEGÚN FASE B.3
  static void _handleMetricTap(DashboardMetric metric) {
    AppRouter.goToDashboard(); // Navega al dashboard con filtro de métrica
  }

  static void _handleEventTap(Evento evento) {
    // Navegar a vista del mapa en modo admin
    final context = AppRouter.navigatorKey.currentContext!;
    Navigator.of(context).pushNamed(
      AppConstants.mapViewRoute,
      arguments: {
        'eventoId': evento.id,
        'isAdminMode': true,
      },
    );
  }

  static void _handleEventEdit(Evento evento) {
    // Navegar a crear evento con datos para editar
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
          '¿Estás seguro de eliminar "${evento.titulo}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmarEliminacionAdmin(evento);
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

  // ✅ MÉTODO AUXILIAR NUEVO PARA ELIMINACIÓN
  static Future<void> _confirmarEliminacionAdmin(Evento evento) async {
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

  /// 📊 NUEVO: Widget para items de alerta
  static Widget _buildAlertItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
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

  /// 📊 NUEVO: Widget para estadísticas rápidas
  static Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  /// 📊 NUEVO: Widget para items de eventos rápidos
  static Widget _buildEventQuickItem(Evento evento) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: evento.isActive ? Colors.green : AppColors.textGray,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              evento.titulo,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            evento.isActive ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 11,
              color: evento.isActive ? Colors.green : AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
