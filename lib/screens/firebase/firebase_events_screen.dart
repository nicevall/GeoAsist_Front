// lib/screens/firebase/firebase_events_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase/firebase_evento_service.dart';
import '../../services/firebase/firebase_auth_service.dart';
import '../../models/evento_model.dart';
import '../../utils/colors.dart';

class FirebaseEventsScreen extends StatefulWidget {
  const FirebaseEventsScreen({super.key});

  @override
  State<FirebaseEventsScreen> createState() => _FirebaseEventsScreenState();
}

class _FirebaseEventsScreenState extends State<FirebaseEventsScreen> {
  late FirebaseEventoService _eventoService;
  late FirebaseAuthService _authService;
  
  String _searchQuery = '';
  bool _showActiveOnly = false;
  
  @override
  void initState() {
    super.initState();
    _eventoService = context.read<FirebaseEventoService>();
    _authService = context.read<FirebaseAuthService>();
    
    // Inicializar streams de tiempo real
    _eventoService.initializeStreams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Firebase'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _eventoService.refreshEventos,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildEventsList()),
        ],
      ),
      floatingActionButton: _buildCreateEventFAB(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar eventos...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Solo Activos'),
            selected: _showActiveOnly,
            onSelected: (selected) {
              setState(() {
                _showActiveOnly = selected;
              });
            },
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('${_eventoService.cachedEventos.length} eventos'),
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventoService.eventosStream,
      initialData: _eventoService.cachedEventos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && 
            _eventoService.cachedEventos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        final eventos = snapshot.data ?? [];
        final filteredEventos = _filterEventos(eventos);

        if (filteredEventos.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: _eventoService.refreshEventos,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredEventos.length,
            itemBuilder: (context, index) {
              final eventoMap = filteredEventos[index];
              try {
                final evento = Evento.fromJson(eventoMap);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFirebaseEventCard(evento),
                );
              } catch (e) {
                // Fallback para datos mal formateados
                return Card(
                  child: ListTile(
                    title: Text(eventoMap['titulo']?.toString() ?? 'Evento sin título'),
                    subtitle: Text('Error: $e'),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFirebaseEventCard(Evento evento) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToEventDetails(evento),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evento.titulo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(evento),
                ],
              ),
              const SizedBox(height: 8),
              if (evento.lugar != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(evento.lugar!, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${evento.horaInicioFormatted} - ${evento.horaFinalFormatted}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (evento.descripcion?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  evento.descripcion!,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              _buildEventActions(evento),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Evento evento) {
    Color color;
    String label;
    IconData icon;

    if (evento.isActive) {
      color = Colors.green;
      label = 'ACTIVO';
      icon = Icons.circle;
    } else {
      color = Colors.grey;
      label = 'PROGRAMADO';
      icon = Icons.schedule;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildEventActions(Evento evento) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (evento.isActive)
          TextButton.icon(
            onPressed: () => _joinEvent(evento),
            icon: const Icon(Icons.login),
            label: const Text('Unirse'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        TextButton.icon(
          onPressed: () => _viewEventDetails(evento),
          icon: const Icon(Icons.info_outline),
          label: const Text('Detalles'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
          ),
        ),
        if (_canEditEvent(evento))
          TextButton.icon(
            onPressed: () => _editEvent(evento),
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron eventos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Intenta con otros términos de búsqueda'
                  : 'No hay eventos disponibles en este momento',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error cargando eventos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _eventoService.refreshEventos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCreateEventFAB() {
    // Solo mostrar FAB si el usuario puede crear eventos
    if (!_canCreateEvents()) return null;

    return FloatingActionButton.extended(
      onPressed: _createEvent,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Crear Evento'),
    );
  }

  // 🔍 FILTROS Y BÚSQUEDA
  List<Map<String, dynamic>> _filterEventos(List<Map<String, dynamic>> eventos) {
    var filtered = eventos;

    // Filtrar por texto de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((evento) {
        final titulo = (evento['titulo'] ?? '').toString().toLowerCase();
        final descripcion = (evento['descripcion'] ?? '').toString().toLowerCase();
        final lugar = (evento['lugar'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return titulo.contains(query) || descripcion.contains(query) || lugar.contains(query);
      }).toList();
    }

    // Filtrar solo activos
    if (_showActiveOnly) {
      filtered = filtered.where((evento) => evento['isActive'] == true).toList();
    }

    return filtered;
  }

  // 🎯 ACCIONES DE EVENTOS
  void _joinEvent(Evento evento) {
    Navigator.pushNamed(
      context,
      '/attendance-tracking',
      arguments: {
        'eventoId': evento.id,
        'userName': _authService.currentUser?.displayName ?? 'Usuario',
      },
    );
  }

  void _viewEventDetails(Evento evento) {
    Navigator.pushNamed(
      context,
      '/event-details',
      arguments: evento,
    );
  }

  void _editEvent(Evento evento) {
    Navigator.pushNamed(
      context,
      '/edit-event',
      arguments: evento,
    );
  }

  void _createEvent() {
    Navigator.pushNamed(context, '/create-event');
  }

  void _navigateToEventDetails(Evento evento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildEventDetailsModal(evento),
    );
  }

  Widget _buildEventDetailsModal(Evento evento) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                evento.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Tipo', evento.tipo ?? 'No especificado', Icons.category),
                      _buildDetailItem('Lugar', evento.lugar ?? 'No especificado', Icons.location_on),
                      _buildDetailItem('Fecha', evento.fechaInicioFormatted, Icons.date_range),
                      _buildDetailItem(
                        'Horario', 
                        '${evento.horaInicioFormatted} - ${evento.horaFinalFormatted}',
                        Icons.schedule,
                      ),
                      _buildDetailItem('Radio', '${evento.rangoPermitido.toInt()}m', Icons.radio_button_checked),
                      if (evento.descripcion?.isNotEmpty == true)
                        _buildDetailItem('Descripción', evento.descripcion!, Icons.description),
                      const SizedBox(height: 20),
                      if (evento.isActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _joinEvent(evento);
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Unirse al Evento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔐 VERIFICACIONES DE PERMISOS
  bool _canCreateEvents() {
    // Solo profesors y admin pueden crear eventos
    return true; // TODO: Implementar verificación de rol desde Firebase Auth
  }

  bool _canEditEvent(Evento evento) {
    // Solo el creador o admin pueden editar
    final currentUserId = _authService.currentUserId;
    return (evento.creadoPor == currentUserId || _isAdmin());
  }

  bool _isAdmin() {
    // TODO: Implementar verificación de rol admin desde Firestore
    return false;
  }
}