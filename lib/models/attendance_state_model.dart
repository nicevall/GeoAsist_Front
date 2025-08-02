// lib/models/attendance_state_model.dart
enum AttendanceState {
  outsideRange, // Fuera del rango del evento
  insideRange, // Dentro del rango, puede registrar
  registered, // Ya registró asistencia exitosamente
  gracePeriod, // En período de gracia (fuera pero con 60s)
  eventEnded, // Evento terminó, no puede registrar
  eventNotStarted, // Evento aún no inicia
  loading, // Verificando estado
  error, // Error al verificar estado
}

class StudentAttendanceStatus {
  final String eventoId;
  final AttendanceState state;
  final bool hasRegistered;
  final DateTime? registeredAt;
  final int gracePeriodSeconds;
  final bool isInsideGeofence;
  final String? errorMessage;
  final double? distanceToEvent; // Distancia en metros al evento

  StudentAttendanceStatus({
    required this.eventoId,
    required this.state,
    this.hasRegistered = false,
    this.registeredAt,
    this.gracePeriodSeconds = 60,
    this.isInsideGeofence = false,
    this.errorMessage,
    this.distanceToEvent,
  });

  // Crear copia con cambios
  StudentAttendanceStatus copyWith({
    String? eventoId,
    AttendanceState? state,
    bool? hasRegistered,
    DateTime? registeredAt,
    int? gracePeriodSeconds,
    bool? isInsideGeofence,
    String? errorMessage,
    double? distanceToEvent,
  }) {
    return StudentAttendanceStatus(
      eventoId: eventoId ?? this.eventoId,
      state: state ?? this.state,
      hasRegistered: hasRegistered ?? this.hasRegistered,
      registeredAt: registeredAt ?? this.registeredAt,
      gracePeriodSeconds: gracePeriodSeconds ?? this.gracePeriodSeconds,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      errorMessage: errorMessage ?? this.errorMessage,
      distanceToEvent: distanceToEvent ?? this.distanceToEvent,
    );
  }

  // Estado inicial para un evento
  factory StudentAttendanceStatus.initial(String eventoId) {
    return StudentAttendanceStatus(
      eventoId: eventoId,
      state: AttendanceState.loading,
      hasRegistered: false,
      gracePeriodSeconds: 60,
      isInsideGeofence: false,
    );
  }

  // Getters de conveniencia
  bool get canRegisterAttendance =>
      state == AttendanceState.insideRange && !hasRegistered;

  bool get showAttendanceButton =>
      state == AttendanceState.insideRange && !hasRegistered;

  bool get showGracePeriodWarning => state == AttendanceState.gracePeriod;

  bool get isInActiveEvent =>
      state != AttendanceState.eventEnded &&
      state != AttendanceState.eventNotStarted;

  String get statusMessage {
    switch (state) {
      case AttendanceState.outsideRange:
        return isInsideGeofence
            ? 'Fuera del área del evento'
            : 'Dirigiéndose al evento...';
      case AttendanceState.insideRange:
        return hasRegistered
            ? '✅ Asistencia ya registrada'
            : '✅ En el área del evento';
      case AttendanceState.registered:
        return '✅ Asistencia registrada exitosamente';
      case AttendanceState.gracePeriod:
        return '⚠️ Período de gracia activo';
      case AttendanceState.eventEnded:
        return '🔒 Evento finalizado';
      case AttendanceState.eventNotStarted:
        return '⏰ Evento aún no inicia';
      case AttendanceState.loading:
        return '🔄 Verificando estado...';
      case AttendanceState.error:
        return errorMessage ?? '❌ Error al verificar estado';
    }
  }

  String get buttonText {
    switch (state) {
      case AttendanceState.insideRange:
        return hasRegistered
            ? '✅ Asistencia Confirmada'
            : 'Registrar Mi Asistencia';
      case AttendanceState.registered:
        return '✅ Asistencia Confirmada';
      case AttendanceState.gracePeriod:
        return 'Regresa al área para registrar';
      case AttendanceState.eventEnded:
        return 'Evento finalizado';
      case AttendanceState.eventNotStarted:
        return 'Evento no ha iniciado';
      default:
        return 'Acércate al evento';
    }
  }

  // Convertir respuesta del backend a estado
  factory StudentAttendanceStatus.fromLocationResponse({
    required String eventoId,
    required Map<String, dynamic> locationData,
    required bool hasRegistered,
    DateTime? registeredAt,
  }) {
    final bool insideGeofence = locationData['insideGeofence'] ?? false;
    final double? distance = locationData['distance']?.toDouble();
    final bool eventActive = locationData['eventActive'] ?? true;
    final bool eventStarted = locationData['eventStarted'] ?? true;

    AttendanceState state;

    if (!eventStarted) {
      state = AttendanceState.eventNotStarted;
    } else if (!eventActive) {
      state = AttendanceState.eventEnded;
    } else if (hasRegistered) {
      state = AttendanceState.registered;
    } else if (insideGeofence) {
      state = AttendanceState.insideRange;
    } else {
      // Si estuvo dentro pero salió, iniciar período de gracia
      final bool wasInside = locationData['wasInside'] ?? false;
      state = wasInside
          ? AttendanceState.gracePeriod
          : AttendanceState.outsideRange;
    }

    return StudentAttendanceStatus(
      eventoId: eventoId,
      state: state,
      hasRegistered: hasRegistered,
      registeredAt: registeredAt,
      isInsideGeofence: insideGeofence,
      distanceToEvent: distance,
      gracePeriodSeconds: state == AttendanceState.gracePeriod ? 60 : 0,
    );
  }

  @override
  String toString() {
    return 'StudentAttendanceStatus(eventoId: $eventoId, state: $state, '
        'hasRegistered: $hasRegistered, isInsideGeofence: $isInsideGeofence, '
        'distance: ${distanceToEvent?.toStringAsFixed(1)}m)';
  }
}
