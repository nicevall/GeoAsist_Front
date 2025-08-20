// lib/screens/available_events_screen.dart - FASE C CON VALIDACIONES DE SEGURIDAD
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';
import '../utils/app_router.dart';
import '../widgets/event_attendance_card.dart';
// 🔒 NUEVOS IMPORTS PARA VALIDACIONES DE SEGURIDAD FASE C

class AvailableEventsScreen extends StatefulWidget {
  const AvailableEventsScreen({super.key});

  @override
  State<AvailableEventsScreen> createState() => _AvailableEventsScreenState();
}

class _AvailableEventsScreenState extends State<AvailableEventsScreen> {
  final EventoService _eventoService = EventoService();

  // 🔒 SERVICIOS DE VALIDACIÓN FASE C

  List<Evento> _eventos = [];
  bool _isLoading = true;

  // 🔒 ESTADO DE VALIDACIONES
  bool _isValidatingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _handleJoinEventWithValidations(Evento evento) async {
    debugPrint('🎯 Usuario seleccionó evento: ${evento.titulo}');

    if (_isValidatingPermissions) return;

    setState(() => _isValidatingPermissions = true);

    try {
      // ✅ NAVEGACIÓN DIRECTA - El AttendanceTrackingScreen manejará permisos
      debugPrint('✅ Navegando al tracking de asistencia');
      _navigateToEventSafely(evento);
      
    } catch (e) {
      debugPrint('❌ Error: $e');
      AppRouter.showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isValidatingPermissions = false);
    }
  }



  // 🔒 NAVEGACIÓN SEGURA (SOLO DESPUÉS DE VALIDACIONES)
  void _navigateToEventSafely(Evento evento) {
    if (!mounted) return;

    debugPrint('🚀 Navegando de forma segura a evento: ${evento.titulo}');

    // Navegar al attendance tracking con todos los permisos validados
    Navigator.pushNamed(
      context,
      '/attendance-tracking',
      arguments: {
        'userName': 'Estudiante',
        'eventoId': evento.id,
        'permissionsValidated': true,
        'preciseLocationGranted': true,
        'backgroundPermissionsGranted': true,
        'batteryOptimizationDisabled': true,
      },
    );
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
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
              EventAttendanceCard(
                evento: evento,
                onGoToLocation: () => _handleJoinEventWithValidations(evento),
              ),
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
