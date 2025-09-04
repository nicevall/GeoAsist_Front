import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

/// **CreateEventUseCase**: Business logic for event creation with comprehensive validation
/// 
/// **Purpose**: Orchestrates event creation process with validation, geolocation checks, and scheduling
/// **AI Context**: Single responsibility use case following Clean Architecture principles for event management
/// **Dependencies**: EventRepository interface only
/// **Used by**: EventController, EventCreationPage, EventManagementService
/// **Performance**: Lightweight use case optimized for complex event creation workflows
class CreateEventUseCase {
  /// **Property**: Repository dependency for data operations
  /// **AI Context**: Injected dependency following Dependency Inversion Principle
  final EventRepository _eventRepository;

  const CreateEventUseCase(this._eventRepository);

  /// **Method**: Execute event creation with comprehensive validation
  /// **AI Context**: Main use case execution method with multi-layered validation and error handling
  /// **Inputs**: eventCreationData (EventCreationData) with all event information
  /// **Outputs**: Future CreateEventUseCaseResult with created event or detailed error feedback
  /// **Side Effects**: Creates event in repository, triggers notifications, validates schedules
  /// **Error Cases**: ValidationError, LocationConflict, SchedulingConflict, PermissionError
  Future<CreateEventUseCaseResult> executeEventCreation({
    required EventCreationData eventCreationData,
  }) async {
    try {
      // AI Context: Pre-validation of event creation data before repository operations
      final validationResult = await _validateEventCreationData(eventCreationData);

      if (!validationResult.isValid) {
        return CreateEventUseCaseResult.validationFailure(
          validationErrors: validationResult.errorMessages,
        );
      }

      // AI Context: Transform creation data into complete event entity
      final eventEntity = _transformCreationDataToEventEntity(eventCreationData);

      // AI Context: Delegate to repository for actual event creation
      final creationResult = await _eventRepository.createNewEvent(
        eventData: eventEntity,
        creatorAuthToken: eventCreationData.creatorAuthToken,
      );

      if (creationResult.isSuccessful && creationResult.createdEvent != null) {
        return CreateEventUseCaseResult.success(
          createdEvent: creationResult.createdEvent!,
          successMessage: 'Evento "${eventEntity.eventTitle}" creado exitosamente',
        );
      } else {
        return CreateEventUseCaseResult.creationFailure(
          error: creationResult.error!,
          validationErrors: creationResult.validationErrors,
        );
      }
    } catch (exception) {
      // AI Context: Handle unexpected exceptions with user-friendly messages
      return CreateEventUseCaseResult.unexpectedError(
        errorMessage: 'Error inesperado al crear evento: ${exception.toString()}',
      );
    }
  }

  /// **Method**: Validate event creation data with business rules
  /// **AI Context**: Comprehensive validation covering all business requirements
  /// **Inputs**: eventCreationData (EventCreationData)
  /// **Returns**: EventCreationValidationResult with validation status and errors
  /// **Side Effects**: None - pure validation function
  Future<EventCreationValidationResult> _validateEventCreationData(
    EventCreationData eventCreationData,
  ) async {
    final List<String> validationErrors = [];

    // AI Context: Basic field validation
    if (eventCreationData.eventTitle.trim().isEmpty) {
      validationErrors.add('El título del evento es obligatorio');
    } else if (eventCreationData.eventTitle.trim().length < 3) {
      validationErrors.add('El título debe tener al menos 3 caracteres');
    } else if (eventCreationData.eventTitle.length > 100) {
      validationErrors.add('El título no puede exceder 100 caracteres');
    }

    if (eventCreationData.eventDescription.trim().length > 1000) {
      validationErrors.add('La descripción no puede exceder 1000 caracteres');
    }

    if (eventCreationData.eventLocationName.trim().isEmpty) {
      validationErrors.add('La ubicación del evento es obligatoria');
    } else if (eventCreationData.eventLocationName.length > 200) {
      validationErrors.add('La ubicación no puede exceder 200 caracteres');
    }

    // AI Context: Geolocation validation
    final geoValidation = _validateGeolocationCoordinates(eventCreationData.eventCoordinates);
    if (!geoValidation.isValid) {
      validationErrors.addAll(geoValidation.errorMessages);
    }

    // AI Context: Schedule validation
    final scheduleValidation = _validateEventSchedule(eventCreationData.scheduleInfo);
    if (!scheduleValidation.isValid) {
      validationErrors.addAll(scheduleValidation.errorMessages);
    }

    // AI Context: Capacity validation
    if (eventCreationData.maximumParticipantsAllowed != null) {
      if (eventCreationData.maximumParticipantsAllowed! <= 0) {
        validationErrors.add('La capacidad máxima debe ser mayor a cero');
      } else if (eventCreationData.maximumParticipantsAllowed! > 10000) {
        validationErrors.add('La capacidad máxima no puede exceder 10,000 participantes');
      }
    }

    // AI Context: Creator permission validation
    if (eventCreationData.creatorAuthToken.isEmpty) {
      validationErrors.add('Token de autenticación requerido');
    }

    // AI Context: Event type specific validation
    final typeSpecificValidation = _validateEventTypeSpecificRules(eventCreationData);
    if (!typeSpecificValidation.isValid) {
      validationErrors.addAll(typeSpecificValidation.errorMessages);
    }

    return EventCreationValidationResult(
      isValid: validationErrors.isEmpty,
      errorMessages: validationErrors,
    );
  }

  /// **Method**: Validate geolocation coordinates and geofencing parameters
  /// **AI Context**: GPS coordinate validation with reasonable bounds and geofence sizing
  /// **Input**: coordinates (EventGeolocationCoordinates)
  /// **Returns**: ValidationResult indicating if coordinates are valid
  EventCreationValidationResult _validateGeolocationCoordinates(
    EventGeolocationCoordinates coordinates,
  ) {
    final List<String> errors = [];

    // AI Context: Latitude validation (valid range -90 to 90)
    if (coordinates.latitude < -90.0 || coordinates.latitude > 90.0) {
      errors.add('La latitud debe estar entre -90 y 90 grados');
    }

    // AI Context: Longitude validation (valid range -180 to 180)
    if (coordinates.longitude < -180.0 || coordinates.longitude > 180.0) {
      errors.add('La longitud debe estar entre -180 y 180 grados');
    }

    // AI Context: Check for null island coordinates (0,0) which are likely invalid
    if (coordinates.latitude == 0.0 && coordinates.longitude == 0.0) {
      errors.add('Las coordenadas (0,0) no son válidas para un evento');
    }

    // AI Context: Geofence radius validation
    if (coordinates.geofenceRadiusMeters <= 0) {
      errors.add('El radio de geovalla debe ser mayor a cero');
    } else if (coordinates.geofenceRadiusMeters < 10) {
      errors.add('El radio mínimo de geovalla es 10 metros');
    } else if (coordinates.geofenceRadiusMeters > 10000) {
      errors.add('El radio máximo de geovalla es 10 kilómetros');
    }

    // AI Context: GPS accuracy validation
    if (coordinates.accuracyMeters < 1) {
      errors.add('La precisión GPS debe ser al menos 1 metro');
    } else if (coordinates.accuracyMeters > 100) {
      errors.add('La precisión GPS no puede exceder 100 metros');
    }

    return EventCreationValidationResult(
      isValid: errors.isEmpty,
      errorMessages: errors,
    );
  }

  /// **Method**: Validate event schedule with business rules
  /// **AI Context**: Date/time validation ensuring logical scheduling and future events
  /// **Input**: scheduleInfo (EventScheduleInfo)
  /// **Returns**: ValidationResult indicating if schedule is valid
  EventCreationValidationResult _validateEventSchedule(
    EventScheduleInfo scheduleInfo,
  ) {
    final List<String> errors = [];

    final now = DateTime.now();
    final startTime = scheduleInfo.eventStartDateTime;
    final endTime = scheduleInfo.eventEndDateTime;

    // AI Context: Basic date ordering validation
    if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
      errors.add('La fecha de fin debe ser posterior a la fecha de inicio');
    }

    // AI Context: Future event validation (events should be scheduled for future)
    if (startTime.isBefore(now)) {
      errors.add('El evento debe programarse para una fecha futura');
    }

    // AI Context: Reasonable scheduling limits
    final duration = endTime.difference(startTime);
    if (duration.inMinutes < 15) {
      errors.add('La duración mínima del evento es 15 minutos');
    } else if (duration.inDays > 30) {
      errors.add('La duración máxima del evento es 30 días');
    }

    // AI Context: Scheduling advance notice validation
    final advanceNotice = startTime.difference(now);
    if (advanceNotice.inMinutes < 30) {
      errors.add('El evento debe programarse con al menos 30 minutos de anticipación');
    } else if (advanceNotice.inDays > 365) {
      errors.add('El evento no puede programarse con más de un año de anticipación');
    }

    // AI Context: All-day event validation
    if (scheduleInfo.isAllDayEvent) {
      if (duration.inHours < 4) {
        errors.add('Los eventos de todo el día deben durar al menos 4 horas');
      }
    }

    return EventCreationValidationResult(
      isValid: errors.isEmpty,
      errorMessages: errors,
    );
  }

  /// **Method**: Validate event type specific business rules
  /// **AI Context**: Different event types have different validation requirements
  /// **Input**: eventCreationData (EventCreationData)
  /// **Returns**: ValidationResult with type-specific validation errors
  EventCreationValidationResult _validateEventTypeSpecificRules(
    EventCreationData eventCreationData,
  ) {
    final List<String> errors = [];

    switch (eventCreationData.eventType) {
      case EventType.exam:
        // AI Context: Exams require stricter validation
        if (eventCreationData.scheduleInfo.eventEndDateTime
            .difference(eventCreationData.scheduleInfo.eventStartDateTime)
            .inHours > 4) {
          errors.add('Los exámenes no pueden durar más de 4 horas');
        }
        
        if (eventCreationData.attendancePolicies.gracePeriodsConfig.lateArrivalMinutes > 5) {
          errors.add('El período de gracia para exámenes no puede exceder 5 minutos');
        }
        break;

      case EventType.fieldTrip:
        // AI Context: Field trips require special considerations
        if (eventCreationData.scheduleInfo.eventEndDateTime
            .difference(eventCreationData.scheduleInfo.eventStartDateTime)
            .inHours < 2) {
          errors.add('Las salidas de campo deben durar al menos 2 horas');
        }
        
        if (eventCreationData.eventCoordinates.geofenceRadiusMeters < 50) {
          errors.add('Las salidas de campo requieren un radio mínimo de 50 metros');
        }
        break;

      case EventType.lecture:
      case EventType.seminar:
      case EventType.workshop:
        // AI Context: Standard academic events validation
        if (eventCreationData.scheduleInfo.eventEndDateTime
            .difference(eventCreationData.scheduleInfo.eventStartDateTime)
            .inMinutes < 30) {
          errors.add('Las clases académicas deben durar al menos 30 minutos');
        }
        break;

      case EventType.meeting:
      case EventType.conference:
      case EventType.practicalSession:
        // AI Context: Professional events validation
        if (eventCreationData.scheduleInfo.isAllDayEvent && 
            eventCreationData.maximumParticipantsAllowed == null) {
          errors.add('Los eventos de todo el día requieren límite de capacidad');
        }
        break;
    }

    return EventCreationValidationResult(
      isValid: errors.isEmpty,
      errorMessages: errors,
    );
  }

  /// **Method**: Transform creation data into complete event entity
  /// **AI Context**: Data transformation with default value assignment and entity construction
  /// **Input**: eventCreationData (EventCreationData)
  /// **Returns**: EventEntity ready for repository operations
  EventEntity _transformCreationDataToEventEntity(
    EventCreationData eventCreationData,
  ) {
    final now = DateTime.now();

    return EventEntity(
      eventIdentifier: '', // AI Context: Will be assigned by repository
      eventTitle: eventCreationData.eventTitle.trim(),
      eventDescription: eventCreationData.eventDescription.trim(),
      eventLocationName: eventCreationData.eventLocationName.trim(),
      eventCoordinates: eventCreationData.eventCoordinates,
      scheduleInfo: eventCreationData.scheduleInfo,
      creatorInfo: eventCreationData.creatorInfo,
      eventStatus: EventStatusType.draft, // AI Context: New events start as draft
      eventType: eventCreationData.eventType,
      attendancePolicies: eventCreationData.attendancePolicies,
      maximumParticipantsAllowed: eventCreationData.maximumParticipantsAllowed,
      currentRegisteredCount: 0, // AI Context: New events have no participants
      eventCreatedAt: now,
      lastUpdatedAt: now,
    );
  }
}

/// **EventCreationData**: Input data for event creation use case
/// **AI Context**: Data transfer object containing all information needed to create an event
class EventCreationData {
  final String eventTitle;
  final String eventDescription;
  final String eventLocationName;
  final EventGeolocationCoordinates eventCoordinates;
  final EventScheduleInfo scheduleInfo;
  final EventCreatorInfo creatorInfo;
  final EventType eventType;
  final EventAttendancePolicies attendancePolicies;
  final int? maximumParticipantsAllowed;
  final String creatorAuthToken;

  const EventCreationData({
    required this.eventTitle,
    required this.eventDescription,
    required this.eventLocationName,
    required this.eventCoordinates,
    required this.scheduleInfo,
    required this.creatorInfo,
    required this.eventType,
    required this.attendancePolicies,
    required this.creatorAuthToken,
    this.maximumParticipantsAllowed,
  });

  /// **Factory**: Create from form data with defaults
  factory EventCreationData.fromFormInput({
    required String title,
    required String description,
    required String location,
    required double latitude,
    required double longitude,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required EventType type,
    required EventCreatorInfo creator,
    required String authToken,
    double geofenceRadius = 100.0,
    int? maxParticipants,
    bool isAllDay = false,
  }) {
    return EventCreationData(
      eventTitle: title,
      eventDescription: description,
      eventLocationName: location,
      eventCoordinates: EventGeolocationCoordinates(
        latitude: latitude,
        longitude: longitude,
        geofenceRadiusMeters: geofenceRadius,
      ),
      scheduleInfo: EventScheduleInfo(
        eventStartDateTime: startDateTime,
        eventEndDateTime: endDateTime,
        timeZone: 'America/Guayaquil',
        isAllDayEvent: isAllDay,
      ),
      creatorInfo: creator,
      eventType: type,
      attendancePolicies: const EventAttendancePolicies(
        gracePeriodsConfig: EventGracePeriodConfiguration(),
      ),
      maximumParticipantsAllowed: maxParticipants,
      creatorAuthToken: authToken,
    );
  }
}

/// **CreateEventUseCaseResult**: Result object for event creation use case operations
/// **AI Context**: Encapsulates all possible outcomes of event creation process
class CreateEventUseCaseResult {
  final bool isSuccessful;
  final EventEntity? createdEvent;
  final String? successMessage;
  final List<String>? validationErrors;
  final EventCreationError? creationError;
  final String? unexpectedErrorMessage;

  const CreateEventUseCaseResult._({
    required this.isSuccessful,
    this.createdEvent,
    this.successMessage,
    this.validationErrors,
    this.creationError,
    this.unexpectedErrorMessage,
  });

  /// **Factory**: Create successful event creation result
  factory CreateEventUseCaseResult.success({
    required EventEntity createdEvent,
    required String successMessage,
  }) {
    return CreateEventUseCaseResult._(
      isSuccessful: true,
      createdEvent: createdEvent,
      successMessage: successMessage,
    );
  }

  /// **Factory**: Create validation failure result
  factory CreateEventUseCaseResult.validationFailure({
    required List<String> validationErrors,
  }) {
    return CreateEventUseCaseResult._(
      isSuccessful: false,
      validationErrors: validationErrors,
    );
  }

  /// **Factory**: Create creation failure result
  factory CreateEventUseCaseResult.creationFailure({
    required EventCreationError error,
    List<String>? validationErrors,
  }) {
    return CreateEventUseCaseResult._(
      isSuccessful: false,
      creationError: error,
      validationErrors: validationErrors,
    );
  }

  /// **Factory**: Create unexpected error result
  factory CreateEventUseCaseResult.unexpectedError({
    required String errorMessage,
  }) {
    return CreateEventUseCaseResult._(
      isSuccessful: false,
      unexpectedErrorMessage: errorMessage,
    );
  }

  /// **Method**: Get user-friendly error message for display
  /// **AI Context**: Converts technical errors into user-friendly Spanish messages
  String get userFriendlyErrorMessage {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return validationErrors!.join('\n');
    }

    if (creationError != null) {
      switch (creationError!) {
        case EventCreationError.validationFailed:
          return 'Los datos del evento no son válidos. Verifica la información ingresada.';
        case EventCreationError.locationConflict:
          return 'Ya existe un evento programado en esta ubicación y horario.';
        case EventCreationError.scheduleConflict:
          return 'Conflicto de horario con otro evento existente.';
        case EventCreationError.permissionDenied:
          return 'No tienes permisos para crear eventos.';
        case EventCreationError.networkError:
          return 'Error de conexión. Verifica tu conexión a internet.';
        case EventCreationError.serverError:
          return 'Error del servidor. Intenta nuevamente más tarde.';
      }
    }

    if (unexpectedErrorMessage != null) {
      return unexpectedErrorMessage!;
    }

    return 'Error desconocido durante la creación del evento';
  }
}

/// **EventCreationValidationResult**: Internal validation result
/// **AI Context**: Simple result object for validation operations
class EventCreationValidationResult {
  final bool isValid;
  final List<String> errorMessages;

  const EventCreationValidationResult({
    required this.isValid,
    required this.errorMessages,
  });
}