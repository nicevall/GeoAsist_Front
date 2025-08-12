// lib/screens/available_events_screen.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';
import '../utils/app_router.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/event_attendance_card.dart';
import '../widgets/detailed_stats_widget.dart'; // ✅ AGREGADO PARA FASE B

class AvailableEventsScreen extends StatefulWidget {
  const AvailableEventsScreen({super.key});

  @override
  State<AvailableEventsScreen> createState() => _AvailableEventsScreenState();
}

class _AvailableEventsScreenState extends State<AvailableEventsScreen> {
  final EventoService _eventoService = EventoService();
  List<Evento> _eventos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final eventos = await _eventoService.obtenerEventos();
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error al cargar eventos', isError: true);
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
        child: _buildBody(),
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO SEGÚN FASE B.3
  Widget _buildBody() {
    if (_isLoading) {
      return SkeletonLoaders.eventsList(count: 3);
    }

    if (_eventos.isEmpty) {
      return _buildEmptyState();
    }

    // ✅ CAMBIO: SingleChildScrollView + Column en lugar de ListView.builder directo
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Lista de eventos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eventos.length,
            itemBuilder: (context, index) => _buildEventCard(_eventos[index]),
          ),

          // ✅ AGREGADO: Estadísticas detalladas para estudiantes (FASE B.3)
          if (_eventos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const DetailedStatsWidget(isDocente: false),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(Evento evento) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EventAttendanceCard(
        evento: evento,
        onGoToLocation: () => _goToEventLocation(evento),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
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
      ),
    );
  }

  void _goToEventLocation(Evento evento) {
    // Navegar al mapa con el evento específico Y modo estudiante
    Navigator.pushNamed(
      context,
      '/map-view',
      arguments: {
        'isAdminMode': false,
        'userName': 'Estudiante',
        'eventoId': evento.id,
        'isStudentMode': true, // ✅ CRÍTICO: Activar modo estudiante
      },
    );
  }
}
