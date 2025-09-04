// lib/widgets/dashboard/admin_dashboard_section.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/dashboard_metric_model.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import '../../widgets/admin_dashboard_widgets.dart';
import '../../widgets/custom_button.dart';
import 'dashboard_metrics_widget.dart';
import 'dashboard_events_widget.dart';

/// ✅ ADMIN DASHBOARD SECTION: Panel completo para administrador
/// Responsabilidades:
/// - Panel completo para administrador con estética preservada
/// - Métricas del sistema reales del backend
/// - Vista de todos los eventos
/// - Alertas del sistema
/// - Navegación admin preservada
class AdminDashboardSection extends StatelessWidget {
  final Usuario currentUser;
  final List<DashboardMetric> metrics;
  final List<Evento> eventos;
  final bool isLoadingMetrics;
  final bool isLoadingEvents;
  final VoidCallback? onViewAllEvents;
  final VoidCallback? onViewReports;
  final VoidCallback? onSystemSettings;
  final VoidCallback? onLogout;
  final Function(Evento)? onEventTap;

  const AdminDashboardSection({
    super.key,
    required this.currentUser,
    required this.metrics,
    required this.eventos,
    required this.isLoadingMetrics,
    required this.isLoadingEvents,
    this.onViewAllEvents,
    this.onViewReports,
    this.onSystemSettings,
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
          AdminDashboardWidgets.buildWelcomeHeader(currentUser.nombre),

          const SizedBox(height: 16),

          // Métricas del sistema
          _buildSystemMetricsSection(),

          const SizedBox(height: 24),

          // Sección de eventos globales
          _buildGlobalEventsSection(),

          const SizedBox(height: 24),

          // Alertas del sistema
          _buildSystemAlertsSection(),

          const SizedBox(height: 24),

          // Acciones rápidas admin
          _buildAdminQuickActions(),

          const SizedBox(height: 32),

          // Botón de logout
          if (onLogout != null) _buildLogoutButton(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 📊 SECCIÓN DE MÉTRICAS DEL SISTEMA
  Widget _buildSystemMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            const Text(
              'Métricas del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Usar el widget reutilizable de métricas
        DashboardMetricsWidget(
          metrics: metrics,
          customMetrics: _getAdminMetrics(),
          isLoading: isLoadingMetrics,
          layout: MetricLayout.grid,
          userRole: 'admin',
        ),
      ],
    );
  }

  /// 🌍 SECCIÓN DE EVENTOS GLOBALES
  Widget _buildGlobalEventsSection() {
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
                  'Eventos del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            if (onViewAllEvents != null)
              TextButton(
                onPressed: onViewAllEvents,
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de eventos limitada (últimos 5)
        DashboardEventsWidget(
          eventos: eventos.take(5).toList(),
          isLoading: isLoadingEvents,
          userRole: 'admin',
          onEventTap: onEventTap,
          displayMode: EventsDisplayMode.list,
        ),

        if (!isLoadingEvents && eventos.length > 5) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onViewAllEvents,
              icon: const Icon(Icons.arrow_forward),
              label: Text('Ver ${eventos.length - 5} eventos más'),
            ),
          ),
        ],
      ],
    );
  }

  /// 🚨 SECCIÓN DE ALERTAS DEL SISTEMA
  Widget _buildSystemAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: AppColors.warningOrange),
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

        // Generar alertas basadas en datos
        ..._getSystemAlerts().map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  /// ⚡ ACCIONES RÁPIDAS ADMIN
  Widget _buildAdminQuickActions() {
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

        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Ver Reportes',
                onPressed: onViewReports ?? () {},
                backgroundColor: AppColors.secondaryTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Configuración',
                onPressed: onSystemSettings ?? () {},
                backgroundColor: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🚨 TARJETA DE ALERTA
  Widget _buildAlertCard(SystemAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.severity == AlertSeverity.high 
            ? AppColors.errorRed.withValues(alpha: 0.1)
            : alert.severity == AlertSeverity.medium
                ? AppColors.warningOrange.withValues(alpha: 0.1)
                : AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.severity == AlertSeverity.high 
              ? AppColors.errorRed
              : alert.severity == AlertSeverity.medium
                  ? AppColors.warningOrange
                  : AppColors.successGreen,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            alert.severity == AlertSeverity.high 
                ? Icons.error
                : alert.severity == AlertSeverity.medium
                    ? Icons.warning
                    : Icons.info,
            color: alert.severity == AlertSeverity.high 
                ? AppColors.errorRed
                : alert.severity == AlertSeverity.medium
                    ? AppColors.warningOrange
                    : AppColors.successGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
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
        onPressed: onLogout ?? () {},
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  /// 📊 MÉTRICAS ESPECÍFICAS DE ADMIN
  List<MetricData> _getAdminMetrics() {
    final eventosActivos = eventos.where((e) => e.isActive).length;
    
    return [
      MetricData(
        title: 'Eventos Activos',
        value: eventosActivos.toString(),
        icon: Icons.event,
        color: AppColors.secondaryTeal,
      ),
      MetricData(
        title: 'Total Eventos',
        value: eventos.length.toString(),
        icon: Icons.event_note,
        color: Colors.purple,
      ),
    ];
  }

  /// 🚨 OBTENER ALERTAS DEL SISTEMA
  List<SystemAlert> _getSystemAlerts() {
    List<SystemAlert> alerts = [];

    // Alerta de eventos sin actividad
    final eventosInactivos = eventos.where((e) => !e.isActive).length;
    if (eventosInactivos > 0) {
      alerts.add(SystemAlert(
        title: 'Eventos Inactivos',
        message: '$eventosInactivos eventos están desactivados',
        severity: AlertSeverity.medium,
      ));
    }

    // Alerta si no hay eventos
    if (eventos.isEmpty) {
      alerts.add(SystemAlert(
        title: 'Sin Eventos',
        message: 'No hay eventos creados en el sistema',
        severity: AlertSeverity.high,
      ));
    }

    // Alerta de sistema saludable
    if (alerts.isEmpty) {
      alerts.add(SystemAlert(
        title: 'Sistema Operativo',
        message: 'Todos los sistemas funcionan correctamente',
        severity: AlertSeverity.low,
      ));
    }

    return alerts;
  }
}

/// ✅ MODELO DE ALERTA DEL SISTEMA
class SystemAlert {
  final String title;
  final String message;
  final AlertSeverity severity;

  SystemAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
}

/// ✅ NIVELES DE SEVERIDAD
enum AlertSeverity {
  low,    // Info/Success
  medium, // Warning
  high,   // Error/Critical
}