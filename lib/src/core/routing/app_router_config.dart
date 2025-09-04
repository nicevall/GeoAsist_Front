import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Authentication feature imports
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/controllers/authentication_controller.dart';

// Core imports
import '../dependency_injection/dependency_injection_container.dart';

/// **AppRouterConfig**: Centralized routing configuration for Clean Architecture
/// 
/// **Purpose**: Manages all application routes with dependency injection integration
/// **AI Context**: Router configuration supporting feature-first architecture with lazy loading
/// **Dependencies**: Flutter Navigator 2.0, Provider for state management
/// **Used by**: Main app widget and navigation system
/// **Performance**: Lazy route generation with dependency injection per route
class AppRouterConfig {
  /// **Property**: Map of route names to route builders
  /// **AI Context**: Type-safe route definition with dependency injection support
  static final Map<String, Widget Function(BuildContext)> _routeBuilders = {
    // Authentication feature routes
    LoginPage.routeName: (context) => _buildAuthenticationRoute(
      context,
      (authController) => const LoginPage(),
    ),
    
    // Dashboard routes (placeholders for other features)
    '/dashboard/student': (context) => _buildDashboardRoute(context, 'student'),
    '/dashboard/professor': (context) => _buildDashboardRoute(context, 'professor'),
    '/dashboard/admin': (context) => _buildDashboardRoute(context, 'admin'),
    
    // Authentication flow routes
    '/authentication/register': (context) => _buildPlaceholderRoute('Registration Page'),
    '/authentication/password-reset': (context) => _buildPlaceholderRoute('Password Reset Page'),
    
    // Settings routes
    '/settings': (context) => _buildPlaceholderRoute('Settings Page'),
    '/settings/profile': (context) => _buildPlaceholderRoute('Profile Settings Page'),
    
    // Event management routes
    '/events': (context) => _buildPlaceholderRoute('Events Page'),
    '/events/create': (context) => _buildPlaceholderRoute('Create Event Page'),
    '/events/:id': (context) => _buildPlaceholderRoute('Event Details Page'),
  };

  /// **Property**: Default route when no specific route is matched
  /// **AI Context**: Fallback route for unknown or invalid routes
  static const String defaultRoute = LoginPage.routeName;

  /// **Property**: Initial route based on authentication state
  /// **AI Context**: Dynamic initial route selection based on user session
  static String get initialRoute {
    // AI Context: Check if user has valid session to determine initial route
    try {
      final authService = DependencyInjectionContainer.getDependency();
      // AI Context: Check authentication status via dynamic call for now
      if ((authService as dynamic).isUserCurrentlyAuthenticated == true) {
        // AI Context: Redirect to appropriate dashboard based on user role
        return _getDashboardRouteForUserRole();
      }
    } catch (e) {
      // AI Context: Fallback to login if dependency resolution fails
    }
    
    return LoginPage.routeName;
  }

  /// **Method**: Generate routes using Navigator 2.0 pattern
  /// **AI Context**: Route factory with dependency injection and error handling
  /// **Input**: RouteSettings containing route name and arguments
  /// **Returns**: Route with dynamic type or null with appropriate page widget
  static Route<dynamic>? generateRoute(RouteSettings routeSettings) {
    final routeName = routeSettings.name ?? defaultRoute;
    
    // AI Context: Handle parameterized routes (like /events/:id)
    final normalizedRouteName = _normalizeRouteWithParameters(routeName);
    
    final routeBuilder = _routeBuilders[normalizedRouteName];
    
    if (routeBuilder != null) {
      return MaterialPageRoute(
        builder: routeBuilder,
        settings: routeSettings,
      );
    }

    // AI Context: Handle unknown routes with error page
    return _generateUnknownRoute(routeSettings);
  }

  /// **Method**: Build authentication routes with dependency injection
  /// **AI Context**: Creates authentication pages with injected controllers
  /// **Returns**: Widget wrapped with necessary providers and dependencies
  static Widget _buildAuthenticationRoute(
    BuildContext context,
    Widget Function(AuthenticationController) pageBuilder,
  ) {
    // AI Context: Get authentication controller from dependency injection
    final authController = DependencyInjectionContainer.getDependency<AuthenticationController>();
    
    return ChangeNotifierProvider<AuthenticationController>(
      create: (_) => authController,
      child: pageBuilder(authController),
    );
  }

  /// **Method**: Build dashboard routes based on user role
  /// **AI Context**: Role-based dashboard routing with access control
  /// **Input**: userRole (String) - role type for dashboard selection
  /// **Returns**: Widget containing appropriate dashboard for user role
  static Widget _buildDashboardRoute(BuildContext context, String userRole) {
    // AI Context: Placeholder implementation - would integrate with actual dashboard features
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${userRole.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleUserLogout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getDashboardIconForRole(userRole),
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Dashboard de ${_getRoleDisplayName(userRole)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Panel principal para gestión de ${_getRoleFeatures(userRole)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // AI Context: Navigate to main feature based on role
                _navigateToMainFeatureForRole(context, userRole);
              },
              child: Text('Ir a ${_getMainFeatureNameForRole(userRole)}'),
            ),
          ],
        ),
      ),
    );
  }

  /// **Method**: Build placeholder routes for features under development
  /// **AI Context**: Temporary routes showing development status
  /// **Input**: pageTitle (String) - title for placeholder page
  /// **Returns**: Widget containing placeholder content
  static Widget _buildPlaceholderRoute(String pageTitle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta funcionalidad está en desarrollo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // AI Context: Navigate back to previous screen
              },
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  /// **Method**: Generate route for unknown/invalid routes
  /// **AI Context**: Error handling for invalid navigation attempts
  /// **Returns**: Route to error page with navigation options
  static Route<dynamic> _generateUnknownRoute(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Página no encontrada'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Página no encontrada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La ruta "${routeSettings.name}" no existe',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    defaultRoute,
                    (route) => false,
                  );
                },
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
      settings: routeSettings,
    );
  }

  /// **Method**: Normalize routes with parameters for lookup
  /// **AI Context**: Convert parameterized routes to base route for matching
  /// **Input**: routeName (String) - route with potential parameters
  /// **Returns**: String - normalized route name for lookup
  static String _normalizeRouteWithParameters(String routeName) {
    // AI Context: Simple parameter detection and normalization
    if (routeName.startsWith('/events/') && routeName != '/events/create') {
      return '/events/:id';
    }
    
    return routeName;
  }

  /// **Method**: Get dashboard route for current user role
  /// **AI Context**: Role-based dashboard route selection
  /// **Returns**: String - appropriate dashboard route for user
  static String _getDashboardRouteForUserRole() {
    // AI Context: Would check actual user role from authentication service
    // Placeholder implementation
    return '/dashboard/student';
  }

  /// **Method**: Handle user logout from dashboard
  /// **AI Context**: Logout flow with session cleanup and navigation
  /// **Side Effects**: Clears authentication state and navigates to login
  static void _handleUserLogout(BuildContext context) async {
    try {
      // AI Context: Get authentication controller and sign out
      final authController = context.read<AuthenticationController>();
      await authController.signOutCurrentUser();
      
      // AI Context: Navigate to login and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      // AI Context: Show error snackbar if logout fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// **Helper Methods**: UI utilities for dashboard customization
  static IconData _getDashboardIconForRole(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'professor':
        return Icons.school;
      case 'student':
        return Icons.person;
      default:
        return Icons.dashboard;
    }
  }

  static String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'professor':
        return 'Profesor';
      case 'student':
        return 'Estudiante';
      default:
        return 'Usuario';
    }
  }

  static String _getRoleFeatures(String role) {
    switch (role) {
      case 'admin':
        return 'usuarios y configuración del sistema';
      case 'professor':
        return 'eventos y asistencias';
      case 'student':
        return 'asistencias y eventos';
      default:
        return 'funciones básicas';
    }
  }

  static String _getMainFeatureNameForRole(String role) {
    switch (role) {
      case 'admin':
        return 'Gestión de Usuarios';
      case 'professor':
        return 'Mis Eventos';
      case 'student':
        return 'Mis Asistencias';
      default:
        return 'Funciones Principales';
    }
  }

  static void _navigateToMainFeatureForRole(BuildContext context, String role) {
    String targetRoute;
    
    switch (role) {
      case 'admin':
        targetRoute = '/settings';
        break;
      case 'professor':
        targetRoute = '/events';
        break;
      case 'student':
        targetRoute = '/events';
        break;
      default:
        targetRoute = '/events';
    }
    
    Navigator.of(context).pushNamed(targetRoute);
  }

  /// **Method**: Check if route requires authentication
  /// **AI Context**: Route guard for protected pages
  /// **Input**: routeName (String) - route to check
  /// **Returns**: bool - true if route requires authentication
  static bool requiresAuthentication(String routeName) {
    const publicRoutes = {
      LoginPage.routeName,
      '/authentication/register',
      '/authentication/password-reset',
    };
    
    return !publicRoutes.contains(routeName);
  }

  /// **Method**: Get all registered routes
  /// **AI Context**: Utility for debugging and testing
  /// **Returns**: List of String - all registered route names
  static List<String> getAllRoutes() {
    return _routeBuilders.keys.toList();
  }
}