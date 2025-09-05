// lib/core/repositories/base_repository.dart
import '../utils/result.dart';

/// Base repository interface that provides common CRUD operations
/// All domain repositories should extend this interface
abstract class BaseRepository<T, ID> {
  /// Get all entities
  Future<Result<List<T>>> getAll();

  /// Get entity by ID
  Future<Result<T>> getById(ID id);

  /// Create a new entity
  Future<Result<T>> create(T entity);

  /// Update an existing entity
  Future<Result<T>> update(ID id, T entity);

  /// Delete entity by ID
  Future<Result<bool>> delete(ID id);

  /// Check if entity exists by ID
  Future<Result<bool>> exists(ID id);
}

/// Repository interface for entities that support pagination
abstract class PaginatedRepository<T, ID> extends BaseRepository<T, ID> {
  /// Get paginated results
  Future<Result<PaginatedResult<T>>> getPaginated({
    int page = 1,
    int limit = 20,
    String? sortBy,
    SortOrder sortOrder = SortOrder.asc,
    Map<String, dynamic>? filters,
  });

  /// Search entities with pagination
  Future<Result<PaginatedResult<T>>> search({
    required String query,
    int page = 1,
    int limit = 20,
    String? sortBy,
    SortOrder sortOrder = SortOrder.asc,
  });
}

/// Repository interface for entities that support real-time updates
abstract class StreamRepository<T, ID> extends BaseRepository<T, ID> {
  /// Get real-time stream of all entities
  Stream<Result<List<T>>> getAllStream();

  /// Get real-time stream of entity by ID
  Stream<Result<T>> getByIdStream(ID id);

  /// Get real-time stream with filters
  Stream<Result<List<T>>> getFilteredStream(Map<String, dynamic> filters);
}

/// Repository interface for entities with soft delete support
abstract class SoftDeleteRepository<T, ID> extends BaseRepository<T, ID> {
  /// Get all entities including deleted ones
  Future<Result<List<T>>> getAllWithDeleted();

  /// Soft delete entity (mark as deleted)
  Future<Result<bool>> softDelete(ID id);

  /// Restore soft-deleted entity
  Future<Result<bool>> restore(ID id);

  /// Permanently delete entity
  Future<Result<bool>> hardDelete(ID id);
}

/// Result class for paginated data
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// Create PaginatedResult from raw data
  factory PaginatedResult.fromData({
    required List<T> items,
    required int totalCount,
    required int page,
    required int limit,
  }) {
    final totalPages = (totalCount / limit).ceil();
    return PaginatedResult<T>(
      items: items,
      totalCount: totalCount,
      currentPage: page,
      totalPages: totalPages,
      itemsPerPage: limit,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, totalCount: $totalCount, '
           'currentPage: $currentPage, totalPages: $totalPages)';
  }
}

/// Sort order enumeration
enum SortOrder {
  asc,
  desc,
}

/// Base cache-aware repository that can work offline
abstract class CacheAwareRepository<T, ID> extends BaseRepository<T, ID> {
  /// Get entity from cache first, then from network if not found
  Future<Result<T>> getByIdCacheFirst(ID id);

  /// Get all entities from cache first, then from network if not found
  Future<Result<List<T>>> getAllCacheFirst();

  /// Force refresh from network and update cache
  Future<Result<List<T>>> refreshFromNetwork();

  /// Get cache status for entity
  Future<CacheStatus> getCacheStatus(ID id);

  /// Clear cache for specific entity
  Future<void> clearCache(ID id);

  /// Clear all cache
  Future<void> clearAllCache();
}

/// Cache status enumeration
enum CacheStatus {
  cached,
  expired,
  notCached,
}

/// Repository exception for consistent error handling
class RepositoryException implements Exception {
  final String message;
  final String? code;
  final Object? originalException;

  const RepositoryException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'RepositoryException(message: $message, code: $code)';
  }
}