// lib/services/background_location_service.dart
// ✅ ENHANCED: Optimized background location tracking
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'storage_service.dart';
import 'location_service.dart';
import 'dart:async';
import 'dart:convert';

class BackgroundLocationService {
  // ✅ SINGLETON SEGURO CON LAZY INITIALIZATION
  static BackgroundLocationService? _instance;
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static Completer<BackgroundLocationService>? _initCompleter;
  
  // Constructor privado
  BackgroundLocationService._internal();
  
  // ✅ MÉTODO SEGURO DE OBTENCIÓN DE INSTANCIA CON LAZY INITIALIZATION
  static Future<BackgroundLocationService> getInstance() async {
    // Si ya está inicializado, devolver la instancia
    if (_instance != null && _isInitialized) {
      return _instance!;
    }
    
    // Si está en proceso de inicialización, esperar
    if (_isInitializing && _initCompleter != null) {
      return _initCompleter!.future;
    }
    
    // Comenzar nueva inicialización
    _isInitializing = true;
    _initCompleter = Completer<BackgroundLocationService>();
    
    try {
      _instance = BackgroundLocationService._internal();
      await _instance!._initialize();
      _isInitialized = true;
      _isInitializing = false;
      
      _initCompleter!.complete(_instance!);
      return _instance!;
    } catch (e) {
      debugPrint('❌ Error en inicialización de BackgroundService: $e');
      _isInitializing = false;
      _isInitialized = false;
      _instance = null;
      
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }
  
  // ✅ MÉTODO SÍNCRONO PARA CASOS QUE NO PUEDEN ESPERAR
  static BackgroundLocationService? getInstanceIfInitialized() {
    return (_instance != null && _isInitialized) ? _instance : null;
  }
  
  // ✅ MÉTODO DE CLEANUP PARA REINICIAR EL SINGLETON
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!.dispose();
    }
    _instance = null;
    _isInitialized = false;
    _isInitializing = false;
    _initCompleter = null;
    debugPrint('✅ BackgroundLocationService reset completed');
  }
  
  // ✅ MOCK WORKMANAGER FOR TESTS
  Workmanager? _mockWorkmanager;
  
  // Campos internos con inicialización segura
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionSubscription;
  LocationService? _locationService;
  bool _instanceInitialized = false; // Campo de instancia separado del estático
  
  /// ✅ FACTORY FOR TESTS WITH MOCK WORKMANAGER
  factory BackgroundLocationService.withMockWorkmanager(Workmanager mockWorkmanager) {
    final instance = BackgroundLocationService._testInstance();
    instance._mockWorkmanager = mockWorkmanager;
    return instance;
  }
  
  /// ✅ GETTER FOR WORKMANAGER (MOCK OR REAL)
  Workmanager get _workmanager => _mockWorkmanager ?? Workmanager();
  
  // 🧪 Test-specific constructor to create fresh instances
  BackgroundLocationService._testInstance() {
    _isTracking = false;
    _isPaused = false;
    _currentEventId = null;
    _lastBackgroundUpdate = null;
    _instanceInitialized = false;
    _locationService = null;
    _trackingTimer = null;
    _positionSubscription = null;
  }
  
  // 🧪 Public method to create test instances (bypasses singleton)
  static BackgroundLocationService createTestInstance() {
    return BackgroundLocationService._testInstance();
  }

  static const String taskName = "locationTracking";
  static const String pausedTaskName = "locationTracking_paused";
  
  // ✅ ENHANCED: Background service state management
  bool _isTracking = false;
  bool _isPaused = false;
  String? _currentEventId;
  DateTime? _lastBackgroundUpdate;
  
  // ✅ ENHANCED: Performance optimization
  static const Duration _normalFrequency = Duration(seconds: 30);
  static const Duration _pausedFrequency = Duration(minutes: 5);

  // This method has been moved and enhanced above

  /// ✅ ENHANCED: Start optimized event tracking with intelligent frequency
  Future<void> startEventTracking(String eventoId) async {
    try {
      debugPrint('🎯 Starting enhanced background tracking for event: $eventoId');

      // ✅ ENHANCED: Stop any existing tracking first
      await stopEventTracking();
      
      // ✅ ENHANCED: Store current tracking state
      _currentEventId = eventoId;
      _isTracking = true;
      _isPaused = false;
      _lastBackgroundUpdate = null;
      
      // ✅ ENHANCED: Store event ID for persistence across app restarts
      final storageService = StorageService();
      await storageService.saveData('background_tracking_event', eventoId);
      await storageService.saveData('background_tracking_active', 'true');

      // ✅ ENHANCED: Register optimized periodic task
      await _workmanager.registerPeriodicTask(
        taskName,
        taskName,
        frequency: _normalFrequency,
        initialDelay: const Duration(seconds: 15), // Faster initial start
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false, // Allow on low battery for attendance
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        inputData: {
          'eventoId': eventoId,
          'action': 'trackLocation',
          'startTime': DateTime.now().toIso8601String(),
          'version': '2.0',
        },
      );

      debugPrint('✅ Enhanced background tracking started for event: $eventoId');
      debugPrint('📊 Tracking frequency: ${_normalFrequency.inSeconds}s');
    } catch (e) {
      debugPrint('❌ Error starting background tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// ✅ ENHANCED: Stop tracking with comprehensive cleanup
  Future<void> stopEventTracking() async {
    try {
      debugPrint('🛑 Stopping enhanced background tracking');
      
      // ✅ ENHANCED: Cancel all related tasks
      await _workmanager.cancelByUniqueName(taskName);
      await _workmanager.cancelByUniqueName(pausedTaskName);
      
      // ✅ ENHANCED: Clear tracking state
      _isTracking = false;
      _isPaused = false;
      _currentEventId = null;
      _lastBackgroundUpdate = null;
      
      // ✅ ENHANCED: Clear persistent storage
      final storageService = StorageService();
      await storageService.removeData('background_tracking_event');
      await storageService.removeData('background_tracking_active');
      
      debugPrint('✅ Background tracking stopped and cleaned up');
    } catch (e) {
      debugPrint('❌ Error stopping background tracking: $e');
    }
  }

  /// ✅ NUEVO: Método de tracking continuo con Timer
  Future<bool> startContinuousTracking({
    required String userId,
    required String eventoId,
    Duration interval = const Duration(minutes: 2),
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ BackgroundService no inicializado');
      return false;
    }
    
    if (_isTracking) {
      debugPrint('⚠️ Tracking ya está activo');
      return true;
    }
    
    try {
      debugPrint('🎯 Iniciando tracking continuo para evento: $eventoId');
      
      _trackingTimer = Timer.periodic(interval, (timer) async {
        await _performBackgroundLocationUpdate(userId, eventoId);
      });
      
      _isTracking = true;
      _currentEventId = eventoId;
      debugPrint('✅ Tracking continuo iniciado');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error iniciando tracking continuo: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Realizar actualización de ubicación en background
  Future<void> _performBackgroundLocationUpdate(String userId, String eventoId) async {
    if (!_isInitialized || _locationService == null) {
      debugPrint('⚠️ Servicio no disponible para update background');
      return;
    }
    
    try {
      final position = await _locationService!.getCurrentPosition();
      if (position != null) {
        await _locationService!.updateUserLocationComplete(
          userId: userId,
          latitude: position.latitude,
          longitude: position.longitude,
          eventoId: eventoId,
          backgroundUpdate: true,
        );
        debugPrint('✅ Update background exitoso');
      }
    } catch (e) {
      debugPrint('❌ Error en update background: $e');
      // No detener tracking por un error individual
    }
  }

  /// ✅ NUEVO: Detener tracking con limpieza
  void stopTracking() {
    if (_trackingTimer != null) {
      _trackingTimer!.cancel();
      _trackingTimer = null;
    }
    
    if (_positionSubscription != null) {
      _positionSubscription!.cancel();
      _positionSubscription = null;
    }
    
    _isTracking = false;
    debugPrint('🛑 Tracking background detenido');
  }

  /// ✅ ENHANCED: Pause tracking with reduced frequency during breaks
  Future<void> pauseTracking() async {
    try {
      debugPrint('⏸️ Pausing background tracking for break');
      
      if (!_isTracking || _currentEventId == null) {
        debugPrint('⚠️ No active tracking to pause');
        return;
      }
      
      _isPaused = true;
      
      // ✅ ENHANCED: Cancel normal tracking
      await _workmanager.cancelByUniqueName(taskName);
      
      // ✅ ENHANCED: Start reduced frequency tracking
      await _workmanager.registerPeriodicTask(
        pausedTaskName,
        pausedTaskName,
        frequency: _pausedFrequency,
        initialDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
        inputData: {
          'eventoId': _currentEventId!,
          'action': 'pausedMode',
          'pauseStartTime': DateTime.now().toIso8601String(),
          'version': '2.0',
        },
      );
      
      debugPrint('✅ Background tracking paused - reduced frequency: ${_pausedFrequency.inMinutes}min');
    } catch (e) {
      debugPrint('❌ Error pausing background tracking: $e');
    }
  }

  /// ✅ ENHANCED: Resume tracking with optimized transition
  Future<void> resumeTracking(String eventoId) async {
    try {
      debugPrint('▶️ Resuming background tracking after break');
      
      // ✅ ENHANCED: Cancel paused tracking
      await _workmanager.cancelByUniqueName(pausedTaskName);
      
      // ✅ ENHANCED: Validate event ID consistency
      if (_currentEventId != null && _currentEventId != eventoId) {
        debugPrint('⚠️ Event ID mismatch during resume: $_currentEventId vs $eventoId');
      }
      
      // ✅ ENHANCED: Resume with immediate update
      _isPaused = false;
      await startEventTracking(eventoId);
      
      debugPrint('✅ Background tracking resumed successfully');
    } catch (e) {
      debugPrint('❌ Error resuming background tracking: $e');
      // Try to restart from scratch
      await startEventTracking(eventoId);
    }
  }
  
  /// ✅ MÉTODO DE ESTADO Y DEBUGGING
  Map<String, dynamic> getTrackingStatus() {
    return {
      'isInitialized': _isInitialized,
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'hasActiveTimer': _trackingTimer != null && _trackingTimer!.isActive,
      'hasLocationService': _locationService != null,
      'currentEventId': _currentEventId,
      'lastUpdate': _lastBackgroundUpdate?.toIso8601String(),
      'frequency': _isPaused ? _pausedFrequency.inSeconds : _normalFrequency.inSeconds,
      'instanceHash': hashCode,
    };
  }
  
  // ✅ GETTERS FOR TESTING
  bool get isTracking => _isTracking;
  bool get isInitialized => _instanceInitialized;
  String? get currentEventId => _currentEventId;
  
  /// ✅ MÉTODO DE DISPOSE PARA LIMPIAR RECURSOS
  Future<void> dispose() async {
    debugPrint('🧹 Disposing BackgroundLocationService...');
    
    stopTracking();
    
    if (_locationService != null) {
      _locationService!.dispose();
      _locationService = null;
    }
    
    _instanceInitialized = false;
    debugPrint('✅ BackgroundLocationService disposed');
  }
  
  /// ✅ ENHANCED: Force immediate background update
  Future<bool> forceBackgroundUpdate() async {
    if (!_isTracking || _currentEventId == null) {
      debugPrint('⚠️ No active tracking for forced update');
      return false;
    }
    
    try {
      debugPrint('⚡ Forcing immediate background update');
      
      // Execute the tracking function directly
      await _trackUserLocationEnhanced(_currentEventId!, immediate: true);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error in forced background update: $e');
      return false;
    }
  }
  
  /// ✅ INICIALIZACIÓN ROBUSTA CON ERROR HANDLING
  Future<void> _initialize() async {
    if (_instanceInitialized) {
      debugPrint('✅ BackgroundLocationService ya inicializado');
      return;
    }
    
    try {
      debugPrint('🚀 Inicializando BackgroundLocationService...');
      
      // 1. Inicializar LocationService
      _locationService = LocationService();
      
      // 2. Verificar permisos básicos
      final hasPermissions = await _checkBasicPermissions();
      if (!hasPermissions) {
        debugPrint('⚠️ Permisos de ubicación no otorgados - continuando en modo limitado');
        // No fallar completamente, solo marcar como limitado
      }
      
      // 3. Inicializar Workmanager con manejo de errores
      try {
        await _workmanager.initialize(callbackDispatcher);
        debugPrint('✅ Workmanager inicializado');
      } catch (e) {
        debugPrint('⚠️ Error inicializando Workmanager: $e');
        // Continuar sin Workmanager en entornos de test
      }
      
      // 4. Configurar tracking parameters
      _configureTrackingParameters();
      
      // 5. Recover tracking state if app was restarted
      await _recoverTrackingState();
      
      _instanceInitialized = true;
      debugPrint('✅ BackgroundLocationService inicializado correctamente');
      
    } catch (e) {
      debugPrint('❌ Error inicializando BackgroundLocationService: $e');
      _instanceInitialized = false;
      rethrow;
    }
  }
  
  /// ✅ VERIFICAR PERMISOS BÁSICOS
  Future<bool> _checkBasicPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('❌ Error verificando permisos: $e');
      return false;
    }
  }
  
  /// ✅ CONFIGURAR PARÁMETROS DE TRACKING
  void _configureTrackingParameters() {
    debugPrint('⚙️ Configurando parámetros de tracking background');
  }
  
  /// ✅ ENHANCED: Recover tracking state after app restart
  Future<void> _recoverTrackingState() async {
    try {
      final storageService = StorageService();
      final eventId = await storageService.getData('background_tracking_event');
      final isActive = await storageService.getData('background_tracking_active');
      
      if (eventId != null && isActive == 'true') {
        debugPrint('🔄 Recovering background tracking for event: $eventId');
        _currentEventId = eventId;
        _isTracking = true;
        // Note: Don't restart automatically - let the app decide
        debugPrint('✅ Tracking state recovered, waiting for explicit restart');
      }
    } catch (e) {
      debugPrint('❌ Error recovering tracking state: $e');
    }
  }
}

/// ✅ ENHANCED: Optimized background callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final startTime = DateTime.now();
      debugPrint('🎯 Enhanced background task starting: $task');
      debugPrint('📊 Input data: $inputData');

      final action = inputData?['action'] ?? 'unknown';
      final eventoId = inputData?['eventoId'];
      final version = inputData?['version'] ?? '1.0';
      
      debugPrint('🔧 Task version: $version, Action: $action');

      bool success = false;
      switch (action) {
        case 'trackLocation':
          success = await _trackUserLocationEnhanced(eventoId);
          break;
        case 'pausedMode':
          success = await _handlePausedMode(eventoId);
          break;
        default:
          debugPrint('⚠️ Unknown background action: $action');
          success = false;
      }

      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ Background task completed: $task (${duration.inMilliseconds}ms, success: $success)');
      
      return success;
    } catch (e, stackTrace) {
      debugPrint('❌ Critical error in background task: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  });
}

/// ✅ ENHANCED: Advanced background location tracking with optimization
Future<bool> _trackUserLocationEnhanced(String? eventoId, {bool immediate = false}) async {
  if (eventoId == null) {
    debugPrint('❌ No event ID provided for background tracking');
    return false;
  }

  final startTime = DateTime.now();
  
  try {
    debugPrint('🎯 Enhanced background tracking for event: $eventoId');

    // 1. ✅ ENHANCED: Verify permissions with detailed logging
    final permissionValid = await _verifyLocationPermissions();
    if (!permissionValid) {
      debugPrint('❌ Location permissions insufficient for background tracking');
      return false;
    }

    // 2. ✅ ENHANCED: Get high-quality position with retry
    final position = await _getBackgroundPosition();
    if (position == null) {
      debugPrint('❌ Failed to obtain GPS position in background');
      return false;
    }

    // 3. ✅ ENHANCED: Validate position quality
    if (!_isBackgroundPositionValid(position)) {
      debugPrint('⚠️ Background position quality insufficient, skipping update');
      return false;
    }

    // 4. ✅ ENHANCED: Get user data with error handling
    final storageService = StorageService();
    final user = await storageService.getUser();
    if (user == null) {
      debugPrint('❌ No user data available for background tracking');
      return false;
    }

    // 5. ✅ ENHANCED: Use optimized location service
    final locationService = LocationService();
    final response = await locationService.updateUserLocationComplete(
      userId: user.id,
      latitude: position.latitude,
      longitude: position.longitude,
      eventoId: eventoId,
      backgroundUpdate: true,
      forceSend: immediate,
    );

    if (response != null) {
      debugPrint('✅ Background location sent successfully');
      debugPrint('📊 Response: inside=${response.insideGeofence}, distance=${response.distance}m');

      // 6. ✅ ENHANCED: Handle critical situations
      await _handleBackgroundResponse(response, eventoId);
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('⏱️ Background update completed in ${duration.inMilliseconds}ms');
      
      return true;
    } else {
      debugPrint('❌ Background location update failed');
      return false;
    }

  } catch (e, stackTrace) {
    final duration = DateTime.now().difference(startTime);
    debugPrint('❌ Error in enhanced background tracking: $e');
    debugPrint('⏱️ Failed after ${duration.inMilliseconds}ms');
    debugPrint('📍 Stack trace: $stackTrace');
    return false;
  }
}

/// ✅ ENHANCED: Handle paused mode tracking
Future<bool> _handlePausedMode(String? eventoId) async {
  if (eventoId == null) return false;
  
  try {
    debugPrint('⏸️ Background tracking in paused mode for event: $eventoId');
    
    // In paused mode, we still track but less frequently
    // This helps detect when user returns to event area
    final result = await _trackUserLocationEnhanced(eventoId);
    
    if (result) {
      debugPrint('✅ Paused mode tracking successful');
    } else {
      debugPrint('⚠️ Paused mode tracking failed');
    }
    
    return result;
  } catch (e) {
    debugPrint('❌ Error in paused mode tracking: $e');
    return false;
  }
}

/// ✅ ENHANCED: Verify location permissions for background
Future<bool> _verifyLocationPermissions() async {
  try {
    final permission = await Geolocator.checkPermission();
    
    switch (permission) {
      case LocationPermission.always:
        debugPrint('✅ Background location permission: Always granted');
        return true;
      case LocationPermission.whileInUse:
        debugPrint('⚠️ Background location permission: Only while in use');
        // Still allow - background tasks can run briefly after app backgrounded
        return true;
      case LocationPermission.denied:
        debugPrint('❌ Background location permission: Denied');
        return false;
      case LocationPermission.deniedForever:
        debugPrint('❌ Background location permission: Permanently denied');
        return false;
      default:
        debugPrint('❓ Background location permission: Unknown status');
        return false;
    }
  } catch (e) {
    debugPrint('❌ Error checking background permissions: $e');
    return false;
  }
}

/// ✅ ENHANCED: Get position optimized for background
Future<Position?> _getBackgroundPosition() async {
  try {
    // Background GPS requests should be faster and more battery-efficient
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // Medium accuracy for better battery
        timeLimit: Duration(seconds: 8), // Shorter timeout in background
        distanceFilter: 2, // Only update if moved 2+ meters
      ),
    ).timeout(const Duration(seconds: 10));

    debugPrint('📍 Background position: (${position.latitude}, ${position.longitude})');
    debugPrint('🎯 Accuracy: ${position.accuracy}m, Age: ${DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)).inSeconds}s');
    
    return position;
  } catch (e) {
    debugPrint('❌ Background GPS error: $e');
    
    // Try to get last known position as fallback
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        debugPrint('🔄 Using last known position as fallback');
        return lastPosition;
      }
    } catch (e2) {
      debugPrint('❌ Last known position also failed: $e2');
    }
    
    return null;
  }
}

/// ✅ ENHANCED: Validate background position quality
bool _isBackgroundPositionValid(Position position) {
  // More lenient validation for background (battery optimization)
  if (position.accuracy > 100.0) {
    debugPrint('⚠️ Background position accuracy too poor: ${position.accuracy}m');
    return false;
  }
  
  final positionAge = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)
  );
  if (positionAge > Duration(minutes: 10)) {
    debugPrint('⚠️ Background position too old: ${positionAge.inMinutes}min');
    return false;
  }
  
  return true;
}

/// ✅ ENHANCED: Handle background response with notifications
Future<void> _handleBackgroundResponse(dynamic response, String eventoId) async {
  try {
    // Check if user is outside geofence in an active event
    if (response.eventActive && response.eventStarted && !response.insideGeofence) {
      debugPrint('🚨 CRITICAL: User outside geofence during active event');
      debugPrint('📏 Distance from event: ${response.distance}m');
      
      // Could trigger local notification here if needed
      // Note: Be careful with notification frequency in background
      
      // Log this critical event for the app to handle when it comes to foreground
      final storageService = StorageService();
      await storageService.saveData('background_geofence_violation', jsonEncode({
        'eventId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
        'distance': response.distance,
        'coordinates': {
          'lat': response.latitude,
          'lng': response.longitude,
        }
      }));
      
      debugPrint('📝 Geofence violation logged for foreground handling');
    } else if (response.insideGeofence && response.eventActive) {
      debugPrint('✅ User properly inside event geofence');
      
      // Clear any previous violation
      final storageService = StorageService();
      await storageService.removeData('background_geofence_violation');
    }
  } catch (e) {
    debugPrint('❌ Error handling background response: $e');
  }
}
