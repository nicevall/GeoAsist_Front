// lib/core/utils/app_logger.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging configuration for the GeoAsist application
/// Provides different log levels and formatted output based on build mode
class AppLogger {
  static Logger? _instance;
  
  /// Get the singleton logger instance
  static Logger get instance {
    _instance ??= _createLogger();
    return _instance!;
  }
  
  /// Create logger with appropriate configuration
  static Logger _createLogger() {
    return Logger(
      filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
      printer: kDebugMode ? PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ) : SimplePrinter(),
      output: kDebugMode ? ConsoleOutput() : null,
    );
  }
}

/// Global logger instance for easy access throughout the app
final logger = AppLogger.instance;

/// Extension methods for common logging patterns
extension LoggerExtensions on Logger {
  /// Log API request
  void apiRequest(String method, String url, [Map<String, dynamic>? data]) {
    d('🌐 API $method $url${data != null ? ' with data: $data' : ''}');
  }
  
  /// Log API response
  void apiResponse(String method, String url, int statusCode, [dynamic data]) {
    if (statusCode >= 200 && statusCode < 300) {
      i('✅ API $method $url -> $statusCode${data != null ? ' data: $data' : ''}');
    } else {
      e('❌ API $method $url -> $statusCode${data != null ? ' data: $data' : ''}');
    }
  }
  
  /// Log navigation event
  void navigation(String from, String to) {
    i('📱 Navigation: $from -> $to');
  }
  
  /// Log performance metric
  void performance(String operation, Duration duration) {
    if (duration.inMilliseconds > 100) {
      w('⚠️ Performance: $operation took ${duration.inMilliseconds}ms');
    } else {
      d('⚡ Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }
}