// lib/main.dart - CORREGIDO SIN ERRORES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';

// Importaciones principales del proyecto
import 'core/geo_assist_app.dart';
import 'services/background_service.dart';
import 'services/notifications/notification_manager.dart';
import 'services/permission_service.dart';
import 'utils/connectivity_manager.dart';
import 'services/student_attendance_manager.dart';
import 'services/location_service.dart';
import 'services/storage_service.dart';
import 'services/asistencia_service.dart';
import 'services/evento_service.dart';

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

    // ✅ LANZAR LA APLICACIÓN CON MULTIPROVIDER
    runApp(
      MultiProvider(
        providers: [
          // 📱 CORE ATTENDANCE MANAGER (PROVIDER SIMPLE - NO ES CHANGENOTIFIER)
          Provider<StudentAttendanceManager>(
            create: (_) => StudentAttendanceManager(),
            lazy: false, // Inicializar inmediatamente para tests
          ),
          
          // 📢 NOTIFICATION MANAGER (PROVIDER SIMPLE - NO ES CHANGENOTIFIER)
          Provider<NotificationManager>(
            create: (_) => NotificationManager(),
            lazy: false,
          ),
          
          // 🌐 CONNECTIVITY MANAGER (PROVIDER SIMPLE - NO ES CHANGENOTIFIER) 
          Provider<ConnectivityManager>(
            create: (_) => ConnectivityManager(),
            lazy: false,
          ),
          
          // 📍 LOCATION SERVICE (PROVIDER SIMPLE)
          Provider<LocationService>(
            create: (_) => LocationService(),
            lazy: false,
          ),
          
          // 💾 STORAGE SERVICE (PROVIDER SIMPLE)
          Provider<StorageService>(
            create: (_) => StorageService(),
            lazy: false,
          ),
          
          // 🔋 BACKGROUND SERVICE (PROVIDER SIMPLE)
          Provider<BackgroundService>(
            create: (_) => BackgroundService(),
            lazy: false,
          ),
          
          // 🔌 API SERVICES (PROVIDER SIMPLE)
          Provider<AsistenciaService>(
            create: (_) => AsistenciaService(),
            lazy: true,
          ),
          
          Provider<EventoService>(
            create: (_) => EventoService(),
            lazy: true,
          ),
          
          Provider<PermissionService>(
            create: (_) => PermissionService(),
            lazy: true,
          ),
        ],
        child: const GeoAssistApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR CRÍTICO durante inicialización: $e');
    debugPrint('📋 StackTrace: $stackTrace');

    // En caso de error crítico, lanzar app básica con providers mínimos
    debugPrint('⚠️ Iniciando en modo de recuperación con providers básicos...');
    runApp(
      MultiProvider(
        providers: [
          // Providers mínimos para recuperación
          Provider<StudentAttendanceManager>(
            create: (_) => StudentAttendanceManager(),
            lazy: false,
          ),
          Provider<NotificationManager>(
            create: (_) => NotificationManager(),
            lazy: false,
          ),
        ],
        child: const GeoAssistApp(),
      ),
    );
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

// GeoAssistApp ahora está definido en lib/core/geo_assist_app.dart
