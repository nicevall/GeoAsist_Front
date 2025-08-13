// lib/core/app_constants.dart
import 'package:flutter/material.dart';

// Core application constants
class AppConstants {
  // App Information
  static const String appName = 'GeoAsist';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Geo-location based attendance system';

  // ✅ ACTUALIZADO: Nueva IP del servidor - Día 4
  static const String baseUrl =
      'http://44.211.171.188/api'; // Nueva IP del servidor
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ✅ ACTUALIZADO: WebSocket para tiempo real - Nueva IP
  static const String baseUrlWebSocket = 'ws://44.211.171.188';

  // ✅ CONFIGURACIÓN CRÍTICA Día 4 - APP ACTIVE VALIDATION
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration gracePeriodDuration =
      Duration(seconds: 30); // ✅ CORREGIDO: 30 segundos según Día 4
  static const double maxGpsAccuracyMeters = 20.0;
  static const Duration permissionCheckInterval = Duration(minutes: 10);

  // ✅ NUEVAS CONSTANTES DÍA 4 - LIFECYCLE MANAGEMENT
  static const Duration appClosedGracePeriod = Duration(seconds: 30);
  static const Duration backgroundTrackingInterval =
      Duration(seconds: 10); // GPS cada 10s en background
  static const Duration lifecycleCheckInterval =
      Duration(seconds: 5); // Check lifecycle cada 5s
  static const int maxHeartbeatFailures =
      3; // Máximo fallos de heartbeat antes de pérdida
  static const Duration appRestartGracePeriod =
      Duration(seconds: 15); // Grace para restart automático

  // API Endpoints
  static const String loginEndpoint = '/usuarios/login';
  static const String registerEndpoint = '/usuarios/registrar';
  static const String profileEndpoint = '/usuarios/perfil';
  static const String eventosEndpoint = '/eventos';
  static const String asistenciaEndpoint = '/asistencia/registrar';
  static const String locationEndpoint = '/location/update';
  static const String dashboardEndpoint = '/dashboard/metrics';

  // ✅ NUEVOS ENDPOINTS DÍA 4 - BACKEND INTEGRATION
  static const String heartbeatEndpoint = '/asistencia/heartbeat';
  static const String backgroundStatusEndpoint =
      '/asistencia/background-status';
  static const String recoveryEndpoint = '/asistencia/recovery';
  static const String marcarAusenteEndpoint = '/asistencia/marcar-ausente';

  // Location & Geofencing
  static const double defaultLocationAccuracy = 5.0; // meters
  static const Duration locationUpdateInterval = Duration(seconds: 10);
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

  // Navigation Routes - BÁSICAS
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String mapViewRoute = '/map-view';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String locationPickerRoute = '/location-picker';

  // Rutas principales - ADMIN Y DOCENTE
  static const String dashboardRoute = '/dashboard';
  static const String professorManagementRoute = '/professor-management';
  static const String createProfessorRoute = '/create-professor';
  static const String createEventRoute = '/create-event';
  static const String eventManagementRoute = '/event-management';
  static const String eventDetailsRoute = '/event-details';

  // Rutas de verificación
  static const String verifyEmailEndpoint = '/usuarios/verificar-correo';
  static const String resendCodeEndpoint = '/usuarios/reenviar-codigo';

  // Rutas para estudiantes
  static const String availableEventsRoute = '/available-events';

  // ✅ NUEVAS RUTAS DÍA 4 - REFACTORIZACIÓN COMPLETA
  static const String eventMonitorRoute =
      '/event-monitor'; // Antes teacher-dashboard
  static const String attendanceTrackingRoute =
      '/attendance-tracking'; // Antes student-dashboard
  static const String justificationsRoute = '/justifications';
  static const String submitJustificationRoute = '/submit-justification';
  static const String justificationListRoute = '/justification-list';

  // ✅ MANTENER COMPATIBILIDAD TEMPORAL
  static const String studentDashboardRoute =
      '/attendance-tracking'; // Alias para attendanceTrackingRoute

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

  // ✅ NUEVOS MENSAJES DÍA 4 - APP LIFECYCLE VALIDATION
  static const String appClosedWarningMessage =
      '🚨 REABRE GEOASIST EN 30s o perderás tu asistencia';
  static const String preciseLocationRequiredMessage =
      'Se requiere ubicación PRECISA para registrar asistencia';
  static const String backgroundPermissionRequiredMessage =
      'Se requieren permisos de background para el tracking continuo';
  static const String batteryOptimizationDisableMessage =
      'Desactiva la optimización de batería para GeoAsist';
  static const String heartbeatFailedMessage =
      'Conexión perdida con el servidor. Verificando...';
  static const String attendanceLostMessage =
      'Asistencia perdida por cierre de aplicación';

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

  // ✅ NUEVAS CONSTANTES FASE C - TRACKING Y NOTIFICACIONES MEJORADAS

  /// Intervalo de tracking optimizado para Día 4 (10 segundos para precision)
  static const int trackingIntervalSeconds = 10;

  /// Intervalo de tracking en background (5 segundos para detección precisa)
  static const int backgroundTrackingIntervalSeconds = 5;

  /// IDs de notificaciones específicas DÍA 4
  static const int eventActiveNotificationId = 1001;
  static const int geofenceExitNotificationId = 1002;
  static const int gracePeriodNotificationId = 1003;
  static const int trackingPausedNotificationId = 1004;
  static const int attendanceRegisteredNotificationId = 1005;
  static const int appClosedWarningNotificationId = 1006; // ✅ NUEVO
  static const int heartbeatFailedNotificationId = 1007; // ✅ NUEVO
  static const int trackingActiveNotificationId = 1008; // ✅ NUEVO

  /// Configuración de período de gracia DÍA 4 (30 segundos)
  static const int defaultGracePeriodMinutes = 0; // ✅ CORREGIDO: 0 minutos
  static const int gracePeriodSeconds = 30; // ✅ NUEVO: 30 segundos exactos

  /// Radio de geofence por defecto
  static const double defaultGeofenceRadius = 100.0;

  /// Precisión GPS requerida (PRECISA OBLIGATORIA)
  static const double defaultGpsAccuracy = 5.0; // ✅ MEJORADO: 5 metros máximo

  /// Tiempo máximo de ausencia
  static const int defaultMaxAbsenceMinutes = 1; // ✅ NUEVO: 1 minuto máximo

  /// Configuración de notificaciones DÍA 4
  static const String notificationChannelId = 'geo_asist_attendance';
  static const String notificationChannelName = 'Asistencia Geolocalizada';
  static const String notificationChannelDescription =
      'Notificaciones del sistema de asistencia';

  // ✅ NUEVOS CANALES DÍA 4
  static const String criticalChannelId = 'geo_asist_critical';
  static const String criticalChannelName = 'Alertas Críticas';
  static const String criticalChannelDescription =
      'Alertas críticas de pérdida de asistencia';

  /// Configuración de debugging
  static const bool enableDetailedLogging = true;
  static const bool enablePerformanceMonitoring = true;

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

  // ✅ HEADERS PARA AUTENTICACIÓN CON JWT
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // API Endpoints - Eventos expandidos
  static const String eventosEditar = '/eventos'; // Para PUT /{id}
  static const String eventosEliminar = '/eventos'; // Para DELETE /{id}
  static const String eventosMis = '/eventos/mis';

  // API Endpoints - Dashboard expandido
  static const String dashboardEventMetrics =
      '/dashboard/metrics/event'; // Para /{id}
  static const String dashboardOverview = '/dashboard/overview';

  // ✅ CONFIGURACIÓN DÍA 4 - VALIDACIONES DE SEGURIDAD
  static const bool enforceBackgroundPermissions = true;
  static const bool enforcePreciseLocation = true;
  static const bool enforceAppActiveValidation = true;
  static const bool enableGracePeriodCountdown = true;
  static const bool enableHeartbeatValidation = true;
}
