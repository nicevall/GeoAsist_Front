import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';
import '../utils/app_router.dart';
import '../widgets/loading_skeleton.dart';

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
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SkeletonLoaders.eventsList(count: 3);
    }

    if (_eventos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventos.length,
      itemBuilder: (context, index) => _buildEventCard(_eventos[index]),
    );
  }

  Widget _buildEventCard(Evento evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: evento.isActive
                        ? Colors.green
                        : AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (evento.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (evento.descripcion?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                evento.descripcion!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  _formatDate(evento.fecha),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRange(evento.horaInicio, evento.horaFinal),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  'UIDE Campus Principal',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const SizedBox(width: 16),
                Icon(Icons.radio_button_checked,
                    size: 16, color: AppColors.textGray),
                const SizedBox(width: 4),
                Text(
                  'Rango: ${evento.rangoPermitido.toInt()}m',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToEventLocation(evento),
                icon: const Icon(Icons.location_on, size: 20),
                label: const Text('Ir a Ubicación del Evento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          ElevatedButton(
            onPressed: _loadEvents,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _goToEventLocation(Evento evento) {
    // Navegar al mapa con el evento específico
    Navigator.pushNamed(
      context,
      '/map-view',
      arguments: {
        'isAdminMode': false,
        'userName': 'Estudiante',
        'eventoId': evento.id,
        'isStudentMode': true,
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
