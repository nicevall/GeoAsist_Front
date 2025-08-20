// lib/services/location_service.dart
// ✅ ENHANCED: Optimized location service for consistent updates
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/location_response_model.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ApiService _apiService = ApiService();
  
  // ✅ ENHANCED: Location caching and consistency management
  Position? _lastKnownPosition;
  DateTime? _lastPositionUpdate;
  LocationResponseModel? _lastLocationResponse;
  DateTime? _lastBackendUpdate;
  
  // ✅ ENHANCED: Update frequency and performance controls
  static const Duration _minUpdateInterval = Duration(seconds: 10);
  static const Duration _cacheValidityDuration = Duration(seconds: 30);
  static const double _significantDistanceChange = 5.0; // meters
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // ✅ ENHANCED: Performance tracking
  final List<LocationPerformanceMetric> _performanceMetrics = [];
  Timer? _performanceCleanupTimer;
  
  // ✅ ENHANCED: Connection status tracking
  bool _isOnline = true;
  final List<LocationUpdate> _offlineQueue = [];

  /// ✅ ENHANCED: Legacy method with modern optimizations
  Future<ApiResponse<Map<String, dynamic>>> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    bool? previousState,
    String? eventoId,
  }) async {
    try {
      debugPrint('📍 Legacy location update (use updateUserLocationComplete instead)');
      
      // Use optimized method internally
      if (eventoId != null) {
        final result = await updateUserLocationComplete(
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          eventoId: eventoId,
          backgroundUpdate: false,
        );
        
        if (result != null) {
          return ApiResponse.success(result.toJson(), message: 'Location updated');
        }
      }
      
      // Fallback to direct API call
      final body = {
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (previousState != null) 'previousState': previousState,
        if (eventoId != null) 'eventoId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiService.post(
        AppConstants.locationEndpoint,
        body: body,
      );

      if (response.success) {
        return ApiResponse.success(response.data!, message: response.message);
      }

      return ApiResponse.error(
          response.error ?? 'Error al actualizar ubicación');
    } catch (e) {
      debugPrint('❌ Legacy location update error: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // This method has been moved and enhanced above

  /// ✅ ENHANCED: Get current GPS position with caching and optimization
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    final startTime = DateTime.now();
    
    try {
      debugPrint('📍 Getting optimized GPS position (force: $forceRefresh)');

      // ✅ ENHANCED: Use cached position if valid and no force refresh
      if (!forceRefresh && _canUseCachedPosition()) {
        debugPrint('✅ Using cached GPS position (${_cacheAge().inSeconds}s old)');
        _recordPerformanceMetric('cached_position', startTime, true);
        return _lastKnownPosition;
      }

      // ✅ ENHANCED: Verify permissions with detailed handling
      final permissionStatus = await _checkAndRequestPermissions();
      if (!permissionStatus) {
        _recordPerformanceMetric('permission_denied', startTime, false);
        return null;
      }

      // ✅ ENHANCED: Get position with retry mechanism
      final position = await _getPositionWithRetry();
      
      if (position != null) {
        // ✅ ENHANCED: Validate position quality
        if (_isPositionValid(position)) {
          _lastKnownPosition = position;
          _lastPositionUpdate = DateTime.now();
          
          debugPrint('✅ Fresh position obtained: (${position.latitude}, ${position.longitude})');
          debugPrint('   - Accuracy: ${position.accuracy}m');
          debugPrint('   - Age: ${DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)).inSeconds}s');
          
          _recordPerformanceMetric('fresh_position', startTime, true);
        } else {
          debugPrint('⚠️ Position quality insufficient, using fallback');
          _recordPerformanceMetric('poor_quality', startTime, false);
          return _lastKnownPosition; // Return last known good position
        }
      } else {
        _recordPerformanceMetric('position_failed', startTime, false);
      }

      return position;
    } catch (e) {
      debugPrint('❌ Error getting GPS position: $e');
      _recordPerformanceMetric('exception', startTime, false);
      
      // ✅ ENHANCED: Return cached position as fallback
      if (_lastKnownPosition != null) {
        debugPrint('💾 Using last known position as fallback');
        return _lastKnownPosition;
      }
      
      return null;
    }
  }
  
  /// ✅ ENHANCED: Location update with intelligent batching and optimization
  Future<LocationResponseModel?> updateUserLocationComplete({
    required String userId,
    required double latitude,
    required double longitude,
    required String eventoId,
    bool backgroundUpdate = false,
    bool forceSend = false,
  }) async {
    final startTime = DateTime.now();
    
    try {
      debugPrint('📍 Optimized location update to backend');
      debugPrint('   - User: $userId');
      debugPrint('   - Coordinates: ($latitude, $longitude)');
      debugPrint('   - Event: $eventoId');
      debugPrint('   - Background: $backgroundUpdate');
      debugPrint('   - Force: $forceSend');

      // ✅ ENHANCED: Check if update is necessary
      if (!forceSend && !_shouldSendUpdate(latitude, longitude, backgroundUpdate)) {
        debugPrint('⏭️ Skipping update - too frequent or insignificant change');
        _recordPerformanceMetric('update_skipped', startTime, true);
        return _lastLocationResponse;
      }

      // ✅ ENHANCED: Handle offline mode
      if (!_isOnline) {
        debugPrint('📶 Offline mode - queuing update');
        _queueOfflineUpdate(userId, latitude, longitude, eventoId, backgroundUpdate);
        return _lastLocationResponse;
      }

      // ✅ ENHANCED: Send with retry mechanism
      final response = await _sendLocationUpdateWithRetry(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        eventoId: eventoId,
        backgroundUpdate: backgroundUpdate,
      );

      if (response != null) {
        _lastLocationResponse = response;
        _lastBackendUpdate = DateTime.now();
        
        debugPrint('✅ Backend response processed successfully:');
        debugPrint('   - Inside geofence: ${response.insideGeofence}');
        debugPrint('   - Distance: ${response.distance}m');
        debugPrint('   - Event active: ${response.eventActive}');
        debugPrint('   - Can register: ${response.canRegisterAttendance}');
        
        _recordPerformanceMetric('update_success', startTime, true);
        
        // ✅ ENHANCED: Process offline queue if we're back online
        _processOfflineQueue();
      } else {
        debugPrint('❌ Location update failed');
        _recordPerformanceMetric('update_failed', startTime, false);
        _handleUpdateFailure();
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error in updateUserLocationComplete: $e');
      _recordPerformanceMetric('update_exception', startTime, false);
      _handleUpdateFailure();
      return _lastLocationResponse; // Return cached response
    }
  }

  // ✅ ENHANCED: Helper methods for optimization
  
  /// Check if cached position can be used
  bool _canUseCachedPosition() {
    if (_lastKnownPosition == null || _lastPositionUpdate == null) {
      return false;
    }
    
    return _cacheAge() < _cacheValidityDuration;
  }
  
  /// Get cache age
  Duration _cacheAge() {
    if (_lastPositionUpdate == null) return Duration(hours: 1);
    return DateTime.now().difference(_lastPositionUpdate!);
  }
  
  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        debugPrint('🔑 Requesting location permissions');
        permission = await Geolocator.requestPermission();
      }
      
      switch (permission) {
        case LocationPermission.denied:
          debugPrint('❌ Location permissions denied');
          return false;
        case LocationPermission.deniedForever:
          debugPrint('❌ Location permissions permanently denied');
          return false;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          debugPrint('✅ Location permissions granted: $permission');
          return true;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      return false;
    }
  }
  
  /// Get position with retry mechanism
  Future<Position?> _getPositionWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        debugPrint('🎯 GPS attempt $attempt of $_maxRetryAttempts');
        
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8 + (attempt * 2)), // Progressive timeout
            distanceFilter: 1, // Only update if moved at least 1 meter
          ),
        ).timeout(Duration(seconds: 10 + (attempt * 2)));
        
        debugPrint('✅ GPS position obtained on attempt $attempt');
        return position;
      } catch (e) {
        debugPrint('❌ GPS attempt $attempt failed: $e');
        
        if (attempt < _maxRetryAttempts) {
          debugPrint('🔄 Retrying in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
        }
      }
    }
    
    debugPrint('❌ All GPS attempts failed');
    return null;
  }
  
  /// Validate position quality
  bool _isPositionValid(Position position) {
    // Check accuracy threshold
    if (position.accuracy > 50.0) {
      debugPrint('⚠️ Position accuracy poor: ${position.accuracy}m');
      return false;
    }
    
    // Check if position is too old
    final positionAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)
    );
    if (positionAge > Duration(minutes: 5)) {
      debugPrint('⚠️ Position too old: ${positionAge.inMinutes}min');
      return false;
    }
    
    // Check for invalid coordinates
    if (position.latitude.abs() > 90 || position.longitude.abs() > 180) {
      debugPrint('⚠️ Invalid coordinates: (${position.latitude}, ${position.longitude})');
      return false;
    }
    
    return true;
  }
  
  /// Check if location update should be sent
  bool _shouldSendUpdate(double lat, double lng, bool backgroundUpdate) {
    // Always send if no previous update
    if (_lastBackendUpdate == null) return true;
    
    // Check time-based throttling
    final timeSinceLastUpdate = DateTime.now().difference(_lastBackendUpdate!);
    if (timeSinceLastUpdate < _minUpdateInterval && !backgroundUpdate) {
      return false;
    }
    
    // Check distance-based filtering
    if (_lastLocationResponse != null) {
      final distance = _calculateDistance(
        lat, lng, 
        _lastLocationResponse!.latitude, 
        _lastLocationResponse!.longitude
      );
      
      if (distance < _significantDistanceChange && !backgroundUpdate) {
        debugPrint('📎 Distance change insignificant: ${distance.toStringAsFixed(1)}m');
        return false;
      }
    }
    
    return true;
  }
  
  /// Calculate distance between two points
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
  
  /// Send location update with retry
  Future<LocationResponseModel?> _sendLocationUpdateWithRetry({
    required String userId,
    required double latitude,
    required double longitude,
    required String eventoId,
    required bool backgroundUpdate,
  }) async {
    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        debugPrint('📤 Location update attempt $attempt of $_maxRetryAttempts');
        
        final response = await _apiService.post(
          AppConstants.locationEndpoint,
          body: {
            'userId': userId,
            'latitude': latitude,
            'longitude': longitude,
            'eventoId': eventoId,
            'backgroundUpdate': backgroundUpdate,
            'timestamp': DateTime.now().toIso8601String(),
            'attempt': attempt,
          },
        ).timeout(Duration(seconds: 10 + (attempt * 2)));

        if (response.success && response.data != null) {
          final locationResponse = LocationResponseModel.fromSimpleResponse(response.data!);
          debugPrint('✅ Location update successful on attempt $attempt');
          return locationResponse;
        } else {
          debugPrint('❌ Backend rejected update on attempt $attempt: ${response.message}');
          if (attempt == _maxRetryAttempts) {
            return LocationResponseModel.error(userId, latitude, longitude);
          }
        }
      } catch (e) {
        debugPrint('❌ Location update attempt $attempt failed: $e');
        
        if (attempt < _maxRetryAttempts) {
          debugPrint('🔄 Retrying location update in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
        }
      }
    }
    
    debugPrint('❌ All location update attempts failed');
    _isOnline = false; // Mark as offline
    return null;
  }
  
  /// Queue offline update
  void _queueOfflineUpdate(String userId, double lat, double lng, String eventoId, bool bg) {
    final update = LocationUpdate(
      userId: userId,
      latitude: lat,
      longitude: lng,
      eventoId: eventoId,
      backgroundUpdate: bg,
      timestamp: DateTime.now(),
    );
    
    _offlineQueue.add(update);
    debugPrint('💫 Queued offline update (${_offlineQueue.length} pending)');
    
    // Limit queue size
    if (_offlineQueue.length > 50) {
      _offlineQueue.removeAt(0);
      debugPrint('⚠️ Offline queue full, removed oldest update');
    }
  }
  
  /// Process offline queue
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    
    debugPrint('📤 Processing ${_offlineQueue.length} offline updates');
    
    final updates = List<LocationUpdate>.from(_offlineQueue);
    _offlineQueue.clear();
    
    for (final update in updates) {
      try {
        await _sendLocationUpdateWithRetry(
          userId: update.userId,
          latitude: update.latitude,
          longitude: update.longitude,
          eventoId: update.eventoId,
          backgroundUpdate: update.backgroundUpdate,
        );
        
        // Small delay between batch updates
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('❌ Failed to process offline update: $e');
        // Re-queue failed update
        _offlineQueue.add(update);
      }
    }
    
    _isOnline = true;
    debugPrint('✅ Offline queue processing completed');
  }
  
  /// Handle update failure
  void _handleUpdateFailure() {
    _isOnline = false;
    debugPrint('❌ Marking service as offline due to update failure');
  }
  
  /// Record performance metric
  void _recordPerformanceMetric(String operation, DateTime startTime, bool success) {
    final metric = LocationPerformanceMetric(
      operation: operation,
      startTime: startTime,
      endTime: DateTime.now(),
      success: success,
    );
    
    _performanceMetrics.add(metric);
    
    // Clean old metrics periodically
    if (_performanceMetrics.length > 100) {
      _performanceMetrics.removeRange(0, 20);
    }
    
    debugPrint('📊 Performance: $operation = ${metric.duration.inMilliseconds}ms (${success ? "success" : "failed"})');
  }
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_performanceMetrics.isEmpty) return {};
    
    final successful = _performanceMetrics.where((m) => m.success).toList();
    final failed = _performanceMetrics.where((m) => !m.success).toList();
    
    final avgDuration = successful.isEmpty ? 0 : 
      successful.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / successful.length;
    
    return {
      'total_operations': _performanceMetrics.length,
      'successful_operations': successful.length,
      'failed_operations': failed.length,
      'success_rate': _performanceMetrics.isEmpty ? 0 : successful.length / _performanceMetrics.length,
      'average_duration_ms': avgDuration.round(),
      'offline_queue_size': _offlineQueue.length,
      'is_online': _isOnline,
      'cache_age_seconds': _cacheAge().inSeconds,
    };
  }
  
  /// Cleanup resources
  void dispose() {
    debugPrint('🧹 Disposing LocationService resources');
    _performanceCleanupTimer?.cancel();
    _offlineQueue.clear();
    _performanceMetrics.clear();
    debugPrint('✅ LocationService disposed');
  }
}

// ✅ ENHANCED: Data classes for optimization

class LocationUpdate {
  final String userId;
  final double latitude;
  final double longitude;
  final String eventoId;
  final bool backgroundUpdate;
  final DateTime timestamp;
  
  LocationUpdate({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.eventoId,
    required this.backgroundUpdate,
    required this.timestamp,
  });
}

class LocationPerformanceMetric {
  final String operation;
  final DateTime startTime;
  final DateTime endTime;
  final bool success;
  
  LocationPerformanceMetric({
    required this.operation,
    required this.startTime,
    required this.endTime,
    required this.success,
  });
  
  Duration get duration => endTime.difference(startTime);
}
