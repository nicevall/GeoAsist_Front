// **EventEntity**: Core business entity for event management and attendance tracking
// 
// **Purpose**: Represents the fundamental event domain object with geolocation and scheduling
// **AI Context**: This entity defines event properties and business rules for attendance control
// **Dependencies**: None (Pure domain entity)
// **Used by**: EventRepository, EventUseCase, AttendanceTrackingUseCase
// **Performance**: Lightweight value object optimized for frequent access and geolocation calculations

import 'dart:math';

class EventEntity {
  /// **Property**: Event unique identifier from backend database
  /// **AI Context**: Primary key for event identification across system
  final String eventIdentifier;
  
  /// **Property**: Event display name for UI and notifications
  /// **AI Context**: Human-readable name for event identification
  final String eventTitle;
  
  /// **Property**: Event detailed description
  /// **AI Context**: Comprehensive event information for participants
  final String eventDescription;
  
  /// **Property**: Event physical location name
  /// **AI Context**: Human-readable location for display and context
  final String eventLocationName;
  
  /// **Property**: Event geolocation coordinates for attendance validation
  /// **AI Context**: GPS coordinates used for geofencing and proximity detection
  final EventGeolocationCoordinates eventCoordinates;
  
  /// **Property**: Event scheduling information
  /// **AI Context**: Date and time details for event timing and duration
  final EventScheduleInfo scheduleInfo;
  
  /// **Property**: Event creator/professor information
  /// **AI Context**: Professor who created and manages the event
  final EventCreatorInfo creatorInfo;
  
  /// **Property**: Event current status
  /// **AI Context**: Lifecycle state determining available actions and UI behavior
  final EventStatusType eventStatus;
  
  /// **Property**: Event type classification
  /// **AI Context**: Category affecting attendance rules and validation requirements
  final EventType eventType;
  
  /// **Property**: Maximum number of participants allowed
  /// **AI Context**: Capacity control for event registration and attendance
  final int? maximumParticipantsAllowed;
  
  /// **Property**: Number of currently registered participants
  /// **AI Context**: Real-time count for capacity monitoring
  final int currentRegisteredCount;
  
  /// **Property**: Attendance tracking policies and rules
  /// **AI Context**: Configuration for geofencing, grace periods, and validation
  final EventAttendancePolicies attendancePolicies;
  
  /// **Property**: Event creation timestamp
  /// **AI Context**: Used for audit trails and event ordering
  final DateTime eventCreatedAt;
  
  /// **Property**: Last update timestamp
  /// **AI Context**: Used for data synchronization and cache invalidation
  final DateTime lastUpdatedAt;

  const EventEntity({
    required this.eventIdentifier,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventLocationName,
    required this.eventCoordinates,
    required this.scheduleInfo,
    required this.creatorInfo,
    required this.eventStatus,
    required this.eventType,
    required this.attendancePolicies,
    required this.currentRegisteredCount,
    required this.eventCreatedAt,
    required this.lastUpdatedAt,
    this.maximumParticipantsAllowed,
  });

  /// **Method**: Check if event is currently active for attendance
  /// **AI Context**: Determines if students can mark attendance based on schedule and status
  /// **Returns**: boolean indicating if event is in active attendance period
  bool get isCurrentlyActiveForAttendance {
    if (eventStatus != EventStatusType.active) return false;
    
    final now = DateTime.now();
    final startTime = scheduleInfo.eventStartDateTime;
    final endTime = scheduleInfo.eventEndDateTime;
    
    // AI Context: Consider grace period for late arrivals
    final attendanceStartTime = startTime.subtract(
      Duration(minutes: attendancePolicies.gracePeriodsConfig.earlyArrivalMinutes),
    );
    final attendanceEndTime = endTime.add(
      Duration(minutes: attendancePolicies.gracePeriodsConfig.lateArrivalMinutes),
    );
    
    return now.isAfter(attendanceStartTime) && now.isBefore(attendanceEndTime);
  }

  /// **Method**: Check if event has available capacity for registration
  /// **AI Context**: Validates if new participants can register for the event
  /// **Returns**: boolean indicating if registration is available
  bool get hasAvailableCapacity {
    if (maximumParticipantsAllowed == null) return true;
    return currentRegisteredCount < maximumParticipantsAllowed!;
  }

  /// **Method**: Check if event is in future (hasn't started yet)
  /// **AI Context**: Determines if event can still be modified or cancelled
  /// **Returns**: boolean indicating if event is scheduled for future
  bool get isFutureEvent {
    return DateTime.now().isBefore(scheduleInfo.eventStartDateTime);
  }

  /// **Method**: Check if event has ended
  /// **AI Context**: Determines if event is completed and attendance is closed
  /// **Returns**: boolean indicating if event has finished
  bool get hasEventEnded {
    return DateTime.now().isAfter(scheduleInfo.eventEndDateTime);
  }

  /// **Method**: Get event duration in minutes
  /// **AI Context**: Calculates total event duration for display and scheduling
  /// **Returns**: Duration of the event
  Duration get eventDuration {
    return scheduleInfo.eventEndDateTime.difference(scheduleInfo.eventStartDateTime);
  }

  /// **Method**: Check if user can mark attendance from specific location
  /// **AI Context**: Validates if user's GPS coordinates are within event geofence
  /// **Input**: userLatitude, userLongitude - user's current GPS coordinates
  /// **Returns**: boolean indicating if user is within attendance radius
  bool canMarkAttendanceFromLocation({
    required double userLatitude,
    required double userLongitude,
  }) {
    final distance = _calculateDistanceInMeters(
      userLatitude,
      userLongitude,
      eventCoordinates.latitude,
      eventCoordinates.longitude,
    );
    
    return distance <= eventCoordinates.geofenceRadiusMeters;
  }

  /// **Method**: Create copy of event entity with modified properties
  /// **AI Context**: Immutable object pattern for state management
  EventEntity copyWith({
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
    return EventEntity(
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

  /// **Private Method**: Calculate distance between two GPS coordinates using Haversine formula
  /// **AI Context**: Precise distance calculation for geofencing validation
  /// **Returns**: distance in meters between two GPS points
  double _calculateDistanceInMeters(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = (dLat / 2) * (dLat / 2) +
        (dLon / 2) * (dLon / 2) * 
        _cosine(_degreesToRadians(lat1)) * 
        _cosine(_degreesToRadians(lat2));
    
    final double c = 2 * _arctangent2(_squareRoot(a), _squareRoot(1 - a));
    
    return earthRadiusKm * c * 1000; // Convert to meters
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);
  double _cosine(double radians) => cos(radians);
  double _squareRoot(double value) => sqrt(value);
  double _arctangent2(double y, double x) => atan2(y, x);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventEntity && other.eventIdentifier == eventIdentifier;
  }

  @override
  int get hashCode => eventIdentifier.hashCode;

  @override
  String toString() {
    return 'EventEntity{id: $eventIdentifier, title: $eventTitle, status: $eventStatus}';
  }
}

/// **EventGeolocationCoordinates**: GPS coordinates and geofencing configuration
/// **AI Context**: Precise location data for attendance validation
class EventGeolocationCoordinates {
  final double latitude;
  final double longitude;
  final double geofenceRadiusMeters;
  final double accuracyMeters;

  const EventGeolocationCoordinates({
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    this.accuracyMeters = 10.0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventGeolocationCoordinates &&
           other.latitude == latitude &&
           other.longitude == longitude &&
           other.geofenceRadiusMeters == geofenceRadiusMeters;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, geofenceRadiusMeters);
}

/// **EventScheduleInfo**: Comprehensive scheduling information for events
/// **AI Context**: Date, time, and duration details for event planning
class EventScheduleInfo {
  final DateTime eventStartDateTime;
  final DateTime eventEndDateTime;
  final String timeZone;
  final bool isAllDayEvent;
  final List<EventRecurrenceRule>? recurrenceRules;

  const EventScheduleInfo({
    required this.eventStartDateTime,
    required this.eventEndDateTime,
    required this.timeZone,
    this.isAllDayEvent = false,
    this.recurrenceRules,
  });

  Duration get duration => eventEndDateTime.difference(eventStartDateTime);
  bool get isRecurringEvent => recurrenceRules != null && recurrenceRules!.isNotEmpty;
}

/// **EventCreatorInfo**: Professor/administrator who created the event
/// **AI Context**: Creator identification for permissions and notifications
class EventCreatorInfo {
  final String creatorUserId;
  final String creatorDisplayName;
  final String creatorEmailAddress;
  final String creatorRoleType;

  const EventCreatorInfo({
    required this.creatorUserId,
    required this.creatorDisplayName,
    required this.creatorEmailAddress,
    required this.creatorRoleType,
  });

  bool get isAdministrator => creatorRoleType == 'admin';
  bool get isProfessor => creatorRoleType == 'profesor';
}

/// **EventAttendancePolicies**: Rules and policies for attendance tracking
/// **AI Context**: Configuration for geofencing, grace periods, and validation rules
class EventAttendancePolicies {
  final EventGracePeriodConfiguration gracePeriodsConfig;
  final bool requiresGeolocationValidation;
  final bool allowsManualAttendanceOverride;
  final int minimumAttendanceDurationMinutes;
  final bool sendsAttendanceNotifications;

  const EventAttendancePolicies({
    required this.gracePeriodsConfig,
    this.requiresGeolocationValidation = true,
    this.allowsManualAttendanceOverride = false,
    this.minimumAttendanceDurationMinutes = 0,
    this.sendsAttendanceNotifications = true,
  });
}

/// **EventGracePeriodConfiguration**: Grace period settings for attendance
/// **AI Context**: Flexible timing policies for late arrivals and early departures
class EventGracePeriodConfiguration {
  final int earlyArrivalMinutes;
  final int lateArrivalMinutes;
  final int earlyDepartureMinutes;

  const EventGracePeriodConfiguration({
    this.earlyArrivalMinutes = 15,
    this.lateArrivalMinutes = 10,
    this.earlyDepartureMinutes = 5,
  });
}

/// **EventRecurrenceRule**: Rules for recurring events
/// **AI Context**: Pattern definition for repeating events
class EventRecurrenceRule {
  final EventRecurrenceType recurrenceType;
  final int intervalCount;
  final List<int>? daysOfWeek;
  final DateTime? recurrenceEndDate;
  final int? maxOccurrences;

  const EventRecurrenceRule({
    required this.recurrenceType,
    this.intervalCount = 1,
    this.daysOfWeek,
    this.recurrenceEndDate,
    this.maxOccurrences,
  });
}

/// **Enums**: Type-safe enumerations for event properties
enum EventStatusType {
  draft,
  active,
  suspended,
  cancelled,
  completed,
}

enum EventType {
  lecture,
  seminar,
  workshop,
  exam,
  meeting,
  conference,
  fieldTrip,
  practicalSession,
}

enum EventRecurrenceType {
  daily,
  weekly,
  monthly,
  custom,
}

/// **Extensions**: Convenient string representations for enums
extension EventStatusTypeExtension on EventStatusType {
  String get displayName {
    switch (this) {
      case EventStatusType.draft:
        return 'Borrador';
      case EventStatusType.active:
        return 'Activo';
      case EventStatusType.suspended:
        return 'Suspendido';
      case EventStatusType.cancelled:
        return 'Cancelado';
      case EventStatusType.completed:
        return 'Completado';
    }
  }

  bool get allowsAttendance {
    return this == EventStatusType.active;
  }

  bool get canBeModified {
    return this == EventStatusType.draft || this == EventStatusType.active;
  }
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.lecture:
        return 'Clase';
      case EventType.seminar:
        return 'Seminario';
      case EventType.workshop:
        return 'Taller';
      case EventType.exam:
        return 'Examen';
      case EventType.meeting:
        return 'Reunión';
      case EventType.conference:
        return 'Conferencia';
      case EventType.fieldTrip:
        return 'Salida de Campo';
      case EventType.practicalSession:
        return 'Sesión Práctica';
    }
  }

  bool get requiresStrictAttendance {
    return this == EventType.exam || this == EventType.practicalSession;
  }
}