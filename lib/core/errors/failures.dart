// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

/// Base abstract class for all failures in the application
/// Provides a consistent way to handle different types of errors
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final String? technicalMessage;

  const Failure({
    required this.message,
    this.code,
    this.technicalMessage,
  });

  @override
  List<Object?> get props => [message, code, technicalMessage];

  @override
  String toString() {
    return '$runtimeType(message: $message, code: $code, technicalMessage: $technicalMessage)';
  }
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory NetworkFailure.connectionTimeout() {
    return const NetworkFailure(
      message: 'Connection timeout. Please check your internet connection.',
      code: 'NETWORK_TIMEOUT',
      technicalMessage: 'HTTP request timeout exceeded',
    );
  }

  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      message: 'No internet connection available.',
      code: 'NO_CONNECTION',
      technicalMessage: 'Network not reachable',
    );
  }

  factory NetworkFailure.serverError(int statusCode) {
    return NetworkFailure(
      message: 'Server error occurred. Please try again later.',
      code: 'SERVER_ERROR_$statusCode',
      technicalMessage: 'HTTP $statusCode error',
    );
  }
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure(
      message: 'Invalid email or password.',
      code: 'INVALID_CREDENTIALS',
      technicalMessage: 'Authentication failed with provided credentials',
    );
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Your session has expired. Please login again.',
      code: 'TOKEN_EXPIRED',
      technicalMessage: 'JWT token expired',
    );
  }

  factory AuthFailure.userNotFound() {
    return const AuthFailure(
      message: 'User account not found.',
      code: 'USER_NOT_FOUND',
      technicalMessage: 'User ID not found in database',
    );
  }

  factory AuthFailure.emailNotVerified() {
    return const AuthFailure(
      message: 'Please verify your email address before continuing.',
      code: 'EMAIL_NOT_VERIFIED',
      technicalMessage: 'User email verification pending',
    );
  }
}

/// Validation-related failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    super.technicalMessage,
    this.fieldErrors,
  });

  factory ValidationFailure.requiredField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName is required.',
      code: 'REQUIRED_FIELD',
      technicalMessage: 'Field validation failed: $fieldName is required',
      fieldErrors: {fieldName: '$fieldName is required'},
    );
  }

  factory ValidationFailure.invalidFormat(String fieldName, String format) {
    return ValidationFailure(
      message: 'Please enter a valid $fieldName.',
      code: 'INVALID_FORMAT',
      technicalMessage: 'Field validation failed: $fieldName format invalid',
      fieldErrors: {fieldName: 'Please enter a valid $format'},
    );
  }

  factory ValidationFailure.multipleFields(Map<String, String> errors) {
    return ValidationFailure(
      message: 'Please fix the errors below.',
      code: 'MULTIPLE_VALIDATION_ERRORS',
      technicalMessage: 'Multiple field validation errors',
      fieldErrors: errors,
    );
  }

  @override
  List<Object?> get props => [message, code, technicalMessage, fieldErrors];
}

/// Location/Geofencing-related failures
class LocationFailure extends Failure {
  const LocationFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory LocationFailure.permissionDenied() {
    return const LocationFailure(
      message: 'Location permission is required for attendance tracking.',
      code: 'LOCATION_PERMISSION_DENIED',
      technicalMessage: 'User denied location permission',
    );
  }

  factory LocationFailure.serviceDisabled() {
    return const LocationFailure(
      message: 'Location services are disabled. Please enable them.',
      code: 'LOCATION_SERVICE_DISABLED',
      technicalMessage: 'GPS/Location services not enabled',
    );
  }

  factory LocationFailure.outOfRange() {
    return const LocationFailure(
      message: 'You are outside the event area. Please move closer.',
      code: 'LOCATION_OUT_OF_RANGE',
      technicalMessage: 'User location outside geofence boundary',
    );
  }

  factory LocationFailure.accuracyTooLow() {
    return const LocationFailure(
      message: 'Location accuracy is too low. Please try again.',
      code: 'LOCATION_ACCURACY_LOW',
      technicalMessage: 'GPS accuracy below minimum threshold',
    );
  }
}

/// Firebase/Firestore-related failures
class FirebaseFailure extends Failure {
  const FirebaseFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory FirebaseFailure.permissionDenied() {
    return const FirebaseFailure(
      message: 'You don\'t have permission to perform this action.',
      code: 'FIREBASE_PERMISSION_DENIED',
      technicalMessage: 'Firestore security rules denied operation',
    );
  }

  factory FirebaseFailure.unavailable() {
    return const FirebaseFailure(
      message: 'Service temporarily unavailable. Please try again.',
      code: 'FIREBASE_UNAVAILABLE',
      technicalMessage: 'Firebase service unavailable',
    );
  }

  factory FirebaseFailure.quotaExceeded() {
    return const FirebaseFailure(
      message: 'Service limit exceeded. Please try again later.',
      code: 'FIREBASE_QUOTA_EXCEEDED',
      technicalMessage: 'Firebase quota/rate limit exceeded',
    );
  }
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory CacheFailure.notFound() {
    return const CacheFailure(
      message: 'Data not found in cache.',
      code: 'CACHE_NOT_FOUND',
      technicalMessage: 'Requested data not available in local cache',
    );
  }

  factory CacheFailure.expired() {
    return const CacheFailure(
      message: 'Cached data has expired.',
      code: 'CACHE_EXPIRED',
      technicalMessage: 'Cache TTL exceeded',
    );
  }
}

/// Generic server failure
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory ServerFailure.internalError() {
    return const ServerFailure(
      message: 'An unexpected error occurred. Please try again.',
      code: 'INTERNAL_SERVER_ERROR',
      technicalMessage: 'Server internal error',
    );
  }

  factory ServerFailure.maintenance() {
    return const ServerFailure(
      message: 'Service is under maintenance. Please try again later.',
      code: 'SERVER_MAINTENANCE',
      technicalMessage: 'Server under maintenance',
    );
  }
}

/// Unknown/Unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.technicalMessage,
  });

  factory UnknownFailure.fromException(Object exception) {
    return UnknownFailure(
      message: 'An unexpected error occurred.',
      code: 'UNKNOWN_ERROR',
      technicalMessage: exception.toString(),
    );
  }
}