// lib/models/attendance_policies_model.dart
// ⚙️ MODELO DE POLÍTICAS DE ASISTENCIA FASE A1.1 - Políticas dinámicas del evento
// VERSIÓN CORREGIDA - Sin JSON serialization automática

import 'evento_model.dart';

class AttendancePolicies {
  // 🎯 POLÍTICAS PRINCIPALES DE ASISTENCIA

  /// Período de gracia en minutos cuando el usuario sale del geofence
  final int gracePeriodMinutes;

  /// Radio del geofence en metros
  final double geofenceRadiusMeters;

  /// Intervalo de tracking en segundos
  final int trackingIntervalSeconds;

  /// Permite registro de asistencia solo cuando está dentro del geofence
  final bool requireGeofenceForAttendance;

  /// Permite múltiples registros de asistencia
  final bool allowMultipleRegistrations;

  /// Tiempo máximo de ausencia permitido en minutos (antes de marcar falta)
  final int maxAbsenceMinutes;

  /// Habilita notificaciones push
  final bool enableNotifications;

  /// Habilita tracking en background
  final bool enableBackgroundTracking;

  /// Precisión requerida del GPS en metros
  final double requiredGpsAccuracy;

  /// Configuración de recesos
  final BreakConfiguration? breakConfiguration;

  /// Configuración de validaciones especiales
  final ValidationRules? validationRules;

  const AttendancePolicies({
    required this.gracePeriodMinutes,
    required this.geofenceRadiusMeters,
    required this.trackingIntervalSeconds,
    required this.requireGeofenceForAttendance,
    required this.allowMultipleRegistrations,
    required this.maxAbsenceMinutes,
    required this.enableNotifications,
    required this.enableBackgroundTracking,
    required this.requiredGpsAccuracy,
    this.breakConfiguration,
    this.validationRules,
  });

  // 🏭 FACTORY METHODS

  /// Factory manual para parsear JSON
  factory AttendancePolicies.fromJson(Map<String, dynamic> json) {
    return AttendancePolicies(
      gracePeriodMinutes: json['gracePeriodMinutes'] ?? 1,
      geofenceRadiusMeters: (json['geofenceRadiusMeters'] ?? 100.0).toDouble(),
      trackingIntervalSeconds: json['trackingIntervalSeconds'] ?? 30,
      requireGeofenceForAttendance:
          json['requireGeofenceForAttendance'] ?? true,
      allowMultipleRegistrations: json['allowMultipleRegistrations'] ?? false,
      maxAbsenceMinutes: json['maxAbsenceMinutes'] ?? 10,
      enableNotifications: json['enableNotifications'] ?? true,
      enableBackgroundTracking: json['enableBackgroundTracking'] ?? true,
      requiredGpsAccuracy: (json['requiredGpsAccuracy'] ?? 10.0).toDouble(),
      breakConfiguration: json['breakConfiguration'] != null
          ? BreakConfiguration.fromJson(
              json['breakConfiguration'] as Map<String, dynamic>)
          : null,
      validationRules: json['validationRules'] != null
          ? ValidationRules.fromJson(
              json['validationRules'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'gracePeriodMinutes': gracePeriodMinutes,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'trackingIntervalSeconds': trackingIntervalSeconds,
      'requireGeofenceForAttendance': requireGeofenceForAttendance,
      'allowMultipleRegistrations': allowMultipleRegistrations,
      'maxAbsenceMinutes': maxAbsenceMinutes,
      'enableNotifications': enableNotifications,
      'enableBackgroundTracking': enableBackgroundTracking,
      'requiredGpsAccuracy': requiredGpsAccuracy,
      'breakConfiguration': breakConfiguration?.toJson(),
      'validationRules': validationRules?.toJson(),
    };
  }

  // 🏭 FACTORY: CREAR DESDE EVENTO
  factory AttendancePolicies.fromEvento(Evento evento) {
    return AttendancePolicies(
      gracePeriodMinutes: 1, // Valor por defecto del sistema
      geofenceRadiusMeters: evento.rangoPermitido,
      trackingIntervalSeconds: 30, // Optimizado para A1.1
      requireGeofenceForAttendance: true,
      allowMultipleRegistrations: false,
      maxAbsenceMinutes: 10,
      enableNotifications: true,
      enableBackgroundTracking: true,
      requiredGpsAccuracy: 10.0,
      // Configuraciones por defecto para el evento
      breakConfiguration: BreakConfiguration.defaultConfig(),
      validationRules: ValidationRules.defaultRules(),
    );
  }

  // 🏭 FACTORY: POLÍTICAS POR DEFECTO DEL SISTEMA
  factory AttendancePolicies.defaultPolicies() {
    return const AttendancePolicies(
      gracePeriodMinutes: 1,
      geofenceRadiusMeters: 100.0,
      trackingIntervalSeconds: 30,
      requireGeofenceForAttendance: true,
      allowMultipleRegistrations: false,
      maxAbsenceMinutes: 10,
      enableNotifications: true,
      enableBackgroundTracking: true,
      requiredGpsAccuracy: 10.0,
    );
  }

  // 🏭 FACTORY: POLÍTICAS ESTRICTAS
  factory AttendancePolicies.strictPolicies() {
    return const AttendancePolicies(
      gracePeriodMinutes: 0, // Sin período de gracia
      geofenceRadiusMeters: 50.0, // Radio más pequeño
      trackingIntervalSeconds: 15, // Tracking más frecuente
      requireGeofenceForAttendance: true,
      allowMultipleRegistrations: false,
      maxAbsenceMinutes: 5, // Menos tolerancia
      enableNotifications: true,
      enableBackgroundTracking: true,
      requiredGpsAccuracy: 5.0, // Mayor precisión requerida
    );
  }

  // 🏭 FACTORY: POLÍTICAS FLEXIBLES
  factory AttendancePolicies.flexiblePolicies() {
    return const AttendancePolicies(
      gracePeriodMinutes: 3, // Período de gracia más largo
      geofenceRadiusMeters: 200.0, // Radio más amplio
      trackingIntervalSeconds: 60, // Tracking menos frecuente
      requireGeofenceForAttendance: false, // Permite registro fuera del área
      allowMultipleRegistrations: true,
      maxAbsenceMinutes: 20, // Mayor tolerancia
      enableNotifications: true,
      enableBackgroundTracking: true,
      requiredGpsAccuracy: 20.0, // Menor precisión requerida
    );
  }

  // 🔄 COPYWITH
  AttendancePolicies copyWith({
    int? gracePeriodMinutes,
    double? geofenceRadiusMeters,
    int? trackingIntervalSeconds,
    bool? requireGeofenceForAttendance,
    bool? allowMultipleRegistrations,
    int? maxAbsenceMinutes,
    bool? enableNotifications,
    bool? enableBackgroundTracking,
    double? requiredGpsAccuracy,
    BreakConfiguration? breakConfiguration,
    ValidationRules? validationRules,
  }) {
    return AttendancePolicies(
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      trackingIntervalSeconds:
          trackingIntervalSeconds ?? this.trackingIntervalSeconds,
      requireGeofenceForAttendance:
          requireGeofenceForAttendance ?? this.requireGeofenceForAttendance,
      allowMultipleRegistrations:
          allowMultipleRegistrations ?? this.allowMultipleRegistrations,
      maxAbsenceMinutes: maxAbsenceMinutes ?? this.maxAbsenceMinutes,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableBackgroundTracking:
          enableBackgroundTracking ?? this.enableBackgroundTracking,
      requiredGpsAccuracy: requiredGpsAccuracy ?? this.requiredGpsAccuracy,
      breakConfiguration: breakConfiguration ?? this.breakConfiguration,
      validationRules: validationRules ?? this.validationRules,
    );
  }

  // 🔍 GETTERS COMPUTADOS

  /// Período de gracia en segundos
  int get gracePeriodSeconds => gracePeriodMinutes * 60;

  /// Tiempo máximo de ausencia en segundos
  int get maxAbsenceSeconds => maxAbsenceMinutes * 60;

  /// Indica si las políticas son estrictas
  bool get isStrictMode => gracePeriodMinutes == 0 && maxAbsenceMinutes <= 5;

  /// Indica si las políticas son flexibles
  bool get isFlexibleMode =>
      gracePeriodMinutes >= 3 && !requireGeofenceForAttendance;

  /// Obtiene la descripción del modo de políticas
  String get modeDescription {
    if (isStrictMode) return 'Modo Estricto';
    if (isFlexibleMode) return 'Modo Flexible';
    return 'Modo Estándar';
  }

  /// Obtiene un resumen de las políticas para mostrar al usuario
  Map<String, String> get userFriendlySummary {
    return {
      'Período de gracia': gracePeriodMinutes == 0
          ? 'Sin período de gracia'
          : '$gracePeriodMinutes minuto${gracePeriodMinutes > 1 ? 's' : ''}',
      'Área de asistencia': '${geofenceRadiusMeters.toStringAsFixed(0)} metros',
      'Registro requerido':
          requireGeofenceForAttendance ? 'Solo dentro del área' : 'Flexible',
      'Tracking': 'Cada $trackingIntervalSeconds segundos',
      'Ausencia máxima': '$maxAbsenceMinutes minutos',
    };
  }

  // 🔧 MÉTODOS DE VALIDACIÓN

  /// Valida si las políticas son coherentes
  bool isValid() {
    return gracePeriodMinutes >= 0 &&
        geofenceRadiusMeters > 0 &&
        trackingIntervalSeconds > 0 &&
        maxAbsenceMinutes > 0 &&
        requiredGpsAccuracy > 0;
  }

  /// Obtiene los errores de validación
  List<String> getValidationErrors() {
    List<String> errors = [];

    if (gracePeriodMinutes < 0) {
      errors.add('El período de gracia no puede ser negativo');
    }

    if (geofenceRadiusMeters <= 0) {
      errors.add('El radio del geofence debe ser mayor a 0');
    }

    if (trackingIntervalSeconds <= 0) {
      errors.add('El intervalo de tracking debe ser mayor a 0');
    }

    if (maxAbsenceMinutes <= 0) {
      errors.add('El tiempo máximo de ausencia debe ser mayor a 0');
    }

    if (requiredGpsAccuracy <= 0) {
      errors.add('La precisión GPS requerida debe ser mayor a 0');
    }

    return errors;
  }

  @override
  String toString() {
    return 'AttendancePolicies('
        'grace: ${gracePeriodMinutes}min, '
        'radius: ${geofenceRadiusMeters}m, '
        'interval: ${trackingIntervalSeconds}s, '
        'requireGeofence: $requireGeofenceForAttendance, '
        'maxAbsence: ${maxAbsenceMinutes}min'
        ')';
  }
}

// 🎯 CONFIGURACIÓN DE RECESOS
class BreakConfiguration {
  final bool allowBreaks;
  final int maxBreakDurationMinutes;
  final int maxBreaksPerEvent;
  final bool requireReturnToGeofence;

  const BreakConfiguration({
    required this.allowBreaks,
    required this.maxBreakDurationMinutes,
    required this.maxBreaksPerEvent,
    required this.requireReturnToGeofence,
  });

  /// Factory manual para parsear JSON
  factory BreakConfiguration.fromJson(Map<String, dynamic> json) {
    return BreakConfiguration(
      allowBreaks: json['allowBreaks'] ?? true,
      maxBreakDurationMinutes: json['maxBreakDurationMinutes'] ?? 15,
      maxBreaksPerEvent: json['maxBreaksPerEvent'] ?? 2,
      requireReturnToGeofence: json['requireReturnToGeofence'] ?? true,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'allowBreaks': allowBreaks,
      'maxBreakDurationMinutes': maxBreakDurationMinutes,
      'maxBreaksPerEvent': maxBreaksPerEvent,
      'requireReturnToGeofence': requireReturnToGeofence,
    };
  }

  factory BreakConfiguration.defaultConfig() {
    return const BreakConfiguration(
      allowBreaks: true,
      maxBreakDurationMinutes: 15,
      maxBreaksPerEvent: 2,
      requireReturnToGeofence: true,
    );
  }

  @override
  String toString() {
    return 'BreakConfiguration('
        'allowed: $allowBreaks, '
        'maxDuration: ${maxBreakDurationMinutes}min, '
        'maxBreaks: $maxBreaksPerEvent, '
        'requireReturn: $requireReturnToGeofence'
        ')';
  }
}

// 🎯 REGLAS DE VALIDACIÓN
class ValidationRules {
  /// Requiere confirmación manual para registrar asistencia
  final bool requireManualConfirmation;

  /// Requiere que el dispositivo esté conectado a WiFi específico
  final bool requireSpecificWifi;

  /// SSID del WiFi requerido (si requireSpecificWifi es true)
  final String? requiredWifiSSID;

  /// Permite registro solo en horarios específicos
  final bool restrictByTimeWindow;

  /// Hora de inicio permitida (formato HH:mm)
  final String? allowedStartTime;

  /// Hora de fin permitida (formato HH:mm)
  final String? allowedEndTime;

  /// Requiere código QR específico del evento
  final bool requireQRCode;

  /// Código QR del evento
  final String? eventQRCode;

  const ValidationRules({
    required this.requireManualConfirmation,
    required this.requireSpecificWifi,
    this.requiredWifiSSID,
    required this.restrictByTimeWindow,
    this.allowedStartTime,
    this.allowedEndTime,
    required this.requireQRCode,
    this.eventQRCode,
  });

  /// Factory manual para parsear JSON
  factory ValidationRules.fromJson(Map<String, dynamic> json) {
    return ValidationRules(
      requireManualConfirmation: json['requireManualConfirmation'] ?? false,
      requireSpecificWifi: json['requireSpecificWifi'] ?? false,
      requiredWifiSSID: json['requiredWifiSSID'],
      restrictByTimeWindow: json['restrictByTimeWindow'] ?? false,
      allowedStartTime: json['allowedStartTime'],
      allowedEndTime: json['allowedEndTime'],
      requireQRCode: json['requireQRCode'] ?? false,
      eventQRCode: json['eventQRCode'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'requireManualConfirmation': requireManualConfirmation,
      'requireSpecificWifi': requireSpecificWifi,
      'requiredWifiSSID': requiredWifiSSID,
      'restrictByTimeWindow': restrictByTimeWindow,
      'allowedStartTime': allowedStartTime,
      'allowedEndTime': allowedEndTime,
      'requireQRCode': requireQRCode,
      'eventQRCode': eventQRCode,
    };
  }

  factory ValidationRules.defaultRules() {
    return const ValidationRules(
      requireManualConfirmation: false,
      requireSpecificWifi: false,
      restrictByTimeWindow: false,
      requireQRCode: false,
    );
  }

  factory ValidationRules.strictRules() {
    return const ValidationRules(
      requireManualConfirmation: true,
      requireSpecificWifi: true,
      restrictByTimeWindow: true,
      requireQRCode: false,
    );
  }

  /// Indica si hay validaciones adicionales activas
  bool get hasActiveValidations {
    return requireManualConfirmation ||
        requireSpecificWifi ||
        restrictByTimeWindow ||
        requireQRCode;
  }

  /// Obtiene lista de validaciones activas para mostrar al usuario
  List<String> get activeValidationsList {
    List<String> validations = [];

    if (requireManualConfirmation) {
      validations.add('Confirmación manual requerida');
    }

    if (requireSpecificWifi && requiredWifiSSID != null) {
      validations.add('WiFi específico: $requiredWifiSSID');
    }

    if (restrictByTimeWindow &&
        allowedStartTime != null &&
        allowedEndTime != null) {
      validations.add('Horario permitido: $allowedStartTime - $allowedEndTime');
    }

    if (requireQRCode) {
      validations.add('Código QR requerido');
    }

    return validations;
  }

  @override
  String toString() {
    return 'ValidationRules('
        'manual: $requireManualConfirmation, '
        'wifi: $requireSpecificWifi, '
        'timeWindow: $restrictByTimeWindow, '
        'qr: $requireQRCode'
        ')';
  }
}
