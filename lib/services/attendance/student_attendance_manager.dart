// lib/services/attendance/student_attendance_manager.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../models/evento_model.dart';
import '../../models/ubicacion_model.dart';
import '../location_service.dart';
import '../permission_service.dart';
import '../storage_service.dart';
import '../notifications/notification_manager.dart';
import '../asistencia/heartbeat_manager.dart';
import '../asistencia/geofence_manager.dart';
import 'attendance_state_manager.dart';
import 'grace_period_manager.dart';
import '../asistencia/asistencia_service.dart';

/// ✅ STUDENT ATTENDANCE MANAGER MODULAR: Coordinador de tracking
/// Responsabilidades:
/// - Coordinación central de todos los managers especializados
/// - App lifecycle management
/// - Tracking principal de estudiante
/// - Integración con servicios de localización
/// - Manejo de estados globales de tracking
/// - Sincronización entre todos los componentes
class StudentAttendanceManager {
  static final StudentAttendanceManager _instance = StudentAttendanceManager._internal();
  factory StudentAttendanceManager() => _instance;
  StudentAttendanceManager._internal();

  // 🎯 MANAGERS ESPECIALIZADOS
  final HeartbeatManager _heartbeatManager = HeartbeatManager();
  final GeofenceManager _geofenceManager = GeofenceManager();
  final AttendanceStateManager _stateManager = AttendanceStateManager();
  final GracePeriodManager _gracePeriodManager = GracePeriodManager();
  final AsistenciaService _asistenciaService = AsistenciaService();

  // 🎯 SERVICIOS
  final LocationService _locationService = LocationService();
  final PermissionService _permissionService = PermissionService();
  final StorageService _storageService = StorageService();
  final NotificationManager _notificationManager = NotificationManager();

  // 🎯 ESTADO DE TRACKING
  bool _isTrackingActive = false;
  bool _isAppInForeground = true;
  Evento? _currentEvent;
  Timer? _locationTimer;
  StreamSubscription? _geofenceSubscription;
  StreamSubscription? _gracePeriodSubscription;
  StreamSubscription? _stateSubscription;

  // ⚙️ CONFIGURACIÓN
  static const Duration _locationUpdateInterval = Duration(seconds: 10);

  // 🔄 STREAMS
  final StreamController<StudentTrackingState> _trackingController = 
      StreamController<StudentTrackingState>.broadcast();

  /// Stream para escuchar cambios de estado de tracking
  Stream<StudentTrackingState> get trackingStream => _trackingController.stream;

  /// ✅ INICIALIZAR TRACKING PARA EVENTO
  Future<bool> startTrackingForEvent(Evento evento) async {
    debugPrint('🎯 [StudentAttendanceManager] Starting tracking for: ${evento.titulo}');

    try {
      // 1. Verificar permisos
      final permissionResult = await _permissionService.requestLocationPermissions();
      if (permissionResult != LocationPermissionResult.granted) {
        debugPrint('❌ Location permissions not granted');
        return false;
      }

      // 2. Configurar evento actual
      _currentEvent = evento;

      // 3. Configurar managers especializados
      _geofenceManager.configureEvent(evento);
      _stateManager.initializeForEvent(evento.id!);

      // 4. Configurar suscripciones
      _setupSubscriptions();

      // 5. Iniciar heartbeat
      await _heartbeatManager.startHeartbeat(eventoId: evento.id!);

      // 6. Iniciar tracking de ubicación
      _startLocationTracking();

      // 7. Actualizar estado de app
      _updateAppLifecycleState();

      _isTrackingActive = true;
      _emitTrackingState(StudentTrackingStatus.active);

      debugPrint('✅ Tracking started successfully for event: ${evento.titulo}');
      return true;

    } catch (e) {
      debugPrint('❌ Error starting tracking: $e');
      await stopTracking();
      return false;
    }
  }

  /// ✅ DETENER TRACKING
  Future<void> stopTracking() async {
    debugPrint('🛑 [StudentAttendanceManager] Stopping tracking');

    try {
      _isTrackingActive = false;

      // 1. Detener heartbeat
      await _heartbeatManager.stopHeartbeat();

      // 2. Cancelar grace periods activos
      await _gracePeriodManager.cancelAllGracePeriods();

      // 3. Detener location tracking
      _locationTimer?.cancel();
      _locationTimer = null;

      // 4. Cancelar suscripciones
      _geofenceSubscription?.cancel();
      _gracePeriodSubscription?.cancel();
      _stateSubscription?.cancel();

      // 5. Limpiar estados
      _currentEvent = null;
      _stateManager.clearState();

      // 6. Limpiar notificaciones
      await _notificationManager.clearAllNotifications();

      _emitTrackingState(StudentTrackingStatus.stopped);
      debugPrint('✅ Tracking stopped successfully');

    } catch (e) {
      debugPrint('❌ Error stopping tracking: $e');
    }
  }

  /// ✅ MANEJAR CAMBIOS DE LIFECYCLE DE APP
  void handleAppLifecycleChange(AppLifecycleState state) {
    debugPrint('📱 [StudentAttendanceManager] App lifecycle changed: $state');

    final isInForeground = state == AppLifecycleState.resumed;
    
    if (_isAppInForeground == isInForeground) {
      return; // Sin cambios
    }

    _isAppInForeground = isInForeground;

    // Actualizar estado en managers
    _heartbeatManager.updateAppState(isInForeground: isInForeground);

    if (isInForeground) {
      _handleAppReturned();
    } else {
      _handleAppClosed();
    }
  }

  /// 🔄 CONFIGURAR SUSCRIPCIONES A MANAGERS
  void _setupSubscriptions() {
    // 1. Suscribirse a eventos de geofence
    _geofenceSubscription = _geofenceManager.geofenceStream.listen((event) {
      _handleGeofenceEvent(event);
    });

    // 2. Suscribirse a grace periods
    _gracePeriodSubscription = _gracePeriodManager.gracePeriodStream.listen((event) {
      _handleGracePeriodEvent(event);
    });

    // 3. Suscribirse a cambios de estado de asistencia
    _stateSubscription = _stateManager.stateStream.listen((change) {
      _handleAttendanceStateChange(change);
    });
  }

  /// 📍 INICIAR TRACKING DE UBICACIÓN
  void _startLocationTracking() {
    debugPrint('📍 Starting location tracking timer');

    _locationTimer = Timer.periodic(_locationUpdateInterval, (timer) async {
      if (!_isTrackingActive) {
        timer.cancel();
        return;
      }

      await _performLocationUpdate();
    });

    // Realizar primera actualización inmediatamente
    _performLocationUpdate();
  }

  /// 📍 REALIZAR ACTUALIZACIÓN DE UBICACIÓN
  Future<void> _performLocationUpdate() async {
    if (!_isTrackingActive || _currentEvent == null) return;

    try {
      // 1. Obtener ubicación actual
      final location = await _locationService.getCurrentPosition();
      if (location == null) {
        debugPrint('⚠️ Failed to get current location');
        return;
      }
      debugPrint('📍 Location update: ${location.latitude}, ${location.longitude}');

      // 2. Verificar geofence
      final geofenceResult = _geofenceManager.checkPosition(
        location.latitude,
        location.longitude,
        accuracy: location.accuracy,
      );

      if (!geofenceResult.isSuccess) {
        debugPrint('⚠️ Geofence check failed: ${geofenceResult.error}');
        return;
      }

      // 3. Actualizar estado de asistencia
      _stateManager.updateStateBasedOnPosition(
        latitude: location.latitude,
        longitude: location.longitude,
        distance: geofenceResult.distance!,
        allowedRadius: _currentEvent!.rangoPermitido,
        eventStartTime: _currentEvent!.horaInicio,
      );

      // 4. Actualizar ubicación en backend
      await _asistenciaService.actualizarUbicacion(
        latitud: location.latitude,
        longitud: location.longitude,
        eventoId: _currentEvent!.id,
      );

    } catch (e) {
      debugPrint('❌ Error in location update: $e');
    }
  }

  /// 🚨 MANEJAR EVENTO DE GEOFENCE
  void _handleGeofenceEvent(GeofenceEvent event) {
    debugPrint('🚨 Geofence event: ${event.type}');

    switch (event.type) {
      case GeofenceEventType.entered:
        _handleGeofenceEntered(event);
        break;
      case GeofenceEventType.exited:
        _handleGeofenceExited(event);
        break;
    }
  }

  /// ✅ MANEJAR ENTRADA A GEOFENCE
  void _handleGeofenceEntered(GeofenceEvent event) {
    debugPrint('✅ Student entered geofence');

    // Cancelar grace period de geofence si está activo
    if (_gracePeriodManager.isGeofenceGraceActive) {
      _gracePeriodManager.cancelGeofenceGracePeriod();
    }

    // Intentar registrar asistencia automáticamente
    _attemptAutomaticAttendanceRegistration(event.location);
  }

  /// 🚨 MANEJAR SALIDA DE GEOFENCE
  void _handleGeofenceExited(GeofenceEvent event) {
    debugPrint('🚨 Student exited geofence');

    // Iniciar grace period de geofence (60 segundos)
    _gracePeriodManager.startGeofenceGracePeriod();
  }

  /// 📝 INTENTAR REGISTRO AUTOMÁTICO DE ASISTENCIA
  Future<void> _attemptAutomaticAttendanceRegistration(Ubicacion location) async {
    if (_currentEvent == null) return;

    try {
      debugPrint('📝 Attempting automatic attendance registration');

      final user = await _storageService.getUser();
      if (user == null) {
        debugPrint('❌ No user found for attendance registration');
        return;
      }

      final result = await _asistenciaService.registrarAsistencia(
        eventoId: _currentEvent!.id!,
        usuarioId: user.id,
        latitud: location.latitud,
        longitud: location.longitud,
      );

      if (result.success) {
        debugPrint('✅ Automatic attendance registration successful');
        await _notificationManager.showAttendanceRegisteredNotification();
      } else {
        debugPrint('❌ Automatic attendance registration failed: ${result.error}');
      }

    } catch (e) {
      debugPrint('❌ Error in automatic attendance registration: $e');
    }
  }

  /// ⏰ MANEJAR EVENTOS DE GRACE PERIOD
  void _handleGracePeriodEvent(GracePeriodEvent event) {
    debugPrint('⏰ Grace period event: ${event.type} (${event.remaining}s remaining)');

    switch (event.type) {
      case GracePeriodEventType.geofenceExpired:
        _handleGeofenceGraceExpired();
        break;
      case GracePeriodEventType.appClosedExpired:
        _handleAppClosedGraceExpired();
        break;
      default:
        break;
    }
  }

  /// 🚨 MANEJAR EXPIRACIÓN DE GRACE PERIOD GEOFENCE
  void _handleGeofenceGraceExpired() {
    debugPrint('🚨 Geofence grace period expired - marking as boundary violation');
    
    // Marcar como violación de límites
    _emitTrackingState(StudentTrackingStatus.boundaryViolation);
  }

  /// 🚨 MANEJAR EXPIRACIÓN DE GRACE PERIOD APP CERRADA
  void _handleAppClosedGraceExpired() {
    debugPrint('🚨 App closed grace period expired - marking as absent');
    
    // Marcar como ausente por app cerrada
    _markAsAbsent('App cerrada por más de 30 segundos');
  }

  /// 📊 MANEJAR CAMBIOS DE ESTADO DE ASISTENCIA
  void _handleAttendanceStateChange(AttendanceStateChange change) {
    debugPrint('📊 Attendance state changed: ${change.fromState} -> ${change.toState}');
    
    // Emitir estado de tracking actualizado
    _emitTrackingState(_getTrackingStatusFromAttendanceState(change.toState));
  }

  /// 📱 MANEJAR APP REGRESANDO A FOREGROUND
  void _handleAppReturned() {
    debugPrint('📱 App returned to foreground');

    // Cancelar grace period de app cerrada si está activo
    if (_gracePeriodManager.isAppClosedGraceActive) {
      _gracePeriodManager.cancelAppClosedGracePeriod();
    }

    // Realizar actualización inmediata de ubicación
    _performLocationUpdate();
  }

  /// 📱 MANEJAR APP YENDO A BACKGROUND
  void _handleAppClosed() {
    debugPrint('📱 App went to background');

    // Iniciar grace period de app cerrada (30 segundos)
    _gracePeriodManager.startAppClosedGracePeriod();
  }

  /// ❌ MARCAR COMO AUSENTE
  Future<void> _markAsAbsent(String reason) async {
    if (_currentEvent == null) return;

    try {
      final user = await _storageService.getUser();
      if (user == null) return;

      await _asistenciaService.marcarAusente(
        usuarioId: user.id,
        eventoId: _currentEvent!.id!,
        motivo: reason,
      );

      debugPrint('❌ Marked as absent: $reason');

    } catch (e) {
      debugPrint('❌ Error marking as absent: $e');
    }
  }

  /// 🔄 ACTUALIZAR ESTADO DE APP LIFECYCLE
  void _updateAppLifecycleState() {
    // Actualizar heartbeat con estado actual de app
    _heartbeatManager.updateAppState(
      isInForeground: _isAppInForeground,
      isInGracePeriod: _gracePeriodManager.hasAnyGracePeriodActive,
    );
  }

  /// 📊 CONVERTIR ESTADO DE ASISTENCIA A ESTADO DE TRACKING
  StudentTrackingStatus _getTrackingStatusFromAttendanceState(EstadoAsistencia estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return StudentTrackingStatus.present;
      case EstadoAsistencia.ausente:
        return StudentTrackingStatus.absent;
      case EstadoAsistencia.pendiente:
        return StudentTrackingStatus.pending;
      case EstadoAsistencia.justificado:
        return StudentTrackingStatus.justified;
      case EstadoAsistencia.tarde:
        return StudentTrackingStatus.late;
      case EstadoAsistencia.inicial:
        return StudentTrackingStatus.active;
    }
  }

  /// 🔄 EMITIR ESTADO DE TRACKING
  void _emitTrackingState(StudentTrackingStatus status) {
    final state = StudentTrackingState(
      status: status,
      currentEvent: _currentEvent,
      isAppInForeground: _isAppInForeground,
      hasAnyGracePeriodActive: _gracePeriodManager.hasAnyGracePeriodActive,
      timestamp: DateTime.now(),
    );

    if (!_trackingController.isClosed) {
      _trackingController.add(state);
    }
  }

  /// 📊 OBTENER ESTADO ACTUAL
  StudentTrackingState getCurrentState() {
    return StudentTrackingState(
      status: _isTrackingActive ? StudentTrackingStatus.active : StudentTrackingStatus.stopped,
      currentEvent: _currentEvent,
      isAppInForeground: _isAppInForeground,
      hasAnyGracePeriodActive: _gracePeriodManager.hasAnyGracePeriodActive,
      timestamp: DateTime.now(),
    );
  }

  /// 🧹 CLEANUP
  void dispose() {
    debugPrint('🧹 Disposing StudentAttendanceManager');

    stopTracking();
    _trackingController.close();
    
    _heartbeatManager.dispose();
    _geofenceManager.dispose();
    _stateManager.dispose();
    _gracePeriodManager.dispose();
    
    debugPrint('🧹 StudentAttendanceManager disposed');
  }
}

/// ✅ ESTADO DE TRACKING DE ESTUDIANTE
class StudentTrackingState {
  final StudentTrackingStatus status;
  final Evento? currentEvent;
  final bool isAppInForeground;
  final bool hasAnyGracePeriodActive;
  final DateTime timestamp;

  const StudentTrackingState({
    required this.status,
    this.currentEvent,
    required this.isAppInForeground,
    required this.hasAnyGracePeriodActive,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'StudentTrackingState(status: $status, event: ${currentEvent?.titulo}, '
           'foreground: $isAppInForeground, gracePeriod: $hasAnyGracePeriodActive)';
  }
}

/// ✅ ESTADOS DE TRACKING
enum StudentTrackingStatus {
  stopped,          // Tracking detenido
  active,           // Tracking activo
  present,          // Presente en el evento
  absent,           // Ausente del evento
  pending,          // Pendiente (fuera pero en tiempo)
  late,             // Llegó tarde
  justified,        // Justificado
  boundaryViolation, // Violación de límites
}