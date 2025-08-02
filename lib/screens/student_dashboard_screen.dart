import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/storage_service.dart';
import '../services/evento_service.dart';
import '../models/usuario_model.dart';
import '../models/evento_model.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String userName;

  const StudentDashboardScreen({
    super.key,
    this.userName = 'Usuario',
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StorageService _storageService = StorageService();
  final EventoService _eventoService = EventoService();

  // TODO PHASE 4: Student Profile Management
  // Este campo será usado para:
  // - Personalización del dashboard con foto/nombre completo
  // - Configuraciones de notificaciones personalizadas
  // - Historial personal de asistencias del estudiante
  // - Estadísticas individuales (% asistencia, eventos totales)
  // - Integración con endpoints: PUT /api/usuarios/{id}, GET /api/usuarios/perfil/{id}
  Usuario? _currentUser;
  List<Evento> _upcomingEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUpcomingEvents();
  }

  Future<void> _loadUserData() async {
    final user = await _storageService.getUser();
    setState(() => _currentUser = user);
  }

  Future<void> _loadUpcomingEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final eventos = await _eventoService.obtenerEventos();
      final now = DateTime.now();
      final upcoming = eventos
          .where((evento) => evento.fecha.isAfter(now) || evento.isActive)
          .take(3)
          .toList();
      setState(() {
        _upcomingEvents = upcoming;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() => _isLoadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Geo Asistencia'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadUpcomingEvents();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildUpcomingEvents(),
              const SizedBox(height: 32),
              _buildLogoutButton(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.blue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hola, ${widget.userName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Estudiante',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event_available,
                title: 'Eventos Disponibles',
                subtitle: 'Ver eventos activos',
                color: AppColors.primaryOrange,
                onTap: () => AppRouter.goToAvailableEvents(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.location_on,
                title: 'Mi Ubicación',
                subtitle: 'Ver mapa en vivo',
                color: AppColors.secondaryTeal,
                onTap: () => AppRouter.goToMapView(
                    isAdminMode: false, userName: widget.userName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person,
                title: 'Mi Perfil',
                subtitle: 'Información personal',
                color: Colors.purple,
                onTap: () => AppRouter.showSnackBar('Próximamente: Mi perfil'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.help_outline,
                title: 'Ayuda',
                subtitle: 'Información de la app',
                color: Colors.green,
                onTap: () =>
                    AppRouter.showSnackBar('Próximamente: Centro de ayuda'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos Eventos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            TextButton(
              onPressed: () => AppRouter.goToAvailableEvents(),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingEvents)
          const Center(child: CircularProgressIndicator())
        else if (_upcomingEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No hay eventos próximos',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._upcomingEvents.map((evento) => _buildEventCard(evento)),
      ],
    );
  }

  Widget _buildEventCard(Evento evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: evento.isActive ? Colors.green : AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_formatDate(evento.fecha)} • ${_formatTime(evento.horaInicio)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          if (evento.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () => AppRouter.logout(),
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.red, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
