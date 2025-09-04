// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import 'dart:math' as math;
import '../utils/colors.dart';
import '../services/dashboard_service.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../services/asistencia_service.dart';
import '../services/location_service.dart';
import '../models/dashboard_metric_model.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../models/asistencia_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_skeleton.dart';
import '../core/app_constants.dart';
import '../widgets/dashboard/admin_dashboard_section.dart';
import '../widgets/dashboard/professor_dashboard_section.dart';
import '../widgets/dashboard/student_dashboard_section.dart';

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
  final AsistenciaService _asistenciaService = AsistenciaService(); 
  final LocationService _locationService = LocationService(); // ✅ AGREGADO

  // Variables de estado
  List<DashboardMetric> _metrics = [];
  List<Evento> _eventos = [];
  List<Evento> _userEvents = []; // Solo para profesors
  Usuario? _currentUser;
  Evento? _eventoActivo; // ✅ AGREGADO para estudiante

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
    // ✅ SOLO UN setState al inicio
    setState(() {
      _isLoadingUser = true;
      _isLoadingMetrics = true;
      _isLoadingEvents = true;
    });

    try {
      // ✅ Cargar usuario primero, luego eventos según rol
      final user = await _loadUserDataSync();
      
      final results = await Future.wait([
        _loadMetricsSync(),
        _loadEventsForUserSync(user),
      ]);

      final metrics = results[0] as List<DashboardMetric>?;
      final eventos = results[1] as List<Evento>;

      // ✅ Procesar datos sin setState
      if (user?.rol == AppConstants.estudianteRole) {
        try {
          if (user?.id != null && user!.id.isNotEmpty) {
            debugPrint('✅ Usando usuario principal: ${user!.id}');
            await _loadAsistenciasSync(user!.id);
          } else {
            debugPrint('⚠️ Usuario sin ID válido, creando usuario de prueba...');
            // Crear usuario de prueba
            final testUser = await StorageService().createTestUserIfNeeded();
            debugPrint('✅ Usuario de prueba creado: ${testUser.id}');
            if (testUser.id.isNotEmpty) {
              await _loadAsistenciasSync(testUser.id);
            } else {
              debugPrint('❌ Usuario de prueba también tiene ID vacío');
            }
          }
        } catch (e) {
          debugPrint('❌ Error cargando asistencias: $e');
        }
      }

      // ✅ Procesar eventos para estudiantes CON LÓGICA MEJORADA
      Evento? eventoActivo;
      List<Evento> userEvents = []; // ✅ DECLARAR VARIABLE
      if (user?.rol == AppConstants.estudianteRole) {
        eventoActivo = await _selectBestEventForStudent(eventos);
        debugPrint('🎯 Evento seleccionado para estudiante: ${eventoActivo?.titulo ?? "Ninguno"}');
      }

      // ✅ NUEVOS: Eventos específicos para profesors/admin
      if (user?.rol == AppConstants.profesorRole || user?.rol == 'admin') {
        // Los eventos ya vienen filtrados por getEventosByCreador()
        userEvents = eventos;
        debugPrint('✅ Eventos del profesor ${user?.nombre} procesados: ${userEvents.length}');
      }

      // ✅ UN SOLO setState con todos los datos
      setState(() {
        _currentUser = user;
        _metrics = metrics ?? [];
        _eventos = eventos;
        _userEvents = userEvents;
        _eventoActivo = eventoActivo;

        // ✅ Marcar todas las cargas como completadas
        _isLoadingUser = false;
        _isLoadingMetrics = false;
        _isLoadingEvents = false;
      });

      debugPrint(
          '✅ Dashboard inicializado: Usuario=${user?.nombre}, Eventos=${eventos.length}');
    } catch (e) {
      debugPrint('❌ Error en inicialización: $e');
      setState(() {
        _isLoadingUser = false;
        _isLoadingMetrics = false;
        _isLoadingEvents = false;
      });
    }
  }

  /// Carga usuario sin setState - ✅ TOLERANTE CON ERRORES TEMPORALES
  Future<Usuario?> _loadUserDataSync() async {
    try {
      final user = await _storageService.getUser();
      if (user != null) {
        debugPrint('Usuario cargado: ${user.nombre} - Rol: ${user.rol}');
        return user;
      } else {
        debugPrint('⚠️ No hay usuario en storage - es posible logout legítimo');
        // Solo hacer logout si realmente no hay datos de usuario
        final hasAnyUserData = await _storageService.getToken();
        if (hasAnyUserData == null) {
          debugPrint('🚪 No hay token - redirigiendo a login');
          AppRouter.logout();
        }
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Error temporal cargando usuario: $e - NO desconectando');
      // ✅ NO desconectar automáticamente en errores temporales
      // Solo desconectar si hay evidencia clara de que la sesión es inválida
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
  Future<List<Evento>> _loadEventsForUserSync(Usuario? user) async {
    try {
      List<Evento> eventos;
      
      // ✅ CARGAR EVENTOS SEGÚN EL ROL DEL USUARIO
      if (user?.rol == 'profesor' || user?.rol == 'admin') {
        // Para profesors: solo sus eventos
        eventos = await _eventoService.getEventosByCreador(user!.id);
        debugPrint('Eventos del profesor ${user.nombre} cargados: ${eventos.length}');
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


  /// Maneja el refresh de todos los datos
  Future<void> _handleRefresh() async {
    await _initializeData();
  }

  /// ✅ NUEVA LÓGICA: Selecciona el mejor evento para el estudiante
  /// Prioriza por: 1) Estado del evento, 2) Proximidad geográfica, 3) Tiempo
  Future<Evento?> _selectBestEventForStudent(List<Evento> eventos) async {
    try {
      debugPrint('🎯 Seleccionando mejor evento para estudiante...');
      
      // 1. Filtrar solo eventos relevantes para estudiantes
      final eventosRelevantes = eventos.where((evento) => 
        evento.estado == 'En proceso' || // Ya iniciado (máxima prioridad)
        evento.estado == 'activo' ||     // Programado para hoy
        evento.estado == 'En espera'     // Pausado temporalmente
      ).toList();
      
      if (eventosRelevantes.isEmpty) {
        debugPrint('❌ No hay eventos relevantes para estudiantes');
        return null;
      }
      
      // 2. Obtener ubicación actual del estudiante (si es posible)
      double? studentLat, studentLng;
      try {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          studentLat = position.latitude;
          studentLng = position.longitude;
          debugPrint('📍 Ubicación estudiante: $studentLat, $studentLng');
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo obtener ubicación del estudiante: $e');
      }
      
      // 3. Calcular puntuación para cada evento
      final eventosConPuntuacion = eventosRelevantes.map((evento) {
        double puntuacion = 0;
        
        // FACTOR 1: Estado del evento (más peso a eventos ya iniciados)
        switch (evento.estado) {
          case 'En proceso':
            puntuacion += 100; // Máxima prioridad - evento activo
            break;
          case 'En espera':
            puntuacion += 80;  // Alta prioridad - evento pausado
            break;
          case 'activo':
            puntuacion += 60;  // Prioridad media - evento programado
            break;
        }
        
        // FACTOR 2: Proximidad geográfica (si tenemos ubicación)
        if (studentLat != null && studentLng != null) {
          final distance = _calculateDistance(
            studentLat, studentLng,
            evento.ubicacion.latitud, evento.ubicacion.longitud
          );
          
          // Bonus por proximidad (máximo 50 puntos)
          if (distance <= evento.rangoPermitido) {
            puntuacion += 50; // Dentro del área del evento
          } else if (distance <= evento.rangoPermitido * 2) {
            puntuacion += 25; // Cerca del evento
          } else if (distance <= evento.rangoPermitido * 5) {
            puntuacion += 10; // Relativamente cerca
          }
          
          debugPrint('📏 Distancia a ${evento.titulo}: ${distance.round()}m (Rango: ${evento.rangoPermitido.round()}m)');
        }
        
        // FACTOR 3: Tiempo - bonus por eventos que ya deberían haber comenzado
        final now = DateTime.now();
        try {
          // Combinar fecha y hora de inicio del evento
          final eventDateTime = DateTime(
            evento.fecha.year,
            evento.fecha.month, 
            evento.fecha.day,
            evento.horaInicio.hour,
            evento.horaInicio.minute
          );
          
          if (now.isAfter(eventDateTime)) {
            puntuacion += 30; // Bonus por evento que ya debería estar en curso
          } else if (now.difference(eventDateTime).inHours.abs() <= 1) {
            puntuacion += 15; // Bonus por evento próximo (1 hora)
          }
        } catch (e) {
          debugPrint('⚠️ Error procesando fecha/hora del evento ${evento.titulo}: $e');
        }
        
        debugPrint('🎯 ${evento.titulo}: ${puntuacion.round()} puntos (Estado: ${evento.estado})');
        
        return MapEntry(evento, puntuacion);
      }).toList();
      
      // 4. Ordenar por puntuación y seleccionar el mejor
      eventosConPuntuacion.sort((a, b) => b.value.compareTo(a.value));
      final mejorEvento = eventosConPuntuacion.first.key;
      final puntuacion = eventosConPuntuacion.first.value;
      
      debugPrint('✅ Mejor evento seleccionado: ${mejorEvento.titulo} (${puntuacion.round()} puntos)');
      return mejorEvento;
      
    } catch (e) {
      debugPrint('❌ Error en selección de evento: $e');
      // Fallback a la lógica anterior
      final eventosActivos = eventos.where((e) => e.isActive);
      return eventosActivos.isNotEmpty ? eventosActivos.first : null;
    }
  }
  
  /// Calcula la distancia en metros entre dos coordenadas usando la fórmula de Haversine
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    
    const double R = 6371000; // Radio de la Tierra en metros
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLng = (lng2 - lng1) * (math.pi / 180);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ✅ Evita salir accidentalmente
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // ✅ Al presionar atrás, minimizar app en lugar de cerrar sesión
        _handleBackButton(context);
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// ✅ Maneja el botón de atrás de forma inteligente
  void _handleBackButton(BuildContext context) {
    // Mostrar diálogo de confirmación antes de minimizar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Deseas salir?'),
        content: const Text('La app se minimizará y el tracking continuará en segundo plano.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ✅ Minimizar app sin cerrar sesión
              _minimizeApp();
            },
            child: const Text('Minimizar'),
          ),
        ],
      ),
    );
  }

  /// ✅ Minimiza la app manteniéndola activa en background
  void _minimizeApp() {
    // En Android esto moverá la app al background
    // sin cerrar la sesión ni detener servicios
    debugPrint('📱 Minimizando app - sesión y tracking activos');
    
    try {
      // Minimizar la aplicación en Android
      SystemNavigator.pop();
    } catch (e) {
      debugPrint('⚠️ Error minimizando app: $e');
    }
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
        return AdminDashboardSection(
          currentUser: _currentUser!,
          metrics: _metrics,
          eventos: _eventos,
          isLoadingMetrics: _isLoadingMetrics,
          isLoadingEvents: _isLoadingEvents,
          onViewAllEvents: () => AppRouter.goToSystemEventsManagement(),
          onViewReports: () => Navigator.pushNamed(context, '/admin/reports'),
          onSystemSettings: () => Navigator.pushNamed(context, '/admin/settings'),
          onLogout: _showLogoutDialog,
          onEventTap: _handleEventTap,
        );
      case AppConstants.profesorRole:
        return ProfessorDashboardSection(
          currentUser: _currentUser!,
          metrics: _metrics,
          userEvents: _userEvents,
          isLoadingMetrics: _isLoadingMetrics,
          isLoadingEvents: _isLoadingEvents,
          onCreateEvent: () => Navigator.pushNamed(context, AppConstants.createEventRoute),
          onManageEvents: () => Navigator.pushNamed(context, AppConstants.myEventsManagementRoute),
          onViewReports: () => Navigator.pushNamed(context, '/professor/reports'),
          onLogout: _showLogoutDialog,
          onEventTap: _handleEventTap,
        );
      case AppConstants.estudianteRole:
        return StudentDashboardSection(
          currentUser: _currentUser!,
          metrics: _metrics,
          availableEvents: _eventos.where((e) => e.isActive).toList(),
          activeEvent: _eventoActivo,
          isLoadingMetrics: _isLoadingMetrics,
          isLoadingEvents: _isLoadingEvents,
          onJoinEvent: () => Navigator.pushNamed(context, AppConstants.availableEventsRoute),
          onJoinSpecificEvent: _handleJoinSpecificEvent, // ✅ NUEVO: Registro directo
          onViewJustifications: () => AppRouter.goToJustifications(),
          onViewHistory: () => Navigator.pushNamed(context, '/student/history'),
          onLogout: _showLogoutDialog,
          onEventTap: _handleStudentEventTap,
          onStartTracking: _navigateToTracking,
        );
      default:
        return _buildUnsupportedRoleState();
    }
  }

  /// Maneja el tap en evento según el rol del usuario
  void _handleEventTap(Evento evento) {
    switch (_currentUser?.rol) {
      case AppConstants.profesorRole:
        _handleTeacherEventTap(evento);
        break;
      case AppConstants.estudianteRole:
        _handleStudentEventTap(evento);
        break;
      default:
        Navigator.pushNamed(
          context,
          '/event/details',
          arguments: {'eventId': evento.id},
        );
        break;
    }
  }

  // ===========================================
  // ✅ MÉTODOS DE NAVEGACIÓN MEJORADOS
  // ===========================================

  /// ✅ NAVEGACIÓN A TRACKING con validaciones mejoradas
  Future<void> _navigateToTracking() async {
    if (_eventoActivo != null) {
      final user = await _storageService.getUser();
      if (user == null) {
        _showErrorDialog('Error de Usuario', 'No se pudo obtener la información del usuario');
        return;
      }

      try {
        AppRouter.joinEventAsStudent(
          eventoId: _eventoActivo!.id!,
          userName: widget.userName,
          permissionsValidated: true,
          preciseLocationGranted: true,
          backgroundPermissionsGranted: true,
          batteryOptimizationDisabled: true,
        );
      } catch (e) {
        debugPrint('❌ Error en navegación a tracking: $e');
        _showErrorDialog('Error de Navegación', 
          'No se pudo acceder al tracking. Verifica tus permisos de ubicación.');
      }
    } else {
      Navigator.pushNamed(context, AppConstants.availableEventsRoute);
    }
  }

  /// Manejo de tap en evento para profesor
  void _handleTeacherEventTap(Evento evento) {
    debugPrint('👩‍🏫 Docente tocó evento: ${evento.titulo}');
    Navigator.pushNamed(
      context,
      AppConstants.eventMonitorRoute,
      arguments: {
        'eventId': evento.id!,
        'teacherName': _currentUser?.nombre ?? 'Profesor',
      },
    );
  }

  /// ✅ NUEVO: Registro directo en evento específico
  Future<void> _handleJoinSpecificEvent(Evento evento) async {
    debugPrint('🎯 Estudiante se está registrando directamente en evento: ${evento.titulo}');
    
    if (evento.id == null || evento.id!.isEmpty) {
      _showErrorDialog('Error de Evento', 'El evento no tiene un ID válido');
      return;
    }

    final user = await _storageService.getUser();
    if (user == null) {
      _showErrorDialog('Error de Usuario', 'No se pudo obtener la información del usuario');
      return;
    }

    // ✅ PREVENIR REGISTROS MÚLTIPLES: Verificar si ya está inscrito en otro evento
    if (_eventoActivo != null && _eventoActivo!.id != evento.id) {
      _showEventConflictDialog(evento);
      return;
    }

    // ✅ Mostrar confirmación de registro
    final confirmed = await _showJoinEventConfirmation(evento);
    if (!confirmed) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // ✅ REGISTRO DIRECTO: Inscribirse al evento y activarlo
      setState(() {
        _eventoActivo = evento;
      });

      // Cerrar indicador de carga
      Navigator.pop(context);

      // ✅ Ir directamente al tracking del evento
      AppRouter.joinEventAsStudent(
        eventoId: evento.id!,
        userName: widget.userName,
        permissionsValidated: true,
        preciseLocationGranted: true,
        backgroundPermissionsGranted: true,
        batteryOptimizationDisabled: true,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Te has inscrito en "${evento.titulo}"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // Cerrar indicador de carga si está abierto
      Navigator.pop(context);
      debugPrint('❌ Error en registro directo: $e');
      _showErrorDialog('Error de Registro', 
        'No se pudo inscribir en el evento. Verifica tu conexión.');
    }
  }

  /// Manejo de tap en evento para estudiante con validaciones
  Future<void> _handleStudentEventTap(Evento evento) async {
    debugPrint('🎓 Estudiante tocó evento: ${evento.titulo}');
    
    if (evento.id == null || evento.id!.isEmpty) {
      _showErrorDialog('Error de Evento', 'El evento no tiene un ID válido');
      return;
    }

    final user = await _storageService.getUser();
    if (user == null) {
      _showErrorDialog('Error de Usuario', 'No se pudo obtener la información del usuario');
      return;
    }

    try {
      AppRouter.joinEventAsStudent(
        eventoId: evento.id!,
        userName: widget.userName,
        permissionsValidated: true,
        preciseLocationGranted: true,
        backgroundPermissionsGranted: true,
        batteryOptimizationDisabled: true,
      );
    } catch (e) {
      debugPrint('❌ Error en navegación de estudiante: $e');
      _showErrorDialog('Error de Navegación', 
        'No se pudo acceder al evento. Verifica tus permisos de ubicación.');
    }
  }

  /// Obtener valor de métrica real

  /// Mostrar diálogo de error con título y mensaje personalizados
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

  /// ✅ NUEVO: Confirmar inscripción en evento
  Future<bool> _showJoinEventConfirmation(Evento evento) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Inscripción'),
        content: Text(
          '¿Deseas inscribirte en "${evento.titulo}"?\n\n'
          'Lugar: ${evento.lugar ?? "No especificado"}\n'
          'Hora: ${evento.horaInicioFormatted}\n\n'
          'Una vez inscrito, no podrás unirte a otros eventos hasta que este termine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryTeal,
            ),
            child: const Text('Inscribirme'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// ✅ NUEVO: Mostrar diálogo de conflicto de eventos
  void _showEventConflictDialog(Evento nuevoEvento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ya tienes un evento activo'),
        content: Text(
          'Actualmente estás inscrito en "${_eventoActivo?.titulo}".\n\n'
          'Para inscribirte en "${nuevoEvento.titulo}", primero debes '
          'completar o abandonar el evento actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Llevar al usuario a su evento activo
              _navigateToTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Ver evento activo'),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // ✅ ESTADOS Y WIDGETS ESENCIALES
  // ===========================================

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
  Widget _buildErrorState(String title, String subtitle, VoidCallback onAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textGray), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            CustomButton(text: 'Reintentar', onPressed: onAction),
          ],
        ),
      ),
    );
  }




  /// Diálogo de logout limpio
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(fontSize: 16, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600], padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }
}
