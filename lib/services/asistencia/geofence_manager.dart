// lib/services/asistencia/geofence_manager.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../models/evento_model.dart';
import '../../models/ubicacion_model.dart';

/// ✅ GEOFENCE MANAGER: Detección de área y cálculo Haversine
/// Responsabilidades:
/// - Cálculo Haversine exacto del backend (distancia en metros)
/// - Detección entrada/salida de geocerca
/// - Validación de coordenadas GPS válidas
/// - Registro de eventos geofence con timestamps
/// - Monitoreo continuo de posición relativa
class GeofenceManager {
  static final GeofenceManager _instance = GeofenceManager._internal();
  factory GeofenceManager() => _instance;
  GeofenceManager._internal();

  // ⚙️ CONFIGURACIÓN GEOFENCE
  static const double _earthRadiusKm = 6371.0; // Radio de la Tierra en km
  static const double _validLatitudeRange = 90.0;
  static const double _validLongitudeRange = 180.0;
  static const double _minAccuracyMeters = 50.0; // Precisión mínima GPS

  // 🎯 ESTADO ACTUAL
  Evento? _currentEvent;
  Ubicacion? _lastValidLocation;
  bool _isInsideGeofence = false;
  DateTime? _lastGeofenceChange;
  double? _lastCalculatedDistance;

  // 🔄 STREAMS
  final StreamController<GeofenceEvent> _geofenceController = 
      StreamController<GeofenceEvent>.broadcast();

  /// Stream para escuchar eventos de geofence
  Stream<GeofenceEvent> get geofenceStream => _geofenceController.stream;

  /// ✅ CONFIGURAR EVENTO PARA MONITOREO
  void configureEvent(Evento evento) {
    debugPrint('🎯 Configuring geofence for event: ${evento.titulo}');
    debugPrint('📍 Event location: ${evento.ubicacion.latitud}, ${evento.ubicacion.longitud}');
    debugPrint('📏 Event radius: ${evento.rangoPermitido}m');
    
    _currentEvent = evento;
    _lastValidLocation = null;
    _isInsideGeofence = false;
    _lastGeofenceChange = null;
    _lastCalculatedDistance = null;
  }

  /// ✅ VERIFICAR POSICIÓN ACTUAL
  GeofenceResult checkPosition(double latitude, double longitude, {double? accuracy}) {
    debugPrint('📱 Checking position: $latitude, $longitude (accuracy: ${accuracy ?? 'unknown'}m)');

    // 1. Validar coordenadas
    final validationResult = validateCoordinates(latitude, longitude);
    if (!validationResult.isValid) {
      debugPrint('❌ Invalid coordinates: ${validationResult.error}');
      return GeofenceResult.invalid(validationResult.error!);
    }

    // 2. Validar que hay evento configurado
    if (_currentEvent == null) {
      debugPrint('❌ No event configured for geofence');
      return GeofenceResult.error('No event configured');
    }

    // 3. Validar precisión GPS si disponible
    if (accuracy != null && accuracy > _minAccuracyMeters) {
      debugPrint('⚠️ Low GPS accuracy: ${accuracy}m (min: $_minAccuracyMeters m)');
      return GeofenceResult.lowAccuracy(accuracy);
    }

    // 4. Calcular distancia usando Haversine
    final distance = calculateHaversineDistance(
      latitude, longitude,
      _currentEvent!.ubicacion.latitud, _currentEvent!.ubicacion.longitud,
    );

    _lastCalculatedDistance = distance;
    _lastValidLocation = Ubicacion(latitud: latitude, longitud: longitude);

    debugPrint('📏 Distance to event: ${distance.toStringAsFixed(2)}m (radius: ${_currentEvent!.rangoPermitido}m)');

    // 5. Determinar si está dentro de la geocerca
    final isInside = distance <= _currentEvent!.rangoPermitido;
    final previousState = _isInsideGeofence;

    // 6. Detectar cambio de estado
    if (isInside != previousState) {
      _isInsideGeofence = isInside;
      _lastGeofenceChange = DateTime.now();
      
      final event = GeofenceEvent(
        type: isInside ? GeofenceEventType.entered : GeofenceEventType.exited,
        timestamp: _lastGeofenceChange!,
        location: Ubicacion(latitud: latitude, longitud: longitude),
        distance: distance,
        eventId: _currentEvent!.id,
        accuracy: accuracy,
      );

      debugPrint('🚨 Geofence ${isInside ? 'ENTERED' : 'EXITED'} - Distance: ${distance.toStringAsFixed(2)}m');
      _emitGeofenceEvent(event);
    }

    // 7. Crear resultado
    return GeofenceResult.success(
      isInside: isInside,
      distance: distance,
      accuracy: accuracy,
    );
  }

  /// 🧮 CÁLCULO HAVERSINE (EXACTO DEL BACKEND)
  /// Implementación idéntica al backend para consistencia
  double calculateHaversineDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    // Convertir grados a radianes
    final lat1Rad = _degreesToRadians(lat1);
    final lon1Rad = _degreesToRadians(lon1);
    final lat2Rad = _degreesToRadians(lat2);
    final lon2Rad = _degreesToRadians(lon2);

    // Diferencias
    final deltaLat = lat2Rad - lat1Rad;
    final deltaLon = lon2Rad - lon1Rad;

    // Fórmula Haversine
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLon / 2) * math.sin(deltaLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Distancia en metros
    final distanceKm = _earthRadiusKm * c;
    final distanceMeters = distanceKm * 1000;

    return distanceMeters;
  }

  /// ✅ VALIDAR COORDENADAS
  CoordinateValidation validateCoordinates(double latitude, double longitude) {
    // Validar latitud
    if (latitude.isNaN || latitude.isInfinite) {
      return CoordinateValidation.invalid('Latitude is not a valid number');
    }
    if (latitude.abs() > _validLatitudeRange) {
      return CoordinateValidation.invalid('Latitude must be between -90 and 90 degrees');
    }

    // Validar longitud
    if (longitude.isNaN || longitude.isInfinite) {
      return CoordinateValidation.invalid('Longitude is not a valid number');
    }
    if (longitude.abs() > _validLongitudeRange) {
      return CoordinateValidation.invalid('Longitude must be between -180 and 180 degrees');
    }

    // Validar que no sean coordenadas por defecto (0,0)
    if (latitude == 0.0 && longitude == 0.0) {
      return CoordinateValidation.invalid('Invalid default coordinates (0,0)');
    }

    return CoordinateValidation.valid();
  }

  /// 📊 OBTENER ESTADO ACTUAL
  GeofenceStatus getCurrentStatus() {
    return GeofenceStatus(
      isConfigured: _currentEvent != null,
      isInsideGeofence: _isInsideGeofence,
      lastLocation: _lastValidLocation,
      lastDistance: _lastCalculatedDistance,
      lastGeofenceChange: _lastGeofenceChange,
      eventLocation: _currentEvent?.ubicacion,
      eventRadius: _currentEvent?.rangoPermitido,
    );
  }

  /// 🔄 EMITIR EVENTO GEOFENCE
  void _emitGeofenceEvent(GeofenceEvent event) {
    if (!_geofenceController.isClosed) {
      _geofenceController.add(event);
    }
  }

  /// ⚙️ UTILIDADES PRIVADAS
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// 🧹 CLEANUP
  void dispose() {
    debugPrint('🧹 Disposing GeofenceManager');
    
    _geofenceController.close();
    _currentEvent = null;
    _lastValidLocation = null;
    
    debugPrint('🧹 GeofenceManager disposed');
  }
}

/// ✅ RESULTADO DE VERIFICACIÓN GEOFENCE
class GeofenceResult {
  final bool isSuccess;
  final bool isInside;
  final double? distance;
  final double? accuracy;
  final String? error;
  final GeofenceResultType type;

  const GeofenceResult._({
    required this.isSuccess,
    required this.isInside,
    this.distance,
    this.accuracy,
    this.error,
    required this.type,
  });

  factory GeofenceResult.success({
    required bool isInside,
    required double distance,
    double? accuracy,
  }) {
    return GeofenceResult._(
      isSuccess: true,
      isInside: isInside,
      distance: distance,
      accuracy: accuracy,
      type: GeofenceResultType.success,
    );
  }

  factory GeofenceResult.invalid(String error) {
    return GeofenceResult._(
      isSuccess: false,
      isInside: false,
      error: error,
      type: GeofenceResultType.invalidCoordinates,
    );
  }

  factory GeofenceResult.lowAccuracy(double accuracy) {
    return GeofenceResult._(
      isSuccess: false,
      isInside: false,
      accuracy: accuracy,
      error: 'GPS accuracy too low: ${accuracy}m',
      type: GeofenceResultType.lowAccuracy,
    );
  }

  factory GeofenceResult.error(String error) {
    return GeofenceResult._(
      isSuccess: false,
      isInside: false,
      error: error,
      type: GeofenceResultType.error,
    );
  }

  @override
  String toString() {
    return 'GeofenceResult(success: $isSuccess, inside: $isInside, '
           'distance: ${distance?.toStringAsFixed(2)}m, error: $error)';
  }
}

/// ✅ TIPOS DE RESULTADO GEOFENCE
enum GeofenceResultType {
  success,
  invalidCoordinates,
  lowAccuracy,
  error,
}

/// ✅ EVENTO DE GEOFENCE
class GeofenceEvent {
  final GeofenceEventType type;
  final DateTime timestamp;
  final Ubicacion location;
  final double distance;
  final String? eventId;
  final double? accuracy;

  const GeofenceEvent({
    required this.type,
    required this.timestamp,
    required this.location,
    required this.distance,
    this.eventId,
    this.accuracy,
  });

  @override
  String toString() {
    return 'GeofenceEvent(type: $type, distance: ${distance.toStringAsFixed(2)}m, '
           'timestamp: ${timestamp.toIso8601String()})';
  }
}

/// ✅ TIPOS DE EVENTO GEOFENCE
enum GeofenceEventType {
  entered,  // Entró a la geocerca
  exited,   // Salió de la geocerca
}

/// ✅ VALIDACIÓN DE COORDENADAS
class CoordinateValidation {
  final bool isValid;
  final String? error;

  const CoordinateValidation._(this.isValid, this.error);

  factory CoordinateValidation.valid() {
    return const CoordinateValidation._(true, null);
  }

  factory CoordinateValidation.invalid(String error) {
    return CoordinateValidation._(false, error);
  }
}

/// ✅ ESTADO ACTUAL DEL GEOFENCE
class GeofenceStatus {
  final bool isConfigured;
  final bool isInsideGeofence;
  final Ubicacion? lastLocation;
  final double? lastDistance;
  final DateTime? lastGeofenceChange;
  final Ubicacion? eventLocation;
  final double? eventRadius;

  const GeofenceStatus({
    required this.isConfigured,
    required this.isInsideGeofence,
    this.lastLocation,
    this.lastDistance,
    this.lastGeofenceChange,
    this.eventLocation,
    this.eventRadius,
  });

  @override
  String toString() {
    return 'GeofenceStatus(configured: $isConfigured, inside: $isInsideGeofence, '
           'distance: ${lastDistance?.toStringAsFixed(2)}m)';
  }
}