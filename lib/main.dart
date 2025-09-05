// lib/main.dart - FIREBASE MIGRATION
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';

// Firebase imports
import 'services/firebase/firebase_config.dart';
import 'services/firebase/firebase_auth_service.dart';
import 'services/firebase/firebase_evento_service.dart';
import 'services/firebase/firebase_asistencia_service.dart';
import 'services/firebase/firebase_messaging_service.dart';

// Importaciones principales del proyecto
import 'core/geo_assist_app.dart';
import 'services/background_service.dart';
import 'services/notifications/notification_manager.dart';
import 'services/permission_service.dart';
import 'utils/connectivity_manager.dart';
import 'services/student_attendance_manager.dart';
import 'services/location_service.dart';
import 'services/storage_service.dart';
import 'services/pre_registration_notification_service.dart';
import 'services/session_persistence_service.dart';

/// 🎯 CALLBACK DISPATCHER PARA WORKMANAGER
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      logger.d('🔄 [BACKGROUND] Ejecutando tarea: $task');

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
          logger.d('⚠️ [BACKGROUND] Tipo de tarea desconocido: $taskType');
      }

      return Future.value(true);
    } catch (e) {
      logger.d('❌ [BACKGROUND] Error en tarea $task: $e');
      return Future.value(false);
    }
  });
}

/// 🎯 HANDLERS DE TAREAS BACKGROUND
Future<void> _handleBackgroundTracking(String? eventId, String? userId) async {
  logger.d('📍 [BACKGROUND] Ejecutando tracking - Evento: $eventId');
}

Future<void> _handleBackgroundHeartbeat(String? eventId, String? userId) async {
  logger.d('💓 [BACKGROUND] Enviando heartbeat - Usuario: $userId');
}

Future<void> _handleBackgroundLocationUpdate(
    String? eventId, String? userId) async {
  logger.d('🌍 [BACKGROUND] Actualizando ubicación en background');
}

/// 🚀 FUNCIÓN MAIN CON INICIALIZACIÓN ASÍNCRONA
void main() async {
  // ✅ CONFIGURACIÓN INICIAL OBLIGATORIA
  WidgetsFlutterBinding.ensureInitialized();

  logger.d('🚀 Iniciando GeoAsist con servicios de Fase C...');

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

    logger.d('✅ Inicialización completa - Lanzando aplicación');

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
          
          // 🔥 FIREBASE SERVICES (PROVIDER SIMPLE)
          Provider<FirebaseAuthService>(
            create: (_) => FirebaseAuthService(),
            lazy: true,
          ),
          
          Provider<FirebaseEventoService>(
            create: (_) => FirebaseEventoService(),
            lazy: true,
          ),
          
          Provider<FirebaseAsistenciaService>(
            create: (_) => FirebaseAsistenciaService(),
            lazy: true,
          ),
          
          Provider<FirebaseMessagingService>(
            create: (_) => FirebaseMessagingService(),
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
    logger.d('❌ ERROR CRÍTICO durante inicialización: $e');
    logger.d('📋 StackTrace: $stackTrace');

    // En caso de error crítico, lanzar app básica con providers mínimos
    logger.d('⚠️ Iniciando en modo de recuperación con providers básicos...');
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
  logger.d('🔧 Inicializando servicios críticos...');

  try {
    // 1. 🔥 FIREBASE CORE (PRIMER SERVICIO)
    logger.d('🔥 Inicializando Firebase...');
    await FirebaseConfig.initialize();
    logger.d('✅ Firebase inicializado');

    // 2. 📱 NOTIFICATION MANAGER (SEGUNDO SERVICIO)
    logger.d('📱 Inicializando NotificationManager...');
    final notificationManager = NotificationManager();
    await notificationManager.initialize();
    logger.d('✅ NotificationManager inicializado');

    // 3. 🔋 BACKGROUND SERVICE (INCLUYE WORKMANAGER)
    logger.d('🔋 Inicializando BackgroundService...');
    final backgroundService = BackgroundService();
    await backgroundService.initialize();
    logger.d('✅ BackgroundService inicializado');

    // 4. 🎯 STUDENT ATTENDANCE MANAGER (INICIALIZACIÓN TEMPRANA)
    logger.d('🎯 Inicializando StudentAttendanceManager...');
    final attendanceManager = StudentAttendanceManager();
    await attendanceManager.initialize(autoStart: false); // No auto start en main
    logger.d('✅ StudentAttendanceManager inicializado');

    logger.d('✅ Servicios críticos inicializados correctamente');
  } catch (e) {
    logger.d('❌ Error en servicios críticos: $e');
    logger.d('⚠️ Iniciando en modo de recuperación con providers básicos...');
    // No relanzar - permitir que la app funcione en modo de recuperación
  }
}

/// 🎯 INICIALIZAR SERVICIOS SECUNDARIOS (OPCIONALES)
Future<void> _initializeSecondaryServices() async {
  logger.d('🔧 Inicializando servicios secundarios...');

  try {
    // 1. 🌐 CONNECTIVITY MANAGER
    logger.d('🌐 Inicializando ConnectivityManager...');
    final connectivityManager = ConnectivityManager();
    await connectivityManager.initialize();
    logger.d('✅ ConnectivityManager inicializado');

    // 2. 📝 PRE-REGISTRATION NOTIFICATION SERVICE
    logger.d('📝 Inicializando PreRegistrationNotificationService...');
    final preRegService = PreRegistrationNotificationService();
    await preRegService.initialize();
    logger.d('✅ PreRegistrationNotificationService inicializado');

    // 3. 💾 SESSION PERSISTENCE SERVICE
    logger.d('💾 Inicializando SessionPersistenceService...');
    final sessionPersistenceService = SessionPersistenceService();
    await sessionPersistenceService.initialize();
    logger.d('✅ SessionPersistenceService inicializado');

    // 4. 🔐 PERMISSION SERVICE (VALIDACIÓN INICIAL)
    logger.d('🔐 Validando permisos básicos...');
    final permissionService = PermissionService();

    // Solo verificar permisos básicos, no forzar solicitud
    final hasBasicPermissions =
        await permissionService.hasLocationPermissions();
    logger.d(
        '📍 Permisos básicos de ubicación: ${hasBasicPermissions ? "✅" : "⚠️"}');

    if (!hasBasicPermissions) {
      logger.d('⚠️ Permisos de ubicación pendientes - se solicitarán en uso');
    }

    logger.d('✅ Servicios secundarios inicializados correctamente');
  } catch (e) {
    logger.d('⚠️ Error en servicios secundarios (no crítico): $e');
    // No relanzar error - los servicios secundarios son opcionales
  }
}

// GeoAssistApp ahora está definido en lib/core/geo_assist_app.dart
