// lib/models/api_response_model.dart
// ✅ ENHANCED: Robust API response handling for backend compatibility

/// HTTP status code ranges for response categorization
enum ApiResponseStatus {
  success,     // 2xx
  clientError, // 4xx
  serverError, // 5xx
  networkError, // Network/connectivity issues
  unknown      // Unexpected responses
}

/// Enhanced API response model with comprehensive backend compatibility
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  
  // ✅ ENHANCED: Additional metadata for better error handling
  final int? statusCode;
  final ApiResponseStatus status;
  final Map<String, dynamic>? headers;
  final DateTime timestamp;
  final String? requestId;
  final Map<String, dynamic>? metadata;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
    this.status = ApiResponseStatus.unknown,
    this.headers,
    DateTime? timestamp,
    this.requestId,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create successful response
  factory ApiResponse.success(
    T data, {
    String message = 'Success',
    int? statusCode = 200,
    Map<String, dynamic>? headers,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
      status: ApiResponseStatus.success,
      headers: headers,
      requestId: requestId,
      metadata: metadata,
    );
  }

  /// Create error response
  factory ApiResponse.error(
    String error, {
    String? message,
    int? statusCode,
    Map<String, dynamic>? headers,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) {
    final status = _determineStatusFromCode(statusCode);
    return ApiResponse(
      success: false,
      message: message ?? 'Error',
      error: error,
      statusCode: statusCode,
      status: status,
      headers: headers,
      requestId: requestId,
      metadata: metadata,
    );
  }

  /// Create response from raw HTTP response
  factory ApiResponse.fromHttpResponse(
    dynamic responseBody,
    int statusCode, {
    Map<String, String>? headers,
    String? requestId,
  }) {
    try {
      final isSuccess = statusCode >= 200 && statusCode < 300;
      final status = _determineStatusFromCode(statusCode);
      
      // Handle different response body structures
      final parsedData = _parseResponseBody<T>(responseBody, isSuccess);
      
      return ApiResponse(
        success: isSuccess,
        message: parsedData['message'] ?? (isSuccess ? 'Success' : 'Error'),
        data: parsedData['data'],
        error: parsedData['error'],
        statusCode: statusCode,
        status: status,
        headers: headers?.cast<String, dynamic>(),
        requestId: requestId,
        metadata: parsedData['metadata'],
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        statusCode: statusCode,
        headers: headers?.cast<String, dynamic>(),
        requestId: requestId,
      );
    }
  }

  /// Create network error response
  factory ApiResponse.networkError(String error, {String? requestId}) {
    return ApiResponse(
      success: false,
      message: 'Network Error',
      error: error,
      status: ApiResponseStatus.networkError,
      requestId: requestId,
    );
  }

  /// Determine status from HTTP status code
  static ApiResponseStatus _determineStatusFromCode(int? statusCode) {
    if (statusCode == null) return ApiResponseStatus.unknown;
    
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponseStatus.success;
    } else if (statusCode >= 400 && statusCode < 500) {
      return ApiResponseStatus.clientError;
    } else if (statusCode >= 500) {
      return ApiResponseStatus.serverError;
    } else {
      return ApiResponseStatus.unknown;
    }
  }

  /// Parse response body handling various backend structures
  static Map<String, dynamic> _parseResponseBody<T>(dynamic body, bool isSuccess) {
    if (body == null) {
      return {
        'data': null,
        'message': isSuccess ? 'Success' : 'No response data',
        'error': isSuccess ? null : 'Empty response',
      };
    }

    // Handle different response structures from backend
    if (body is Map<String, dynamic>) {
      final Map<String, dynamic> result = {};
      
      // Extract data - check various possible field names
      if (body.containsKey('data')) {
        result['data'] = body['data'] as T?;
      } else if (body.containsKey('result')) {
        result['data'] = body['result'] as T?;
      } else if (body.containsKey('payload')) {
        result['data'] = body['payload'] as T?;
      } else if (isSuccess) {
        // If no explicit data field, use the whole body as data for success
        result['data'] = body as T?;
      }
      
      // Extract message
      result['message'] = body['message'] ?? 
                         body['msg'] ?? 
                         body['description'] ?? 
                         (isSuccess ? 'Success' : 'Error');
      
      // Extract error
      result['error'] = body['error'] ?? 
                       body['errorMessage'] ?? 
                       body['err'] ??
                       (isSuccess ? null : result['message']);
      
      // Extract metadata
      final metadata = <String, dynamic>{};
      for (final entry in body.entries) {
        if (!['data', 'result', 'payload', 'message', 'msg', 'error', 'errorMessage'].contains(entry.key)) {
          metadata[entry.key] = entry.value;
        }
      }
      if (metadata.isNotEmpty) {
        result['metadata'] = metadata;
      }
      
      return result;
    } else {
      // Handle primitive responses
      return {
        'data': isSuccess ? body as T? : null,
        'message': isSuccess ? 'Success' : 'Error',
        'error': isSuccess ? null : body.toString(),
      };
    }
  }

  /// Check if response indicates a retryable error
  bool get isRetryable {
    switch (status) {
      case ApiResponseStatus.serverError:
      case ApiResponseStatus.networkError:
        return true;
      case ApiResponseStatus.clientError:
        return statusCode == 429; // Rate limiting
      case ApiResponseStatus.success:
      case ApiResponseStatus.unknown:
        return false;
    }
  }

  /// Check if error is due to authentication
  bool get isAuthError {
    return statusCode == 401 || 
           statusCode == 403 ||
           (error != null && (
             error!.toLowerCase().contains('unauthorized') ||
             error!.toLowerCase().contains('forbidden') ||
             error!.toLowerCase().contains('token')
           ));
  }

  /// Check if error is validation-related
  bool get isValidationError {
    return statusCode == 400 ||
           statusCode == 422 ||
           (error != null && (
             error!.toLowerCase().contains('validation') ||
             error!.toLowerCase().contains('invalid') ||
             error!.toLowerCase().contains('bad request')
           ));
  }

  /// Get user-friendly error message
  String get userFriendlyError {
    if (error == null) return 'Unknown error occurred';
    
    switch (status) {
      case ApiResponseStatus.networkError:
        return 'Network connection error. Please check your internet connection.';
      case ApiResponseStatus.serverError:
        return 'Server error. Please try again later.';
      case ApiResponseStatus.clientError:
        if (isAuthError) {
          return 'Authentication required. Please log in again.';
        } else if (isValidationError) {
          return error!; // Show validation errors directly
        } else {
          return 'Request error. Please check your input.';
        }
      default:
        return error!;
    }
  }

  /// Convert to JSON for debugging/logging
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
      'statusCode': statusCode,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'requestId': requestId,
      'headers': headers,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, status: ${status.name}, '
           'statusCode: $statusCode, message: $message, error: $error)';
  }
}
