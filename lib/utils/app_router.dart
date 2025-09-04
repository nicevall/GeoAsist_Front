// lib/utils/app_router.dart - VERSIÓN CORREGIDA CON NAVEGACIÓN UNIFICADA
import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/map_view/map_view_screen.dart';
import '../screens/create_professor_screen.dart';
import '../screens/dashboard_screen.dart'; // ✅ DASHBOARD UNIFICADO
import '../screens/professor_management_screen.dart';
import '../screens/create_event_screen.dart';
import '../services/storage_service.dart';
import '../models/evento_model.dart';
import '../screens/available_events_screen.dart';
import '../screens/attendance/attendance_tracking_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/events/event_monitor_screen.dart';
import '../screens/justifications/justifications_screen.dart';
import '../screens/justifications/create_justification_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/my_events_management_screen.dart';
import '../screens/admin/system_events_management_screen.dart';
import '../screens/firebase/simple_firebase_test_screen.dart';

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  // Global key for navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Storage service for user data
  static final StorageService _storageService = StorageService();

  // Simple route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppConstants.registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppConstants.mapViewRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MapViewScreen(
            isAdminMode: args?['isAdminMode'] ?? false,
            userName: args?['userName'] ?? 'Usuario',
            eventoId: args?['eventoId'],
            isStudentMode: args?['isStudentMode'] ?? false,
            // ✅ AGREGAR: Parámetros de validación
            permissionsValidated: args?['permissionsValidated'],
            preciseLocationGranted: args?['preciseLocationGranted'],
            backgroundPermissionsGranted: args?['backgroundPermissionsGranted'],
            batteryOptimizationDisabled: args?['batteryOptimizationDisabled'],
          ),
        );

      // ✅ DASHBOARD UNIFICADO PARA TODOS LOS ROLES
      case AppConstants.dashboardRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userName: args?['userName'] ?? 'Usuario',
          ),
        );

      // ✅ ESTUDIANTE - REDIRIGIR AL DASHBOARD UNIFICADO
      case AppConstants.studentDashboardRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userName: args?['userName'] ?? 'Usuario',
          ),
        );

      case AppConstants.eventMonitorRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final teacherName = args?['teacherName'] as String?;

        if (eventId == null || teacherName == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Error: Faltan parámetros para monitorear evento'),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => EventMonitorScreen(
            eventId: eventId,
            teacherName: teacherName,
          ),
        );

      // ✅ ENHANCED: Attendance Tracking con validación de parámetros
      case AppConstants.attendanceTrackingRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        
        // Validar parámetros críticos
        final eventoId = args?['eventoId'] as String?;
        final userName = args?['userName'] as String?;
        
        if (eventoId == null || eventoId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'ID de evento requerido para tracking',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => goToDashboard(),
                      child: const Text('Volver al Dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        return MaterialPageRoute(
          builder: (_) => AttendanceTrackingScreen(
            userName: userName ?? 'Usuario',
            eventoId: eventoId,
          ),
        );

      case AppConstants.createProfessorRoute:
        return MaterialPageRoute(builder: (_) => const CreateProfessorScreen());

      case AppConstants.professorManagementRoute:
        return MaterialPageRoute(
            builder: (_) => const ProfessorManagementScreen());

      case AppConstants.availableEventsRoute:
        return MaterialPageRoute(builder: (_) => const AvailableEventsScreen());

      case AppConstants.createEventRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateEventScreen(
            editEvent: args?['editEvent'] as Evento?,
          ),
        );

      case AppConstants.eventManagementRoute:
        return MaterialPageRoute(
          builder: (_) => const CreateEventScreen(),
        );

      case AppConstants.eventDetailsRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventoId = args?['eventoId'] as String?;
        if (eventoId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('ID de evento requerido')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) {
              final teacherName = snapshot.data ?? 'Profesor';
              return EventMonitorScreen(
                eventId: eventoId,
                teacherName: teacherName,
              );
            },
          ),
        );

      case AppConstants.locationPickerRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLatitude: args?['initialLatitude'] ?? -0.1805,
            initialLongitude: args?['initialLongitude'] ?? -78.4680,
            initialRange: args?['initialRange'] ?? 100.0,
            initialLocationName:
                args?['initialLocationName'] ?? 'UIDE Campus Principal',
          ),
        );

      // 📄 JUSTIFICATIONS ROUTES
      case AppConstants.justificationsRoute:
        return MaterialPageRoute(
          builder: (_) => const JustificationsScreen(),
        );

      case AppConstants.submitJustificationRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateJustificationScreen(
            eventoId: args?['eventoId'] as String?,
          ),
        );

      // ⚙️ NOTIFICATION SETTINGS ROUTE
      case AppConstants.notificationSettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );
      
      // 🔥 FIREBASE TEST ROUTE
      case AppConstants.firebaseTestRoute:
        return MaterialPageRoute(
          builder: (_) => SimpleFirebaseTestScreen(),
        );

      // ✅ NUEVAS RUTAS PARA ADMINISTRACIÓN Y PROFESORES
      case AppConstants.reportsRoute:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(), // Usar dashboard que ya tiene reportes
        );

      case AppConstants.allMyEventsRoute:
        return MaterialPageRoute(
          builder: (_) => const AvailableEventsScreen(), // Usar pantalla de eventos disponibles
        );

      case AppConstants.myEventsManagementRoute:
        return MaterialPageRoute(
          builder: (_) => const MyEventsManagementScreen(),
        );

      case AppConstants.adminUsersRoute:
        return MaterialPageRoute(
          builder: (_) => const ProfessorManagementScreen(),
        );

      case AppConstants.adminEventsRoute:
        return MaterialPageRoute(
          builder: (_) => const SystemEventsManagementScreen(), // ✅ PANTALLA ESPECÍFICA PARA ADMIN
        );

      case AppConstants.systemEventsViewRoute: // ✅ USAR CONSTANTE
        return MaterialPageRoute(
          builder: (_) => const AvailableEventsScreen(), // Solo ver eventos
        );

      case AppConstants.adminStatsRoute:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(), // Usar dashboard que ya tiene estadísticas
        );

      default:
        return MaterialPageRoute(
          builder: (_) => FutureBuilder<bool>(
            future: isAuthenticated,
            builder: (context, snapshot) {
              final isAuth = snapshot.data ?? false;
              
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Página no encontrada: ${settings.name}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (isAuth) {
                            // Si está autenticado, volver al dashboard
                            goToDashboard();
                          } else {
                            // Solo ir al login si NO está autenticado
                            Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
                          }
                        },
                        child: Text(isAuth ? 'Volver al Dashboard' : 'Ir al Login'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
    }
  }

  // ✅ MÉTODOS DE NAVEGACIÓN CORREGIDOS

  /// Navegar al login
  static void goToLogin() {
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed(AppConstants.loginRoute);
  }

  /// Navegar al registro
  static void goToRegister() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.registerRoute);
  }

  /// ✅ DASHBOARD UNIFICADO PARA ADMIN Y DOCENTE
  static void goToDashboard({String userName = 'Usuario'}) {
    Navigator.of(navigatorKey.currentContext!).pushReplacementNamed(
      AppConstants.dashboardRoute,
      arguments: {'userName': userName},
    );
  }

  /// ✅ SIMPLIFICADO: Todos van al mismo dashboard
  static void goToStudentDashboard({String userName = 'Usuario'}) {
    goToDashboard(userName: userName); // ✅ Llama al método unificado
  }

  /// ✅ NUEVO: Navegar a tracking especializado
  static void goToAttendanceTracking({
    String userName = 'Usuario',
    String? eventoId,
  }) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.attendanceTrackingRoute,
      arguments: {
        'userName': userName,
        if (eventoId != null) 'eventoId': eventoId,
      },
    );
  }

  /// ✅ NUEVO: Navegar a monitor de eventos (para profesors)
  static void goToEventMonitor({
    required String eventId,
    required String teacherName,
  }) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.eventMonitorRoute,
      arguments: {
        'eventId': eventId,
        'teacherName': teacherName,
      },
    );
  }

  /// Navegar al map view
  static void goToMapView({
    bool isAdminMode = false,
    bool isStudentMode = false,
    String userName = 'Usuario',
    String? eventoId,
  }) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.mapViewRoute,
      arguments: {
        'isAdminMode': isAdminMode,
        'isStudentMode': isStudentMode,
        'userName': userName,
        if (eventoId != null) 'eventoId': eventoId,
      },
    );
  }

  /// Gestión de profesores
  static void goToCreateProfessor() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.createProfessorRoute);
  }

  static void goToProfessorManagement() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.professorManagementRoute);
  }

  /// ✅ NAVEGACIÓN DE EVENTOS
  static void goToCreateEvent({Evento? editEvent}) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.createEventRoute,
      arguments: {'editEvent': editEvent},
    );
  }

  static void goToAvailableEvents() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.availableEventsRoute);
  }

  static void goToEventManagement() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.eventManagementRoute);
  }

  static void goToEventDetails(String eventoId) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.eventDetailsRoute,
      arguments: {'eventoId': eventoId},
    );
  }

  /// 📊 NAVEGACIÓN REAL PARA ADMINISTRACIÓN
  static void goToUserManagement() {
    navigatorKey.currentState?.pushNamed(AppConstants.adminUsersRoute);
  }

  static void goToSystemEvents() {
    navigatorKey.currentState?.pushNamed(AppConstants.systemEventsViewRoute); // ✅ USAR CONSTANTE
  }

  static void goToSystemEventsManagement() {
    navigatorKey.currentState?.pushNamed(AppConstants.adminEventsRoute); // ✅ GESTIÓN COMPLETA
  }

  static void goToAdvancedStats() {
    navigatorKey.currentState?.pushNamed(AppConstants.adminStatsRoute);
  }

  static void goToSystemAlerts() {
    goToNotificationSettings(); // Usa la pantalla de configuración de notificaciones
  }

  static void goToSystemConfig() {
    goToNotificationSettings(); // Configuración del sistema
  }

  /// 📊 NAVEGACIÓN PARA PROFESORES
  static void navigateToReports() {
    navigatorKey.currentState?.pushNamed(AppConstants.reportsRoute);
  }

  static void navigateToAllMyEvents() {
    navigatorKey.currentState?.pushNamed(AppConstants.allMyEventsRoute);
  }

  static void navigateToMyEventsManagement() {
    navigatorKey.currentState?.pushNamed(AppConstants.myEventsManagementRoute);
  }

  /// 📄 NAVEGACIÓN DE JUSTIFICACIONES
  static void goToJustifications() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.justificationsRoute);
  }

  static void goToCreateJustification({String? eventoId}) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.submitJustificationRoute,
      arguments: {'eventoId': eventoId},
    );
  }

  /// ⚙️ NAVEGACIÓN DE CONFIGURACIONES
  static void goToNotificationSettings() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.notificationSettingsRoute);
  }
  
  /// 🔥 NAVEGACIÓN FIREBASE
  static void goToFirebaseTest() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.firebaseTestRoute);
  }

  /// ✅ ENHANCED: Helper para navegación de asistencia con validación
  static void goToAttendanceTrackingEnhanced({
    required String eventoId,
    required String userName,
  }) {
    if (eventoId.isEmpty) {
      showSnackBar('ID de evento requerido para tracking', isError: true);
      return;
    }
    
    navigatorKey.currentState?.pushNamed(
      AppConstants.attendanceTrackingRoute,
      arguments: {
        'eventoId': eventoId,
        'userName': userName,
      },
    );
  }

  /// ✅ ENHANCED: Helper para join event directo con validaciones
  static void joinEventAsStudent({
    required String eventoId,
    required String userName,
    bool permissionsValidated = false,
    bool preciseLocationGranted = false,
    bool backgroundPermissionsGranted = false,
    bool batteryOptimizationDisabled = false,
  }) {
    if (eventoId.isEmpty) {
      showSnackBar('ID de evento requerido', isError: true);
      return;
    }

    navigatorKey.currentState?.pushNamed(
      AppConstants.mapViewRoute,
      arguments: {
        'isStudentMode': true,
        'userName': userName,
        'eventoId': eventoId,
        'isAdminMode': false,
        'permissionsValidated': permissionsValidated,
        'preciseLocationGranted': preciseLocationGranted,
        'backgroundPermissionsGranted': backgroundPermissionsGranted,
        'batteryOptimizationDisabled': batteryOptimizationDisabled,
      },
    );
  }

  /// ✅ ENHANCED: Helper para ir a MapView con todos los parámetros
  static void goToMapViewWithValidations({
    required String eventoId,
    required String userName,
    required bool isStudentMode,
    required bool isAdminMode,
    bool permissionsValidated = true,
    bool preciseLocationGranted = true,
    bool backgroundPermissionsGranted = true,
    bool batteryOptimizationDisabled = true,
  }) {
    navigatorKey.currentState?.pushNamed(
      AppConstants.mapViewRoute,
      arguments: {
        'isStudentMode': isStudentMode,
        'userName': userName,
        'eventoId': eventoId,
        'isAdminMode': isAdminMode,
        'permissionsValidated': permissionsValidated,
        'preciseLocationGranted': preciseLocationGranted,
        'backgroundPermissionsGranted': backgroundPermissionsGranted,
        'batteryOptimizationDisabled': batteryOptimizationDisabled,
      },
    );
  }

  /// ✅ NAVEGACIÓN BASADA EN ROL - UNIFICADA
  static void navigateByRole(String userRole, String userName) {
    switch (userRole) {
      case AppConstants.adminRole:
      case AppConstants.profesorRole:
      case AppConstants.estudianteRole:
        // ✅ TODOS VAN AL MISMO DASHBOARD UNIFICADO
        goToDashboard(userName: userName);
        break;
      default:
        goToLogin();
    }
  }

  /// ✅ NAVEGACIÓN HACIA ATRÁS CON CONTEXTO INTELIGENTE
  static void goBack() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // ✅ LÓGICA INTELIGENTE: Verificar si está autenticado
        _handleNoBackStack();
      }
    }
  }

  /// ✅ MANEJO CUANDO NO HAY STACK DE NAVEGACIÓN
  static Future<void> _handleNoBackStack() async {
    try {
      final isAuth = await isAuthenticated;
      if (isAuth) {
        // Si está autenticado, se queda donde está
        debugPrint('🏠 Usuario autenticado - permaneciendo en pantalla actual');
      } else {
        // Solo va al login si NO está autenticado
        goToLogin();
      }
    } catch (e) {
      // En caso de error, se queda donde está
      debugPrint(
          '🏠 Error verificando autenticación - permaneciendo en pantalla actual');
    }
  }

  /// ✅ UTILIDADES DE NAVEGACIÓN

  /// Location picker con resultado
  static Future<Map<String, dynamic>?> goToLocationPicker({
    double initialLatitude = -0.1805,
    double initialLongitude = -78.4680,
    double initialRange = 100.0,
    String initialLocationName = 'UIDE Campus Principal',
  }) async {
    return await Navigator.of(navigatorKey.currentContext!).pushNamed(
      AppConstants.locationPickerRoute,
      arguments: {
        'initialLatitude': initialLatitude,
        'initialLongitude': initialLongitude,
        'initialRange': initialRange,
        'initialLocationName': initialLocationName,
      },
    ) as Map<String, dynamic>?;
  }

  /// Navegación genérica
  static void navigateTo(String route, {Map<String, dynamic>? arguments}) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      route,
      arguments: arguments,
    );
  }

  /// ✅ UTILIDADES DE UI

  /// Mostrar snackbar
  static void showSnackBar(String message, {bool isError = false}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Mostrar diálogo de confirmación
  static Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value(false);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// ✅ GESTIÓN DE SESIÓN

  /// Verificar si está autenticado
  static Future<bool> get isAuthenticated async {
    try {
      final user = await _storageService.getUser();
      final token = await _storageService.getToken();
      return user != null && token != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener rol del usuario actual
  static Future<String?> get currentUserRole async {
    try {
      return await _storageService.getUserRole();
    } catch (e) {
      return null;
    }
  }

  /// Auto-navegación basada en sesión almacenada
  static Future<void> autoNavigateFromSession() async {
    try {
      final user = await _storageService.getUser();
      if (user != null) {
        navigateByRole(user.rol, user.nombre);
      } else {
        goToLogin();
      }
    } catch (e) {
      goToLogin();
    }
  }

  /// Obtener nombre real del usuario logueado
  static Future<String> _getUserName() async {
    try {
      final user = await _storageService.getUser();
      return user?.nombre ?? 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  /// Cerrar sesión y limpiar datos
  static Future<void> logout() async {
    try {
      await _storageService.clearAll();
      goToLogin();
      showSnackBar('Sesión cerrada correctamente');
    } catch (e) {
      showSnackBar('Error al cerrar sesión', isError: true);
    }
  }
}
