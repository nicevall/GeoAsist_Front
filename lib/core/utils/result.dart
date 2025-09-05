// lib/core/utils/result.dart
import '../errors/failures.dart';

/// A generic Result type that encapsulates either a success value or a failure
/// This provides a clean way to handle operations that can fail without throwing exceptions
abstract class Result<T> {
  const Result();

  /// Returns true if this is a Success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure result  
  bool get isFailure => this is FailureResult<T>;

  /// Execute different functions based on the result type
  R fold<R>(R Function(Failure failure) onFailure, R Function(T success) onSuccess);

  /// Transform the success value if this is a Success result
  Result<R> map<R>(R Function(T value) transform) {
    return fold<Result<R>>(
      (failure) => FailureResult<R>(failure),
      (success) => Success<R>(transform(success)),
    );
  }

  /// Chain operations that return Result types
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return fold<Result<R>>(
      (failure) => FailureResult<R>(failure),
      (success) => transform(success),
    );
  }

  /// Get the success value or return a default value
  T getOrElse(T defaultValue) {
    return fold<T>(
      (failure) => defaultValue,
      (success) => success,
    );
  }

  /// Get the success value or throw an exception
  T getOrThrow() {
    return fold<T>(
      (failure) => throw Exception(failure.message),
      (success) => success,
    );
  }
}

/// Represents a successful result containing a value
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T success) onSuccess) {
    return onSuccess(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result containing a failure
class FailureResult<T> extends Result<T> {
  final failure;

  const FailureResult(this.failure);

  @override
  R fold<R>(R Function(failure) onFailure, R Function(T success) onSuccess) {
    return onFailure(failure);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FailureResult<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'FailureResult($failure)';
}

/// Extension methods for easier Result handling
extension ResultExtensions<T> on Result<T> {
  /// Execute a side effect if this is a Success result
  Result<T> onSuccess(void Function(T value) action) {
    if (isSuccess) {
      action((this as Success<T>).value);
    }
    return this;
  }

  /// Execute a side effect if this is a Failure result
  Result<T> onFailure(void Function(failure) action) {
    if (isFailure) {
      action((this as FailureResult<T>).failure);
    }
    return this;
  }

  /// Handle both success and failure cases with side effects
  Result<T> handle({
    void Function(T value)? onSuccess,
    void Function(failure)? onFailure,
  }) {
    return fold<Result<T>>(
      (failure) {
        onFailure?.call(failure);
        return this;
      },
      (success) {
        onSuccess?.call(success);
        return this;
      },
    );
  }
}

/// Convenience methods for creating Result instances
class ResultUtils {
  /// Create a Success result
  static Result<T> success<T>(T value) => Success<T>(value);

  /// Create a Failure result
  static Result<T> failure<T>(failure) => FailureResult<T>(failure);

  /// Wrap a potentially throwing operation in a Result
  static Result<T> tryCall<T>(T Function() operation) {
    try {
      return Success<T>(operation());
    } catch (e) {
      return FailureResult<T>(UnknownFailure.fromException(e));
    }
  }

  /// Wrap an async operation in a Result
  static Future<Result<T>> tryCallAsync<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Success<T>(result);
    } catch (e) {
      return FailureResult<T>(UnknownFailure.fromException(e));
    }
  }

  /// Combine multiple Results into a single Result containing a list
  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final List<T> values = [];
    for (final result in results) {
      if (result.isFailure) {
        return FailureResult<List<T>>((result as FailureResult<T>).failure);
      }
      values.add((result as Success<T>).value);
    }
    return Success<List<T>>(values);
  }
}