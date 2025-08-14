// lib/main.dart - CORREGIDO SIN ERRORES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

// Importaciones principales del proyecto
import 'core/app_constants.dart';
import 'utils/app_router.dart';
import 'utils/colors.dart';
import 'services/background_service.dart';
import 'services/notifications/notification_manager.dart';
import 'services/permission_service.dart';
import 'utils/connectivity_manager.dart';
import 'services/student_attendance_manager.dart';

/// 🎯 CALLBACK DISPATCHER PARA WORKMANAGER
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🔄 [BACKGROUND] Ejecutando tarea: $task');

      final taskType = inputData?['task_type'] as String?;
      final eventId = inputData?['event_id'] as String?;
      final userId = inputData?['user_id'] as String?;

      switch (taskType) {
        case 'tracking':
          await _handleBackgroundTracking(eventId, userId);
          break;
        case 'heartbeat':
          await _handleBackgroundHeartbeat(eventId, userId);
          break;
        case 'location_update':
          await _handleBackgroundLocationUpdate(eventId, userId);
          break;
        default:
          debugPrint('⚠️ [BACKGROUND] Tipo de tarea desconocido: $taskType');
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('❌ [BACKGROUND] Error en tarea $task: $e');
      return Future.value(false);
    }
  });
}

/// 🎯 HANDLERS DE TAREAS BACKGROUND
Future<void> _handleBackgroundTracking(String? eventId, String? userId) async {
  debugPrint('📍 [BACKGROUND] Ejecutando tracking - Evento: $eventId');
}

Future<void> _handleBackgroundHeartbeat(String? eventId, String? userId) async {
  debugPrint('💓 [BACKGROUND] Enviando heartbeat - Usuario: $userId');
}

Future<void> _handleBackgroundLocationUpdate(
    String? eventId, String? userId) async {
  debugPrint('🌍 [BACKGROUND] Actualizando ubicación en background');
}

/// 🚀 FUNCIÓN MAIN CON INICIALIZACIÓN ASÍNCRONA
void main() async {
  // ✅ CONFIGURACIÓN INICIAL OBLIGATORIA
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Iniciando GeoAsist con servicios de Fase C...');

  try {
    // ✅ CONFIGURAR ORIENTACIÓN DE PANTALLA
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // ✅ INICIALIZAR SERVICIOS CRÍTICOS EN ORDEN
    await _initializeCriticalServices();

    // ✅ INICIALIZAR SERVICIOS SECUNDARIOS
    await _initializeSecondaryServices();

    debugPrint('✅ Inicialización completa - Lanzando aplicación');

    // ✅ LANZAR LA APLICACIÓN
    runApp(const GeoAssistApp());
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR CRÍTICO durante inicialización: $e');
    debugPrint('📋 StackTrace: $stackTrace');

    // En caso de error crítico, lanzar app básica sin servicios avanzados
    debugPrint('⚠️ Iniciando en modo de recuperación...');
    runApp(const GeoAssistApp());
  }
}

/// 🎯 INICIALIZAR SERVICIOS CRÍTICOS (OBLIGATORIOS)
Future<void> _initializeCriticalServices() async {
  debugPrint('🔧 Inicializando servicios críticos...');

  try {
    // 1. 📱 NOTIFICATION MANAGER (PRIMER SERVICIO)
    debugPrint('📱 Inicializando NotificationManager...');
    final notificationManager = NotificationManager();
    await notificationManager.initialize();
    debugPrint('✅ NotificationManager inicializado');

    // 2. 🔋 BACKGROUND SERVICE (INCLUYE WORKMANAGER)
    debugPrint('🔋 Inicializando BackgroundService...');
    final backgroundService = BackgroundService();
    await backgroundService.initialize();
    debugPrint('✅ BackgroundService inicializado');

    debugPrint('✅ Servicios críticos inicializados correctamente');
  } catch (e) {
    debugPrint('❌ Error en servicios críticos: $e');
    rethrow;
  }
}

/// 🎯 INICIALIZAR SERVICIOS SECUNDARIOS (OPCIONALES)
Future<void> _initializeSecondaryServices() async {
  debugPrint('🔧 Inicializando servicios secundarios...');

  try {
    // 1. 🌐 CONNECTIVITY MANAGER
    debugPrint('🌐 Inicializando ConnectivityManager...');
    final connectivityManager = ConnectivityManager();
    await connectivityManager.initialize();
    debugPrint('✅ ConnectivityManager inicializado');

    // 2. 🔐 PERMISSION SERVICE (VALIDACIÓN INICIAL)
    debugPrint('🔐 Validando permisos básicos...');
    final permissionService = PermissionService();

    // Solo verificar permisos básicos, no forzar solicitud
    final hasBasicPermissions =
        await permissionService.hasLocationPermissions();
    debugPrint(
        '📍 Permisos básicos de ubicación: ${hasBasicPermissions ? "✅" : "⚠️"}');

    if (!hasBasicPermissions) {
      debugPrint('⚠️ Permisos de ubicación pendientes - se solicitarán en uso');
    }

    debugPrint('✅ Servicios secundarios inicializados correctamente');
  } catch (e) {
    debugPrint('⚠️ Error en servicios secundarios (no crítico): $e');
    // No relanzar error - los servicios secundarios son opcionales
  }
}

/// 🎯 WIDGET PRINCIPAL DE LA APLICACIÓN
class GeoAssistApp extends StatefulWidget {
  const GeoAssistApp({super.key});

  @override
  State<GeoAssistApp> createState() => _GeoAssistAppState();
}

/// 🎯 STATE DE LA APLICACIÓN CON LIFECYCLE OBSERVER
class _GeoAssistAppState extends State<GeoAssistApp>
    with WidgetsBindingObserver {
  // ✅ FASE 3: REFERENCIA AL STUDENTATTENDANCEMANAGER
  StudentAttendanceManager? _attendanceManager;

  @override
  void initState() {
    super.initState();

    // ✅ CONFIGURAR LIFECYCLE OBSERVER
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🔄 Lifecycle observer activado en GeoAssistApp');

    // ✅ FASE 3: INICIALIZAR REFERENCIA AL STUDENTATTENDANCEMANAGER
    _initializeAttendanceManagerReference();
  }

  // ✅ FASE 3: NUEVO MÉTODO - Obtener referencia al StudentAttendanceManager
  void _initializeAttendanceManagerReference() {
    try {
      // Obtener la instancia singleton del StudentAttendanceManager
      _attendanceManager = StudentAttendanceManager();
      debugPrint('✅ Referencia a StudentAttendanceManager inicializada');
    } catch (e) {
      debugPrint('⚠️ Error inicializando referencia AttendanceManager: $e');
    }
  }

  @override
  void dispose() {
    // ✅ LIMPIAR LIFECYCLE OBSERVER
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔄 Lifecycle observer desactivado');
    super.dispose();
  }

  /// 🎯 DETECTOR DE CAMBIOS DE LIFECYCLE (CRÍTICO PARA FASE C)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('🔄 [LIFECYCLE] Cambio detectado: $state');

    // ✅ FASE 3 CRÍTICO: CONECTAR CON STUDENTATTENDANCEMANAGER
    if (_attendanceManager != null) {
      _attendanceManager!.handleAppLifecycleChange(state);
      debugPrint('📱 Lifecycle enviado a StudentAttendanceManager');
    } else {
      debugPrint('⚠️ StudentAttendanceManager no disponible para lifecycle');
    }

    // ✅ MANTENER: Métodos existentes para logging y debugging
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// 🔄 APP RESUMED (REABIERTA) - LOGGING ADICIONAL
  void _handleAppResumed() {
    debugPrint('✅ [LIFECYCLE] App reabierta - Reactivando tracking');

    try {
      // ✅ FASE 3: Confirmar que AttendanceManager recibió el evento
      if (_attendanceManager != null) {
        final attendanceState = _attendanceManager!.currentState;
        debugPrint(
            '📱 Estado AttendanceManager: ${attendanceState.trackingStatus}');
        debugPrint('⏰ Grace period activo: ${attendanceState.isInGracePeriod}');
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando servicio: $e');
    }
  }

  /// 🔄 APP PAUSED (EN BACKGROUND) - LOGGING ADICIONAL
  void _handleAppPaused() {
    debugPrint('⚠️ [LIFECYCLE] App en background - Continuando tracking');

    try {
      // ✅ FASE 3: Logging del estado de AttendanceManager
      if (_attendanceManager != null) {
        final isTracking = _attendanceManager!.currentState.trackingStatus;
        debugPrint('📱 AttendanceManager tracking: $isTracking');
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando background service: $e');
    }
  }

  /// 🔄 APP DETACHED (CERRADA) - CRÍTICO PARA FASE 3
  void _handleAppDetached() {
    debugPrint(
        '🚨 [LIFECYCLE] App CERRADA - Grace period iniciado automáticamente');

    // ✅ FASE 3: Confirmar que AttendanceManager recibió el evento crítico
    if (_attendanceManager != null) {
      final attendanceState = _attendanceManager!.currentState;
      debugPrint('📱 Estado post-detached: ${attendanceState.trackingStatus}');
      debugPrint('⏰ Grace period iniciado: ${attendanceState.isInGracePeriod}');
      debugPrint(
          '⏱️ Segundos restantes: ${attendanceState.gracePeriodRemaining}');
    } else {
      debugPrint('❌ CRÍTICO: AttendanceManager no disponible durante detached');
    }
  }

  /// 🔄 APP INACTIVE (TRANSITORIA)
  void _handleAppInactive() {
    debugPrint('⏸️ [LIFECYCLE] App inactiva temporalmente');

    // ✅ FASE 3: Estado transitorio - solo logging
    if (_attendanceManager != null) {
      final isTracking = _attendanceManager!.currentState.trackingStatus;
      debugPrint('📱 Tracking durante inactive: $isTracking');
    }
  }

  /// 🔄 APP HIDDEN (MINIMIZADA)
  void _handleAppHidden() {
    debugPrint('👁️ [LIFECYCLE] App oculta - Tracking en background activo');

    // ✅ FASE 3: Confirmar estado durante hidden
    if (_attendanceManager != null) {
      final isTracking = _attendanceManager!.currentState.trackingStatus;
      debugPrint('📱 Tracking durante hidden: $isTracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Navegación
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.loginRoute,

      // Tema
      theme: ThemeData(
        primarySwatch: _createMaterialColor(AppColors.primaryOrange),
        primaryColor: AppColors.primaryOrange,
        scaffoldBackgroundColor: AppColors.lightGray,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // Builder para configuraciones globales
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }

  // Helper para crear Material Color
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor((r << 16) | (g << 8) | b | 0xFF000000, swatch);
  }
}
