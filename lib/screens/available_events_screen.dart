// lib/screens/available_events_screen.dart - INTEGRACIÓN COMPLETA EVENTOS-ASISTENCIA
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../utils/app_router.dart';
import '../core/app_constants.dart';

class AvailableEventsScreen extends StatefulWidget {
  const AvailableEventsScreen({super.key});

  @override
  State<AvailableEventsScreen> createState() => _AvailableEventsScreenState();
}

class _AvailableEventsScreenState extends State<AvailableEventsScreen> {
  final EventoService _eventoService = EventoService();
  final StorageService _storageService = StorageService();
  final PermissionService _permissionService = PermissionService();

  List<Evento> _eventos = [];
  Usuario? _currentUser;
  bool _isLoading = true;
  bool _isValidatingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// ✅ NUEVO: Método que realmente funciona para unirse al evento
  Future<void> _handleJoinEventWithValidations(Evento evento) async {
    if (_isValidatingPermissions) return;

    setState(() => _isValidatingPermissions = true);

    try {
      debugPrint('🎯 Uniéndose al evento: ${evento.titulo}');
      
      // 1. Validar que el evento esté activo
      if (!evento.isActive) {
        AppRouter.showSnackBar('❌ El evento no está activo', isError: true);
        return;
      }
      
      // 2. Validar permisos de ubicación
      final hasPermissions = await _permissionService.validateAllPermissionsForTracking();
      
      if (!hasPermissions) {
        AppRouter.showSnackBar('❌ Se requieren permisos de ubicación', isError: true);
        return;
      }
      
      // 3. Navegar a pantalla de tracking con evento específico
      AppRouter.goToAttendanceTracking(
        userName: _currentUser?.nombre ?? 'Usuario',
        eventoId: evento.id,
      );
      
      debugPrint('✅ Navegando a tracking para evento: ${evento.id}');
      
    } catch (e) {
      debugPrint('❌ Error joining event: $e');
      AppRouter.showSnackBar('❌ Error uniéndose al evento: $e', isError: true);
    } finally {
      setState(() => _isValidatingPermissions = false);
    }
  }




  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // Cargar usuario actual
      _currentUser = await _storageService.getUser();
      
      debugPrint('📋 Cargando eventos disponibles...');
      final eventos = await _eventoService.obtenerEventos();
      
      debugPrint('✅ Eventos cargados: ${eventos.length}');
      for (var evento in eventos) {
        debugPrint('📅 Evento: ${evento.titulo} - ID: ${evento.id} - Activo: ${evento.isActive}');
        debugPrint('📍 Ubicación: ${evento.ubicacion.latitud}, ${evento.ubicacion.longitud}');
        debugPrint('🎯 Rango: ${evento.rangoPermitido}m');
      }
      
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
      
      if (eventos.isEmpty) {
        AppRouter.showSnackBar('No hay eventos disponibles', isError: false);
      }
    } catch (e) {
      debugPrint('❌ Error cargando eventos: $e');
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error al cargar eventos: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Eventos Disponibles'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _isLoading
            ? _buildLoadingState()
            : _eventos.isEmpty
                ? _buildEmptyState()
                : _buildEventsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando eventos...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventos.length,
      itemBuilder: (context, index) {
        final evento = _eventos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              _buildEventCard(evento),
              // Overlay de loading durante validaciones
              if (_isValidatingPermissions)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryOrange),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Validando permisos...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  /// ✅ NUEVO: Event card personalizada con botón Join Event funcional
  Widget _buildEventCard(Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
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
            
            const SizedBox(height: 8),
            
            // Información del evento
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    evento.lugar ?? 'Sin ubicación',
                    style: const TextStyle(fontSize: 14, color: AppColors.textGray),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  _formatEventDate(evento.fecha),
                  style: const TextStyle(fontSize: 14, color: AppColors.textGray),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(evento.horaInicio)} - ${_formatTime(evento.horaFinal)}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textGray),
                ),
              ],
            ),
            
            if (evento.descripcion != null && evento.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                evento.descripcion!,
                style: const TextStyle(fontSize: 14, color: AppColors.darkGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // ✅ BOTÓN JOIN EVENT FUNCIONAL
            if (_currentUser?.rol == AppConstants.estudianteRole) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleJoinEventWithValidations(evento),
                  icon: const Icon(Icons.location_on),
                  label: const Text('UNIRSE AL EVENTO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: evento.isActive 
                        ? AppColors.primaryOrange 
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Hoy';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Mañana';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los eventos aparecerán aquí cuando los docentes los creen',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }







}
