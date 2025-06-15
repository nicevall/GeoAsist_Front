import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../screens/login_screen.dart';
import '../screens/map_view_screen.dart';

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  // Global key for navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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

      // TODO: Add other routes as screens are implemented
      /*
      case AppConstants.registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppConstants.adminDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case AppConstants.attendeeDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AttendeeDashboardScreen());
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
                    'Page not found: ${settings.name}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(navigatorKey.currentContext!)
                        .pushReplacementNamed(AppConstants.loginRoute),
                    child: const Text('Go to Login'),
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

  static void goToAttendeeDashboard() {
    Navigator.of(navigatorKey.currentContext!)
        .pushReplacementNamed(AppConstants.attendeeDashboardRoute);
  }

  static void goToMapView(
      {bool isAdminMode = false, String userName = 'Usuario'}) {
    Navigator.of(navigatorKey.currentContext!).pushNamed(
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

  // Navigate based on user role
  static void navigateByRole(String userRole) {
    switch (userRole) {
      case AppConstants.adminRole:
        goToAdminDashboard();
        break;
      case AppConstants.attendeeRole:
        goToAttendeeDashboard();
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
          backgroundColor: isError ? Colors.red : null,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Show dialog using navigator context
  static Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
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

  // Check if user is authenticated (placeholder - implement with your auth logic)
  static bool get isAuthenticated {
    // TODO: Implement authentication check
    return false;
  }

  // Get current user role (placeholder - implement with your auth logic)
  static String? get currentUserRole {
    // TODO: Implement user role retrieval
    return null;
  }
}
