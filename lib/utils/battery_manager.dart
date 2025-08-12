// lib/utils/battery_manager.dart
// 🎯 BLOQUE 2 A1.3 - GESTIÓN INTELIGENTE DE BATERÍA
// Detección de estado de carga/descarga, modo ahorro automático
// Tracking adaptivo según batería, predicción de duración restante

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:logger/logger.dart';

/// 🔋 Gestor inteligente de batería
/// Optimiza el comportamiento de la app según el estado de la batería
class BatteryManager {
  static final BatteryManager _instance = BatteryManager._internal();
  factory BatteryManager() => _instance;
  BatteryManager._internal();

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

  final Battery _battery = Battery();

  // 📊 Estado de la batería
  int _currentBatteryLevel = 100;
  BatteryState _currentBatteryState = BatteryState.unknown;
  bool _isLowPowerMode = false;
  bool _isOptimizationEnabled = false;

  // ⏱️ Control de frecuencia
  Duration _trackingFrequency = const Duration(seconds: 30);
  Timer? _batteryMonitorTimer;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  // 📈 Historial para predicciones
  final List<BatteryReading> _batteryHistory = [];
  final int _maxHistoryLength = 100; // Últimas 100 lecturas

  // 🎯 Thresholds configurables
  int _lowBatteryThreshold = 20;
  int _criticalBatteryThreshold = 10;
  int _veryLowBatteryThreshold = 5;

  // 📱 Callbacks de eventos
  final List<Function(int)> _batteryLevelCallbacks = [];
  final List<Function(BatteryState)> _batteryStateCallbacks = [];
  final List<Function(bool)> _lowPowerModeCallbacks = [];

  bool _isInitialized = false;

  /// 🚀 Inicialización del battery manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🔋 Inicializando Battery Manager...');

      // Leer estado inicial
      await _updateBatteryStatus();

      // Configurar monitoreo continuo
      _setupBatteryMonitoring();

      // Iniciar tracking
      _startBatteryTracking();

      _isInitialized = true;
      _logger.i(
          '✅ Battery Manager inicializado - Nivel: $_currentBatteryLevel%, Estado: $_currentBatteryState');
    } catch (e, stackTrace) {
      _logger.e('❌ Error inicializando Battery Manager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 📊 Configurar monitoreo de batería
  void _setupBatteryMonitoring() {
    // Monitorear cambios de estado (carga/descarga)
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
      (BatteryState state) {
        _onBatteryStateChanged(state);
      },
      onError: (error) {
        _logger.w('⚠️ Error en stream de estado de batería: $error');
      },
    );
  }

  /// ⏱️ Iniciar tracking de batería
  void _startBatteryTracking() {
    _batteryMonitorTimer?.cancel();

    _batteryMonitorTimer = Timer.periodic(_trackingFrequency, (_) async {
      await _updateBatteryStatus();
    });

    _logger.d('⏱️ Battery tracking iniciado - Frecuencia: $_trackingFrequency');
  }

  /// 📊 Actualizar estado de la batería
  Future<void> _updateBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      // Detectar cambios significativos
      final levelChanged = level != _currentBatteryLevel;
      final stateChanged = state != _currentBatteryState;

      if (levelChanged || stateChanged) {
        _currentBatteryLevel = level;
        _currentBatteryState = state;

        // Agregar al historial
        _addBatteryReading(level, state);

        // Verificar optimizaciones necesarias
        _checkBatteryOptimizations();

        // Notificar callbacks
        if (levelChanged) {
          _notifyBatteryLevelCallbacks(level);
        }
        if (stateChanged) {
          _notifyBatteryStateCallbacks(state);
        }

        if (kDebugMode) {
          _logger.d('🔋 Batería actualizada: $level% - $state');
        }
      }
    } catch (e) {
      _logger.w('⚠️ Error actualizando estado de batería: $e');
    }
  }

  /// 📈 Agregar lectura al historial
  void _addBatteryReading(int level, BatteryState state) {
    final reading = BatteryReading(
      level: level,
      state: state,
      timestamp: DateTime.now(),
    );

    _batteryHistory.add(reading);

    // Mantener historial limitado
    if (_batteryHistory.length > _maxHistoryLength) {
      _batteryHistory.removeAt(0);
    }
  }

  /// 🎯 Verificar optimizaciones necesarias
  void _checkBatteryOptimizations() {
    final previousOptimizationState = _isOptimizationEnabled;

    // Determinar si debe optimizar
    _isOptimizationEnabled = _shouldEnableOptimization();

    // Si cambió el estado de optimización
    if (_isOptimizationEnabled != previousOptimizationState) {
      if (_isOptimizationEnabled) {
        _enableBatteryOptimizations();
      } else {
        _disableBatteryOptimizations();
      }
    }

    // Verificar modo de bajo consumo
    _checkLowPowerMode();
  }

  /// 🔍 Determinar si debe habilitar optimización
  bool _shouldEnableOptimization() {
    // Habilitar optimización si:
    // 1. Batería baja
    if (_currentBatteryLevel <= _lowBatteryThreshold) return true;

    // 2. Descargando rápidamente
    if (_isDischarging() && _getPredictedBatteryLife() < 2.0) return true;

    // 3. No está cargando y nivel medio-bajo
    if (!_isCharging() && _currentBatteryLevel <= 30) return true;

    return false;
  }

  /// ⚡ Habilitar optimizaciones de batería
  void _enableBatteryOptimizations() {
    _logger.i('⚡ Habilitando optimizaciones de batería...');

    // Reducir frecuencia de tracking
    _setTrackingFrequency(Duration(
        minutes: _currentBatteryLevel <= _criticalBatteryThreshold ? 5 : 2));

    // Notificar a listeners
    _notifyOptimizationStateChanged(true);
  }

  /// 🚀 Deshabilitar optimizaciones de batería
  void _disableBatteryOptimizations() {
    _logger.i('🚀 Deshabilitando optimizaciones de batería...');

    // Restaurar frecuencia normal
    _setTrackingFrequency(const Duration(seconds: 30));

    // Notificar a listeners
    _notifyOptimizationStateChanged(false);
  }

  /// 🔋 Verificar modo de bajo consumo
  void _checkLowPowerMode() {
    final shouldEnableLowPower =
        _currentBatteryLevel <= _veryLowBatteryThreshold;

    if (shouldEnableLowPower != _isLowPowerMode) {
      _isLowPowerMode = shouldEnableLowPower;
      _notifyLowPowerModeCallbacks(_isLowPowerMode);

      if (_isLowPowerMode) {
        _logger.w(
            '🔋 Modo de bajo consumo activado - Batería: $_currentBatteryLevel%');
      } else {
        _logger.i(
            '🚀 Modo de bajo consumo desactivado - Batería: $_currentBatteryLevel%');
      }
    }
  }

  /// 🔄 Cambiar frecuencia de tracking
  void setTrackingFrequency(Duration frequency) {
    _setTrackingFrequency(frequency);
  }

  void _setTrackingFrequency(Duration frequency) {
    if (_trackingFrequency == frequency) return;

    _trackingFrequency = frequency;

    // Reiniciar timer con nueva frecuencia
    if (_batteryMonitorTimer?.isActive == true) {
      _startBatteryTracking();
    }

    _logger.d('⏱️ Frecuencia de battery tracking cambiada: $frequency');
  }

  /// 📊 Callbacks de eventos de batería
  void _onBatteryStateChanged(BatteryState state) {
    _logger.d('🔄 Estado de batería cambió: $_currentBatteryState → $state');

    if (state == BatteryState.charging &&
        _currentBatteryState != BatteryState.charging) {
      _logger.i('🔌 Dispositivo conectado a cargador');
    } else if (state != BatteryState.charging &&
        _currentBatteryState == BatteryState.charging) {
      _logger.i('🔌 Dispositivo desconectado del cargador');
    }
  }

  /// 📈 Predicción de duración de batería
  double getPredictedBatteryLife() {
    return _getPredictedBatteryLife();
  }

  double _getPredictedBatteryLife() {
    if (_batteryHistory.length < 5 || _isCharging()) {
      return double.infinity; // No se puede predecir o está cargando
    }

    try {
      // Calcular tasa de descarga promedio (últimas 5 lecturas)
      final recentReadings = _batteryHistory.reversed.take(5).toList();
      if (recentReadings.length < 2) return double.infinity;

      double totalDischarge = 0;
      Duration totalTime = Duration.zero;

      for (int i = 1; i < recentReadings.length; i++) {
        final discharge = recentReadings[i - 1].level - recentReadings[i].level;
        final timeDiff = recentReadings[i - 1]
            .timestamp
            .difference(recentReadings[i].timestamp);

        if (discharge > 0 && timeDiff.inMinutes > 0) {
          totalDischarge += discharge;
          totalTime += timeDiff;
        }
      }

      if (totalDischarge <= 0) return double.infinity;

      // Calcular tasa de descarga por hora
      final dischargeRatePerHour =
          totalDischarge / (totalTime.inMinutes / 60.0);

      // Predecir tiempo restante
      final hoursRemaining = _currentBatteryLevel / dischargeRatePerHour;

      return hoursRemaining;
    } catch (e) {
      _logger.w('⚠️ Error calculando predicción de batería: $e');
      return double.infinity;
    }
  }

  /// 🔍 Métodos de estado
  bool _isCharging() => _currentBatteryState == BatteryState.charging;
  bool _isDischarging() => _currentBatteryState == BatteryState.discharging;
  bool isLowBattery() => _currentBatteryLevel <= _lowBatteryThreshold;
  bool isCriticalBattery() => _currentBatteryLevel <= _criticalBatteryThreshold;
  bool isOptimizationEnabled() => _isOptimizationEnabled;
  bool isLowPowerMode() => _isLowPowerMode;

  /// 📊 Obtener estado completo de batería
  Future<Map<String, dynamic>> getBatteryStatus() async {
    await _updateBatteryStatus();

    return {
      'level': _currentBatteryLevel,
      'state': _currentBatteryState.toString(),
      'isCharging': _isCharging(),
      'isDischarging': _isDischarging(),
      'isLowBattery': isLowBattery(),
      'isCriticalBattery': isCriticalBattery(),
      'isLowPowerMode': _isLowPowerMode,
      'isOptimizationEnabled': _isOptimizationEnabled,
      'predictedBatteryLife': _getPredictedBatteryLife(),
      'trackingFrequency': _trackingFrequency.inSeconds,
      'historyCount': _batteryHistory.length,
      'thresholds': {
        'low': _lowBatteryThreshold,
        'critical': _criticalBatteryThreshold,
        'veryLow': _veryLowBatteryThreshold,
      },
    };
  }

  /// 📊 Obtener nivel actual de batería
  Future<int> getCurrentBatteryLevel() async {
    try {
      _currentBatteryLevel = await _battery.batteryLevel;
      return _currentBatteryLevel;
    } catch (e) {
      _logger.w('⚠️ Error obteniendo nivel de batería: $e');
      return _currentBatteryLevel;
    }
  }

  /// 🎯 Configurar thresholds
  void configureBatteryThresholds({
    int? lowBatteryThreshold,
    int? criticalBatteryThreshold,
    int? veryLowBatteryThreshold,
  }) {
    if (lowBatteryThreshold != null) _lowBatteryThreshold = lowBatteryThreshold;
    if (criticalBatteryThreshold != null)
      _criticalBatteryThreshold = criticalBatteryThreshold;
    if (veryLowBatteryThreshold != null)
      _veryLowBatteryThreshold = veryLowBatteryThreshold;

    _logger.i(
        '🎯 Thresholds de batería configurados: Low=$_lowBatteryThreshold%, '
        'Critical=$_criticalBatteryThreshold%, VeryLow=$_veryLowBatteryThreshold%');
  }

  /// 📞 Registrar callbacks de eventos
  void addBatteryLevelCallback(Function(int) callback) {
    _batteryLevelCallbacks.add(callback);
  }

  void addBatteryStateCallback(Function(BatteryState) callback) {
    _batteryStateCallbacks.add(callback);
  }

  void addLowPowerModeCallback(Function(bool) callback) {
    _lowPowerModeCallbacks.add(callback);
  }

  /// 🔔 Notificar callbacks
  void _notifyBatteryLevelCallbacks(int level) {
    for (final callback in _batteryLevelCallbacks) {
      try {
        callback(level);
      } catch (e) {
        _logger.w('⚠️ Error en callback de nivel de batería: $e');
      }
    }
  }

  void _notifyBatteryStateCallbacks(BatteryState state) {
    for (final callback in _batteryStateCallbacks) {
      try {
        callback(state);
      } catch (e) {
        _logger.w('⚠️ Error en callback de estado de batería: $e');
      }
    }
  }

  void _notifyLowPowerModeCallbacks(bool enabled) {
    for (final callback in _lowPowerModeCallbacks) {
      try {
        callback(enabled);
      } catch (e) {
        _logger.w('⚠️ Error en callback de modo bajo consumo: $e');
      }
    }
  }

  void _notifyOptimizationStateChanged(bool enabled) {
    _logger.i('🎯 Estado de optimización cambiado: $enabled');
    // Aquí se podría notificar a otros componentes del sistema
  }

  /// 📊 Obtener estadísticas de batería
  Map<String, dynamic> getBatteryStatistics() {
    if (_batteryHistory.isEmpty) {
      return {
        'averageLevel': _currentBatteryLevel,
        'minLevel': _currentBatteryLevel,
        'maxLevel': _currentBatteryLevel,
        'totalReadings': 0,
        'chargingCycles': 0,
        'averageDischargeRate': 0.0,
      };
    }

    final levels = _batteryHistory.map((r) => r.level).toList();
    final averageLevel = levels.reduce((a, b) => a + b) / levels.length;
    final minLevel = levels.reduce((a, b) => a < b ? a : b);
    final maxLevel = levels.reduce((a, b) => a > b ? a : b);

    // Contar ciclos de carga
    int chargingCycles = 0;
    bool wasCharging = false;
    for (final reading in _batteryHistory) {
      final isCharging = reading.state == BatteryState.charging;
      if (isCharging && !wasCharging) {
        chargingCycles++;
      }
      wasCharging = isCharging;
    }

    return {
      'averageLevel': averageLevel.round(),
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'totalReadings': _batteryHistory.length,
      'chargingCycles': chargingCycles,
      'averageDischargeRate': _calculateAverageDischargeRate(),
    };
  }

  /// 📉 Calcular tasa promedio de descarga
  double _calculateAverageDischargeRate() {
    if (_batteryHistory.length < 2) return 0.0;

    double totalDischarge = 0;
    int dischargeCount = 0;
    Duration totalTime = Duration.zero;

    for (int i = 1; i < _batteryHistory.length; i++) {
      final prev = _batteryHistory[i - 1];
      final current = _batteryHistory[i];

      if (prev.state == BatteryState.discharging &&
          current.state == BatteryState.discharging) {
        final discharge = prev.level - current.level;
        final timeDiff = current.timestamp.difference(prev.timestamp);

        if (discharge > 0 && timeDiff.inMinutes > 0) {
          totalDischarge += discharge;
          totalTime += timeDiff;
          dischargeCount++;
        }
      }
    }

    if (dischargeCount == 0 || totalTime.inMinutes == 0) return 0.0;

    // Retornar tasa de descarga por hora
    return (totalDischarge / (totalTime.inMinutes / 60.0));
  }

  /// 🎯 Forzar optimización por batería baja
  void forceOptimizationForLowBattery() {
    _logger.i('🎯 Forzando optimización por batería baja...');
    _isOptimizationEnabled = true;
    _enableBatteryOptimizations();
  }

  /// 🚀 Deshabilitar optimización forzada
  void disableOptimization() {
    _logger.i('🚀 Deshabilitando optimización forzada...');
    _isOptimizationEnabled = false;
    _disableBatteryOptimizations();
  }

  /// 🛑 Dispose
  void dispose() {
    _batteryMonitorTimer?.cancel();
    _batteryStateSubscription?.cancel();
    _batteryHistory.clear();
    _batteryLevelCallbacks.clear();
    _batteryStateCallbacks.clear();
    _lowPowerModeCallbacks.clear();
    _isInitialized = false;

    _logger.i('🛑 Battery Manager disposed');
  }
}

/// 📊 Modelo de lectura de batería
class BatteryReading {
  final int level;
  final BatteryState state;
  final DateTime timestamp;

  BatteryReading({
    required this.level,
    required this.state,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'BatteryReading(level: $level%, state: $state, time: $timestamp)';
  }
}
