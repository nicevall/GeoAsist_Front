// lib/services/asistencia/asistencia_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/app_constants.dart';
import '../../core/api_endpoints.dart';
import '../../core/backend_sync_service.dart';
import '../../core/error_handler.dart';
import '../../utils/haversine_calculator.dart';
import '../../models/api_response_model.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';
import '../../models/asistencia_model.dart';
import '../api_service.dart';
import '../storage_service.dart';
import 'heartbeat_manager.dart';
import 'geofence_manager.dart';
import '../attendance/attendance_state_manager.dart';

/// ✅ ASISTENCIA SERVICE MODULAR: Coordinador principal de asistencia
/// Responsabilidades:
/// - API pública para registro de asistencia
/// - Integración con backend siguiendo flujo exacto
/// - Coordinación entre HeartbeatManager, GeofenceManager y AttendanceStateManager
/// - Validaciones de negocio antes de registro
/// - Manejo de errores y retry logic
/// - Session management para tracking
class AsistenciaService {
  static final AsistenciaService _instance = AsistenciaService._internal();
  factory AsistenciaService() => _instance;
  AsistenciaService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final BackendSyncService _syncService = BackendSyncService();
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // 🎯 MANAGERS ESPECIALIZADOS
  final HeartbeatManager _heartbeatManager = HeartbeatManager();
  final GeofenceManager _geofenceManager = GeofenceManager();
  final AttendanceStateManager _stateManager = AttendanceStateManager();

  // ⚙️ CONFIGURACIÓN
  static const int _maxRetries = 3;

  /// ✅ REGISTRAR ASISTENCIA (MÉTODO PRINCIPAL)
  /// Implementa exactamente el flujo del backend documentado en DETALLES BACK.md
  Future<ApiResponse<bool>> registrarAsistencia({
    required String eventoId,
    required String usuarioId,
    required double latitud,
    required double longitud,
    String? estado,
    String? observaciones,
  }) async {
    logger.d('📝 [AsistenciaService] Registrando asistencia para evento: $eventoId');
    logger.d('📍 Coordenadas: $latitud, $longitud');

    try {
      // 1. Validar que hay sesión activa
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      // 2. Validar coordenadas usando Haversine Calculator
      try {
        HaversineCalculator.calculateDistance(latitud, longitud, latitud, longitud);
      } catch (e) {
        return ApiResponse.error('Coordenadas inválidas: ${e.toString()}');
      }
      
      final coordinateValidation = _geofenceManager.validateCoordinates(latitud, longitud);
      if (!coordinateValidation.isValid) {
        return ApiResponse.error('Coordenadas inválidas: ${coordinateValidation.error}');
      }

      // 3. Preparar datos según formato backend
      final registroData = {
        'eventoId': eventoId,
        'usuarioId': usuarioId,
        'latitud': latitud,
        'longitud': longitud,
        'fecha': DateTime.now().toIso8601String().split('T')[0],
        'hora': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 4. Agregar estado y observaciones si se proporcionan
      if (estado != null) registroData['estado'] = estado;
      if (observaciones != null) registroData['observaciones'] = observaciones;

      logger.d('📤 Datos a enviar: $registroData');

      // 5. Enviar al backend con retry mejorado usando ErrorHandler
      final response = await _errorHandler.executeWithRetry(() async {
        return await _apiService.post(
          ApiEndpoints.registerAttendance,
          body: registroData,
          headers: AppConstants.getAuthHeaders(token),
        );
      }, context: 'registrarAsistencia', maxRetries: _maxRetries);

      if (response.success) {
        logger.d('✅ Asistencia registrada exitosamente');
        
        // 6. Actualizar estado local si el registro fue exitoso
        _updateLocalStateAfterRegistration(latitud, longitud, response.data);
        
        // 7. Sincronizar con backend service
        _syncService.addPendingOperation(SyncOperation(
          type: SyncOperationType.attendance,
          data: registroData,
          method: 'POST',
        ));
        
        return ApiResponse.success(true, message: 'Asistencia registrada exitosamente');
      } else {
        final appError = _errorHandler.handleError(response.error ?? 'Error registrando asistencia', context: 'registrarAsistencia');
        logger.d('❌ Error registrando asistencia: ${appError.message}');
        return ApiResponse.error(appError.userFriendlyMessage);
      }

    } catch (e) {
      logger.d('❌ Excepción registrando asistencia: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// ✅ ACTUALIZAR UBICACIÓN EN TIEMPO REAL
  Future<ApiResponse<Map<String, dynamic>>> actualizarUbicacion({
    required double latitud,
    required double longitud,
    String? eventoId,
  }) async {
    logger.d('📍 [AsistenciaService] Actualizando ubicación: $latitud, $longitud');

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final locationData = {
        'latitud': latitud,
        'longitud': longitud,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (eventoId != null) {
        locationData['eventoId'] = eventoId;
      }

      final response = await _apiService.post(
        '/location/update',
        body: locationData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        logger.d('✅ Ubicación actualizada exitosamente');
        return ApiResponse.success(response.data ?? {});
      } else {
        logger.d('❌ Error actualizando ubicación: ${response.error}');
        return ApiResponse.error(response.error ?? 'Error actualizando ubicación');
      }

    } catch (e) {
      logger.d('❌ Error actualizando ubicación: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// ✅ OBTENER ASISTENCIAS DE UN EVENTO
  Future<List<Asistencia>> obtenerAsistenciasEvento(String eventoId) async {
    logger.d('👥 [AsistenciaService] Obteniendo asistencias del evento: $eventoId');

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No hay sesión activa');
        return [];
      }

      final response = await _apiService.get(
        '/asistencia/evento/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final List<dynamic> asistenciasData = response.data!['asistencias'] ?? response.data!;
        final asistencias = asistenciasData.map((data) => Asistencia.fromJson(data)).toList();

        logger.d('✅ Asistencias cargadas: ${asistencias.length} registros');
        return asistencias;
      }

      logger.d('❌ Error obteniendo asistencias: ${response.error}');
      return [];
    } catch (e) {
      logger.d('❌ Excepción obteniendo asistencias: $e');
      return [];
    }
  }

  /// ✅ OBTENER HISTORIAL DE USUARIO
  Future<List<Asistencia>> obtenerHistorialUsuario(String usuarioId) async {
    logger.d('📚 [AsistenciaService] Obteniendo historial del usuario: $usuarioId');

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No hay sesión activa');
        return [];
      }

      final response = await _apiService.get(
        '/asistencia/usuario/$usuarioId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final List<dynamic> asistenciasData = response.data!['asistencias'] ?? response.data!;
        final asistencias = asistenciasData.map((data) => Asistencia.fromJson(data)).toList();

        // Ordenar por fecha más reciente primero
        asistencias.sort((a, b) => b.fecha.compareTo(a.fecha));

        logger.d('✅ Historial cargado: ${asistencias.length} registros');
        return asistencias;
      }

      logger.d('❌ Error obteniendo historial: ${response.error}');
      return [];
    } catch (e) {
      logger.d('❌ Excepción obteniendo historial: $e');
      return [];
    }
  }

  /// ✅ ENVIAR JUSTIFICACIÓN
  Future<ApiResponse<bool>> enviarJustificacion({
    required String eventoId,
    required String usuarioId,
    required String linkDocumento,
    String? motivo,
  }) async {
    logger.d('📄 [AsistenciaService] Enviando justificación');

    try {
      if (!_esLinkValido(linkDocumento)) {
        return ApiResponse.error('El link proporcionado no es válido');
      }

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
        'latitud': 0.0,
        'longitud': 0.0,
      };

      return await registrarAsistencia(
        eventoId: eventoId,
        usuarioId: usuarioId,
        latitud: 0.0,
        longitud: 0.0,
        estado: 'justificado',
        observaciones: justificacionData['observaciones'] as String,
      );

    } catch (e) {
      logger.d('❌ Excepción enviando justificación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// ✅ MARCAR COMO AUSENTE
  Future<ApiResponse<bool>> marcarAusente({
    required String usuarioId,
    required String eventoId,
    required String motivo,
  }) async {
    logger.d('❌ [AsistenciaService] Marcando usuario como ausente: $motivo');

    return await registrarAsistencia(
      eventoId: eventoId,
      usuarioId: usuarioId,
      latitud: 0.0,
      longitud: 0.0,
      estado: 'ausente',
      observaciones: motivo,
    );
  }

  /// ⚙️ UTILIDADES PRIVADAS


  /// Actualizar estado local después de registro exitoso
  void _updateLocalStateAfterRegistration(double lat, double lng, Map<String, dynamic>? responseData) {
    // Notificar a los managers sobre el registro exitoso
    logger.d('📊 Actualizando estado local después de registro exitoso');
    
    // El estado será manejado por AttendanceStateManager según la respuesta del backend
    if (responseData != null && responseData.containsKey('estado')) {
      final estadoBackend = responseData['estado'].toString();
      logger.d('📊 Estado retornado por backend: $estadoBackend');
    }
  }

  /// Validar si es un link válido
  bool _esLinkValido(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 🧹 CLEANUP
  void dispose() {
    logger.d('🧹 Disposing AsistenciaService');
    
    _heartbeatManager.dispose();
    _geofenceManager.dispose();
    _stateManager.dispose();
    
    logger.d('🧹 AsistenciaService disposed');
  }
}