import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/screens/firebase/firebase_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase/firebase_auth_service.dart';
import '../../services/firebase/firebase_evento_service.dart';
import '../../services/firebase/firebase_asistencia_service.dart';
import '../../services/firebase/firebase_messaging_service.dart';
// Unused import removed: evento_model
// Unused import removed
import '../../models/usuario_model.dart';
import '../../utils/colors.dart';

class FirebaseDashboardScreen extends StatefulWidget {
  const FirebaseDashboardScreen({super.key});

  @override
  State<FirebaseDashboardScreen> createState() => _FirebaseDashboardScreenState();
}

class _FirebaseDashboardScreenState extends State<FirebaseDashboardScreen> {
  late FirebaseAuthService _authService;
  late FirebaseEventoService _eventoService;
  late FirebaseAsistenciaService _asistenciaService;
  late FirebaseMessagingService _messagingService;
  
  Usuario? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = context.read<FirebaseAuthService>();
    _eventoService = context.read<FirebaseEventoService>();
    _asistenciaService = context.read<FirebaseAsistenciaService>();
    _messagingService = context.read<FirebaseMessagingService>();
    
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      // Obtener usuario actual
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        // Convertir a nuestro modelo Usuario si es necesario
        
        // Inicializar servicios Firebase
        await _eventoService.initialize();
        await _asistenciaService.initialize();
        await _messagingService.initialize(firebaseUser.uid);
      }
    } catch (e) {
      logger.d('Error inicializando datos de usuario: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return _buildNotLoggedIn();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${_currentUser!.nombre}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          PopupMenuButton(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configuración'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(),
              const SizedBox(height: 20),
              _buildEventoActivo(),
              const SizedBox(height: 20),
              _buildEventosHoy(),
              const SizedBox(height: 20),
              _buildAsistenciasRecientes(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildQuickActions(),
    );
  }

  Widget _buildNotLoggedIn() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Sesión no iniciada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor inicia sesión para continuar',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _asistenciaService.asistenciasStream,
      builder: (context, snapshot) {
        // Placeholder stats for compatibility
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Asistencias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', '0', Icons.event_available),
                    _buildStatCard('Esta Semana', '0', Icons.date_range),
                    _buildStatCard('Puntualidad', '0%', Icons.schedule),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventoActivo() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _eventoService.eventoActivoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final eventoActivo = snapshot.data;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evento Activo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (eventoActivo != null)
                  _buildActiveEventCardFromMap(eventoActivo)
                else
                  _buildNoActiveEvent(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveEventCardFromMap(Map<String, dynamic> eventoData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Evento Activo',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            eventoData['titulo']?.toString() ?? 'Evento sin título',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            eventoData['descripcion']?.toString() ?? 'Sin descripción',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }


  Widget _buildNoActiveEvent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No hay eventos activos',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventosHoy() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventoService.eventosStream,
      builder: (context, snapshot) {
        final eventosHoy = (snapshot.data ?? [])
            .where((e) => _isTodayFromMap(e))
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Eventos de Hoy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/firebase-events'),
                      child: const Text('Ver Todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (eventosHoy.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay eventos programados para hoy'),
                    ),
                  )
                else
                  ...eventosHoy.take(3).map((evento) => _buildEventListItemFromMap(evento)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsistenciasRecientes() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _asistenciaService.asistenciasStream,
      builder: (context, snapshot) {
        final asistencias = (snapshot.data ?? []).take(5).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistencias Recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (asistencias.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay asistencias registradas'),
                    ),
                  )
                else
                  ...asistencias.map((asistencia) => _buildAsistenciaListItemFromMap(asistencia)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventListItemFromMap(Map<String, dynamic> eventoData) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryColor,
        child: Icon(
          Icons.schedule,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(eventoData['titulo']?.toString() ?? 'Sin título'),
      subtitle: Text('${eventoData['horaInicio']?.toString() ?? 'Sin hora'} - ${eventoData['lugar']?.toString() ?? 'Sin lugar'}'),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () {
        // Navigation logic here
      },
    );
  }


  Widget _buildAsistenciaListItemFromMap(Map<String, dynamic> asistenciaData) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.event_available,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(asistenciaData['eventoTitulo']?.toString() ?? 'Evento sin título'),
      subtitle: Text('Estado: ${asistenciaData['estado']?.toString() ?? 'Sin estado'}'),
      trailing: Chip(
        label: Text(
          _getEstadoLabel(asistenciaData['estado']?.toString() ?? ''),
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      ),
    );
  }


  Widget _buildQuickActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "join_event",
          onPressed: _quickJoinEvent,
          backgroundColor: Colors.green,
          child: const Icon(Icons.login, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "view_events",
          onPressed: () => Navigator.pushNamed(context, '/firebase-events'),
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.event, color: Colors.white),
        ),
      ],
    );
  }

  // 🎯 ACCIONES
  Future<void> _refreshData() async {
    await Future.wait([
      _eventoService.refreshEventos(),
      _asistenciaService.refreshAsistencias(),
    ]);
  }

  // Unused methods removed: _joinEvent, _navigateToEvent

  Future<void> _quickJoinEvent() async {
    final response = await _eventoService.getEventoActivo();
    if (response != null) {
      // Convert Map to Evento if needed, for now just show placeholder
      logger.d('Event found: $response');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay eventos activos disponibles'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      logger.d('Error during logout: $e');
    }
  }

  // 🔧 UTILIDADES
  bool _isTodayFromMap(Map<String, dynamic> evento) {
    try {
      final fechaStr = evento['fecha']?.toString();
      if (fechaStr == null) return false;
      final fecha = DateTime.parse(fechaStr);
      return _isToday(fecha);
    } catch (e) {
      return false;
    }
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  // Unused method _formatTimestamp removed

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'presente_a_tiempo':
        return 'A tiempo';
      case 'presente_temprano':
        return 'Temprano';
      case 'presente_tarde':
        return 'Tarde';
      default:
        return estado;
    }
  }
}