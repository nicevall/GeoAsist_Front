// lib/services/student_attendance_manager.dart
import 'dart:async';
import 'package:flutter/widgets.dart'; // Para AppLifecycleState
import '../models/attendance_state_model.dart';
import '../models/location_response_model.dart';
import '../models/attendance_policies_model.dart';
import '../models/evento_model.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'asistencia_service.dart'; // Para integración backend
import 'permission_service.dart'; // Para validaciones
import 'notifications/notification_manager.dart'; // Para notificaciones nuevas
import 'storage_service.dart';
import '../core/app_constants.dart';

class StudentAttendanceManager {
  static final StudentAttendanceManager _instance =
      StudentAttendanceManager._internal();
  factory StudentAttendanceManager() => _instance;
  StudentAttendanceManager._internal();

  // 🎯 DEPENDENCIAS
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final PermissionService _permissionService = PermissionService();
  final NotificationManager _notificationManager = NotificationManager();

  // 🎯 STREAMS Y CONTROLADORES - Una sola fuente de verdad
  final StreamController<AttendanceState> _stateController =
      StreamController<AttendanceState>.broadcast();
  final StreamController<LocationResponseModel> _locationController =
      StreamController<LocationResponseModel>.broadcast();

  // 🎯 ESTADO ACTUAL
  AttendanceState _currentState = AttendanceState.initial();
  LocationResponseModel? _lastLocationResponse;
  AttendancePolicies? _currentPolicies;
  Timer? _trackingTimer;
  Timer? _gracePeriodTimer;
  Timer? _heartbeatTimer;
  Timer? _lifecycleTimer;
  bool _isAppInForeground = true;
  final int _gracePeriodSeconds = 30;

  // 🎯 GETTERS PÚBLICOS
  Stream<AttendanceState> get stateStream => _stateController.stream;
  Stream<LocationResponseModel> get locationStream =>
      _locationController.stream;
  AttendanceState get currentState => _currentState;
  LocationResponseModel? get lastLocationResponse => _lastLocationResponse;

  // 🎯 INICIALIZACIÓN DEL MANAGER
  Future<void> initialize() async {
    debugPrint('🎯 Inicializando StudentAttendanceManager con restricciones');

    try {
      // 1. Inicializar notificaciones críticas
      await _notificationManager.initialize();

      // 2. Validar permisos estrictos
      final permissionsValid =
          await _permissionService.validateAllPermissionsForTracking();
      if (!permissionsValid) {
        throw Exception('Permisos críticos no otorgados');
      }

      // 3. Inicializar servicios dependientes
      await _notificationService.initialize();

      // 4. Cargar usuario actual
      final user = await _storageService.getUser();
      if (user != null) {
        _updateState(_currentState.copyWith(currentUser: user));
      }

      debugPrint('✅ StudentAttendanceManager inicializado con restricciones');
    } catch (e) {
      debugPrint('❌ Error crítico inicializando: $e');
      await _notificationManager.showCriticalAppLifecycleWarning();
      rethrow;
    }
  }

  // 🎯 INICIAR TRACKING PARA UN EVENTO ESPECÍFICO
  Future<void> startEventTracking(Evento evento) async {
    debugPrint('🎯 Iniciando tracking para evento: ${evento.titulo}');

    try {
      // 1. Cargar políticas del evento
      _currentPolicies = AttendancePolicies.fromEvento(evento);

      // 2. Actualizar estado inicial
      _updateState(_currentState.copyWith(
        currentEvent: evento,
        policies: _currentPolicies,
        trackingStatus: TrackingStatus.active,
        gracePeriodRemaining: _currentPolicies!.gracePeriodMinutes * 60,
        trackingStartTime: DateTime.now(),
      ));

      // 3. Mostrar notificación persistente del evento - CON VALIDACIÓN
      if (evento.id != null && evento.id!.isNotEmpty) {
        await _notificationService.showEventActiveNotification(
          eventName: evento.titulo,
          eventId: evento.id!,
        );
      } else {
        debugPrint(
            '⚠️ Evento sin ID válido - omitiendo notificación específica');
        // Podrías mostrar una notificación genérica o manejar el error
      }

      // 4. Iniciar timer de tracking (30 segundos para precisión optimizada)
      _startTrackingTimer();

      // 5. ✅ NUEVO: Iniciar heartbeat obligatorio
      _startHeartbeatTimer();

      // 6. ✅ NUEVO: Iniciar monitoreo de lifecycle
      _startLifecycleMonitoring();

      // 7. Realizar primera actualización inmediata
      await _performLocationUpdate();

      debugPrint('✅ Tracking iniciado exitosamente');
    } catch (e) {
      debugPrint('❌ Error iniciando tracking: $e');
      _updateState(_currentState.copyWith(
        trackingStatus: TrackingStatus.error,
        lastError: 'Error iniciando tracking: $e',
      ));
    }
  }

  // 🎯 TIMER PRINCIPAL DE TRACKING
  void _startTrackingTimer() {
    _trackingTimer?.cancel();

    _trackingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.trackingIntervalSeconds),
      (_) => _performLocationUpdate(),
    );

    debugPrint(
        '🕒 Timer de tracking iniciado (${AppConstants.trackingIntervalSeconds}s)');
  }

  // 🎯 ACTUALIZACIÓN PRINCIPAL DE UBICACIÓN
  Future<void> _performLocationUpdate() async {
    if (_currentState.currentEvent == null ||
        _currentState.currentUser == null) {
      debugPrint('⚠️ No hay evento o usuario activo para tracking');
      return;
    }

    try {
      // 1. Obtener ubicación actual del usuario
      final userPosition = await _locationService.getCurrentPosition();
      if (userPosition == null) {
        debugPrint('⚠️ No se pudo obtener ubicación del usuario');
        return;
      }

      // 2. Enviar ubicación al backend y obtener respuesta completa
      final locationResponse =
          await _locationService.updateUserLocationComplete(
        userId: _currentState.currentUser?.id ?? '',
        latitude: userPosition.latitude,
        longitude: userPosition.longitude,
        eventoId: _currentState.currentEvent?.id ?? '',
      );

      if (locationResponse != null) {
        _lastLocationResponse = locationResponse;
        _locationController.add(locationResponse);

        // 3. Procesar respuesta del backend y actualizar estados
        await _processLocationResponse(locationResponse);
      }
    } catch (e) {
      debugPrint('❌ Error en actualización de ubicación: $e');
      _updateState(_currentState.copyWith(
        lastError: 'Error actualizando ubicación: $e',
      ));
    }
  }

  // 🎯 PROCESAR RESPUESTA COMPLETA DEL BACKEND
  Future<void> _processLocationResponse(LocationResponseModel response) async {
    debugPrint('📍 Procesando respuesta del backend:');
    debugPrint('   - insideGeofence: ${response.insideGeofence}');
    debugPrint('   - distance: ${response.distance}m');
    debugPrint('   - eventActive: ${response.eventActive}');
    debugPrint('   - eventStarted: ${response.eventStarted}');

    // 1. Verificar si el evento sigue activo
    if (!response.eventActive) {
      await _handleEventEnded();
      return;
    }

    // 2. Determinar nuevo estado basado en la respuesta del backend
    final bool wasInside = _currentState.isInsideGeofence;
    final bool nowInside = response.insideGeofence;

    // 3. Detectar cambios de estado (entrada/salida del geofence)
    if (wasInside != nowInside) {
      if (nowInside) {
        await _handleEnteredGeofence(response);
      } else {
        await _handleExitedGeofence(response);
      }
    }

    // 4. Actualizar estado principal
    _updateState(_currentState.copyWith(
      isInsideGeofence: response.insideGeofence,
      distanceToEvent: response.distance,
      canRegisterAttendance: response.eventStarted && response.insideGeofence,
      lastLocationUpdate: DateTime.now(),
      userLatitude: response.latitude,
      userLongitude: response.longitude,
    ));
  }

  // 🎯 MANEJAR ENTRADA AL GEOFENCE
  Future<void> _handleEnteredGeofence(LocationResponseModel response) async {
    debugPrint('✅ Usuario entró al geofence del evento');

    // 1. Cancelar período de gracia si estaba activo
    _cancelGracePeriod();

    // 2. ✅ NUEVO: Mostrar notificación de entrada
    await _notificationManager.showGeofenceEnteredNotification(
        _currentState.currentEvent?.titulo ?? 'Evento');

    // 3. ✅ NUEVO: Registrar evento en backend
    await registerGeofenceEvent(
      entering: true,
      latitude: response.latitude,
      longitude: response.longitude,
    );

    // 4. Actualizar estado
    _updateState(_currentState.copyWith(
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
    ));
  }

  // 🎯 MANEJAR SALIDA DEL GEOFENCE
  Future<void> _handleExitedGeofence(LocationResponseModel response) async {
    debugPrint('⚠️ Usuario salió del geofence del evento');

    // 1. ✅ NUEVO: Mostrar notificación inmediata de salida
    await _notificationManager.showGeofenceExitedNotification(
        _currentState.currentEvent?.titulo ?? 'Evento');

    // 2. ✅ NUEVO: Registrar evento en backend
    await registerGeofenceEvent(
      entering: false,
      latitude: response.latitude,
      longitude: response.longitude,
    );

    // 3. Iniciar período de gracia
    _startGracePeriod();
  }

  // 🎯 INICIAR PERÍODO DE GRACIA
  void _startGracePeriod() {
    if (_currentPolicies == null) return;

    final gracePeriodSeconds = _currentPolicies!.gracePeriodMinutes * 60;

    _updateState(_currentState.copyWith(
      isInGracePeriod: true,
      gracePeriodRemaining: gracePeriodSeconds,
    ));

    // Mostrar notificación de inicio de período de gracia
    _notificationService.showGracePeriodStartedNotification(
      remainingSeconds: gracePeriodSeconds,
    );

    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final remaining = _currentState.gracePeriodRemaining - 1;

        if (remaining <= 0) {
          _handleGracePeriodExpired();
          timer.cancel();
        } else {
          _updateState(_currentState.copyWith(
            gracePeriodRemaining: remaining,
          ));
        }
      },
    );

    debugPrint('⏰ Período de gracia iniciado: ${gracePeriodSeconds}s');
  }

  // 🎯 CANCELAR PERÍODO DE GRACIA
  void _cancelGracePeriod() {
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;

    debugPrint('✅ Período de gracia cancelado');
  }

  // 🎯 MANEJAR EXPIRACIÓN DEL PERÍODO DE GRACIA
  Future<void> _handleGracePeriodExpired() async {
    debugPrint('❌ Período de gracia expirado');

    // 1. Mostrar notificación crítica - CORREGIDO (ya existe en NotificationService)
    await _notificationService.showGracePeriodExpiredNotification();

    // 2. Actualizar estado
    _updateState(_currentState.copyWith(
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
      hasViolatedBoundary: true,
    ));
  }

  // 🎯 MANEJAR FIN DEL EVENTO
  Future<void> _handleEventEnded() async {
    debugPrint('🏁 Evento terminado');

    // 1. Detener tracking
    await stopTracking();

    // 2. Actualizar estado final
    _updateState(_currentState.copyWith(
      trackingStatus: TrackingStatus.completed,
      currentEvent: null,
    ));
  }

  // 🎯 DETENER TRACKING
  Future<void> stopTracking() async {
    debugPrint('🛑 Deteniendo tracking con limpieza completa');

    // 1. Cancelar todos los timers críticos
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lifecycleTimer?.cancel();
    _lifecycleTimer = null;

    // 2. Limpiar notificaciones
    await _notificationManager.clearAllNotifications();

    // 3. Actualizar estado
    _updateState(_currentState.copyWith(
      trackingStatus: TrackingStatus.stopped,
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
    ));

    debugPrint('✅ Tracking detenido con limpieza completa');
  }

  // 🎯 PAUSAR TRACKING (DURANTE RECESOS)
  Future<void> pauseTracking() async {
    debugPrint('⏸️ Pausando tracking para receso');

    _trackingTimer?.cancel();
    _gracePeriodTimer?.cancel();

    _updateState(_currentState.copyWith(
      trackingStatus: TrackingStatus.paused,
      isInGracePeriod: false,
    ));

    await _notificationService.showTrackingPausedNotification();
  }

  // 🎯 REANUDAR TRACKING (DESPUÉS DEL RECESO)
  Future<void> resumeTracking() async {
    debugPrint('▶️ Reanudando tracking después del receso');

    _updateState(_currentState.copyWith(
      trackingStatus: TrackingStatus.active,
    ));

    _startTrackingTimer();

    // Mostrar notificación de reanudación - CORREGIDO
    await _notificationService.showTrackingResumedNotification();

    // Realizar actualización inmediata
    await _performLocationUpdate();
  }

  // 🎯 REGISTRAR ASISTENCIA MANUALMENTE
  Future<bool> registerAttendance() async {
    if (!_currentState.canAttemptAttendanceRegistration) {
      debugPrint('⚠️ No se puede registrar asistencia en este momento');
      return false;
    }

    try {
      debugPrint(
          '📝 Registrando asistencia para evento: ${_currentState.currentEvent?.titulo}');

      // Aquí iría la lógica para registrar en el backend
      // FUTURO: Integrar con AsistenciaService para persistencia

      // Mostrar notificación de confirmación
      await _notificationService.showAttendanceRegisteredNotification(
        eventName: _currentState.currentEvent?.titulo ?? 'Evento',
      );

      // Actualizar estado
      _updateState(_currentState.copyWith(
        hasRegisteredAttendance: true,
        attendanceRegisteredTime: DateTime.now(),
      ));

      debugPrint('✅ Asistencia registrada exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error registrando asistencia: $e');
      _updateState(_currentState.copyWith(
        lastError: 'Error registrando asistencia: $e',
      ));
      return false;
    }
  }

  // 🎯 OBTENER RESUMEN DEL ESTADO ACTUAL
  Map<String, dynamic> getCurrentStateInfo() {
    return {
      'event': _currentState.currentEvent?.titulo ?? 'Sin evento',
      'tracking': _currentState.trackingStatus.toString(),
      'insideGeofence': _currentState.isInsideGeofence,
      'distance': '${_currentState.distanceToEvent.toStringAsFixed(1)}m',
      'canRegister': _currentState.canRegisterAttendance,
      'hasRegistered': _currentState.hasRegisteredAttendance,
      'gracePeriod': _currentState.isInGracePeriod,
      'gracePeriodRemaining': _currentState.gracePeriodRemaining,
      'lastUpdate': _currentState.lastLocationUpdate?.toString() ?? 'Nunca',
    };
  }

  // 🎯 ACTUALIZAR ESTADO INTERNO Y NOTIFICAR LISTENERS
  void _updateState(AttendanceState newState) {
    _currentState = newState;
    _stateController.add(_currentState);

    // Log del estado para debugging
    if (AppConstants.enableDetailedLogging) {
      debugPrint('🎯 Estado actualizado: ${_currentState.statusText}');
    }
  }

  // 🎯 CLEANUP Y DISPOSE
  Future<void> dispose() async {
    debugPrint('🧹 Limpiando StudentAttendanceManager con recursos críticos');

    // Detener tracking activo
    await stopTracking();

    // Cerrar streams
    await _stateController.close();
    await _locationController.close();

    // Limpiar timers críticos
    _heartbeatTimer?.cancel();
    _lifecycleTimer?.cancel();

    // Limpiar servicios
    await _notificationManager.clearAllNotifications();

    debugPrint('✅ StudentAttendanceManager disposed completamente');
  }

  // 🎯 ========== MÉTODOS CRÍTICOS DÍA 2 ==========

  /// Registro de asistencia con backend real
  Future<bool> registerAttendanceWithBackend() async {
    if (!_currentState.canAttemptAttendanceRegistration) {
      debugPrint('⚠️ No se puede registrar asistencia en este momento');
      return false;
    }

    try {
      debugPrint('📝 Registrando asistencia en backend real');

      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _currentState.currentEvent!.id!,
        usuarioId: _currentState.currentUser!.id,
        latitud: _lastLocationResponse?.latitude ?? 0.0,
        longitud: _lastLocationResponse?.longitude ?? 0.0,
        estado: 'presente',
      );

      if (response.success) {
        await _notificationManager.showAttendanceRegisteredNotification();

        _updateState(_currentState.copyWith(
          hasRegisteredAttendance: true,
          attendanceRegisteredTime: DateTime.now(),
        ));

        debugPrint('✅ Asistencia registrada en backend exitosamente');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error registrando asistencia en backend: $e');
      return false;
    }
  }

  /// Validar permisos antes de iniciar tracking
  Future<bool> validatePermissionsBeforeTracking() async {
    try {
      debugPrint('🔍 Validando permisos antes de iniciar tracking');

      final permissionsValid =
          await _permissionService.validateAllPermissionsForTracking();

      if (!permissionsValid) {
        debugPrint('❌ Permisos insuficientes para tracking');
        await _notificationManager.showCriticalAppLifecycleWarning();
        return false;
      }

      debugPrint('✅ Todos los permisos validados correctamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error validando permisos: $e');
      return false;
    }
  }

  /// Manejo mejorado de app lifecycle con restricciones
  void handleAppLifecycleChange(AppLifecycleState state) {
    debugPrint('📱 App lifecycle cambió a: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        debugPrint('✅ App en foreground - tracking normal');
        break;

      case AppLifecycleState.paused:
        _isAppInForeground = false;
        debugPrint('⚠️ App pausada - iniciando grace period');
        _startAppClosedGracePeriod();
        break;

      case AppLifecycleState.detached:
        debugPrint('🚨 App DESCONECTADA - PÉRDIDA AUTOMÁTICA DE ASISTENCIA');
        _triggerAutomaticAttendanceLoss('Aplicación cerrada/eliminada');
        break;

      case AppLifecycleState.inactive:
        debugPrint('⏸️ App inactiva temporalmente');
        break;

      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        debugPrint('🙈 App hidden - modo background');
        break;
    }
  }

  /// Heartbeat crítico al backend
  Future<void> sendHeartbeatToBackend() async {
    if (_currentState.currentEvent == null ||
        _currentState.currentUser == null) {
      return;
    }

    try {
      final response = await _asistenciaService.enviarHeartbeat(
        usuarioId: _currentState.currentUser!.id,
        eventoId: _currentState.currentEvent!.id!,
      );

      if (!response.success) {
        debugPrint('⚠️ Heartbeat falló: ${response.error}');
        _handleHeartbeatFailure();
      } else {
        debugPrint('💓 Heartbeat enviado exitosamente');
      }
    } catch (e) {
      debugPrint('❌ Error en heartbeat crítico: $e');
      _handleHeartbeatFailure();
    }
  }

  /// Registro de eventos de geofence
  Future<void> registerGeofenceEvent({
    required bool entering,
    required double latitude,
    required double longitude,
  }) async {
    if (_currentState.currentEvent == null ||
        _currentState.currentUser == null) {
      return;
    }

    try {
      await _asistenciaService.registrarEventoGeofence(
        usuarioId: _currentState.currentUser!.id,
        eventoId: _currentState.currentEvent!.id!,
        entrando: entering,
        latitud: latitude,
        longitud: longitude,
      );

      debugPrint(
          '📍 Evento geofence registrado: ${entering ? "entrada" : "salida"}');
    } catch (e) {
      debugPrint('❌ Error registrando evento geofence: $e');
    }
  }

  // 🎯 MÉTODOS PRIVADOS CRÍTICOS

  /// Heartbeat obligatorio cada 30 segundos
  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (_currentState.trackingStatus == TrackingStatus.active) {
          await sendHeartbeatToBackend();
        }
      },
    );

    debugPrint('💓 Heartbeat iniciado cada 30 segundos');
  }

  /// Manejar falla crítica de heartbeat
  void _handleHeartbeatFailure() {
    debugPrint('🚨 Falla crítica de heartbeat detectada');

    _notificationManager.showAppClosedWarningNotification(30);

    Timer(const Duration(minutes: 2), () {
      if (_currentState.trackingStatus == TrackingStatus.active) {
        _triggerAutomaticAttendanceLoss('Pérdida de conectividad crítica');
      }
    });
  }

  /// Monitoreo de lifecycle de app
  void _startLifecycleMonitoring() {
    _lifecycleTimer?.cancel();

    _lifecycleTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (!_isAppInForeground &&
            _currentState.trackingStatus == TrackingStatus.active) {
          _handleAppInBackground();
        }
      },
    );

    debugPrint('📱 Monitoreo de lifecycle iniciado');
  }

  /// Grace period crítico por cierre de app
  void _startAppClosedGracePeriod() {
    debugPrint('⏰ Iniciando grace period crítico de 30 segundos');

    _notificationManager.showAppClosedWarningNotification(_gracePeriodSeconds);

    Timer(Duration(seconds: _gracePeriodSeconds), () {
      if (!_isAppInForeground &&
          _currentState.trackingStatus == TrackingStatus.active) {
        _triggerAutomaticAttendanceLoss('App cerrada por más de 30 segundos');
      }
    });
  }

  /// Manejar app en background
  void _handleAppInBackground() {
    if (_currentState.trackingStatus != TrackingStatus.active) return;

    debugPrint('📱 App en background durante tracking activo');
    _notificationManager.showCriticalAppLifecycleWarning();
  }

  /// Pérdida automática de asistencia
  Future<void> _triggerAutomaticAttendanceLoss(String reason) async {
    debugPrint('🚨 PÉRDIDA AUTOMÁTICA DE ASISTENCIA: $reason');

    if (_currentState.currentEvent == null ||
        _currentState.currentUser == null) {
      return;
    }

    try {
      await _asistenciaService.marcarAusentePorCierreApp(
        usuarioId: _currentState.currentUser!.id,
        eventoId: _currentState.currentEvent!.id!,
      );

      await stopTracking();
      await _notificationManager.clearAllNotifications();

      _updateState(_currentState.copyWith(
        trackingStatus: TrackingStatus.completed,
        lastError: reason,
      ));

      debugPrint('✅ Pérdida de asistencia procesada');
    } catch (e) {
      debugPrint('❌ Error procesando pérdida de asistencia: $e');
    }
  }
}
