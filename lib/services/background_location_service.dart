// lib/services/background_location_service.dart
// ✅ ENHANCED: Optimized background location tracking
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'location_service.dart';
import 'dart:async';
import 'dart:convert';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

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
  static const Duration _criticalFrequency = Duration(seconds: 15);

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
      await Workmanager().registerPeriodicTask(
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
      await Workmanager().cancelByUniqueName(taskName);
      await Workmanager().cancelByUniqueName(pausedTaskName);
      
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
      await Workmanager().cancelByUniqueName(taskName);
      
      // ✅ ENHANCED: Start reduced frequency tracking
      await Workmanager().registerPeriodicTask(
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
      await Workmanager().cancelByUniqueName(pausedTaskName);
      
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
  
  /// ✅ ENHANCED: Get current tracking status
  Map<String, dynamic> getTrackingStatus() {
    return {
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'currentEventId': _currentEventId,
      'lastUpdate': _lastBackgroundUpdate?.toIso8601String(),
      'frequency': _isPaused ? _pausedFrequency.inSeconds : _normalFrequency.inSeconds,
    };
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
  
  /// ✅ ENHANCED: Initialize background service with recovery
  @override
  Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing enhanced background location service');
      
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      // ✅ ENHANCED: Recover tracking state if app was restarted
      await _recoverTrackingState();
      
      debugPrint('✅ Background location service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing background service: $e');
      rethrow;
    }
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
