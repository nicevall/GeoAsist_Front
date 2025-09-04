// lib/models/attendance_state_model.dart
// 📊 MODELO DE ESTADOS DE ASISTENCIA FASE A1.1 - Estados unificados
import 'evento_model.dart';
import 'usuario_model.dart';
import 'attendance_policies_model.dart';

// 🎯 ENUM DE ESTADO DE TRACKING
enum TrackingStatus {
  initial, // Estado inicial, sin tracking
  active, // Tracking activo
  paused, // Pausado durante receso
  stopped, // Tracking detenido manualmente
  completed, // Evento completado
  error, // Error en tracking
}

// 🎯 ENUM DE ESTADO DE ASISTENCIA
enum AttendanceStatus {
  notStarted, // Evento no ha comenzado
  canRegister, // Puede registrar asistencia
  registered, // Asistencia ya registrada
  outsideGeofence, // Fuera del área permitida
  gracePeriod, // En período de gracia
  violation, // Violación de límites
}

// 🎯 CLASE PRINCIPAL DE ESTADO DE ASISTENCIA
class AttendanceState {
  // 📍 INFORMACIÓN BÁSICA
  final Usuario? currentUser;
  final Evento? currentEvent;
  final AttendancePolicies? policies;

  // 📍 ESTADO DE TRACKING
  final TrackingStatus trackingStatus;
  final AttendanceStatus attendanceStatus;

  // 📍 UBICACIÓN Y GEOFENCING
  final bool isInsideGeofence;
  final double userLatitude;
  final double userLongitude;
  final double distanceToEvent;

  // 📍 PERÍODO DE GRACIA
  final bool isInGracePeriod;
  final int gracePeriodRemaining; // En segundos

  // 📍 ASISTENCIA
  final bool canRegisterAttendance;
  final bool hasRegisteredAttendance;
  final bool hasViolatedBoundary;

  // 📍 TIMESTAMPS
  final DateTime? lastLocationUpdate;
  final DateTime? trackingStartTime;
  final DateTime? attendanceRegisteredTime;

  // 📍 ERRORES
  final String? lastError;

  const AttendanceState({
    this.currentUser,
    this.currentEvent,
    this.policies,
    required this.trackingStatus,
    required this.attendanceStatus,
    required this.isInsideGeofence,
    required this.userLatitude,
    required this.userLongitude,
    required this.distanceToEvent,
    required this.isInGracePeriod,
    required this.gracePeriodRemaining,
    required this.canRegisterAttendance,
    required this.hasRegisteredAttendance,
    required this.hasViolatedBoundary,
    this.lastLocationUpdate,
    this.trackingStartTime,
    this.attendanceRegisteredTime,
    this.lastError,
  });

  // 🏭 FACTORY: ESTADO INICIAL
  factory AttendanceState.initial() {
    return const AttendanceState(
      trackingStatus: TrackingStatus.initial,
      attendanceStatus: AttendanceStatus.notStarted,
      isInsideGeofence: false,
      userLatitude: 0.0,
      userLongitude: 0.0,
      distanceToEvent: 0.0,
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
      canRegisterAttendance: false,
      hasRegisteredAttendance: false,
      hasViolatedBoundary: false,
    );
  }

  // 🏭 FACTORY: ESTADO DE ERROR
  factory AttendanceState.error(String errorMessage) {
    return AttendanceState(
      trackingStatus: TrackingStatus.error,
      attendanceStatus: AttendanceStatus.notStarted,
      isInsideGeofence: false,
      userLatitude: 0.0,
      userLongitude: 0.0,
      distanceToEvent: 0.0,
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
      canRegisterAttendance: false,
      hasRegisteredAttendance: false,
      hasViolatedBoundary: false,
      lastError: errorMessage,
    );
  }

  // 🔄 COPYWITH: CREAR COPIA CON CAMBIOS ESPECÍFICOS
  AttendanceState copyWith({
    Usuario? currentUser,
    Evento? currentEvent,
    AttendancePolicies? policies,
    TrackingStatus? trackingStatus,
    AttendanceStatus? attendanceStatus,
    bool? isInsideGeofence,
    double? userLatitude,
    double? userLongitude,
    double? distanceToEvent,
    bool? isInGracePeriod,
    int? gracePeriodRemaining,
    bool? canRegisterAttendance,
    bool? hasRegisteredAttendance,
    bool? hasViolatedBoundary,
    DateTime? lastLocationUpdate,
    DateTime? trackingStartTime,
    DateTime? attendanceRegisteredTime,
    String? lastError,
  }) {
    return AttendanceState(
      currentUser: currentUser ?? this.currentUser,
      currentEvent: currentEvent ?? this.currentEvent,
      policies: policies ?? this.policies,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      distanceToEvent: distanceToEvent ?? this.distanceToEvent,
      isInGracePeriod: isInGracePeriod ?? this.isInGracePeriod,
      gracePeriodRemaining: gracePeriodRemaining ?? this.gracePeriodRemaining,
      canRegisterAttendance:
          canRegisterAttendance ?? this.canRegisterAttendance,
      hasRegisteredAttendance:
          hasRegisteredAttendance ?? this.hasRegisteredAttendance,
      hasViolatedBoundary: hasViolatedBoundary ?? this.hasViolatedBoundary,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      trackingStartTime: trackingStartTime ?? this.trackingStartTime,
      attendanceRegisteredTime:
          attendanceRegisteredTime ?? this.attendanceRegisteredTime,
      lastError: lastError ?? this.lastError,
    );
  }

  // 🔍 GETTERS COMPUTADOS

  /// Indica si el tracking está actualmente en ejecución
  bool get isTrackingActive => trackingStatus == TrackingStatus.active;

  /// Indica si el usuario está en una situación crítica
  bool get isCriticalState =>
      isInGracePeriod ||
      hasViolatedBoundary ||
      trackingStatus == TrackingStatus.error;

  /// Obtiene el texto de estado legible para el usuario
  String get statusText {
    if (trackingStatus == TrackingStatus.error) {
      return 'Error en el sistema';
    }

    if (trackingStatus == TrackingStatus.paused) {
      return 'Tracking pausado (receso)';
    }

    if (!isTrackingActive) {
      return 'Tracking no activo';
    }

    if (isInGracePeriod) {
      final minutes = (gracePeriodRemaining / 60).floor();
      final seconds = gracePeriodRemaining % 60;
      return 'Período de gracia: ${minutes}m ${seconds}s';
    }

    if (hasViolatedBoundary) {
      return 'Violación de límites detectada';
    }

    if (isInsideGeofence) {
      if (canRegisterAttendance && !hasRegisteredAttendance) {
        return 'Dentro del área - Puede registrar asistencia';
      }
      if (hasRegisteredAttendance) {
        return 'Asistencia registrada - Dentro del área';
      }
      return 'Dentro del área del evento';
    } else {
      return 'Fuera del área del evento';
    }
  }

  /// Obtiene el color de estado para la UI
  String get statusColor {
    if (trackingStatus == TrackingStatus.error || hasViolatedBoundary) {
      return '#FF4444'; // Rojo crítico
    }

    if (isInGracePeriod) {
      return '#FF6B35'; // Naranja de advertencia
    }

    if (isInsideGeofence && canRegisterAttendance) {
      return '#4ECDC4'; // Teal exitoso
    }

    if (isInsideGeofence) {
      return '#4CAF50'; // Verde seguro
    }

    return '#9E9E9E'; // Gris neutral
  }

  /// Indica si se debe mostrar información de debugging
  bool get shouldShowDebugInfo =>
      trackingStatus == TrackingStatus.error || lastError != null;

  // 🎯 MÉTODOS DE VALIDACIÓN

  /// Verifica si el estado actual permite registrar asistencia
  bool get canAttemptAttendanceRegistration {
    return trackingStatus == TrackingStatus.active &&
        isInsideGeofence &&
        canRegisterAttendance &&
        !hasRegisteredAttendance;
  }

  /// Verifica si el usuario necesita atención inmediata
  bool get requiresImmediateAttention {
    return isInGracePeriod && gracePeriodRemaining < 30; // Últimos 30 segundos
  }

  /// Verifica si el tracking está en un estado estable
  bool get isStableState {
    return trackingStatus == TrackingStatus.active &&
        lastError == null &&
        !isInGracePeriod;
  }

  // 🐛 DEBUGGING Y LOGGING

  @override
  String toString() {
    return 'AttendanceState('
        'trackingStatus: $trackingStatus, '
        'attendanceStatus: $attendanceStatus, '
        'isInsideGeofence: $isInsideGeofence, '
        'distance: ${distanceToEvent.toStringAsFixed(1)}m, '
        'gracePeriod: $isInGracePeriod, '
        'remaining: ${gracePeriodRemaining}s, '
        'canRegister: $canRegisterAttendance, '
        'hasRegistered: $hasRegisteredAttendance, '
        'hasViolated: $hasViolatedBoundary, '
        'error: $lastError'
        ')';
  }

  /// Información detallada para debugging
  Map<String, dynamic> toDebugMap() {
    return {
      'user': currentUser?.nombre ?? 'No user',
      'event': currentEvent?.titulo ?? 'No event',
      'trackingStatus': trackingStatus.toString(),
      'attendanceStatus': attendanceStatus.toString(),
      'location': {
        'isInside': isInsideGeofence,
        'userLat': userLatitude,
        'userLng': userLongitude,
        'distance': distanceToEvent,
      },
      'gracePeriod': {
        'active': isInGracePeriod,
        'remaining': gracePeriodRemaining,
      },
      'attendance': {
        'canRegister': canRegisterAttendance,
        'hasRegistered': hasRegisteredAttendance,
        'hasViolated': hasViolatedBoundary,
      },
      'timestamps': {
        'lastUpdate': lastLocationUpdate?.toIso8601String(),
        'trackingStart': trackingStartTime?.toIso8601String(),
        'attendanceRegistered': attendanceRegisteredTime?.toIso8601String(),
      },
      'error': lastError,
    };
  }

  /// ✅ NUEVO: Serializar a JSON para persistencia
  Map<String, dynamic> toJson() => toDebugMap();

  /// ✅ NUEVO: Deserializar desde JSON para persistencia
  factory AttendanceState.fromJson(Map<String, dynamic> json) {
    return AttendanceState(
      currentUser: json['currentUser'] != null 
          ? Usuario.fromJson(json['currentUser'] as Map<String, dynamic>)
          : null,
      currentEvent: json['currentEvent'] != null
          ? Evento.fromJson(json['currentEvent'] as Map<String, dynamic>)
          : null,
      policies: json['policies'] != null
          ? AttendancePolicies.fromJson(json['policies'] as Map<String, dynamic>)
          : null,
      trackingStatus: _parseTrackingStatus(json['trackingStatus'] as String? ?? 'initial'),
      attendanceStatus: _parseAttendanceStatus(json['attendanceStatus'] as String? ?? 'notStarted'),
      isInsideGeofence: json['location']?['insideGeofence'] as bool? ?? false,
      userLatitude: json['location']?['latitude']?.toDouble() ?? 0.0,
      userLongitude: json['location']?['longitude']?.toDouble() ?? 0.0,
      distanceToEvent: json['location']?['distance']?.toDouble() ?? 999999.0,
      isInGracePeriod: json['gracePeriod']?['active'] as bool? ?? false,
      gracePeriodRemaining: json['gracePeriod']?['remaining'] as int? ?? 0,
      canRegisterAttendance: json['attendance']?['canRegister'] as bool? ?? false,
      hasRegisteredAttendance: json['attendance']?['hasRegistered'] as bool? ?? false,
      hasViolatedBoundary: json['attendance']?['hasViolated'] as bool? ?? false,
      lastLocationUpdate: json['timestamps']?['lastUpdate'] != null
          ? DateTime.parse(json['timestamps']['lastUpdate'] as String)
          : null,
      trackingStartTime: json['timestamps']?['trackingStart'] != null
          ? DateTime.parse(json['timestamps']['trackingStart'] as String)
          : null,
      attendanceRegisteredTime: json['timestamps']?['attendanceRegistered'] != null
          ? DateTime.parse(json['timestamps']['attendanceRegistered'] as String)
          : null,
      lastError: json['error'] as String?,
    );
  }

  /// Helper para parsear TrackingStatus desde string
  static TrackingStatus _parseTrackingStatus(String status) {
    switch (status) {
      case 'initial': return TrackingStatus.initial;
      case 'active': return TrackingStatus.active;
      case 'paused': return TrackingStatus.paused;
      case 'stopped': return TrackingStatus.stopped;
      case 'completed': return TrackingStatus.completed;
      case 'error': return TrackingStatus.error;
      default: return TrackingStatus.initial;
    }
  }

  /// Helper para parsear AttendanceStatus desde string
  static AttendanceStatus _parseAttendanceStatus(String status) {
    switch (status) {
      case 'notStarted': return AttendanceStatus.notStarted;
      case 'canRegister': return AttendanceStatus.canRegister;
      case 'registered': return AttendanceStatus.registered;
      case 'outsideGeofence': return AttendanceStatus.outsideGeofence;
      case 'gracePeriod': return AttendanceStatus.gracePeriod;
      case 'violation': return AttendanceStatus.violation;
      default: return AttendanceStatus.notStarted;
    }
  }
}
