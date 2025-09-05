// lib/core/performance/android_optimizations.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:geo_asist_front/core/utils/app_logger.dart';

/// Android-specific performance optimizations for GeoAsist
/// Focused on battery life, memory management, and Play Store requirements
class AndroidPerformanceOptimizer {
  static AndroidPerformanceOptimizer? _instance;
  static AndroidPerformanceOptimizer get instance {
    _instance ??= AndroidPerformanceOptimizer._();
    return _instance!;
  }
  
  AndroidPerformanceOptimizer._();
  
  Timer? _batteryOptimizationTimer;
  bool _isBackgroundOptimized = false;

  /// Initialize Android-specific optimizations
  void initialize() {
    _optimizeForAndroid();
    _setupBatteryOptimization();
    _optimizeMemoryUsage();
  }

  /// Configure Android-specific system UI
  void _optimizeForAndroid() {
    if (Platform.isAndroid) {
      // Set Android-specific system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Optimize for Android edge-to-edge
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );
    }
  }

  /// Battery optimization for background location tracking
  void _setupBatteryOptimization() {
    _batteryOptimizationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _optimizeBatteryUsage(),
    );
  }

  void _optimizeBatteryUsage() {
    // Reduce location update frequency when app is in background
    if (!_isAppInForeground()) {
      _reduceBackgroundOperations();
    } else {
      _restoreNormalOperations();
    }
  }

  bool _isAppInForeground() {
    return WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _reduceBackgroundOperations() {
    if (!_isBackgroundOptimized) {
      _isBackgroundOptimized = true;
      // Signal to reduce GPS precision, network calls, etc.
      logger.d('🔋 Android: Optimizing for background operations');
    }
  }

  void _restoreNormalOperations() {
    if (_isBackgroundOptimized) {
      _isBackgroundOptimized = false;
      logger.d('⚡ Android: Restored normal operations');
    }
  }

  /// Memory management optimization
  void _optimizeMemoryUsage() {
    // Trigger garbage collection hints
    Timer.periodic(const Duration(minutes: 10), (timer) {
      _triggerMemoryCleanup();
    });
  }

  void _triggerMemoryCleanup() {
    // Clear image caches periodically
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    logger.d('🧹 Android: Memory cleanup performed');
  }

  /// Dispose resources
  void dispose() {
    _batteryOptimizationTimer?.cancel();
    _batteryOptimizationTimer = null;
  }

  /// Check if device supports background location
  bool get supportsBackgroundLocation => Platform.isAndroid;

  /// Get recommended location accuracy for Android
  LocationAccuracy get recommendedLocationAccuracy {
    return _isBackgroundOptimized 
        ? LocationAccuracy.low
        : LocationAccuracy.high;
  }
}

/// Android-specific location accuracy enum
enum LocationAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
}

/// Android Material 3 widget optimizations
class AndroidMaterial3Widgets {
  /// Create Android-optimized Material 3 AppBar
  static AppBar createOptimizedAppBar({
    required String title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool centerTitle = false, // Android default
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 4,
      surfaceTintColor: Colors.transparent,
    );
  }

  /// Create Android-optimized Bottom Navigation Bar
  static Widget createOptimizedBottomNavigation({
    required int currentIndex,
    required List<BottomNavigationBarItem> items,
    required ValueChanged<int> onTap,
  }) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items.map((item) => NavigationDestination(
        icon: item.icon,
        label: item.label!,
        selectedIcon: item.activeIcon,
      )).toList(),
      elevation: 8,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Create Android-optimized Floating Action Button
  static Widget createOptimizedFAB({
    required VoidCallback onPressed,
    required Widget child,
    String? heroTag,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: heroTag,
      elevation: 6,
      highlightElevation: 8,
      child: child,
    );
  }

  /// Create Android-optimized Dialog
  static Widget createOptimizedDialog({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      actionsPadding: const EdgeInsets.all(16),
    );
  }
}

/// Android-specific performance monitoring
class AndroidPerformanceMonitor {
  static final List<PerformanceMetric> _metrics = [];
  
  /// Record a performance metric
  static void recordMetric({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    _metrics.add(PerformanceMetric(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));
    
    // Keep only last 100 metrics to prevent memory leaks
    if (_metrics.length > 100) {
      _metrics.removeRange(0, _metrics.length - 100);
    }
    
    // Log slow operations
    if (duration.inMilliseconds > 100) {
      logger.d('⚠️ Android Performance: Slow operation $operation: ${duration.inMilliseconds}ms');
    }
  }

  /// Get performance summary
  static PerformanceSummary getPerformanceSummary() {
    if (_metrics.isEmpty) {
      return PerformanceSummary.empty();
    }
    
    final durations = _metrics.map((m) => m.duration.inMilliseconds).toList();
    durations.sort();
    
    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final median = durations[durations.length ~/ 2];
    final p95 = durations[(durations.length * 0.95).round() - 1];
    
    return PerformanceSummary(
      averageDuration: avg,
      medianDuration: median.toDouble(),
      p95Duration: p95.toDouble(),
      totalOperations: _metrics.length,
      slowOperations: _metrics.where((m) => m.duration.inMilliseconds > 100).length,
    );
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });
}

/// Performance summary data class
class PerformanceSummary {
  final double averageDuration;
  final double medianDuration;
  final double p95Duration;
  final int totalOperations;
  final int slowOperations;

  const PerformanceSummary({
    required this.averageDuration,
    required this.medianDuration,
    required this.p95Duration,
    required this.totalOperations,
    required this.slowOperations,
  });

  factory PerformanceSummary.empty() {
    return const PerformanceSummary(
      averageDuration: 0,
      medianDuration: 0,
      p95Duration: 0,
      totalOperations: 0,
      slowOperations: 0,
    );
  }

  double get slowOperationPercentage {
    return totalOperations > 0 ? (slowOperations / totalOperations) * 100 : 0;
  }

  @override
  String toString() {
    return 'Performance Summary: '
        'Avg: ${averageDuration.toStringAsFixed(1)}ms, '
        'Median: ${medianDuration.toStringAsFixed(1)}ms, '
        'P95: ${p95Duration.toStringAsFixed(1)}ms, '
        'Slow ops: ${slowOperationPercentage.toStringAsFixed(1)}%';
  }
}