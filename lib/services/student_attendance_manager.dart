import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/student_attendance_manager.dart
import 'dart:async';
import 'package:flutter/widgets.dart'; // Para AppLifecycleState
import '../models/attendance_state_model.dart';
import '../models/location_response_model.dart';
import '../models/attendance_policies_model.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart'; // ✅ AGREGADO: Import faltante para Usuario
import 'location_service.dart';
import 'background_location_service.dart'; // ✅ NUEVO: Para tracking continuo
import 'asistencia_service.dart'; // Para integración backend
import 'permission_service.dart'; // Para validaciones
import 'notifications/notification_manager.dart'; // ✅ UNIFIED: Solo NotificationManager
import 'teacher_notification_service.dart'; // ✅ NUEVO para notificaciones profesor
import 'storage_service.dart';
import 'evento_service.dart'; // ✅ AGREGADO para eventos
import 'websocket_service.dart'; // ✅ NUEVO para WebSocket robusto
import 'session_persistence_service.dart'; // ✅ NUEVO para persistencia de sesiones
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
  // ✅ INICIALIZACIÓN SEGURA DE BACKGROUND SERVICE
  BackgroundLocationService? _backgroundService;
  // ✅ UNIFIED: Usar solo NotificationManager
  final NotificationManager _notificationManager = NotificationManager();
  final TeacherNotificationService _teacherNotificationService = TeacherNotificationService(); // ✅ NUEVO
  final StorageService _storageService = StorageService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final PermissionService _permissionService = PermissionService();
  // ✅ NUEVO: Servicio de persistencia de sesiones
  final SessionPersistenceService _sessionPersistence = SessionPersistenceService();
  bool _isServicesInitialized = false;

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
  
  // ✅ NUEVO: WebSocket integration
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  // 🎯 NUEVOS MÉTODOS PARA GRACE PERIOD
  Future<void> _triggerGracePeriod() async {
    if (_currentState.isInGracePeriod) return;

    logger.d('🚨 Grace period iniciado - 30 segundos');

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

    logger.d('✅ Grace period cancelado');

    _gracePeriodTimer?.cancel();
    await _notificationManager.clearAllNotifications();

    _updateState(_currentState.copyWith(
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
    ));
  }

  Future<void> _triggerAttendanceLoss() async {
    logger.d('❌ Asistencia perdida por cierre de app');

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
    logger.d('🎯 Inicializando StudentAttendanceManager (autoStart: $autoStart)');

    try {
      logger.d('🚀 Inicializando servicios de asistencia...');
      
      // 1. Inicializar servicios críticos con error handling
      await _notificationManager.initialize();
      
      // ✅ NUEVO: Inicializar servicio de persistencia de sesiones
      await _sessionPersistence.initialize();

      // 2. ✅ INICIALIZACIÓN SEGURA DE BACKGROUND SERVICE
      try {
        _backgroundService = await BackgroundLocationService.getInstance();
        logger.d('✅ BackgroundService inicializado');
      } catch (e) {
        logger.d('⚠️ BackgroundService no disponible: $e');
        // Continuar sin background service (modo degradado)
        _backgroundService = null;
      }

      // 3. Validar permisos estrictos
      final permissionsValid =
          await _permissionService.validateAllPermissionsForTracking();
      if (!permissionsValid) {
        throw Exception('Permisos críticos no otorgados');
      }

      // 4. Cargar usuario actual
      final user = await _storageService.getUser();
      if (user != null) {
        _updateState(_currentState.copyWith(currentUser: user));
      }

      // 5. ✅ NUEVO: Verificar si hay una sesión activa para recuperar
      await _checkAndRecoverActiveSession();

      // 6. ✅ NUEVO: Si autoStart=true y hay evento, activar tracking inmediatamente
      if (autoStart && eventId != null) {
        await _startTrackingForEvent(eventId, userId);
      }

      _isServicesInitialized = true;
      logger.d('✅ Servicios de asistencia inicializados (autoStart: $autoStart)');
    } catch (e) {
      logger.d('❌ Error crítico inicializando servicios: $e');
      _isServicesInitialized = false;
      await _notificationManager.showCriticalAppLifecycleWarning();
      rethrow;
    }
  }

  /// ✅ NUEVO: Método privado para iniciar tracking de evento específico
  Future<void> _startTrackingForEvent(String eventId, String? userId) async {
    try {
      logger.d('🚀 Iniciando tracking automático para evento: $eventId');
      
      // Buscar el evento
      final eventoService = EventoService();
      final eventos = await eventoService.obtenerEventos();
      final evento = eventos.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Evento no encontrado: $eventId'),
      );
      
      // Iniciar tracking para este evento
      await startEventTracking(evento);
      
      logger.d('✅ Tracking automático iniciado para: ${evento.titulo}');
    } catch (e) {
      logger.d('❌ Error iniciando tracking automático: $e');
      // No rethrow para que no bloquee la inicialización
    }
  }

  // 🎯 INICIAR TRACKING PARA UN EVENTO ESPECÍFICO
  Future<void> startEventTracking(Evento evento) async {
    logger.d('🎯 Iniciando tracking para evento: ${evento.titulo}');

    try {
      // 1. Cargar políticas del evento
      _currentPolicies = AttendancePolicies.fromEvento(evento);

      // 2. ✅ CRÍTICO: Cargar usuario actual desde storage
      final currentUser = await _storageService.getUser();
      if (currentUser == null) {
        throw Exception('No hay usuario logueado para iniciar tracking');
      }
      logger.d('✅ Usuario cargado para tracking: ${currentUser.correo}');

      // 3. Actualizar estado inicial con evento Y usuario
      _updateState(_currentState.copyWith(
        currentEvent: evento,
        currentUser: currentUser, // ✅ CRÍTICO: Asignar usuario al estado
        policies: _currentPolicies,
        trackingStatus: TrackingStatus.active,
        gracePeriodRemaining: _currentPolicies!.gracePeriodMinutes * 60,
        trackingStartTime: DateTime.now(),
      ));

      // ✅ NUEVO: Guardar sesión activa para persistencia
      await _saveActiveSession(evento, currentUser);

      // 3. Mostrar notificación persistente del evento - CON VALIDACIÓN
      if (evento.id != null && evento.id!.isNotEmpty) {
        // ✅ UNIFIED: Usar NotificationManager para evento activo
        await _notificationManager.showEventStartedNotification(
            evento.titulo); // Fixed: use titulo instead of nombre
        await _notificationManager.showTrackingActiveNotification();
      } else {
        logger.d(
            '⚠️ Evento sin ID válido - omitiendo notificación específica');
        // Podrías mostrar una notificación genérica o manejar el error
      }

      // 4. ✅ NUEVO: Inicializar conexión WebSocket
      await _initializeWebSocketForEvent(evento.id!);

      // 5. Iniciar timer de tracking (30 segundos para precisión optimizada)
      _startTrackingTimer();

      // 6. ✅ NUEVO: Iniciar heartbeat obligatorio
      _startHeartbeatTimer();

      // 6. ✅ NUEVO: Iniciar monitoreo de lifecycle
      _startLifecycleMonitoring();

      // 7. Realizar primera actualización inmediata
      await _performLocationUpdate();

      logger.d('✅ Tracking iniciado exitosamente');
    } catch (e) {
      logger.d('❌ Error iniciando tracking: $e');
      _updateState(_currentState.copyWith(
        trackingStatus: TrackingStatus.error,
        lastError: 'Error iniciando tracking: $e',
      ));
    }
  }

  /// ✅ NUEVO: Método público para iniciar tracking con background support
  Future<bool> startAttendanceTracking({
    required String eventoId,
    bool enableBackgroundTracking = true,
  }) async {
    if (!_isServicesInitialized) {
      logger.d('❌ Servicios no inicializados');
      return false;
    }
    
    try {
      // Start foreground tracking
      _startTrackingTimer();
      
      // Start background tracking if available and enabled
      if (enableBackgroundTracking && _backgroundService != null) {
        final bgSuccess = await _backgroundService!.startContinuousTracking(
          userId: _currentState.currentUser?.id ?? '',
          eventoId: eventoId,
        );
        logger.d(bgSuccess ? '✅ Background tracking iniciado' : '⚠️ Background tracking falló');
      }
      
      return true;
    } catch (e) {
      logger.d('❌ Error iniciando tracking: $e');
      return false;
    }
  }

  // 🎯 TIMER PRINCIPAL DE TRACKING
  void _startTrackingTimer() {
    _trackingTimer?.cancel();

    _trackingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.trackingIntervalSeconds),
      (_) => _performLocationUpdate(),
    );

    logger.d(
        '🕒 Timer de tracking iniciado (${AppConstants.trackingIntervalSeconds}s)');
  }

  // 🎯 ACTUALIZACIÓN PRINCIPAL DE UBICACIÓN
  Future<void> _performLocationUpdate() async {
    if (_currentState.currentEvent == null ||
        _currentState.currentUser == null) {
      logger.d('⚠️ No hay evento o usuario activo para tracking');
      return;
    }

    try {
      // 1. Obtener ubicación actual del usuario
      final userPosition = await _locationService.getCurrentPosition();
      if (userPosition == null) {
        logger.d('⚠️ No se pudo obtener ubicación del usuario');
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
        
        // 4. ✅ NUEVO: Actualizar estado de sesión persistente
        await _updateSessionState();
      }
    } catch (e) {
      logger.d('❌ Error en actualización de ubicación: $e');
      _updateState(_currentState.copyWith(
        lastError: 'Error actualizando ubicación: $e',
      ));
    }
  }

  // 🎯 PROCESAR RESPUESTA COMPLETA DEL BACKEND
  Future<void> _processLocationResponse(LocationResponseModel response) async {
    logger.d('📍 Procesando respuesta del backend:');
    logger.d('   - insideGeofence: ${response.insideGeofence}');
    logger.d('   - distance: ${response.distance}m');
    logger.d('   - eventActive: ${response.eventActive}');
    logger.d('   - eventStarted: ${response.eventStarted}');

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
    logger.d('🗺️ ACTUALIZANDO COORDENADAS DEL USUARIO:');
    logger.d('   - Lat: ${response.latitude}');
    logger.d('   - Lng: ${response.longitude}');
    logger.d('   - Inside geofence: ${response.insideGeofence}');
    logger.d('   - Distance: ${response.distance}m');
    
    _updateState(_currentState.copyWith(
      isInsideGeofence: response.insideGeofence,
      distanceToEvent: response.distance,
      // ✅ PERMITIR REGISTRO COMO "REGISTRADO" EN EVENTOS NO INICIADOS
      // Los estudiantes pueden registrarse si están dentro del geofence,
      // independientemente del estado del evento (iniciado o no iniciado)
      canRegisterAttendance: response.eventActive && response.insideGeofence,
      lastLocationUpdate: DateTime.now(),
      userLatitude: response.latitude,
      userLongitude: response.longitude,
    ));
  }

  // 🎯 MANEJAR ENTRADA AL GEOFENCE
  Future<void> _handleEnteredGeofence(LocationResponseModel response) async {
    logger.d('✅ Usuario entró al geofence del evento');

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
    logger.d('⚠️ Usuario salió del geofence del evento');

    // 1. ✅ NUEVO: Mostrar notificación inmediata de salida
    await _notificationManager.showGeofenceExitedNotification(
        _currentState.currentEvent?.titulo ?? 'Evento');

    // 2. ✅ NUEVO: Notificar al profesor que el estudiante salió del área
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

  /// ✅ NUEVO: Notificar al profesor que el estudiante salió del área
  Future<void> _notifyTeacherStudentLeftArea() async {
    try {
      if (_currentState.currentEvent == null || _currentState.currentUser == null) {
        logger.d('⚠️ No hay evento o usuario para notificar al profesor');
        return;
      }

      await _teacherNotificationService.notifyStudentLeftArea(
        studentName: _currentState.currentUser!.nombre,
        eventTitle: _currentState.currentEvent!.titulo,
        eventId: _currentState.currentEvent!.id!,
        timeOutside: null, // Se calculará en el backend o en tiempo real
      );

      logger.d('📨 Docente notificado: estudiante ${_currentState.currentUser!.nombre} salió del área');
    } catch (e) {
      logger.d('❌ Error notificando profesor sobre estudiante que salió: $e');
    }
  }

  /// ✅ NUEVO: Notificar al profesor que el estudiante se registró
  Future<void> _notifyTeacherStudentJoined() async {
    try {
      if (_currentState.currentEvent == null || _currentState.currentUser == null) {
        logger.d('⚠️ No hay evento o usuario para notificar al profesor');
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

      logger.d('📨 Docente notificado: estudiante ${_currentState.currentUser!.nombre} se registró');
    } catch (e) {
      logger.d('❌ Error notificando profesor sobre estudiante registrado: $e');
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

    logger.d('⏰ Período de gracia iniciado: ${gracePeriodSeconds}s');
  }

  /// ✅ NUEVO DÍA 4: Continuar heartbeat en background (sin interrumpir)
  void _continueBackgroundHeartbeat() {
    logger.d('💓 Continuando heartbeat en background');

    // El heartbeat sigue funcionando normalmente en background
    // No se interrumpe por estar en background
    if (_heartbeatTimer?.isActive == true) {
      logger.d('✅ Heartbeat activo en background - sin cambios');
    }
  }

  // 🎯 MANEJAR EXPIRACIÓN DEL PERÍODO DE GRACIA
  Future<void> _handleGracePeriodExpired() async {
    logger.d('❌ Período de gracia expirado');

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
    logger.d('🏁 Evento terminado');

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
    logger.d('🛑 Deteniendo tracking con limpieza completa');

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

    // 2. ✅ NUEVO: Limpiar conexión WebSocket
    _cleanupWebSocketConnection();

    // 3. ✅ NUEVO: Limpiar sesión activa
    await _clearActiveSession();

    // 4. Limpiar notificaciones
    await _notificationManager.clearAllNotifications();

    // 3. Actualizar estado
    _updateState(_currentState.copyWith(
      trackingStatus: TrackingStatus.stopped,
      isInGracePeriod: false,
      gracePeriodRemaining: 0,
    ));

    logger.d('✅ Tracking detenido con limpieza completa');
  }

  // 🎯 PAUSAR TRACKING (DURANTE RECESOS)
  Future<void> pauseTracking() async {
    logger.d('⏸️ Pausando tracking para receso');

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
    logger.d('▶️ Reanudando tracking después del receso');

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
      logger.d('⚠️ No se puede registrar asistencia en este momento');
      return false;
    }

    try {
      logger.d(
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

      // ✅ NUEVO: Enviar notificación via WebSocket
      _sendAttendanceUpdate('presente');

      logger.d('✅ Asistencia registrada exitosamente');
      return true;
    } catch (e) {
      logger.d('❌ Error registrando asistencia: $e');
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
      logger.d('🎯 Estado actualizado: ${_currentState.statusText}');
    }
  }

  // 🎯 CLEANUP Y DISPOSE - FIXED: Enhanced memory leak prevention
  Future<void> dispose() async {
    logger.d('🧹 Limpiando StudentAttendanceManager con recursos críticos');

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
      logger.d('⚠️ Error closing state controller: $e');
    }

    try {
      if (!_locationController.isClosed) {
        await _locationController.close();
      }
    } catch (e) {
      logger.d('⚠️ Error closing location controller: $e');
    }

    // 4. FIXED: Location service cleanup (no subscriptions to stop, but ensure no pending operations)
    // Note: LocationService doesn't have persistent subscriptions to stop
    logger.d('✅ Location service cleanup completed');

    // 5. FIXED: Clean up notification service
    try {
      await _notificationManager.clearAllNotifications();
    } catch (e) {
      logger.d('⚠️ Error clearing notifications: $e');
    }

    // 6. FIXED: Reset state to prevent accidental reuse
    _currentState = AttendanceState.initial();

    logger.d('✅ StudentAttendanceManager disposed completamente - No memory leaks');
  }

  // 🎯 ========== MÉTODOS CRÍTICOS DÍA 2 ==========

  /// Registro de asistencia con backend real
  Future<bool> registerAttendanceWithBackend() async {
    if (!_currentState.canAttemptAttendanceRegistration) {
      logger.d('⚠️ No se puede registrar asistencia en este momento');
      return false;
    }

    try {
      logger.d('📝 Registrando asistencia en backend real');

      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _currentState.currentEvent!.id!,
        usuarioId: _currentState.currentUser!.id,
        latitud: _lastLocationResponse?.latitude ?? 0.0,
        longitud: _lastLocationResponse?.longitude ?? 0.0,
        estado: 'presente',
      );

      if (response.success) {
        await _notificationManager.showAttendanceRegisteredNotification();
        
        // ✅ NUEVO: Notificar al profesor que el estudiante se registró
        await _notifyTeacherStudentJoined();

        _updateState(_currentState.copyWith(
          hasRegisteredAttendance: true,
          attendanceRegisteredTime: DateTime.now(),
        ));

        logger.d('✅ Asistencia registrada en backend exitosamente');
        return true;
      }

      return false;
    } catch (e) {
      logger.d('❌ Error registrando asistencia en backend: $e');
      return false;
    }
  }

  /// Validar permisos antes de iniciar tracking
  Future<bool> validatePermissionsBeforeTracking() async {
    try {
      logger.d('🔍 Validando permisos antes de iniciar tracking');

      final permissionsValid =
          await _permissionService.validateAllPermissionsForTracking();

      if (!permissionsValid) {
        logger.d('❌ Permisos insuficientes para tracking');
        await _notificationManager.showCriticalAppLifecycleWarning();
        return false;
      }

      logger.d('✅ Todos los permisos validados correctamente');
      return true;
    } catch (e) {
      logger.d('❌ Error validando permisos: $e');
      return false;
    }
  }

  /// Manejo mejorado de app lifecycle con restricciones
  void handleAppLifecycleChange(AppLifecycleState state) {
    logger.d('📱 App lifecycle cambió a: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        logger.d('✅ App en foreground - tracking normal');

        if (_currentState.isInGracePeriod) {
          _cancelGracePeriod();
        }
        break;

      case AppLifecycleState.paused:
        _isAppInForeground = false;
        logger.d('📱 App en background - tracking continúa normalmente');
        // ✅ CORREGIDO: NO iniciar grace period para 'paused' - solo background tracking normal
        _updateBackgroundTrackingStatus();
        break;

      case AppLifecycleState.detached:
        logger.d('🚨 App CERRADA COMPLETAMENTE - Iniciando grace period 30s');
        _isAppInForeground = false;
        _triggerGracePeriod();
        break;

      case AppLifecycleState.inactive:
        logger.d('⏸️ App inactiva temporalmente - sin cambios');
        break;

      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        logger.d('🙈 App hidden - background tracking normal');
        // ✅ CORREGIDO: NO grace period para hidden - solo background tracking
        _updateBackgroundTrackingStatus();
        break;
    }
  }

  /// ✅ NUEVO DÍA 4: Actualizar estado de background tracking (sin penalización)
  void _updateBackgroundTrackingStatus() {
    if (_currentState.trackingStatus != TrackingStatus.active) return;

    logger.d('📱 Actualizando a background tracking - SIN penalización');

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
      logger.d('💓 Enviando heartbeat crítico al backend');

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

        logger.d('✅ Heartbeat enviado exitosamente');
      } else {
        logger.d('⚠️ Heartbeat falló - intentando reconectar');
        _handleHeartbeatFailure();
      }
    } catch (e) {
      logger.d('❌ Error enviando heartbeat: $e');
      _handleHeartbeatFailure();
    }
  }

  Future<void> _processBackendCommand(String command) async {
    logger.d('📡 Procesando comando del backend: $command');

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
        logger.d('⚠️ Comando desconocido: $command');
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

      logger.d(
          '📍 Evento geofence registrado: ${entering ? "entrada" : "salida"}');
    } catch (e) {
      logger.d('❌ Error registrando evento geofence: $e');
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

    logger.d('💓 Heartbeat iniciado cada 30 segundos');
  }

  /// Manejar falla crítica de heartbeat - FIXED: No memory leaks
  void _handleHeartbeatFailure() {
    logger.d('🚨 Falla crítica de heartbeat detectada');

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

    logger.d('📱 Monitoreo de lifecycle iniciado');
  }

  /// Manejar app en background
  void _handleAppInBackground() {
    if (_currentState.trackingStatus != TrackingStatus.active) return;

    logger.d('📱 App en background durante tracking activo');
    _notificationManager.showCriticalAppLifecycleWarning();
  }

  /// Pérdida automática de asistencia
  Future<void> _triggerAutomaticAttendanceLoss(String reason) async {
    logger.d('🚨 PÉRDIDA AUTOMÁTICA DE ASISTENCIA: $reason');

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

      logger.d('✅ Pérdida de asistencia procesada');
    } catch (e) {
      logger.d('❌ Error procesando pérdida de asistencia: $e');
    }
  }

  /// ✅ NUEVO: Inicializar WebSocket para el evento
  Future<void> _initializeWebSocketForEvent(String eventoId) async {
    try {
      logger.d('🔌 Inicializando WebSocket para estudiante en evento: $eventoId');
      
      // Obtener información del usuario actual
      final currentUser = await _storageService.getUser();
      if (currentUser == null) {
        logger.d('❌ No hay usuario logueado para WebSocket');
        return;
      }
      
      // Conectar al WebSocket
      final connected = await WebSocketService.instance.connectToEvent(
        eventId: eventoId,
        userId: currentUser.id,
        userRole: 'student',
      );
      
      if (connected) {
        // Escuchar mensajes WebSocket
        _wsSubscription = WebSocketService.instance.messageStream.listen(
          _handleWebSocketMessage,
          onError: (error) {
            logger.d('❌ Error WebSocket en attendance manager: $error');
          },
        );
        
        logger.d('✅ WebSocket inicializado para estudiante');
      }
    } catch (e) {
      logger.d('❌ Error configurando WebSocket: $e');
    }
  }

  /// ✅ NUEVO: Manejar mensajes WebSocket
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    
    logger.d('📨 Mensaje WebSocket recibido en attendance manager: $messageType');
    
    switch (messageType) {
      case 'event_status_changed':
        _handleEventStatusChanged(data);
        break;
        
      case 'grace_period_started':
        _handleGracePeriodStarted(data);
        break;
        
      case 'forced_attendance_check':
        _handleForcedAttendanceCheck(data);
        break;
        
      case 'break_started':
        _handleBreakStarted(data);
        break;
        
      case 'break_ended':
        _handleBreakEnded(data);
        break;
    }
  }

  /// ✅ NUEVO: Manejar cambio de estado de evento
  void _handleEventStatusChanged(Map<String, dynamic> data) {
    final newStatus = data['newStatus'] as String?;
    logger.d('📢 Estado de evento cambiado: $newStatus');
    
    if (newStatus == 'finalizado' || newStatus == 'cancelado') {
      _handleEventEnded();
    }
  }

  /// ✅ NUEVO: Manejar evento finalizado via WebSocket

  /// ✅ NUEVO: Manejar período de gracia iniciado via WebSocket
  void _handleGracePeriodStarted(Map<String, dynamic> data) {
    final gracePeriodSeconds = data['gracePeriodSeconds'] as int? ?? 60;
    logger.d('⏰ Período de gracia iniciado via WebSocket: ${gracePeriodSeconds}s');
    
    // Iniciar período de gracia local
    _triggerGracePeriod();
  }

  /// ✅ NUEVO: Manejar verificación forzada de asistencia
  void _handleForcedAttendanceCheck(Map<String, dynamic> data) {
    logger.d('🔍 Verificación forzada de asistencia solicitada');
    // Realizar verificación inmediata de ubicación
    _performLocationUpdate();
  }

  /// ✅ NUEVO: Manejar inicio de receso
  void _handleBreakStarted(Map<String, dynamic> data) {
    final breakDurationMinutes = data['breakDurationMinutes'] as int? ?? 15;
    logger.d('⏸️ Receso iniciado: $breakDurationMinutes minutos');
    
    // Mostrar notificación de receso
    _notificationManager.showBreakStartedNotification();
  }

  /// ✅ NUEVO: Manejar fin de receso
  void _handleBreakEnded(Map<String, dynamic> data) {
    logger.d('▶️ Receso terminado');
    
    // Mostrar notificación de fin de receso
    _notificationManager.showBreakEndedNotification();
  }

  /// ✅ NUEVO: Enviar actualización de asistencia via WebSocket
  void _sendAttendanceUpdate(String status) {
    try {
      if (_currentState.currentEvent?.id == null || _currentState.currentUser?.id == null) {
        logger.d('⚠️ No hay evento o usuario para enviar update WebSocket');
        return;
      }
      
      final message = {
        'type': 'attendance_update',
        'eventId': _currentState.currentEvent!.id,
        'userId': _currentState.currentUser!.id,
        'studentName': _currentState.currentUser!.nombre,
        'attendanceStatus': status,
        'timestamp': DateTime.now().toIso8601String(),
        'coordinates': {
          'latitude': _currentState.userLatitude,
          'longitude': _currentState.userLongitude,
        },
      };
      
      WebSocketService.instance.sendMessage(message);
      logger.d('📤 Actualización de asistencia enviada via WebSocket');
      
    } catch (e) {
      logger.d('❌ Error enviando update via WebSocket: $e');
    }
  }

  /// ✅ NUEVO: Limpiar conexión WebSocket
  void _cleanupWebSocketConnection() async {
    try {
      await _wsSubscription?.cancel();
      _wsSubscription = null;
      logger.d('✅ WebSocket connection cleaned up en attendance manager');
    } catch (e) {
      logger.d('❌ Error limpiando WebSocket: $e');
    }
  }

  /// ✅ NUEVO: Verificar y recuperar sesión activa al inicializar la app
  Future<void> _checkAndRecoverActiveSession() async {
    try {
      logger.d('🔍 Verificando si hay sesión activa para recuperar...');
      
      final activeSession = await _sessionPersistence.getActiveSession();
      if (activeSession == null) {
        logger.d('💡 No hay sesión activa para recuperar');
        return;
      }
      
      logger.d('🔄 Sesión activa encontrada: ${activeSession.eventTitle}');
      
      // Verificar si el evento aún es válido (no ha terminado hace más de 1 hora)
      final now = DateTime.now();
      if (now.isAfter(activeSession.eventEndTime.add(Duration(hours: 1)))) {
        logger.d('⚠️ Sesión expirada, limpiando...');
        await _sessionPersistence.clearActiveSession();
        return;
      }
      
      // Obtener estado guardado
      final savedState = await _sessionPersistence.getSavedAttendanceState();
      if (savedState == null) {
        logger.d('❌ No se pudo recuperar el estado de asistencia');
        await _sessionPersistence.clearActiveSession();
        return;
      }
      
      // Recuperar el estado
      _currentState = savedState;
      _stateController.add(_currentState);
      
      // Reiniciar el tracking si estaba activo
      if (_currentState.trackingStatus == TrackingStatus.active) {
        logger.d('🎯 Recuperando tracking activo para: ${activeSession.eventTitle}');
        
        // Reiniciar timers y tracking
        await _resumeTracking(activeSession);
        
        // Mostrar notificación de recuperación
        await _notificationManager.showAttendanceRecoveredNotification(
          activeSession.eventTitle,
          _formatDuration(now.difference(activeSession.startedAt)),
        );
        
        logger.d('✅ Sesión recuperada exitosamente');
      }
    } catch (e) {
      logger.d('❌ Error recuperando sesión activa: $e');
      // En caso de error, limpiar la sesión para evitar estados inconsistentes
      await _sessionPersistence.clearActiveSession();
    }
  }

  /// ✅ NUEVO: Reanudar tracking después de recuperación
  Future<void> _resumeTracking(ActiveSessionData session) async {
    try {
      // Reiniciar tracking timer
      _startTrackingTimer();
      
      // Reiniciar heartbeat timer 
      _startHeartbeatTimer();
      
      // Actualizar WebSocket si es necesario
      await _initializeWebSocketForEvent(session.eventId);
      
      logger.d('✅ Tracking reanudado para: ${session.eventTitle}');
    } catch (e) {
      logger.d('❌ Error reanudando tracking: $e');
    }
  }

  /// ✅ NUEVO: Guardar sesión activa cuando se inicia tracking
  Future<void> _saveActiveSession(Evento evento, Usuario usuario) async {
    try {
      await _sessionPersistence.saveActiveSession(
        evento: evento,
        usuario: usuario,
        state: _currentState,
      );
      logger.d('💾 Sesión activa guardada para: ${evento.titulo}');
    } catch (e) {
      logger.d('❌ Error guardando sesión activa: $e');
    }
  }

  /// ✅ NUEVO: Actualizar estado de sesión periódicamente
  Future<void> _updateSessionState() async {
    try {
      if (await _sessionPersistence.hasActiveSession()) {
        await _sessionPersistence.updateSessionState(_currentState);
      }
    } catch (e) {
      logger.d('❌ Error actualizando estado de sesión: $e');
    }
  }

  /// ✅ NUEVO: Finalizar sesión activa
  Future<void> _clearActiveSession() async {
    try {
      await _sessionPersistence.clearActiveSession();
      logger.d('✅ Sesión activa finalizada');
    } catch (e) {
      logger.d('❌ Error finalizando sesión activa: $e');
    }
  }

  /// Helper para formatear duración
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
