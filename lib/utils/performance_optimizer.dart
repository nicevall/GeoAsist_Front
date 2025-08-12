// lib/utils/performance_optimizer.dart
// 🎯 BLOQUE 2 A1.3 - COORDINADOR CENTRAL DE OPTIMIZACIONES
// Detección automática de lag/stuttering, priorización inteligente de tareas
// Cleanup automático de recursos, monitoreo de FPS en tiempo real

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';
import 'battery_manager.dart';
import 'memory_manager.dart';
import 'connectivity_manager.dart';

/// 🎯 Coordinador central de optimizaciones de performance
/// Monitorea FPS, detecta lag, prioriza tareas y optimiza recursos automáticamente
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // 📊 Monitoreo de performance
  Timer? _performanceMonitorTimer;
  Timer? _resourceCleanupTimer;
  final List<double> _frameTimings = [];
  double _averageFps = 60.0;
  bool _isLowPerformanceMode = false;

  // 🎯 Thresholds configurables según dispositivo
  double _targetFps = 60.0;
  double _lagThreshold = 16.67; // 60 FPS = 16.67ms por frame
  int _frameTimingHistoryLimit = 120; // 2 segundos a 60fps

  // 🔧 Gestores especializados
  late BatteryManager _batteryManager;
  late MemoryManager _memoryManager;
  late ConnectivityManager _connectivityManager;

  // 📈 Estado de optimización
  bool _isInitialized = false;
  bool _isMonitoring = false;
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.optimal;

  /// 🚀 Inicialización del optimizador
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🎯 Inicializando Performance Optimizer...');

      // Inicializar gestores especializados
      _batteryManager = BatteryManager();
      _memoryManager = MemoryManager();
      _connectivityManager = ConnectivityManager();

      await _batteryManager.initialize();
      await _memoryManager.initialize();
      await _connectivityManager.initialize();

      // Configurar thresholds según dispositivo
      await _configureDeviceSpecificSettings();

      // Configurar monitoreo de frames
      _setupFrameMonitoring();

      _isInitialized = true;
      _logger.i('✅ Performance Optimizer inicializado correctamente');
    } catch (e, stackTrace) {
      _logger.e('❌ Error inicializando Performance Optimizer',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 📱 Configuración específica por dispositivo
  Future<void> _configureDeviceSpecificSettings() async {
    try {
      // Configurar FPS objetivo según plataforma
      if (Platform.isAndroid) {
        _targetFps = 60.0; // Android estándar
        _lagThreshold = 20.0; // Más tolerante en Android
      } else if (Platform.isIOS) {
        _targetFps = 60.0; // iOS estándar
        _lagThreshold = 16.67; // Más estricto en iOS
      }

      // Ajustar según batería inicial
      final batteryLevel = await _batteryManager.getCurrentBatteryLevel();
      if (batteryLevel < 20) {
        _enableLowPerformanceMode();
      }

      _logger.i(
          '📱 Configuración específica: FPS=$_targetFps, Lag threshold=${_lagThreshold}ms');
    } catch (e) {
      _logger
          .w('⚠️ Error configurando settings específicos del dispositivo: $e');
    }
  }

  /// 📊 Configurar monitoreo de frames
  void _setupFrameMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (!_isMonitoring) return;

      final frameTime = timeStamp.inMicroseconds / 1000.0; // Convertir a ms
      _frameTimings.add(frameTime);

      // Mantener historial limitado
      if (_frameTimings.length > _frameTimingHistoryLimit) {
        _frameTimings.removeAt(0);
      }

      // Calcular FPS promedio cada 30 frames
      if (_frameTimings.length >= 30 && _frameTimings.length % 30 == 0) {
        _calculateAverageFps();
        _checkPerformanceLevel();
      }
    });
  }

  /// 🎯 Iniciar monitoreo de performance
  void startMonitoring() {
    if (_isMonitoring) return;

    _logger.i('🎯 Iniciando monitoreo de performance...');
    _isMonitoring = true;

    // Timer principal de monitoreo (cada 5 segundos)
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _performFullAnalysis(),
    );

    // Timer de cleanup (cada 30 segundos)
    _resourceCleanupTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performResourceCleanup(),
    );

    _logger.i('✅ Monitoreo de performance iniciado');
  }

  /// ⏹️ Detener monitoreo
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _logger.i('⏹️ Deteniendo monitoreo de performance...');

    _performanceMonitorTimer?.cancel();
    _resourceCleanupTimer?.cancel();
    _isMonitoring = false;

    _logger.i('✅ Monitoreo detenido');
  }

  /// 📊 Análisis completo de performance
  Future<void> _performFullAnalysis() async {
    try {
      // Análisis de memoria
      final memoryStatus = await _memoryManager.getMemoryStatus();

      // Análisis de batería
      final batteryStatus = await _batteryManager.getBatteryStatus();

      // Análisis de conectividad
      final connectivityStatus =
          await _connectivityManager.getConnectivityStatus();

      // Determinar nivel de performance necesario
      _determineOptimalPerformanceLevel(
        memoryStatus: memoryStatus,
        batteryStatus: batteryStatus,
        connectivityStatus: connectivityStatus,
      );

      // Log del estado actual
      if (kDebugMode) {
        _logger.d(
            '📊 Performance Analysis - FPS: ${_averageFps.toStringAsFixed(1)}, '
            'Level: $_currentPerformanceLevel, '
            'Memory: ${memoryStatus['usagePercentage'].toStringAsFixed(1)}%');
      }
    } catch (e) {
      _logger.w('⚠️ Error en análisis de performance: $e');
    }
  }

  /// 🎯 Determinar nivel óptimo de performance
  void _determineOptimalPerformanceLevel({
    required Map<String, dynamic> memoryStatus,
    required Map<String, dynamic> batteryStatus,
    required Map<String, dynamic> connectivityStatus,
  }) {
    PerformanceLevel newLevel = PerformanceLevel.optimal;

    // Criterios para degradar performance
    if (batteryStatus['level'] < 15 ||
        batteryStatus['isLowPowerMode'] == true) {
      newLevel = PerformanceLevel.battery_saver;
    } else if (memoryStatus['usagePercentage'] > 80) {
      newLevel = PerformanceLevel.memory_optimized;
    } else if (_averageFps < 30) {
      newLevel = PerformanceLevel.performance_optimized;
    } else if (connectivityStatus['isConnected'] == false) {
      newLevel = PerformanceLevel.offline_optimized;
    }

    // Aplicar nuevo nivel si es diferente
    if (newLevel != _currentPerformanceLevel) {
      _applyPerformanceLevel(newLevel);
    }
  }

  /// ⚙️ Aplicar nivel de performance
  void _applyPerformanceLevel(PerformanceLevel level) {
    _logger.i(
        '🎯 Cambiando nivel de performance: $_currentPerformanceLevel → $level');
    _currentPerformanceLevel = level;

    switch (level) {
      case PerformanceLevel.optimal:
        _applyOptimalSettings();
        break;
      case PerformanceLevel.battery_saver:
        _applyBatterySaverSettings();
        break;
      case PerformanceLevel.memory_optimized:
        _applyMemoryOptimizedSettings();
        break;
      case PerformanceLevel.performance_optimized:
        _applyPerformanceOptimizedSettings();
        break;
      case PerformanceLevel.offline_optimized:
        _applyOfflineOptimizedSettings();
        break;
    }
  }

  /// 🎯 Configuraciones óptimas
  void _applyOptimalSettings() {
    _isLowPerformanceMode = false;
    // Configuraciones para máximo rendimiento
    _memoryManager.setCleanupFrequency(const Duration(minutes: 2));
    _batteryManager.setTrackingFrequency(const Duration(seconds: 30));
  }

  /// 🔋 Configuraciones ahorro de batería
  void _applyBatterySaverSettings() {
    _isLowPerformanceMode = true;
    _memoryManager.setCleanupFrequency(const Duration(minutes: 5));
    _batteryManager.setTrackingFrequency(const Duration(minutes: 2));
    _connectivityManager.setUpdateFrequency(const Duration(minutes: 1));
  }

  /// 🧠 Configuraciones optimización de memoria
  void _applyMemoryOptimizedSettings() {
    _memoryManager.setCleanupFrequency(const Duration(seconds: 30));
    _memoryManager.enableAggressiveCleanup(true);
  }

  /// ⚡ Configuraciones optimización de performance
  void _applyPerformanceOptimizedSettings() {
    _targetFps = 30.0; // Reducir FPS objetivo
    _lagThreshold = 33.33; // Más tolerante al lag
  }

  /// 📱 Configuraciones modo offline
  void _applyOfflineOptimizedSettings() {
    _connectivityManager.enableOfflineMode(true);
    _memoryManager.enableDataCaching(true);
  }

  /// 📊 Calcular FPS promedio
  void _calculateAverageFps() {
    if (_frameTimings.isEmpty) return;

    final validTimings = _frameTimings.where((t) => t > 0 && t < 1000).toList();
    if (validTimings.isEmpty) return;

    final avgFrameTime =
        validTimings.reduce((a, b) => a + b) / validTimings.length;
    _averageFps = 1000.0 / avgFrameTime;
  }

  /// 🔍 Verificar nivel de performance
  void _checkPerformanceLevel() {
    final isLagging = _frameTimings.any((t) => t > _lagThreshold);

    if (isLagging && _averageFps < _targetFps * 0.8) {
      if (!_isLowPerformanceMode) {
        _logger.w(
            '⚠️ Detectado lag/stuttering - FPS: ${_averageFps.toStringAsFixed(1)}');
        _enableLowPerformanceMode();
      }
    } else if (_isLowPerformanceMode && _averageFps > _targetFps * 0.95) {
      _disableLowPerformanceMode();
    }
  }

  /// 🐌 Habilitar modo bajo rendimiento
  void _enableLowPerformanceMode() {
    _isLowPerformanceMode = true;
    _applyPerformanceOptimizedSettings();
    _logger.i('🐌 Modo bajo rendimiento habilitado');
  }

  /// 🚀 Deshabilitar modo bajo rendimiento
  void _disableLowPerformanceMode() {
    _isLowPerformanceMode = false;
    _applyOptimalSettings();
    _logger.i('🚀 Modo bajo rendimiento deshabilitado');
  }

  /// 🧹 Cleanup de recursos
  Future<void> _performResourceCleanup() async {
    try {
      await _memoryManager.performCleanup();

      // Limpiar historial de frames si es muy grande
      if (_frameTimings.length > _frameTimingHistoryLimit * 2) {
        _frameTimings.removeRange(0, _frameTimingHistoryLimit);
      }
    } catch (e) {
      _logger.w('⚠️ Error en cleanup de recursos: $e');
    }
  }

  /// 📊 Obtener métricas actuales
  Map<String, dynamic> getCurrentMetrics() {
    return {
      'averageFps': _averageFps,
      'targetFps': _targetFps,
      'isLowPerformanceMode': _isLowPerformanceMode,
      'currentLevel': _currentPerformanceLevel.toString(),
      'frameTimingsCount': _frameTimings.length,
      'isMonitoring': _isMonitoring,
      'batteryOptimized': _batteryManager.isOptimizationEnabled(),
      'memoryOptimized': _memoryManager.isCleanupEnabled(),
    };
  }

  /// 🎯 Forzar optimización inmediata
  Future<void> forceOptimization() async {
    _logger.i('🎯 Forzando optimización inmediata...');

    await _performFullAnalysis();
    await _performResourceCleanup();

    _logger.i('✅ Optimización forzada completada');
  }

  /// 🛑 Dispose
  void dispose() {
    stopMonitoring();
    _batteryManager.dispose();
    _memoryManager.dispose();
    _connectivityManager.dispose();
    _frameTimings.clear();
    _isInitialized = false;

    _logger.i('🛑 Performance Optimizer disposed');
  }
}

/// 📊 Niveles de performance
enum PerformanceLevel {
  optimal, // Rendimiento máximo
  battery_saver, // Ahorro de batería
  memory_optimized, // Optimizado para memoria
  performance_optimized, // Optimizado para performance
  offline_optimized, // Optimizado para modo offline
}
