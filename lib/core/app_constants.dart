import 'package:flutter/material.dart';

// Core application constants
class AppConstants {
  // App Information
  static const String appName = 'GeoAsist';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Geo-location based attendance system';

  // API Configuration - ACTUALIZADO PARA BACKEND REAL
  static const String baseUrl = 'http://54.210.246.199/api'; // Backend real
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // API Endpoints
  static const String loginEndpoint = '/usuarios/login';
  static const String registerEndpoint = '/usuarios/registrar';
  static const String profileEndpoint = '/usuarios/perfil';
  static const String eventosEndpoint = '/eventos';
  static const String asistenciaEndpoint = '/asistencia/registrar';
  static const String locationEndpoint = '/location/update';
  static const String dashboardEndpoint = '/dashboard/metrics';

  // Location & Geofencing
  static const double defaultLocationAccuracy = 5.0; // meters
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const Duration gracePeriodDuration = Duration(minutes: 1);
  static const double geofenceRadius = 100.0; // meters
  static const Duration breakTimerInterval = Duration(seconds: 1);

  // Authentication
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userDataKey = 'user_data';
  static const String userIdKey = 'user_id';

  // User Roles - COHERENTE CON BACKEND
  static const String adminRole = 'admin';
  static const String docenteRole = 'docente';
  static const String estudianteRole = 'estudiante';

  // Navigation Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String mapViewRoute = '/map-view';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';

  static const String locationPickerRoute = '/location-picker';

  // Rutas principales
  static const String dashboardRoute = '/dashboard';
  static const String professorManagementRoute = '/professor-management';
  static const String createProfessorRoute = '/create-professor';

  static const String createEventRoute = '/create-event';
  static const String eventManagementRoute = '/event-management';
  static const String eventDetailsRoute = '/event-details';

  static const String verifyEmailEndpoint = '/usuarios/verificar-correo';
  static const String resendCodeEndpoint = '/usuarios/reenviar-codigo';

  static const String availableEventsRoute = '/available-events';
  static const String studentDashboardRoute = '/student-dashboard';

  // Error Messages
  static const String networkErrorMessage =
      'Error de conexión. Verifica tu internet.';
  static const String locationPermissionDeniedMessage =
      'Se requiere permiso de ubicación para el seguimiento de asistencia.';
  static const String locationServiceDisabledMessage =
      'Activa los servicios de ubicación para continuar.';
  static const String invalidCredentialsMessage =
      'Correo o contraseña incorrectos.';
  static const String genericErrorMessage =
      'Ocurrió un error inesperado. Inténtalo de nuevo.';

  // Location & Permission Messages
  static const String locationPermissionRequiredMessage =
      'Se requieren permisos de ubicación para registrar asistencia.';
  static const String gpsDisabledMessage =
      'Activa el GPS para continuar con el registro de asistencia.';
  static const String locationErrorMessage =
      'Error al obtener tu ubicación. Intenta nuevamente.';

  // Mensajes de error para gestión de Docentes
  static const String professorCreationErrorMessage =
      'Error al crear el Docente. Verifica los datos.';
  static const String professorUpdateErrorMessage =
      'Error al actualizar los datos del Docente.';
  static const String professorDeletionErrorMessage =
      'Error al eliminar el Docente.';
  static const String duplicateEmailErrorMessage =
      'Ya existe un usuario con este correo electrónico.';

  // Success Messages
  static const String loginSuccessMessage = '¡Inicio de sesión exitoso!';
  static const String registrationSuccessMessage =
      '¡Registro exitoso! Ya puedes iniciar sesión.';
  static const String attendanceMarkedMessage =
      'Asistencia registrada correctamente.';
  static const String breakStartedMessage = 'Período de descanso iniciado.';
  static const String breakEndedMessage = 'Período de descanso terminado.';
  // Mensajes de éxito para gestión de Docentes
  static const String professorCreatedSuccessMessage =
      '¡Docente creado exitosamente!';
  static const String professorUpdatedSuccessMessage =
      '¡Datos del Docente actualizados!';
  static const String professorDeletedSuccessMessage =
      '¡Docente eliminado exitosamente!';

  // UI Configuration
  static const double borderRadius = 25.0;
  static const double cardElevation = 5.0;
  static const double buttonHeight = 55.0;
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const EdgeInsets widgetMargin = EdgeInsets.symmetric(vertical: 8.0);

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Map Configuration
  static const double defaultMapZoom = 17.0;
  static const double maxMapZoom = 20.0;
  static const double minMapZoom = 10.0;

  // Break System
  static const List<int> defaultBreakDurations = [5, 10, 15, 30]; // minutes
  static const int maxBreakDuration = 60; // minutes

  // Request Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> getAuthHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };
}
