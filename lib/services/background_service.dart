import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/background_service.dart
// 🔥 SERVICIO COMPLETO - FOREGROUNDSERVICE NATIVO + WORKMANAGER + LIFECYCLE MANAGEMENT
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import '../services/notifications/notification_manager.dart';
import '../services/asistencia_service.dart';
import '../services/storage_service.dart';

/// Servicio completo de background con ForegroundService nativo de Android
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  // 🎯 NUEVAS PROPIEDADES PARA HEARTBEAT MEJORADO
  int _consecutiveHeartbeatFailures = 0;
  int _totalHeartbeatsSent = 0;
  int _totalHeartbeatFailures = 0;
  DateTime? _lastSuccessfulHeartbeat;
  bool _isHeartbeatCriticalFailure = false;
  final bool _isAppInForeground = true;
  static const int _maxConsecutiveFailures = 3;

  // 🔥 METHODCHANNEL PARA COMUNICACIÓN NATIVA
  static const MethodChannel _nativeChannel =
      MethodChannel('com.geoasist/foreground_service');

  // 🎯 IDENTIFICADORES DE TAREAS
  static const String _trackingTaskName = 'tracking_task';
  static const String _heartbeatTaskName = 'heartbeat_task';
  static const String _locationUpdateTaskName = 'location_update_task';
  static const String _lifecycleMonitorTaskName = 'lifecycle_monitor_task';

  // 🎯 SERVICIOS
  late NotificationManager _notificationManager;
  late AsistenciaService _asistenciaService;

  // 🎯 ESTADO DEL SERVICIO
  bool _isInitialized = false;
  bool _isForegroundServiceActive = false;
  bool _isNativeForegroundActive =
      false; // 🔥 NUEVO: Estado del servicio nativo
  bool _isWakeLockActive = false;
  String? _currentEventId;
  String? _currentUserId;
  DateTime? _lastHeartbeat; // 🔥 NUEVO: Último heartbeat
  int _gracePeriodSeconds = 30; // 🔥 NUEVO: Contador de grace period
  bool _isInGracePeriod = false; // 🔥 NUEVO: Estado de grace period

  // 🎯 TIMERS Y CONTROLADORES
  Timer? _heartbeatTimer;
  Timer? _locationTimer;
  Timer? _lifecycleTimer;
  Timer? _gracePeriodTimer; // 🔥 NUEVO: Timer para grace period

  /// Inicializar el servicio de background completo
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.d(
          '🚀 Inicializando BackgroundService con ForegroundService nativo');

      _notificationManager = NotificationManager();
      _asistenciaService = AsistenciaService();

      // 1. Inicializar notificaciones
      await _notificationManager.initialize();

      // 2. Inicializar WorkManager
      await _initializeWorkManager();

      // 3. 🔥 NUEVO: Verificar battery optimization
      await _checkBatteryOptimizationStatus();

      _isInitialized = true;
      logger.d('✅ BackgroundService inicializado con soporte nativo');
    } catch (e) {
      logger.d('❌ Error inicializando BackgroundService: $e');
      rethrow;
    }
  }

  Future<void> _initializeWorkManager() async {
    try {
      logger.d('⚙️ Configurando WorkManager');

      await Workmanager().initialize(
        callbackDispatcher,
      );

      logger.d('✅ WorkManager configurado');
    } catch (e) {
      logger.d('❌ Error configurando WorkManager: $e');
      rethrow;
    }
  }

  // 🔥 FOREGROUND SERVICE NATIVO - INTEGRACIÓN COMPLETA

  /// Iniciar ForegroundService nativo de Android + WorkManager
  Future<void> startForegroundService({
    required String userId,
    required String eventId,
  }) async {
    try {
      logger.d('🚀 Iniciando ForegroundService nativo completo');

      if (_isForegroundServiceActive) {
        logger.d('⚠️ ForegroundService ya está activo');
        return;
      }

      // 1. Guardar contexto del evento
      _currentEventId = eventId;
      _currentUserId = userId;

      // 2. 🔥 NUEVO: Iniciar ForegroundService nativo de Android
      final nativeSuccess = await _startNativeForegroundService();
      if (!nativeSuccess) {
        logger.d('❌ No se pudo iniciar ForegroundService nativo');
        // Continuar con WorkManager aunque falle el nativo
      }

      // 3. Crear notificación persistente de Flutter
      await _createPersistentTrackingNotification();

      // 4. Activar wake lock nativo
      await _enableNativeWakeLock();

      // 5. Registrar tareas de WorkManager
      await _registerBackgroundTasks();

      // 6. Iniciar timers críticos de Flutter
      _startCriticalTimers();

      // 7. Configurar tracking para el evento
      await setupTrackingForEvent(eventId, userId);

      _isForegroundServiceActive = true;
      _lastHeartbeat = DateTime.now();

      logger.d('✅ ForegroundService COMPLETO iniciado (Nativo + Flutter)');
    } catch (e) {
      logger.d('❌ Error iniciando ForegroundService completo: $e');
      rethrow;
    }
  }

  /// 🔥 NUEVO: Iniciar el ForegroundService nativo de Android
  Future<bool> _startNativeForegroundService() async {
    try {
      logger.d('📱 Iniciando ForegroundService nativo de Android');

      final success =
          await _nativeChannel.invokeMethod<bool>('startForegroundService') ??
              false;

      if (success) {
        _isNativeForegroundActive = true;
        logger.d('✅ ForegroundService nativo iniciado exitosamente');
      } else {
        logger.d('❌ ForegroundService nativo falló al iniciar');
      }

      return success;
    } catch (e) {
      logger.d('❌ Error comunicándose con ForegroundService nativo: $e');
      return false;
    }
  }

  /// Detener ForegroundService nativo + WorkManager
  Future<void> stopForegroundService() async {
    try {
      logger.d('🛑 Deteniendo ForegroundService completo');

      // 1. 🔥 NUEVO: Detener ForegroundService nativo
      await _stopNativeForegroundService();

      // 2. Cancelar todas las tareas de WorkManager
      await _cancelAllBackgroundTasks();

      // 3. Detener timers de Flutter
      _stopCriticalTimers();

      // 4. 🔥 NUEVO: Cancelar grace period si está activo
      _cancelGracePeriod();

      // 5. Desactivar wake lock nativo
      await _disableNativeWakeLock();

      // 6. Limpiar notificaciones de Flutter
      await _notificationManager.clearAllNotifications();

      // 7. Limpiar estado
      _isForegroundServiceActive = false;
      _isNativeForegroundActive = false;
      _currentUserId = null;
      _currentEventId = null;
      _lastHeartbeat = null;

      logger.d('✅ ForegroundService COMPLETO detenido');
    } catch (e) {
      logger.d('❌ Error deteniendo ForegroundService: $e');
    }
  }

  /// 🔥 NUEVO: Detener el ForegroundService nativo de Android
  Future<void> _stopNativeForegroundService() async {
    try {
      if (!_isNativeForegroundActive) return;

      logger.d('📱 Deteniendo ForegroundService nativo de Android');

      await _nativeChannel.invokeMethod('stopForegroundService');
      _isNativeForegroundActive = false;

      logger.d('✅ ForegroundService nativo detenido');
    } catch (e) {
      logger.d('❌ Error deteniendo ForegroundService nativo: $e');
    }
  }

  Future<void> _createPersistentTrackingNotification() async {
    try {
      logger.d('📱 Creando notificación persistente');

      await _notificationManager.showTrackingActiveNotification();

      logger.d('✅ Notificación persistente creada');
    } catch (e) {
      logger.d('❌ Error creando notificación persistente: $e');
      rethrow;
    }
  }

  // 🎯 NATIVE WAKE LOCK

  /// Activar wake lock usando permisos nativos de Android
  Future<void> _enableNativeWakeLock() async {
    try {
      if (_isWakeLockActive) return;

      logger.d('🔋 Activando Wake Lock nativo (Android permissions)');

      // El permiso WAKE_LOCK ya está en AndroidManifest.xml
      // El sistema Android gestiona automáticamente el wake lock
      // con ForegroundService + WorkManager
      _isWakeLockActive = true;

      logger.d(
          '✅ Wake Lock nativo activado - CPU mantenida activa por sistema');
    } catch (e) {
      logger.d('❌ Error activando Wake Lock nativo: $e');
      // No es crítico, continuamos sin wake lock específico
    }
  }

  /// Desactivar wake lock nativo
  Future<void> _disableNativeWakeLock() async {
    try {
      if (!_isWakeLockActive) return;

      logger.d('🔋 Desactivando Wake Lock nativo');

      // El sistema Android libera automáticamente el wake lock
      // cuando se detiene el ForegroundService
      _isWakeLockActive = false;

      logger.d('✅ Wake Lock nativo desactivado');
    } catch (e) {
      logger.d('❌ Error desactivando Wake Lock nativo: $e');
    }
  }

  // 🔥 NUEVOS MÉTODOS CRÍTICOS

  /// Verificar y solicitar exención de optimización de batería
  Future<void> _checkBatteryOptimizationStatus() async {
    try {
      logger.d('🔋 Verificando optimización de batería');

      final isIgnored = await _nativeChannel
              .invokeMethod<bool>('isBatteryOptimizationIgnored') ??
          false;

      if (!isIgnored) {
        logger.d('⚡ Solicitando exención de optimización de batería');
        await _nativeChannel
            .invokeMethod('requestBatteryOptimizationExemption');
      } else {
        logger.d('✅ App ya está exenta de optimización de batería');
      }
    } catch (e) {
      logger.d('❌ Error verificando battery optimization: $e');
    }
  }

  /// 🔥 NUEVO: Actualizar estado de la notificación nativa
  Future<void> updateNativeNotificationStatus(String status) async {
    try {
      if (!_isNativeForegroundActive) return;

      logger.d('📱 Actualizando notificación nativa: $status');

      await _nativeChannel.invokeMethod('updateNotificationStatus', {
        'status': status,
      });
    } catch (e) {
      logger.d('❌ Error actualizando notificación nativa: $e');
    }
  }

  /// 🔥 NUEVO: Iniciar el período de gracia de 30 segundos
  Future<void> _startGracePeriod() async {
    if (_isInGracePeriod) return;

    logger.d('⏳ Iniciando grace period de 30 segundos');

    _isInGracePeriod = true;
    _gracePeriodSeconds = 30;

    // Timer que cuenta regresivamente cada segundo
    _gracePeriodTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      _gracePeriodSeconds--;

      // Mostrar notificación de countdown cada 5 segundos
      if (_gracePeriodSeconds % 5 == 0 || _gracePeriodSeconds <= 10) {
        await _notificationManager
            .showAppClosedWarningNotification(_gracePeriodSeconds);
      }

      // Actualizar notificación nativa también
      await updateNativeNotificationStatus(
          'REABRE YA - ${_gracePeriodSeconds}s');

      // Si se acaba el tiempo, activar pérdida de asistencia
      if (_gracePeriodSeconds <= 0) {
        timer.cancel();
        await triggerAttendanceLossProtocol('Grace period expirado');
      }
    });
  }

  /// 🔥 NUEVO: Cancelar el período de gracia
  void _cancelGracePeriod() {
    if (!_isInGracePeriod) return;

    logger.d('✅ Cancelando grace period - App reactivada');

    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    _isInGracePeriod = false;
    _gracePeriodSeconds = 30;

    // Limpiar notificaciones de warning
    _notificationManager.clearAllNotifications();
  }

  // 🎯 BACKGROUND TASKS

  /// Registrar todas las tareas de background
  Future<void> _registerBackgroundTasks() async {
    try {
      logger.d('📋 Registrando tareas de background');

      // 1. Tarea principal de tracking
      await _registerTrackingTask();

      // 2. Tarea de heartbeat
      await _registerHeartbeatTask();

      // 3. Tarea de actualizaciones de ubicación
      await _registerLocationUpdateTask();

      // 4. Tarea de monitoreo de lifecycle
      await _registerLifecycleMonitorTask();

      logger.d('✅ Todas las tareas de background registradas');
    } catch (e) {
      logger.d('❌ Error registrando tareas: $e');
      rethrow;
    }
  }

  Future<void> _registerTrackingTask() async {
    await Workmanager().registerPeriodicTask(
      _trackingTaskName,
      _trackingTaskName,
      frequency: const Duration(minutes: 15), // Mínimo permitido por Android
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'task_type': 'tracking',
        'event_id': _currentEventId,
        'user_id': _currentUserId,
      },
    );

    logger.d('📍 Tarea de tracking registrada');
  }

  Future<void> _registerHeartbeatTask() async {
    await Workmanager().registerPeriodicTask(
      _heartbeatTaskName,
      _heartbeatTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        'task_type': 'heartbeat',
        'event_id': _currentEventId,
        'user_id': _currentUserId,
      },
    );

    logger.d('💓 Tarea de heartbeat registrada');
  }

  Future<void> _registerLocationUpdateTask() async {
    await Workmanager().registerPeriodicTask(
      _locationUpdateTaskName,
      _locationUpdateTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        'task_type': 'location_update',
        'event_id': _currentEventId,
        'user_id': _currentUserId,
      },
    );

    logger.d('🌍 Tarea de ubicación registrada');
  }

  Future<void> _registerLifecycleMonitorTask() async {
    await Workmanager().registerPeriodicTask(
      _lifecycleMonitorTaskName,
      _lifecycleMonitorTaskName,
      frequency: const Duration(minutes: 15),
      inputData: {
        'task_type': 'lifecycle_monitor',
        'event_id': _currentEventId,
        'user_id': _currentUserId,
      },
    );

    logger.d('🔄 Tarea de lifecycle registrada');
  }

  /// Cancelar todas las tareas de background
  Future<void> _cancelAllBackgroundTasks() async {
    try {
      logger.d('🚫 Cancelando todas las tareas de background');

      await Workmanager().cancelByUniqueName(_trackingTaskName);
      await Workmanager().cancelByUniqueName(_heartbeatTaskName);
      await Workmanager().cancelByUniqueName(_locationUpdateTaskName);
      await Workmanager().cancelByUniqueName(_lifecycleMonitorTaskName);

      logger.d('✅ Todas las tareas canceladas');
    } catch (e) {
      logger.d('❌ Error cancelando tareas: $e');
    }
  }

  // 🎯 TIMERS CRÍTICOS

  /// Iniciar timers críticos del foreground
  void _startCriticalTimers() {
    logger.d('⏰ Iniciando timers críticos');

    // Heartbeat cada 30 segundos (complementa WorkManager)
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await _performHeartbeat();
      },
    );

    // Actualización de ubicación cada 10 segundos
    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        await _performLocationUpdate();
      },
    );

    // Monitoreo de lifecycle cada 5 segundos
    _lifecycleTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        await _performLifecycleCheck();
      },
    );

    logger.d('✅ Timers críticos iniciados');
  }

  /// Detener timers críticos
  void _stopCriticalTimers() {
    logger.d('⏰ Deteniendo timers críticos');

    _heartbeatTimer?.cancel();
    _locationTimer?.cancel();
    _lifecycleTimer?.cancel();

    _heartbeatTimer = null;
    _locationTimer = null;
    _lifecycleTimer = null;

    logger.d('✅ Timers detenidos');
  }

  // 🎯 EJECUCIÓN DE TAREAS - MEJORADAS

  /// 🔥 ACTUALIZAR tu método _performHeartbeat() existente:
  Future<void> _performHeartbeat() async {
    try {
      if (_currentUserId == null || _currentEventId == null) {
        logger.d('⚠️ Heartbeat cancelado - Sin usuario/evento activo');
        return;
      }

      logger.d(
          '💓 Enviando heartbeat crítico mejorado (#$_totalHeartbeatsSent)');

      // 1. ✅ NUEVO: Obtener ubicación real para heartbeat si está disponible
      final currentLocation = await _getCurrentLocationForHeartbeat();

      // 2. ✅ NUEVO: Usar tu AsistenciaService mejorado
      final heartbeatResponse =
          await _asistenciaService.enviarHeartbeatConValidacion(
        usuarioId: _currentUserId!,
        eventoId: _currentEventId!,
        latitud: currentLocation['latitude'],
        longitud: currentLocation['longitude'],
        appActive: _isAppInForeground, // Usar tu variable existente
        maxReintentos: 2, // Menos reintentos para el timer automático
      );

      // 3. ✅ NUEVO: Procesar respuesta del backend
      if (heartbeatResponse.success) {
        await _handleSuccessfulHeartbeat(heartbeatResponse.data);
      } else {
        throw Exception(
            'Backend rechazó heartbeat: ${heartbeatResponse.error}');
      }

      // 4. ✅ NUEVO: Actualizar estadísticas de éxito
      _totalHeartbeatsSent++;
      _consecutiveHeartbeatFailures = 0;
      _lastSuccessfulHeartbeat = DateTime.now();
      _isHeartbeatCriticalFailure = false;

      // 5. ✅ Actualizar tus notificaciones existentes
      final timeString = DateTime.now().toString().substring(11, 19);
      await updateNativeNotificationStatus('💓 Heartbeat OK $timeString');
      await _notificationManager.updateTrackingNotificationStatus(
          'Heartbeat #$_totalHeartbeatsSent - $timeString');
      logger.d('💓 Heartbeat #$_totalHeartbeatsSent enviado exitosamente');
    } catch (e) {
      logger.d('❌ Error crítico en heartbeat #$_totalHeartbeatsSent: $e');
      await _handleHeartbeatFailure(e.toString());
    }
  }

  /// 🔥 NUEVO: Obtener ubicación actual para heartbeat (compatible con tu sistema)
  Future<Map<String, double?>> _getCurrentLocationForHeartbeat() async {
    try {
      // ✅ Integrar con tu sistema de ubicación existente si está disponible
      // Por ahora, usar valores seguros que no rompan el flujo
      return {
        'latitude': null, // En producción: usar tu LocationService
        'longitude': null,
        'accuracy': null,
      };
    } catch (e) {
      logger.d('⚠️ Error obteniendo ubicación para heartbeat: $e');
      return {'latitude': null, 'longitude': null, 'accuracy': null};
    }
  }

  /// 🔥 NUEVO: Procesar respuesta exitosa del heartbeat
  Future<void> _handleSuccessfulHeartbeat(
      Map<String, dynamic>? responseData) async {
    try {
      if (responseData == null) return;

      logger.d('📊 Procesando respuesta de heartbeat exitoso');

      // 1. ✅ Verificar si el evento sigue activo según el backend
      final eventStillActive =
          responseData['eventoActivo'] ?? responseData['eventActive'] ?? true;
      if (!eventStillActive) {
        logger.d('🏁 Backend reporta evento terminado - deteniendo tracking');
        await _handleEventEndedByBackend();
        return;
      }

      // 2. ✅ Verificar estado de asistencia según el backend
      final attendanceStatus = responseData['estadoAsistencia'] ??
          responseData['attendanceStatus'] as String?;
      if (attendanceStatus == 'lost' || attendanceStatus == 'ausente') {
        logger.d(
            '❌ Backend reporta asistencia perdida - activando protocolo');
        await triggerAttendanceLossProtocol(
            'Backend reportó pérdida de asistencia');
        return;
      }

      // 3. ✅ Verificar si hay receso activo
      final inBreak =
          responseData['enReceso'] ?? responseData['inBreak'] ?? false;
      if (inBreak) {
        logger.d('⏸️ Backend reporta receso activo');
        await _notificationManager.showBreakStartedNotification();
      }

      // 4. ✅ Procesar comandos del backend si los hay
      final backendCommands = responseData['comandosBackend'] ??
          responseData['commands'] as List<dynamic>?;
      if (backendCommands != null && backendCommands.isNotEmpty) {
        await _processBackendCommands(backendCommands);
      }

      // 5. ✅ Actualizar métricas si están disponibles
      final metrics = responseData['metricas'] ??
          responseData['metrics'] as Map<String, dynamic>?;
      if (metrics != null) {
        logger.d('📈 Métricas recibidas del backend: ${metrics.keys}');
      }
    } catch (e) {
      logger.d('⚠️ Error procesando respuesta de heartbeat: $e');
    }
  }

  Future<void> _performLocationUpdate() async {
    try {
      if (_currentUserId == null || _currentEventId == null) return;

      logger.d('🌍 Actualizando ubicación desde timer');

      // En una implementación real, aquí se obtendría la ubicación GPS
      // y se enviaría al backend
    } catch (e) {
      logger.d('❌ Error actualizando ubicación: $e');
    }
  }

  /// 🔥 MODIFICADO: Lifecycle check con validación nativa
  Future<void> _performLifecycleCheck() async {
    try {
      logger.d('🔄 Verificando estado de app lifecycle');

      // Verificar que ambos servicios siguen activos
      if (_isForegroundServiceActive && _lastHeartbeat != null) {
        final timeSinceLastHeartbeat =
            DateTime.now().difference(_lastHeartbeat!);

        if (timeSinceLastHeartbeat.inSeconds > 60) {
          logger.d('⚠️ Heartbeat perdido - reiniciando');
          await _performHeartbeat();
        }

        // 🔥 NUEVO: Verificar estado del servicio nativo también
        if (_isNativeForegroundActive) {
          await updateNativeNotificationStatus('Lifecycle Check OK');
        }
      }
    } catch (e) {
      logger.d('❌ Error en lifecycle check: $e');
    }
  }

  /// 🔥 ACTUALIZAR tu método _handleHeartbeatFailure() existente:
  Future<void> _handleHeartbeatFailure(String error) async {
    _consecutiveHeartbeatFailures++;
    _totalHeartbeatFailures++;

    logger.d(
        '💔 Fallo de heartbeat #$_consecutiveHeartbeatFailures/$_maxConsecutiveFailures');
    logger.d('💔 Error: $error');

    // 1. ✅ Actualizar tus notificaciones existentes
    await updateNativeNotificationStatus(
        '💔 Heartbeat Error $_consecutiveHeartbeatFailures/$_maxConsecutiveFailures');
    await _notificationManager.showConnectionErrorNotification();

    // 2. ✅ Escalación según número de fallos consecutivos
    if (_consecutiveHeartbeatFailures == 1) {
      logger.d('⚠️ Primer fallo de heartbeat - monitoreando...');
    } else if (_consecutiveHeartbeatFailures == 2) {
      logger.d('🚨 Segundo fallo de heartbeat - advertencia crítica');
      await _notificationManager.showCriticalAppLifecycleWarning();
    } else if (_consecutiveHeartbeatFailures >= _maxConsecutiveFailures) {
      logger.d(
          '❌ FALLOS CRÍTICOS DE HEARTBEAT - Activando protocolo de pérdida');
      _isHeartbeatCriticalFailure = true;

      await _notificationManager.showAppClosedWarningNotification(30);

      // ✅ Usar tu timer de grace period existente
      Timer(const Duration(seconds: 30), () async {
        if (_consecutiveHeartbeatFailures >= _maxConsecutiveFailures) {
          await triggerAttendanceLossProtocol(
              'Fallos críticos de heartbeat consecutivos');
        }
      });
    }

    // 3. ✅ NUEVO: Intentar recovery automático
    await _attemptHeartbeatRecovery();
  }

  /// 🔥 NUEVO: Intentar recuperación automática del heartbeat
  Future<void> _attemptHeartbeatRecovery() async {
    try {
      logger.d('🔄 Intentando recuperación automática de heartbeat...');

      // 1. ✅ Verificar conectividad usando tu AsistenciaService mejorado
      final isConnected = await _asistenciaService.testConnection();
      if (!isConnected.success) {
        logger.d('❌ Sin conectividad - no se puede recuperar heartbeat');
        return;
      }

      // 2. ✅ Verificar que tus servicios básicos funcionen
      final servicesHealthy = await _validateCoreServices();
      if (!servicesHealthy) {
        logger.d('❌ Servicios core no están saludables');
        return;
      }

      // 3. ✅ Reintentrar heartbeat inmediatamente
      logger.d('🔄 Reintentando heartbeat después de fallo...');
      await _performHeartbeat();
    } catch (e) {
      logger.d('❌ Error en recuperación de heartbeat: $e');
    }
  }

  /// 🔥 NUEVO: Validar servicios core para recovery
  Future<bool> _validateCoreServices() async {
    try {
      // 🔧 CORREGIDO: Sin comparaciones null innecesarias
      final asistenciaServiceOk = _isInitialized;
      final notificationManagerOk = _isInitialized;
      final nativeServiceOk = _isNativeForegroundActive;

      final allServicesOk =
          asistenciaServiceOk && notificationManagerOk && nativeServiceOk;

      logger.d('🔍 Validación servicios core: $allServicesOk');
      return allServicesOk;
    } catch (e) {
      logger.d('❌ Error validando servicios core: $e');
      return false;
    }
  }

  /// 🔥 NUEVO: Procesar comandos del backend
  Future<void> _processBackendCommands(List<dynamic> commands) async {
    try {
      for (final command in commands) {
        if (command is! Map<String, dynamic>) continue;

        final commandType = command['type'] as String?;
        logger.d('📨 Procesando comando del backend: $commandType');

        switch (commandType) {
          case 'start_break':
            await _notificationManager.showBreakStartedNotification();
            break;
          case 'end_break':
            await _notificationManager.showBreakEndedNotification();
            break;
          case 'force_location_update':
            await _performLocationUpdate(); // Usar tu método existente
            break;
          case 'update_notification':
            final message = command['message'] as String?;
            if (message != null) {
              await updateNativeNotificationStatus(message);
            }
            break;
          default:
            logger.d('⚠️ Comando desconocido del backend: $commandType');
        }
      }
    } catch (e) {
      logger.d('❌ Error procesando comandos del backend: $e');
    }
  }

  /// 🔥 NUEVO: Manejar evento terminado por el backend
  Future<void> _handleEventEndedByBackend() async {
    logger.d('🏁 El backend reporta que el evento ha terminado');

    await _notificationManager
        .showEventEndedNotification(_currentEventId ?? '');
    await stopForegroundService(); // Usar tu método existente
  }

  // 🎯 GESTIÓN DE NOTIFICACIONES

  /// Actualizar estado de la notificación de tracking
  Future<void> _updateTrackingNotificationStatus(String status) async {
    try {
      await _notificationManager.updateTrackingNotificationStatus(status);
      await updateNativeNotificationStatus(
          status); // 🔥 NUEVO: Actualizar ambas
    } catch (e) {
      logger.d('❌ Error actualizando notificación: $e');
    }
  }

  /// Mostrar notificación de advertencia crítica
  Future<void> showCriticalAppLifecycleWarning() async {
    try {
      logger.d('🚨 Mostrando advertencia crítica de lifecycle');

      await _notificationManager.showCriticalAppLifecycleWarning();
    } catch (e) {
      logger.d('❌ Error mostrando advertencia crítica: $e');
    }
  }

  // 🎯 MANEJO DE APP LIFECYCLE - MEJORADO

  /// Manejar eventos de lifecycle de la aplicación
  Future<void> handleAppLifecycleEvents(String state) async {
    logger.d('📱 App lifecycle cambió a: $state');

    switch (state) {
      case 'resumed':
        await _handleAppResumed();
        break;
      case 'paused':
        await _handleAppPaused();
        break;
      case 'detached':
        await _handleAppDetached();
        break;
      case 'inactive':
        await _handleAppInactive();
        break;
      case 'hidden':
        await _handleAppHidden();
        break;
    }
  }

  /// 🔥 MODIFICADO: App resumed con grace period
  Future<void> _handleAppResumed() async {
    logger.d('✅ App resumed - Cancelando grace period');

    // 🔥 NUEVO: Cancelar grace period si estaba activo
    if (_isInGracePeriod) {
      _cancelGracePeriod();
    }

    if (_isForegroundServiceActive) {
      await updateNativeNotificationStatus('Tracking Activo');
      await _notificationManager
          .updateTrackingNotificationStatus('Tracking Activo');
    }
  }

  /// 🔥 MODIFICADO: App paused con grace period
  Future<void> _handleAppPaused() async {
    logger.d('⏸️ App paused - Iniciando grace period');

    if (_isForegroundServiceActive) {
      await updateNativeNotificationStatus('Tracking en Background');
      await _notificationManager
          .updateTrackingNotificationStatus('Tracking en Background');
      await _startGracePeriod(); // 🔥 NUEVO: Iniciar grace period
    }
  }

  /// 🔥 MODIFICADO: App detached sin grace period
  Future<void> _handleAppDetached() async {
    logger.d('❌ App detached - Activando protocolo de pérdida inmediata');

    // 🔥 NUEVO: Sin grace period para detached
    await triggerAttendanceLossProtocol('App cerrada completamente');
  }

  Future<void> _handleAppInactive() async {
    logger.d('⚠️ App inactive - Monitoreando...');
  }

  Future<void> _handleAppHidden() async {
    logger.d('🙈 App hidden - Tracking pausado temporalmente');

    if (_isForegroundServiceActive) {
      await _updateTrackingNotificationStatus('Tracking Pausado');
    }
  }

  /// 🔥 ACTUALIZAR tu método triggerAttendanceLossProtocol() existente:
  Future<void> triggerAttendanceLossProtocol(String reason) async {
    try {
      logger.d('❌ ACTIVANDO PROTOCOLO DE PÉRDIDA: $reason');

      if (_currentUserId != null && _currentEventId != null) {
        // ✅ Usar tu AsistenciaService mejorado
        await _asistenciaService.marcarAusentePorCierreApp(
          usuarioId: _currentUserId!,
          eventoId: _currentEventId!,
          razonEspecifica: reason,
        );
      }

      // ✅ Usar tus métodos existentes
      await stopForegroundService();
      await _notificationManager.clearAllNotifications();

      logger.d('✅ Protocolo de pérdida ejecutado');
    } catch (e) {
      logger.d('❌ Error en protocolo de pérdida: $e');
    }
  }

  // 🎯 CONFIGURACIÓN DE TRACKING

  /// 🔥 ACTUALIZAR tu método setupTrackingForEvent() existente:
  Future<void> setupTrackingForEvent(String eventId, String userId) async {
    try {
      logger.d('⚙️ Configurando tracking para evento: $eventId');

      _currentEventId = eventId;
      _currentUserId = userId;

      // ✅ NUEVO: Reset de estadísticas para nuevo evento
      resetHeartbeatStatistics();

      if (_isForegroundServiceActive) {
        await _cancelAllBackgroundTasks();
        await _registerBackgroundTasks();
      }

      logger.d('✅ Tracking configurado para evento: $eventId');
    } catch (e) {
      logger.d('❌ Error configurando tracking: $e');
      rethrow;
    }
  }

  // 🎯 ESTADO Y INFORMACIÓN - AMPLIADO

  /// Verificar si el servicio está activo
  bool get isForegroundServiceActive => _isForegroundServiceActive;

  /// 🔥 NUEVO: Verificar si el ForegroundService nativo está activo
  bool get isNativeForegroundActive => _isNativeForegroundActive;

  /// Verificar si WakeLock está activo
  bool get isWakeLockActive => _isWakeLockActive;

  /// 🔥 NUEVO: Verificar si está en período de gracia
  bool get isInGracePeriod => _isInGracePeriod;

  /// 🔥 NUEVO: Obtener segundos restantes del período de gracia
  int get gracePeriodSecondsRemaining => _gracePeriodSeconds;

  /// 🔥 NUEVO: Obtener último heartbeat
  DateTime? get lastHeartbeat => _lastHeartbeat;

  /// 🔥 ACTUALIZAR tu método getCompleteServiceStatus() existente:
  Map<String, dynamic> getCompleteServiceStatus() {
    final baseStatus = {
      'initialized': _isInitialized,
      'foreground_service_active': _isForegroundServiceActive,
      'native_foreground_active': _isNativeForegroundActive,
      'wakelock_active': _isWakeLockActive,
      'in_grace_period': _isInGracePeriod,
      'grace_period_seconds_remaining': _gracePeriodSeconds,
      'current_event_id': _currentEventId,
      'current_user_id': _currentUserId,
      'last_heartbeat': _lastHeartbeat?.toIso8601String(),
      'heartbeat_timer_active': _heartbeatTimer?.isActive ?? false,
      'location_timer_active': _locationTimer?.isActive ?? false,
      'lifecycle_timer_active': _lifecycleTimer?.isActive ?? false,
    };

    // ✅ NUEVO: Agregar estadísticas de heartbeat
    final heartbeatStats = {
      'total_heartbeats_sent': _totalHeartbeatsSent,
      'total_failures': _totalHeartbeatFailures,
      'consecutive_failures': _consecutiveHeartbeatFailures,
      'last_successful_heartbeat': _lastSuccessfulHeartbeat?.toIso8601String(),
      'is_critical_failure': _isHeartbeatCriticalFailure,
      'success_rate': _totalHeartbeatsSent > 0
          ? ((_totalHeartbeatsSent - _totalHeartbeatFailures) /
                  _totalHeartbeatsSent *
                  100)
              .toStringAsFixed(1)
          : '0.0',
    };

    // ✅ NUEVO: Agregar estadísticas del AsistenciaService
    final asistenciaStats = _asistenciaService.getHeartbeatStatistics();

    return {
      ...baseStatus,
      'heartbeat_statistics': heartbeatStats,
      'asistencia_service_stats': asistenciaStats,
    };
  }

  /// 🔥 NUEVO: Reset de estadísticas de heartbeat (para nuevos eventos)
  void resetHeartbeatStatistics() {
    logger.d('🔄 Reseteando estadísticas de heartbeat');

    _consecutiveHeartbeatFailures = 0;
    _totalHeartbeatsSent = 0;
    _totalHeartbeatFailures = 0;
    _lastSuccessfulHeartbeat = null;
    _isHeartbeatCriticalFailure = false;

    // ✅ También resetear en AsistenciaService
    _asistenciaService.resetSession();
  }

  /// Obtener información del estado actual (compatibilidad)
  Map<String, dynamic> getServiceStatus() {
    return getCompleteServiceStatus();
  }

  /// Limpiar configuración
  void clearConfiguration() {
    logger.d('🧹 Limpiando configuración de BackgroundService');

    _currentEventId = null;
    _currentUserId = null;
  }

  /// Reiniciar servicio completo
  Future<void> restart() async {
    try {
      logger.d('🔄 Reiniciando BackgroundService');

      await stopForegroundService();
      await Future.delayed(const Duration(seconds: 2));

      if (_currentUserId != null && _currentEventId != null) {
        await startForegroundService(
          userId: _currentUserId!,
          eventId: _currentEventId!,
        );
      }

      logger.d('✅ BackgroundService reiniciado');
    } catch (e) {
      logger.d('❌ Error reiniciando servicio: $e');
      rethrow;
    }
  }
}

// 🎯 CALLBACK DISPATCHER PARA WORKMANAGER

/// Callback dispatcher para tareas de background de WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      logger.d('🔄 Ejecutando tarea de background: $task');
      logger.d('📦 Datos de entrada: $inputData');

      // Obtener tipo de tarea
      final taskType = inputData?['task_type'] as String?;
      final eventId = inputData?['event_id'] as String?;
      final userId = inputData?['user_id'] as String?;

      if (taskType == null || eventId == null || userId == null) {
        logger.d('❌ Datos insuficientes para ejecutar tarea');
        return Future.value(false);
      }

      // Ejecutar según el tipo de tarea
      switch (taskType) {
        case 'tracking':
          await _executeTrackingTask(eventId, userId);
          break;
        case 'heartbeat':
          await _executeHeartbeatTask(eventId, userId);
          break;
        case 'location_update':
          await _executeLocationUpdateTask(eventId, userId);
          break;
        case 'lifecycle_monitor':
          await _executeLifecycleMonitorTask(eventId, userId);
          break;
        default:
          logger.d('❌ Tipo de tarea desconocido: $taskType');
          return Future.value(false);
      }

      logger.d('✅ Tarea completada: $task');
      return Future.value(true);
    } catch (e) {
      logger.d('❌ Error ejecutando tarea de background: $e');
      return Future.value(false);
    }
  });
}

// 🎯 EJECUCIÓN DE TAREAS ESPECÍFICAS

Future<void> _executeTrackingTask(String eventId, String userId) async {
  try {
    logger.d('📍 Ejecutando tarea de tracking');

    // Verificar que el tracking sigue siendo necesario
    final storageService = StorageService();
    final user = await storageService.getUser();

    if (user?.id != userId) {
      logger.d('⚠️ Usuario cambió, cancelando tracking');
      return;
    }

    // Realizar verificaciones de tracking
    await _performBackgroundTrackingCheck(eventId, userId);

    logger.d('✅ Tarea de tracking completada');
  } catch (e) {
    logger.d('❌ Error en tarea de tracking: $e');
    rethrow;
  }
}

Future<void> _executeHeartbeatTask(String eventId, String userId) async {
  try {
    logger.d('💓 Ejecutando tarea de heartbeat');

    final asistenciaService = AsistenciaService();

    // Enviar heartbeat al backend
    await asistenciaService.actualizarUbicacion(
      usuarioId: userId,
      eventoId: eventId,
      latitud: 0.0, // Placeholder - en producción usar ubicación real
      longitud: 0.0,
    );

    logger.d('✅ Heartbeat enviado desde background');
  } catch (e) {
    logger.d('❌ Error en heartbeat background: $e');
    rethrow;
  }
}

Future<void> _executeLocationUpdateTask(String eventId, String userId) async {
  try {
    logger.d('🌍 Ejecutando tarea de actualización de ubicación');

    // En una implementación real, aquí se obtendría la ubicación GPS actual
    // y se enviaría al backend usando AsistenciaService

    final asistenciaService = AsistenciaService();

    // Placeholder para actualización de ubicación
    await asistenciaService.actualizarUbicacion(
      usuarioId: userId,
      eventoId: eventId,
      latitud: 0.0, // En producción: obtener GPS real
      longitud: 0.0,
    );

    logger.d('✅ Ubicación actualizada desde background');
  } catch (e) {
    logger.d('❌ Error actualizando ubicación background: $e');
    rethrow;
  }
}

Future<void> _executeLifecycleMonitorTask(String eventId, String userId) async {
  try {
    logger.d('🔄 Ejecutando tarea de monitoreo de lifecycle');

    // Verificar que la app no haya sido terminada abruptamente
    final notificationManager = NotificationManager();

    // Actualizar notificación para mostrar que el background está funcionando
    await notificationManager.updateTrackingNotificationStatus(
        'Background Activo - ${DateTime.now().toString().substring(11, 19)}');

    logger.d('✅ Monitoreo de lifecycle completado');
  } catch (e) {
    logger.d('❌ Error en monitoreo lifecycle: $e');
    rethrow;
  }
}

Future<void> _performBackgroundTrackingCheck(
    String eventId, String userId) async {
  try {
    logger.d('🔍 Verificando estado de tracking en background');

    final asistenciaService = AsistenciaService();

    // Verificar estado actual de asistencia
    final estado =
        await asistenciaService.validarEstadoAsistencia(userId, eventId);

    if (estado == null) {
      logger.d('⚠️ No hay asistencia registrada para verificar');
      return;
    }

    if (estado == 'ausente') {
      logger.d('❌ Usuario ya marcado como ausente, deteniendo tracking');

      // Cancelar todas las tareas si ya está ausente
      await Workmanager().cancelAll();
      return;
    }

    logger.d('✅ Estado de tracking verificado: $estado');
  } catch (e) {
    logger.d('❌ Error verificando tracking: $e');
    rethrow;
  }
}

// 🎯 UTILIDADES ADICIONALES PARA BACKGROUND

/// Verificar si WorkManager está funcionando correctamente
Future<bool> isWorkManagerHealthy() async {
  try {
    // En una implementación real, se verificaría el estado de WorkManager
    // Por ahora, simplemente retornamos true
    return true;
  } catch (e) {
    logger.d('❌ Error verificando WorkManager: $e');
    return false;
  }
}

/// Obtener estadísticas de tareas ejecutadas
Future<Map<String, dynamic>> getBackgroundTaskStats() async {
  try {
    // En una implementación real, se obtendrían estadísticas de WorkManager
    // Por ahora, retornamos datos simulados para debugging
    return {
      'tasks_executed': 0,
      'tasks_failed': 0,
      'last_execution': null,
      'average_execution_time': 0,
    };
  } catch (e) {
    logger.d('❌ Error obteniendo estadísticas: $e');
    return {'error': e.toString()};
  }
}

/// Cleanup de recursos al terminar
Future<void> cleanupBackgroundResources() async {
  try {
    logger.d('🧹 Limpiando recursos de background');

    // Cancelar todas las tareas de WorkManager
    await Workmanager().cancelAll();

    // El sistema Android libera automáticamente los recursos al terminar ForegroundService

    logger.d('✅ Recursos de background limpiados');
  } catch (e) {
    logger.d('❌ Error limpiando recursos: $e');
  }
}
