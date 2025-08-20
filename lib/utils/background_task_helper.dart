//lib/utils/background_task_helper.dart
// 🎯 HELPER DE TAREAS EN BACKGROUND FASE A1.2 - Preparado para optimizaciones A1.3
import 'package:flutter/foundation.dart';
import 'dart:async';

class BackgroundTaskHelper {
  static final BackgroundTaskHelper _instance =
      BackgroundTaskHelper._internal();
  factory BackgroundTaskHelper() => _instance;
  BackgroundTaskHelper._internal();

  // 🎯 ESTADO DEL HELPER
  bool _isInitialized = false;
  final Map<String, Timer> _activeTasks = {};
  final Map<String, DateTime> _taskLastExecution = {};

  // 🎯 CONFIGURACIÓN DE OPTIMIZACIÓN
  static const Duration _batteryOptimizedInterval = Duration(minutes: 2);
  static const Duration _normalInterval = Duration(seconds: 30);
  static const Duration _highFrequencyInterval = Duration(seconds: 15);

  // 🎯 INICIALIZACIÓN
  Future<void> initialize() async {
    debugPrint('🔧 Inicializando BackgroundTaskHelper');

    try {
      _isInitialized = true;
      debugPrint('✅ BackgroundTaskHelper inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando background helper: $e');
    }
  }

  // 🎯 GESTIÓN DE TAREAS PERIÓDICAS

  /// Programar una tarea periódica con optimización inteligente
  void schedulePeriodicTask({
    required String taskId,
    required Duration interval,
    required Future<void> Function() task,
    BackgroundTaskPriority priority = BackgroundTaskPriority.normal,
    bool respectBatteryOptimization = true,
  }) {
    if (!_isInitialized) {
      debugPrint('⚠️ BackgroundTaskHelper no inicializado');
      return;
    }

    // Cancelar tarea existente si existe
    cancelTask(taskId);

    // Determinar intervalo optimizado
    final optimizedInterval = _getOptimizedInterval(
      interval,
      priority,
      respectBatteryOptimization,
    );

    debugPrint(
        '📅 Programando tarea: $taskId (${optimizedInterval.inSeconds}s)');

    // Crear timer con la tarea optimizada
    final timer = Timer.periodic(optimizedInterval, (_) async {
      await _executeTaskWithOptimization(taskId, task, priority);
    });

    _activeTasks[taskId] = timer;
    debugPrint('✅ Tarea programada: $taskId');
  }

  /// Cancelar una tarea específica
  void cancelTask(String taskId) {
    final timer = _activeTasks.remove(taskId);
    if (timer != null) {
      timer.cancel();
      _taskLastExecution.remove(taskId);
      debugPrint('🛑 Tarea cancelada: $taskId');
    }
  }

  /// Cancelar todas las tareas
  void cancelAllTasks() {
    debugPrint('🧹 Cancelando todas las tareas en background');

    for (final timer in _activeTasks.values) {
      timer.cancel();
    }

    _activeTasks.clear();
    _taskLastExecution.clear();

    debugPrint('✅ Todas las tareas canceladas');
  }

  /// Obtener información de tareas activas
  Map<String, dynamic> getTasksInfo() {
    return {
      'totalTasks': _activeTasks.length,
      'activeTasks': _activeTasks.keys.toList(),
      'lastExecutions': _taskLastExecution,
      'isInitialized': _isInitialized,
    };
  }

  // 🎯 TAREAS ESPECÍFICAS DEL SISTEMA DE ASISTENCIA

  /// Tarea optimizada para tracking de ubicación
  void scheduleLocationTrackingTask({
    required Future<void> Function() locationUpdateCallback,
    bool isEventActive = false,
    bool isUserInsideGeofence = true,
  }) {
    final priority = _determineLocationTrackingPriority(
      isEventActive,
      isUserInsideGeofence,
    );

    final interval = _determineLocationTrackingInterval(
      isEventActive,
      isUserInsideGeofence,
    );

    schedulePeriodicTask(
      taskId: 'location_tracking',
      interval: interval,
      task: locationUpdateCallback,
      priority: priority,
      respectBatteryOptimization:
          !isEventActive, // Menos optimización si hay evento activo
    );
  }

  /// Tarea para sincronización de datos
  void scheduleDataSyncTask({
    required Future<void> Function() syncCallback,
    bool isHighPriority = false,
  }) {
    schedulePeriodicTask(
      taskId: 'data_sync',
      interval: isHighPriority
          ? const Duration(minutes: 1)
          : const Duration(minutes: 5),
      task: syncCallback,
      priority: isHighPriority
          ? BackgroundTaskPriority.high
          : BackgroundTaskPriority.low,
    );
  }

  /// Tarea para limpieza de cache y memoria
  void scheduleCleanupTask({
    required Future<void> Function() cleanupCallback,
  }) {
    schedulePeriodicTask(
      taskId: 'cleanup',
      interval: const Duration(minutes: 15),
      task: cleanupCallback,
      priority: BackgroundTaskPriority.low,
    );
  }

  // 🎯 MÉTODOS PRIVADOS DE OPTIMIZACIÓN

  Duration _getOptimizedInterval(
    Duration baseInterval,
    BackgroundTaskPriority priority,
    bool respectBatteryOptimization,
  ) {
    if (!respectBatteryOptimization) {
      return baseInterval;
    }

    // Aplicar optimización basada en la prioridad
    switch (priority) {
      case BackgroundTaskPriority.critical:
        return baseInterval; // Sin cambios para tareas críticas
      case BackgroundTaskPriority.high:
        return Duration(
          milliseconds: (baseInterval.inMilliseconds * 1.2).round(),
        );
      case BackgroundTaskPriority.normal:
        return Duration(
          milliseconds: (baseInterval.inMilliseconds * 1.5).round(),
        );
      case BackgroundTaskPriority.low:
        return Duration(
          milliseconds: (baseInterval.inMilliseconds * 2.0).round(),
        );
    }
  }

  Future<void> _executeTaskWithOptimization(
    String taskId,
    Future<void> Function() task,
    BackgroundTaskPriority priority,
  ) async {
    final startTime = DateTime.now();

    try {
      // Verificar si es momento apropiado para ejecutar
      if (_shouldSkipExecution(taskId, priority)) {
        return;
      }

      debugPrint('⚡ Ejecutando tarea: $taskId');

      // Ejecutar la tarea
      await task();

      // Registrar ejecución exitosa
      _taskLastExecution[taskId] = startTime;

      final executionTime = DateTime.now().difference(startTime);
      debugPrint(
          '✅ Tarea completada: $taskId (${executionTime.inMilliseconds}ms)');
    } catch (e) {
      debugPrint('❌ Error en tarea $taskId: $e');

      // Manejar errores según la prioridad
      _handleTaskError(taskId, e, priority);
    }
  }

  bool _shouldSkipExecution(String taskId, BackgroundTaskPriority priority) {
    // Para tareas críticas, nunca omitir
    if (priority == BackgroundTaskPriority.critical) {
      return false;
    }

    // ✅ Implementación básica de optimización (simplificada para evitar async)
    // En implementación completa, esto sería async
    return false;
  }

  void _handleTaskError(
      String taskId, dynamic error, BackgroundTaskPriority priority) {
    switch (priority) {
      case BackgroundTaskPriority.critical:
        debugPrint('🚨 Error crítico en tarea $taskId: $error');
        // ✅ Implementación básica - error crítico logueado
        break;
      case BackgroundTaskPriority.high:
        debugPrint('⚠️ Error en tarea de alta prioridad $taskId: $error');
        break;
      default:
        debugPrint('ℹ️ Error en tarea $taskId: $error');
        break;
    }
  }

  BackgroundTaskPriority _determineLocationTrackingPriority(
    bool isEventActive,
    bool isUserInsideGeofence,
  ) {
    if (isEventActive && !isUserInsideGeofence) {
      return BackgroundTaskPriority.critical; // Usuario fuera durante evento
    } else if (isEventActive) {
      return BackgroundTaskPriority.high; // Evento activo
    } else {
      return BackgroundTaskPriority.normal; // Sin evento activo
    }
  }

  Duration _determineLocationTrackingInterval(
    bool isEventActive,
    bool isUserInsideGeofence,
  ) {
    if (isEventActive && !isUserInsideGeofence) {
      return _highFrequencyInterval; // Tracking frecuente si está fuera
    } else if (isEventActive) {
      return _normalInterval; // Tracking normal durante evento
    } else {
      return _batteryOptimizedInterval; // Tracking optimizado sin evento
    }
  }

  // 🎯 MÉTODOS PARA FUTURAS OPTIMIZACIONES (A1.3)

  // TODO: Implementar en A1.3
  // Future<bool> _isBatteryOptimizationEnabled() async {
  //   // Detectar configuraciones de ahorro de batería
  //   return false;
  // }

  // TODO: Implementar en A1.3
  // Future<bool> _isConnectedToWifi() async {
  //   // Detectar tipo de conexión
  //   return false;
  // }

  // TODO: Implementar en A1.3
  // Future<void> _adjustTasksForPowerState() async {
  //   // Ajustar frecuencia según estado de energía
  // }


  // 🎯 CLEANUP Y DISPOSE
  void dispose() {
    debugPrint('🧹 Limpiando BackgroundTaskHelper');
    cancelAllTasks();
    _isInitialized = false;
  }
}

// 🎯 ENUM PARA PRIORIDAD DE TAREAS
enum BackgroundTaskPriority {
  critical, // Tareas críticas que no se pueden omitir
  high, // Tareas importantes con alta frecuencia
  normal, // Tareas regulares con frecuencia estándar
  low, // Tareas de mantenimiento con baja frecuencia
}
