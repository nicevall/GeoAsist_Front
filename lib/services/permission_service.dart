// lib/services/permission_service.dart
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Solicita permisos de ubicación de forma escalonada
  Future<LocationPermissionResult> requestLocationPermissions() async {
    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      // 2. Verificar permisos actuales
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // 3. Solicitar permisos por primera vez
        permission = await Geolocator.requestPermission();
      }

      // 4. Manejar diferentes estados
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionResult.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionResult.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionResult.granted;
        default:
          return LocationPermissionResult.denied;
      }
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      return LocationPermissionResult.error;
    }
  }

  /// Verifica si ya tenemos permisos de ubicación
  Future<bool> hasLocationPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error verificando permisos: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual del dispositivo
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await hasLocationPermissions()) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Abre la configuración de la app para permisos
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Error abriendo configuración: $e');
    }
  }

  /// Stream de ubicación en tiempo real
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Solo actualizar si se mueve 5+ metros
      ),
    );
  }
}

/// Resultado de la solicitud de permisos
enum LocationPermissionResult {
  granted, // Permisos concedidos
  denied, // Permisos denegados
  deniedForever, // Permisos denegados permanentemente
  serviceDisabled, // Servicio GPS deshabilitado
  error, // Error al solicitar
}
