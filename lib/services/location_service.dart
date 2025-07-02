// lib/services/location_service.dart
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse<Map<String, dynamic>>> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    bool? previousState,
    String? eventoId,
  }) async {
    try {
      final body = {
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (previousState != null) 'previousState': previousState,
        if (eventoId != null) 'eventoId': eventoId,
      };

      final response = await _apiService.post(
        AppConstants.locationEndpoint,
        body: body,
      );

      if (response.success) {
        return ApiResponse.success(response.data!, message: response.message);
      }

      return ApiResponse.error(
          response.error ?? 'Error al actualizar ubicación');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }
}
