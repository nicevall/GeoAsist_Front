// lib/utils/connectivity_manager.dart
// 🎯 BLOQUE 2 A1.3 - GESTIÓN DE CONECTIVIDAD Y MODO OFFLINE
// Detección automática WiFi/móvil/sin conexión, cache inteligente
// Sincronización automática, optimización de requests, retry logic

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📡 Gestor inteligente de conectividad
/// Maneja conexiones de red, modo offline y sincronización de datos
class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

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

  final Connectivity _connectivity = Connectivity();

  // 📊 Estado de conectividad
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  bool _isConnected = false;
  bool _isOfflineModeEnabled = false;
  ConnectionQuality _connectionQuality = ConnectionQuality.unknown;

  // ⏱️ Control de actualizaciones
  Duration _updateFrequency = const Duration(seconds: 15);
  Timer? _connectivityMonitorTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // 📈 Historial y métricas
  final List<ConnectivityReading> _connectivityHistory = [];
  final int _maxHistoryLength = 100;
  DateTime? _lastConnectedTime;
  Duration _totalOfflineTime = Duration.zero;

  // 🗂️ Cache offline
  final Map<String, OfflineCacheEntry> _offlineCache = {};
  final List<PendingRequest> _pendingRequests = [];
  final int _maxCacheSize = 500;
  final Duration _cacheExpirationTime = const Duration(hours: 24);

  // 🔄 Retry y sincronización
  bool _isSyncInProgress = false;
  Timer? _syncTimer;

  // 📱 Callbacks de eventos
  final List<Function(bool)> _connectivityCallbacks = [];
  final List<Function(ConnectivityResult)> _connectivityTypeCallbacks = [];
  final List<Function(ConnectionQuality)> _qualityCallbacks = [];

  // 🎯 Configuración
  bool _isAutoSyncEnabled = true;
  Duration _syncInterval = const Duration(minutes: 5);
  int _maxRetryAttempts = 3;
  Duration _retryDelay = const Duration(seconds: 2);

  bool _isInitialized = false;

  /// 🚀 Inicialización del connectivity manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('📡 Inicializando Connectivity Manager...');

      // Verificar conectividad inicial
      await _updateConnectivityStatus();

      // Configurar monitoreo continuo
      _setupConnectivityMonitoring();

      // Cargar cache offline desde storage
      await _loadOfflineCache();

      // Iniciar sincronización automática
      if (_isAutoSyncEnabled) {
        _startAutoSync();
      }

      _isInitialized = true;
      _logger.i(
          '✅ Connectivity Manager inicializado - Estado: $_currentConnectivity, '
          'Conectado: $_isConnected');
    } catch (e, stackTrace) {
      _logger.e('❌ Error inicializando Connectivity Manager',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 📊 Configurar monitoreo de conectividad
  void _setupConnectivityMonitoring() {
    // Stream de cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty) {
          _onConnectivityChanged(results.first);
        }
      },
      onError: (error) {
        _logger.w('⚠️ Error en stream de conectividad: $error');
      },
    );

    // Timer para verificaciones periódicas
    _connectivityMonitorTimer = Timer.periodic(_updateFrequency, (_) async {
      await _updateConnectivityStatus();
      await _testConnectionQuality();
    });
  }

  Future<void> _updateConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.isNotEmpty) {
        await _processConnectivityChange(results.first);
      }
    } catch (e) {
      _logger.w('⚠️ Error actualizando estado de conectividad: $e');
    }
  }

  /// 📊 Procesar cambio de conectividad
  Future<void> _processConnectivityChange(ConnectivityResult result) async {
    final previousConnectivity = _currentConnectivity;
    final wasConnected = _isConnected;

    _currentConnectivity = result;
    _isConnected = result != ConnectivityResult.none;

    // Agregar al historial
    _addConnectivityReading(result, _isConnected);

    // Manejar cambios de estado
    if (_isConnected && !wasConnected) {
      await _onConnectionRestored();
    } else if (!_isConnected && wasConnected) {
      _onConnectionLost();
    }

    // Notificar callbacks si hay cambio
    if (result != previousConnectivity) {
      _notifyConnectivityTypeCallbacks(result);
    }
    if (_isConnected != wasConnected) {
      _notifyConnectivityCallbacks(_isConnected);
    }

    if (kDebugMode) {
      _logger.d('📡 Conectividad: $result, Conectado: $_isConnected');
    }
  }

  /// 🔄 Manejar eventos de conectividad
  void _onConnectivityChanged(ConnectivityResult result) {
    _processConnectivityChange(result);
  }

  /// ✅ Conexión restaurada
  Future<void> _onConnectionRestored() async {
    _logger.i('✅ Conexión restaurada: $_currentConnectivity');

    _lastConnectedTime = DateTime.now();

    // Intentar sincronización automática
    if (_isAutoSyncEnabled && _pendingRequests.isNotEmpty) {
      await syncPendingRequests();
    }

    // Actualizar calidad de conexión
    await _testConnectionQuality();
  }

  /// ❌ Conexión perdida
  void _onConnectionLost() {
    _logger.w('❌ Conexión perdida');

    if (_lastConnectedTime != null) {
      _totalOfflineTime =
          _totalOfflineTime + DateTime.now().difference(_lastConnectedTime!);
    }

    // Habilitar modo offline automáticamente
    if (!_isOfflineModeEnabled) {
      enableOfflineMode(true);
    }
  }

  /// 📈 Agregar lectura al historial
  void _addConnectivityReading(ConnectivityResult result, bool isConnected) {
    final reading = ConnectivityReading(
      connectivityType: result,
      isConnected: isConnected,
      quality: _connectionQuality,
      timestamp: DateTime.now(),
    );

    _connectivityHistory.add(reading);

    // Mantener historial limitado
    if (_connectivityHistory.length > _maxHistoryLength) {
      _connectivityHistory.removeAt(0);
    }
  }

  /// 🧪 Probar calidad de conexión
  Future<void> _testConnectionQuality() async {
    if (!_isConnected) {
      _connectionQuality = ConnectionQuality.none;
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Test simple con timeout
      final response = await HttpClient()
          .getUrl(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5))
          .then((request) => request.close());

      stopwatch.stop();

      if (response.statusCode == 200) {
        final latency = stopwatch.elapsedMilliseconds;
        _connectionQuality = _determineQualityFromLatency(latency);
      } else {
        _connectionQuality = ConnectionQuality.poor;
      }
    } catch (e) {
      _connectionQuality = ConnectionQuality.poor;
      _logger.w('⚠️ Error probando calidad de conexión: $e');
    }

    _notifyQualityCallbacks(_connectionQuality);
  }

  /// 📊 Determinar calidad por latencia
  ConnectionQuality _determineQualityFromLatency(int latencyMs) {
    if (latencyMs < 100) return ConnectionQuality.excellent;
    if (latencyMs < 300) return ConnectionQuality.good;
    if (latencyMs < 1000) return ConnectionQuality.fair;
    return ConnectionQuality.poor;
  }

  /// 🗂️ Gestión de cache offline
  Future<void> cacheData(String key, Map<String, dynamic> data,
      {Duration? ttl}) async {
    final entry = OfflineCacheEntry(
      key: key,
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _cacheExpirationTime,
    );

    _offlineCache[key] = entry;

    // Verificar límite de cache
    if (_offlineCache.length > _maxCacheSize) {
      _cleanupOldestCacheEntry();
    }

    // Persistir en storage
    await _saveOfflineCache();

    _logger.d('🗂️ Datos cacheados offline: $key');
  }

  Map<String, dynamic>? getCachedData(String key) {
    final entry = _offlineCache[key];
    if (entry == null) return null;

    // Verificar expiración
    if (DateTime.now().difference(entry.timestamp) > entry.ttl) {
      _offlineCache.remove(key);
      _saveOfflineCache(); // Async sin await para no bloquear
      return null;
    }

    return entry.data;
  }

  /// 📨 Agregar request pendiente para sincronización
  void addPendingRequest(
      String url, String method, Map<String, dynamic>? data) {
    final request = PendingRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      method: method,
      data: data,
      timestamp: DateTime.now(),
      attempts: 0,
    );

    _pendingRequests.add(request);
    _logger.d('📨 Request pendiente agregado: $method $url');
  }

  /// 🔄 Sincronizar requests pendientes
  Future<bool> syncPendingRequests() async {
    if (!_isConnected || _isSyncInProgress || _pendingRequests.isEmpty) {
      return false;
    }

    _logger.i(
        '🔄 Iniciando sincronización de ${_pendingRequests.length} requests pendientes...');
    _isSyncInProgress = true;

    int successCount = 0;
    final failedRequests = <PendingRequest>[];

    try {
      for (final request in List.from(_pendingRequests)) {
        final success = await _syncSingleRequest(request);

        if (success) {
          successCount++;
          _pendingRequests.remove(request);
        } else {
          request.attempts++;
          if (request.attempts >= _maxRetryAttempts) {
            _pendingRequests.remove(request);
            failedRequests.add(request);
          }
        }
      }

      _logger.i('✅ Sincronización completada - Éxito: $successCount, '
          'Fallos permanentes: ${failedRequests.length}, '
          'Pendientes: ${_pendingRequests.length}');

      return successCount > 0;
    } finally {
      _isSyncInProgress = false;
    }
  }

  /// 📤 Sincronizar request individual
  Future<bool> _syncSingleRequest(PendingRequest request) async {
    try {
      _logger.d('📤 Sincronizando: ${request.method} ${request.url}');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      HttpClientRequest httpRequest;

      if (request.method.toUpperCase() == 'POST') {
        httpRequest = await client.postUrl(Uri.parse(request.url));
        httpRequest.headers.contentType = ContentType.json;
        if (request.data != null) {
          httpRequest.write(jsonEncode(request.data));
        }
      } else {
        httpRequest = await client.getUrl(Uri.parse(request.url));
      }

      final response = await httpRequest.close();
      final success = response.statusCode >= 200 && response.statusCode < 300;

      if (success) {
        _logger.d('✅ Request sincronizado exitosamente: ${request.url}');
      } else {
        _logger.w('❌ Error sincronizando request: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      _logger.w('❌ Error en sincronización de request: $e');
      return false;
    }
  }

  /// ⏱️ Configurar sincronización automática
  void _startAutoSync() {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      if (_isConnected && _pendingRequests.isNotEmpty) {
        await syncPendingRequests();
      }
    });

    _logger
        .d('⏱️ Sincronización automática iniciada - Intervalo: $_syncInterval');
  }

  /// 💾 Persistencia de cache
  Future<void> _saveOfflineCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheMap = <String, Map<String, dynamic>>{};

      for (final entry in _offlineCache.entries) {
        cacheMap[entry.key] = {
          'data': entry.value.data,
          'timestamp': entry.value.timestamp.millisecondsSinceEpoch,
          'ttl': entry.value.ttl.inMilliseconds,
        };
      }

      await prefs.setString('offline_cache', jsonEncode(cacheMap));
    } catch (e) {
      _logger.w('⚠️ Error guardando cache offline: $e');
    }
  }

  Future<void> _loadOfflineCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('offline_cache');

      if (cacheString != null) {
        final cacheMap = jsonDecode(cacheString) as Map<String, dynamic>;

        for (final entry in cacheMap.entries) {
          final data = entry.value as Map<String, dynamic>;
          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
          final ttl = Duration(milliseconds: data['ttl']);

          // Solo cargar si no ha expirado
          if (DateTime.now().difference(timestamp) < ttl) {
            _offlineCache[entry.key] = OfflineCacheEntry(
              key: entry.key,
              data: data['data'],
              timestamp: timestamp,
              ttl: ttl,
            );
          }
        }

        _logger.d('💾 Cache offline cargado: ${_offlineCache.length} entradas');
      }
    } catch (e) {
      _logger.w('⚠️ Error cargando cache offline: $e');
    }
  }

  void _cleanupOldestCacheEntry() {
    if (_offlineCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _offlineCache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _offlineCache.remove(oldestKey);
    }
  }

  /// ⚙️ Configuración
  void setUpdateFrequency(Duration frequency) {
    _updateFrequency = frequency;
    _setupConnectivityMonitoring(); // Reiniciar con nueva frecuencia
    _logger.d('⚙️ Frecuencia de actualización cambiada: $frequency');
  }

  void enableOfflineMode(bool enabled) {
    _isOfflineModeEnabled = enabled;
    _logger.i('📱 Modo offline ${enabled ? 'habilitado' : 'deshabilitado'}');
  }

  void configureRetry({
    int? maxAttempts,
    Duration? retryDelay,
  }) {
    if (maxAttempts != null) _maxRetryAttempts = maxAttempts;
    if (retryDelay != null) _retryDelay = retryDelay;

    _logger.i(
        '🔄 Configuración de retry: Max=$_maxRetryAttempts, Delay=$_retryDelay');
  }

  void enableAutoSync(bool enabled, {Duration? interval}) {
    _isAutoSyncEnabled = enabled;
    if (interval != null) _syncInterval = interval;

    if (enabled) {
      _startAutoSync();
    } else {
      _syncTimer?.cancel();
    }

    _logger.i(
        '🔄 Sincronización automática ${enabled ? 'habilitada' : 'deshabilitada'}');
  }

  /// 📊 Estado y métricas
  bool isConnected() => _isConnected;
  bool isOfflineModeEnabled() => _isOfflineModeEnabled;
  ConnectivityResult getCurrentConnectivity() => _currentConnectivity;
  ConnectionQuality getConnectionQuality() => _connectionQuality;

  Future<Map<String, dynamic>> getConnectivityStatus() async {
    await _updateConnectivityStatus();

    return {
      'isConnected': _isConnected,
      'connectivityType': _currentConnectivity.toString(),
      'quality': _connectionQuality.toString(),
      'isOfflineModeEnabled': _isOfflineModeEnabled,
      'pendingRequestsCount': _pendingRequests.length,
      'cacheSize': _offlineCache.length,
      'totalOfflineTime': _totalOfflineTime.inMinutes,
      'lastConnectedTime': _lastConnectedTime?.toIso8601String(),
      'isSyncInProgress': _isSyncInProgress,
    };
  }

  Map<String, dynamic> getConnectivityStatistics() {
    if (_connectivityHistory.isEmpty) {
      return {
        'totalReadings': 0,
        'connectionUptime': 100.0,
        'mostCommonType': _currentConnectivity.toString(),
        'qualityDistribution': {},
      };
    }

    final totalReadings = _connectivityHistory.length;
    final connectedReadings =
        _connectivityHistory.where((r) => r.isConnected).length;
    final uptime = (connectedReadings / totalReadings) * 100;

    // Tipo más común
    final typeCount = <ConnectivityResult, int>{};
    for (final reading in _connectivityHistory) {
      typeCount[reading.connectivityType] =
          (typeCount[reading.connectivityType] ?? 0) + 1;
    }
    final mostCommonType =
        typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Distribución de calidad
    final qualityCount = <ConnectionQuality, int>{};
    for (final reading in _connectivityHistory) {
      qualityCount[reading.quality] = (qualityCount[reading.quality] ?? 0) + 1;
    }

    return {
      'totalReadings': totalReadings,
      'connectionUptime': uptime,
      'mostCommonType': mostCommonType.toString(),
      'qualityDistribution':
          qualityCount.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  /// 📞 Callbacks de eventos
  void addConnectivityCallback(Function(bool) callback) {
    _connectivityCallbacks.add(callback);
  }

  void addConnectivityTypeCallback(Function(ConnectivityResult) callback) {
    _connectivityTypeCallbacks.add(callback);
  }

  void addQualityCallback(Function(ConnectionQuality) callback) {
    _qualityCallbacks.add(callback);
  }

  void _notifyConnectivityCallbacks(bool isConnected) {
    for (final callback in _connectivityCallbacks) {
      try {
        callback(isConnected);
      } catch (e) {
        _logger.w('⚠️ Error en callback de conectividad: $e');
      }
    }
  }

  void _notifyConnectivityTypeCallbacks(ConnectivityResult type) {
    for (final callback in _connectivityTypeCallbacks) {
      try {
        callback(type);
      } catch (e) {
        _logger.w('⚠️ Error en callback de tipo de conectividad: $e');
      }
    }
  }

  void _notifyQualityCallbacks(ConnectionQuality quality) {
    for (final callback in _qualityCallbacks) {
      try {
        callback(quality);
      } catch (e) {
        _logger.w('⚠️ Error en callback de calidad: $e');
      }
    }
  }

  /// 🎯 Optimización forzada
  Future<void> forceOptimization() async {
    _logger.i('🎯 Forzando optimización de conectividad...');

    // Limpiar cache expirado
    final expiredKeys = <String>[];
    final now = DateTime.now();

    for (final entry in _offlineCache.entries) {
      if (now.difference(entry.value.timestamp) > entry.value.ttl) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _offlineCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      await _saveOfflineCache();
      _logger.d('🗂️ Cache expirado limpiado: ${expiredKeys.length} entradas');
    }

    // Intentar sincronización si hay conexión
    if (_isConnected && _pendingRequests.isNotEmpty) {
      await syncPendingRequests();
    }

    _logger.i('✅ Optimización de conectividad completada');
  }

  /// 🛑 Dispose
  void dispose() {
    _connectivityMonitorTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _offlineCache.clear();
    _pendingRequests.clear();
    _connectivityHistory.clear();
    _connectivityCallbacks.clear();
    _connectivityTypeCallbacks.clear();
    _qualityCallbacks.clear();
    _isInitialized = false;

    _logger.i('🛑 Connectivity Manager disposed');
  }
}

/// 📊 Calidad de conexión
enum ConnectionQuality {
  unknown,
  none,
  poor,
  fair,
  good,
  excellent,
}

/// 📊 Modelo de lectura de conectividad
class ConnectivityReading {
  final ConnectivityResult connectivityType;
  final bool isConnected;
  final ConnectionQuality quality;
  final DateTime timestamp;

  ConnectivityReading({
    required this.connectivityType,
    required this.isConnected,
    required this.quality,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ConnectivityReading(type: $connectivityType, connected: $isConnected, quality: $quality, time: $timestamp)';
  }
}

/// 🗂️ Entrada de cache offline
class OfflineCacheEntry {
  final String key;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration ttl;

  OfflineCacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  @override
  String toString() {
    return 'OfflineCacheEntry(key: $key, time: $timestamp, ttl: $ttl)';
  }
}

/// 📨 Request pendiente
class PendingRequest {
  final String id;
  final String url;
  final String method;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  int attempts;

  PendingRequest({
    required this.id,
    required this.url,
    required this.method,
    required this.data,
    required this.timestamp,
    this.attempts = 0,
  });

  @override
  String toString() {
    return 'PendingRequest(id: $id, method: $method, url: $url, attempts: $attempts)';
  }
}

/// 🔄 Configuración de retry
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;

  RetryConfig({
    required this.maxAttempts,
    required this.initialDelay,
    this.backoffMultiplier = 2.0,
  });
}
