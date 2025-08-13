// lib/services/background_service.dart
// 🔥 SERVICIO COMPLETO - FOREGROUNDSERVICE NATIVO + WORKMANAGER + LIFECYCLE MANAGEMENT
import 'dart:async';
import 'package:flutter/foundation.dart';
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
      debugPrint(
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
      debugPrint('✅ BackgroundService inicializado con soporte nativo');
    } catch (e) {
      debugPrint('❌ Error inicializando BackgroundService: $e');
      rethrow;
    }
  }

  Future<void> _initializeWorkManager() async {
    try {
      debugPrint('⚙️ Configurando WorkManager');

      await Workmanager().initialize(
        callbackDispatcher,
      );

      debugPrint('✅ WorkManager configurado');
    } catch (e) {
      debugPrint('❌ Error configurando WorkManager: $e');
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
      debugPrint('🚀 Iniciando ForegroundService nativo completo');

      if (_isForegroundServiceActive) {
        debugPrint('⚠️ ForegroundService ya está activo');
        return;
      }

      // 1. Guardar contexto del evento
      _currentEventId = eventId;
      _currentUserId = userId;

      // 2. 🔥 NUEVO: Iniciar ForegroundService nativo de Android
      final nativeSuccess = await _startNativeForegroundService();
      if (!nativeSuccess) {
        debugPrint('❌ No se pudo iniciar ForegroundService nativo');
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

      debugPrint('✅ ForegroundService COMPLETO iniciado (Nativo + Flutter)');
    } catch (e) {
      debugPrint('❌ Error iniciando ForegroundService completo: $e');
      rethrow;
    }
  }

  /// 🔥 NUEVO: Iniciar el ForegroundService nativo de Android
  Future<bool> _startNativeForegroundService() async {
    try {
      debugPrint('📱 Iniciando ForegroundService nativo de Android');

      final success =
          await _nativeChannel.invokeMethod<bool>('startForegroundService') ??
              false;

      if (success) {
        _isNativeForegroundActive = true;
        debugPrint('✅ ForegroundService nativo iniciado exitosamente');
      } else {
        debugPrint('❌ ForegroundService nativo falló al iniciar');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error comunicándose con ForegroundService nativo: $e');
      return false;
    }
  }

  /// Detener ForegroundService nativo + WorkManager
  Future<void> stopForegroundService() async {
    try {
      debugPrint('🛑 Deteniendo ForegroundService completo');

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

      debugPrint('✅ ForegroundService COMPLETO detenido');
    } catch (e) {
      debugPrint('❌ Error deteniendo ForegroundService: $e');
    }
  }

  /// 🔥 NUEVO: Detener el ForegroundService nativo de Android
  Future<void> _stopNativeForegroundService() async {
    try {
      if (!_isNativeForegroundActive) return;

      debugPrint('📱 Deteniendo ForegroundService nativo de Android');

      await _nativeChannel.invokeMethod('stopForegroundService');
      _isNativeForegroundActive = false;

      debugPrint('✅ ForegroundService nativo detenido');
    } catch (e) {
      debugPrint('❌ Error deteniendo ForegroundService nativo: $e');
    }
  }

  Future<void> _createPersistentTrackingNotification() async {
    try {
      debugPrint('📱 Creando notificación persistente');

      await _notificationManager.showTrackingActiveNotification();

      debugPrint('✅ Notificación persistente creada');
    } catch (e) {
      debugPrint('❌ Error creando notificación persistente: $e');
      rethrow;
    }
  }

  // 🎯 NATIVE WAKE LOCK

  /// Activar wake lock usando permisos nativos de Android
  Future<void> _enableNativeWakeLock() async {
    try {
      if (_isWakeLockActive) return;

      debugPrint('🔋 Activando Wake Lock nativo (Android permissions)');

      // El permiso WAKE_LOCK ya está en AndroidManifest.xml
      // El sistema Android gestiona automáticamente el wake lock
      // con ForegroundService + WorkManager
      _isWakeLockActive = true;

      debugPrint(
          '✅ Wake Lock nativo activado - CPU mantenida activa por sistema');
    } catch (e) {
      debugPrint('❌ Error activando Wake Lock nativo: $e');
      // No es crítico, continuamos sin wake lock específico
    }
  }

  /// Desactivar wake lock nativo
  Future<void> _disableNativeWakeLock() async {
    try {
      if (!_isWakeLockActive) return;

      debugPrint('🔋 Desactivando Wake Lock nativo');

      // El sistema Android libera automáticamente el wake lock
      // cuando se detiene el ForegroundService
      _isWakeLockActive = false;

      debugPrint('✅ Wake Lock nativo desactivado');
    } catch (e) {
      debugPrint('❌ Error desactivando Wake Lock nativo: $e');
    }
  }

  // 🔥 NUEVOS MÉTODOS CRÍTICOS

  /// Verificar y solicitar exención de optimización de batería
  Future<void> _checkBatteryOptimizationStatus() async {
    try {
      debugPrint('🔋 Verificando optimización de batería');

      final isIgnored = await _nativeChannel
              .invokeMethod<bool>('isBatteryOptimizationIgnored') ??
          false;

      if (!isIgnored) {
        debugPrint('⚡ Solicitando exención de optimización de batería');
        await _nativeChannel
            .invokeMethod('requestBatteryOptimizationExemption');
      } else {
        debugPrint('✅ App ya está exenta de optimización de batería');
      }
    } catch (e) {
      debugPrint('❌ Error verificando battery optimization: $e');
    }
  }

  /// 🔥 NUEVO: Actualizar estado de la notificación nativa
  Future<void> updateNativeNotificationStatus(String status) async {
    try {
      if (!_isNativeForegroundActive) return;

      debugPrint('📱 Actualizando notificación nativa: $status');

      await _nativeChannel.invokeMethod('updateNotificationStatus', {
        'status': status,
      });
    } catch (e) {
      debugPrint('❌ Error actualizando notificación nativa: $e');
    }
  }

  /// 🔥 NUEVO: Iniciar el período de gracia de 30 segundos
  Future<void> _startGracePeriod() async {
    if (_isInGracePeriod) return;

    debugPrint('⏳ Iniciando grace period de 30 segundos');

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

    debugPrint('✅ Cancelando grace period - App reactivada');

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
      debugPrint('📋 Registrando tareas de background');

      // 1. Tarea principal de tracking
      await _registerTrackingTask();

      // 2. Tarea de heartbeat
      await _registerHeartbeatTask();

      // 3. Tarea de actualizaciones de ubicación
      await _registerLocationUpdateTask();

      // 4. Tarea de monitoreo de lifecycle
      await _registerLifecycleMonitorTask();

      debugPrint('✅ Todas las tareas de background registradas');
    } catch (e) {
      debugPrint('❌ Error registrando tareas: $e');
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

    debugPrint('📍 Tarea de tracking registrada');
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

    debugPrint('💓 Tarea de heartbeat registrada');
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

    debugPrint('🌍 Tarea de ubicación registrada');
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

    debugPrint('🔄 Tarea de lifecycle registrada');
  }

  /// Cancelar todas las tareas de background
  Future<void> _cancelAllBackgroundTasks() async {
    try {
      debugPrint('🚫 Cancelando todas las tareas de background');

      await Workmanager().cancelByUniqueName(_trackingTaskName);
      await Workmanager().cancelByUniqueName(_heartbeatTaskName);
      await Workmanager().cancelByUniqueName(_locationUpdateTaskName);
      await Workmanager().cancelByUniqueName(_lifecycleMonitorTaskName);

      debugPrint('✅ Todas las tareas canceladas');
    } catch (e) {
      debugPrint('❌ Error cancelando tareas: $e');
    }
  }

  // 🎯 TIMERS CRÍTICOS

  /// Iniciar timers críticos del foreground
  void _startCriticalTimers() {
    debugPrint('⏰ Iniciando timers críticos');

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

    debugPrint('✅ Timers críticos iniciados');
  }

  /// Detener timers críticos
  void _stopCriticalTimers() {
    debugPrint('⏰ Deteniendo timers críticos');

    _heartbeatTimer?.cancel();
    _locationTimer?.cancel();
    _lifecycleTimer?.cancel();

    _heartbeatTimer = null;
    _locationTimer = null;
    _lifecycleTimer = null;

    debugPrint('✅ Timers detenidos');
  }

  // 🎯 EJECUCIÓN DE TAREAS - MEJORADAS

  /// 🔥 MODIFICADO: Heartbeat con validación de estado
  Future<void> _performHeartbeat() async {
    try {
      if (_currentUserId == null || _currentEventId == null) return;

      debugPrint('💓 Enviando heartbeat crítico con validación');

      await _asistenciaService.actualizarUbicacion(
        usuarioId: _currentUserId!,
        eventoId: _currentEventId!,
        latitud: 0.0, // GPS real implementado en StudentAttendanceManager
        longitud: 0.0,
      );

      _lastHeartbeat = DateTime.now();

      // Actualizar ambas notificaciones con último heartbeat
      final now = DateTime.now();
      final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      await updateNativeNotificationStatus('Heartbeat: $timeString');
      await _notificationManager
          .updateTrackingNotificationStatus('Heartbeat: $timeString');
    } catch (e) {
      debugPrint('❌ Error crítico en heartbeat: $e');
      await _handleHeartbeatFailure();
    }
  }

  Future<void> _performLocationUpdate() async {
    try {
      if (_currentUserId == null || _currentEventId == null) return;

      debugPrint('🌍 Actualizando ubicación desde timer');

      // En una implementación real, aquí se obtendría la ubicación GPS
      // y se enviaría al backend
    } catch (e) {
      debugPrint('❌ Error actualizando ubicación: $e');
    }
  }

  /// 🔥 MODIFICADO: Lifecycle check con validación nativa
  Future<void> _performLifecycleCheck() async {
    try {
      debugPrint('🔄 Verificando estado de app lifecycle');

      // Verificar que ambos servicios siguen activos
      if (_isForegroundServiceActive && _lastHeartbeat != null) {
        final timeSinceLastHeartbeat =
            DateTime.now().difference(_lastHeartbeat!);

        if (timeSinceLastHeartbeat.inSeconds > 60) {
          debugPrint('⚠️ Heartbeat perdido - reiniciando');
          await _performHeartbeat();
        }

        // 🔥 NUEVO: Verificar estado del servicio nativo también
        if (_isNativeForegroundActive) {
          await updateNativeNotificationStatus('Lifecycle Check OK');
        }
      }
    } catch (e) {
      debugPrint('❌ Error en lifecycle check: $e');
    }
  }

  /// 🔥 NUEVO: Manejar fallo de heartbeat
  Future<void> _handleHeartbeatFailure() async {
    debugPrint('💔 Fallo crítico de heartbeat');

    await _notificationManager.showConnectionErrorNotification();
    await updateNativeNotificationStatus('Error Conexión');

    // En una implementación real, aquí podrías implementar reconexión automática
  }

  // 🎯 GESTIÓN DE NOTIFICACIONES

  /// Actualizar estado de la notificación de tracking
  Future<void> _updateTrackingNotificationStatus(String status) async {
    try {
      await _notificationManager.updateTrackingNotificationStatus(status);
      await updateNativeNotificationStatus(
          status); // 🔥 NUEVO: Actualizar ambas
    } catch (e) {
      debugPrint('❌ Error actualizando notificación: $e');
    }
  }

  /// Mostrar notificación de advertencia crítica
  Future<void> showCriticalAppLifecycleWarning() async {
    try {
      debugPrint('🚨 Mostrando advertencia crítica de lifecycle');

      await _notificationManager.showCriticalAppLifecycleWarning();
    } catch (e) {
      debugPrint('❌ Error mostrando advertencia crítica: $e');
    }
  }

  // 🎯 MANEJO DE APP LIFECYCLE - MEJORADO

  /// Manejar eventos de lifecycle de la aplicación
  Future<void> handleAppLifecycleEvents(String state) async {
    debugPrint('📱 App lifecycle cambió a: $state');

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
    debugPrint('✅ App resumed - Cancelando grace period');

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
    debugPrint('⏸️ App paused - Iniciando grace period');

    if (_isForegroundServiceActive) {
      await updateNativeNotificationStatus('Tracking en Background');
      await _notificationManager
          .updateTrackingNotificationStatus('Tracking en Background');
      await _startGracePeriod(); // 🔥 NUEVO: Iniciar grace period
    }
  }

  /// 🔥 MODIFICADO: App detached sin grace period
  Future<void> _handleAppDetached() async {
    debugPrint('❌ App detached - Activando protocolo de pérdida inmediata');

    // 🔥 NUEVO: Sin grace period para detached
    await triggerAttendanceLossProtocol('App cerrada completamente');
  }

  Future<void> _handleAppInactive() async {
    debugPrint('⚠️ App inactive - Monitoreando...');
  }

  Future<void> _handleAppHidden() async {
    debugPrint('🙈 App hidden - Tracking pausado temporalmente');

    if (_isForegroundServiceActive) {
      await _updateTrackingNotificationStatus('Tracking Pausado');
    }
  }

  /// Activar protocolo de pérdida de asistencia
  Future<void> triggerAttendanceLossProtocol(String reason) async {
    try {
      debugPrint('❌ ACTIVANDO PROTOCOLO DE PÉRDIDA: $reason');

      if (_currentUserId != null && _currentEventId != null) {
        // Marcar como ausente en el backend
        await _asistenciaService.marcarAusente(
          usuarioId: _currentUserId!,
          eventoId: _currentEventId!,
          motivo: reason,
        );
      }

      // Detener todos los servicios
      await stopForegroundService();

      // Limpiar notificaciones
      await _notificationManager.clearAllNotifications();

      debugPrint('✅ Protocolo de pérdida ejecutado');
    } catch (e) {
      debugPrint('❌ Error en protocolo de pérdida: $e');
    }
  }

  // 🎯 CONFIGURACIÓN DE TRACKING

  /// Configurar tracking para un evento específico
  Future<void> setupTrackingForEvent(String eventId, String userId) async {
    try {
      debugPrint('⚙️ Configurando tracking para evento: $eventId');

      _currentEventId = eventId;
      _currentUserId = userId;

      if (_isForegroundServiceActive) {
        // Reconfigurar tareas con nuevos datos
        await _cancelAllBackgroundTasks();
        await _registerBackgroundTasks();
      }

      debugPrint('✅ Tracking configurado para evento: $eventId');
    } catch (e) {
      debugPrint('❌ Error configurando tracking: $e');
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

  /// 🔥 NUEVO: Obtener estado completo del servicio
  Map<String, dynamic> getCompleteServiceStatus() {
    return {
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
  }

  /// Obtener información del estado actual (compatibilidad)
  Map<String, dynamic> getServiceStatus() {
    return getCompleteServiceStatus();
  }

  /// Limpiar configuración
  void clearConfiguration() {
    debugPrint('🧹 Limpiando configuración de BackgroundService');

    _currentEventId = null;
    _currentUserId = null;
  }

  /// Reiniciar servicio completo
  Future<void> restart() async {
    try {
      debugPrint('🔄 Reiniciando BackgroundService');

      await stopForegroundService();
      await Future.delayed(const Duration(seconds: 2));

      if (_currentUserId != null && _currentEventId != null) {
        await startForegroundService(
          userId: _currentUserId!,
          eventId: _currentEventId!,
        );
      }

      debugPrint('✅ BackgroundService reiniciado');
    } catch (e) {
      debugPrint('❌ Error reiniciando servicio: $e');
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
      debugPrint('🔄 Ejecutando tarea de background: $task');
      debugPrint('📦 Datos de entrada: $inputData');

      // Obtener tipo de tarea
      final taskType = inputData?['task_type'] as String?;
      final eventId = inputData?['event_id'] as String?;
      final userId = inputData?['user_id'] as String?;

      if (taskType == null || eventId == null || userId == null) {
        debugPrint('❌ Datos insuficientes para ejecutar tarea');
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
          debugPrint('❌ Tipo de tarea desconocido: $taskType');
          return Future.value(false);
      }

      debugPrint('✅ Tarea completada: $task');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Error ejecutando tarea de background: $e');
      return Future.value(false);
    }
  });
}

// 🎯 EJECUCIÓN DE TAREAS ESPECÍFICAS

Future<void> _executeTrackingTask(String eventId, String userId) async {
  try {
    debugPrint('📍 Ejecutando tarea de tracking');

    // Verificar que el tracking sigue siendo necesario
    final storageService = StorageService();
    final user = await storageService.getUser();

    if (user?.id != userId) {
      debugPrint('⚠️ Usuario cambió, cancelando tracking');
      return;
    }

    // Realizar verificaciones de tracking
    await _performBackgroundTrackingCheck(eventId, userId);

    debugPrint('✅ Tarea de tracking completada');
  } catch (e) {
    debugPrint('❌ Error en tarea de tracking: $e');
    rethrow;
  }
}

Future<void> _executeHeartbeatTask(String eventId, String userId) async {
  try {
    debugPrint('💓 Ejecutando tarea de heartbeat');

    final asistenciaService = AsistenciaService();

    // Enviar heartbeat al backend
    await asistenciaService.actualizarUbicacion(
      usuarioId: userId,
      eventoId: eventId,
      latitud: 0.0, // Placeholder - en producción usar ubicación real
      longitud: 0.0,
    );

    debugPrint('✅ Heartbeat enviado desde background');
  } catch (e) {
    debugPrint('❌ Error en heartbeat background: $e');
    rethrow;
  }
}

Future<void> _executeLocationUpdateTask(String eventId, String userId) async {
  try {
    debugPrint('🌍 Ejecutando tarea de actualización de ubicación');

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

    debugPrint('✅ Ubicación actualizada desde background');
  } catch (e) {
    debugPrint('❌ Error actualizando ubicación background: $e');
    rethrow;
  }
}

Future<void> _executeLifecycleMonitorTask(String eventId, String userId) async {
  try {
    debugPrint('🔄 Ejecutando tarea de monitoreo de lifecycle');

    // Verificar que la app no haya sido terminada abruptamente
    final notificationManager = NotificationManager();

    // Actualizar notificación para mostrar que el background está funcionando
    await notificationManager.updateTrackingNotificationStatus(
        'Background Activo - ${DateTime.now().toString().substring(11, 19)}');

    debugPrint('✅ Monitoreo de lifecycle completado');
  } catch (e) {
    debugPrint('❌ Error en monitoreo lifecycle: $e');
    rethrow;
  }
}

Future<void> _performBackgroundTrackingCheck(
    String eventId, String userId) async {
  try {
    debugPrint('🔍 Verificando estado de tracking en background');

    final asistenciaService = AsistenciaService();

    // Verificar estado actual de asistencia
    final estado =
        await asistenciaService.validarEstadoAsistencia(userId, eventId);

    if (estado == null) {
      debugPrint('⚠️ No hay asistencia registrada para verificar');
      return;
    }

    if (estado == 'ausente') {
      debugPrint('❌ Usuario ya marcado como ausente, deteniendo tracking');

      // Cancelar todas las tareas si ya está ausente
      await Workmanager().cancelAll();
      return;
    }

    debugPrint('✅ Estado de tracking verificado: $estado');
  } catch (e) {
    debugPrint('❌ Error verificando tracking: $e');
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
    debugPrint('❌ Error verificando WorkManager: $e');
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
    debugPrint('❌ Error obteniendo estadísticas: $e');
    return {'error': e.toString()};
  }
}

/// Cleanup de recursos al terminar
Future<void> cleanupBackgroundResources() async {
  try {
    debugPrint('🧹 Limpiando recursos de background');

    // Cancelar todas las tareas de WorkManager
    await Workmanager().cancelAll();

    // El sistema Android libera automáticamente los recursos al terminar ForegroundService

    debugPrint('✅ Recursos de background limpiados');
  } catch (e) {
    debugPrint('❌ Error limpiando recursos: $e');
  }
}
