// lib/core/api_response_enhanced.dart

/// ✅ API RESPONSE ENHANCED: Manejo de respuestas backend mejorado preservado
/// Responsabilidades:
/// - Tipado estricto de respuestas según DETALLES BACK.md
/// - Validación automática de estructura de datos
/// - Manejo consistente de errores de API
/// - Serialización/deserialización robusta
/// - Metadatos de respuesta (timing, códigos, headers)
/// - Transformación de datos backend a frontend
class ApiResponseEnhanced<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int statusCode;
  final Map<String, String>? headers;
  final Duration? responseTime;
  final DateTime timestamp;
  final ResponseMetadata metadata;

  ApiResponseEnhanced({
    required this.success,
    this.data,
    this.error,
    this.message,
    required this.statusCode,
    this.headers,
    this.responseTime,
    DateTime? timestamp,
    ResponseMetadata? metadata,
  }) : timestamp = timestamp ?? DateTime.now(),
       metadata = metadata ?? const ResponseMetadata();

  /// ✅ CREAR RESPUESTA EXITOSA
  factory ApiResponseEnhanced.success({
    required T data,
    String? message,
    int statusCode = 200,
    Map<String, String>? headers,
    Duration? responseTime,
  }) {
    return ApiResponseEnhanced<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      headers: headers,
      responseTime: responseTime,
      timestamp: DateTime.now(),
      metadata: ResponseMetadata(
        source: ResponseSource.network,
        cached: false,
      ),
    );
  }

  /// ❌ CREAR RESPUESTA DE ERROR
  factory ApiResponseEnhanced.error({
    required String error,
    String? message,
    int statusCode = 500,
    Map<String, String>? headers,
    Duration? responseTime,
  }) {
    return ApiResponseEnhanced<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
      headers: headers,
      responseTime: responseTime,
      timestamp: DateTime.now(),
      metadata: ResponseMetadata(
        source: ResponseSource.network,
        cached: false,
      ),
    );
  }

  /// 💾 CREAR RESPUESTA DESDE CACHE
  factory ApiResponseEnhanced.fromCache({
    required T data,
    String? message,
    DateTime? cacheTime,
  }) {
    return ApiResponseEnhanced<T>(
      success: true,
      data: data,
      message: message ?? 'Datos desde cache',
      statusCode: 200,
      timestamp: DateTime.now(),
      metadata: ResponseMetadata(
        source: ResponseSource.cache,
        cached: true,
        cacheTime: cacheTime,
      ),
    );
  }

  /// 🔄 CREAR RESPUESTA DE LOADING/PENDIENTE
  factory ApiResponseEnhanced.loading({
    String? message,
  }) {
    return ApiResponseEnhanced<T>(
      success: false,
      message: message ?? 'Cargando...',
      statusCode: 102, // Processing
      timestamp: DateTime.now(),
      metadata: ResponseMetadata(
        source: ResponseSource.loading,
        cached: false,
      ),
    );
  }

  /// ⏱️ VERIFICAR SI ES UNA RESPUESTA RECIENTE
  bool get isRecent {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    return diff.inMinutes < 5; // Consideramos reciente si es menor a 5 minutos
  }

  /// 📊 VERIFICAR SI ES UNA RESPUESTA RÁPIDA
  bool get isFastResponse {
    return responseTime != null && responseTime!.inMilliseconds < 1000;
  }

  /// 🎯 VERIFICAR SI VIENE DEL CACHE
  bool get isFromCache => metadata.cached;

  /// 🔍 OBTENER INFORMACIÓN DE DEBUG
  String get debugInfo {
    return 'ApiResponse(success: $success, statusCode: $statusCode, '
           'responseTime: ${responseTime?.inMilliseconds}ms, '
           'source: ${metadata.source}, cached: ${metadata.cached})';
  }

  @override
  String toString() {
    if (success) {
      return 'ApiResponseEnhanced.success(data: $data, statusCode: $statusCode)';
    } else {
      return 'ApiResponseEnhanced.error(error: $error, statusCode: $statusCode)';
    }
  }
}

/// 📊 METADATOS DE RESPUESTA
class ResponseMetadata {
  final ResponseSource source;
  final bool cached;
  final DateTime? cacheTime;
  final String? requestId;
  final Map<String, dynamic>? additionalInfo;

  const ResponseMetadata({
    this.source = ResponseSource.network,
    this.cached = false,
    this.cacheTime,
    this.requestId,
    this.additionalInfo,
  });

  @override
  String toString() {
    return 'ResponseMetadata(source: $source, cached: $cached, cacheTime: $cacheTime)';
  }
}

/// 🔍 FUENTES DE RESPUESTA
enum ResponseSource {
  network,
  cache,
  loading,
  error,
}

/// ✅ FACTORY PARA RESPUESTAS TIPADAS SEGÚN BACKEND
class ApiResponseFactory {
  
  /// 👤 RESPUESTA DE AUTENTICACIÓN
  static ApiResponseEnhanced<AuthResponse> fromAuthJson(
    Map<String, dynamic> json,
    int statusCode,
    Duration? responseTime,
  ) {
    try {
      if (statusCode >= 200 && statusCode < 300) {
        final authData = AuthResponse.fromJson(json);
        return ApiResponseEnhanced.success(
          data: authData,
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      } else {
        return ApiResponseEnhanced.error(
          error: json['error'] as String? ?? 'Error de autenticación',
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      }
    } catch (e) {
      return ApiResponseEnhanced.error(
        error: 'Error parsing auth response: $e',
        statusCode: 500,
        responseTime: responseTime,
      );
    }
  }

  /// 📅 RESPUESTA DE EVENTOS
  static ApiResponseEnhanced<EventosResponse> fromEventosJson(
    Map<String, dynamic> json,
    int statusCode,
    Duration? responseTime,
  ) {
    try {
      if (statusCode >= 200 && statusCode < 300) {
        final eventosData = EventosResponse.fromJson(json);
        return ApiResponseEnhanced.success(
          data: eventosData,
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      } else {
        return ApiResponseEnhanced.error(
          error: json['error'] as String? ?? 'Error obteniendo eventos',
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      }
    } catch (e) {
      return ApiResponseEnhanced.error(
        error: 'Error parsing eventos response: $e',
        statusCode: 500,
        responseTime: responseTime,
      );
    }
  }

  /// 📊 RESPUESTA DE ASISTENCIAS
  static ApiResponseEnhanced<AsistenciasResponse> fromAsistenciasJson(
    Map<String, dynamic> json,
    int statusCode,
    Duration? responseTime,
  ) {
    try {
      if (statusCode >= 200 && statusCode < 300) {
        final asistenciasData = AsistenciasResponse.fromJson(json);
        return ApiResponseEnhanced.success(
          data: asistenciasData,
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      } else {
        return ApiResponseEnhanced.error(
          error: json['error'] as String? ?? 'Error obteniendo asistencias',
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      }
    } catch (e) {
      return ApiResponseEnhanced.error(
        error: 'Error parsing asistencias response: $e',
        statusCode: 500,
        responseTime: responseTime,
      );
    }
  }

  /// 📍 RESPUESTA DE UBICACIÓN
  static ApiResponseEnhanced<LocationResponse> fromLocationJson(
    Map<String, dynamic> json,
    int statusCode,
    Duration? responseTime,
  ) {
    try {
      if (statusCode >= 200 && statusCode < 300) {
        final locationData = LocationResponse.fromJson(json);
        return ApiResponseEnhanced.success(
          data: locationData,
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      } else {
        return ApiResponseEnhanced.error(
          error: json['error'] as String? ?? 'Error de ubicación',
          message: json['message'] as String?,
          statusCode: statusCode,
          responseTime: responseTime,
        );
      }
    } catch (e) {
      return ApiResponseEnhanced.error(
        error: 'Error parsing location response: $e',
        statusCode: 500,
        responseTime: responseTime,
      );
    }
  }

  /// ⚙️ RESPUESTA GENÉRICA
  static ApiResponseEnhanced<Map<String, dynamic>> fromGenericJson(
    Map<String, dynamic> json,
    int statusCode,
    Duration? responseTime,
  ) {
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponseEnhanced.success(
        data: json,
        message: json['message'] as String?,
        statusCode: statusCode,
        responseTime: responseTime,
      );
    } else {
      return ApiResponseEnhanced.error(
        error: json['error'] as String? ?? 'Error en la respuesta',
        message: json['message'] as String?,
        statusCode: statusCode,
        responseTime: responseTime,
      );
    }
  }
}

/// 👤 MODELO DE RESPUESTA DE AUTENTICACIÓN
class AuthResponse {
  final String token;
  final String refreshToken;
  final UserData user;
  final DateTime expiresAt;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

/// 👤 DATOS DE USUARIO
class UserData {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  const UserData({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] as String? ?? json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo,
    };
  }
}

/// 📅 RESPUESTA DE EVENTOS
class EventosResponse {
  final List<EventoData> eventos;
  final int total;
  final int activos;
  final int inactivos;

  const EventosResponse({
    required this.eventos,
    required this.total,
    required this.activos,
    required this.inactivos,
  });

  factory EventosResponse.fromJson(Map<String, dynamic> json) {
    final eventosList = json['eventos'] as List<dynamic>? ?? [];
    
    return EventosResponse(
      eventos: eventosList.map((e) => EventoData.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? eventosList.length,
      activos: json['activos'] as int? ?? 0,
      inactivos: json['inactivos'] as int? ?? 0,
    );
  }
}

/// 📅 DATOS DE EVENTO
class EventoData {
  final String id;
  final String titulo;
  final String? descripcion;
  final String? lugar;
  final DateTime horaInicio;
  final DateTime horaFin;
  final double lat;
  final double lng;
  final double rangoPermitido;
  final bool activo;
  final String estado;
  final String profesorId;

  const EventoData({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.lugar,
    required this.horaInicio,
    required this.horaFin,
    required this.lat,
    required this.lng,
    required this.rangoPermitido,
    required this.activo,
    required this.estado,
    required this.profesorId,
  });

  factory EventoData.fromJson(Map<String, dynamic> json) {
    return EventoData(
      id: json['_id'] as String? ?? json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      lugar: json['lugar'] as String?,
      horaInicio: DateTime.parse(json['horaInicio'] as String),
      horaFin: DateTime.parse(json['horaFin'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      rangoPermitido: (json['rangoPermitido'] as num? ?? json['radio'] as num? ?? 50).toDouble(),
      activo: json['activo'] as bool? ?? true,
      estado: json['estado'] as String? ?? 'activo',
      profesorId: json['profesorId'] as String? ?? json['profesor'] as String? ?? '',
    );
  }
}

/// 📊 RESPUESTA DE ASISTENCIAS
class AsistenciasResponse {
  final List<AsistenciaData> asistencias;
  final int total;
  final EstadisticasAsistencia estadisticas;

  const AsistenciasResponse({
    required this.asistencias,
    required this.total,
    required this.estadisticas,
  });

  factory AsistenciasResponse.fromJson(Map<String, dynamic> json) {
    final asistenciasList = json['asistencias'] as List<dynamic>? ?? [];
    
    return AsistenciasResponse(
      asistencias: asistenciasList.map((a) => AsistenciaData.fromJson(a as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? asistenciasList.length,
      estadisticas: EstadisticasAsistencia.fromJson(json['estadisticas'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// 📊 DATOS DE ASISTENCIA
class AsistenciaData {
  final String id;
  final String eventoId;
  final String estudianteId;
  final String estado;
  final DateTime hora;
  final double lat;
  final double lng;
  final double? distancia;
  final String? justificacion;

  const AsistenciaData({
    required this.id,
    required this.eventoId,
    required this.estudianteId,
    required this.estado,
    required this.hora,
    required this.lat,
    required this.lng,
    this.distancia,
    this.justificacion,
  });

  factory AsistenciaData.fromJson(Map<String, dynamic> json) {
    return AsistenciaData(
      id: json['_id'] as String? ?? json['id'] as String,
      eventoId: json['eventoId'] as String,
      estudianteId: json['estudianteId'] as String,
      estado: json['estado'] as String,
      hora: DateTime.parse(json['hora'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distancia: (json['distancia'] as num?)?.toDouble(),
      justificacion: json['justificacion'] as String?,
    );
  }
}

/// 📈 ESTADÍSTICAS DE ASISTENCIA
class EstadisticasAsistencia {
  final int presente;
  final int tarde;
  final int ausente;
  final int justificado;
  final int pendiente;

  const EstadisticasAsistencia({
    required this.presente,
    required this.tarde,
    required this.ausente,
    required this.justificado,
    required this.pendiente,
  });

  factory EstadisticasAsistencia.fromJson(Map<String, dynamic> json) {
    return EstadisticasAsistencia(
      presente: json['presente'] as int? ?? 0,
      tarde: json['tarde'] as int? ?? 0,
      ausente: json['ausente'] as int? ?? 0,
      justificado: json['justificado'] as int? ?? 0,
      pendiente: json['pendiente'] as int? ?? 0,
    );
  }

  int get total => presente + tarde + ausente + justificado + pendiente;
}

/// 📍 RESPUESTA DE UBICACIÓN
class LocationResponse {
  final bool inGeofence;
  final double distance;
  final String message;
  final DateTime timestamp;

  const LocationResponse({
    required this.inGeofence,
    required this.distance,
    required this.message,
    required this.timestamp,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      inGeofence: json['inGeofence'] as bool? ?? false,
      distance: (json['distance'] as num? ?? 0).toDouble(),
      message: json['message'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}