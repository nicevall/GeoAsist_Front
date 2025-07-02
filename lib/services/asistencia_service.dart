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
}
