// lib/screens/dashboard/widgets/event_control_panel_widget.dart
// 🎯 PANEL DE CONTROL DE EVENTOS FASE A1.2 - Dashboard del profesor
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/evento_model.dart';

class EventControlPanelWidget extends StatefulWidget {
  final List<Evento> teacherEvents;
  final Evento? activeEvent;
  final Function(String) onEventSelected;
  final bool isAutoRefreshEnabled;
  final VoidCallback onToggleAutoRefresh;
  final VoidCallback onManualRefresh;

  const EventControlPanelWidget({
    super.key,
    required this.teacherEvents,
    this.activeEvent,
    required this.onEventSelected,
    required this.isAutoRefreshEnabled,
    required this.onToggleAutoRefresh,
    required this.onManualRefresh,
  });

  @override
  State<EventControlPanelWidget> createState() =>
      _EventControlPanelWidgetState();
}

class _EventControlPanelWidgetState extends State<EventControlPanelWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🎯 HEADER CON CONTROLES PRINCIPALES
          _buildHeader(),

          // 🎯 PANEL EXPANDIBLE DE SELECCIÓN DE EVENTOS
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: _buildEventSelectionPanel(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.secondaryTeal,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Fila principal con información del evento
          Row(
            children: [
              // Icono del evento
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Información del evento activo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activeEvent?.titulo ?? 'Seleccionar Evento',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.activeEvent != null
                          ? '${widget.teacherEvents.length} eventos disponibles'
                          : 'Ningún evento seleccionado',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de expansión
              IconButton(
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.expand_more,
                    color: Colors.white,
                  ),
                ),
                onPressed: _toggleExpansion,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fila de controles
          Row(
            children: [
              // Control de auto-refresh
              Expanded(
                child: _buildControlButton(
                  icon: widget.isAutoRefreshEnabled
                      ? Icons.sync
                      : Icons.sync_disabled,
                  label: 'Auto-actualización',
                  isActive: widget.isAutoRefreshEnabled,
                  onTap: widget.onToggleAutoRefresh,
                ),
              ),

              const SizedBox(width: 8),

              // Botón de actualización manual
              Expanded(
                child: _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Actualizar ahora',
                  isActive: true,
                  onTap: widget.onManualRefresh,
                ),
              ),

              const SizedBox(width: 8),

              // Botón de configuración
              _buildControlButton(
                icon: Icons.settings,
                label: 'Config',
                isActive: true,
                onTap: _showConfigurationDialog,
                isCompact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelectionPanel() {
    if (widget.teacherEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.textGray,
            ),
            SizedBox(height: 12),
            Text(
              'No tienes eventos creados',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del panel
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Seleccionar Evento Activo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
          ),

          // Lista de eventos
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.teacherEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = widget.teacherEvents[index];
                final isSelected = widget.activeEvent?.id == event.id;

                return EventSelectionCard(
                  event: event,
                  isSelected: isSelected,
                  onSelect: () {
                    if (event.id != null) {
                      widget.onEventSelected(event.id!);
                      _toggleExpansion(); // Cerrar panel después de seleccionar
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            if (!isCompact) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración del Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Actualización automática'),
              subtitle: const Text('Actualizar métricas cada 30 segundos'),
              value: widget.isAutoRefreshEnabled,
              onChanged: (_) => widget.onToggleAutoRefresh(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca del Dashboard'),
              subtitle: const Text('Versión 1.2 - Tiempo real'),
              onTap: () {
                Navigator.of(context).pop();
                _showAboutDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard del Docente'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Características:'),
            SizedBox(height: 8),
            Text('• Monitoreo en tiempo real'),
            Text('• Actualización automática cada 30s'),
            Text('• Filtros de estudiantes'),
            Text('• Métricas de asistencia'),
            Text('• Notificaciones contextuales'),
            SizedBox(height: 16),
            Text(
                'Desarrollado para el sistema de asistencia por geolocalización.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// 🎯 WIDGET DE TARJETA DE SELECCIÓN DE EVENTO
class EventSelectionCard extends StatelessWidget {
  final Evento event;
  final bool isSelected;
  final VoidCallback onSelect;

  const EventSelectionCard({
    super.key,
    required this.event,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : AppColors.lightGray.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Indicador de selección
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryOrange : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryOrange : AppColors.textGray,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Información del evento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryOrange
                          : AppColors.darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.descripcion?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.descripcion!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Estado del evento
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getEventStatusColor(event)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getEventStatusText(event),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getEventStatusColor(event),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Fecha y hora
                      Text(
                        _getEventTimeText(event),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Icono de acción
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryOrange : AppColors.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventStatusColor(Evento event) {
    final now = DateTime.now();

    // ✅ CORREGIDO: Usar campos correctos del modelo Evento
    final eventStart =
        event.horaInicio; // Usar horaInicio en lugar de fechaInicio
    final eventEnd = event.horaFinal; // Usar horaFinal en lugar de fechaFinal

    if (now.isBefore(eventStart)) {
      return AppColors.secondaryTeal; // Próximo
    } else if (now.isAfter(eventEnd)) {
      return AppColors.textGray; // Finalizado
    } else {
      return Colors.green; // Activo
    }
  }

  String _getEventStatusText(Evento event) {
    final now = DateTime.now();

    // ✅ CORREGIDO: Usar campos correctos del modelo Evento
    final eventStart = event.horaInicio;
    final eventEnd = event.horaFinal;

    if (now.isBefore(eventStart)) {
      return 'PRÓXIMO';
    } else if (now.isAfter(eventEnd)) {
      return 'FINALIZADO';
    } else {
      return 'ACTIVO';
    }
  }

  String _getEventTimeText(Evento event) {
    // ✅ CORREGIDO: Usar campo fecha en lugar de fechaInicio
    final fecha = event.fecha;
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
