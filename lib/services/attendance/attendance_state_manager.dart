// lib/services/attendance/attendance_state_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/ubicacion_model.dart';

/// ✅ ATTENDANCE STATE MANAGER: Estados de asistencia según backend
/// Responsabilidades:
/// - Manejo de estados de asistencia exactos del backend
/// - Transiciones de estado válidas según flujo backend
/// - Cache de estados para optimización
/// - Validación de cambios de estado
/// - Sincronización con estado del servidor
class AttendanceStateManager {
  static final AttendanceStateManager _instance = AttendanceStateManager._internal();
  factory AttendanceStateManager() => _instance;
  AttendanceStateManager._internal();

  // 🎯 ESTADO ACTUAL
  EstadoAsistencia _currentState = EstadoAsistencia.inicial;
  DateTime? _lastStateChange;
  String? _currentEventId;
  Ubicacion? _lastKnownLocation;
  double? _lastCalculatedDistance;
  String? _stateReason;

  // 📊 HISTORIAL DE ESTADOS
  final List<AttendanceStateRecord> _stateHistory = [];
  static const int _maxHistorySize = 50;

  // 🔄 STREAMS
  final StreamController<AttendanceStateChange> _stateController = 
      StreamController<AttendanceStateChange>.broadcast();

  /// Stream para escuchar cambios de estado
  Stream<AttendanceStateChange> get stateStream => _stateController.stream;

  /// ✅ INICIALIZAR PARA EVENTO
  void initializeForEvent(String eventId) {
    debugPrint('🎯 Initializing attendance state for event: $eventId');
    
    _currentEventId = eventId;
    _transitionTo(EstadoAsistencia.inicial, 'Event initialized');
  }

  /// ✅ ACTUALIZAR ESTADO BASADO EN POSICIÓN
  void updateStateBasedOnPosition({
    required double latitude,
    required double longitude,
    required double distance,
    required double allowedRadius,
    required DateTime eventStartTime,
  }) {
    final now = DateTime.now();
    final minutesUntilStart = eventStartTime.difference(now).inMinutes;
    
    debugPrint('📍 Updating state - Distance: ${distance.toStringAsFixed(2)}m, '
               'Radius: ${allowedRadius}m, Minutes until start: $minutesUntilStart');

    _lastKnownLocation = Ubicacion(latitud: latitude, longitud: longitude);
    _lastCalculatedDistance = distance;

    // Determinar estado según flujo del backend
    final newState = _calculateStateFromBackendLogic(
      distance: distance,
      allowedRadius: allowedRadius,
      minutesUntilStart: minutesUntilStart,
    );

    if (newState != _currentState) {
      final reason = _getStateChangeReason(newState, distance, allowedRadius, minutesUntilStart);
      _transitionTo(newState, reason);
    }
  }

  /// 🔄 FORZAR TRANSICIÓN DE ESTADO
  void forceStateTransition(EstadoAsistencia newState, String reason) {
    debugPrint('🔄 Forcing state transition to: $newState (reason: $reason)');
    _transitionTo(newState, reason);
  }

  /// 🧮 CALCULAR ESTADO SEGÚN LÓGICA DEL BACKEND
  EstadoAsistencia _calculateStateFromBackendLogic({
    required double distance,
    required double allowedRadius,
    required int minutesUntilStart,
  }) {
    // Lógica exacta del backend según DETALLES BACK.md:
    
    // 1. Si está dentro del radio permitido -> PRESENTE
    if (distance <= allowedRadius) {
      return EstadoAsistencia.presente;
    }
    
    // 2. Si está fuera del radio pero antes de 10min del inicio -> PENDIENTE
    if (distance > allowedRadius && minutesUntilStart > 0) {
      return EstadoAsistencia.pendiente;
    }
    
    // 3. Si está fuera del radio y pasaron los 10min -> AUSENTE
    if (distance > allowedRadius && minutesUntilStart <= 0) {
      return EstadoAsistencia.ausente;
    }
    
    // 4. Estado por defecto
    return EstadoAsistencia.inicial;
  }

  /// ✅ TRANSICIÓN DE ESTADO
  void _transitionTo(EstadoAsistencia newState, String reason) {
    final previousState = _currentState;
    final timestamp = DateTime.now();
    
    // Validar transición
    if (!_isValidTransition(previousState, newState)) {
      debugPrint('❌ Invalid state transition: $previousState -> $newState');
      return;
    }
    
    // Actualizar estado
    _currentState = newState;
    _lastStateChange = timestamp;
    _stateReason = reason;
    
    // Registrar en historial
    _addToHistory(AttendanceStateRecord(
      fromState: previousState,
      toState: newState,
      timestamp: timestamp,
      reason: reason,
      location: _lastKnownLocation,
      distance: _lastCalculatedDistance,
    ));
    
    // Emitir evento
    final change = AttendanceStateChange(
      fromState: previousState,
      toState: newState,
      timestamp: timestamp,
      reason: reason,
      location: _lastKnownLocation,
      distance: _lastCalculatedDistance,
    );
    
    debugPrint('📊 State transition: $previousState -> $newState (reason: $reason)');
    _emitStateChange(change);
  }

  /// ✅ VALIDAR TRANSICIÓN DE ESTADO
  bool _isValidTransition(EstadoAsistencia from, EstadoAsistencia to) {
    // Matriz de transiciones válidas según backend
    const validTransitions = {
      EstadoAsistencia.inicial: [
        EstadoAsistencia.presente,
        EstadoAsistencia.pendiente,
        EstadoAsistencia.ausente,
      ],
      EstadoAsistencia.pendiente: [
        EstadoAsistencia.presente,
        EstadoAsistencia.ausente,
        EstadoAsistencia.tarde,
      ],
      EstadoAsistencia.presente: [
        EstadoAsistencia.ausente,
        EstadoAsistencia.tarde,
      ],
      EstadoAsistencia.ausente: [
        EstadoAsistencia.justificado,
        EstadoAsistencia.presente, // Puede volver si regresa a tiempo
      ],
      EstadoAsistencia.tarde: [
        EstadoAsistencia.ausente,
        EstadoAsistencia.justificado,
      ],
      EstadoAsistencia.justificado: [], // Estado final
    };
    
    return validTransitions[from]?.contains(to) ?? false;
  }

  /// 📝 OBTENER RAZÓN DEL CAMBIO DE ESTADO
  String _getStateChangeReason(
    EstadoAsistencia newState,
    double distance,
    double allowedRadius,
    int minutesUntilStart,
  ) {
    switch (newState) {
      case EstadoAsistencia.presente:
        return 'Within allowed radius (${distance.toStringAsFixed(1)}m ≤ ${allowedRadius}m)';
      case EstadoAsistencia.pendiente:
        return 'Outside radius but ${minutesUntilStart}min until start';
      case EstadoAsistencia.ausente:
        return 'Outside radius and past grace period';
      case EstadoAsistencia.tarde:
        return 'Arrived late but within allowed time';
      case EstadoAsistencia.justificado:
        return 'Manually justified';
      case EstadoAsistencia.inicial:
        return 'Initial state';
    }
  }

  /// 📚 AGREGAR AL HISTORIAL
  void _addToHistory(AttendanceStateRecord record) {
    _stateHistory.add(record);
    
    // Mantener tamaño máximo del historial
    while (_stateHistory.length > _maxHistorySize) {
      _stateHistory.removeAt(0);
    }
  }

  /// 📊 OBTENER ESTADO ACTUAL COMPLETO
  AttendanceStateInfo getCurrentStateInfo() {
    return AttendanceStateInfo(
      currentState: _currentState,
      lastStateChange: _lastStateChange,
      reason: _stateReason,
      eventId: _currentEventId,
      lastLocation: _lastKnownLocation,
      lastDistance: _lastCalculatedDistance,
    );
  }

  /// 📜 OBTENER HISTORIAL DE ESTADOS
  List<AttendanceStateRecord> getStateHistory() {
    return List.unmodifiable(_stateHistory);
  }

  /// 🔍 BUSCAR EN HISTORIAL
  List<AttendanceStateRecord> findStateChanges({
    EstadoAsistencia? fromState,
    EstadoAsistencia? toState,
    DateTime? after,
    DateTime? before,
  }) {
    return _stateHistory.where((record) {
      if (fromState != null && record.fromState != fromState) return false;
      if (toState != null && record.toState != toState) return false;
      if (after != null && record.timestamp.isBefore(after)) return false;
      if (before != null && record.timestamp.isAfter(before)) return false;
      return true;
    }).toList();
  }

  /// 🔄 EMITIR CAMBIO DE ESTADO
  void _emitStateChange(AttendanceStateChange change) {
    if (!_stateController.isClosed) {
      _stateController.add(change);
    }
  }

  /// 🧹 LIMPIAR ESTADO
  void clearState() {
    debugPrint('🧹 Clearing attendance state');
    
    _currentState = EstadoAsistencia.inicial;
    _lastStateChange = null;
    _currentEventId = null;
    _lastKnownLocation = null;
    _lastCalculatedDistance = null;
    _stateReason = null;
    _stateHistory.clear();
  }

  /// 🧹 CLEANUP
  void dispose() {
    debugPrint('🧹 Disposing AttendanceStateManager');
    
    _stateController.close();
    _stateHistory.clear();
    
    debugPrint('🧹 AttendanceStateManager disposed');
  }
}

/// ✅ ESTADOS DE ASISTENCIA (EXACTOS DEL BACKEND)
enum EstadoAsistencia {
  inicial,      // Estado inicial
  presente,     // Dentro del radio permitido
  pendiente,    // Fuera del radio pero <10min del inicio
  ausente,      // Fuera del radio y >10min
  justificado,  // Con documento válido
  tarde,        // Llegó tarde pero dentro del tiempo
}

/// ✅ INFORMACIÓN COMPLETA DEL ESTADO
class AttendanceStateInfo {
  final EstadoAsistencia currentState;
  final DateTime? lastStateChange;
  final String? reason;
  final String? eventId;
  final Ubicacion? lastLocation;
  final double? lastDistance;

  const AttendanceStateInfo({
    required this.currentState,
    this.lastStateChange,
    this.reason,
    this.eventId,
    this.lastLocation,
    this.lastDistance,
  });

  @override
  String toString() {
    return 'AttendanceStateInfo(state: $currentState, reason: $reason, '
           'distance: ${lastDistance?.toStringAsFixed(2)}m)';
  }
}

/// ✅ CAMBIO DE ESTADO
class AttendanceStateChange {
  final EstadoAsistencia fromState;
  final EstadoAsistencia toState;
  final DateTime timestamp;
  final String reason;
  final Ubicacion? location;
  final double? distance;

  const AttendanceStateChange({
    required this.fromState,
    required this.toState,
    required this.timestamp,
    required this.reason,
    this.location,
    this.distance,
  });

  @override
  String toString() {
    return 'AttendanceStateChange($fromState -> $toState: $reason)';
  }
}

/// ✅ REGISTRO DE ESTADO EN HISTORIAL
class AttendanceStateRecord {
  final EstadoAsistencia fromState;
  final EstadoAsistencia toState;
  final DateTime timestamp;
  final String reason;
  final Ubicacion? location;
  final double? distance;

  const AttendanceStateRecord({
    required this.fromState,
    required this.toState,
    required this.timestamp,
    required this.reason,
    this.location,
    this.distance,
  });

  @override
  String toString() {
    return 'AttendanceStateRecord(${timestamp.toIso8601String()}: $fromState -> $toState)';
  }
}