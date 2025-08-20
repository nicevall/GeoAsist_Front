// lib/services/student_attendance_manager.dart
import 'dart:async';
import 'package:flutter/widgets.dart'; // Para AppLifecycleState
import '../models/attendance_state_model.dart';
import '../models/location_response_model.dart';
import '../models/attendance_policies_model.dart';
import '../models/evento_model.dart';
import 'location_service.dart';
import 'asistencia_service.dart'; // Para integración backend
import 'permission_service.dart'; // Para validaciones
import 'notifications/notification_manager.dart'; // ✅ UNIFIED: Solo NotificationManager
import 'teacher_notification_service.dart'; // ✅ NUEVO para notificaciones docente
import 'storage_service.dart';
import 'evento_service.dart'; // ✅ AGREGADO para eventos
import '../core/app_constants.dart';

class StudentAttendanceManager {
  static final StudentAttendanceManager _instance =
      StudentAttendanceManager._internal();
  factory StudentAttendanceManager() => _instance;
  StudentAttendanceManager._internal();
  
  // 🧪 Test-specific constructor to create fresh instances
  StudentAttendanceManager._testInstance() {
    _currentState = AttendanceState.initial();
    _lastLocationResponse = null;
    _currentPolicies = null;
    _trackingTimer = null;
    _gracePeriodTimer = null;
    _heartbeatTimer = null;
    _lifecycleTimer = null;
    _heartbeatFailureTimer = null;
    _isAppInForeground = true;
  }
  
  // 🧪 Public method to create test instances (bypasses singleton)
  static StudentAttendanceManager createTestInstance() {
    return StudentAttendanceManager._testInstance();
  }

  // 🎯 DEPENDENCIAS
  final LocationService _locationService = LocationService();
  // ✅ UNIFIED: Usar solo NotificationManager
  final NotificationManager _notificationManager = NotificationManager();
  final TeacherNotificationService _teacherNotificationService = TeacherNotificationService(); // ✅ NUEVO
  final StorageService _storageService = StorageService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final PermissionService _permissionService = PermissionService();

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
  Timer? _heartbeatFailureTimer; // ✅ FIXED: Track heartbeat failure timer to prevent memory leaks
  bool _isAppInForeground = true;

  // 🎯 NUEVOS MÉTODOS PARA GRACE PERIOD
  Future<void> _triggerGracePeriod() async {
    if (_currentState.isInGracePeriod) return;

    debugPrint('🚨 Grace period iniciado - 30 segundos');

    await _notificationManager.showAppClosedWarningNotification(30);

    _gracePeriodTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final remaining = 30 - timer.tick;

      _updateState(_currentState.copyWith(
        isInGracePeriod: true,
        gracePeriodRemaining: remaining,
      ));

      if (remaining <= 0) {
        timer.cancel();
        _triggerAttendanceLoss();
      }
    });
  }

  Future<void> _cancelGracePeriod() async {
    if (!_currentState.isInGracePeriod) return;

    debugPrint('✅ Grace period cancelado');

    _gracePeriodTimer?.cancel();
    await _notificationManager.clearAllNotifications();

    _updateState(_currentState.copyWith(
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
    ));
  }

  Future<void> _triggerAttendanceLoss() async {
    debugPrint('❌ Asistencia perdida por cierre de app');

    if (_currentState.currentEvent != null &&
        _currentState.currentUser != null) {
      await _asistenciaService.enviarHeartbeat(
        usuarioId: _currentState.currentUser!.id,
        eventoId: _currentState.currentEvent!.id!,
        isAppActive: false,
        isInGracePeriod: true,
        gracePeriodRemaining: 0,
      );
    }

    await stopTracking();
    await _notificationManager.clearAllNotifications();
  }

  // 🎯 GETTERS PÚBLICOS
  Stream<AttendanceState> get stateStream => _stateController.stream;
  Stream<LocationResponseModel> get locationStream =>
      _locationController.stream;
  AttendanceState get currentState => _currentState;
  LocationResponseModel? get lastLocationResponse => _lastLocationResponse;

  // 🎯 INICIALIZACIÓN DEL MANAGER
  /// ✅ MODIFICADO: Initialize con autoStart para tracking automático
  Future<void> initialize({
    String? userId,
    String? eventId,
    bool autoStart = true, // ✅ AGREGAR PARÁMETRO
  }) async {
    debugPrint('🎯 Inicializando StudentAttendanceManager (autoStart: $autoStart)');

    try {
      // 1. Inicializar notificaciones críticas
      await _notificationManager.initialize();

      // 2. Validar permisos estrictos
      final permissionsValid =
          await _permissionService.validateAllPermissionsForTracking();
      if (!permissionsValid) {
        throw Exception('Permisos críticos no otorgados');
      }

      // 3. Cargar usuario actual
      final user = await _storageService.getUser();
      if (user != null) {
        _updateState(_currentState.copyWith(currentUser: user));
      }

      // 4. ✅ NUEVO: Si autoStart=true y hay evento, activar tracking inmediatamente
      if (autoStart && eventId != null) {
        await _startTrackingForEvent(eventId, userId);
      }

      debugPrint('✅ StudentAttendanceManager inicializado (autoStart: $autoStart)');
    } catch (e) {
      debugPrint('❌ Error crítico inicializando: $e');
      await _notificationManager.showCriticalAppLifecycleWarning();
      rethrow;
    }
  }

  /// ✅ NUEVO: Método privado para iniciar tracking de evento específico
  Future<void> _startTrackingForEvent(String eventId, String? userId) async {
    try {
      debugPrint('🚀 Iniciando tracking automático para evento: $eventId');
      
      // Buscar el evento
      final eventoService = EventoService();
      final eventos = await eventoService.obtenerEventos();
      final evento = eventos.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Evento no encontrado: $eventId'),
      );
      
      // Iniciar tracking para este evento
      await startEventTracking(evento);
      
      debugPrint('✅ Tracking automático iniciado para: ${evento.titulo}');
    } catch (e) {
      debugPrint('❌ Error iniciando tracking automático: $e');
      // No rethrow para que no bloquee la inicialización
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
        // ✅ UNIFIED: Usar NotificationManager para evento activo
        await _notificationManager.showEventStartedNotification(
            evento.titulo); // Fixed: use titulo instead of nombre
        await _notificationManager.showTrackingActiveNotification();
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

    // 2. ✅ NUEVO: Notificar al docente que el estudiante salió del área
    await _notifyTeacherStudentLeftArea();

    // 3. ✅ NUEVO: Registrar evento en backend
    await registerGeofenceEvent(
      entering: false,
      latitude: response.latitude,
      longitude: response.longitude,
    );

    // 4. Iniciar período de gracia
    _startGracePeriod();
  }

  /// ✅ NUEVO: Notificar al docente que el estudiante salió del área
  Future<void> _notifyTeacherStudentLeftArea() async {
    try {
      if (_currentState.currentEvent == null || _currentState.currentUser == null) {
        debugPrint('⚠️ No hay evento o usuario para notificar al docente');
        return;
      }

      await _teacherNotificationService.notifyStudentLeftArea(
        studentName: _currentState.currentUser!.nombre,
        eventTitle: _currentState.currentEvent!.titulo,
        eventId: _currentState.currentEvent!.id!,
        timeOutside: null, // Se calculará en el backend o en tiempo real
      );

      debugPrint('📨 Docente notificado: estudiante ${_currentState.currentUser!.nombre} salió del área');
    } catch (e) {
      debugPrint('❌ Error notificando docente sobre estudiante que salió: $e');
    }
  }

  /// ✅ NUEVO: Notificar al docente que el estudiante se registró
  Future<void> _notifyTeacherStudentJoined() async {
    try {
      if (_currentState.currentEvent == null || _currentState.currentUser == null) {
        debugPrint('⚠️ No hay evento o usuario para notificar al docente');
        return;
      }

      // Estimar métricas actuales (en producción vendrían del backend)
      const int totalExpected = 30; // TODO: obtener del backend
      const int currentAttendance = 1; // TODO: obtener conteo real del backend

      await _teacherNotificationService.notifyStudentJoined(
        studentName: _currentState.currentUser!.nombre,
        eventTitle: _currentState.currentEvent!.titulo,
        eventId: _currentState.currentEvent!.id!,
        currentAttendance: currentAttendance,
        totalStudents: totalExpected,
      );

      debugPrint('📨 Docente notificado: estudiante ${_currentState.currentUser!.nombre} se registró');
    } catch (e) {
      debugPrint('❌ Error notificando docente sobre estudiante registrado: $e');
    }
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
    // ✅ UNIFIED: Usar NotificationManager para grace period
    _notificationManager.showGracePeriodStartedNotification(
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

  /// ✅ NUEVO DÍA 4: Continuar heartbeat en background (sin interrumpir)
  void _continueBackgroundHeartbeat() {
    debugPrint('💓 Continuando heartbeat en background');

    // El heartbeat sigue funcionando normalmente en background
    // No se interrumpe por estar en background
    if (_heartbeatTimer?.isActive == true) {
      debugPrint('✅ Heartbeat activo en background - sin cambios');
    }
  }

  // 🎯 MANEJAR EXPIRACIÓN DEL PERÍODO DE GRACIA
  Future<void> _handleGracePeriodExpired() async {
    debugPrint('❌ Período de gracia expirado');

    // 1. Mostrar notificación crítica - CORREGIDO (ya existe en NotificationService)
    // ✅ UNIFIED: Usar NotificationManager para grace period expirado
    await _notificationManager.showGracePeriodExpiredNotification();

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
    _heartbeatFailureTimer?.cancel(); // ✅ FIXED: Also cancel in stopTracking
    _heartbeatFailureTimer = null;

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

    // ✅ UNIFIED: Usar NotificationManager para tracking pausado
    await _notificationManager.showBreakStartedNotification();
  }

  // 🎯 REANUDAR TRACKING (DESPUÉS DEL RECESO)
  Future<void> resumeTracking() async {
    debugPrint('▶️ Reanudando tracking después del receso');

    _updateState(_currentState.copyWith(
      trackingStatus: TrackingStatus.active,
    ));

    _startTrackingTimer();

    // Mostrar notificación de reanudación - CORREGIDO
    // ✅ UNIFIED: Usar NotificationManager para tracking reanudado
    await _notificationManager.showBreakEndedNotification();
    await _notificationManager.showTrackingResumedNotification();

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
      // ✅ UNIFIED: Usar NotificationManager para asistencia registrada
      await _notificationManager.showAttendanceRegisteredNotification();

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

  // 🎯 CLEANUP Y DISPOSE - FIXED: Enhanced memory leak prevention
  Future<void> dispose() async {
    debugPrint('🧹 Limpiando StudentAttendanceManager con recursos críticos');

    // 1. Detener tracking activo (ya cancela la mayoría de timers)
    await stopTracking();

    // 2. FIXED: Ensure ALL timers are cancelled (double-check)
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lifecycleTimer?.cancel();
    _lifecycleTimer = null;
    _heartbeatFailureTimer?.cancel(); // ✅ FIXED: Cancel failure timer
    _heartbeatFailureTimer = null;

    // 3. FIXED: Close streams safely with error handling
    try {
      if (!_stateController.isClosed) {
        await _stateController.close();
      }
    } catch (e) {
      debugPrint('⚠️ Error closing state controller: $e');
    }

    try {
      if (!_locationController.isClosed) {
        await _locationController.close();
      }
    } catch (e) {
      debugPrint('⚠️ Error closing location controller: $e');
    }

    // 4. FIXED: Location service cleanup (no subscriptions to stop, but ensure no pending operations)
    // Note: LocationService doesn't have persistent subscriptions to stop
    debugPrint('✅ Location service cleanup completed');

    // 5. FIXED: Clean up notification service
    try {
      await _notificationManager.clearAllNotifications();
    } catch (e) {
      debugPrint('⚠️ Error clearing notifications: $e');
    }

    // 6. FIXED: Reset state to prevent accidental reuse
    _currentState = AttendanceState.initial();

    debugPrint('✅ StudentAttendanceManager disposed completamente - No memory leaks');
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
        
        // ✅ NUEVO: Notificar al docente que el estudiante se registró
        await _notifyTeacherStudentJoined();

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

        if (_currentState.isInGracePeriod) {
          _cancelGracePeriod();
        }
        break;

      case AppLifecycleState.paused:
        _isAppInForeground = false;
        debugPrint('📱 App en background - tracking continúa normalmente');
        // ✅ CORREGIDO: NO iniciar grace period para 'paused' - solo background tracking normal
        _updateBackgroundTrackingStatus();
        break;

      case AppLifecycleState.detached:
        debugPrint('🚨 App CERRADA COMPLETAMENTE - Iniciando grace period 30s');
        _isAppInForeground = false;
        _triggerGracePeriod();
        break;

      case AppLifecycleState.inactive:
        debugPrint('⏸️ App inactiva temporalmente - sin cambios');
        break;

      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        debugPrint('🙈 App hidden - background tracking normal');
        // ✅ CORREGIDO: NO grace period para hidden - solo background tracking
        _updateBackgroundTrackingStatus();
        break;
    }
  }

  /// ✅ NUEVO DÍA 4: Actualizar estado de background tracking (sin penalización)
  void _updateBackgroundTrackingStatus() {
    if (_currentState.trackingStatus != TrackingStatus.active) return;

    debugPrint('📱 Actualizando a background tracking - SIN penalización');

    // Mostrar notificación informativa (no warning)
    _notificationManager.showBackgroundTrackingNotification();

    // Actualizar estado interno sin grace period
    _updateState(_currentState.copyWith(
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
    ));

    // Continuar heartbeat en background
    _continueBackgroundHeartbeat();
  }

  /// ✅ MODIFICADO DÍA 4: Heartbeat crítico mejorado
  Future<void> sendHeartbeatToBackend() async {
    if (_currentState.currentEvent == null ||
        _currentState.currentUser == null ||
        _currentState.trackingStatus != TrackingStatus.active) {
      return;
    }

    try {
      debugPrint('💓 Enviando heartbeat crítico al backend');

      final response = await _asistenciaService.enviarHeartbeat(
        usuarioId: _currentState.currentUser!.id,
        eventoId: _currentState.currentEvent!.id!,
        isAppActive: _isAppInForeground,
        isInGracePeriod: _currentState.isInGracePeriod,
        gracePeriodRemaining: _currentState.gracePeriodRemaining,
      );

      if (response.success) {
        // Procesar comandos del backend si los hay
        if (response.data != null && response.data!.containsKey('command')) {
          await _processBackendCommand(response.data!['command']);
        }

        debugPrint('✅ Heartbeat enviado exitosamente');
      } else {
        debugPrint('⚠️ Heartbeat falló - intentando reconectar');
        _handleHeartbeatFailure();
      }
    } catch (e) {
      debugPrint('❌ Error enviando heartbeat: $e');
      _handleHeartbeatFailure();
    }
  }

  Future<void> _processBackendCommand(String command) async {
    debugPrint('📡 Procesando comando del backend: $command');

    switch (command) {
      case 'force_attendance_loss':
        await _triggerAutomaticAttendanceLoss('Comando del backend');
        break;
      case 'extend_grace_period':
        if (_currentState.isInGracePeriod) {
          // Extender grace period por 15 segundos adicionales
          _updateState(_currentState.copyWith(
            gracePeriodRemaining: _currentState.gracePeriodRemaining + 15,
          ));
        }
        break;
      case 'start_break':
        await pauseTracking();
        break;
      case 'end_break':
        await resumeTracking();
        break;
      default:
        debugPrint('⚠️ Comando desconocido: $command');
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

  /// Manejar falla crítica de heartbeat - FIXED: No memory leaks
  void _handleHeartbeatFailure() {
    debugPrint('🚨 Falla crítica de heartbeat detectada');

    _notificationManager.showAppClosedWarningNotification(30);

    // ✅ FIXED: Cancel existing failure timer before creating new one
    _heartbeatFailureTimer?.cancel();
    
    _heartbeatFailureTimer = Timer(const Duration(minutes: 2), () {
      if (_currentState.trackingStatus == TrackingStatus.active) {
        _triggerAutomaticAttendanceLoss('Pérdida de conectividad crítica');
      }
      _heartbeatFailureTimer = null; // Clear reference after completion
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
