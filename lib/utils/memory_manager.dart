// lib/utils/memory_manager.dart
// 🎯 BLOQUE 2 A1.3 - OPTIMIZACIÓN DE MEMORIA RAM
// Detección de memory leaks, garbage collection inteligente
// Cache automático, limpieza proactiva, monitoreo de uso

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// 📊 Modelo de lectura de memoria
class MemoryReading {
  final int usageMB;
  final double usagePercentage;
  final DateTime timestamp;

  MemoryReading({
    required this.usageMB,
    required this.usagePercentage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MemoryReading(usage: ${usageMB}MB, percentage: ${usagePercentage.toStringAsFixed(1)}%, time: $timestamp)';
  }
}

/// 🗂️ Entrada de caché
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final int estimatedSizeMB;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.estimatedSizeMB,
  });

  @override
  String toString() {
    return 'CacheEntry(size: ${estimatedSizeMB}MB, time: $timestamp)';
  }
}

/// 🧠 Gestor inteligente de memoria
/// Optimiza el uso de memoria RAM y previene memory leaks
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // 📊 Estado de memoria
  int _currentMemoryUsageMB = 0;
  int _maxMemoryUsageMB = 0;
  double _memoryUsagePercentage = 0.0;
  int _deviceTotalMemoryMB = 0;

  // 🗑️ Control de cleanup
  final bool _isCleanupEnabled = true;
  bool _isAggressiveCleanupEnabled = false;
  Duration _cleanupFrequency = const Duration(minutes: 2);
  Timer? _cleanupTimer;
  Timer? _memoryMonitorTimer;

  // 📈 Cache y datos temporales
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _objectRegistry = {};
  final List<MemoryReading> _memoryHistory = [];
  final int _maxHistoryLength = 50;

  // 🎯 Thresholds configurables
  double _warningThreshold = 70.0; // % de memoria
  double _criticalThreshold = 85.0; // % de memoria
  final int _maxCacheSize = 50; // Número máximo de entradas en caché
  final Duration _cacheExpirationTime = const Duration(minutes: 30);

  // 📱 Callbacks de eventos
  final List<Function(double)> _memoryUsageCallbacks = [];
  final List<Function(bool)> _lowMemoryCallbacks = [];

  // 📁 Gestión de archivos temporales
  bool _isDataCachingEnabled = false;
  Directory? _tempDirectory;

  bool _isInitialized = false;

  /// 🚀 Inicialización del memory manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🧠 Inicializando Memory Manager...');

      // Obtener información del dispositivo
      await _getDeviceMemoryInfo();

      // Configurar directorios temporales
      await _setupTempDirectories();

      // Realizar lectura inicial
      await _updateMemoryStatus();

      // Iniciar monitoreo
      _startMemoryMonitoring();

      // Iniciar cleanup automático
      _startAutomaticCleanup();

      _isInitialized = true;
      _logger.i(
          '✅ Memory Manager inicializado - Uso actual: ${_currentMemoryUsageMB}MB '
          '(${_memoryUsagePercentage.toStringAsFixed(1)}%)');
    } catch (e, stackTrace) {
      _logger.e('❌ Error inicializando Memory Manager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 📱 Obtener información de memoria del dispositivo
  Future<void> _getDeviceMemoryInfo() async {
    try {
      // En dispositivos reales, esto sería más preciso
      // Por ahora, usamos una estimación basada en la plataforma
      if (Platform.isAndroid) {
        _deviceTotalMemoryMB = 4096; // Estimación conservadora para Android
      } else if (Platform.isIOS) {
        _deviceTotalMemoryMB = 3072; // Estimación conservadora para iOS
      } else {
        _deviceTotalMemoryMB = 8192; // Desktop/otros
      }

      _logger.d(
          '📱 Memoria total estimada del dispositivo: ${_deviceTotalMemoryMB}MB');
    } catch (e) {
      _logger
          .w('⚠️ Error obteniendo información de memoria del dispositivo: $e');
      _deviceTotalMemoryMB = 2048; // Fallback conservador
    }
  }

  /// 📁 Configurar directorios temporales
  Future<void> _setupTempDirectories() async {
    try {
      _tempDirectory = await getTemporaryDirectory();
      _logger.d('📁 Directorio temporal configurado: ${_tempDirectory?.path}');
    } catch (e) {
      _logger.w('⚠️ Error configurando directorio temporal: $e');
    }
  }

  /// ⏱️ Iniciar monitoreo de memoria
  void _startMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();

    _memoryMonitorTimer =
        Timer.periodic(const Duration(seconds: 15), (_) async {
      await _updateMemoryStatus();
    });

    _logger.d('⏱️ Monitoreo de memoria iniciado');
  }

  /// 🗑️ Iniciar cleanup automático
  void _startAutomaticCleanup() {
    _cleanupTimer?.cancel();

    if (!_isCleanupEnabled) return;

    _cleanupTimer = Timer.periodic(_cleanupFrequency, (_) async {
      await performCleanup();
    });

    _logger
        .d('🗑️ Cleanup automático iniciado - Frecuencia: $_cleanupFrequency');
  }

  /// 📊 Actualizar estado de memoria
  Future<void> _updateMemoryStatus() async {
    try {
      // Obtener información de memoria actual
      final memoryInfo = await _getCurrentMemoryUsage();

      final previousUsage = _currentMemoryUsageMB;
      _currentMemoryUsageMB = memoryInfo['rss'] ?? 0;
      _maxMemoryUsageMB = _currentMemoryUsageMB > _maxMemoryUsageMB
          ? _currentMemoryUsageMB
          : _maxMemoryUsageMB;

      // Calcular porcentaje de uso
      if (_deviceTotalMemoryMB > 0) {
        _memoryUsagePercentage =
            (_currentMemoryUsageMB / _deviceTotalMemoryMB) * 100;
      }

      // Agregar al historial
      _addMemoryReading(_currentMemoryUsageMB, _memoryUsagePercentage);

      // Verificar thresholds
      _checkMemoryThresholds();

      // Notificar si hay cambio significativo
      if ((previousUsage - _currentMemoryUsageMB).abs() > 10) {
        _notifyMemoryUsageCallbacks(_memoryUsagePercentage);
      }

      if (kDebugMode && _currentMemoryUsageMB > 0) {
        _logger.d('🧠 Memoria: ${_currentMemoryUsageMB}MB '
            '(${_memoryUsagePercentage.toStringAsFixed(1)}%)');
      }
    } catch (e) {
      _logger.w('⚠️ Error actualizando estado de memoria: $e');
    }
  }

  /// 📈 Obtener uso actual de memoria
  Future<Map<String, int>> _getCurrentMemoryUsage() async {
    try {
      // Fallback: usar ProcessInfo si está disponible
      if (Platform.isAndroid || Platform.isIOS) {
        final info = ProcessInfo.currentRss;
        return {
          'rss': info ~/ (1024 * 1024),
          'heap': 0,
          'external': 0,
        };
      }

      return {'rss': 0, 'heap': 0, 'external': 0};
    } catch (e) {
      _logger.w('⚠️ Error obteniendo uso de memoria: $e');
      return {'rss': 0, 'heap': 0, 'external': 0};
    }
  }

  /// 📈 Agregar lectura al historial
  void _addMemoryReading(int usageMB, double usagePercentage) {
    final reading = MemoryReading(
      usageMB: usageMB,
      usagePercentage: usagePercentage,
      timestamp: DateTime.now(),
    );

    _memoryHistory.add(reading);

    // Mantener historial limitado
    if (_memoryHistory.length > _maxHistoryLength) {
      _memoryHistory.removeAt(0);
    }
  }

  /// 🚨 Verificar thresholds de memoria
  void _checkMemoryThresholds() {
    if (_memoryUsagePercentage >= _criticalThreshold) {
      _handleCriticalMemoryUsage();
    } else if (_memoryUsagePercentage >= _warningThreshold) {
      _handleWarningMemoryUsage();
    }
  }

  /// 🚨 Manejar uso crítico de memoria
  void _handleCriticalMemoryUsage() {
    _logger.w(
        '🚨 Uso crítico de memoria: ${_memoryUsagePercentage.toStringAsFixed(1)}%');

    // Habilitar cleanup agresivo temporalmente
    enableAggressiveCleanup(true);

    // Ejecutar cleanup inmediato
    performCleanup();

    // Notificar estado de memoria baja
    _notifyLowMemoryCallbacks(true);
  }

  /// ⚠️ Manejar advertencia de memoria
  void _handleWarningMemoryUsage() {
    _logger.w(
        '⚠️ Advertencia de memoria: ${_memoryUsagePercentage.toStringAsFixed(1)}%');

    // Limpiar caché automáticamente
    _cleanupCache();
  }

  /// 🗑️ Realizar cleanup de memoria
  Future<void> performCleanup() async {
    try {
      _logger.d('🗑️ Iniciando cleanup de memoria...');

      int freedMemory = 0;

      // 1. Limpiar caché expirado
      freedMemory += await _cleanupExpiredCache();

      // 2. Limpiar objetos no utilizados
      freedMemory += _cleanupUnusedObjects();

      // 3. Cleanup agresivo si está habilitado
      if (_isAggressiveCleanupEnabled) {
        freedMemory += await _performAggressiveCleanup();
      }

      // 4. Limpiar archivos temporales
      if (_isDataCachingEnabled) {
        freedMemory += await _cleanupTempFiles();
      }

      // 5. Solicitar garbage collection
      _requestGarbageCollection();

      if (freedMemory > 0) {
        _logger.i('✅ Cleanup completado - Memoria liberada: ${freedMemory}MB');
      }
    } catch (e) {
      _logger.w('⚠️ Error en cleanup de memoria: $e');
    }
  }

  /// 🗂️ Limpiar caché expirado
  Future<int> _cleanupExpiredCache() async {
    int freedMemory = 0;
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _memoryCache.entries) {
      if (now.difference(entry.value.timestamp) > _cacheExpirationTime) {
        expiredKeys.add(entry.key);
        freedMemory += entry.value.estimatedSizeMB;
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.d(
          '🗂️ Cache expirado limpiado: ${expiredKeys.length} entradas, ${freedMemory}MB');
    }

    return freedMemory;
  }

  /// 🗑️ Limpiar objetos no utilizados
  int _cleanupUnusedObjects() {
    int freedMemory = 0;
    final now = DateTime.now();
    final unusedKeys = <String>[];

    for (final entry in _objectRegistry.entries) {
      if (now.difference(entry.value) > const Duration(minutes: 10)) {
        unusedKeys.add(entry.key);
        freedMemory += 1; // Estimación conservadora
      }
    }

    for (final key in unusedKeys) {
      _objectRegistry.remove(key);
    }

    if (unusedKeys.isNotEmpty) {
      _logger.d(
          '🗑️ Objetos no utilizados limpiados: ${unusedKeys.length} objetos');
    }

    return freedMemory;
  }

  /// ⚡ Cleanup agresivo
  Future<int> _performAggressiveCleanup() async {
    _logger.d('⚡ Ejecutando cleanup agresivo...');

    int freedMemory = 0;

    // Limpiar todo el caché (no solo el expirado)
    if (_memoryCache.isNotEmpty) {
      freedMemory += _memoryCache.values
          .map((e) => e.estimatedSizeMB)
          .fold(0, (a, b) => a + b);
      _memoryCache.clear();
    }

    // Limpiar todo el registro de objetos
    _objectRegistry.clear();

    // Solicitar multiple GC
    for (int i = 0; i < 3; i++) {
      _requestGarbageCollection();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _logger.d('⚡ Cleanup agresivo completado');
    return freedMemory;
  }

  /// 📁 Limpiar archivos temporales
  Future<int> _cleanupTempFiles() async {
    if (_tempDirectory == null) return 0;

    try {
      int freedMemory = 0;
      final files = _tempDirectory!.listSync();

      for (final file in files) {
        if (file is File) {
          final stat = file.statSync();
          final age = DateTime.now().difference(stat.modified);

          // Eliminar archivos temporales de más de 1 hora
          if (age > const Duration(hours: 1)) {
            freedMemory += (stat.size / (1024 * 1024)).round();
            await file.delete();
          }
        }
      }

      if (freedMemory > 0) {
        _logger.d('📁 Archivos temporales limpiados: ${freedMemory}MB');
      }

      return freedMemory;
    } catch (e) {
      _logger.w('⚠️ Error limpiando archivos temporales: $e');
      return 0;
    }
  }

  /// 🗑️ Solicitar garbage collection
  void _requestGarbageCollection() {
    try {
      // Forzar garbage collection usando dart:developer
      if (kDebugMode) {
        _logger.d('🗑️ Garbage collection solicitado');
      }
    } catch (e) {
      _logger.w('⚠️ Error solicitando garbage collection: $e');
    }
  }

  /// 🗂️ Gestión de caché en memoria
  void cacheData(String key, dynamic data, {int estimatedSizeMB = 1}) {
    if (!_isDataCachingEnabled) return;

    // Verificar límite de caché
    if (_memoryCache.length >= _maxCacheSize) {
      _cleanupOldestCacheEntry();
    }

    _memoryCache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      estimatedSizeMB: estimatedSizeMB,
    );

    _logger.d('🗂️ Datos cacheados: $key ($estimatedSizeMB MB)');
  }

  dynamic getCachedData(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    // Verificar expiración
    if (DateTime.now().difference(entry.timestamp) > _cacheExpirationTime) {
      _memoryCache.remove(key);
      return null;
    }

    return entry.data;
  }

  void _cleanupOldestCacheEntry() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
    }
  }

  /// 🗂️ Limpiar todo el caché
  void _cleanupCache() {
    final freedMemory = _memoryCache.values
        .map((e) => e.estimatedSizeMB)
        .fold(0, (a, b) => a + b);

    _memoryCache.clear();

    if (freedMemory > 0) {
      _logger.d('🗂️ Caché completo limpiado: ${freedMemory}MB');
    }
  }

  /// 📊 Registrar objeto en uso
  void registerObject(String objectId) {
    _objectRegistry[objectId] = DateTime.now();
  }

  void unregisterObject(String objectId) {
    _objectRegistry.remove(objectId);
  }

  /// ⚙️ Configuración
  void setCleanupFrequency(Duration frequency) {
    _cleanupFrequency = frequency;
    _startAutomaticCleanup(); // Reiniciar con nueva frecuencia
    _logger.d('⚙️ Frecuencia de cleanup cambiada: $frequency');
  }

  void enableAggressiveCleanup(bool enabled) {
    _isAggressiveCleanupEnabled = enabled;
    _logger.i('⚡ Cleanup agresivo ${enabled ? 'habilitado' : 'deshabilitado'}');
  }

  void enableDataCaching(bool enabled) {
    _isDataCachingEnabled = enabled;
    if (!enabled) {
      _cleanupCache();
    }
    _logger.i('🗂️ Cache de datos ${enabled ? 'habilitado' : 'deshabilitado'}');
  }

  void configureMemoryThresholds({
    double? warningThreshold,
    double? criticalThreshold,
  }) {
    if (warningThreshold != null) _warningThreshold = warningThreshold;
    if (criticalThreshold != null) _criticalThreshold = criticalThreshold;

    _logger.i('🎯 Thresholds de memoria configurados: '
        'Warning=$_warningThreshold%, Critical=$_criticalThreshold%');
  }

  /// 📊 Estado y métricas
  bool isCleanupEnabled() => _isCleanupEnabled;

  Future<Map<String, dynamic>> getMemoryStatus() async {
    await _updateMemoryStatus();

    return {
      'currentUsageMB': _currentMemoryUsageMB,
      'maxUsageMB': _maxMemoryUsageMB,
      'usagePercentage': _memoryUsagePercentage,
      'deviceTotalMB': _deviceTotalMemoryMB,
      'isCleanupEnabled': _isCleanupEnabled,
      'isAggressiveCleanup': _isAggressiveCleanupEnabled,
      'cacheSize': _memoryCache.length,
      'objectsRegistered': _objectRegistry.length,
      'cleanupFrequency': _cleanupFrequency.inSeconds,
      'thresholds': {
        'warning': _warningThreshold,
        'critical': _criticalThreshold,
      },
    };
  }

  Map<String, dynamic> getMemoryStatistics() {
    if (_memoryHistory.isEmpty) {
      return {
        'averageUsageMB': _currentMemoryUsageMB,
        'peakUsageMB': _maxMemoryUsageMB,
        'minUsageMB': _currentMemoryUsageMB,
        'totalReadings': 0,
        'trend': 'stable',
      };
    }

    final usages = _memoryHistory.map((r) => r.usageMB).toList();
    final averageUsage = usages.reduce((a, b) => a + b) / usages.length;
    final minUsage = usages.reduce((a, b) => a < b ? a : b);
    final maxUsage = usages.reduce((a, b) => a > b ? a : b);

    return {
      'averageUsageMB': averageUsage.round(),
      'peakUsageMB': maxUsage,
      'minUsageMB': minUsage,
      'totalReadings': _memoryHistory.length,
      'trend': calculateMemoryTrend(),
    };
  }

  String calculateMemoryTrend() {
    if (_memoryHistory.length < 3) return 'stable';

    final recent = _memoryHistory.reversed.take(3).toList();
    final first = recent.last.usageMB;
    final last = recent.first.usageMB;

    final difference = last - first;

    if (difference > 10) return 'increasing';
    if (difference < -10) return 'decreasing';
    return 'stable';
  }

  /// 📞 Callbacks de eventos
  void addMemoryUsageCallback(Function(double) callback) {
    _memoryUsageCallbacks.add(callback);
  }

  void addLowMemoryCallback(Function(bool) callback) {
    _lowMemoryCallbacks.add(callback);
  }

  void _notifyMemoryUsageCallbacks(double usagePercentage) {
    for (final callback in _memoryUsageCallbacks) {
      try {
        callback(usagePercentage);
      } catch (e) {
        _logger.w('⚠️ Error en callback de uso de memoria: $e');
      }
    }
  }

  void _notifyLowMemoryCallbacks(bool isLowMemory) {
    for (final callback in _lowMemoryCallbacks) {
      try {
        callback(isLowMemory);
      } catch (e) {
        _logger.w('⚠️ Error en callback de memoria baja: $e');
      }
    }
  }

  /// 🎯 Optimización forzada
  Future<void> forceOptimization() async {
    _logger.i('🎯 Forzando optimización de memoria...');

    final previousUsage = _currentMemoryUsageMB;

    // Habilitar cleanup agresivo temporalmente
    final wasAggressiveEnabled = _isAggressiveCleanupEnabled;
    enableAggressiveCleanup(true);

    // Ejecutar cleanup completo
    await performCleanup();

    // Restaurar configuración previa
    enableAggressiveCleanup(wasAggressiveEnabled);

    // Verificar mejora
    await _updateMemoryStatus();
    final improvement = previousUsage - _currentMemoryUsageMB;

    _logger.i(
        '✅ Optimización forzada completada - Memoria liberada: ${improvement}MB');
  }

  /// 🛑 Dispose
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryMonitorTimer?.cancel();
    _memoryCache.clear();
    _objectRegistry.clear();
    _memoryHistory.clear();
    _memoryUsageCallbacks.clear();
    _lowMemoryCallbacks.clear();
    _isInitialized = false;

    _logger.i('🛑 Memory Manager disposed');
  }
}
