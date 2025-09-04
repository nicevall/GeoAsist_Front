import '../entities/event_entity.dart';

/// **EventRepository**: Domain interface for event management operations
/// 
/// **Purpose**: Defines contract for event data operations without implementation details
/// **AI Context**: Clean Architecture boundary between domain and data layers for event management
/// **Dependencies**: EventEntity only
/// **Implementation**: Concrete implementation in data layer
/// **Performance**: Interface only - implementation handles optimization and caching
abstract class EventRepository {
  /// **Method**: Create new event with validation and geolocation
  /// **AI Context**: Primary event creation flow with comprehensive validation
  /// **Inputs**: eventData (EventEntity) with all required information
  /// **Outputs**: Future EventCreationResult with created event or validation errors
  /// **Side Effects**: Stores event in backend, triggers notifications
  /// **Error Cases**: ValidationError, DuplicateLocationError, CreationPermissionError
  Future<EventCreationResult> createNewEvent({
    required EventEntity eventData,
    required String creatorAuthToken,
  });

  /// **Method**: Update existing event with change validation
  /// **AI Context**: Event modification with permission checks and conflict resolution
  /// **Inputs**: eventId (String), updatedEventData (EventEntity), authToken (String)
  /// **Outputs**: Future EventUpdateResult with updated event or error details
  /// **Side Effects**: Updates backend data, notifies registered participants
  /// **Error Cases**: EventNotFound, UpdatePermissionDenied, ConflictingSchedule
  Future<EventUpdateResult> updateExistingEvent({
    required String eventId,
    required EventEntity updatedEventData,
    required String editorAuthToken,
  });

  /// **Method**: Delete event with participant notification
  /// **AI Context**: Event deletion with cascade operations and participant management
  /// **Inputs**: eventId (String), authToken (String)
  /// **Outputs**: Future EventDeletionResult indicating success or failure
  /// **Side Effects**: Removes event data, cancels notifications, notifies participants
  /// **Error Cases**: EventNotFound, DeletionPermissionDenied, ActiveParticipantsError
  Future<EventDeletionResult> deleteEvent({
    required String eventId,
    required String authToken,
  });

  /// **Method**: Get event by unique identifier
  /// **AI Context**: Single event retrieval with full details and current status
  /// **Inputs**: eventId (String)
  /// **Outputs**: Future EventEntity or null if not found
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: EventNotFound, AccessPermissionDenied
  Future<EventEntity?> getEventById(String eventId);

  /// **Method**: Get events created by specific user (professor/admin)
  /// **AI Context**: Creator's event management dashboard with filtering options
  /// **Inputs**: creatorUserId (String), filters (EventQueryFilters)
  /// **Outputs**: Future List of EventEntity with created events
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: UserNotFound, AccessPermissionDenied
  Future<List<EventEntity>> getEventsByCreator({
    required String creatorUserId,
    EventQueryFilters? filters,
  });

  /// **Method**: Get events available for student participation
  /// **AI Context**: Student dashboard showing available events within geographic proximity
  /// **Inputs**: studentUserId (String), userLocation (EventGeolocationCoordinates), filters
  /// **Outputs**: Future List of EventEntity with available events
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: LocationAccessDenied, NoEventsFound
  Future<List<EventEntity>> getAvailableEventsForStudent({
    required String studentUserId,
    EventGeolocationCoordinates? userCurrentLocation,
    EventQueryFilters? filters,
  });

  /// **Method**: Get events by geographic proximity
  /// **AI Context**: Location-based event discovery for attendance and exploration
  /// **Inputs**: centerCoordinates (EventGeolocationCoordinates), searchRadiusKm (double)
  /// **Outputs**: Future List of EventEntity with nearby events
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: InvalidCoordinates, LocationServiceError
  Future<List<EventEntity>> getEventsByProximity({
    required EventGeolocationCoordinates centerCoordinates,
    required double searchRadiusKilometers,
    EventQueryFilters? filters,
  });

  /// **Method**: Register student for event participation
  /// **AI Context**: Event registration with capacity validation and geolocation checks
  /// **Inputs**: eventId (String), studentUserId (String), authToken (String)
  /// **Outputs**: Future EventRegistrationResult with registration status
  /// **Side Effects**: Updates participant list, triggers confirmation notifications
  /// **Error Cases**: EventCapacityReached, DuplicateRegistration, EventNotActive
  Future<EventRegistrationResult> registerStudentForEvent({
    required String eventId,
    required String studentUserId,
    required String authToken,
  });

  /// **Method**: Unregister student from event
  /// **AI Context**: Event unregistration with cancellation policies and notifications
  /// **Inputs**: eventId (String), studentUserId (String), authToken (String)
  /// **Outputs**: Future EventUnregistrationResult with unregistration status
  /// **Side Effects**: Updates participant list, triggers cancellation notifications
  /// **Error Cases**: RegistrationNotFound, UnregistrationDeadlinePassed
  Future<EventUnregistrationResult> unregisterStudentFromEvent({
    required String eventId,
    required String studentUserId,
    required String authToken,
  });

  /// **Method**: Get registered participants for event
  /// **AI Context**: Event participant management for professors and administrators
  /// **Inputs**: eventId (String), authToken (String)
  /// **Outputs**: Future List of EventParticipantInfo with participant details
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: EventNotFound, AccessPermissionDenied
  Future<List<EventParticipantInfo>> getEventParticipants({
    required String eventId,
    required String authToken,
  });

  /// **Method**: Update event status (activate, suspend, complete)
  /// **AI Context**: Event lifecycle management with status transition validation
  /// **Inputs**: eventId (String), newStatus (EventStatusType), authToken (String)
  /// **Outputs**: Future EventStatusUpdateResult with status change result
  /// **Side Effects**: Updates event state, triggers status-specific notifications
  /// **Error Cases**: InvalidStatusTransition, EventNotFound, PermissionDenied
  Future<EventStatusUpdateResult> updateEventStatus({
    required String eventId,
    required EventStatusType newStatus,
    required String authToken,
  });

  /// **Method**: Search events with flexible criteria
  /// **AI Context**: Advanced event search with multiple filtering and sorting options
  /// **Inputs**: searchQuery (EventSearchQuery)
  /// **Outputs**: Future EventSearchResult with matching events and metadata
  /// **Side Effects**: None - read-only operation  
  /// **Error Cases**: InvalidSearchCriteria, SearchServiceError
  Future<EventSearchResult> searchEvents({
    required EventSearchQuery searchQuery,
  });

  /// **Method**: Get event statistics and analytics
  /// **AI Context**: Event performance metrics for professors and administrators
  /// **Inputs**: eventId (String), authToken (String)
  /// **Outputs**: Future EventStatistics with participation and attendance data
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: EventNotFound, StatisticsAccessDenied
  Future<EventStatistics> getEventStatistics({
    required String eventId,
    required String authToken,
  });
}

/// **EventCreationResult**: Result object for event creation operations
/// **AI Context**: Encapsulates creation success/failure with detailed feedback
class EventCreationResult {
  final bool isSuccessful;
  final EventEntity? createdEvent;
  final List<String>? validationErrors;
  final EventCreationError? error;

  const EventCreationResult._({
    required this.isSuccessful,
    this.createdEvent,
    this.validationErrors,
    this.error,
  });

  /// **Factory**: Create successful event creation result
  factory EventCreationResult.success(EventEntity createdEvent) {
    return EventCreationResult._(
      isSuccessful: true,
      createdEvent: createdEvent,
    );
  }

  /// **Factory**: Create validation failure result
  factory EventCreationResult.validationFailure(List<String> errors) {
    return EventCreationResult._(
      isSuccessful: false,
      validationErrors: errors,
    );
  }

  /// **Factory**: Create creation error result
  factory EventCreationResult.failure(EventCreationError error) {
    return EventCreationResult._(
      isSuccessful: false,
      error: error,
    );
  }
}

/// **EventUpdateResult**: Result object for event update operations
class EventUpdateResult {
  final bool isSuccessful;
  final EventEntity? updatedEvent;
  final List<String>? validationErrors;
  final EventUpdateError? error;

  const EventUpdateResult._({
    required this.isSuccessful,
    this.updatedEvent,
    this.validationErrors,
    this.error,
  });

  factory EventUpdateResult.success(EventEntity updatedEvent) {
    return EventUpdateResult._(
      isSuccessful: true,
      updatedEvent: updatedEvent,
    );
  }

  factory EventUpdateResult.validationFailure(List<String> errors) {
    return EventUpdateResult._(
      isSuccessful: false,
      validationErrors: errors,
    );
  }

  factory EventUpdateResult.failure(EventUpdateError error) {
    return EventUpdateResult._(
      isSuccessful: false,
      error: error,
    );
  }
}

/// **EventDeletionResult**: Result object for event deletion operations
class EventDeletionResult {
  final bool isSuccessful;
  final String? errorMessage;
  final List<String>? affectedParticipants;

  const EventDeletionResult._({
    required this.isSuccessful,
    this.errorMessage,
    this.affectedParticipants,
  });

  factory EventDeletionResult.success({List<String>? notifiedParticipants}) {
    return EventDeletionResult._(
      isSuccessful: true,
      affectedParticipants: notifiedParticipants,
    );
  }

  factory EventDeletionResult.failure(String errorMessage) {
    return EventDeletionResult._(
      isSuccessful: false,
      errorMessage: errorMessage,
    );
  }
}

/// **EventRegistrationResult**: Result object for event registration operations
class EventRegistrationResult {
  final bool isSuccessful;
  final String? confirmationMessage;
  final EventRegistrationError? error;

  const EventRegistrationResult._({
    required this.isSuccessful,
    this.confirmationMessage,
    this.error,
  });

  factory EventRegistrationResult.success({String? message}) {
    return EventRegistrationResult._(
      isSuccessful: true,
      confirmationMessage: message,
    );
  }

  factory EventRegistrationResult.failure(EventRegistrationError error) {
    return EventRegistrationResult._(
      isSuccessful: false,
      error: error,
    );
  }
}

/// **EventUnregistrationResult**: Result object for event unregistration operations
class EventUnregistrationResult {
  final bool isSuccessful;
  final String? confirmationMessage;
  final EventUnregistrationError? error;

  const EventUnregistrationResult._({
    required this.isSuccessful,
    this.confirmationMessage,
    this.error,
  });

  factory EventUnregistrationResult.success({String? message}) {
    return EventUnregistrationResult._(
      isSuccessful: true,
      confirmationMessage: message,
    );
  }

  factory EventUnregistrationResult.failure(EventUnregistrationError error) {
    return EventUnregistrationResult._(
      isSuccessful: false,
      error: error,
    );
  }
}

/// **EventStatusUpdateResult**: Result object for event status change operations
class EventStatusUpdateResult {
  final bool isSuccessful;
  final EventStatusType? newStatus;
  final String? errorMessage;

  const EventStatusUpdateResult._({
    required this.isSuccessful,
    this.newStatus,
    this.errorMessage,
  });

  factory EventStatusUpdateResult.success(EventStatusType newStatus) {
    return EventStatusUpdateResult._(
      isSuccessful: true,
      newStatus: newStatus,
    );
  }

  factory EventStatusUpdateResult.failure(String errorMessage) {
    return EventStatusUpdateResult._(
      isSuccessful: false,
      errorMessage: errorMessage,
    );
  }
}

/// **Supporting Data Classes**: Query filters, search parameters, and metadata

/// **EventQueryFilters**: Filtering options for event queries
class EventQueryFilters {
  final EventStatusType? statusFilter;
  final EventType? typeFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final int? maxResults;
  final EventSortingOption? sortBy;

  const EventQueryFilters({
    this.statusFilter,
    this.typeFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.maxResults,
    this.sortBy,
  });
}

/// **EventSearchQuery**: Advanced search parameters
class EventSearchQuery {
  final String? titleKeywords;
  final String? descriptionKeywords;
  final String? locationKeywords;
  final EventQueryFilters? filters;
  final EventGeolocationCoordinates? nearLocation;
  final double? proximityRadiusKm;

  const EventSearchQuery({
    this.titleKeywords,
    this.descriptionKeywords,
    this.locationKeywords,
    this.filters,
    this.nearLocation,
    this.proximityRadiusKm,
  });
}

/// **EventSearchResult**: Search results with metadata
class EventSearchResult {
  final List<EventEntity> matchingEvents;
  final int totalResultsCount;
  final bool hasMoreResults;
  final String? searchQueryHash;

  const EventSearchResult({
    required this.matchingEvents,
    required this.totalResultsCount,
    this.hasMoreResults = false,
    this.searchQueryHash,
  });
}

/// **EventParticipantInfo**: Participant details for event management
class EventParticipantInfo {
  final String participantUserId;
  final String participantName;
  final String participantEmail;
  final DateTime registrationDate;
  final EventParticipantStatus participantStatus;

  const EventParticipantInfo({
    required this.participantUserId,
    required this.participantName,
    required this.participantEmail,
    required this.registrationDate,
    required this.participantStatus,
  });
}

/// **EventStatistics**: Analytics and performance metrics
class EventStatistics {
  final int totalRegistrations;
  final int actualAttendees;
  final double attendanceRate;
  final Map<String, int> attendanceByTimeSlot;
  final List<EventParticipantInfo> topParticipants;

  const EventStatistics({
    required this.totalRegistrations,
    required this.actualAttendees,
    required this.attendanceRate,
    required this.attendanceByTimeSlot,
    required this.topParticipants,
  });
}

/// **Enums**: Error types and operational categories

enum EventCreationError {
  validationFailed,
  locationConflict,
  scheduleConflict,
  permissionDenied,
  networkError,
  serverError,
}

enum EventUpdateError {
  eventNotFound,
  permissionDenied,
  validationFailed,
  scheduleConflict,
  participantsConflict,
  networkError,
  serverError,
}

enum EventRegistrationError {
  eventNotFound,
  eventCapacityReached,
  duplicateRegistration,
  eventNotActive,
  registrationDeadlinePassed,
  networkError,
  serverError,
}

enum EventUnregistrationError {
  eventNotFound,
  registrationNotFound,
  unregistrationDeadlinePassed,
  eventAlreadyStarted,
  networkError,
  serverError,
}

enum EventParticipantStatus {
  registered,
  confirmed,
  attended,
  absent,
  cancelled,
}

enum EventSortingOption {
  createdDateAsc,
  createdDateDesc,
  startDateAsc,
  startDateDesc,
  titleAsc,
  titleDesc,
  proximityAsc,
}