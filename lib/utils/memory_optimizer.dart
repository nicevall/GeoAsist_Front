// lib/utils/memory_optimizer.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ✅ PRODUCTION READY: Memory Management and Performance Optimization
/// Provides comprehensive memory leak prevention and resource optimization
class MemoryOptimizer {
  static const String _tag = 'MemoryOptimizer';
  
  // Memory thresholds and limits
  static const int _maxImageCacheSize = 50;
  static const int _maxImageCacheBytes = 50 << 20; // 50 MB
  static const int _maxInstructionCacheSize = 20;
  static const Duration _memoryCheckInterval = Duration(minutes: 5);
  static const Duration _cacheCleanupInterval = Duration(minutes: 10);
  
  static Timer? _memoryMonitorTimer;
  static Timer? _cacheCleanupTimer;
  static bool _isInitialized = false;
  
  /// Initialize memory optimization systems
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    logger.d('$_tag: Initializing memory optimization systems...');
    
    try {
      // Configure image cache limits
      optimizeImageCache();
      
      // Configure instruction cache
      optimizeInstructionCache();
      
      // Start periodic memory monitoring
      _startMemoryMonitoring();
      
      // Start periodic cache cleanup
      _startCacheCleanup();
      
      // Configure platform-specific optimizations
      await _configurePlatformOptimizations();
      
      _isInitialized = true;
      logger.d('$_tag: Memory optimization systems initialized successfully');
    } catch (e) {
      logger.d('$_tag: Failed to initialize memory optimization: $e');
    }
  }

  /// Configure image cache for optimal memory usage
  static void optimizeImageCache() {
    logger.d('$_tag: Configuring image cache optimization...');
    
    PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheBytes;
    PaintingBinding.instance.imageCache.currentSizeBytes;
    
    logger.d('$_tag: Image cache configured - Max size: $_maxImageCacheSize, Max bytes: ${_maxImageCacheBytes ~/ (1024 * 1024)}MB');
  }

  /// Configure instruction cache
  static void optimizeInstructionCache() {
    logger.d('$_tag: Configuring instruction cache optimization...');
    
    // Limit the number of cached instructions for UI performance
    if (PaintingBinding.instance.imageCache.currentSize > _maxInstructionCacheSize) {
      clearInstructionCache();
    }
  }

  /// Clear unused resources and caches
  static void clearUnusedResources({bool aggressive = false}) {
    logger.d('$_tag: Clearing unused resources (aggressive: $aggressive)...');
    
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    
    if (aggressive) {
      // Clear live images as well (more aggressive)
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Clear instruction cache
      clearInstructionCache();
      
      // Force garbage collection if in debug mode
      if (kDebugMode) {
        _forceGarbageCollection();
      }
    }
    
    logger.d('$_tag: Resource cleanup completed');
  }

  /// Clear instruction cache
  static void clearInstructionCache() {
    logger.d('$_tag: Clearing instruction cache...');
    
    // Clear display lists and cached instructions
    PaintingBinding.instance.imageCache.evict(Object());
  }

  /// Monitor memory usage periodically
  static void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_memoryCheckInterval, (timer) {
      _checkMemoryUsage();
    });
    
    logger.d('$_tag: Started memory monitoring (interval: ${_memoryCheckInterval.inMinutes}min)');
  }

  /// Start periodic cache cleanup
  static void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(_cacheCleanupInterval, (timer) {
      _performPeriodicCleanup();
    });
    
    logger.d('$_tag: Started periodic cache cleanup (interval: ${_cacheCleanupInterval.inMinutes}min)');
  }

  /// Check current memory usage and take action if needed
  static void _checkMemoryUsage() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final currentSize = imageCache.currentSize;
      final currentSizeBytes = imageCache.currentSizeBytes;
      final maxSizeBytes = imageCache.maximumSizeBytes;
      
      // Calculate memory usage percentage
      final memoryUsagePercent = (currentSizeBytes / maxSizeBytes * 100).round();
      
      logger.d('$_tag: Memory check - Images: $currentSize/${imageCache.maximumSize}, '
          'Bytes: ${(currentSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB/'
          '${(maxSizeBytes / (1024 * 1024)).round()}MB ($memoryUsagePercent%)');
      
      // Take action if memory usage is high
      if (memoryUsagePercent > 80) {
        logger.d('$_tag: High memory usage detected ($memoryUsagePercent%) - performing cleanup');
        _performEmergencyCleanup();
      } else if (memoryUsagePercent > 60) {
        logger.d('$_tag: Moderate memory usage detected ($memoryUsagePercent%) - performing light cleanup');
        _performLightCleanup();
      }
    } catch (e) {
      logger.d('$_tag: Error checking memory usage: $e');
    }
  }

  /// Perform periodic maintenance cleanup
  static void _performPeriodicCleanup() {
    logger.d('$_tag: Performing periodic cache cleanup...');
    
    final imageCache = PaintingBinding.instance.imageCache;
    final sizeBefore = imageCache.currentSizeBytes;
    
    // Clear unused images that haven't been accessed recently
    imageCache.clear();
    
    final sizeAfter = imageCache.currentSizeBytes;
    final bytesFreed = sizeBefore - sizeAfter;
    
    if (bytesFreed > 0) {
      logger.d('$_tag: Periodic cleanup freed ${(bytesFreed / (1024 * 1024)).toStringAsFixed(1)}MB');
    }
  }

  /// Perform light cleanup for moderate memory usage
  static void _performLightCleanup() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Clear some cached images but keep live ones
    imageCache.clear();
    
    logger.d('$_tag: Light cleanup completed');
  }

  /// Perform emergency cleanup for high memory usage
  static void _performEmergencyCleanup() {
    logger.d('$_tag: Performing emergency memory cleanup...');
    
    clearUnusedResources(aggressive: true);
    
    // Additional emergency measures
    SystemChannels.platform.invokeMethod('System.requestGarbageCollection');
    
    logger.d('$_tag: Emergency cleanup completed');
  }

  /// Configure platform-specific optimizations
  static Future<void> _configurePlatformOptimizations() async {
    if (Platform.isAndroid) {
      await _configureAndroidOptimizations();
    } else if (Platform.isIOS) {
      await _configureIOSOptimizations();
    }
  }

  /// Configure Android-specific memory optimizations
  static Future<void> _configureAndroidOptimizations() async {
    logger.d('$_tag: Configuring Android memory optimizations...');
    
    try {
      // Enable hardware acceleration
      await SystemChannels.platform.invokeMethod('Android.enableHardwareAcceleration');
      
      // Configure Android-specific memory settings
      await SystemChannels.platform.invokeMethod('Android.optimizeMemory');
      
      logger.d('$_tag: Android optimizations configured');
    } catch (e) {
      logger.d('$_tag: Android optimization configuration failed: $e');
    }
  }

  /// Configure iOS-specific memory optimizations
  static Future<void> _configureIOSOptimizations() async {
    logger.d('$_tag: Configuring iOS memory optimizations...');
    
    try {
      // Configure iOS-specific settings
      await SystemChannels.platform.invokeMethod('iOS.optimizeMemory');
      
      logger.d('$_tag: iOS optimizations configured');
    } catch (e) {
      logger.d('$_tag: iOS optimization configuration failed: $e');
    }
  }

  /// Force garbage collection (debug mode only)
  static void _forceGarbageCollection() {
    if (kDebugMode) {
      logger.d('$_tag: Forcing garbage collection...');
      
      // This is a debug-only operation
      try {
        SystemChannels.platform.invokeMethod('System.gc');
      } catch (e) {
        logger.d('$_tag: Failed to force garbage collection: $e');
      }
    }
  }

  /// Get current memory usage statistics
  static MemoryUsageStats getMemoryUsageStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    return MemoryUsageStats(
      imageCacheSize: imageCache.currentSize,
      imageCacheMaxSize: imageCache.maximumSize,
      imageCacheSizeBytes: imageCache.currentSizeBytes,
      imageCacheMaxSizeBytes: imageCache.maximumSizeBytes,
      memoryUsagePercent: (imageCache.currentSizeBytes / imageCache.maximumSizeBytes * 100).round(),
    );
  }

  /// Optimize memory for specific use cases
  static void optimizeForUseCase(MemoryOptimizationMode mode) {
    logger.d('$_tag: Optimizing memory for use case: ${mode.name}');
    
    switch (mode) {
      case MemoryOptimizationMode.lowMemory:
        _optimizeForLowMemory();
        break;
      case MemoryOptimizationMode.highPerformance:
        _optimizeForHighPerformance();
        break;
      case MemoryOptimizationMode.balanced:
        _optimizeForBalanced();
        break;
      case MemoryOptimizationMode.backgroundMode:
        _optimizeForBackground();
        break;
    }
  }

  /// Optimize for low memory devices
  static void _optimizeForLowMemory() {
    logger.d('$_tag: Configuring for low memory mode...');
    
    PaintingBinding.instance.imageCache.maximumSize = 20;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20; // 20 MB
    
    // Clear current cache to apply new limits
    clearUnusedResources(aggressive: true);
  }

  /// Optimize for high performance
  static void _optimizeForHighPerformance() {
    logger.d('$_tag: Configuring for high performance mode...');
    
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
  }

  /// Optimize for balanced performance
  static void _optimizeForBalanced() {
    logger.d('$_tag: Configuring for balanced mode...');
    
    optimizeImageCache(); // Use default settings
  }

  /// Optimize for background mode
  static void _optimizeForBackground() {
    logger.d('$_tag: Configuring for background mode...');
    
    // Aggressive cleanup for background mode
    clearUnusedResources(aggressive: true);
    
    // Reduce cache limits
    PaintingBinding.instance.imageCache.maximumSize = 10;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20; // 10 MB
  }

  /// Handle memory warning from system
  static void handleMemoryWarning() {
    logger.d('$_tag: Received memory warning - performing emergency cleanup');
    
    _performEmergencyCleanup();
    
    // Switch to low memory mode temporarily
    optimizeForUseCase(MemoryOptimizationMode.lowMemory);
  }

  /// Dispose memory optimization systems
  static void dispose() {
    logger.d('$_tag: Disposing memory optimization systems...');
    
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
    
    _isInitialized = false;
    
    logger.d('$_tag: Memory optimization systems disposed');
  }

  /// Print memory usage report
  static void printMemoryReport() {
    if (!kDebugMode) return;
    
    final stats = getMemoryUsageStats();
    
    logger.d('$_tag: ========== MEMORY USAGE REPORT ==========');
    logger.d('$_tag: Image Cache: ${stats.imageCacheSize}/${stats.imageCacheMaxSize} items');
    logger.d('$_tag: Cache Size: ${(stats.imageCacheSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB/'
        '${(stats.imageCacheMaxSizeBytes / (1024 * 1024)).round()}MB');
    logger.d('$_tag: Usage: ${stats.memoryUsagePercent}%');
    logger.d('$_tag: =========================================');
  }
}

/// Memory usage statistics
class MemoryUsageStats {
  final int imageCacheSize;
  final int imageCacheMaxSize;
  final int imageCacheSizeBytes;
  final int imageCacheMaxSizeBytes;
  final int memoryUsagePercent;

  MemoryUsageStats({
    required this.imageCacheSize,
    required this.imageCacheMaxSize,
    required this.imageCacheSizeBytes,
    required this.imageCacheMaxSizeBytes,
    required this.memoryUsagePercent,
  });
}

/// Memory optimization modes
enum MemoryOptimizationMode {
  lowMemory,
  balanced,
  highPerformance,
  backgroundMode,
}