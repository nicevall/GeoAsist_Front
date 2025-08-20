// lib/utils/location_helper.dart
import '../core/app_constants.dart';

/// Utilidad centralizada para manejo de ubicaciones en el frontend
class LocationHelper {
  
  /// Crear datos de ubicación con formato consistente
  static Map<String, dynamic> createLocationData({
    required double latitude,
    required double longitude,
    String? address,
    double range = 100.0,
  }) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address ?? 'Ubicación personalizada',
      'range': range,
    };
  }
  
  /// Validar si los datos de ubicación son válidos
  static bool isLocationValid(Map<String, dynamic>? location) {
    if (location == null) return false;
    
    final lat = location['latitude'];
    final lng = location['longitude'];
    
    return lat != null && lng != null &&
           lat is double && lng is double &&
           lat >= -90 && lat <= 90 &&
           lng >= -180 && lng <= 180;
  }
  
  /// Obtener ubicación por defecto (UIDE Campus Quito)
  static Map<String, dynamic> getDefaultLocation() {
    return {
      'latitude': AppConstants.defaultLatitude,
      'longitude': AppConstants.defaultLongitude,
      'address': AppConstants.defaultAddress,
      'range': AppConstants.defaultRange,
    };
  }
  
  /// Verificar si una ubicación es la ubicación por defecto
  static bool isDefaultLocation(double latitude, double longitude) {
    const double tolerance = 0.00001; // Tolerancia para comparación de doubles
    return (latitude - AppConstants.defaultLatitude).abs() < tolerance && 
           (longitude - AppConstants.defaultLongitude).abs() < tolerance;
  }
  
  /// Formatear ubicación para mostrar en la UI
  static String formatLocationForDisplay(Map<String, dynamic> location) {
    final lat = location['latitude']?.toStringAsFixed(6) ?? '0.0';
    final lng = location['longitude']?.toStringAsFixed(6) ?? '0.0';
    final address = location['address'] ?? location['locationName'] ?? 'Sin dirección';
    
    return '$address\nLat: $lat, Lng: $lng';
  }
  
  /// Formatear coordenadas para mostrar en formato compacto
  static String formatCoordinates(double latitude, double longitude) {
    return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
  }
  
  /// Validar datos de ubicación antes del envío al backend
  static ValidationResult validateLocationBeforeSend({
    required double latitude,
    required double longitude,
    required String locationName,
    required double range,
  }) {
    final errors = <String>[];
    
    // Validar coordenadas
    if (latitude < -90 || latitude > 90) {
      errors.add('Latitud debe estar entre -90 y 90 grados');
    }
    
    if (longitude < -180 || longitude > 180) {
      errors.add('Longitud debe estar entre -180 y 180 grados');
    }
    
    // Validar rango
    if (range <= 0 || range > 1000) {
      errors.add('Rango debe estar entre 1 y 1000 metros');
    }
    
    // Validar nombre de ubicación
    if (locationName.trim().isEmpty) {
      errors.add('Nombre de ubicación no puede estar vacío');
    }
    
    // Verificar si las coordenadas son exactamente 0,0 (probablemente un error)
    if (latitude == 0.0 && longitude == 0.0) {
      errors.add('Coordenadas (0,0) probablemente indican un error de ubicación');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Calcular distancia entre dos puntos (aproximada)
  static double calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const double earthRadius = 6371000; // Radio de la Tierra en metros
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    
    final double a = 
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Verificar si una ubicación está dentro del rango de otra
  static bool isWithinRange(
    double userLat, double userLng,
    double eventLat, double eventLng,
    double rangeMeters,
  ) {
    final double distance = calculateDistance(userLat, userLng, eventLat, eventLng);
    return distance <= rangeMeters;
  }
  
  /// Normalizar datos de ubicación del LocationPicker
  static Map<String, dynamic> normalizeLocationPickerResult(Map<String, dynamic> result) {
    return {
      'latitude': result['latitude'] ?? result['lat'] ?? 0.0,
      'longitude': result['longitude'] ?? result['lng'] ?? 0.0,
      'address': result['locationName'] ?? result['address'] ?? 'Ubicación personalizada',
      'range': result['range'] ?? 100.0,
    };
  }
  
  /// Obtener resumen de ubicación para logs de depuración
  static String getLocationSummary({
    required double latitude,
    required double longitude,
    required String locationName,
    required double range,
  }) {
    final isDefault = isDefaultLocation(latitude, longitude);
    return '''
=== RESUMEN DE UBICACIÓN ===
Nombre: $locationName
Coordenadas: ${formatCoordinates(latitude, longitude)}
Rango: ${range.toInt()}m
¿Es ubicación por defecto?: $isDefault
===========================''';
  }
  
  // Métodos matemáticos auxiliares
  static double _toRadians(double degrees) => degrees * (3.14159265359 / 180);
  static double _sin(double x) => double.parse((x).toStringAsFixed(10));
  static double _cos(double x) => double.parse((1 - x * x / 2).toStringAsFixed(10));
  static double _sqrt(double x) => double.parse((x).toStringAsFixed(10));
  static double _atan2(double y, double x) => double.parse((y / x).toStringAsFixed(10));
}

/// Resultado de validación de ubicación
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  String get errorMessage => errors.join(', ');
}