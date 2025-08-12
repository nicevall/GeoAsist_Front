// lib/utils/app_router.dart - VERSIÓN COMPLETA CON EVENTOS
import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/map_view/map_view_screen.dart';
import '../screens/create_professor_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/professor_management_screen.dart';
import '../screens/create_event_screen.dart'; // ✅ AGREGADO
import '../services/storage_service.dart';
import '../models/evento_model.dart'; // ✅ AGREGADO
import '../screens/available_events_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/location_picker_screen.dart';

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
          ),
        );

      case AppConstants.dashboardRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userName: args?['userName'] ?? 'Usuario',
          ),
        );

      case AppConstants.createProfessorRoute:
        return MaterialPageRoute(builder: (_) => const CreateProfessorScreen());

      case AppConstants.professorManagementRoute:
        return MaterialPageRoute(
            builder: (_) => const ProfessorManagementScreen());

      case AppConstants.availableEventsRoute:
        return MaterialPageRoute(builder: (_) => const AvailableEventsScreen());

      case AppConstants.studentDashboardRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => StudentDashboardScreen(
            userName: args?['userName'] ?? 'Usuario',
          ),
        );

      case AppConstants.createEventRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateEventScreen(
            editEvent: args?['editEvent'] as Evento?,
          ),
        );

      case AppConstants.eventManagementRoute:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Event Management - Próximamente'),
            ),
          ),
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
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Event Details - Próximamente'),
            ),
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

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
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
                    onPressed: () => Navigator.of(navigatorKey.currentContext!)
                        .pushReplacementNamed(AppConstants.loginRoute),
                    child: const Text('Ir al Login'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  // Navigation helper methods
  static void goToLogin() {
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed(AppConstants.loginRoute);
  }

  static void goToRegister() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.registerRoute);
  }

  static void goToDashboard({String userName = 'Usuario'}) {
    Navigator.of(navigatorKey.currentContext!).pushReplacementNamed(
      AppConstants.dashboardRoute,
      arguments: {'userName': userName},
    );
  }

  static void goToCreateProfessor() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.createProfessorRoute);
  }

  static void goToProfessorManagement() {
    Navigator.of(navigatorKey.currentContext!)
        .pushNamed(AppConstants.professorManagementRoute);
  }

  static void goToMapView(
      {bool isAdminMode = false, String userName = 'Usuario'}) {
    Navigator.of(navigatorKey.currentContext!).pushReplacementNamed(
      AppConstants.mapViewRoute,
      arguments: {
        'isAdminMode': isAdminMode,
        'userName': userName,
      },
    );
  }

  static void goToStudentDashboard({String userName = 'Usuario'}) {
    Navigator.of(navigatorKey.currentContext!).pushReplacementNamed(
      AppConstants.studentDashboardRoute,
      arguments: {'userName': userName},
    );
  }

  // ✅ NUEVOS MÉTODOS DE NAVEGACIÓN PARA EVENTOS
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

  // Back navigation
  static void goBack() {
    if (Navigator.of(navigatorKey.currentContext!).canPop()) {
      Navigator.of(navigatorKey.currentContext!).pop();
    } else {
      goToLogin();
    }
  }

  // Navigate based on user role - ACTUALIZADO PARA NUEVOS ROLES
  static void navigateByRole(String userRole, String userName) {
    switch (userRole) {
      case AppConstants.adminRole:
        goToDashboard(userName: userName);
        break;
      case AppConstants.docenteRole:
        goToDashboard(userName: userName);
        break;
      case AppConstants.estudianteRole:
        goToStudentDashboard(userName: userName);
        break;
      default:
        goToLogin();
    }
  }

  // Show snackbar using navigator context
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

  // Show dialog using navigator context
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

  // Check if user is authenticated
  static Future<bool> get isAuthenticated async {
    try {
      final user = await _storageService.getUser();
      final token = await _storageService.getToken();
      return user != null && token != null;
    } catch (e) {
      return false;
    }
  }

  // Get current user role
  static Future<String?> get currentUserRole async {
    try {
      return await _storageService.getUserRole();
    } catch (e) {
      return null;
    }
  }

  // Auto-navigate based on stored session
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

  // Logout and clear session
  static Future<void> logout() async {
    try {
      await _storageService.clearAll();
      goToLogin();
      showSnackBar('Sesión cerrada correctamente');
    } catch (e) {
      showSnackBar('Error al cerrar sesión', isError: true);
    }
  }

  static void navigateTo(String route, {Map<String, dynamic>? arguments}) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      route,
      arguments: arguments,
    );
  }
}
