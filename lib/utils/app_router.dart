import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../screens/login_screen.dart';
import '../screens/map_view/map_view_screen.dart';
import '../services/storage_service.dart';

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  // Global key for navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Storage service for user data
  static final StorageService _storageService = StorageService();

  // Simple route generator for now (we'll upgrade to GoRouter once dependencies are added)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppConstants.mapViewRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MapViewScreen(
            isAdminMode: args?['isAdminMode'] ?? false,
            userName: args?['userName'] ?? 'Usuario',
          ),
        );

      // T  ODO: Add other routes as screens are implemented
      /*
      case AppConstants.registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppConstants.adminDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case AppConstants.docenteDashboardRoute:
        return MaterialPageRoute(builder: (_) => const DocenteDashboardScreen());
      case AppConstants.estudianteDashboardRoute:
        return MaterialPageRoute(builder: (_) => const EstudianteDashboardScreen());
      */

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

  static void goToAdminDashboard() {
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed(AppConstants.adminDashboardRoute);
  }

  static void goToDocenteDashboard() {
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed(AppConstants.docenteDashboardRoute);
  }

  static void goToEstudianteDashboard() {
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed(AppConstants.estudianteDashboardRoute);
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
      case AppConstants.docenteRole:
        goToMapView(isAdminMode: true, userName: userName);
        break;
      case AppConstants.estudianteRole:
        goToMapView(isAdminMode: false, userName: userName);
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
}
