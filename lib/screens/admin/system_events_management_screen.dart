// lib/screens/admin/system_events_management_screen.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';
import '../../services/evento_service.dart';
import '../../services/storage_service.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import '../../widgets/loading_skeleton.dart';
import '../../core/app_constants.dart';

/// ✅ PANTALLA MEJORADA: Gestión de eventos del sistema (Admin) basada en la pantalla del profesor
/// Características:
/// - Diseño limpio y profesional igual al del profesor
/// - Muestra TODOS los eventos del sistema
/// - Incluye información de "Creado por" para cada evento
/// - Filtros y búsqueda avanzada
/// - Estadísticas del sistema completas
class SystemEventsManagementScreen extends StatefulWidget {
  const SystemEventsManagementScreen({super.key});

  @override
  State<SystemEventsManagementScreen> createState() => _SystemEventsManagementScreenState();
}

class _SystemEventsManagementScreenState extends State<SystemEventsManagementScreen> {
  final EventoService _eventoService = EventoService();
  final StorageService _storageService = StorageService();
  
  List<Evento> _allSystemEvents = [];
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
      // Cargar usuario actual para verificar permisos
      _currentUser = await _storageService.getUser();
      
      if (_currentUser?.rol != AppConstants.adminRole) {
        throw Exception('Solo los administradores pueden acceder a esta pantalla');
      }
      
      // ✅ ADMIN: Cargar TODOS los eventos del sistema
      debugPrint('👑 Cargando todos los eventos del sistema...');
      final eventos = await _eventoService.obtenerEventos();
      setState(() {
        _allSystemEvents = eventos;
        _isLoading = false;
      });
      debugPrint('✅ Admin: Cargados ${eventos.length} eventos del sistema');
      
    } catch (e) {
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error cargando eventos: $e', isError: true);
    }
  }

  List<Evento> get _filteredEvents {
    List<Evento> filtered = _allSystemEvents;
    
    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((evento) =>
        evento.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (evento.lugar?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (evento.creadoPor?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
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
        'Gestión del Sistema',
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
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar eventos',
        ),
      ],
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
              hintText: 'Buscar eventos o creadores...',
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
          // Estadísticas del sistema
          _buildSystemStats(),
          
          const SizedBox(height: 20),
          
          // Lista de eventos
          ...filteredEvents.map((evento) => _buildEventCard(evento)),
        ],
      ),
    );
  }

  Widget _buildSystemStats() {
    final totalEvents = _allSystemEvents.length;
    final activeEvents = _allSystemEvents.where((e) => e.isActive).length;
    final upcomingEvents = _allSystemEvents.where((e) => 
      e.fecha.isAfter(DateTime.now()) && !e.isActive
    ).length;
    
    // ✅ ESTADÍSTICA ADICIONAL PARA ADMIN: Eventos creados hoy
    final todayEvents = _allSystemEvents.where((e) => 
      e.createdAt != null &&
      e.createdAt!.day == DateTime.now().day &&
      e.createdAt!.month == DateTime.now().month &&
      e.createdAt!.year == DateTime.now().year
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
            'Estadísticas del Sistema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primera fila de estadísticas
          Row(
            children: [
              Expanded(child: _buildStatItem('Total', totalEvents.toString(), AppColors.primaryOrange)),
              Expanded(child: _buildStatItem('Activos', activeEvents.toString(), Colors.green)),
              Expanded(child: _buildStatItem('Próximos', upcomingEvents.toString(), AppColors.secondaryTeal)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Segunda fila - estadística específica de admin
          Row(
            children: [
              Expanded(child: _buildStatItem('Hoy', todayEvents.toString(), Colors.purple)),
              Expanded(child: Container()), // Espacio vacío
              Expanded(child: Container()), // Espacio vacío
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
                      
                      // ✅ INFORMACIÓN ESPECÍFICA PARA ADMIN: Creado por
                      if (evento.creadoPor != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: AppColors.primaryOrange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Creado por: ${evento.creadoPor}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Estado del evento
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: evento.isActive ? Colors.green : AppColors.textGray,
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
          
          // Cuerpo del evento
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Información del evento
                Row(
                  children: [
                    Expanded(
                      child: _buildEventInfo('Fecha', _formatDate(evento.fecha)),
                    ),
                    Expanded(
                      child: _buildEventInfo('Hora', evento.horaInicioFormatted),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (evento.descripcion?.isNotEmpty == true) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      evento.descripcion!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGray,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewEventDetails(evento),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Ver Detalles'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          side: BorderSide(color: AppColors.primaryOrange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _manageEvent(evento),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Gestionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildEventInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: AppColors.textGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay eventos en el sistema',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Los eventos creados por profesores aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => AppRouter.goToCreateEvent(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Primer Evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => AppRouter.goToCreateEvent(),
      backgroundColor: AppColors.primaryOrange,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _viewEventDetails(Evento evento) {
    // TODO: Navegar a pantalla de detalles
    AppRouter.showSnackBar('Ver detalles de: ${evento.titulo}');
  }

  void _manageEvent(Evento evento) {
    // Navegar a pantalla de gestión específica del evento
    Navigator.pushNamed(
      context,
      AppConstants.eventMonitorRoute,
      arguments: {
        'eventId': evento.id!,
        'teacherName': 'Admin',
      },
    );
  }
}