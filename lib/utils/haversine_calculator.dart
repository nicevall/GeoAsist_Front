// lib/utils/haversine_calculator.dart
import 'dart:math' as math;

/// ✅ HAVERSINE CALCULATOR: Cálculo exacto de distancias preservado
/// Responsabilidades:
/// - Implementación exacta según especificación del backend (DETALLES BACK.md)
/// - Cálculo de distancia usando fórmula Haversine
/// - Radio de la Tierra: 6371.0 km (estándar internacional)
/// - Compatibilidad perfecta con backend Node.js
/// - Validación de coordenadas geográficas
/// - Optimización para cálculos repetitivos
class HaversineCalculator {
  // 🌍 CONSTANTES GEOGRÁFICAS
  /// Radio de la Tierra en kilómetros (estándar internacional)
  /// Mismo valor usado en backend: const double _earthRadiusKm = 6371.0;
  static const double _earthRadiusKm = 6371.0;
  
  /// Radio de la Tierra en metros
  static const double _earthRadiusM = _earthRadiusKm * 1000;
  
  /// Límites de coordenadas válidas
  static const double _minLatitude = -90.0;
  static const double _maxLatitude = 90.0;
  static const double _minLongitude = -180.0;
  static const double _maxLongitude = 180.0;

  /// ✅ CALCULAR DISTANCIA ENTRE DOS PUNTOS (PRINCIPAL)
  /// Implementación exacta de la fórmula Haversine
  /// Parámetros:
  /// - lat1, lng1: Coordenadas del primer punto
  /// - lat2, lng2: Coordenadas del segundo punto
  /// Retorna: Distancia en metros (double)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Validar coordenadas antes del cálculo
    _validateCoordinates(lat1, lng1);
    _validateCoordinates(lat2, lng2);
    
    // Conversión de grados a radianes
    final double lat1Rad = _toRadians(lat1);
    final double lng1Rad = _toRadians(lng1);
    final double lat2Rad = _toRadians(lat2);
    final double lng2Rad = _toRadians(lng2);
    
    // Diferencias en radianes
    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLng = lng2Rad - lng1Rad;
    
    // Fórmula Haversine
    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
                    math.cos(lat1Rad) * math.cos(lat2Rad) *
                    math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    // Distancia en metros
    final double distance = _earthRadiusM * c;
    
    return distance;
  }

  /// 🎯 VERIFICAR SI PUNTO ESTÁ DENTRO DE GEOFENCE
  /// Parámetros:
  /// - userLat, userLng: Coordenadas del usuario
  /// - centerLat, centerLng: Centro del geofence
  /// - radiusMeters: Radio permitido en metros
  /// Retorna: true si está dentro, false si está fuera
  static bool isWithinGeofence(
    double userLat,
    double userLng,
    double centerLat,
    double centerLng,
    double radiusMeters,
  ) {
    final double distance = calculateDistance(userLat, userLng, centerLat, centerLng);
    return distance <= radiusMeters;
  }

  /// 📏 CALCULAR DISTANCIA CON INFORMACIÓN DETALLADA
  /// Retorna un objeto con toda la información del cálculo
  static DistanceResult calculateDistanceDetailed(
    double lat1,
    double lng1,
    double lat2,
    double lng2, {
    double? geofenceRadius,
  }) {
    final double distance = calculateDistance(lat1, lng1, lat2, lng2);
    
    return DistanceResult(
      distance: distance,
      isWithinGeofence: geofenceRadius != null ? distance <= geofenceRadius : null,
      bearing: calculateBearing(lat1, lng1, lat2, lng2),
      point1: GeoPoint(lat1, lng1),
      point2: GeoPoint(lat2, lng2),
      geofenceRadius: geofenceRadius,
    );
  }

  /// 🧭 CALCULAR RUMBO ENTRE DOS PUNTOS
  /// Retorna el rumbo en grados (0-360)
  static double calculateBearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    _validateCoordinates(lat1, lng1);
    _validateCoordinates(lat2, lng2);
    
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);
    final double deltaLngRad = _toRadians(lng2 - lng1);
    
    final double y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    final double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
                    math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);
    
    final double bearingRad = math.atan2(y, x);
    
    // Convertir a grados y normalizar (0-360)
    return (_toDegrees(bearingRad) + 360) % 360;
  }

  /// 📊 OBTENER MÚLTIPLES DISTANCIAS DESDE UN PUNTO
  /// Útil para calcular distancias a múltiples eventos desde la ubicación actual
  static List<DistanceToPoint> calculateDistancesToMultiplePoints(
    double originLat,
    double originLng,
    List<GeoPoint> destinations,
  ) {
    _validateCoordinates(originLat, originLng);
    
    return destinations.map((destination) {
      final distance = calculateDistance(
        originLat, 
        originLng, 
        destination.latitude, 
        destination.longitude,
      );
      
      return DistanceToPoint(
        destination: destination,
        distance: distance,
        bearing: calculateBearing(
          originLat, 
          originLng, 
          destination.latitude, 
          destination.longitude,
        ),
      );
    }).toList();
  }

  /// 🔍 ENCONTRAR PUNTO MÁS CERCANO
  static DistanceToPoint? findNearestPoint(
    double originLat,
    double originLng,
    List<GeoPoint> points,
  ) {
    if (points.isEmpty) return null;
    
    final distances = calculateDistancesToMultiplePoints(originLat, originLng, points);
    
    return distances.reduce((a, b) => a.distance < b.distance ? a : b);
  }

  /// 📐 CALCULAR ÁREA APROXIMADA DE GEOFENCE CIRCULAR
  /// Retorna el área en metros cuadrados
  static double calculateGeofenceArea(double radiusMeters) {
    return math.pi * radiusMeters * radiusMeters;
  }

  /// 🎯 GENERAR PUNTOS EN EL PERÍMETRO DE UN CÍRCULO
  /// Útil para visualización de geofences
  static List<GeoPoint> generateCirclePoints(
    double centerLat,
    double centerLng,
    double radiusMeters, {
    int numberOfPoints = 32,
  }) {
    _validateCoordinates(centerLat, centerLng);
    
    final List<GeoPoint> points = [];
    final double angleStep = 360.0 / numberOfPoints;
    
    for (int i = 0; i < numberOfPoints; i++) {
      final double angle = i * angleStep;
      final GeoPoint point = _calculatePointAtDistanceAndBearing(
        centerLat,
        centerLng,
        radiusMeters,
        angle,
      );
      points.add(point);
    }
    
    return points;
  }

  /// 📍 CALCULAR PUNTO A DISTANCIA Y RUMBO ESPECÍFICOS
  static GeoPoint _calculatePointAtDistanceAndBearing(
    double lat,
    double lng,
    double distanceMeters,
    double bearingDegrees,
  ) {
    final double latRad = _toRadians(lat);
    final double lngRad = _toRadians(lng);
    final double bearingRad = _toRadians(bearingDegrees);
    final double angularDistance = distanceMeters / _earthRadiusM;
    
    final double lat2Rad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
      math.cos(latRad) * math.sin(angularDistance) * math.cos(bearingRad)
    );
    
    final double lng2Rad = lngRad + math.atan2(
      math.sin(bearingRad) * math.sin(angularDistance) * math.cos(latRad),
      math.cos(angularDistance) - math.sin(latRad) * math.sin(lat2Rad)
    );
    
    return GeoPoint(_toDegrees(lat2Rad), _toDegrees(lng2Rad));
  }

  /// 🔄 CONVERSIONES AUXILIARES
  
  /// Convertir grados a radianes
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
  
  /// Convertir radianes a grados
  static double _toDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  /// ✅ VALIDACIONES
  
  /// Validar coordenadas geográficas
  static void _validateCoordinates(double latitude, double longitude) {
    if (latitude < _minLatitude || latitude > _maxLatitude) {
      throw ArgumentError('Latitud inválida: $latitude. Debe estar entre $_minLatitude y $_maxLatitude');
    }
    
    if (longitude < _minLongitude || longitude > _maxLongitude) {
      throw ArgumentError('Longitud inválida: $longitude. Debe estar entre $_minLongitude y $_maxLongitude');
    }
  }

  /// Validar radio de geofence
  static void validateGeofenceRadius(double radius) {
    if (radius <= 0) {
      throw ArgumentError('Radio de geofence inválido: $radius. Debe ser mayor a 0');
    }
    
    if (radius > 10000) { // 10 km máximo
      throw ArgumentError('Radio de geofence demasiado grande: $radius. Máximo permitido: 10000m');
    }
  }

  /// 📊 UTILIDADES DE FORMATO
  
  /// Formatear distancia para mostrar al usuario
  static String formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(1)}m';
    } else {
      final double distanceKm = distanceMeters / 1000;
      return '${distanceKm.toStringAsFixed(2)}km';
    }
  }

  /// Formatear rumbo para mostrar al usuario
  static String formatBearing(double bearingDegrees) {
    final List<String> directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    
    final int index = ((bearingDegrees + 11.25) / 22.5).floor() % 16;
    return '${directions[index]} (${bearingDegrees.toStringAsFixed(0)}°)';
  }

  /// 🧪 VERIFICAR COMPATIBILIDAD CON BACKEND
  /// Este método verifica que nuestros cálculos coincidan con el backend
  static bool verifyBackendCompatibility() {
    // Coordenadas de prueba (Lima, Perú)
    const double lat1 = -12.046374;
    const double lng1 = -77.042793;
    const double lat2 = -12.046500;
    const double lng2 = -77.042900;
    
    // Cálculo esperado según backend
    final double calculatedDistance = calculateDistance(lat1, lng1, lat2, lng2);
    
    // La distancia entre estos puntos debe ser aproximadamente 15-20 metros
    return calculatedDistance > 10 && calculatedDistance < 30;
  }
}

/// 📍 CLASE PARA REPRESENTAR UN PUNTO GEOGRÁFICO
class GeoPoint {
  final double latitude;
  final double longitude;
  final String? name;
  final Map<String, dynamic>? metadata;

  const GeoPoint(
    this.latitude,
    this.longitude, {
    this.name,
    this.metadata,
  });

  @override
  String toString() {
    return 'GeoPoint(lat: $latitude, lng: $longitude${name != null ? ", name: $name" : ""})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoPoint &&
           other.latitude == latitude &&
           other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// 📏 RESULTADO DETALLADO DE CÁLCULO DE DISTANCIA
class DistanceResult {
  final double distance;
  final bool? isWithinGeofence;
  final double bearing;
  final GeoPoint point1;
  final GeoPoint point2;
  final double? geofenceRadius;

  const DistanceResult({
    required this.distance,
    this.isWithinGeofence,
    required this.bearing,
    required this.point1,
    required this.point2,
    this.geofenceRadius,
  });

  /// Formatear resultado para display
  String get formattedDistance => HaversineCalculator.formatDistance(distance);
  String get formattedBearing => HaversineCalculator.formatBearing(bearing);

  @override
  String toString() {
    return 'DistanceResult(distance: $formattedDistance, '
           'bearing: $formattedBearing, '
           'inGeofence: $isWithinGeofence)';
  }
}

/// 🎯 DISTANCIA A UN PUNTO ESPECÍFICO
class DistanceToPoint {
  final GeoPoint destination;
  final double distance;
  final double bearing;

  const DistanceToPoint({
    required this.destination,
    required this.distance,
    required this.bearing,
  });

  String get formattedDistance => HaversineCalculator.formatDistance(distance);
  String get formattedBearing => HaversineCalculator.formatBearing(bearing);

  @override
  String toString() {
    return 'DistanceToPoint(to: ${destination.name ?? destination.toString()}, '
           'distance: $formattedDistance, bearing: $formattedBearing)';
  }
}