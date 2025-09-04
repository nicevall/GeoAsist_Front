import '../../domain/entities/event_entity.dart';

/// **EventModel**: Data Transfer Object for event management and API integration
/// 
/// **Purpose**: Handles JSON serialization/deserialization for event data from backend
/// **AI Context**: Bridge between external API and domain entities with backend field mapping
/// **Dependencies**: EventEntity and all related value objects
/// **Used by**: EventRepository, ApiService, local storage operations
/// **Performance**: Optimized for frequent JSON parsing with comprehensive validation
class EventModel extends EventEntity {
  const EventModel({
    required super.eventIdentifier,
    required super.eventTitle,
    required super.eventDescription,
    required super.eventLocationName,
    required super.eventCoordinates,
    required super.scheduleInfo,
    required super.creatorInfo,
    required super.eventStatus,
    required super.eventType,
    required super.attendancePolicies,
    required super.currentRegisteredCount,
    required super.eventCreatedAt,
    required super.lastUpdatedAt,
    super.maximumParticipantsAllowed,
  });

  /// **Factory**: Create EventModel from backend JSON response
  /// **AI Context**: Parses API response with backend field names and Spanish conventions
  /// **Input**: Map with String keys and dynamic values from HTTP response
  /// **Output**: EventModel with validated and parsed data
  /// **Error Cases**: Missing required fields, invalid coordinates, malformed dates
  factory EventModel.fromBackendJson(Map<String, dynamic> backendJson) {
    try {
      // AI Context: Handle multiple ID field formats from different endpoints
      final eventId = backendJson['_id']?.toString() ?? 
                      backendJson['id']?.toString() ?? 
                      '';
                      
      if (eventId.isEmpty) {
        throw ArgumentError('Event ID is required but was empty or null');
      }

      // AI Context: Parse geolocation coordinates with validation
      final coordenadas = backendJson['coordenadas'] as Map<String, dynamic>? ?? {};
      final latitude = _parseDoubleFromDynamic(coordenadas['latitud']);
      final longitude = _parseDoubleFromDynamic(coordenadas['longitud']);
      final radio = _parseDoubleFromDynamic(coordenadas['radio']) ?? 100.0;

      if (latitude == null || longitude == null) {
        throw ArgumentError('Event coordinates are required: latitude and longitude');
      }

      final coordinates = EventGeolocationCoordinates(
        latitude: latitude,
        longitude: longitude,
        geofenceRadiusMeters: radio,
        accuracyMeters: _parseDoubleFromDynamic(coordenadas['precision']) ?? 10.0,
      );

      // AI Context: Parse schedule information with timezone handling
      final scheduleInfo = _parseScheduleInfoFromBackend(backendJson);

      // AI Context: Parse creator information
      final creatorInfo = _parseCreatorInfoFromBackend(backendJson);

      // AI Context: Parse attendance policies with default values
      final attendancePolicies = _parseAttendancePoliciesFromBackend(backendJson);

      // AI Context: Parse event status and type with validation
      final eventStatus = _parseEventStatusFromBackend(backendJson['estado']?.toString());
      final eventType = _parseEventTypeFromBackend(backendJson['tipo']?.toString());

      // AI Context: Parse timestamps with null safety
      final createdAt = _parseDateTimeFromBackend(backendJson['fechaCreacion']);
      final updatedAt = _parseDateTimeFromBackend(backendJson['fechaActualizacion'] ?? backendJson['fechaCreacion']);

      return EventModel(
        eventIdentifier: eventId,
        eventTitle: backendJson['nombre']?.toString() ?? '',
        eventDescription: backendJson['descripcion']?.toString() ?? '',
        eventLocationName: backendJson['lugar']?.toString() ?? '',
        eventCoordinates: coordinates,
        scheduleInfo: scheduleInfo,
        creatorInfo: creatorInfo,
        eventStatus: eventStatus,
        eventType: eventType,
        attendancePolicies: attendancePolicies,
        maximumParticipantsAllowed: backendJson['capacidadMaxima'] != null 
            ? int.tryParse(backendJson['capacidadMaxima'].toString())
            : null,
        currentRegisteredCount: int.tryParse(backendJson['participantesRegistrados']?.length?.toString() ?? '0') ?? 0,
        eventCreatedAt: createdAt,
        lastUpdatedAt: updatedAt,
      );
    } catch (e) {
      throw FormatException('Error parsing EventModel from backend JSON: ${e.toString()}');
    }
  }

  /// **Method**: Convert EventModel to backend-compatible JSON
  /// **AI Context**: Serializes for API requests with backend field names (Spanish)
  /// **Output**: Map with String keys and dynamic values for HTTP request body
  /// **Side Effects**: None - pure data transformation
  Map<String, dynamic> toBackendJson() {
    return {
      'nombre': eventTitle,
      'descripcion': eventDescription,
      'lugar': eventLocationName,
      'coordenadas': {
        'latitud': eventCoordinates.latitude,
        'longitud': eventCoordinates.longitude,
        'radio': eventCoordinates.geofenceRadiusMeters,
        'precision': eventCoordinates.accuracyMeters,
      },
      'fechaInicio': scheduleInfo.eventStartDateTime.toIso8601String(),
      'fechaFin': scheduleInfo.eventEndDateTime.toIso8601String(),
      'zonaHoraria': scheduleInfo.timeZone,
      'esDeTodoElDia': scheduleInfo.isAllDayEvent,
      'estado': _eventStatusToBackendString(eventStatus),
      'tipo': _eventTypeToBackendString(eventType),
      'capacidadMaxima': maximumParticipantsAllowed,
      'politicasAsistencia': {
        'requiereGeovalidacion': attendancePolicies.requiresGeolocationValidation,
        'permiteAnulacionManual': attendancePolicies.allowsManualAttendanceOverride,
        'duracionMinimaMinutos': attendancePolicies.minimumAttendanceDurationMinutes,
        'enviaNotificaciones': attendancePolicies.sendsAttendanceNotifications,
        'periodoGracia': {
          'llegadaTemprana': attendancePolicies.gracePeriodsConfig.earlyArrivalMinutes,
          'llegadaTardia': attendancePolicies.gracePeriodsConfig.lateArrivalMinutes,
          'salidaTemprana': attendancePolicies.gracePeriodsConfig.earlyDepartureMinutes,
        },
      },
    };
  }

  /// **Method**: Convert to simplified JSON for local storage
  /// **AI Context**: Lighter format for SharedPreferences or local cache
  /// **Output**: Minimal JSON with essential fields only
  Map<String, dynamic> toLocalStorageJson() {
    return {
      'id': eventIdentifier,
      'nombre': eventTitle,
      'descripcion': eventDescription,
      'lugar': eventLocationName,
      'coordenadas': {
        'latitud': eventCoordinates.latitude,
        'longitud': eventCoordinates.longitude,
        'radio': eventCoordinates.geofenceRadiusMeters,
      },
      'fechaInicio': scheduleInfo.eventStartDateTime.toIso8601String(),
      'fechaFin': scheduleInfo.eventEndDateTime.toIso8601String(),
      'estado': eventStatus.name,
      'tipo': eventType.name,
      'creadorId': creatorInfo.creatorUserId,
      'creadorNombre': creatorInfo.creatorDisplayName,
      'participantesCount': currentRegisteredCount,
      'capacidadMaxima': maximumParticipantsAllowed,
      'fechaCreacion': eventCreatedAt.toIso8601String(),
      'fechaActualizacion': lastUpdatedAt.toIso8601String(),
    };
  }

  /// **Factory**: Create EventModel from local storage JSON
  /// **AI Context**: Parses data from SharedPreferences or local cache
  /// **Input**: Map with String keys and dynamic values from local storage
  /// **Output**: EventModel instance
  factory EventModel.fromLocalStorageJson(Map<String, dynamic> localJson) {
    try {
      final coordenadas = localJson['coordenadas'] as Map<String, dynamic>;
      
      final coordinates = EventGeolocationCoordinates(
        latitude: coordenadas['latitud']?.toDouble() ?? 0.0,
        longitude: coordenadas['longitud']?.toDouble() ?? 0.0,
        geofenceRadiusMeters: coordenadas['radio']?.toDouble() ?? 100.0,
      );

      final scheduleInfo = EventScheduleInfo(
        eventStartDateTime: DateTime.parse(localJson['fechaInicio']),
        eventEndDateTime: DateTime.parse(localJson['fechaFin']),
        timeZone: 'America/Guayaquil', // Default timezone
      );

      final creatorInfo = EventCreatorInfo(
        creatorUserId: localJson['creadorId']?.toString() ?? '',
        creatorDisplayName: localJson['creadorNombre']?.toString() ?? '',
        creatorEmailAddress: '', // Not stored in local cache
        creatorRoleType: 'profesor', // Default role
      );

      final attendancePolicies = EventAttendancePolicies(
        gracePeriodsConfig: const EventGracePeriodConfiguration(),
      );

      return EventModel(
        eventIdentifier: localJson['id']?.toString() ?? '',
        eventTitle: localJson['nombre']?.toString() ?? '',
        eventDescription: localJson['descripcion']?.toString() ?? '',
        eventLocationName: localJson['lugar']?.toString() ?? '',
        eventCoordinates: coordinates,
        scheduleInfo: scheduleInfo,
        creatorInfo: creatorInfo,
        eventStatus: EventStatusType.values.firstWhere(
          (status) => status.name == localJson['estado']?.toString(),
          orElse: () => EventStatusType.draft,
        ),
        eventType: EventType.values.firstWhere(
          (type) => type.name == localJson['tipo']?.toString(),
          orElse: () => EventType.lecture,
        ),
        attendancePolicies: attendancePolicies,
        maximumParticipantsAllowed: localJson['capacidadMaxima'] != null 
            ? int.tryParse(localJson['capacidadMaxima'].toString())
            : null,
        currentRegisteredCount: int.tryParse(localJson['participantesCount']?.toString() ?? '0') ?? 0,
        eventCreatedAt: DateTime.parse(localJson['fechaCreacion']),
        lastUpdatedAt: DateTime.parse(localJson['fechaActualizacion']),
      );
    } catch (e) {
      throw FormatException('Error parsing EventModel from local storage: ${e.toString()}');
    }
  }

  /// **Method**: Create copy of EventModel with modified properties
  /// **AI Context**: Immutable object pattern for state management
  /// **Override**: Extends parent copyWith to return EventModel type
  @override
  EventModel copyWith({
    String? eventIdentifier,
    String? eventTitle,
    String? eventDescription,
    String? eventLocationName,
    EventGeolocationCoordinates? eventCoordinates,
    EventScheduleInfo? scheduleInfo,
    EventCreatorInfo? creatorInfo,
    EventStatusType? eventStatus,
    EventType? eventType,
    int? maximumParticipantsAllowed,
    int? currentRegisteredCount,
    EventAttendancePolicies? attendancePolicies,
    DateTime? eventCreatedAt,
    DateTime? lastUpdatedAt,
  }) {
    return EventModel(
      eventIdentifier: eventIdentifier ?? this.eventIdentifier,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      eventLocationName: eventLocationName ?? this.eventLocationName,
      eventCoordinates: eventCoordinates ?? this.eventCoordinates,
      scheduleInfo: scheduleInfo ?? this.scheduleInfo,
      creatorInfo: creatorInfo ?? this.creatorInfo,
      eventStatus: eventStatus ?? this.eventStatus,
      eventType: eventType ?? this.eventType,
      maximumParticipantsAllowed: maximumParticipantsAllowed ?? this.maximumParticipantsAllowed,
      currentRegisteredCount: currentRegisteredCount ?? this.currentRegisteredCount,
      attendancePolicies: attendancePolicies ?? this.attendancePolicies,
      eventCreatedAt: eventCreatedAt ?? this.eventCreatedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  /// **Method**: Create empty/placeholder EventModel
  /// **AI Context**: Useful for initialization states and testing
  /// **Returns**: EventModel with safe default values
  static EventModel empty() {
    return EventModel(
      eventIdentifier: '',
      eventTitle: '',
      eventDescription: '',
      eventLocationName: '',
      eventCoordinates: const EventGeolocationCoordinates(
        latitude: 0.0,
        longitude: 0.0,
        geofenceRadiusMeters: 100.0,
      ),
      scheduleInfo: EventScheduleInfo(
        eventStartDateTime: DateTime.now(),
        eventEndDateTime: DateTime.now().add(const Duration(hours: 1)),
        timeZone: 'America/Guayaquil',
      ),
      creatorInfo: const EventCreatorInfo(
        creatorUserId: '',
        creatorDisplayName: '',
        creatorEmailAddress: '',
        creatorRoleType: 'profesor',
      ),
      eventStatus: EventStatusType.draft,
      eventType: EventType.lecture,
      attendancePolicies: const EventAttendancePolicies(
        gracePeriodsConfig: EventGracePeriodConfiguration(),
      ),
      currentRegisteredCount: 0,
      eventCreatedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// **Method**: Validate EventModel has required data for API operations
  /// **AI Context**: Ensures model is complete before API operations
  /// **Returns**: boolean indicating if all required fields are present
  bool get isValidForApiOperations {
    return eventIdentifier.isNotEmpty && 
           eventTitle.isNotEmpty && 
           eventLocationName.isNotEmpty &&
           eventCoordinates.latitude != 0.0 &&
           eventCoordinates.longitude != 0.0 &&
           creatorInfo.creatorUserId.isNotEmpty;
  }

  // **Private Helper Methods**: JSON parsing utilities

  /// **Private Method**: Safely parse double from dynamic value
  static double? _parseDoubleFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// **Private Method**: Parse schedule information from backend JSON
  static EventScheduleInfo _parseScheduleInfoFromBackend(Map<String, dynamic> json) {
    final startDate = _parseDateTimeFromBackend(json['fechaInicio']);
    final endDate = _parseDateTimeFromBackend(json['fechaFin']);
    
    return EventScheduleInfo(
      eventStartDateTime: startDate,
      eventEndDateTime: endDate,
      timeZone: json['zonaHoraria']?.toString() ?? 'America/Guayaquil',
      isAllDayEvent: json['esDeTodoElDia'] == true,
    );
  }

  /// **Private Method**: Parse creator information from backend JSON
  static EventCreatorInfo _parseCreatorInfoFromBackend(Map<String, dynamic> json) {
    return EventCreatorInfo(
      creatorUserId: json['creadorId']?.toString() ?? json['profesorId']?.toString() ?? '',
      creatorDisplayName: json['creadorNombre']?.toString() ?? json['profesorNombre']?.toString() ?? '',
      creatorEmailAddress: json['creadorEmail']?.toString() ?? json['profesorEmail']?.toString() ?? '',
      creatorRoleType: json['creadorRol']?.toString() ?? 'profesor',
    );
  }

  /// **Private Method**: Parse attendance policies from backend JSON
  static EventAttendancePolicies _parseAttendancePoliciesFromBackend(Map<String, dynamic> json) {
    final politicas = json['politicasAsistencia'] as Map<String, dynamic>? ?? {};
    final periodoGracia = politicas['periodoGracia'] as Map<String, dynamic>? ?? {};
    
    return EventAttendancePolicies(
      gracePeriodsConfig: EventGracePeriodConfiguration(
        earlyArrivalMinutes: int.tryParse(periodoGracia['llegadaTemprana']?.toString() ?? '15') ?? 15,
        lateArrivalMinutes: int.tryParse(periodoGracia['llegadaTardia']?.toString() ?? '10') ?? 10,
        earlyDepartureMinutes: int.tryParse(periodoGracia['salidaTemprana']?.toString() ?? '5') ?? 5,
      ),
      requiresGeolocationValidation: politicas['requiereGeovalidacion'] == true,
      allowsManualAttendanceOverride: politicas['permiteAnulacionManual'] == true,
      minimumAttendanceDurationMinutes: int.tryParse(politicas['duracionMinimaMinutos']?.toString() ?? '0') ?? 0,
      sendsAttendanceNotifications: politicas['enviaNotificaciones'] != false,
    );
  }

  /// **Private Method**: Parse DateTime from backend JSON with error handling
  static DateTime _parseDateTimeFromBackend(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is Map && dateValue.containsKey('\$date')) {
        // AI Context: Handle MongoDB date format
        return DateTime.parse(dateValue['\$date']);
      }
    } catch (e) {
      // AI Context: Fallback to current time on parsing error
    }
    
    return DateTime.now();
  }

  /// **Private Method**: Parse event status from backend string
  static EventStatusType _parseEventStatusFromBackend(String? statusString) {
    switch (statusString?.toLowerCase()) {
      case 'activo':
      case 'active':
        return EventStatusType.active;
      case 'suspendido':
      case 'suspended':
        return EventStatusType.suspended;
      case 'cancelado':
      case 'cancelled':
        return EventStatusType.cancelled;
      case 'completado':
      case 'completed':
        return EventStatusType.completed;
      case 'borrador':
      case 'draft':
      default:
        return EventStatusType.draft;
    }
  }

  /// **Private Method**: Parse event type from backend string
  static EventType _parseEventTypeFromBackend(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'clase':
      case 'lecture':
        return EventType.lecture;
      case 'seminario':
      case 'seminar':
        return EventType.seminar;
      case 'taller':
      case 'workshop':
        return EventType.workshop;
      case 'examen':
      case 'exam':
        return EventType.exam;
      case 'reunion':
      case 'meeting':
        return EventType.meeting;
      case 'conferencia':
      case 'conference':
        return EventType.conference;
      case 'salida_campo':
      case 'field_trip':
        return EventType.fieldTrip;
      case 'practica':
      case 'practical':
        return EventType.practicalSession;
      default:
        return EventType.lecture;
    }
  }

  /// **Private Method**: Convert event status to backend string
  static String _eventStatusToBackendString(EventStatusType status) {
    switch (status) {
      case EventStatusType.active:
        return 'activo';
      case EventStatusType.suspended:
        return 'suspendido';
      case EventStatusType.cancelled:
        return 'cancelado';
      case EventStatusType.completed:
        return 'completado';
      case EventStatusType.draft:
        return 'borrador';
    }
  }

  /// **Private Method**: Convert event type to backend string
  static String _eventTypeToBackendString(EventType type) {
    switch (type) {
      case EventType.lecture:
        return 'clase';
      case EventType.seminar:
        return 'seminario';
      case EventType.workshop:
        return 'taller';
      case EventType.exam:
        return 'examen';
      case EventType.meeting:
        return 'reunion';
      case EventType.conference:
        return 'conferencia';
      case EventType.fieldTrip:
        return 'salida_campo';
      case EventType.practicalSession:
        return 'practica';
    }
  }
}