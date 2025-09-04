// lib/services/asistencia_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/asistencia_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'dart:io';
import 'dart:math' as math;

/// ✅ ENHANCED: Error types for better categorization
enum AsistenciaErrorType {
  network,      // Network connectivity issues
  timeout,      // Request timeout
  authentication, // Auth token issues
  validation,   // Input validation errors
  server,       // Server-side errors (5xx)
  unknown       // Unexpected errors
}

/// Servicio para manejar todas las operaciones de asistencia con el backend real
/// ✅ ENHANCED: Improved HTTP error handling and network resilience
class AsistenciaService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // 🎯 NUEVAS PROPIEDADES PARA HEARTBEAT MEJORADO
  static String? _sessionId;
  static int _heartbeatSequence = 0;

  // ✅ ENHANCED: Error handling configuration
  static const int _maxRetries = 3;
  static const int _baseRetryDelayMs = 1000; // 1 second
  static const int _timeoutSeconds = 30;

  /// ✅ ENHANCED: Robust error handling with retry logic and categorization
  Future<ApiResponse<T>> _executeWithRetry<T>(
    Future<ApiResponse<T>> Function() operation, {
    int maxRetries = _maxRetries,
    bool shouldRetry = true,
    String operationName = 'operation',
  }) async {
    int attempt = 1;
    
    while (attempt <= maxRetries) {
      try {
        debugPrint('🔄 [$operationName] Intento $attempt/$maxRetries');
        
        final response = await operation().timeout(
          Duration(seconds: _timeoutSeconds),
          onTimeout: () => ApiResponse<T>.error('Timeout después de ${_timeoutSeconds}s'),
        );
        
        if (response.success || !shouldRetry || attempt == maxRetries) {
          if (response.success) {
            debugPrint('✅ [$operationName] Exitoso en intento $attempt');
          }
          return response;
        }
        
        // Determine if we should retry based on error type
        final errorType = _categorizeError(response.error ?? '');
        if (!_shouldRetryForErrorType(errorType)) {
          debugPrint('❌ [$operationName] Error no recuperable: ${response.error}');
          return response;
        }
        
      } catch (e) {
        debugPrint('❌ [$operationName] Excepción en intento $attempt: $e');
        
        if (attempt == maxRetries) {
          return ApiResponse<T>.error(_formatError(e, operationName));
        }
      }
      
      if (attempt < maxRetries) {
        final delayMs = _calculateRetryDelay(attempt);
        debugPrint('⏳ [$operationName] Esperando ${delayMs}ms antes del siguiente intento...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
      
      attempt++;
    }
    
    return ApiResponse<T>.error('$operationName falló después de $maxRetries intentos');
  }

  /// Categorize error for appropriate handling
  AsistenciaErrorType _categorizeError(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('timeout') || lowerError.contains('time out')) {
      return AsistenciaErrorType.timeout;
    }
    if (lowerError.contains('network') || lowerError.contains('connection') || 
        lowerError.contains('unreachable') || lowerError.contains('dns')) {
      return AsistenciaErrorType.network;
    }
    if (lowerError.contains('unauthorized') || lowerError.contains('401') ||
        lowerError.contains('token') || lowerError.contains('sesión')) {
      return AsistenciaErrorType.authentication;
    }
    if (lowerError.contains('validation') || lowerError.contains('400') ||
        lowerError.contains('bad request') || lowerError.contains('invalid')) {
      return AsistenciaErrorType.validation;
    }
    if (lowerError.contains('500') || lowerError.contains('502') || 
        lowerError.contains('503') || lowerError.contains('server error')) {
      return AsistenciaErrorType.server;
    }
    
    return AsistenciaErrorType.unknown;
  }

  /// Determine if we should retry based on error type
  bool _shouldRetryForErrorType(AsistenciaErrorType errorType) {
    switch (errorType) {
      case AsistenciaErrorType.network:
      case AsistenciaErrorType.timeout:
      case AsistenciaErrorType.server:
        return true; // Retryable
      case AsistenciaErrorType.authentication:
      case AsistenciaErrorType.validation:
        return false; // Not retryable
      case AsistenciaErrorType.unknown:
        return true; // Assume retryable for unknown errors
    }
  }

  /// Calculate exponential backoff delay
  int _calculateRetryDelay(int attempt) {
    final exponentialDelay = _baseRetryDelayMs * math.pow(2, attempt - 1);
    final jitter = math.Random().nextInt(500); // Add 0-500ms jitter
    return (exponentialDelay + jitter).toInt().clamp(0, 10000); // Max 10s
  }

  /// Format error messages consistently
  String _formatError(dynamic error, String operation) {
    if (error is SocketException) {
      return 'Sin conexión de red para $operation';
    }
    if (error is TimeoutException) {
      return 'Timeout en $operation - verifique su conexión';
    }
    if (error is HttpException) {
      return 'Error HTTP en $operation: ${error.message}';
    }
    
    return 'Error en $operation: ${error.toString()}';
  }

  // 🎯 MÉTODO 2: Actualizar ubicación en tiempo real - ENHANCED with retry logic
  Future<ApiResponse<bool>> actualizarUbicacion({
    required String usuarioId,
    required String eventoId,
    required double latitud,
    required double longitud,
    double? precision,
    double? speed,
  }) async {
    debugPrint('📍 Actualizando ubicación en tiempo real');
    debugPrint('🌍 Usuario: $usuarioId en evento: $eventoId');
    debugPrint('📊 Coords: ($latitud, $longitud), precisión: ${precision ?? 'N/A'}m');

    return _executeWithRetry<bool>(
      () async {
        final token = await _storageService.getToken();
        if (token == null) {
          debugPrint('❌ No hay sesión activa para actualizar ubicación');
          return ApiResponse.error('No hay sesión activa');
        }

        final locationData = {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'latitude': latitud,   // ✅ CRÍTICO: Backend espera 'latitude' (inglés)
          'longitude': longitud, // ✅ CRÍTICO: Backend espera 'longitude' (inglés)  
          'timestamp': DateTime.now().toIso8601String(),
          if (precision != null) 'precision': precision,
          if (speed != null) 'speed': speed,
        };

        final response = await _apiService.post(
          AppConstants.locationEndpoint, // '/location/update'
          body: locationData,
          headers: AppConstants.getAuthHeaders(token),
        );

        if (response.success) {
          return ApiResponse.success(true, message: 'Ubicación actualizada');
        }

        return ApiResponse.error(response.error ?? 'Error actualizando ubicación');
      },
      operationName: 'ActualizarUbicacion',
      shouldRetry: true,
    );
  }

  // 🎯 MÉTODO 3: Obtener asistencias de un evento específico (para profesor)
  Future<List<Asistencia>> obtenerAsistenciasEvento(String eventoId) async {
    try {
      debugPrint('👥 Obteniendo asistencias del evento: $eventoId');
      
      // ✅ CRÍTICO: Validar eventoId antes de hacer request al backend
      if (eventoId.isEmpty || eventoId == 'null' || eventoId == 'undefined') {
        debugPrint('❌ eventoId inválido: "$eventoId" - retornando lista vacía');
        return [];
      }

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para obtener asistencias');
        return [];
      }

      final response = await _apiService.get(
        '${AppConstants.asistenciaEndpoint.replaceAll('/registrar', '/event')}/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Response success: ${response.success}');

      if (response.success && response.data != null) {
        final List<dynamic> asistenciasData =
            response.data!['asistencias'] ?? response.data!;
        final asistencias =
            asistenciasData.map((data) => Asistencia.fromJson(data)).toList();

        debugPrint('✅ Asistencias cargadas: ${asistencias.length} registros');
        return asistencias;
      }

      debugPrint('❌ Error obteniendo asistencias: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('❌ Excepción obteniendo asistencias: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 4: Obtener historial de asistencias de un usuario
  Future<List<Asistencia>> obtenerHistorialUsuario(String usuarioId) async {
    try {
      // Validar que el usuarioId no esté vacío
      if (usuarioId.isEmpty) {
        debugPrint('❌ UsuarioId vacío, no se puede obtener historial');
        return [];
      }

      debugPrint(
          '📚 Obteniendo historial de asistencias del usuario: $usuarioId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para obtener historial');
        return [];
      }

      final response = await _apiService.get(
        '${AppConstants.asistenciaEndpoint.replaceAll('/registrar', '/mis-asistencias')}',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final List<dynamic> asistenciasData =
            response.data!['asistencias'] ?? response.data!;
        final asistencias =
            asistenciasData.map((data) => Asistencia.fromJson(data)).toList();

        // Ordenar por fecha más reciente primero
        asistencias.sort((a, b) => b.fecha.compareTo(a.fecha));

        debugPrint('✅ Historial cargado: ${asistencias.length} registros');
        return asistencias;
      }

      debugPrint('❌ Error obteniendo historial: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('❌ Excepción obteniendo historial: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 5: Obtener estadísticas personales de asistencia
  Future<Map<String, dynamic>> obtenerEstadisticasPersonales(
      String usuarioId) async {
    try {
      debugPrint(
          '📊 Obteniendo estadísticas personales del usuario: $usuarioId');
          
      // ✅ CRÍTICO: Validar usuarioId antes de hacer request al backend
      if (usuarioId.isEmpty || usuarioId == 'null' || usuarioId == 'undefined') {
        debugPrint('❌ usuarioId inválido: "$usuarioId" - retornando mapa vacío');
        return {};
      }

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para obtener estadísticas');
        return {};
      }

      final response = await _apiService.get(
        '/dashboard/student/metrics',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final stats = response.data!;
        debugPrint('✅ Estadísticas cargadas: $stats');
        return stats;
      }

      debugPrint('❌ Error obteniendo estadísticas: ${response.error}');
      return {};
    } catch (e) {
      debugPrint('❌ Excepción obteniendo estadísticas: $e');
      return {};
    }
  }

  // 🎯 MÉTODO 6: Enviar justificación con link de documento
  Future<ApiResponse<bool>> enviarJustificacion({
    required String eventoId,
    required String usuarioId,
    required String linkDocumento,
    String? motivo,
  }) async {
    try {
      debugPrint('📄 Enviando justificación con link');
      debugPrint('🔗 Link: $linkDocumento');
      debugPrint('📝 Motivo: ${motivo ?? 'No especificado'}');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para enviar justificación');
        return ApiResponse.error('No hay sesión activa');
      }

      // Validar que sea un link válido
      if (!_esLinkValido(linkDocumento)) {
        debugPrint('❌ Link no válido: $linkDocumento');
        return ApiResponse.error('El link proporcionado no es válido');
      }

      // Usar el campo observaciones para almacenar la justificación
      final justificacionData = {
        'usuarioId': usuarioId,
        'eventoId': eventoId,
        'estado': 'justificado',
        'observaciones': jsonEncode({
          'tipo': 'justificacion',
          'linkDocumento': linkDocumento,
          'motivo': motivo,
          'fechaEnvio': DateTime.now().toIso8601String(),
        }),
        'fecha': DateTime.now().toIso8601String().split('T')[0],
        'hora': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
        'latitud': 0.0, // No relevante para justificaciones
        'longitud': 0.0,
      };

      // ✅ CORREGIDO: Usar endpoint correcto con /api
      final response = await _apiService.post(
        AppConstants.asistenciaEndpoint, // '/asistencia/registrar'
        body: justificacionData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Justificación enviada exitosamente');
        return ApiResponse.success(true,
            message: 'Justificación enviada exitosamente');
      }

      debugPrint('❌ Error enviando justificación: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error enviando justificación');
    } catch (e) {
      debugPrint('❌ Excepción enviando justificación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 7: Obtener justificaciones de un usuario
  Future<List<Map<String, dynamic>>> obtenerJustificaciones(
      String usuarioId) async {
    try {
      debugPrint('📄 Obteniendo justificaciones del usuario: $usuarioId');

      final asistencias = await obtenerHistorialUsuario(usuarioId);
      final justificaciones = <Map<String, dynamic>>[];

      for (final asistencia in asistencias) {
        if (asistencia.observaciones != null &&
            asistencia.observaciones!.isNotEmpty) {
          try {
            final observacionesData = jsonDecode(asistencia.observaciones!);
            if (observacionesData['tipo'] == 'justificacion') {
              justificaciones.add({
                'id': asistencia.id,
                'eventoId': asistencia.eventoId,
                'linkDocumento': observacionesData['linkDocumento'],
                'motivo': observacionesData['motivo'],
                'fechaEnvio': observacionesData['fechaEnvio'],
                'estado': asistencia.estado,
                'fecha': asistencia.fecha,
              });
            }
          } catch (e) {
            // Observaciones que no son JSON válido se ignoran
            continue;
          }
        }
      }

      debugPrint('✅ Justificaciones encontradas: ${justificaciones.length}');
      return justificaciones;
    } catch (e) {
      debugPrint('❌ Error obteniendo justificaciones: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 8: Stream para actualizaciones en tiempo real
  Stream<List<Asistencia>> subscribeToAsistenciaUpdates(
      String eventoId) async* {
    while (true) {
      try {
        final asistencias = await obtenerAsistenciasEvento(eventoId);
        yield asistencias;

        // Esperar 30 segundos antes de la siguiente actualización
        await Future.delayed(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('❌ Error en stream de asistencias: $e');
        yield [];
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }

  // 🎯 MÉTODO 9: Validar estado de asistencia en un evento
  Future<String?> validarEstadoAsistencia(
      String usuarioId, String eventoId) async {
    try {
      debugPrint('🔍 Validando estado de asistencia');
      debugPrint('👤 Usuario: $usuarioId, Evento: $eventoId');

      final asistencias = await obtenerAsistenciasEvento(eventoId);
      final asistenciaUsuario =
          asistencias.where((a) => a.usuarioId == usuarioId).toList();

      if (asistenciaUsuario.isEmpty) {
        debugPrint('📋 Usuario sin asistencia registrada');
        return null;
      }

      // Obtener la asistencia más reciente
      asistenciaUsuario.sort((a, b) => b.fecha.compareTo(a.fecha));
      final ultimaAsistencia = asistenciaUsuario.first;

      debugPrint('✅ Estado actual: ${ultimaAsistencia.estado}');
      return ultimaAsistencia.estado;
    } catch (e) {
      debugPrint('❌ Error validando estado: $e');
      return null;
    }
  }

  // 🎯 MÉTODO 10: Marcar usuario como ausente (para app lifecycle)
  Future<ApiResponse<bool>> marcarAusente({
    required String usuarioId,
    required String eventoId,
    required String motivo,
  }) async {
    try {
      debugPrint('❌ Marcando usuario como ausente');
      debugPrint('📱 Motivo: $motivo');

      return await registrarAsistencia(
        eventoId: eventoId,
        usuarioId: usuarioId,
        latitud: 0.0, // Ubicación no relevante para ausencia
        longitud: 0.0,
        estado: 'ausente',
        observaciones: motivo,
      ).then((response) {
        if (response.success) {
          return ApiResponse.success(true,
              message: 'Usuario marcado como ausente');
        }
        return ApiResponse.error(response.error ?? 'Error marcando ausencia');
      });
    } catch (e) {
      debugPrint('❌ Error marcando ausente: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> enviarHeartbeat({
    required String usuarioId,
    required String eventoId,
    required bool isAppActive,
    required bool isInGracePeriod,
    required int gracePeriodRemaining,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('💓 Enviando heartbeat mejorado con estado de app');

      final response = await _apiService.post(
        AppConstants.heartbeatEndpoint, // '/asistencia/heartbeat'
        body: {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'timestamp': DateTime.now().toIso8601String(),
          'appStatus': isAppActive ? 'foreground' : 'background',
          'isInGracePeriod': isInGracePeriod,
          'gracePeriodRemaining': gracePeriodRemaining,
          'platform': Platform.operatingSystem,
          'appVersion': AppConstants.appVersion,
          'connectionType': 'mobile', // Podría ser wifi, mobile, etc.
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('💓 Heartbeat enviado exitosamente');

        // El backend puede devolver comandos o información adicional
        return ApiResponse.success(response.data ?? {});
      }

      debugPrint('❌ Error en heartbeat: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error en heartbeat');
    } catch (e) {
      debugPrint('❌ Excepción en heartbeat: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ✅ NUEVO DÍA 4: Registrar recovery exitoso cuando app vuelve en grace period
  Future<ApiResponse<bool>> registrarRecoveryExitoso({
    required String usuarioId,
    required String eventoId,
    required int downtimeSeconds,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint(
          '✅ Registrando recovery exitoso - downtime: ${downtimeSeconds}s');

      final response = await _apiService.post(
        AppConstants.recoveryEndpoint, // '/asistencia/recovery'
        body: {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'downtimeSeconds': downtimeSeconds,
          'recoveryTimestamp': DateTime.now().toIso8601String(),
          'gracePeriodUsed': downtimeSeconds,
          'platform': Platform.operatingSystem,
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Recovery exitoso registrado en backend');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(response.error ?? 'Error registrando recovery');
    } catch (e) {
      debugPrint('❌ Error registrando recovery: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  // ✅ NUEVO DÍA 4: Marcar estado de background tracking (SIN penalización)
  Future<ApiResponse<bool>> marcarEstadoBackgroundTracking({
    required String usuarioId,
    required String eventoId,
    required String
        status, // 'background_started', 'background_active', 'background_ended'
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('📱 Marcando estado background: $status');

      final response = await _apiService.post(
        AppConstants
            .backgroundStatusEndpoint, // '/asistencia/background-status'
        body: {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
          'tracking_type': 'background_normal', // No es grace period
          'platform': Platform.operatingSystem,
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Estado background registrado: $status');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(
          response.error ?? 'Error marcando estado background');
    } catch (e) {
      debugPrint('❌ Error marcando estado background: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// 🔥 NUEVO: Heartbeat con validación previa y reintentos automáticos
  Future<ApiResponse<Map<String, dynamic>>> enviarHeartbeatConValidacion({
    required String usuarioId,
    required String eventoId,
    double? latitud,
    double? longitud,
    bool? appActive,
    int maxReintentos = 3,
  }) async {
    for (int intento = 1; intento <= maxReintentos; intento++) {
      try {
        debugPrint(
            '💓 Heartbeat con validación - Intento $intento/$maxReintentos');

        // 1. ✅ Validar conexión antes de enviar
        if (intento == 1) {
          // Solo validar en el primer intento para eficiencia
          final connectionTest = await testConnection();
          if (!connectionTest.success) {
            debugPrint('❌ Sin conexión - omitiendo heartbeat');
            return ApiResponse.error('Sin conexión de red');
          }
        }

        // 2. ✅ Enviar heartbeat con datos completos
        final heartbeatResponse = await enviarHeartbeat(
          usuarioId: usuarioId,
          eventoId: eventoId,
          isAppActive: appActive ?? true, // ✅ Parámetro correcto
          isInGracePeriod: false, // ✅ Parámetro requerido
          gracePeriodRemaining: 0, // ✅ Parámetro requerido
        );

        // 3. ✅ Si es exitoso, retornar inmediatamente
        if (heartbeatResponse.success) {
          if (intento > 1) {
            debugPrint('✅ Heartbeat exitoso después de $intento intentos');
          }
          return heartbeatResponse;
        }

        // 4. ✅ Si falla y no es el último intento, esperar y reintentar
        if (intento < maxReintentos) {
          final delaySegundos = intento * 2; // Backoff exponencial: 2s, 4s, 6s
          debugPrint('⏳ Reintentando heartbeat en ${delaySegundos}s...');
          await Future.delayed(Duration(seconds: delaySegundos));
        }
      } catch (e) {
        debugPrint('❌ Error en intento $intento de heartbeat: $e');

        if (intento == maxReintentos) {
          return ApiResponse.error('Fallos múltiples de heartbeat: $e');
        }
      }
    }

    // Si llegamos aquí, todos los intentos fallaron
    debugPrint('❌ TODOS LOS INTENTOS DE HEARTBEAT FALLARON');
    return ApiResponse.error(
        'Heartbeat falló después de $maxReintentos intentos');
  }

  /// 🔥 NUEVO: Validar estado del evento desde heartbeat
  Future<Map<String, dynamic>?> validarEstadoEventoConHeartbeat({
    required String usuarioId,
    required String eventoId,
  }) async {
    try {
      debugPrint('🔍 Validando estado del evento via heartbeat');

      final heartbeatResponse = await enviarHeartbeatConValidacion(
        usuarioId: usuarioId,
        eventoId: eventoId,
        appActive: true,
      );

      if (heartbeatResponse.success && heartbeatResponse.data != null) {
        final responseData = heartbeatResponse.data!;

        // ✅ Extraer información del estado del evento del backend
        final estadoEvento = {
          'eventoActivo': responseData['eventActive'] ?? true,
          'asistenciaValida': responseData['attendanceValid'] ?? true,
          'estadoAsistencia': responseData['attendanceStatus'] ?? 'unknown',
          'enReceso': responseData['inBreak'] ?? false,
          'comandosBackend': responseData['commands'] ?? [],
          'metricas': responseData['metrics'] ?? {},
          'heartbeatValido': true,
        };

        debugPrint('📊 Estado del evento validado: $estadoEvento');
        return estadoEvento;
      }

      debugPrint('❌ No se pudo validar estado del evento');
      return {'heartbeatValido': false, 'error': heartbeatResponse.error};
    } catch (e) {
      debugPrint('❌ Error validando estado del evento: $e');
      return {'heartbeatValido': false, 'error': e.toString()};
    }
  }

  /// 🔥 NUEVO: Heartbeat de emergencia (para situaciones críticas)
  Future<ApiResponse<bool>> enviarHeartbeatEmergencia({
    required String usuarioId,
    required String eventoId,
    required String tipoEmergencia, // 'app_closing', 'connection_lost', etc.
  }) async {
    try {
      debugPrint('🚨 Enviando heartbeat de EMERGENCIA: $tipoEmergencia');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay token para heartbeat de emergencia');
      }

      final emergencyData = {
        'usuarioId': usuarioId,
        'eventoId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
        'tipo': 'emergency_heartbeat',
        'emergencyType': tipoEmergencia,
        'sessionId': _getOrCreateSessionId(),
        'platform': Platform.operatingSystem,
        'urgente': true,
      };

      // ✅ Timeout más corto para emergencias con endpoint correcto
      final response = await _apiService
          .post(
            AppConstants.heartbeatEndpoint, // '/asistencia/heartbeat'
            body: emergencyData,
            headers: AppConstants.getAuthHeaders(token),
          )
          .timeout(
            const Duration(seconds: 10), // Timeout reducido para emergencias
          );

      if (response.success) {
        debugPrint('✅ Heartbeat de emergencia enviado');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(
          response.error ?? 'Error en heartbeat de emergencia');
    } catch (e) {
      debugPrint('❌ Error crítico en heartbeat de emergencia: $e');
      return ApiResponse.error('Error crítico: $e');
    }
  }

  /// 🔥 NUEVO: Obtener o crear Session ID único
  String _getOrCreateSessionId() {
    if (_sessionId == null) {
      _sessionId =
          '${DateTime.now().millisecondsSinceEpoch}_${Platform.operatingSystem}';
      debugPrint('🆔 Session ID creado: $_sessionId');
    }
    return _sessionId!;
  }

  /// 🔥 NUEVO: Reset de session (para nuevos eventos)
  void resetSession() {
    debugPrint('🔄 Reseteando session de heartbeat');
    _sessionId = null;
    _heartbeatSequence = 0;
  }

  /// 🔥 NUEVO: Obtener estadísticas de heartbeat
  Map<String, dynamic> getHeartbeatStatistics() {
    return {
      'session_id': _sessionId ?? 'no_session',
      'total_heartbeats_sent': _heartbeatSequence,
      'session_start_time': _sessionId != null
          ? DateTime.fromMillisecondsSinceEpoch(
                  int.tryParse(_sessionId!.split('_')[0]) ?? 0)
              .toIso8601String()
          : null,
    };
  }

  /// Obtener métricas de un evento específico
  Future<ApiResponse<Map<String, dynamic>>> obtenerMetricasEvento(
      String eventoId) async {
    try {
      debugPrint('📊 Obteniendo métricas del evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.get(
        '/dashboard/metrics/event/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }

      return ApiResponse.error(response.error ?? 'Error obteniendo métricas');
    } catch (e) {
      debugPrint('❌ Error obteniendo métricas del evento: $e');
      rethrow;
    }
  }

  /// 🔥 NUEVO: Test de conexión rápido para validaciones
  Future<ApiResponse<bool>> testConnection() async {
    try {
      debugPrint('🔍 Testing conexión al backend');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay token para test');
      }

      // ✅ Usar endpoint público de health que no requiere autenticación
      final response = await _apiService.get(
        '/firestore/health', // Endpoint público de health check
        headers: AppConstants.defaultHeaders, // Sin token de autenticación
      );

      final isConnected = response.success;
      debugPrint(
          '📡 Test de conexión: ${isConnected ? "✅ CONECTADO" : "❌ SIN CONEXIÓN"}');

      return ApiResponse.success(isConnected);
    } catch (e) {
      debugPrint('❌ Error en test de conexión: $e');
      return ApiResponse.error('Sin conexión: $e');
    }
  }

  // 🎯 MÉTODO CRÍTICO 2: Marcar ausente específicamente por cierre de app
  Future<ApiResponse<bool>> marcarAusentePorCierreApp({
    required String usuarioId,
    required String eventoId,
    String? razonEspecifica,
  }) async {
    try {
      debugPrint('🚨 Marcando ausente por cierre de app');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.post(
        AppConstants.marcarAusenteEndpoint, // '/asistencia/marcar-ausente'
        body: {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'razon': 'app_closed_30s',
          'detalles':
              razonEspecifica ?? 'Aplicación cerrada por más de 30 segundos',
          'timestamp': DateTime.now().toIso8601String(),
          'gracePeriodExpired': true,
          'platform': Platform.operatingSystem,
          'automatico': true,
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Marcado como ausente por cierre de app');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(response.error ?? 'Error marcando ausente');
    } catch (e) {
      debugPrint('❌ Excepción marcando ausente: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> validarEstadoTracking({
    required String usuarioId,
    required String eventoId,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🔍 Validando estado de tracking en backend');

      final response = await _apiService.get(
        '/asistencia/estado-tracking/$eventoId/$usuarioId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        final data = response.data ?? {};

        debugPrint('✅ Estado de tracking obtenido del backend');
        debugPrint('📊 Estado: ${data['tracking_status']}');
        debugPrint('📊 Último heartbeat: ${data['last_heartbeat']}');

        return ApiResponse.success(data);
      }

      return ApiResponse.error(response.error ?? 'Error validando estado');
    } catch (e) {
      debugPrint('❌ Error validando estado: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> obtenerComandosPendientes({
    required String usuarioId,
    required String eventoId,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.get(
        '/asistencia/comandos-pendientes/$eventoId/$usuarioId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        final comandos = (response.data?['comandos'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

        debugPrint('📡 Comandos pendientes obtenidos: ${comandos.length}');
        return ApiResponse.success(comandos);
      }

      return ApiResponse.error(response.error ?? 'Error obteniendo comandos');
    } catch (e) {
      debugPrint('❌ Error obteniendo comandos: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  Future<ApiResponse<bool>> actualizarUbicacionConEstado({
    required String usuarioId,
    required String eventoId,
    required double latitud,
    required double longitud,
    required bool isAppActive,
    bool isInGracePeriod = false,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🌍 Actualizando ubicación con estado de app');

      final response = await _apiService.post(
        AppConstants.locationEndpoint, // '/location/update'
        body: {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'latitud': latitud,
          'longitud': longitud,
          'timestamp': DateTime.now().toIso8601String(),
          'appStatus': isAppActive ? 'foreground' : 'background',
          'isInGracePeriod': isInGracePeriod,
          'accuracy': 5.0, // GPS preciso
          'altitude': 0.0,
          'speed': 0.0,
          'heading': 0.0,
          'platform': Platform.operatingSystem,
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Ubicación actualizada con estado de app');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(
          response.error ?? 'Error actualizando ubicación');
    } catch (e) {
      debugPrint('❌ Error actualizando ubicación: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  // ✅ ENHANCED: Registration with improved error handling and retry logic
  Future<ApiResponse<bool>> registrarAsistencia({
    required String eventoId,
    required String usuarioId,
    required double latitud,
    required double longitud,
    String estado = 'presente',
    String? observaciones,
    bool validateAppState = true,
  }) async {
    debugPrint('📝 Registrando asistencia con validaciones DÍA 4');

    return _executeWithRetry<bool>(
      () async {
        final token = await _storageService.getToken();
        if (token == null) {
          return ApiResponse.error('No hay sesión activa');
        }

        // ✅ CORREGIDO: Solo enviar lo que el backend espera
        final registroCompleto = {
          'eventoId': eventoId,
          'latitud': latitud,
          'longitud': longitud,
          // Backend solo usa estos 3 campos - resto lo ignora
        };

        final response = await _apiService.post(
          AppConstants.asistenciaEndpoint,
          body: registroCompleto,
          headers: AppConstants.getAuthHeaders(token),
        );

        if (response.success) {
          return ApiResponse.success(true);
        }

        return ApiResponse.error(response.error ?? 'Error registrando asistencia');
      },
      operationName: 'RegistrarAsistencia',
      shouldRetry: true, // Critical operation, retry on transient failures
      maxRetries: 2, // Fewer retries for registration to avoid duplicates
    );
  }

  // ✅ NUEVO: Validar si el heartbeat está funcionando correctamente
  Future<bool> isHeartbeatHealthy() async {
    try {
      final connectionTest = await testConnection();
      return connectionTest.success;
    } catch (e) {
      return false;
    }
  }

  // ✅ NUEVO: Cleanup de resources para heartbeat
  void cleanupHeartbeatResources() {
    debugPrint('🧹 Limpiando recursos de heartbeat');
    resetSession();
  }

  // 🎯 MÉTODO CRÍTICO 3: Registrar eventos específicos de geofence
  Future<ApiResponse<bool>> registrarEventoGeofence({
    required String usuarioId,
    required String eventoId,
    required bool entrando, // true = entrando, false = saliendo
    required double latitud,
    required double longitud,
  }) async {
    try {
      final tipoEvento = entrando ? 'entrada_area' : 'salida_area';
      debugPrint('📍 Registrando $tipoEvento de geofence');

      final response = await actualizarUbicacion(
        usuarioId: usuarioId,
        eventoId: eventoId,
        latitud: latitud,
        longitud: longitud,
      );

      if (response.success) {
        debugPrint('✅ Evento geofence registrado: $tipoEvento');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(response.error ?? 'Error registrando geofence');
    } catch (e) {
      debugPrint('❌ Excepción registrando geofence: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  // 🔧 MÉTODOS UTILITARIOS

  bool _esLinkValido(String link) {
    // Validar que sea una URL válida
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return false;
    }

    // Validar dominios permitidos para documentos
    final dominiosPermitidos = [
      'drive.google.com',
      'docs.google.com',
      'onedrive.live.com',
      '1drv.ms',
      'dropbox.com',
      'docdroid.net',
      'scribd.com',
    ];

    return dominiosPermitidos.any((dominio) => uri.host.contains(dominio));
  }

  // Validar link de documento específico
  bool validarLinkValido(String url) {
    return _esLinkValido(url);
  }

  // Obtener dominios permitidos para UI
  List<String> get dominiosPermitidos => [
        'Google Drive (drive.google.com)',
        'Google Docs (docs.google.com)',
        'OneDrive (onedrive.live.com)',
        'OneDrive Short (1drv.ms)',
        'Dropbox (dropbox.com)',
        'DocDroid (docdroid.net)',
        'Scribd (scribd.com)',
      ];

  // Limpiar cache de asistencias (útil para debugging)
  void limpiarCache() {
    debugPrint('🧹 Limpiando cache de AsistenciaService');
    // En el futuro se puede implementar cache local si es necesario
  }

  // Obtener resumen de asistencias por estado
  Map<String, int> obtenerResumenEstados(List<Asistencia> asistencias) {
    final resumen = <String, int>{
      'presente': 0,
      'ausente': 0,
      'tarde': 0,
      'justificado': 0,
      'receso': 0,
    };

    for (final asistencia in asistencias) {
      resumen[asistencia.estado] = (resumen[asistencia.estado] ?? 0) + 1;
    }

    return resumen;
  }

  // Calcular porcentaje de asistencia de un usuario
  double calcularPorcentajeAsistencia(List<Asistencia> asistenciasUsuario) {
    if (asistenciasUsuario.isEmpty) return 0.0;

    final presentes = asistenciasUsuario
        .where((a) => a.estado == 'presente' || a.estado == 'tarde')
        .length;

    return (presentes / asistenciasUsuario.length) * 100;
  }
}
