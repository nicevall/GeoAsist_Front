// lib/models/location_response_model.dart
// 🌍 MODELO DE RESPUESTA DE UBICACIÓN FASE A1.1 - Mapear respuesta completa del backend
// VERSIÓN CORREGIDA - Sin JSON serialization automática

class LocationResponseModel {
  // 🎯 RESPUESTA PRINCIPAL DEL BACKEND POST /location/update

  /// Indica si el usuario está dentro del geofence del evento
  final bool insideGeofence;

  /// Distancia en metros desde el usuario hasta el centro del evento
  final double distance;

  /// Indica si el evento está actualmente activo
  final bool eventActive;

  /// Indica si el evento ya ha comenzado (puede registrar asistencia)
  final bool eventStarted;

  /// ID del usuario que envió la ubicación
  final String userId;

  /// Latitud confirmada por el backend
  final double latitude;

  /// Longitud confirmada por el backend
  final double longitude;

  /// Timestamp de cuando el backend procesó la ubicación
  final DateTime? timestamp;

  /// Información adicional del evento (opcional)
  final EventLocationInfo? eventInfo;

  const LocationResponseModel({
    required this.insideGeofence,
    required this.distance,
    required this.eventActive,
    required this.eventStarted,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.timestamp,
    this.eventInfo,
  });

  // 🏭 FACTORY METHODS

  /// Factory manual para parsear JSON del backend
  factory LocationResponseModel.fromJson(Map<String, dynamic> json) {
    return LocationResponseModel(
      insideGeofence: json['insideGeofence'] ?? false,
      distance: (json['distance'] ?? 0.0).toDouble(),
      eventActive: json['eventActive'] ?? false,
      eventStarted: json['eventStarted'] ?? false,
      userId: json['userId'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventInfo: json['eventInfo'] != null
          ? EventLocationInfo.fromJson(
              json['eventInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertir a JSON para envío al backend
  Map<String, dynamic> toJson() {
    return {
      'insideGeofence': insideGeofence,
      'distance': distance,
      'eventActive': eventActive,
      'eventStarted': eventStarted,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp?.toIso8601String(),
      'eventInfo': eventInfo?.toJson(),
    };
  }

  // 🏭 FACTORY: CREAR DESDE RESPUESTA SIMPLE
  factory LocationResponseModel.fromSimpleResponse(Map<String, dynamic> data) {
    return LocationResponseModel(
      insideGeofence: data['insideGeofence'] ?? false,
      distance: (data['distance'] ?? 0.0).toDouble(),
      eventActive: data['eventActive'] ?? false,
      eventStarted: data['eventStarted'] ?? false,
      userId: data['userId'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  // 🏭 FACTORY: ESTADO DE ERROR
  factory LocationResponseModel.error(String userId, double lat, double lng) {
    return LocationResponseModel(
      insideGeofence: false,
      distance: 0.0,
      eventActive: false,
      eventStarted: false,
      userId: userId,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );
  }

  // 🔄 COPYWITH
  LocationResponseModel copyWith({
    bool? insideGeofence,
    double? distance,
    bool? eventActive,
    bool? eventStarted,
    String? userId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    EventLocationInfo? eventInfo,
  }) {
    return LocationResponseModel(
      insideGeofence: insideGeofence ?? this.insideGeofence,
      distance: distance ?? this.distance,
      eventActive: eventActive ?? this.eventActive,
      eventStarted: eventStarted ?? this.eventStarted,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      eventInfo: eventInfo ?? this.eventInfo,
    );
  }

  // 🔍 GETTERS COMPUTADOS

  /// Indica si la respuesta es válida
  bool get isValid => userId.isNotEmpty && latitude != 0.0 && longitude != 0.0;

  /// Indica si el usuario puede registrar asistencia
  /// ✅ PERMITIR REGISTRO EN EVENTOS NO INICIADOS
  /// Los estudiantes pueden registrarse como "registrado" si están dentro del geofence
  /// independientemente de si el evento ha iniciado o no
  bool get canRegisterAttendance =>
      eventActive && insideGeofence;

  /// Obtiene el estado de proximidad legible
  String get proximityStatus {
    if (!eventActive) return 'Evento inactivo';
    if (!eventStarted) return 'Evento no iniciado';
    if (insideGeofence) return 'Dentro del área';
    return 'Fuera del área (${distance.toStringAsFixed(1)}m)';
  }

  /// Obtiene el color del estado
  String get statusColor {
    if (!eventActive) return '#9E9E9E'; // Gris
    if (!eventStarted) return '#FFC107'; // Amarillo
    if (insideGeofence) return '#4CAF50'; // Verde
    return '#FF4444'; // Rojo
  }

  /// Indica si es una situación crítica
  bool get isCritical => eventActive && eventStarted && !insideGeofence;

  /// Texto de distancia formateado
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  // 🐛 DEBUGGING

  @override
  String toString() {
    return 'LocationResponse('
        'inside: $insideGeofence, '
        'distance: ${distance.toStringAsFixed(1)}m, '
        'eventActive: $eventActive, '
        'eventStarted: $eventStarted, '
        'user: $userId, '
        'coords: ($latitude, $longitude)'
        ')';
  }

  Map<String, dynamic> toDebugMap() {
    return {
      'insideGeofence': insideGeofence,
      'distance': distance,
      'eventActive': eventActive,
      'eventStarted': eventStarted,
      'userId': userId,
      'coordinates': {'lat': latitude, 'lng': longitude},
      'timestamp': timestamp?.toIso8601String(),
      'canRegister': canRegisterAttendance,
      'status': proximityStatus,
    };
  }
}

// 🎯 INFORMACIÓN ADICIONAL DEL EVENTO (OPCIONAL)
class EventLocationInfo {
  /// Nombre del evento
  final String eventName;

  /// Radio del geofence en metros
  final double geofenceRadius;

  /// Coordenadas del centro del evento
  final double eventLatitude;
  final double eventLongitude;

  /// Tiempo restante del evento en minutos
  final int? timeRemainingMinutes;

  const EventLocationInfo({
    required this.eventName,
    required this.geofenceRadius,
    required this.eventLatitude,
    required this.eventLongitude,
    this.timeRemainingMinutes,
  });

  /// Factory manual para parsear JSON
  factory EventLocationInfo.fromJson(Map<String, dynamic> json) {
    return EventLocationInfo(
      eventName: json['eventName'] ?? '',
      geofenceRadius: (json['geofenceRadius'] ?? 100.0).toDouble(),
      eventLatitude: (json['eventLatitude'] ?? 0.0).toDouble(),
      eventLongitude: (json['eventLongitude'] ?? 0.0).toDouble(),
      timeRemainingMinutes: json['timeRemainingMinutes'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'geofenceRadius': geofenceRadius,
      'eventLatitude': eventLatitude,
      'eventLongitude': eventLongitude,
      'timeRemainingMinutes': timeRemainingMinutes,
    };
  }

  @override
  String toString() {
    return 'EventLocationInfo('
        'name: $eventName, '
        'radius: ${geofenceRadius}m, '
        'center: ($eventLatitude, $eventLongitude), '
        'remaining: ${timeRemainingMinutes}min'
        ')';
  }
}
