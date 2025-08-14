// lib/screens/dashboard_screen.dart - VERSIÓN COMPLETA CON ESTUDIANTE
import 'package:flutter/material.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import '../utils/colors.dart';
import '../services/dashboard_service.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../services/asistencia_service.dart'; // ✅ AGREGADO para estudiante
import '../models/dashboard_metric_model.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../models/asistencia_model.dart'; // ✅ AGREGADO para estudiante
import '../widgets/custom_button.dart';
import '../widgets/admin_dashboard_widgets.dart';
import '../widgets/professor_dashboard_widgets.dart';
import '../widgets/loading_skeleton.dart';
import '../core/app_constants.dart';
import '../widgets/detailed_stats_widget.dart'; // ✅ AHORA SE USA

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({
    super.key,
    this.userName = 'Usuario',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Servicios
  final DashboardService _dashboardService = DashboardService();
  final EventoService _eventoService = EventoService();
  final StorageService _storageService = StorageService();
  final AsistenciaService _asistenciaService =
      AsistenciaService(); // ✅ AGREGADO

  // Variables de estado
  List<DashboardMetric> _metrics = [];
  List<Evento> _eventos = [];
  List<Evento> _userEvents = []; // Solo para docentes
  List<Asistencia> _asistenciasRecientes = []; // ✅ AGREGADO para estudiante
  Usuario? _currentUser;
  Evento? _eventoActivo; // ✅ AGREGADO para estudiante

  // Estados de carga
  bool _isLoadingMetrics = true;
  bool _isLoadingEvents = true;
  bool _isLoadingUser = true;
  bool _isLoadingAsistencias = true; // ✅ AGREGADO

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Inicializa todos los datos necesarios para el dashboard
  Future<void> _initializeData() async {
    await Future.wait([
      _loadUserData(),
      _loadMetrics(),
      _loadEvents(),
    ]);

    // ✅ AGREGADO: Cargar asistencias solo para estudiantes
    if (_currentUser?.rol == AppConstants.estudianteRole) {
      await _loadAsistenciasRecientes();
    }
  }

  /// Carga los datos del usuario actual desde storage
  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);

    try {
      final user = await _storageService.getUser();
      setState(() => _currentUser = user);

      if (user != null) {
        debugPrint('Usuario cargado: ${user.nombre} - Rol: ${user.rol}');
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
      // Si no hay usuario, redirigir al login
      AppRouter.logout();
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  /// Carga las métricas del dashboard
  Future<void> _loadMetrics() async {
    setState(() => _isLoadingMetrics = true);

    try {
      final metrics = await _dashboardService.getMetrics();
      if (metrics != null) {
        setState(() => _metrics = metrics);
        debugPrint('Métricas cargadas: ${metrics.length}');
      }
    } catch (e) {
      debugPrint('Error cargando métricas: $e');
    } finally {
      setState(() => _isLoadingMetrics = false);
    }
  }

  /// Carga los eventos y los filtra según el rol del usuario
  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);

    try {
      final eventos = await _eventoService.obtenerEventos();
      setState(() => _eventos = eventos);

      // Filtrar eventos para docentes
      if (_currentUser?.rol == AppConstants.docenteRole) {
        _filterEventsByUser();
      }

      // ✅ AGREGADO: Buscar evento activo para estudiantes
      if (_currentUser?.rol == AppConstants.estudianteRole) {
        _eventoActivo = eventos.where((e) => e.isActive).isNotEmpty
            ? eventos.firstWhere((e) => e.isActive)
            : null;
      }

      debugPrint('Eventos cargados: ${eventos.length}');
    } catch (e) {
      debugPrint('Error cargando eventos: $e');
    } finally {
      setState(() => _isLoadingEvents = false);
    }
  }

  /// ✅ NUEVO: Cargar asistencias recientes del estudiante
  Future<void> _loadAsistenciasRecientes() async {
    setState(() => _isLoadingAsistencias = true);

    try {
      if (_currentUser?.id != null) {
        debugPrint('📊 Cargando asistencias del estudiante...');
        final asistencias = await _asistenciaService
            .obtenerHistorialUsuario(_currentUser!.id); // ✅ CORREGIDO

        setState(() {
          _asistenciasRecientes =
              asistencias.take(5).toList(); // Solo las 5 más recientes
        });

        debugPrint('✅ ${asistencias.length} asistencias cargadas');
      }
    } catch (e) {
      debugPrint('❌ Error cargando asistencias: $e');
    } finally {
      setState(() => _isLoadingAsistencias = false);
    }
  }

  /// Filtra eventos creados por el usuario actual (solo para docentes)
  void _filterEventsByUser() {
    if (_currentUser != null) {
      _userEvents = _eventos
          .where((evento) => evento.creadoPor == _currentUser!.id)
          .toList();
      debugPrint('Eventos del docente: ${_userEvents.length}');
    }
  }

  /// Maneja el refresh de todos los datos
  Future<void> _handleRefresh() async {
    await _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Construye el AppBar estilo WhatsApp - limpio y minimalista
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Geo Asistencia',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
    );
  }

  /// Construye el cuerpo principal de la pantalla
  Widget _buildBody() {
    // Mostrar skeleton mientras cargan los datos principales
    if (_isLoadingUser || (_isLoadingMetrics && _isLoadingEvents)) {
      return SkeletonLoaders.dashboardPage();
    }

    // Si no hay usuario, mostrar error
    if (_currentUser == null) {
      return _buildErrorState(
        'No se pudo cargar la información del usuario',
        'Inicia sesión nuevamente',
        () => AppRouter.logout(),
      );
    }

    // Mostrar dashboard según el rol
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _buildDashboardByRole(),
    );
  }

  /// Construye el dashboard según el rol del usuario
  Widget _buildDashboardByRole() {
    switch (_currentUser!.rol) {
      case AppConstants.adminRole:
        return _buildAdminDashboard();
      case AppConstants.docenteRole:
        return _buildProfessorDashboard();
      case AppConstants.estudianteRole: // ✅ AGREGAR ESTE CASO
        return _buildStudentDashboard();
      default:
        return _buildUnsupportedRoleState();
    }
  }

  /// Dashboard específico para administrador CON DATOS REALES
  Widget _buildAdminDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida
          AdminDashboardWidgets.buildWelcomeHeader(_currentUser!.nombre),

          const SizedBox(height: 16),

          // Acciones rápidas
          AdminDashboardWidgets.buildQuickActions(),

          const SizedBox(height: 16),

          // ✅ MÉTRICAS REALES DEL BACKEND
          if (_isLoadingMetrics)
            SkeletonLoaders.metricsList(count: 4)
          else if (_metrics.isNotEmpty)
            _buildRealSystemMetrics()
          else
            _buildEmptyMetricsState(),

          const SizedBox(height: 16),

          // ✅ EVENTOS REALES DEL BACKEND
          if (_isLoadingEvents)
            SkeletonLoaders.eventsList(count: 3)
          else if (_eventos.isNotEmpty)
            _buildRealSystemEvents()
          else
            _buildEmptyEventsState('No hay eventos en el sistema'),

          const SizedBox(height: 16),

          // ✅ ESTADÍSTICAS REALES DE ACTIVIDAD
          _buildRealSystemActivity(),

          const SizedBox(height: 16),

          // ✅ NUEVO: INTEGRAR DetailedStatsWidget en dashboard profesor
          if (!_isLoadingEvents && _userEvents.isNotEmpty) ...[
            DetailedStatsWidget(
              isDocente: true,
              eventoId: _userEvents.isNotEmpty ? _userEvents.first.id : null,
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Dashboard específico para docente CON DATOS REALES
  Widget _buildProfessorDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida
          ProfessorDashboardWidgets.buildWelcomeHeader(_currentUser!.nombre),

          const SizedBox(height: 16),

          // ✅ ACCIONES RÁPIDAS CON NAVEGACIÓN REAL
          _buildProfessorQuickActions(),

          const SizedBox(height: 16),

          // ✅ ESTADÍSTICAS REALES DE MIS EVENTOS
          if (_isLoadingEvents)
            SkeletonLoaders.quickActions()
          else
            _buildRealProfessorStats(),

          const SizedBox(height: 16),

          // ✅ MIS EVENTOS REALES CON CONTROLES
          if (_isLoadingEvents)
            SkeletonLoaders.eventsList(count: 2)
          else
            _buildRealMyEvents(),

          const SizedBox(height: 16),

          // ✅ MÉTRICAS REALES DE MIS EVENTOS
          if (_isLoadingMetrics)
            SkeletonLoaders.metricsList(count: 2)
          else
            _buildRealProfessorMetrics(),

          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Dashboard específico para estudiante CON DATOS REALES
  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SALUDO PERSONALIZADO ESTUDIANTE
          _buildStudentWelcomeCard(),

          const SizedBox(height: 16),

          // ✅ ESTADO ACTUAL REAL DEL ESTUDIANTE
          _buildStudentCurrentStatus(),

          const SizedBox(height: 16),

          // ✅ EVENTOS DISPONIBLES REALES (top 3)
          if (_isLoadingEvents)
            SkeletonLoaders.eventsList(count: 3)
          else
            _buildStudentAvailableEvents(),

          const SizedBox(height: 16),

          // ✅ ESTADÍSTICAS PERSONALES REALES
          if (_isLoadingAsistencias)
            SkeletonLoaders.metricsList(count: 2)
          else
            _buildStudentPersonalStats(),

          const SizedBox(height: 16),

          // ✅ HISTORIAL RECIENTE REAL
          _buildStudentRecentHistory(),

          const SizedBox(height: 16),

          // ✅ ACCIONES PRINCIPALES
          _buildStudentActionButtons(),

          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ===========================================
  // ✅ WIDGETS ADMIN CON DATOS REALES
  // ===========================================

  /// ✅ MÉTRICAS REALES DEL SISTEMA
  Widget _buildRealSystemMetrics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Métricas del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grid de métricas reales
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(
                  'Total Usuarios',
                  _getMetricValue('total_usuarios', '0'),
                  Icons.people,
                  AppColors.primaryOrange,
                ),
                _buildMetricCard(
                  'Eventos Activos',
                  _eventos.where((e) => e.isActive).length.toString(),
                  Icons.event,
                  AppColors.secondaryTeal,
                ),
                _buildMetricCard(
                  'Total Eventos',
                  _eventos.length.toString(),
                  Icons.event_note,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Asistencias Hoy',
                  _getMetricValue('asistencias_hoy', '0'),
                  Icons.assignment_turned_in,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ EVENTOS REALES DEL SISTEMA
  Widget _buildRealSystemEvents() {
    final eventosRecientes = _eventos.take(3).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_note, color: AppColors.primaryOrange),
                    SizedBox(width: 8),
                    Text(
                      'Eventos del Sistema',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppConstants.availableEventsRoute),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...eventosRecientes.map((evento) =>
                _buildEventListItem(evento)), // ✅ CORREGIDO: Sin .toList()
          ],
        ),
      ),
    );
  }

  /// ✅ ACTIVIDAD REAL DEL SISTEMA
  Widget _buildRealSystemActivity() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Actividad del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityCard(
                    'Eventos Creados',
                    _eventos.length.toString(),
                    'últimos 30 días',
                    Icons.add_circle,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActivityCard(
                    'Tasa Asistencia',
                    _getMetricValue('tasa_asistencia', '0%'),
                    'promedio general',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // ✅ WIDGETS PROFESOR CON DATOS REALES
  // ===========================================

  /// ✅ ACCIONES RÁPIDAS PROFESOR CON NAVEGACIÓN REAL
  Widget _buildProfessorQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(
                  'Crear Evento',
                  Icons.add_circle,
                  AppColors.primaryOrange,
                  () => Navigator.pushNamed(
                      context, AppConstants.createEventRoute),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  'Mis Eventos',
                  Icons.event_note,
                  AppColors.secondaryTeal,
                  () => Navigator.pushNamed(
                      context, AppConstants.availableEventsRoute),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ ESTADÍSTICAS REALES DEL PROFESOR
  Widget _buildRealProfessorStats() {
    final eventosActivos = _userEvents.where((e) => e.isActive).length;
    final totalEventos = _userEvents.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Eventos Activos',
                    eventosActivos.toString(),
                    Icons.play_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Eventos',
                    totalEventos.toString(),
                    Icons.event_note,
                    AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ MIS EVENTOS REALES CON CONTROLES
  Widget _buildRealMyEvents() {
    if (_userEvents.isEmpty) {
      return _buildEmptyEventsState('No has creado eventos aún');
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Eventos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppConstants.createEventRoute),
                  child: const Text('Crear Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._userEvents.take(3).map((evento) =>
                _buildMyEventItem(evento)), // ✅ CORREGIDO: Sin .toList()
          ],
        ),
      ),
    );
  }

  /// ✅ MÉTRICAS REALES DEL PROFESOR
  Widget _buildRealProfessorMetrics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métricas de Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Promedio Asistencia',
                    _getMetricValue('promedio_asistencia_profesor', '0%'),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Estudiantes Únicos',
                    _getMetricValue('estudiantes_unicos', '0'),
                    Icons.people,
                    AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // ✅ WIDGETS ESTUDIANTE CON DATOS REALES
  // ===========================================

  /// ✅ SALUDO PERSONALIZADO ESTUDIANTE - ESTILO ELEGANTE
  Widget _buildStudentWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 42, 71, 201),
            const Color.fromARGB(255, 30, 79, 214).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryTeal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ ÍCONO CENTRADO ARRIBA (como admin/profesor)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              color: AppColors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          // ✅ TEXTO CENTRADO (como admin/profesor)
          const Text(
            'Bienvenido',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _capitalizeUserName(
                _currentUser?.nombre ?? widget.userName ?? 'Estudiante'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Panel Estudiante',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ✅ ESTADO ACTUAL REAL DEL ESTUDIANTE
  Widget _buildStudentCurrentStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Estado Actual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_eventoActivo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evento Activo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            _eventoActivo!.titulo,
                            style: const TextStyle(color: AppColors.darkGray),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _navigateToTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_busy, color: AppColors.textGray),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sin eventos activos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textGray,
                            ),
                          ),
                          Text(
                            'No hay eventos disponibles ahora',
                            style: TextStyle(color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ EVENTOS DISPONIBLES REALES
  Widget _buildStudentAvailableEvents() {
    final eventosActivos = _eventos.where((e) => e.isActive).take(3).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_available, color: AppColors.primaryOrange),
                    SizedBox(width: 8),
                    Text(
                      'Eventos Disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppConstants.availableEventsRoute),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (eventosActivos.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy,
                          size: 48, color: AppColors.textGray),
                      SizedBox(height: 12),
                      Text(
                        'No hay eventos disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...eventosActivos.map((evento) =>
                  _buildStudentEventItem(evento)), // ✅ CORREGIDO: Sin .toList()
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ ESTADÍSTICAS PERSONALES REALES
  Widget _buildStudentPersonalStats() {
    final totalAsistencias = _asistenciasRecientes.length;
    final asistenciasCompletas =
        _asistenciasRecientes.where((a) => a.estado == 'presente').length;
    final porcentajeAsistencia = totalAsistencias > 0
        ? (asistenciasCompletas / totalAsistencias * 100).round()
        : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Mis Estadísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Asistencias',
                    totalAsistencias.toString(),
                    Icons.assignment_turned_in,
                    AppColors.secondaryTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Porcentaje',
                    '$porcentajeAsistencia%',
                    Icons.trending_up,
                    porcentajeAsistencia >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ HISTORIAL RECIENTE REAL
  Widget _buildStudentRecentHistory() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Historial Reciente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingAsistencias) ...[
              SkeletonLoaders.listItem(), // ✅ CORREGIDO: Usar listItem()
              SkeletonLoaders.listItem(),
              SkeletonLoaders.listItem(),
            ] else if (_asistenciasRecientes.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.assignment,
                          size: 48, color: AppColors.textGray),
                      SizedBox(height: 12),
                      Text(
                        'No hay asistencias registradas',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ..._asistenciasRecientes.take(3).map((asistencia) =>
                  _buildHistoryItem(asistencia)), // ✅ CORREGIDO: Sin .toList()
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ BOTONES DE ACCIÓN ESTUDIANTE
  Widget _buildStudentActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            _buildActionButton(
              'Ver Eventos',
              Icons.event_available,
              AppColors.primaryOrange,
              () => Navigator.pushNamed(
                  context, AppConstants.availableEventsRoute),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              'Mi Tracking',
              Icons.location_on,
              AppColors.secondaryTeal,
              _navigateToTracking,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================
  // ✅ WIDGETS UTILITARIOS REALES
  // ===========================================

  /// ✅ NAVEGACIÓN A TRACKING REAL
  void _navigateToTracking() {
    if (_eventoActivo != null) {
      Navigator.pushNamed(
        context,
        AppConstants.mapViewRoute,
        arguments: {
          'isStudentMode': true,
          'userName': widget.userName,
          'eventoId': _eventoActivo!.id,
        },
      );
    } else {
      // Si no hay evento activo, ir a la lista de eventos
      Navigator.pushNamed(context, AppConstants.availableEventsRoute);
    }
  }

  /// ✅ OBTENER VALOR DE MÉTRICA REAL
  String _getMetricValue(String key, String defaultValue) {
    try {
      final metric = _metrics.firstWhere(
          (m) => m.metric == key); // ✅ CORREGIDO: metric en lugar de name
      return metric.value.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  /// ✅ TARJETA DE MÉTRICA REUTILIZABLE
  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ✅ TARJETA DE ESTADÍSTICA REUTILIZABLE
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ✅ BOTÓN DE ACCIÓN REUTILIZABLE - CORREGIDO
  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return Expanded(
      // ✅ AGREGADO: Expanded automático
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          title,
          overflow:
              TextOverflow.ellipsis, // ✅ AGREGADO: Prevenir overflow de texto
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// ✅ ITEM DE EVENTO REUTILIZABLE
  Widget _buildEventListItem(Evento evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: evento.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(4),
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  evento.lugar ?? 'Sin ubicación',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: evento.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              evento.isActive ? 'Activo' : 'Inactivo',
              style: const TextStyle(
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

  /// ✅ MI EVENTO ITEM (PROFESOR)
  Widget _buildMyEventItem(Evento evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  evento.lugar ?? 'Sin ubicación',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: evento.isActive,
            onChanged: (value) => _toggleEventActive(evento.id!, value),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  /// ✅ ITEM DE EVENTO ESTUDIANTE
  Widget _buildStudentEventItem(Evento evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  evento.lugar ?? 'Sin ubicación',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _joinEvent(evento),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  /// ✅ ITEM DE HISTORIAL
  Widget _buildHistoryItem(Asistencia asistencia) {
    Color stateColor;
    IconData stateIcon;

    switch (asistencia.estado.toLowerCase()) {
      case 'presente':
        stateColor = Colors.green;
        stateIcon = Icons.check_circle;
        break;
      case 'tarde':
        stateColor = Colors.orange;
        stateIcon = Icons.access_time;
        break;
      case 'ausente':
        stateColor = Colors.red;
        stateIcon = Icons.cancel;
        break;
      default:
        stateColor = Colors.grey;
        stateIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(stateIcon, color: stateColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evento ${asistencia.eventoId}', // TODO: Get event name
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  asistencia.fecha.toString().split(' ')[0], // Solo fecha
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stateColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              asistencia.estado.toUpperCase(),
              style: const TextStyle(
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

  /// ✅ TARJETA DE ACTIVIDAD
  Widget _buildActivityCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // ✅ MÉTODOS DE INTERACCIÓN REALES
  // ===========================================

  // ✅ CAMBIAR TODO EL MÉTODO _toggleEventActive:
  Future<void> _toggleEventActive(String eventoId, bool isActive) async {
    try {
      final success =
          await _eventoService.toggleEventoActive(eventoId, isActive);

      if (success) {
        setState(() {
          final index = _userEvents.indexWhere((e) => e.id == eventoId);
          if (index != -1) {
            _userEvents[index] =
                _userEvents[index].copyWith(isActive: isActive);
          }
        });

        // ✅ AGREGAR mounted check:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(isActive ? 'Evento activado' : 'Evento desactivado'),
              backgroundColor: isActive ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Error en la API');
      }
    } catch (e) {
      // ✅ AGREGAR mounted check:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar estado del evento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ UNIRSE A EVENTO (ESTUDIANTE)
  Future<void> _joinEvent(Evento evento) async {
    Navigator.pushNamed(
      context,
      AppConstants.mapViewRoute,
      arguments: {
        'isStudentMode': true,
        'userName': widget.userName,
        'eventoId': evento.id,
      },
    );
  }

  /// Estado para rol no soportado
  Widget _buildUnsupportedRoleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'Rol no soportado en el dashboard',
            style: TextStyle(fontSize: 18, color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Rol actual: ${_currentUser?.rol ?? "Desconocido"}',
            style: const TextStyle(fontSize: 14, color: AppColors.textGray),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Cerrar Sesión',
            onPressed: () => AppRouter.logout(),
          ),
        ],
      ),
    );
  }

  /// Estado de error genérico
  Widget _buildErrorState(
      String title, String subtitle, VoidCallback onAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Reintentar',
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  /// Estado cuando no hay métricas
  Widget _buildEmptyMetricsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.analytics,
            size: 48,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay métricas disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las métricas aparecerán cuando haya actividad en el sistema',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadMetrics,
            child: const Text('Recargar métricas'),
          ),
        ],
      ),
    );
  }

  /// Estado cuando no hay eventos
  Widget _buildEmptyEventsState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_note,
            size: 48,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _loadEvents,
              child: const Text('Recargar eventos'),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ BOTÓN DE CERRAR SESIÓN LIMPIO
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(
          Icons.logout,
          color: Colors.red,
          size: 20,
        ),
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

  String _capitalizeUserName(String name) {
    if (name.isEmpty) return name;

    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// ✅ DIÁLOGO DE LOGOUT LIMPIO
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }
}
