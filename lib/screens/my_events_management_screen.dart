import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/screens/my_events_management_screen.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../widgets/loading_skeleton.dart';
import '../core/app_constants.dart';

class MyEventsManagementScreen extends StatefulWidget {
  const MyEventsManagementScreen({super.key});

  @override
  State<MyEventsManagementScreen> createState() => _MyEventsManagementScreenState();
}

class _MyEventsManagementScreenState extends State<MyEventsManagementScreen> {
  final EventoService _eventoService = EventoService();
  final StorageService _storageService = StorageService();
  
  List<Evento> _userEvents = [];
  Usuario? _currentUser;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'todos'; // todos, activos, inactivos, programados

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar usuario actual
      _currentUser = await _storageService.getUser();
      
      if (_currentUser?.rol == AppConstants.profesorRole) {
        // ✅ PROFESOR: Solo sus eventos
        logger.d('📚 Cargando eventos del profesor: ${_currentUser!.id}');
        final eventos = await _eventoService.getEventosByCreador(_currentUser!.id);
        setState(() {
          _userEvents = eventos;
          _isLoading = false;
        });
        logger.d('✅ Profesor: Cargados ${eventos.length} eventos');
        
      } else if (_currentUser?.rol == AppConstants.adminRole) {
        // ✅ ADMIN: Todos los eventos
        logger.d('👑 Cargando todos los eventos (admin)');
        final eventos = await _eventoService.obtenerEventos();
        setState(() {
          _userEvents = eventos;
          _isLoading = false;
        });
        logger.d('✅ Admin: Cargados ${eventos.length} eventos');
        
      } else {
        throw Exception('Rol no autorizado para gestión de eventos');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error cargando eventos: $e', isError: true);
    }
  }

  List<Evento> get _filteredEvents {
    List<Evento> filtered = _userEvents;
    
    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((evento) =>
        evento.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (evento.lugar?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Filtro por estado
    switch (_filterStatus) {
      case 'activos':
        filtered = filtered.where((e) => e.isActive).toList();
        break;
      case 'inactivos':
        filtered = filtered.where((e) => !e.isActive && e.fecha.isBefore(DateTime.now())).toList();
        break;
      case 'programados':
        filtered = filtered.where((e) => !e.isActive && e.fecha.isAfter(DateTime.now())).toList();
        break;
    }
    
    // Ordenar por fecha (más recientes primero)
    filtered.sort((a, b) => b.fecha.compareTo(a.fecha));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Eventos',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0.5,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: _buildSearchAndFilter(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar eventos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.lightGray.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos'),
                _buildFilterChip('Activos', 'activos'),
                _buildFilterChip('Programados', 'programados'),
                _buildFilterChip('Finalizados', 'inactivos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterStatus = value),
        selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primaryOrange,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryOrange : AppColors.textGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          LoadingSkeleton(height: 120, width: double.infinity),
          SizedBox(height: 16),
          LoadingSkeleton(height: 120, width: double.infinity),
          SizedBox(height: 16),
          LoadingSkeleton(height: 120, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final filteredEvents = _filteredEvents;
    
    if (filteredEvents.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estadísticas rápidas
          _buildQuickStats(),
          
          const SizedBox(height: 20),
          
          // Lista de eventos
          ...filteredEvents.map((evento) => _buildEventCard(evento)),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalEvents = _userEvents.length;
    final activeEvents = _userEvents.where((e) => e.isActive).length;
    final upcomingEvents = _userEvents.where((e) => 
      e.fecha.isAfter(DateTime.now()) && !e.isActive
    ).length;
    
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
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Total', totalEvents.toString(), AppColors.primaryOrange)),
              Expanded(child: _buildStatItem('Activos', activeEvents.toString(), Colors.green)),
              Expanded(child: _buildStatItem('Próximos', upcomingEvents.toString(), AppColors.secondaryTeal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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
        ),
      ],
    );
  }

  Widget _buildEventCard(Evento evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Header del evento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: evento.isActive 
                  ? Colors.green.withValues(alpha: 0.1)
                  : AppColors.lightGray.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              evento.lugar ?? 'Sin ubicación',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: evento.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
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
          ),
          
          // Contenido del evento
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Información del evento
                Row(
                  children: [
                    Expanded(
                      child: _buildEventInfo(
                        Icons.calendar_today,
                        _formatEventDate(evento),
                      ),
                    ),
                    Expanded(
                      child: _buildEventInfo(
                        Icons.access_time,
                        '${_formatTime(evento.horaInicio)} - ${_formatTime(evento.horaFinal)}',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // ✅ BOTONES DE ACCIÓN CON MONITOREO
                Row(
                  children: [
                    // Editar evento
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: 'Editar',
                        color: AppColors.secondaryTeal,
                        onPressed: () => _navigateToEditEvent(evento),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // ✅ MONITOREO EN TIEMPO REAL
                    if (evento.isActive) ...[
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.monitor,
                          label: 'Monitor',
                          color: AppColors.primaryOrange,
                          onPressed: () => _startEventMonitoring(evento),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                    ],
                    
                    // Eliminar evento
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: 'Eliminar',
                        color: Colors.red,
                        onPressed: () => _confirmDeleteEvent(evento),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textGray),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(0, 44),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay eventos que mostrar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No se encontraron eventos con "$_searchQuery"'
                : 'Aún no has creado eventos',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => AppRouter.goToCreateEvent(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Primer Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => AppRouter.goToCreateEvent(),
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo Evento'),
    );
  }

  // Métodos de navegación y acciones
  void _navigateToEditEvent(Evento evento) {
    AppRouter.goToCreateEvent(editEvent: evento);
  }

  /// ✅ MÉTODO DE MONITOREO FUNCIONAL
  Future<void> _startEventMonitoring(Evento evento) async {
    try {
      logger.d('📊 Iniciando monitoreo del evento: ${evento.titulo}');
      
      AppRouter.goToEventMonitor(
        eventId: evento.id!,
        teacherName: _currentUser?.nombre ?? 'Profesor',
      );
      
    } catch (e) {
      logger.d('❌ Error iniciando monitoreo: $e');
      AppRouter.showSnackBar('❌ Error iniciando monitoreo: $e', isError: true);
    }
  }

  Future<void> _confirmDeleteEvent(Evento evento) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Evento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres eliminar este evento?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evento: ${evento.titulo}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Fecha: ${_formatEventDate(evento)}'),
                  Text('Lugar: ${evento.lugar ?? "Sin ubicación"}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Esta acción no se puede deshacer. Se eliminarán todas las asistencias registradas.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteEvent(evento);
    }
  }

  Future<void> _deleteEvent(Evento evento) async {
    try {
      AppRouter.showSnackBar('Eliminando evento...');
      
      final result = await _eventoService.eliminarEvento(evento.id!);
      if (result.success) {
        AppRouter.showSnackBar('✅ Evento eliminado exitosamente');
        await _loadData(); // Recargar datos
      } else {
        AppRouter.showSnackBar('❌ Error: ${result.error}', isError: true);
      }
    } catch (e) {
      AppRouter.showSnackBar('❌ Error de conexión: $e', isError: true);
    }
  }

  // Métodos de formateo
  String _formatEventDate(Evento evento) {
    final now = DateTime.now();
    final eventDate = evento.fecha;
    
    if (eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day) {
      return 'Hoy';
    }
    
    final tomorrow = now.add(const Duration(days: 1));
    if (eventDate.year == tomorrow.year &&
        eventDate.month == tomorrow.month &&
        eventDate.day == tomorrow.day) {
      return 'Mañana';
    }
    
    return '${eventDate.day}/${eventDate.month}/${eventDate.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}