// lib/services/location_service.dart
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/location_response_model.dart';
import 'package:geolocator/geolocator.dart';

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

  /// 🆕 MÉTODO A1.1: Actualizar ubicación y obtener respuesta completa del backend
  Future<LocationResponseModel?> updateUserLocationComplete({
    required String userId,
    required double latitude,
    required double longitude,
    required String eventoId,
    bool backgroundUpdate = false,
  }) async {
    try {
      debugPrint('📍 Enviando ubicación completa al backend');
      debugPrint('   - Usuario: $userId');
      debugPrint('   - Coordenadas: ($latitude, $longitude)');
      debugPrint('   - Evento: $eventoId');
      debugPrint('   - Background: $backgroundUpdate');

      // Enviar ubicación al backend
      final response = await _apiService.post(
        AppConstants.locationEndpoint,
        body: {
          'userId': userId,
          'latitude': latitude,
          'longitude': longitude,
          'eventoId': eventoId,
          'backgroundUpdate': backgroundUpdate,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success && response.data != null) {
        // ✅ PROCESAR RESPUESTA COMPLETA DEL BACKEND
        final locationResponse =
            LocationResponseModel.fromSimpleResponse(response.data!);

        debugPrint('✅ Respuesta del backend procesada:');
        debugPrint(
            '   - Dentro del geofence: ${locationResponse.insideGeofence}');
        debugPrint('   - Distancia: ${locationResponse.distance}m');
        debugPrint('   - Evento activo: ${locationResponse.eventActive}');
        debugPrint(
            '   - Puede registrar: ${locationResponse.canRegisterAttendance}');

        return locationResponse;
      } else {
        debugPrint('❌ Error en respuesta del backend: ${response.message}');
        return LocationResponseModel.error(userId, latitude, longitude);
      }
    } catch (e) {
      debugPrint('❌ Error en updateUserLocationComplete: $e');
      return LocationResponseModel.error(userId, latitude, longitude);
    }
  }

  /// 🆕 MÉTODO A1.1: Obtener posición GPS actual
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('📍 Obteniendo posición GPS actual');

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Permisos de ubicación denegados');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permisos de ubicación denegados permanentemente');
        return null;
      }

      // Obtener posición con configuración optimizada
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
          '✅ Posición obtenida: (${position.latitude}, ${position.longitude})');
      debugPrint('   - Precisión: ${position.accuracy}m');

      return position;
    } catch (e) {
      debugPrint('❌ Error obteniendo posición GPS: $e');
      return null;
    }
  }
}
