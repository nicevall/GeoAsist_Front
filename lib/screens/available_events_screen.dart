import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/screens/available_events_screen.dart - INTEGRACIÓN COMPLETA EVENTOS-ASISTENCIA
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/colors.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../services/pre_registration_notification_service.dart';
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
  final PreRegistrationNotificationService _preRegistrationService = PreRegistrationNotificationService();

  List<Evento> _eventos = [];
  Usuario? _currentUser;
  bool _isLoading = true;
  bool _isValidatingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// ✅ ENHANCED: Método mejorado con navegación avanzada y validaciones completas
  Future<void> _handleJoinEventWithValidations(Evento evento) async {
    if (_isValidatingPermissions) return;

    setState(() => _isValidatingPermissions = true);

    try {
      logger.d('🎯 Uniéndose al evento: ${evento.titulo}');
      
      // 1. Validar datos del evento
      if (evento.id == null || evento.id!.isEmpty) {
        AppRouter.showSnackBar('❌ El evento no tiene un ID válido', isError: true);
        return;
      }
      
      // 2. Validar que el estudiante pueda unirse al evento
      if (!evento.canJoin) {
        AppRouter.showSnackBar('❌ El evento está ${evento.statusText.toLowerCase()} y no permite nuevos participantes', isError: true);
        return;
      }
      
      // 3. Validar usuario actual
      if (_currentUser == null) {
        AppRouter.showSnackBar('❌ No se pudo obtener información del usuario', isError: true);
        return;
      }
      
      // 4. ✅ NUEVO: Mostrar diálogo de confirmación para pre-registro o tracking inmediato
      await _showEventJoinDialog(evento);
      
    } catch (e) {
      logger.d('❌ Error joining event: $e');
      AppRouter.showSnackBar(
        '❌ Error accediendo al evento. Verifica tus permisos de ubicación.', 
        isError: true
      );
    } finally {
      setState(() => _isValidatingPermissions = false);
    }
  }




  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // Cargar usuario actual
      _currentUser = await _storageService.getUser();
      
      logger.d('📋 Cargando eventos disponibles...');
      final eventos = await _eventoService.obtenerEventos();
      
      logger.d('✅ Eventos cargados: ${eventos.length}');
      for (var evento in eventos) {
        logger.d('📅 Evento: ${evento.titulo} - ID: ${evento.id} - Activo: ${evento.isActive}');
        logger.d('📍 Ubicación: ${evento.ubicacion.latitud}, ${evento.ubicacion.longitud}');
        logger.d('🎯 Rango: ${evento.rangoPermitido}m');
      }
      
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
      
      if (eventos.isEmpty) {
        AppRouter.showSnackBar('No hay eventos disponibles', isError: false);
      }
    } catch (e) {
      logger.d('❌ Error cargando eventos: $e');
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error al cargar eventos: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ✅ Evita salir accidentalmente
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // ✅ Al presionar atrás, volver al dashboard en lugar de salir
        _handleBackToMain(context);
      },
      child: Scaffold(
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
      ),
    );
  }

  /// ✅ Maneja el botón de atrás para volver al dashboard principal
  void _handleBackToMain(BuildContext context) {
    // Volver al dashboard principal en lugar de salir de la app
    AppRouter.goToDashboard(userName: _currentUser?.nombre ?? 'Usuario');
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
                    color: evento.statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    evento.statusText,
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
            
            // ✅ BOTÓN JOIN EVENT INTELIGENTE
            if (_currentUser?.rol == AppConstants.estudianteRole) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: evento.canJoin 
                      ? () => _handleJoinEventWithValidations(evento)
                      : null,
                  icon: Icon(
                    evento.canJoin ? Icons.location_on : Icons.lock,
                  ),
                  label: Text(
                    evento.canJoin 
                        ? 'UNIRSE AL EVENTO' 
                        : 'EVENTO ${evento.statusText}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: evento.canJoin 
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
            'Los eventos aparecerán aquí cuando los profesors los creen',
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

  /// ✅ NUEVO: Diálogo inteligente para múltiples eventos en la misma ubicación
  Future<void> _showEventJoinDialog(Evento evento) async {
    // 1. Buscar otros eventos en la misma ubicación
    final eventosEnMismaUbicacion = _eventos.where((e) => 
      e.id != evento.id && _areEventsAtSameLocation(e, evento)
    ).toList();

    logger.d('🎯 Eventos en misma ubicación: ${eventosEnMismaUbicacion.length}');

    // 2. Si hay múltiples eventos en la misma ubicación, mostrar selector
    if (eventosEnMismaUbicacion.isNotEmpty) {
      await _showMultipleEventsDialog(evento, eventosEnMismaUbicacion);
    } else {
      // 3. Solo un evento, proceder normalmente
      await _showSingleEventDialog(evento);
    }
  }

  /// ✅ Diálogo para múltiples eventos en la misma ubicación
  Future<void> _showMultipleEventsDialog(Evento eventoSeleccionado, List<Evento> otrosEventos) async {
    final todosLosEventos = [eventoSeleccionado, ...otrosEventos];
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('📍 Múltiples Eventos en esta Ubicación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hay varios eventos en la misma ubicación. Selecciona el evento específico al que quieres asistir:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...todosLosEventos.map((evento) => _buildEventSelector(evento)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Widget selector para cada evento
  Widget _buildEventSelector(Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          evento.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${evento.lugar ?? 'Sin ubicación específica'}'),
            Text('⏰ ${_formatTime(evento.horaInicio)} - ${_formatTime(evento.horaFinal)}'),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: evento.statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                evento.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: evento.canJoin 
          ? const Icon(Icons.location_on, color: Colors.green)
          : const Icon(Icons.lock, color: Colors.grey),
        onTap: evento.canJoin 
          ? () {
              Navigator.of(context).pop();
              _showSingleEventDialog(evento);
            }
          : null,
      ),
    );
  }

  /// ✅ Diálogo para un solo evento (pre-registro SIEMPRE disponible + tracking inmediato si activo)
  Future<void> _showSingleEventDialog(Evento evento) async {
    final now = DateTime.now();
    final eventStart = evento.fecha.copyWith(
      hour: evento.horaInicio.hour,
      minute: evento.horaInicio.minute,
    );
    
    final esEventoActivo = now.isAfter(eventStart) && now.isBefore(evento.fecha.copyWith(
      hour: evento.horaFinal.hour,
      minute: evento.horaFinal.minute,
    ));

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🎯 ${evento.titulo}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍 Ubicación: ${evento.lugar ?? 'Sin ubicación'}'),
              Text('📅 Fecha: ${_formatEventDate(evento.fecha)}'),
              Text('⏰ Hora: ${_formatTime(evento.horaInicio)} - ${_formatTime(evento.horaFinal)}'),
              const SizedBox(height: 16),
              
              if (esEventoActivo) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('✅ El evento está ACTIVO ahora')),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('⏳ El evento aún no ha comenzado')),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // ✅ NUEVO: Información sobre pre-registro SIEMPRE disponible
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Inscripción al evento:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• No necesitas estar en la ubicación ahora\n'
                      '• Recibirás notificación 5 min antes\n'
                      '• Acceso directo al attendance view',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            
            // ✅ NUEVO: Pre-registro SIEMPRE disponible
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _preRegisterToEvent(evento);
              },
              icon: const Icon(Icons.app_registration),
              label: Text(esEventoActivo ? 'INSCRIBIRME AL EVENTO' : 'INSCRIBIRME AL EVENTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            // ✅ Tracking inmediato solo si está activo
            if (esEventoActivo) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _joinEventImmediately(evento);
                },
                icon: const Icon(Icons.location_on),
                label: const Text('UNIRSE AHORA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// ✅ Verifica si dos eventos están en la misma ubicación (radio de 50m)
  bool _areEventsAtSameLocation(Evento evento1, Evento evento2) {
    const double toleranciaMetros = 50.0; // 50 metros de tolerancia
    
    final lat1 = evento1.ubicacion.latitud;
    final lng1 = evento1.ubicacion.longitud;
    final lat2 = evento2.ubicacion.latitud;
    final lng2 = evento2.ubicacion.longitud;
    
    // Fórmula de distancia simple para distancias cortas
    final deltaLat = (lat1 - lat2) * 111000; // 1 grado ≈ 111km
    final deltaLng = (lng1 - lng2) * 111000 * cos(lat1 * pi / 180);
    final distancia = sqrt(deltaLat * deltaLat + deltaLng * deltaLng);
    
    logger.d('📏 Distancia entre ${evento1.titulo} y ${evento2.titulo}: ${distancia.toStringAsFixed(1)}m');
    
    return distancia <= toleranciaMetros;
  }

  /// ✅ Pre-registra al estudiante para el evento (con notificaciones automáticas)
  Future<void> _preRegisterToEvent(Evento evento) async {
    try {
      logger.d('📝 Pre-registrando para evento: ${evento.titulo}');
      
      if (_currentUser == null) {
        AppRouter.showSnackBar('❌ Error: Usuario no encontrado', isError: true);
        return;
      }

      // ✅ NUEVO: Usar el servicio de pre-registro con notificaciones
      await _preRegistrationService.addPreRegistration(evento, _currentUser!);
      
      // También mantener compatibilidad con el sistema anterior
      final preRegistros = await _storageService.getPreRegisteredEvents() ?? <String>[];
      if (!preRegistros.contains(evento.id)) {
        preRegistros.add(evento.id!);
        await _storageService.savePreRegisteredEvents(preRegistros);
      }
      
      AppRouter.showSnackBar(
        '✅ Inscripción exitosa para "${evento.titulo}"\n'
        '🔔 Recibirás una notificación 5 minutos antes de que comience.\n'
        '🎯 Al tocar la notificación, irás directo al attendance view.',
        isError: false,
      );
      
    } catch (e) {
      logger.d('❌ Error en inscripción: $e');
      AppRouter.showSnackBar('❌ Error al inscribirse: $e', isError: true);
    }
  }

  /// ✅ Une al estudiante inmediatamente al evento activo
  Future<void> _joinEventImmediately(Evento evento) async {
    try {
      logger.d('🎯 Uniéndose inmediatamente al evento: ${evento.titulo}');
      
      // Navegar al tracking del evento
      AppRouter.goToAttendanceTracking(
        eventoId: evento.id!,
      );
      
    } catch (e) {
      logger.d('❌ Error joining immediately: $e');
      AppRouter.showSnackBar('❌ Error accediendo al evento', isError: true);
    }
  }

}
