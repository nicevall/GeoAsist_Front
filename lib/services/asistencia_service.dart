// lib/services/asistencia_service.dart
import '../models/asistencia_model.dart';
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

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
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final body = {
        'eventoId': eventoId,
        'latitud': latitud,
        'longitud': longitud,
      };

      final response = await _apiService.post(
        AppConstants.asistenciaEndpoint,
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final asistenciaData = response.data!['asistencia'];
        if (asistenciaData != null) {
          final asistencia = Asistencia.fromJson(asistenciaData);
          return ApiResponse.success(asistencia, message: response.message);
        }
      }

      return ApiResponse.error(
          response.error ?? 'Error al registrar asistencia');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 1: Métricas específicas por evento (para dashboard docente)
  Future<ApiResponse<Map<String, dynamic>>> obtenerMetricasEvento(
      String eventoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.get(
        '/dashboard/metrics/event/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        // ✅ CORREGIDO - Verificar que data no sea null antes de pasarlo
        final data = response.data!;
        return ApiResponse.success(data);
      }

      return ApiResponse.error(response.error ?? 'Error obteniendo métricas');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 2: Estadísticas básicas del estudiante
  Future<ApiResponse<Map<String, dynamic>>> obtenerEstadisticasEstudiante(
      String estudianteId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.get(
        '/usuarios/perfil/$estudianteId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        // ✅ CORREGIDO - Verificar que data no sea null antes de usarlo
        final userData = response.data!;
        final stats = {
          'totalEventos': userData['eventosInscritos']?.length ?? 0,
          'asistenciaPromedio': _calcularPromedioAsistencia(userData),
          'ultimaAsistencia': userData['ultimaAsistencia'],
        };

        return ApiResponse.success(stats);
      }

      return ApiResponse.error(
          response.error ?? 'Error obteniendo estadísticas');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // Método auxiliar privado
  double _calcularPromedioAsistencia(Map<String, dynamic> userData) {
    // Implementar cálculo basado en datos disponibles
    return 85.0; // Placeholder - implementar lógica real
  }
}
