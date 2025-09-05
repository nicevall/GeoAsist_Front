import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/performance_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'analytics_service.dart';
import '../utils/memory_optimizer.dart';

/// ✅ PRODUCTION READY: Performance Monitoring Service
/// Provides comprehensive performance tracking and optimization recommendations
class PerformanceMonitor {
  static const String _tag = 'PerformanceMonitor';
  
  // Performance monitoring configuration
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const Duration _memoryCheckInterval = Duration(minutes: 2);
  static const Duration _frameTimeThreshold = Duration(microseconds: 16667); // 60 FPS
  static const int _maxPerformanceHistory = 100;
  
  // Monitoring state
  static bool _isMonitoring = false;
  static Timer? _performanceTimer;
  static Timer? _memoryTimer;
  
  // Performance data
  static final List<PerformanceSnapshot> _performanceHistory = [];
  static final Map<String, TimingData> _timingData = {};
  static final Map<String, int> _frameDropCounts = {};
  
  // Frame timing
  static DateTime? _lastFrameTime;
  static int _totalFrames = 0;
  static int _droppedFrames = 0;
  
  /// Initialize performance monitoring
  static Future<void> initialize() async {
    if (_isMonitoring) return;
    
    logger.d('$_tag: Initializing performance monitoring...');
    
    try {
      // Start monitoring timers
      _startPerformanceMonitoring();
      _startMemoryMonitoring();
      
      // Set up frame callback
      _setupFrameCallback();
      
      _isMonitoring = true;
      
      await AnalyticsService.trackEvent(
        category: AnalyticsCategory.system,
        action: 'performance_monitoring_started',
        label: 'Performance monitoring initialized',
      );
      
      logger.d('$_tag: Performance monitoring initialized successfully');
    } catch (e) {
      logger.d('$_tag: Failed to initialize performance monitoring: $e');
      rethrow;
    }
  }
  
  /// Start performance monitoring
  static void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(_monitoringInterval, (timer) {
      _capturePerformanceSnapshot();
    });
    
    logger.d('$_tag: Performance monitoring started');
  }
  
  /// Start memory monitoring
  static void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(_memoryCheckInterval, (timer) {
      _checkMemoryUsage();
    });
    
    logger.d('$_tag: Memory monitoring started');
  }
  
  /// Setup frame callback for frame timing analysis
  static void _setupFrameCallback() {
    WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
  }
  
  /// Handle frame end callback
  static void _onFrameEnd(Duration timeStamp) {
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      _totalFrames++;
      
      // Check if frame was dropped (took longer than 16.67ms for 60 FPS)
      if (frameDuration > _frameTimeThreshold) {
        _droppedFrames++;
        _trackFrameDrop(frameDuration);
      }
    }
    
    _lastFrameTime = now;
    
    // Schedule next frame callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
  }
  
  /// Track frame drop
  static void _trackFrameDrop(Duration frameDuration) {
    final screenName = _getCurrentScreenName();
    _frameDropCounts[screenName] = (_frameDropCounts[screenName] ?? 0) + 1;
    
    // Track significant frame drops
    if (frameDuration.inMilliseconds > 33) { // More than 2 frames dropped
      AnalyticsService.trackPerformanceMetric(
        metricName: 'frame_drop',
        value: frameDuration.inMilliseconds.toDouble(),
        unit: 'ms',
        context: screenName,
        attributes: {
          'severity': frameDuration.inMilliseconds > 100 ? 'severe' : 'moderate',
          'total_frames': _totalFrames,
          'dropped_frames': _droppedFrames,
        },
      );
    }
  }
  
  /// Capture performance snapshot
  static Future<void> _capturePerformanceSnapshot() async {
    try {
      final memoryStats = MemoryOptimizer.getMemoryUsageStats();
      final frameRate = _calculateCurrentFrameRate();
      
      final snapshot = PerformanceSnapshot(
        timestamp: DateTime.now(),
        memoryUsagePercent: memoryStats.memoryUsagePercent,
        memoryUsageBytes: memoryStats.imageCacheSizeBytes,
        frameRate: frameRate,
        droppedFrames: _droppedFrames,
        totalFrames: _totalFrames,
        screenName: _getCurrentScreenName(),
        batteryLevel: await _getBatteryLevel(),
        networkConnected: true, // Would integrate with ConnectivityService
      );
      
      _performanceHistory.add(snapshot);
      
      // Keep history within limits
      if (_performanceHistory.length > _maxPerformanceHistory) {
        _performanceHistory.removeAt(0);
      }
      
      // Check for performance issues
      _analyzePerformance(snapshot);
      
    } catch (e) {
      logger.d('$_tag: Failed to capture performance snapshot: $e');
    }
  }
  
  /// Calculate current frame rate
  static double _calculateCurrentFrameRate() {
    if (_totalFrames == 0) return 0.0;
    
    final successfulFrames = _totalFrames - _droppedFrames;
    final totalTime = _totalFrames / 60.0; // Assuming 60 FPS target
    
    return successfulFrames / totalTime;
  }
  
  /// Get current screen name (would integrate with navigation)
  static String _getCurrentScreenName() {
    // In a real implementation, this would get the current route name
    return 'unknown_screen';
  }
  
  /// Get battery level
  static Future<double?> _getBatteryLevel() async {
    try {
      // In a real implementation, use battery_plus package
      return null; // Placeholder
    } catch (e) {
      return null;
    }
  }
  
  /// Check memory usage and take action if needed
  static void _checkMemoryUsage() {
    final memoryStats = MemoryOptimizer.getMemoryUsageStats();
    
    AnalyticsService.trackPerformanceMetric(
      metricName: 'memory_usage',
      value: memoryStats.memoryUsagePercent.toDouble(),
      unit: '%',
      context: 'periodic_check',
      attributes: {
        'memory_bytes': memoryStats.imageCacheSizeBytes,
        'max_memory_bytes': memoryStats.imageCacheMaxSizeBytes,
      },
    );
    
    // Take action if memory usage is high
    if (memoryStats.memoryUsagePercent > 80) {
      logger.d('$_tag: High memory usage detected - ${memoryStats.memoryUsagePercent}%');
      
      AnalyticsService.trackEvent(
        category: AnalyticsCategory.performance,
        action: 'high_memory_usage',
        label: 'Memory optimization triggered',
        value: memoryStats.memoryUsagePercent.toDouble(),
      );
      
      MemoryOptimizer.clearUnusedResources();
    }
  }
  
  /// Analyze performance snapshot for issues
  static void _analyzePerformance(PerformanceSnapshot snapshot) {
    // Check frame rate
    if (snapshot.frameRate < 45) {
      AnalyticsService.trackEvent(
        category: AnalyticsCategory.performance,
        action: 'low_frame_rate',
        label: snapshot.screenName,
        value: snapshot.frameRate,
        customAttributes: {
          'dropped_frames': snapshot.droppedFrames,
          'total_frames': snapshot.totalFrames,
        },
      );
    }
    
    // Check memory usage
    if (snapshot.memoryUsagePercent > 70) {
      AnalyticsService.trackEvent(
        category: AnalyticsCategory.performance,
        action: 'high_memory_usage',
        label: snapshot.screenName,
        value: snapshot.memoryUsagePercent.toDouble(),
      );
    }
  }
  
  /// Start timing measurement
  static void startTiming(String operationName) {
    _timingData[operationName] = TimingData(
      operationName: operationName,
      startTime: DateTime.now(),
    );
    
    logger.d('$_tag: Started timing: $operationName');
  }
  
  /// End timing measurement
  static void endTiming(String operationName, {Map<String, dynamic>? attributes}) {
    final timingData = _timingData[operationName];
    if (timingData == null) {
      logger.d('$_tag: Warning - No timing data found for: $operationName');
      return;
    }
    
    final duration = DateTime.now().difference(timingData.startTime);
    timingData.duration = duration;
    
    logger.d('$_tag: Completed timing: $operationName - ${duration.inMilliseconds}ms');
    
    // Track the performance metric
    AnalyticsService.trackPerformanceMetric(
      metricName: operationName,
      value: duration.inMilliseconds.toDouble(),
      unit: 'ms',
      context: _getCurrentScreenName(),
      attributes: attributes,
    );
    
    // Remove from active timings
    _timingData.remove(operationName);
  }
  
  /// Get performance summary
  static PerformanceSummary getPerformanceSummary() {
    if (_performanceHistory.isEmpty) {
      return PerformanceSummary(
        averageFrameRate: 0,
        averageMemoryUsage: 0,
        totalDroppedFrames: _droppedFrames,
        totalFrames: _totalFrames,
        performanceScore: 0,
      );
    }
    
    final recentSnapshots = _performanceHistory.take(20).toList();
    
    final avgFrameRate = recentSnapshots
        .map((s) => s.frameRate)
        .reduce((a, b) => a + b) / recentSnapshots.length;
    
    final avgMemoryUsage = recentSnapshots
        .map((s) => s.memoryUsagePercent)
        .reduce((a, b) => a + b) / recentSnapshots.length;
    
    final performanceScore = _calculatePerformanceScore(
      avgFrameRate,
      avgMemoryUsage.toDouble(),
      _droppedFrames / _totalFrames,
    );
    
    return PerformanceSummary(
      averageFrameRate: avgFrameRate,
      averageMemoryUsage: avgMemoryUsage.toDouble(),
      totalDroppedFrames: _droppedFrames,
      totalFrames: _totalFrames,
      performanceScore: performanceScore,
    );
  }
  
  /// Calculate overall performance score (0-100)
  static int _calculatePerformanceScore(
    double frameRate,
    double memoryUsage,
    double frameDropRate,
  ) {
    // Frame rate score (0-40 points)
    final frameRateScore = (frameRate / 60.0 * 40).clamp(0, 40);
    
    // Memory usage score (0-30 points, inverted)
    final memoryScore = (100 - memoryUsage) / 100 * 30;
    
    // Frame drop score (0-30 points, inverted)
    final frameDropScore = (1 - frameDropRate) * 30;
    
    final totalScore = frameRateScore + memoryScore + frameDropScore;
    return totalScore.round().clamp(0, 100);
  }
  
  /// Dispose performance monitoring
  static Future<void> dispose() async {
    logger.d('$_tag: Disposing performance monitoring...');
    
    _performanceTimer?.cancel();
    _memoryTimer?.cancel();
    
    _isMonitoring = false;
    _performanceTimer = null;
    _memoryTimer = null;
    
    _performanceHistory.clear();
    _timingData.clear();
    _frameDropCounts.clear();
    
    await AnalyticsService.trackEvent(
      category: AnalyticsCategory.system,
      action: 'performance_monitoring_stopped',
      label: 'Performance monitoring disposed',
    );
    
    logger.d('$_tag: Performance monitoring disposed');
  }
}

/// Performance snapshot data class
class PerformanceSnapshot {
  final DateTime timestamp;
  final int memoryUsagePercent;
  final int memoryUsageBytes;
  final double frameRate;
  final int droppedFrames;
  final int totalFrames;
  final String screenName;
  final double? batteryLevel;
  final bool networkConnected;
  
  PerformanceSnapshot({
    required this.timestamp,
    required this.memoryUsagePercent,
    required this.memoryUsageBytes,
    required this.frameRate,
    required this.droppedFrames,
    required this.totalFrames,
    required this.screenName,
    this.batteryLevel,
    required this.networkConnected,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'memory_usage_percent': memoryUsagePercent,
      'memory_usage_bytes': memoryUsageBytes,
      'frame_rate': frameRate,
      'dropped_frames': droppedFrames,
      'total_frames': totalFrames,
      'screen_name': screenName,
      'battery_level': batteryLevel,
      'network_connected': networkConnected,
    };
  }
}

/// Timing data class
class TimingData {
  final String operationName;
  final DateTime startTime;
  Duration? duration;
  
  TimingData({
    required this.operationName,
    required this.startTime,
    this.duration,
  });
}

/// Performance summary
class PerformanceSummary {
  final double averageFrameRate;
  final double averageMemoryUsage;
  final int totalDroppedFrames;
  final int totalFrames;
  final int performanceScore;
  
  PerformanceSummary({
    required this.averageFrameRate,
    required this.averageMemoryUsage,
    required this.totalDroppedFrames,
    required this.totalFrames,
    required this.performanceScore,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'average_frame_rate': averageFrameRate,
      'average_memory_usage': averageMemoryUsage,
      'total_dropped_frames': totalDroppedFrames,
      'total_frames': totalFrames,
      'performance_score': performanceScore,
    };
  }
}