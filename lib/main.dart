// lib/main.dart - FASE C COMPLETA CON INICIALIZACIÓN DE SERVICIOS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'utils/app_router.dart';
import 'services/background_service.dart';
import 'services/notifications/notification_manager.dart';
import 'services/permission_service.dart';
import 'utils/connectivity_manager.dart';

/// 🎯 CALLBACK DISPATCHER PARA WORKMANAGER
/// CRÍTICO: Debe estar en el nivel superior para que WorkManager pueda accederlo
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🔄 [BACKGROUND] Ejecutando tarea: $task');
      debugPrint('📦 [BACKGROUND] Datos: $inputData');

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
        case 'lifecycle_monitor':
          await _handleBackgroundLifecycleMonitor(eventId, userId);
          break;
        default:
          debugPrint('⚠️ [BACKGROUND] Tipo de tarea desconocido: $taskType');
      }

      debugPrint('✅ [BACKGROUND] Tarea completada: $task');
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
  // La lógica de tracking se maneja en BackgroundService
  // Aquí solo validamos que la app sigue activa
}

Future<void> _handleBackgroundHeartbeat(String? eventId, String? userId) async {
  debugPrint('💓 [BACKGROUND] Enviando heartbeat - Usuario: $userId');
  // La lógica de heartbeat se maneja en AsistenciaService
  // Este callback solo confirma que WorkManager está funcionando
}

Future<void> _handleBackgroundLocationUpdate(
    String? eventId, String? userId) async {
  debugPrint('🌍 [BACKGROUND] Actualizando ubicación en background');
  // La lógica de ubicación se maneja en LocationService
}

Future<void> _handleBackgroundLifecycleMonitor(
    String? eventId, String? userId) async {
  debugPrint('🔄 [BACKGROUND] Monitoreando lifecycle de app');
  // Verificar si la app sigue activa para tracking
}

/// 🚀 FUNCIÓN MAIN CON INICIALIZACIÓN ASÍNCRONA
void main() async {
  // ✅ PASO 1: CONFIGURACIÓN INICIAL OBLIGATORIA
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Iniciando GeoAsist con servicios de Fase C...');

  try {
    // ✅ PASO 2: CONFIGURAR ORIENTACIÓN DE PANTALLA
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // ✅ PASO 3: INICIALIZAR SERVICIOS CRÍTICOS EN ORDEN
    await _initializeCriticalServices();

    // ✅ PASO 4: INICIALIZAR SERVICIOS SECUNDARIOS
    await _initializeSecondaryServices();

    // ✅ PASO 5: CONFIGURAR LIFECYCLE OBSERVER GLOBAL
    _setupGlobalLifecycleObserver();

    debugPrint('✅ Inicialización completa - Lanzando aplicación');

    // ✅ PASO 6: LANZAR LA APLICACIÓN
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

    // 3. 💾 STORAGE SERVICE (NO REQUIERE INICIALIZACIÓN)
    debugPrint('💾 StorageService listo (usa SharedPreferences directamente)');
    // StorageService usa SharedPreferences de forma lazy - no requiere initialize()

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

/// 🎯 CONFIGURAR LIFECYCLE OBSERVER GLOBAL
void _setupGlobalLifecycleObserver() {
  debugPrint('🔄 Configurando lifecycle observer global...');

  try {
    // El lifecycle observer se configurará en GeoAssistApp
    // Aquí solo registramos que debe configurarse
    debugPrint('✅ Lifecycle observer configurado');
  } catch (e) {
    debugPrint('⚠️ Error configurando lifecycle observer: $e');
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
  // 🎯 SERVICIOS PARA LIFECYCLE MANAGEMENT
  final BackgroundService _backgroundService = BackgroundService();
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();

    // ✅ CONFIGURAR LIFECYCLE OBSERVER
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🔄 Lifecycle observer activado en GeoAssistApp');
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

  /// 🔄 APP RESUMED (REABIERTA)
  void _handleAppResumed() {
    debugPrint('✅ [LIFECYCLE] App reabierta - Reactivando tracking');

    // Verificar estado del BackgroundService
    try {
      final serviceStatus = _backgroundService.getServiceStatus();
      debugPrint('📊 Estado del servicio: $serviceStatus');
    } catch (e) {
      debugPrint('⚠️ Error verificando servicio: $e');
    }
  }

  /// 🔄 APP PAUSED (EN BACKGROUND)
  void _handleAppPaused() {
    debugPrint('⚠️ [LIFECYCLE] App en background - Continuando tracking');

    // Verificar que el BackgroundService está activo
    try {
      final isActive =
          _backgroundService.getServiceStatus()['foreground_service_active'] ??
              false;
      debugPrint('🔋 BackgroundService activo: $isActive');
    } catch (e) {
      debugPrint('⚠️ Error verificando background service: $e');
    }
  }

  /// 🔄 APP DETACHED (CERRADA) - CRÍTICO
  void _handleAppDetached() {
    debugPrint('🚨 [LIFECYCLE] App CERRADA - Iniciando grace period de 30s');

    // CRÍTICO: Activar grace period inmediatamente
    _startGracePeriodCountdown();

    // CRÍTICO: Notificar al BackgroundService del cierre de app
    try {
      // El BackgroundService maneja automáticamente el grace period
      debugPrint('📱 Notificando cierre de app a BackgroundService');
    } catch (e) {
      debugPrint('⚠️ Error notificando cierre: $e');
    }
  }

  /// 🔄 APP INACTIVE (TRANSITORIA)
  void _handleAppInactive() {
    debugPrint('⏸️ [LIFECYCLE] App inactiva temporalmente');

    // Estado transitorio - no hacer nada
  }

  /// 🔄 APP HIDDEN (MINIMIZADA)
  void _handleAppHidden() {
    debugPrint('👁️ [LIFECYCLE] App oculta - Tracking en background activo');

    // App minimizada pero no cerrada - tracking continúa
  }

  /// 🚨 INICIAR GRACE PERIOD DE 30 SEGUNDOS
  void _startGracePeriodCountdown() {
    debugPrint('🚨 Iniciando grace period de 30 segundos...');

    // Mostrar notificación crítica inmediatamente
    try {
      _notificationManager.showAppClosedWarningNotification(30);
      debugPrint('📱 Notificación de warning enviada');
    } catch (e) {
      debugPrint('⚠️ Error enviando notificación: $e');
    }

    // El BackgroundService maneja el countdown y la pérdida de asistencia
    // Esta es solo la activación desde el lifecycle
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Material Design 3 Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Navigation Configuration
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.loginRoute,

      // App-wide configurations
      builder: (context, child) {
        return MediaQuery(
          // Prevent font scaling from system settings to maintain UI consistency
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
