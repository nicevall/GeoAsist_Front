// lib/screens/admin/system_events_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/evento_model.dart';
import '../../services/evento_service.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';

/// Pantalla específica para que los administradores gestionen todos los eventos del sistema
class SystemEventsManagementScreen extends StatefulWidget {
  const SystemEventsManagementScreen({super.key});

  @override
  State<SystemEventsManagementScreen> createState() => _SystemEventsManagementScreenState();
}

class _SystemEventsManagementScreenState extends State<SystemEventsManagementScreen> {
  final EventoService _eventoService = EventoService();
  List<Evento> _eventos = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _showOnlyActiveEvents = false;

  @override
  void initState() {
    super.initState();
    _loadSystemEvents();
  }

  /// Cargar todos los eventos del sistema
  Future<void> _loadSystemEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventos = await _eventoService.obtenerEventos();
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  /// Filtrar eventos según búsqueda y estado
  List<Evento> get _filteredEvents {
    List<Evento> filtered = _eventos;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((evento) =>
          evento.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          evento.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          (evento.creadoPor?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
    }

    // Filtrar por estado si está activo el toggle
    if (_showOnlyActiveEvents) {
      final now = DateTime.now();
      filtered = filtered.where((evento) {
        return evento.isActive || 
               (evento.fecha.isAfter(now) && evento.estado.toLowerCase() != 'cancelado');
      }).toList();
    }

    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

    return filtered;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray.withValues(alpha: 0.1),
      appBar: AppBar(
        title: const Text(
          'Gestión de Eventos del Sistema',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryOrange,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _loadSystemEvents,
            icon: const Icon(Icons.refresh, color: AppColors.white),
            tooltip: 'Actualizar eventos',
          ),
          IconButton(
            onPressed: () => AppRouter.goToCreateEvent(),
            icon: const Icon(Icons.add, color: AppColors.white),
            tooltip: 'Crear nuevo evento',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          _buildHeader(),
          
          // Controles de búsqueda y filtros
          _buildSearchAndFilters(),
          
          // Lista de eventos
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRouter.goToCreateEvent(),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  /// Header con estadísticas del sistema
  Widget _buildHeader() {
    final totalEvents = _eventos.length;
    final activeEvents = _eventos.where((e) => e.isActive).length;
    final todayEvents = _eventos.where((e) => 
        e.fecha.day == DateTime.now().day &&
        e.fecha.month == DateTime.now().month &&
        e.fecha.year == DateTime.now().year).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', '$totalEvents', Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Activos', '$activeEvents', Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Hoy', '$todayEvents', AppColors.primaryOrange),
          ),
        ],
      ),
    );
  }

  /// Card individual de estadística
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }

  /// Controles de búsqueda y filtros
  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por título, descripción o creador...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryOrange),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Toggle para mostrar solo eventos activos
          Row(
            children: [
              Switch(
                value: _showOnlyActiveEvents,
                onChanged: (value) {
                  setState(() {
                    _showOnlyActiveEvents = value;
                  });
                },
                activeColor: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text(
                'Mostrar solo eventos activos/próximos',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredEvents.length} evento(s) encontrado(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Lista de eventos con manejo de estados
  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryOrange),
            SizedBox(height: 16),
            Text(
              'Cargando eventos del sistema...',
              style: TextStyle(color: AppColors.textGray),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSystemEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final filteredEvents = _filteredEvents;

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _showOnlyActiveEvents
                  ? Icons.search_off
                  : Icons.event_available,
              size: 64,
              color: AppColors.textGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _showOnlyActiveEvents
                  ? 'No se encontraron eventos'
                  : 'No hay eventos en el sistema',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Los eventos creados aparecerán aquí',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (_eventos.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AppRouter.goToCreateEvent(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Crear primer evento'),
              ),
            ],
          ],
        ),
      );
    }

    // Lista personalizada de eventos con botones de acción
    return RefreshIndicator(
      onRefresh: _loadSystemEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final evento = filteredEvents[index];
          return _buildEventManagementCard(evento);
        },
      ),
    );
  }

  /// Card de gestión para cada evento
  Widget _buildEventManagementCard(Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del evento
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        evento.creadoPor ?? 'Desconocido',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
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
                    evento.isActive ? 'ACTIVO' : 'INACTIVO',
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
            
            // Información del evento
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray),
                const SizedBox(width: 8),
                Text(
                  _formatDate(evento.fecha),
                  style: const TextStyle(fontSize: 14, color: AppColors.textGray),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: AppColors.textGray),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(evento.horaInicio)} - ${_formatTime(evento.horaFinal)}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textGray),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => AppRouter.goToCreateEvent(editEvent: evento),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteEvent(evento),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _goToEventMonitor(evento),
                    icon: const Icon(Icons.monitor, size: 16),
                    label: const Text('Monitor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Eliminar evento del sistema
  Future<void> _deleteEvent(Evento evento) async {
    final confirmed = await AppRouter.showConfirmDialog(
      title: 'Eliminar Evento',
      content: '¿Estás seguro de eliminar "${evento.titulo}"?\n\n'
               'Esta acción eliminará el evento y toda su información de asistencia.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
    );

    if (confirmed == true) {
      try {
        final result = await _eventoService.eliminarEvento(evento.id!);
        if (result.success) {
          AppRouter.showSnackBar('Evento "${evento.titulo}" eliminado exitosamente');
          await _loadSystemEvents(); // Recargar lista
        } else {
          AppRouter.showSnackBar('Error: ${result.message}', isError: true);
        }
      } catch (e) {
        AppRouter.showSnackBar('Error eliminando evento: $e', isError: true);
      }
    }
  }

  /// Ir al monitor del evento
  void _goToEventMonitor(Evento evento) {
    AppRouter.goToEventMonitor(
      eventId: evento.id!,
      teacherName: evento.creadoPor ?? 'Admin',
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Formatear hora
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}