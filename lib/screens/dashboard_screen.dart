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
    // ✅ SOLO UN setState al inicio
    setState(() {
      _isLoadingUser = true;
      _isLoadingMetrics = true;
      _isLoadingEvents = true;
      _isLoadingAsistencias = true;
    });

    try {
      // ✅ Cargar todo sin setState intermedios
      final results = await Future.wait([
        _loadUserDataSync(),
        _loadMetricsSync(),
        _loadEventsSync(),
      ]);

      final user = results[0] as Usuario?;
      final metrics = results[1] as List<DashboardMetric>?;
      final eventos = results[2] as List<Evento>;

      // ✅ Procesar datos sin setState
      List<Asistencia> asistencias = [];
      if (user?.rol == AppConstants.estudianteRole) {
        try {
          asistencias = await _loadAsistenciasSync(user!.id);
        } catch (e) {
          debugPrint('❌ Error cargando asistencias: $e');
        }
      }

      // ✅ Procesar eventos para estudiantes
      Evento? eventoActivo;
      List<Evento> userEvents = []; // ✅ DECLARAR VARIABLE
      if (user?.rol == AppConstants.estudianteRole) {
        final eventosActivos = eventos.where((e) => e.isActive);
        eventoActivo = eventosActivos.isNotEmpty ? eventosActivos.first : null;
      }

      // ✅ Filtrar eventos para docentes usando el método existente
      if (user?.rol == AppConstants.docenteRole) {
        // Establecer datos temporalmente para usar _filterEventsByUser()
        _currentUser = user;
        _eventos = eventos;
        _filterEventsByUser(); // ✅ USAR EL MÉTODO EXISTENTE
        userEvents = _userEvents; // Copiar resultado
      }

      // ✅ UN SOLO setState con todos los datos
      setState(() {
        _currentUser = user;
        _metrics = metrics ?? [];
        _eventos = eventos;
        _userEvents = userEvents;
        _asistenciasRecientes = asistencias.take(5).toList();
        _eventoActivo = eventoActivo;

        // ✅ Marcar todas las cargas como completadas
        _isLoadingUser = false;
        _isLoadingMetrics = false;
        _isLoadingEvents = false;
        _isLoadingAsistencias = false;
      });

      debugPrint(
          '✅ Dashboard inicializado: Usuario=${user?.nombre}, Eventos=${eventos.length}');
    } catch (e) {
      debugPrint('❌ Error en inicialización: $e');
      setState(() {
        _isLoadingUser = false;
        _isLoadingMetrics = false;
        _isLoadingEvents = false;
        _isLoadingAsistencias = false;
      });
    }
  }

  /// Carga usuario sin setState
  Future<Usuario?> _loadUserDataSync() async {
    try {
      final user = await _storageService.getUser();
      if (user != null) {
        debugPrint('Usuario cargado: ${user.nombre} - Rol: ${user.rol}');
      }
      return user;
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
      AppRouter.logout();
      return null;
    }
  }

  /// Carga métricas sin setState
  Future<List<DashboardMetric>?> _loadMetricsSync() async {
    try {
      final metrics = await _dashboardService.getMetrics();
      if (metrics != null) {
        debugPrint('Métricas cargadas: ${metrics.length}');
      }
      return metrics;
    } catch (e) {
      debugPrint('Error cargando métricas: $e');
      return null;
    }
  }

  /// Carga eventos sin setState
  Future<List<Evento>> _loadEventsSync() async {
    try {
      List<Evento> eventos;
      
      // ✅ CARGAR EVENTOS SEGÚN EL ROL DEL USUARIO
      if (_currentUser?.rol == 'docente' || _currentUser?.rol == 'admin') {
        // Para docentes: solo sus eventos
        eventos = await _eventoService.obtenerEventosDocente(_currentUser!.id);
        debugPrint('Eventos del docente ${_currentUser!.nombre} cargados: ${eventos.length}');
      } else {
        // Para estudiantes: todos los eventos públicos
        eventos = await _eventoService.obtenerEventos();
        debugPrint('Eventos públicos cargados: ${eventos.length}');
      }
      
      return eventos;
    } catch (e) {
      debugPrint('Error cargando eventos: $e');
      return [];
    }
  }

  /// Carga asistencias sin setState
  Future<List<Asistencia>> _loadAsistenciasSync(String userId) async {
    try {
      debugPrint('📊 Cargando asistencias del estudiante...');
      final asistencias =
          await _asistenciaService.obtenerHistorialUsuario(userId);
      debugPrint('✅ ${asistencias.length} asistencias cargadas');
      return asistencias;
    } catch (e) {
      debugPrint('❌ Error cargando asistencias: $e');
      return [];
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

          // ✅ EVENTOS REALES DEL BACKEND CON VISTA EXPANDIDA
          if (_isLoadingEvents)
            SkeletonLoaders.eventsList(count: 3)
          else if (_eventos.isNotEmpty) ...[
            AdminDashboardWidgets.buildSystemEventsOverview(_eventos),
            const SizedBox(height: 16),
          ],

          // 📊 NUEVO: Alertas del sistema
          AdminDashboardWidgets.buildSystemAlerts(),

          const SizedBox(height: 16),

          // ✅ EVENTOS REALES DEL BACKEND (lista detallada)
          if (_eventos.isNotEmpty)
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

  /// ✅ ACCIONES RÁPIDAS PROFESOR - SOLUCIÓN DEFINITIVA
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
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, AppConstants.createEventRoute),
                      icon: const Icon(Icons.add_circle, size: 16),
                      label: const Text(
                        'Crear Evento',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, AppConstants.availableEventsRoute),
                      icon: const Icon(Icons.event_note, size: 16),
                      label: const Text(
                        'Mis Eventos',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
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
            _capitalizeUserName(_currentUser?.nombre ?? widget.userName),
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

  /// ✅ ESTADO ACTUAL REAL DEL ESTUDIANTE - SOLUCIÓN DEFINITIVA
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
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.play_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Evento Activo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _eventoActivo!.titulo,
                      style: const TextStyle(
                        color: AppColors.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ✅ BOTÓN CON TAMAÑO FIJO - SOLUCIÓN DEFINITIVA
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 100,
                        height: 36,
                        child: TextButton(
                          onPressed: _navigateToTracking,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Continuar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
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

  /// ✅ BOTONES DE ACCIÓN ESTUDIANTE - CON JUSTIFICACIONES
  Widget _buildStudentActionButtons() {
    return Column(
      children: [
        // Primera fila - Eventos y Tracking
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                      context, AppConstants.availableEventsRoute),
                  icon: const Icon(Icons.event_available, size: 16),
                  label: const Text(
                    'Ver Eventos',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextButton.icon(
                  onPressed: _navigateToTracking,
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text(
                    'Mi Tracking',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.secondaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Segunda fila - Justificaciones
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextButton.icon(
                  onPressed: () => AppRouter.goToJustifications(),
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text(
                    'Mis Justificaciones',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextButton.icon(
                  onPressed: () => AppRouter.goToCreateJustification(),
                  icon: const Icon(Icons.add_circle, size: 16),
                  label: const Text(
                    'Nueva Justificación',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Tercera fila - Configuraciones
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextButton.icon(
                  onPressed: () => AppRouter.goToNotificationSettings(),
                  icon: const Icon(Icons.notifications, size: 16),
                  label: const Text(
                    'Notificaciones',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextButton.icon(
                  onPressed: () => AppRouter.goToNotificationSettings(),
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text(
                    'Configuración',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
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
        AppConstants.attendanceTrackingRoute,
        arguments: {
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

  // ===========================================
  // ✅ NUEVOS MÉTODOS NAVEGACIÓN MULTIROL
  // ===========================================

  /// ✅ NUEVO: Manejo de tap en evento para estudiante
  void _handleStudentEventTap(Evento evento) {
    debugPrint('🎓 Estudiante tocó evento: ${evento.titulo}');
    // ESTUDIANTE -> Ir directamente a tracking
    Navigator.pushNamed(
      context,
      AppConstants.attendanceTrackingRoute,
      arguments: {
        'userName': widget.userName,
        'eventoId': evento.id,
      },
    );
  }

  /// ✅ NUEVO: Manejo de tap en evento para docente
  void _handleTeacherEventTap(Evento evento) {
    debugPrint('👩‍🏫 Docente tocó evento: ${evento.titulo}');
    // DOCENTE -> Ir a gestión/monitor
    Navigator.pushNamed(
      context,
      AppConstants.eventMonitorRoute,
      arguments: {
        'eventId': evento.id!,
        'teacherName': widget.userName,
      },
    );
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

  /// ✅ MI EVENTO ITEM (PROFESOR) - CON NAVEGACIÓN MULTIROL
  Widget _buildMyEventItem(Evento evento) {
    return GestureDetector(
      onTap: () => _handleTeacherEventTap(evento), // ✅ NUEVO MÉTODO
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textGray,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.lugar ?? 'Sin ubicación',
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '👆 Toca para gestionar',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryOrange,
                      fontStyle: FontStyle.italic,
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
      ),
    );
  }

  /// ✅ ITEM DE EVENTO ESTUDIANTE - CON NAVEGACIÓN MULTIROL
  Widget _buildStudentEventItem(Evento evento) {
    return GestureDetector(
      onTap: () => _handleStudentEventTap(evento), // ✅ NUEVO MÉTODO
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.secondaryTeal.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 16,
                        color: AppColors.secondaryTeal,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textGray,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evento.lugar ?? 'Sin ubicación',
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '👆 Toca para tracking',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryTeal,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // ✅ BOTÓN MEJORADO - Con estados inteligentes
            SizedBox(
              width: 80,
              height: 32,
              child: _buildJoinEventButton(evento),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ ITEM DE HISTORIAL - COMPLETAMENTE CORREGIDO
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

    // ✅ OBTENER NOMBRE DEL EVENTO DEL ID - CORREGIDO
    String eventoNombre = 'Evento Desconocido';
    try {
      final evento = _eventos.firstWhere((e) => e.id == asistencia.eventoId);
      eventoNombre = evento.titulo;
    } catch (e) {
      // ✅ INTERPOLACIÓN CORREGIDA Y SEGURA
      if (asistencia.eventoId.isNotEmpty) {
        final shortId = asistencia.eventoId.length > 8
            ? asistencia.eventoId.substring(0, 8)
            : asistencia.eventoId;
        eventoNombre = 'Evento $shortId';
      } else {
        eventoNombre = 'Evento sin ID';
      }
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
                  eventoNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  asistencia.fecha.toString().split(' ')[0],
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

  /// Cambia el estado activo/inactivo de un evento
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

  /// ✅ UNIRSE A EVENTO (ESTUDIANTE) - FIXED: Enhanced with proper state management
  Future<void> _joinEvent(Evento evento) async {
    if (evento.id == null || evento.id!.isEmpty) {
      _showErrorDialog('Error', 'El evento no tiene un ID válido');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      // 1. Validate that the user can join this event
      if (!_canUserJoinEvent(evento)) {
        _showErrorDialog('No disponible', 
          'Este evento no está disponible para unirse en este momento');
        return;
      }

      // 2. Check if user is already in an active event
      if (_eventoActivo != null && _eventoActivo!.id != evento.id) {
        if (!mounted) return; // Check if widget is still mounted
        final shouldSwitch = await _showEventSwitchDialog(_eventoActivo!.titulo, evento.titulo);
        if (!shouldSwitch || !mounted) return;
      }

      // 3. Set this event as active
      setState(() {
        _eventoActivo = evento;
      });

      // 4. Navigate to attendance tracking
      if (!mounted) return;
      final result = await Navigator.pushNamed(
        context,
        AppConstants.attendanceTrackingRoute,
        arguments: {
          'userName': widget.userName,
          'eventoId': evento.id,
          'evento': evento, // Pass full event object
        },
      );

      // 5. Handle result from attendance screen
      if (result == 'tracking_stopped' || result == 'attendance_lost') {
        setState(() {
          _eventoActivo = null;
        });
        _refreshData(); // Refresh dashboard data
      }

    } catch (e) {
      debugPrint('❌ Error joining event: $e');
      _showErrorDialog('Error', 'No se pudo unir al evento. Inténtalo de nuevo.');
    } finally {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  /// Check if user can join the given event
  bool _canUserJoinEvent(Evento evento) {
    // Event must be active and not ended
    if (evento.horaFinal.isBefore(DateTime.now())) {
      return false; // Event has ended
    }

    // Event should be started or starting soon (within 10 minutes)
    final now = DateTime.now();
    final eventStart = evento.horaInicio;
    final timeDiff = eventStart.difference(now).inMinutes;
    
    // Event hasn't started yet and is more than 10 minutes away
    if (timeDiff > 10) {
      return false;
    }

    return true; // Event is joinable
  }

  /// Show dialog to confirm switching between events
  Future<bool> _showEventSwitchDialog(String currentEvent, String newEvent) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar de Evento'),
        content: Text(
          'Ya estás participando en "$currentEvent". ¿Deseas cambiar a "$newEvent"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Refresh dashboard data after event changes
  Future<void> _refreshData() async {
    await _initializeData();
  }

  /// Show error dialog with custom title and message
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build intelligent join event button with different states
  Widget _buildJoinEventButton(Evento evento) {
    final isCurrentEvent = _eventoActivo?.id == evento.id;
    final canJoin = _canUserJoinEvent(evento);
    
    String buttonText;
    Color backgroundColor;
    Color textColor;
    VoidCallback? onPressed;

    if (isCurrentEvent) {
      buttonText = 'Activo';
      backgroundColor = Colors.green;
      textColor = Colors.white;
      onPressed = () => _joinEvent(evento); // Allow re-entering
    } else if (!canJoin) {
      buttonText = 'No disp.';
      backgroundColor = Colors.grey;
      textColor = Colors.white;
      onPressed = null; // Disabled
    } else {
      buttonText = 'Unirse';
      backgroundColor = AppColors.primaryOrange;
      textColor = Colors.white;
      onPressed = () => _joinEvent(evento);
    }

    return TextButton(
      onPressed: _isLoadingEvents ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: _isLoadingEvents
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              buttonText,
              style: const TextStyle(fontSize: 11),
            ),
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
            onPressed: _handleRefresh,
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
              onPressed: _handleRefresh,
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
