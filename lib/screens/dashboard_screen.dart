// lib/screens/dashboard_screen.dart - VERSIÓN COMPLETA ESTILO WHATSAPP
import 'package:flutter/material.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import '../utils/colors.dart';
import '../services/dashboard_service.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../models/dashboard_metric_model.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/admin_dashboard_widgets.dart';
import '../widgets/professor_dashboard_widgets.dart';
import '../widgets/loading_skeleton.dart';
import '../core/app_constants.dart';
import '../widgets/detailed_stats_widget.dart';

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

  // Variables de estado
  List<DashboardMetric> _metrics = [];
  List<Evento> _eventos = [];
  List<Evento> _userEvents = []; // Solo para docentes
  Usuario? _currentUser;

  // Estados de carga
  bool _isLoadingMetrics = true;
  bool _isLoadingEvents = true;
  bool _isLoadingUser = true;

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

      debugPrint('Eventos cargados: ${eventos.length}');
    } catch (e) {
      debugPrint('Error cargando eventos: $e');
    } finally {
      setState(() => _isLoadingEvents = false);
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
      surfaceTintColor:
          Colors.transparent, // ✅ AGREGADO: Evita que se oscurezca al scroll
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
      default:
        return _buildUnsupportedRoleState();
    }
  }

  /// Dashboard específico para administrador
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

          // Métricas del sistema
          if (_isLoadingMetrics)
            SkeletonLoaders.metricsList(count: 2)
          else if (_metrics.isNotEmpty)
            AdminDashboardWidgets.buildSystemMetrics(_metrics)
          else
            _buildEmptyMetricsState(),

          const SizedBox(height: 16),

          // Eventos recientes del sistema
          if (_isLoadingEvents)
            SkeletonLoaders.eventsList(count: 2)
          else if (_eventos.isNotEmpty)
            AdminDashboardWidgets.buildRecentEvents(_eventos)
          else
            _buildEmptyEventsState('No hay eventos en el sistema'),

          const SizedBox(height: 16),

          // Actividad del sistema - Solo mostrar si hay espacio
          if (_metrics.isNotEmpty) ...[
            AdminDashboardWidgets.buildSystemActivity(),
            const SizedBox(height: 16),
          ],

          // ✅ AGREGADO: Botón de cerrar sesión al final
          const SizedBox(height: 32),
          _buildLogoutButton(),

          // Espacio extra al final para scroll
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Dashboard específico para docente
  Widget _buildProfessorDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida
          ProfessorDashboardWidgets.buildWelcomeHeader(_currentUser!.nombre),

          const SizedBox(height: 16),

          // Acciones rápidas
          ProfessorDashboardWidgets.buildQuickActions(),

          const SizedBox(height: 16),

          // Estadísticas rápidas
          if (_isLoadingEvents)
            SkeletonLoaders.quickActions()
          else
            ProfessorDashboardWidgets.buildQuickStats(_userEvents),

          const SizedBox(height: 16),

          // Próximos eventos - Solo si tiene eventos
          if (!_isLoadingEvents && _userEvents.isNotEmpty) ...[
            ProfessorDashboardWidgets.buildUpcomingEvents(_userEvents),
            const SizedBox(height: 16),
          ],

          // Métricas contextuales
          if (_isLoadingMetrics)
            SkeletonLoaders.metricsList(count: 1)
          else
            ProfessorDashboardWidgets.buildProfessorMetrics(
                _metrics, _userEvents),

          const SizedBox(height: 16),

          // Mis eventos
          if (_isLoadingEvents)
            SkeletonLoaders.eventsList(count: 1)
          else
            ProfessorDashboardWidgets.buildMyEvents(_userEvents),

          // ✅ AGREGADO: Botón de cerrar sesión al final
          const SizedBox(height: 32),
          _buildLogoutButton(),

          // Espacio extra al final para scroll
          const SizedBox(height: 80),

          // Estadísticas detalladas (solo si hay eventos)
          if (!_isLoadingEvents && _userEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            DetailedStatsWidget(
              isDocente: true,
              eventoId: _userEvents.isNotEmpty ? _userEvents.first.id : null,
            ),
          ],
        ],
      ),
    );
  }

  /// ✅ NUEVO: Botón de cerrar sesión limpio al final de la pantalla
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
          // ✅ SIN crossAxisAlignment para centrar
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
            // ✅ AGREGADO: Center alrededor del TextButton
            child: TextButton(
              onPressed: _loadEvents,
              child: const Text('Recargar eventos'),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ CORREGIDO: Diálogo de logout limpio y bien posicionado
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // ✅ Fondo blanco limpio
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
          // Botón Cancelar
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

          // Botón Cerrar Sesión
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
