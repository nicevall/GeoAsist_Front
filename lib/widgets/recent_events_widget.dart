// lib/widgets/recent_events_widget.dart
import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../utils/colors.dart';

/// Widget específico para mostrar eventos recientes con filtrado por estado
class RecentEventsWidget extends StatelessWidget {
  final List<Evento> eventos;
  final bool showInactiveEvents;
  final Function(Evento)? onEventTap;
  final bool showStatusToggle;
  final String title;
  final int maxEvents;
  
  const RecentEventsWidget({
    super.key,
    required this.eventos,
    this.showInactiveEvents = false,
    this.onEventTap,
    this.showStatusToggle = true,
    this.title = 'Eventos Recientes',
    this.maxEvents = 5,
  });

  @override
  Widget build(BuildContext context) {
    // FILTRAR: Solo eventos activos por defecto
    final filteredEvents = _filterEventsByStatus();
    
    if (filteredEvents.isEmpty) {
      return _buildEmptyState();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          ...filteredEvents.take(maxEvents).map((evento) => _buildEventCard(evento)),
        ],
      ),
    );
  }
  
  /// Filtrar eventos según el estado configurado
  List<Evento> _filterEventsByStatus() {
    if (showInactiveEvents) {
      return eventos;
    }
    
    // FILTRAR: Solo eventos activos o próximos
    return eventos.where((evento) {
      final now = DateTime.now();
      
      // Evento está activo
      if (evento.isActive) return true;
      
      // Evento es futuro y no está cancelado
      if (evento.fecha.isAfter(now) && !_isEventCancelled(evento)) {
        return true;
      }
      
      // Evento de hoy que aún no termina
      if (_isEventToday(evento) && !_hasEventEnded(evento)) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  /// Header del widget con título y contador
  Widget _buildHeader() {
    final filteredCount = _filterEventsByStatus().length;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            if (filteredCount > 0)
              Text(
                '$filteredCount evento${filteredCount != 1 ? 's' : ''} ${showInactiveEvents ? 'total' : 'activo'}${filteredCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
          ],
        ),
        // Indicador de filtro activo
        if (!showInactiveEvents)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Solo activos',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  /// Card individual para cada evento
  Widget _buildEventCard(Evento evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _getEventBackgroundColor(evento),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEventBorderColor(evento),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildStatusIndicator(evento),
        title: Text(
          evento.titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getEventSubtitle(evento)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  _formatEventTime(evento),
                  style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                ),
                const Spacer(),
                _buildStatusChip(evento),
              ],
            ),
          ],
        ),
        trailing: showStatusToggle ? _buildEventToggle(evento) : null,
        onTap: () => onEventTap?.call(evento),
      ),
    );
  }
  
  /// Indicador visual del estado del evento
  Widget _buildStatusIndicator(Evento evento) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getStatusColor(evento),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(evento).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
  
  /// Toggle visual para mostrar el estado del evento
  Widget _buildEventToggle(Evento evento) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TOGGLE: Indicador visual del estado (solo visual, no editable)
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _isEventActive(evento),
            onChanged: null, // Solo visual, no editable desde aquí
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
  
  /// Chip de estado del evento
  Widget _buildStatusChip(Evento evento) {
    final status = _getEventStatus(evento);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(evento),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Estado vacío cuando no hay eventos que mostrar
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            showInactiveEvents ? 'No hay eventos' : 'No hay eventos activos',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showInactiveEvents 
                ? 'Los eventos aparecerán aquí cuando se creen'
                : 'Los eventos activos aparecerán aquí',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // ===== MÉTODOS AUXILIARES =====
  
  /// Verificar si un evento está activo
  bool _isEventActive(Evento evento) {
    return evento.isActive;
  }
  
  /// Verificar si un evento está cancelado
  bool _isEventCancelled(Evento evento) {
    return evento.estado.toLowerCase() == 'cancelado';
  }
  
  /// Verificar si un evento es de hoy
  bool _isEventToday(Evento evento) {
    final now = DateTime.now();
    return evento.fecha.year == now.year &&
           evento.fecha.month == now.month &&
           evento.fecha.day == now.day;
  }
  
  /// Verificar si un evento ya terminó
  bool _hasEventEnded(Evento evento) {
    final now = DateTime.now();
    return evento.horaFinal.isBefore(now);
  }
  
  /// Obtener el color de estado del evento
  Color _getStatusColor(Evento evento) {
    if (evento.isActive) return Colors.green;
    
    final now = DateTime.now();
    
    // Evento futuro
    if (evento.fecha.isAfter(now)) return AppColors.secondaryTeal;
    
    // Evento de hoy pero no iniciado
    if (_isEventToday(evento) && evento.horaInicio.isAfter(now)) {
      return Colors.orange;
    }
    
    // Evento terminado
    if (_hasEventEnded(evento)) return Colors.grey;
    
    // Evento cancelado
    if (_isEventCancelled(evento)) return Colors.red;
    
    // Por defecto
    return AppColors.primaryOrange;
  }
  
  /// Obtener el estado textual del evento
  String _getEventStatus(Evento evento) {
    if (evento.isActive) return 'ACTIVO';
    
    final now = DateTime.now();
    
    // Evento futuro
    if (evento.fecha.isAfter(now)) return 'PRÓXIMO';
    
    // Evento de hoy pero no iniciado
    if (_isEventToday(evento) && evento.horaInicio.isAfter(now)) {
      return 'HOY';
    }
    
    // Evento terminado
    if (_hasEventEnded(evento)) return 'FINALIZADO';
    
    // Evento cancelado
    if (_isEventCancelled(evento)) return 'CANCELADO';
    
    // Por defecto
    return 'PENDIENTE';
  }
  
  /// Obtener el color de fondo del evento
  Color _getEventBackgroundColor(Evento evento) {
    if (evento.isActive) {
      return Colors.green.withValues(alpha: 0.05);
    }
    return Colors.white;
  }
  
  /// Obtener el color del borde del evento
  Color _getEventBorderColor(Evento evento) {
    if (evento.isActive) {
      return Colors.green.withValues(alpha: 0.2);
    }
    return AppColors.lightGray.withValues(alpha: 0.5);
  }
  
  /// Obtener el subtítulo del evento
  String _getEventSubtitle(Evento evento) {
    if (evento.descripcion?.isNotEmpty == true) {
      return evento.descripcion!;
    }
    return 'Evento de ${evento.tipo ?? 'asistencia'}';
  }
  
  /// Formatear la hora del evento
  String _formatEventTime(Evento evento) {
    final start = '${evento.horaInicio.hour.toString().padLeft(2, '0')}:${evento.horaInicio.minute.toString().padLeft(2, '0')}';
    final end = '${evento.horaFinal.hour.toString().padLeft(2, '0')}:${evento.horaFinal.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}