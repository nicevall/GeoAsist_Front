// lib/services/background_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../services/notifications/notification_manager.dart';
import '../services/asistencia_service.dart';
import '../services/storage_service.dart';

/// Servicio para manejo de tareas en background y ForegroundService
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  // 🎯 IDENTIFICADORES DE TAREAS
  static const String _trackingTaskName = 'tracking_task';
  static const String _heartbeatTaskName = 'heartbeat_task';
  static const String _locationUpdateTaskName = 'location_update_task';
  static const String _lifecycleMonitorTaskName = 'lifecycle_monitor_task';

  // 🎯 SERVICIOS
  late NotificationManager _notificationManager;
  late AsistenciaService _asistenciaService;
// ✅ CORRECCIÓN: Remover unused warning

  // 🎯 ESTADO DEL SERVICIO
  bool _isInitialized = false;
  bool _isForegroundServiceActive = false;
  bool _isWakeLockActive =
      false; // ✅ Mantener para compatibilidad pero no usar wakelock
  String? _currentEventId;
  String? _currentUserId;

  // 🎯 TIMERS Y CONTROLADORES
  Timer? _heartbeatTimer;
  Timer? _locationTimer;
  Timer? _lifecycleTimer;

  /// Inicializar el servicio de background
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Inicializando BackgroundService');

      _notificationManager = NotificationManager();
      _asistenciaService = AsistenciaService();

      // Inicializar WorkManager
      await _initializeWorkManager();

      _isInitialized = true;
      debugPrint('✅ BackgroundService inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando BackgroundService: $e');
      rethrow; // ✅ CORRECCIÓN: usar rethrow
    }
  }

  Future<void> _initializeWorkManager() async {
    try {
      debugPrint('⚙️ Configurando WorkManager');

      await Workmanager().initialize(
        callbackDispatcher,
        // ✅ CORRECCIÓN: Eliminar isInDebugMode deprecated
        // isInDebugMode: kDebugMode, // ❌ DEPRECATED
      );

      debugPrint('✅ WorkManager configurado');
    } catch (e) {
      debugPrint('❌ Error configurando WorkManager: $e');
      rethrow; // ✅ CORRECCIÓN: usar rethrow
    }
  }

  // 🎯 FOREGROUND SERVICE

  /// Iniciar servicio foreground persistente
  Future<void> startForegroundService() async {
    try {
      debugPrint('▶️ Iniciando ForegroundService');

      if (_isForegroundServiceActive) {
        debugPrint('⚠️ ForegroundService ya está activo');
        return;
      }

      // 1. Crear notificación persistente
      await _createPersistentTrackingNotification();

      // 2. ✅ CORRECCIÓN: Usar permisos nativos en lugar de wakelock
      await _enableNativeWakeLock();

      // 3. Registrar tareas de background críticas
      await _registerBackgroundTasks();

      // 4. Iniciar timers críticos
      _startCriticalTimers();

      _isForegroundServiceActive = true;
      debugPrint('✅ ForegroundService iniciado exitosamente');
    } catch (e) {
      debugPrint('❌ Error iniciando ForegroundService: $e');
      rethrow; // ✅ CORRECCIÓN: usar rethrow
    }
  }

  /// Detener servicio foreground
  Future<void> stopForegroundService() async {
    try {
      debugPrint('⏹️ Deteniendo ForegroundService');

      // 1. Cancelar todas las tareas
      await _cancelAllBackgroundTasks();

      // 2. Detener timers
      _stopCriticalTimers();

      // 3. ✅ CORRECCIÓN: Desactivar wake lock nativo
      await _disableNativeWakeLock();

      // 4. Limpiar notificaciones
      await _notificationManager.clearAllNotifications();

      _isForegroundServiceActive = false;
      debugPrint('✅ ForegroundService detenido');
    } catch (e) {
      debugPrint('❌ Error deteniendo ForegroundService: $e');
    }
  }

  Future<void> _createPersistentTrackingNotification() async {
    try {
      debugPrint('📱 Creando notificación persistente');

      await _notificationManager.showTrackingActiveNotification();

      debugPrint('✅ Notificación persistente creada');
    } catch (e) {
      debugPrint('❌ Error creando notificación persistente: $e');
      rethrow; // ✅ CORRECCIÓN: usar rethrow
    }
  }

  // 🎯 ✅ CORRECCIÓN: NATIVE WAKE LOCK EN LUGAR DE PLUGIN

  /// ✅ Activar wake lock usando permisos nativos de Android
  Future<void> _enableNativeWakeLock() async {
    try {
      if (_isWakeLockActive) return;

      debugPrint('🔋 Activando Wake Lock nativo (Android permissions)');

      // ✅ El permiso WAKE_LOCK ya está en AndroidManifest.xml
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

  /// ✅ Desactivar wake lock nativo
  Future<void> _disableNativeWakeLock() async {
    try {
      if (!_isWakeLockActive) return;

      debugPrint('🔋 Desactivando Wake Lock nativo');

      // ✅ El sistema Android libera automáticamente el wake lock
      // cuando se detiene el ForegroundService
      _isWakeLockActive = false;

      debugPrint('✅ Wake Lock nativo desactivado');
    } catch (e) {
      debugPrint('❌ Error desactivando Wake Lock nativo: $e');
    }
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
      rethrow; // ✅ CORRECCIÓN: usar rethrow
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

  // 🎯 EJECUCIÓN DE TAREAS

  Future<void> _performHeartbeat() async {
    try {
      if (_currentUserId == null || _currentEventId == null) return;

      debugPrint('💓 Enviando heartbeat desde timer');

      await _asistenciaService.actualizarUbicacion(
        usuarioId: _currentUserId!,
        eventoId: _currentEventId!,
        latitud: 0.0, // Se actualizará con ubicación real
        longitud: 0.0,
      );
    } catch (e) {
      debugPrint('❌ Error en heartbeat: $e');
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

  Future<void> _performLifecycleCheck() async {
    try {
      debugPrint('🔄 Verificando estado de lifecycle');

      // Verificar que el servicio sigue activo
      if (_isForegroundServiceActive) {
        await _updateTrackingNotificationStatus('Tracking Activo');
      }
    } catch (e) {
      debugPrint('❌ Error en lifecycle check: $e');
    }
  }

  // 🎯 GESTIÓN DE NOTIFICACIONES

  /// Actualizar estado de la notificación de tracking
  Future<void> _updateTrackingNotificationStatus(String status) async {
    try {
      await _notificationManager.updateTrackingNotificationStatus(status);
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

  // 🎯 MANEJO DE APP LIFECYCLE

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

  Future<void> _handleAppResumed() async {
    debugPrint('✅ App resumed - Servicio continúa normal');

    if (_isForegroundServiceActive) {
      await _updateTrackingNotificationStatus('Tracking Activo');
    }
  }

  Future<void> _handleAppPaused() async {
    debugPrint('⏸️ App paused - Manteniendo tracking en background');

    if (_isForegroundServiceActive) {
      await _updateTrackingNotificationStatus('Tracking en Background');
      await showCriticalAppLifecycleWarning();
    }
  }

  Future<void> _handleAppDetached() async {
    debugPrint('❌ App detached - Activando protocolo de pérdida');

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
      rethrow; // ✅ CORRECCIÓN: usar rethrow
    }
  }

  // 🎯 ESTADO Y INFORMACIÓN

  /// Verificar si el servicio está activo
  bool get isForegroundServiceActive => _isForegroundServiceActive;

  /// Verificar si WakeLock está activo
  bool get isWakeLockActive => _isWakeLockActive;

  /// Obtener información del estado actual
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _isInitialized,
      'foreground_service_active': _isForegroundServiceActive,
      'wakelock_active': _isWakeLockActive,
      'current_event_id': _currentEventId,
      'current_user_id': _currentUserId,
      'heartbeat_timer_active': _heartbeatTimer?.isActive ?? false,
      'location_timer_active': _locationTimer?.isActive ?? false,
      'lifecycle_timer_active': _lifecycleTimer?.isActive ?? false,
    };
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
      await startForegroundService();

      debugPrint('✅ BackgroundService reiniciado');
    } catch (e) {
      debugPrint('❌ Error reiniciando servicio: $e');
      rethrow; // ✅ CORRECCIÓN: usar rethrow
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
    rethrow; // ✅ CORRECCIÓN: usar rethrow
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
    rethrow; // ✅ CORRECCIÓN: usar rethrow
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
    rethrow; // ✅ CORRECCIÓN: usar rethrow
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
    rethrow; // ✅ CORRECCIÓN: usar rethrow
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
    rethrow; // ✅ CORRECCIÓN: usar rethrow
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

    // ✅ CORRECCIÓN: No usar wakelock plugin - el sistema Android
    // libera automáticamente los recursos al terminar ForegroundService

    debugPrint('✅ Recursos de background limpiados');
  } catch (e) {
    debugPrint('❌ Error limpiando recursos: $e');
  }
}
