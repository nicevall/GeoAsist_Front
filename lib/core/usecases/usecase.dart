// lib/core/usecases/usecase.dart
import '../utils/result.dart';
import '../errors/failures.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';

/// Base class for all use cases in the application
/// Use cases represent business logic operations and are the entry point
/// from the presentation layer to the domain layer
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters
  Future<Result<Type>> call(Params params);
}

/// Use case for operations that don't require parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  Future<Result<Type>> call();
}

/// Use case for operations that return streams (real-time data)
abstract class StreamUseCase<Type, Params> {
  /// Execute the use case and return a stream of results
  Stream<Result<Type>> call(Params params);
}

/// Use case for operations that don't require parameters and return streams
abstract class NoParamsStreamUseCase<Type> {
  /// Execute the use case without parameters and return a stream
  Stream<Result<Type>> call();
}

/// Base class for parameters passed to use cases
/// All use case parameters should extend this class
abstract class Params {
  const Params();
}

/// Empty parameters for use cases that don't need parameters
class NoParams extends Params {
  const NoParams();
  
  static const NoParams instance = NoParams();
}

/// Pagination parameters for use cases that support pagination
class PaginationParams extends Params {
  final int page;
  final int limit;
  final String? sortBy;
  final bool ascending;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.ascending = true,
  });

  @override
  String toString() {
    return 'PaginationParams(page: $page, limit: $limit, sortBy: $sortBy, ascending: $ascending)';
  }
}

/// Search parameters for use cases that support search functionality
class SearchParams extends PaginationParams {
  final String query;
  final Map<String, dynamic>? filters;

  const SearchParams({
    required this.query,
    this.filters,
    super.page,
    super.limit,
    super.sortBy,
    super.ascending,
  });

  @override
  String toString() {
    return 'SearchParams(query: $query, filters: $filters, page: $page, limit: $limit)';
  }
}

/// ID-based parameters for use cases that operate on specific entities
class IdParams extends Params {
  final String id;

  const IdParams({required this.id});

  @override
  String toString() => 'IdParams(id: $id)';
}

/// Entity-based parameters for use cases that operate on entities
class EntityParams<T> extends Params {
  final T entity;

  const EntityParams({required this.entity});

  @override
  String toString() => 'EntityParams(entity: $entity)';
}

/// Update parameters combining ID and entity data
class UpdateParams<T> extends Params {
  final String id;
  final T data;

  const UpdateParams({
    required this.id,
    required this.data,
  });

  @override
  String toString() => 'UpdateParams(id: $id, data: $data)';
}

/// Utility class for creating common use case implementations
class UseCaseUtils {
  /// Create a simple use case that wraps a repository method
  static UseCase<T, P> fromRepository<T, P extends Params>(
    Future<Result<T>> Function(P params) repositoryMethod,
  ) {
    return _SimpleUseCase<T, P>(repositoryMethod);
  }

  /// Create a no-params use case that wraps a repository method
  static NoParamsUseCase<T> fromRepositoryNoParams<T>(
    Future<Result<T>> Function() repositoryMethod,
  ) {
    return _SimpleNoParamsUseCase<T>(repositoryMethod);
  }
}

/// Simple implementation of UseCase that wraps a repository method
class _SimpleUseCase<T, P extends Params> extends UseCase<T, P> {
  final Future<Result<T>> Function(P params) _repositoryMethod;

  _SimpleUseCase(this._repositoryMethod);

  @override
  Future<Result<T>> call(P params) {
    return _repositoryMethod(params);
  }
}

/// Simple implementation of NoParamsUseCase that wraps a repository method
class _SimpleNoParamsUseCase<T> extends NoParamsUseCase<T> {
  final Future<Result<T>> Function() _repositoryMethod;

  _SimpleNoParamsUseCase(this._repositoryMethod);

  @override
  Future<Result<T>> call() {
    return _repositoryMethod();
  }
}

/// Mixin for use cases that need validation
mixin ValidationMixin<P extends Params> {
  /// Validate parameters before executing use case
  Result<void> validateParams(P params);

  /// Execute with validation
  Future<Result<T>> executeWithValidation<T>(
    P params,
    Future<Result<T>> Function(P params) operation,
  ) async {
    final validationResult = validateParams(params);
    if (validationResult.isFailure) {
      return FailureResult<T>((validationResult as FailureResult<void>).failure);
    }
    return await operation(params);
  }
}

/// Mixin for use cases that need caching
mixin CacheMixin<T> {
  /// Cache key generator
  String generateCacheKey(dynamic params);

  /// Cache duration
  Duration get cacheDuration => const Duration(minutes: 5);

  /// Check if cached result is still valid
  bool isCacheValid(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) < cacheDuration;
  }
}

/// Mixin for use cases that need logging
mixin LoggingMixin {
  /// Log use case execution start
  void logStart(String useCaseName, dynamic params) {
    logger.i('🚀 Starting $useCaseName with params: $params');
  }

  /// Log use case execution success
  void logSuccess(String useCaseName, dynamic result) {
    logger.i('✅ $useCaseName completed successfully');
  }

  /// Log use case execution failure
  void logFailure(String useCaseName, Failure failure) {
    logger.i('❌ $useCaseName failed: ${failure.message}');
  }
}