// lib/core/api_endpoints.dart
import 'package:flutter/foundation.dart';
import 'utils/app_logger.dart';

/// ✅ API ENDPOINTS: Centralización de endpoints backend preservada
/// Responsabilidades:
/// - URLs centralizadas según DETALLES BACK.md
/// - Configuración de entornos (desarrollo/producción)
/// - Endpoints REST y WebSocket organizados
/// - Headers comunes y tokens de autenticación
/// - Validación de URLs y configuraciones
class ApiEndpoints {
  // ⚙️ CONFIGURACIÓN BASE
  static const String _baseUrlDevelopment = 'http://192.168.2.5:8080/api';
  static const String _baseUrlProduction = 'http://192.168.2.5:8080/api';
  static const String _wsUrlDevelopment = 'ws://192.168.2.5:8080';
  static const String _wsUrlProduction = 'ws://192.168.2.5:8080';

  /// URL base según entorno
  static String get baseUrl => kDebugMode ? _baseUrlDevelopment : _baseUrlProduction;
  
  /// URL WebSocket según entorno
  static String get wsUrl => kDebugMode ? _wsUrlDevelopment : _wsUrlProduction;

  // 🔐 AUTENTICACIÓN Y USUARIOS
  static const String _authPath = '/auth';
  static const String _usersPath = '/usuarios';

  /// POST /usuarios/registrar - Registro de usuario (según API_ENDPOINTS.md)
  static String get register => '$baseUrl$_usersPath/registrar';

  /// POST /usuarios/login - Inicio de sesión (según API_ENDPOINTS.md)
  static String get login => '$baseUrl$_usersPath/login';

  /// POST /auth/refresh - Renovar token
  static String get refreshToken => '$baseUrl$_authPath/refresh';

  /// POST /auth/logout - Cerrar sesión
  static String get logout => '$baseUrl$_authPath/logout';

  /// GET /usuarios/perfil/:id - Perfil del usuario (según API_ENDPOINTS.md)
  static String get userProfile => '$baseUrl$_usersPath/perfil';

  /// PUT /usuarios/:id - Actualizar perfil (según API_ENDPOINTS.md)
  static String get updateProfile => '$baseUrl$_usersPath';

  // 📅 EVENTOS
  static const String _eventsPath = '/eventos';

  /// GET /eventos - Obtener todos los eventos
  static String get events => '$baseUrl$_eventsPath';

  /// GET /eventos/active - Eventos activos (filtrados por soft delete)
  static String get activeEvents => '$baseUrl$_eventsPath/active';

  /// GET /eventos/my - Eventos del usuario actual
  static String get myEvents => '$baseUrl$_eventsPath/my';

  /// GET /eventos/:id - Obtener evento específico
  static String getEventById(String eventId) => '$baseUrl$_eventsPath/$eventId';

  /// POST /eventos - Crear nuevo evento (profesor)
  static String get createEvent => '$baseUrl$_eventsPath';

  /// PUT /eventos/:id - Actualizar evento (profesor)
  static String updateEvent(String eventId) => '$baseUrl$_eventsPath/$eventId';

  /// DELETE /eventos/:id - Eliminar evento (soft delete)
  static String deleteEvent(String eventId) => '$baseUrl$_eventsPath/$eventId';

  /// GET /eventos/:id/students - Estudiantes del evento
  static String getEventStudents(String eventId) => '$baseUrl$_eventsPath/$eventId/students';

  /// GET /eventos/:id/stats - Estadísticas del evento
  static String getEventStats(String eventId) => '$baseUrl$_eventsPath/$eventId/stats';

  // 📊 ASISTENCIAS
  static const String _attendancePath = '/asistencia';

  /// GET /asistencia - Obtener asistencias del usuario
  static String get attendances => '$baseUrl$_attendancePath';

  /// POST /asistencia/registrar - Registrar asistencia con coordenadas
  static String get registerAttendance => '$baseUrl$_attendancePath/registrar';

  /// GET /asistencia/:id - Obtener asistencia específica
  static String getAttendanceById(String attendanceId) => '$baseUrl$_attendancePath/$attendanceId';

  /// PUT /asistencia/:id - Actualizar asistencia
  static String updateAttendance(String attendanceId) => '$baseUrl$_attendancePath/$attendanceId';

  /// POST /asistencia/:id/justify - Justificar asistencia
  static String justifyAttendance(String attendanceId) => '$baseUrl$_attendancePath/$attendanceId/justify';

  /// GET /asistencia/event/:eventId - Asistencias por evento
  static String getAttendancesByEvent(String eventId) => '$baseUrl$_attendancePath/event/$eventId';

  /// GET /asistencia/student/:studentId - Asistencias de estudiante
  static String getAttendancesByStudent(String studentId) => '$baseUrl$_attendancePath/student/$studentId';

  /// GET /asistencia/stats - Estadísticas de asistencia del usuario
  static String get attendanceStats => '$baseUrl$_attendancePath/stats';

  // 🌍 UBICACIÓN Y GEOFENCE
  static const String _locationPath = '/location';

  /// POST /location/update - Actualizar ubicación actual
  static String get updateLocation => '$baseUrl$_locationPath/update';

  /// GET /location/check/:eventId - Verificar si está en geofence
  static String checkGeofence(String eventId) => '$baseUrl$_locationPath/check/$eventId';

  /// POST /location/heartbeat - Enviar heartbeat de ubicación
  static String get locationHeartbeat => '$baseUrl$_locationPath/heartbeat';

  /// GET /location/history - Historial de ubicaciones
  static String get locationHistory => '$baseUrl$_locationPath/history';

  // 📱 WEBSOCKETS TIEMPO REAL
  static const String _wsPath = '/ws';

  /// WebSocket para actualizaciones de ubicación
  static String get wsLocation => '$wsUrl$_wsPath/location';

  /// WebSocket para notificaciones de eventos
  static String get wsEvents => '$wsUrl$_wsPath/events';

  /// WebSocket para alertas de geofence
  static String get wsGeofence => '$wsUrl$_wsPath/geofence';

  /// WebSocket para métricas en tiempo real
  static String get wsMetrics => '$wsUrl$_wsPath/metrics';

  // 📊 DASHBOARD Y MÉTRICAS
  static const String _dashboardPath = '/dashboard';

  /// GET /dashboard/admin - Métricas administrativas
  static String get adminDashboard => '$baseUrl$_dashboardPath/admin';

  /// GET /dashboard/professor - Dashboard de profesor
  static String get professorDashboard => '$baseUrl$_dashboardPath/professor';

  /// GET /dashboard/student - Dashboard de estudiante
  static String get studentDashboard => '$baseUrl$_dashboardPath/student';

  /// GET /dashboard/metrics - Métricas generales
  static String get dashboardMetrics => '$baseUrl$_dashboardPath/metrics';

  // 📄 REPORTES Y EXPORTACIÓN
  static const String _reportsPath = '/reports';

  /// GET /reports/attendance/:eventId - Reporte de asistencia por evento
  static String getAttendanceReport(String eventId) => '$baseUrl$_reportsPath/attendance/$eventId';

  /// GET /reports/attendance/:eventId/pdf - Exportar PDF
  static String getAttendanceReportPdf(String eventId) => '$baseUrl$_reportsPath/attendance/$eventId/pdf';

  /// GET /reports/student/:studentId - Reporte por estudiante
  static String getStudentReport(String studentId) => '$baseUrl$_reportsPath/student/$studentId';

  /// GET /reports/professor - Reportes del profesor
  static String get professorReports => '$baseUrl$_reportsPath/professor';

  // ⚙️ CONFIGURACIÓN Y SISTEMA
  static const String _systemPath = '/system';

  /// GET /system/health - Estado del sistema
  static String get systemHealth => '$baseUrl$_systemPath/health';

  /// GET /system/version - Versión de la API
  static String get systemVersion => '$baseUrl$_systemPath/version';

  /// GET /system/config - Configuración del sistema
  static String get systemConfig => '$baseUrl$_systemPath/config';

  // 🔧 HEADERS COMUNES
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'GeoAsist-Flutter/1.0',
  };

  /// Headers con autenticación JWT
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  /// Headers para multipart (archivos)
  static Map<String, String> multipartHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // 📋 VALIDACIONES Y UTILIDADES
  
  /// Validar si la URL es válida
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Construir URL con parámetros de consulta
  static String buildUrlWithParams(String baseUrl, Map<String, String> params) {
    if (params.isEmpty) return baseUrl;
    
    final uri = Uri.parse(baseUrl);
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...params,
    });
    
    return newUri.toString();
  }

  /// Obtener URL de endpoint con filtros
  static String getEventsWithFilters({
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) {
    final params = <String, String>{};
    
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    
    return buildUrlWithParams(events, params);
  }

  /// Obtener URL de asistencias con filtros
  static String getAttendancesWithFilters({
    String? eventId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    final params = <String, String>{};
    
    if (eventId != null) params['eventId'] = eventId;
    if (status != null) params['status'] = status;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    
    return buildUrlWithParams(attendances, params);
  }

  // 🧪 CONFIGURACIÓN DE TESTING
  static const String _testBaseUrl = 'http://localhost:3001';
  
  /// URL base para testing
  static String get testBaseUrl => _testBaseUrl;

  /// Configurar entorno de testing
  static void setTestingMode(bool enabled) {
    if (kDebugMode) {
      logger.i('🧪 Testing mode: ${enabled ? "enabled" : "disabled"}');
    }
  }

  // 📊 MÉTRICAS DE RENDIMIENTO
  
  /// Timeout por defecto para requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Timeout para requests largos (reportes, uploads)
  static const Duration longTimeout = Duration(minutes: 5);

  /// Timeout para WebSockets
  static const Duration wsTimeout = Duration(seconds: 10);

  /// Reintentos por defecto
  static const int defaultRetries = 3;

  // 🔐 CONFIGURACIÓN DE SEGURIDAD
  
  /// Verificar si el endpoint requiere autenticación
  static bool requiresAuth(String endpoint) {
    const publicEndpoints = [
      '/auth/login',
      '/usuarios',
      '/system/health',
      '/system/version',
    ];
    
    return !publicEndpoints.any((public) => endpoint.contains(public));
  }

  /// Obtener nivel de seguridad del endpoint
  static SecurityLevel getSecurityLevel(String endpoint) {
    if (endpoint.contains('/admin')) return SecurityLevel.admin;
    if (endpoint.contains('/professor') || endpoint.contains('/eventos')) return SecurityLevel.professor;
    if (endpoint.contains('/student') || endpoint.contains('/asistencias')) return SecurityLevel.student;
    return SecurityLevel.public;
  }

  // 📝 DOCUMENTACIÓN Y DEBUG
  
  /// Obtener información del endpoint
  static EndpointInfo getEndpointInfo(String endpoint) {
    return EndpointInfo(
      url: endpoint,
      requiresAuth: requiresAuth(endpoint),
      securityLevel: getSecurityLevel(endpoint),
      timeout: endpoint.contains('/reports') ? longTimeout : defaultTimeout,
    );
  }

  /// Log de configuración actual
  static void logConfiguration() {
    if (kDebugMode) {
      logger.i('🔧 API Configuration:');
      logger.i('   Base URL: $baseUrl');
      logger.i('   WebSocket URL: $wsUrl');
      logger.i('   Environment: ${kDebugMode ? "Development" : "Production"}');
      logger.i('   Default timeout: ${defaultTimeout.inSeconds}s');
    }
  }
}

/// Niveles de seguridad para endpoints
enum SecurityLevel {
  public,
  student,
  professor,
  admin,
}

/// Información detallada de un endpoint
class EndpointInfo {
  final String url;
  final bool requiresAuth;
  final SecurityLevel securityLevel;
  final Duration timeout;

  const EndpointInfo({
    required this.url,
    required this.requiresAuth,
    required this.securityLevel,
    required this.timeout,
  });

  @override
  String toString() {
    return 'EndpointInfo(url: $url, requiresAuth: $requiresAuth, '
           'securityLevel: $securityLevel, timeout: ${timeout.inSeconds}s)';
  }
}