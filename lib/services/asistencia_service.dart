// lib/services/asistencia_service.dart
import '../models/asistencia_model.dart';
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AsistenciaService {
  static final AsistenciaService _instance = AsistenciaService._internal();
  factory AsistenciaService() => _instance;
  AsistenciaService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<ApiResponse<Asistencia>> registrarAsistencia({
    required String eventoId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      debugPrint('📍 Registering attendance for event: $eventoId');
      debugPrint('🗺️ Location: $latitud, $longitud');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No active session found');
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🎫 Token found, proceeding with registration');

      final body = {
        'eventoId': eventoId,
        'latitud': latitud,
        'longitud': longitud,
      };

      debugPrint('📦 Attendance payload: ${jsonEncode(body)}');

      final response = await _apiService.post(
        AppConstants.asistenciaEndpoint,
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Attendance response success: ${response.success}');

      if (response.success && response.data != null) {
        final asistenciaData = response.data!['asistencia'];
        if (asistenciaData != null) {
          final asistencia = Asistencia.fromJson(asistenciaData);
          debugPrint('✅ Attendance registered successfully: ${asistencia.id}');
          return ApiResponse.success(asistencia, message: response.message);
        } else {
          debugPrint('❌ No attendance data in response');
        }
      }

      debugPrint('❌ Attendance registration failed: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error al registrar asistencia');
    } catch (e) {
      debugPrint('❌ Attendance registration exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 1: Métricas específicas por evento (para dashboard docente)
  Future<ApiResponse<Map<String, dynamic>>> obtenerMetricasEvento(
      String eventoId) async {
    try {
      debugPrint('📊 Loading metrics for event: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for metrics request');
        return ApiResponse.error('No hay sesión activa');
      }

      final endpoint = '/dashboard/metrics/event/$eventoId';
      debugPrint('🌐 Metrics endpoint: $endpoint');

      final response = await _apiService.get(
        endpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📊 Metrics response success: ${response.success}');

      if (response.success && response.data != null) {
        final data = response.data!;
        debugPrint('📊 Metrics loaded: ${data.keys.join(', ')}');
        return ApiResponse.success(data);
      }

      debugPrint('❌ Failed to load metrics: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error obteniendo métricas');
    } catch (e) {
      debugPrint('❌ Metrics exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 2: Estadísticas básicas del estudiante
  Future<ApiResponse<Map<String, dynamic>>> obtenerEstadisticasEstudiante(
      String estudianteId) async {
    try {
      debugPrint('👨‍🎓 Loading student statistics for: $estudianteId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for student statistics request');
        return ApiResponse.error('No hay sesión activa');
      }

      final endpoint = '/usuarios/perfil/$estudianteId';
      debugPrint('🌐 Student profile endpoint: $endpoint');

      final response = await _apiService.get(
        endpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📊 Student profile response success: ${response.success}');

      if (response.success && response.data != null) {
        final userData = response.data!;
        debugPrint('📊 Profile data keys: ${userData.keys.join(', ')}');

        final stats = {
          'totalEventos': userData['eventosInscritos']?.length ?? 0,
          'asistenciaPromedio': _calcularPromedioAsistencia(userData),
          'ultimaAsistencia': userData['ultimaAsistencia'],
          'estudianteId': estudianteId,
          'nombre': userData['usuario']?['nombre'] ?? 'Usuario',
        };

        debugPrint('✅ Student statistics calculated: ${stats.keys.join(', ')}');
        return ApiResponse.success(stats);
      }

      debugPrint('❌ Failed to load student statistics: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error obteniendo estadísticas');
    } catch (e) {
      debugPrint('❌ Student statistics exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 3: Obtener historial de asistencias del estudiante
  Future<ApiResponse<List<Map<String, dynamic>>>> obtenerHistorialAsistencias(
      String estudianteId) async {
    try {
      debugPrint('📚 Loading attendance history for student: $estudianteId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for attendance history request');
        return ApiResponse.error('No hay sesión activa');
      }

      final endpoint = '/asistencia/historial/$estudianteId';
      debugPrint('🌐 Attendance history endpoint: $endpoint');

      final response = await _apiService.get(
        endpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📊 Attendance history response success: ${response.success}');

      if (response.success && response.data != null) {
        final historialData = response.data!['asistencias'] ?? [];
        debugPrint(
            '✅ Attendance history loaded: ${historialData.length} records');

        final historial = List<Map<String, dynamic>>.from(historialData);
        return ApiResponse.success(historial);
      }

      debugPrint('❌ Failed to load attendance history: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error obteniendo historial');
    } catch (e) {
      debugPrint('❌ Attendance history exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // Método auxiliar privado para calcular promedio de asistencia
  double _calcularPromedioAsistencia(Map<String, dynamic> userData) {
    try {
      debugPrint('🧮 Calculating attendance average from user data');

      // Implementar lógica basada en datos reales del backend
      final asistencias = userData['asistencias'] ?? [];
      final totalEventos = userData['eventosInscritos']?.length ?? 0;

      if (totalEventos == 0) {
        debugPrint('📊 No events found, returning 0.0 average');
        return 0.0;
      }

      final asistenciasCount = asistencias.length;
      final promedio = (asistenciasCount / totalEventos) * 100;

      debugPrint(
          '📊 Calculated average: $asistenciasCount/$totalEventos = ${promedio.toStringAsFixed(1)}%');
      return promedio;
    } catch (e) {
      debugPrint('❌ Error calculating attendance average: $e');
      return 85.0; // Valor por defecto
    }
  }

  // 🎯 MÉTODO 4: Verificar estado de asistencia para un evento específico
  Future<ApiResponse<Map<String, dynamic>>> verificarEstadoAsistencia({
    required String eventoId,
    required String estudianteId,
  }) async {
    try {
      debugPrint(
          '🔍 Checking attendance status for event: $eventoId, student: $estudianteId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for attendance status check');
        return ApiResponse.error('No hay sesión activa');
      }

      final endpoint = '/asistencia/estado/$eventoId/$estudianteId';
      debugPrint('🌐 Attendance status endpoint: $endpoint');

      final response = await _apiService.get(
        endpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📊 Attendance status response success: ${response.success}');

      if (response.success && response.data != null) {
        final statusData = response.data!;
        debugPrint(
            '✅ Attendance status loaded: ${statusData['estado'] ?? 'unknown'}');
        return ApiResponse.success(statusData);
      }

      debugPrint('❌ Failed to check attendance status: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error verificando estado');
    } catch (e) {
      debugPrint('❌ Attendance status check exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 5: Actualizar asistencia existente (para correcciones)
  Future<ApiResponse<Asistencia>> actualizarAsistencia({
    required String asistenciaId,
    required Map<String, dynamic> datosActualizados,
  }) async {
    try {
      debugPrint('🔄 Updating attendance: $asistenciaId');
      debugPrint('📝 Update data: ${jsonEncode(datosActualizados)}');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for attendance update');
        return ApiResponse.error('No hay sesión activa');
      }

      final endpoint = '/asistencia/$asistenciaId';
      debugPrint('🌐 Update attendance endpoint: $endpoint');

      final response = await _apiService.put(
        endpoint,
        body: datosActualizados,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📊 Update attendance response success: ${response.success}');

      if (response.success && response.data != null) {
        final asistenciaData = response.data!['asistencia'];
        if (asistenciaData != null) {
          final asistencia = Asistencia.fromJson(asistenciaData);
          debugPrint('✅ Attendance updated successfully: ${asistencia.id}');
          return ApiResponse.success(asistencia, message: response.message);
        } else {
          debugPrint('❌ No attendance data in update response');
        }
      }

      debugPrint('❌ Failed to update attendance: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error actualizando asistencia');
    } catch (e) {
      debugPrint('❌ Update attendance exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }
}
