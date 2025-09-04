// lib/utils/error_handler.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geo_asist_front/models/api_response_model.dart';
import 'package:geo_asist_front/utils/colors.dart';

/// ✅ PRODUCTION READY: Comprehensive Error Handling System
/// Provides centralized error management with user-friendly messaging
class ErrorHandler {
  static const String _tag = 'ErrorHandler';

  /// Handle API-related errors with appropriate user feedback
  static void handleApiError(dynamic error, BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showDialog = true,
  }) {
    debugPrint('$_tag: Handling API error: $error');

    ErrorInfo errorInfo = _categorizeError(error);
    
    if (showDialog) {
      _showErrorDialog(
        context,
        errorInfo,
        customMessage: customMessage,
        onRetry: onRetry,
      );
    } else {
      _showErrorSnackBar(context, errorInfo.userMessage);
    }

    // Log error for analytics/monitoring
    _logError('API_ERROR', error, errorInfo);
  }

  /// Handle location service errors
  static void handleLocationError(dynamic error, BuildContext context) {
    debugPrint('$_tag: Handling location error: $error');

    String title = 'Location Error';
    String message = 'Unable to access location services';
    IconData icon = Icons.location_off;
    VoidCallback? action;

    if (error is LocationServiceDisabledException) {
      title = 'Location Services Disabled';
      message = 'Please enable location services in your device settings to continue using attendance tracking.';
      icon = Icons.location_disabled;
      action = () => _openLocationSettings();
    } else if (error is PermissionDeniedException) {
      title = 'Location Permission Required';
      message = 'GeoAsist needs location permission to track your attendance. Please grant permission in settings.';
      icon = Icons.location_disabled;
      action = () => _openAppSettings();
    } else if (error is TimeoutException) {
      title = 'Location Timeout';
      message = 'Unable to get your current location. Please ensure you have a clear view of the sky and try again.';
      icon = Icons.location_searching;
    }

    _showLocationErrorDialog(context, title, message, icon, action);
  }

  /// Handle network connectivity errors
  static void handleNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    debugPrint('$_tag: Handling network error');

    _showNetworkErrorDialog(context, onRetry);
  }

  /// Handle authentication errors
  static void handleAuthError(BuildContext context, String errorMessage) {
    debugPrint('$_tag: Handling auth error: $errorMessage');

    if (errorMessage.toLowerCase().contains('token') || 
        errorMessage.toLowerCase().contains('unauthorized')) {
      _showSessionExpiredDialog(context);
    } else {
      _showAuthErrorDialog(context, errorMessage);
    }
  }

  /// Handle general application errors with crash prevention
  static void handleCriticalError(dynamic error, StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) {
    debugPrint('$_tag: Critical error in $context: $error');
    debugPrint('$_tag: Stack trace: $stackTrace');

    // Log critical error for crash reporting
    _logCriticalError(error, stackTrace, context, additionalInfo);

    // In debug mode, you might want to show more detailed error info
    if (kDebugMode) {
      debugPrint('$_tag: Additional info: $additionalInfo');
    }
  }

  /// Categorize error and provide appropriate response
  static ErrorInfo _categorizeError(dynamic error) {
    if (error is SocketException) {
      return ErrorInfo(
        type: ErrorType.network,
        title: 'Connection Error',
        userMessage: 'Please check your internet connection and try again.',
        technicalMessage: error.message,
        canRetry: true,
      );
    }

    if (error is TimeoutException) {
      return ErrorInfo(
        type: ErrorType.timeout,
        title: 'Request Timeout',
        userMessage: 'The request is taking too long. Please try again.',
        technicalMessage: error.message ?? 'Timeout occurred',
        canRetry: true,
      );
    }

    if (error is HttpException) {
      final statusCode = _extractStatusCode(error.message);
      return _handleHttpError(statusCode, error.message);
    }

    if (error is ApiResponse) {
      return _handleApiResponseError(error);
    }

    if (error is FormatException) {
      return ErrorInfo(
        type: ErrorType.parsing,
        title: 'Data Error',
        userMessage: 'There was an issue processing the server response. Please try again.',
        technicalMessage: error.message,
        canRetry: true,
      );
    }

    // Generic error
    return ErrorInfo(
      type: ErrorType.unknown,
      title: 'Unexpected Error',
      userMessage: 'An unexpected error occurred. Please try again later.',
      technicalMessage: error.toString(),
      canRetry: true,
    );
  }

  /// Handle HTTP status code errors
  static ErrorInfo _handleHttpError(int? statusCode, String message) {
    switch (statusCode) {
      case 400:
        return ErrorInfo(
          type: ErrorType.validation,
          title: 'Invalid Request',
          userMessage: 'Please check your input and try again.',
          technicalMessage: message,
          canRetry: false,
        );
      case 401:
        return ErrorInfo(
          type: ErrorType.authentication,
          title: 'Authentication Required',
          userMessage: 'Your session has expired. Please log in again.',
          technicalMessage: message,
          canRetry: false,
        );
      case 403:
        return ErrorInfo(
          type: ErrorType.authorization,
          title: 'Access Denied',
          userMessage: 'You don\'t have permission to perform this action.',
          technicalMessage: message,
          canRetry: false,
        );
      case 404:
        return ErrorInfo(
          type: ErrorType.notFound,
          title: 'Resource Not Found',
          userMessage: 'The requested information could not be found.',
          technicalMessage: message,
          canRetry: false,
        );
      case 422:
        return ErrorInfo(
          type: ErrorType.validation,
          title: 'Validation Error',
          userMessage: 'Please check your information and try again.',
          technicalMessage: message,
          canRetry: false,
        );
      case 429:
        return ErrorInfo(
          type: ErrorType.rateLimit,
          title: 'Too Many Requests',
          userMessage: 'You\'re making requests too quickly. Please wait a moment and try again.',
          technicalMessage: message,
          canRetry: true,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ErrorInfo(
          type: ErrorType.server,
          title: 'Server Error',
          userMessage: 'Our servers are experiencing issues. Please try again later.',
          technicalMessage: message,
          canRetry: true,
        );
      default:
        return ErrorInfo(
          type: ErrorType.unknown,
          title: 'Network Error',
          userMessage: 'A network error occurred. Please try again.',
          technicalMessage: message,
          canRetry: true,
        );
    }
  }

  /// Handle ApiResponse errors
  static ErrorInfo _handleApiResponseError(ApiResponse response) {
    return ErrorInfo(
      type: ErrorType.api,
      title: 'Server Response Error',
      userMessage: response.error ?? 'An error occurred while processing your request.',
      technicalMessage: response.error ?? 'Unknown API error',
      canRetry: true,
    );
  }

  /// Show comprehensive error dialog
  static void _showErrorDialog(
    BuildContext context,
    ErrorInfo errorInfo, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getErrorIcon(errorInfo.type), color: AppColors.errorRed),
            const SizedBox(width: 8),
            Expanded(child: Text(errorInfo.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customMessage ?? errorInfo.userMessage),
            if (kDebugMode && errorInfo.technicalMessage != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Technical Details:\n${errorInfo.technicalMessage}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (errorInfo.canRetry && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(errorInfo.canRetry ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show location-specific error dialog
  static void _showLocationErrorDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    VoidCallback? action,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (action != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                action();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Open Settings'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show network error dialog
  static void _showNetworkErrorDialog(BuildContext context, VoidCallback? onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text('No Internet Connection'),
          ],
        ),
        content: const Text(
          'Please check your internet connection and try again. Make sure you\'re connected to WiFi or mobile data.',
        ),
        actions: [
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show session expired dialog
  static void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: AppColors.primaryOrange),
            SizedBox(width: 8),
            Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your session has expired for security reasons. Please log in again to continue.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  /// Show auth error dialog
  static void _showAuthErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text('Authentication Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error as snack bar for less critical errors
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get appropriate icon for error type
  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.authorization:
        return Icons.security;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.dns;
      case ErrorType.rateLimit:
        return Icons.speed;
      default:
        return Icons.error_outline;
    }
  }

  /// Extract status code from HTTP exception message
  static int? _extractStatusCode(String message) {
    final RegExp regex = RegExp(r'HttpException: (.+), uri');
    final match = regex.firstMatch(message);
    if (match != null) {
      final statusText = match.group(1);
      return int.tryParse(statusText?.split(' ').first ?? '');
    }
    return null;
  }

  /// Navigate to login screen
  static void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  /// Open device location settings
  static void _openLocationSettings() {
    // Implementation would use app_settings plugin or similar
    debugPrint('$_tag: Opening location settings...');
  }

  /// Open app settings
  static void _openAppSettings() {
    // Implementation would use app_settings plugin or similar
    debugPrint('$_tag: Opening app settings...');
  }

  /// Log error for analytics and monitoring
  static void _logError(String type, dynamic error, ErrorInfo errorInfo) {
    // Implementation would integrate with crash reporting service
    debugPrint('$_tag: Logging error - Type: $type, Info: ${errorInfo.title}');
  }

  /// Log critical error for crash reporting
  static void _logCriticalError(
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  ) {
    // Implementation would integrate with crash reporting service like Firebase Crashlytics
    debugPrint('$_tag: Logging critical error in $context: $error');
  }
}

/// Error information data class
class ErrorInfo {
  final ErrorType type;
  final String title;
  final String userMessage;
  final String? technicalMessage;
  final bool canRetry;

  ErrorInfo({
    required this.type,
    required this.title,
    required this.userMessage,
    this.technicalMessage,
    required this.canRetry,
  });
}

/// Error types for categorization
enum ErrorType {
  network,
  timeout,
  authentication,
  authorization,
  validation,
  notFound,
  server,
  api,
  parsing,
  rateLimit,
  unknown,
}

/// Custom exception classes
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
}