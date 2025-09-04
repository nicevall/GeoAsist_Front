// lib/widgets/dashboard/dashboard_events_widget.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/evento_model.dart';
import '../../core/app_constants.dart';

/// ✅ DASHBOARD EVENTS WIDGET: Eventos reutilizables con estética preservada
/// Responsabilidades:
/// - Renderizado de eventos con estilos exactos del dashboard original
/// - Diferentes vistas por rol (admin, profesor, estudiante)
/// - Navegación contextual preservada
/// - Estados de eventos preservados
/// - Controles por rol (switches, botones)
class DashboardEventsWidget extends StatelessWidget {
  final List<Evento> eventos;
  final bool isLoading;
  final String userRole;
  final String? currentUserId;
  final VoidCallback? onCreateEvent;
  final Function(Evento)? onEventTap;
  final Function(Evento)? onJoinEvent; // Nueva callback para registro directo
  final EventsDisplayMode displayMode;

  const DashboardEventsWidget({
    super.key,
    required this.eventos,
    required this.isLoading,
    required this.userRole,
    this.currentUserId,
    this.onCreateEvent,
    this.onEventTap,
    this.onJoinEvent,
    this.displayMode = EventsDisplayMode.list,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingEvents();
    }

    if (eventos.isEmpty) {
      return _buildEmptyState();
    }

    switch (displayMode) {
      case EventsDisplayMode.list:
        return _buildEventsList();
      case EventsDisplayMode.grid:
        return _buildEventsGrid();
      case EventsDisplayMode.summary:
        return _buildEventsSummary();
    }
  }

  /// 📋 LISTA DE EVENTOS
  Widget _buildEventsList() {
    return Column(
      children: eventos.map((evento) {
        return _buildEventItemByRole(evento);
      }).toList(),
    );
  }

  /// 🏗️ GRID DE EVENTOS
  Widget _buildEventsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        return _buildEventCard(eventos[index]);
      },
    );
  }

  /// 📊 RESUMEN DE EVENTOS
  Widget _buildEventsSummary() {
    final eventosActivos = eventos.where((e) => e.isActive).length;
    final eventosInactivos = eventos.length - eventosActivos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', eventos.length.toString(), Icons.event, AppColors.primaryOrange),
          _buildSummaryItem('Activos', eventosActivos.toString(), Icons.event_available, Colors.green),
          _buildSummaryItem('Inactivos', eventosInactivos.toString(), Icons.event_busy, Colors.grey),
        ],
      ),
    );
  }

  /// 📝 ITEM DE RESUMEN
  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
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
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  /// 🎭 ITEM DE EVENTO SEGÚN ROL
  Widget _buildEventItemByRole(Evento evento) {
    switch (userRole) {
      case AppConstants.adminRole:
        return _buildAdminEventItem(evento);
      case AppConstants.profesorRole:
        return _buildProfessorEventItem(evento);
      case AppConstants.estudianteRole:
        return _buildStudentEventItem(evento);
      default:
        return _buildGenericEventItem(evento);
    }
  }

  /// 👑 ITEM DE EVENTO ADMIN (ESTILO ORIGINAL PRESERVADO)
  Widget _buildAdminEventItem(Evento evento) {
    return GestureDetector(
      onTap: () => onEventTap?.call(evento),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: evento.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  Text(
                    evento.lugar ?? 'Sin ubicación',
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                    ),
                  ),
                  if (evento.creadoPor != null)
                    Text(
                      'Creado por: ${evento.creadoPor}',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: evento.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                evento.isActive ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 👨‍🏫 ITEM DE EVENTO PROFESOR (ESTILO ORIGINAL PRESERVADO)
  Widget _buildProfessorEventItem(Evento evento) {
    return GestureDetector(
      onTap: () => onEventTap?.call(evento),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.lugar ?? 'Sin ubicación',
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '👆 Toca para gestionar',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryOrange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎓 ITEM DE EVENTO ESTUDIANTE (ESTILO ORIGINAL PRESERVADO)
  Widget _buildStudentEventItem(Evento evento) {
    return GestureDetector(
      onTap: () => onEventTap?.call(evento),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.secondaryTeal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 50,
              decoration: BoxDecoration(
                color: evento.isActive ? AppColors.secondaryTeal : Colors.grey,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 16,
                        color: AppColors.secondaryTeal,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.lugar ?? 'Sin ubicación',
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        evento.horaInicioFormatted,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (evento.isActive && onJoinEvent != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onJoinEvent!(evento),
                        icon: const Icon(Icons.login, size: 16),
                        label: const Text('Inscribirse', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📄 ITEM DE EVENTO GENÉRICO
  Widget _buildGenericEventItem(Evento evento) {
    return _buildAdminEventItem(evento); // Usar vista admin como default
  }

  /// 🃏 TARJETA DE EVENTO PARA GRID
  Widget _buildEventCard(Evento evento) {
    return GestureDetector(
      onTap: () => onEventTap?.call(evento),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: evento.isActive ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: evento.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    evento.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.darkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              evento.lugar ?? 'Sin ubicación',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: evento.isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                evento.isActive ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 LOADING DE EVENTOS
  Widget _buildLoadingEvents() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 📭 ESTADO VACÍO
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyMessage(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (userRole == AppConstants.profesorRole && onCreateEvent != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Crear Primer Evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📝 MENSAJE VACÍO SEGÚN ROL
  String _getEmptyMessage() {
    switch (userRole) {
      case AppConstants.adminRole:
        return 'No hay eventos en el sistema';
      case AppConstants.profesorRole:
        return 'No has creado ningún evento aún.\n¡Crea tu primer evento!';
      case AppConstants.estudianteRole:
        return 'No hay eventos disponibles en este momento';
      default:
        return 'No hay eventos disponibles';
    }
  }
}

/// ✅ MODOS DE VISUALIZACIÓN DE EVENTOS
enum EventsDisplayMode {
  list,     // Lista vertical (default)
  grid,     // Grid 2x2
  summary,  // Resumen con contadores
}