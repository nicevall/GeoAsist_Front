// lib/core/bloc/base_state.dart
import 'package:equatable/equatable.dart';

/// Base state class that all BLoC states should extend
/// Provides common state types and Equatable implementation
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Generic initial state
class InitialState extends BaseState {
  const InitialState();

  @override
  String toString() => 'InitialState';
}

/// Generic loading state
class LoadingState extends BaseState {
  final String? message;

  const LoadingState({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'LoadingState(message: $message)';
}

/// Generic loaded state with data
class LoadedState<T> extends BaseState {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'LoadedState(data: $data)';
}

/// Generic error state
class ErrorState extends BaseState {
  final String message;
  final String? code;
  final Object? originalError;

  const ErrorState({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError];

  @override
  String toString() => 'ErrorState(message: $message, code: $code)';
}

/// Empty state for when there's no data
class EmptyState extends BaseState {
  final String? message;

  const EmptyState({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'EmptyState(message: $message)';
}

/// Success state for operations that don't return data
class SuccessState extends BaseState {
  final String? message;

  const SuccessState({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'SuccessState(message: $message)';
}

/// Paginated state for lists with pagination
class PaginatedState<T> extends BaseState {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedState({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
    items,
    currentPage,
    totalPages,
    hasMore,
    isLoadingMore,
  ];

  /// Create a copy with updated values
  PaginatedState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  String toString() => 'PaginatedState(items: ${items.length}, '
      'currentPage: $currentPage, totalPages: $totalPages, hasMore: $hasMore)';
}

/// Mixin for states that can be refreshed
mixin RefreshableState {
  bool get isRefreshing;
}

/// Mixin for states that can show offline status
mixin OfflineState {
  bool get isOffline;
}

/// State wrapper for handling multiple data sources
class MultiDataState<T> extends BaseState {
  final Map<String, T> data;
  final Set<String> loadingKeys;
  final Map<String, String> errors;

  const MultiDataState({
    required this.data,
    this.loadingKeys = const {},
    this.errors = const {},
  });

  /// Check if a specific data key is loading
  bool isLoading(String key) => loadingKeys.contains(key);

  /// Check if a specific data key has an error
  bool hasError(String key) => errors.containsKey(key);

  /// Get error message for a specific key
  String? getError(String key) => errors[key];

  /// Get data for a specific key
  T? getData(String key) => data[key];

  /// Check if all data is loaded
  bool get isAllLoaded => loadingKeys.isEmpty && errors.isEmpty;

  /// Check if any data is loading
  bool get isAnyLoading => loadingKeys.isNotEmpty;

  /// Check if any errors exist
  bool get hasAnyErrors => errors.isNotEmpty;

  @override
  List<Object?> get props => [data, loadingKeys, errors];

  /// Create a copy with updated values
  MultiDataState<T> copyWith({
    Map<String, T>? data,
    Set<String>? loadingKeys,
    Map<String, String>? errors,
  }) {
    return MultiDataState<T>(
      data: data ?? this.data,
      loadingKeys: loadingKeys ?? this.loadingKeys,
      errors: errors ?? this.errors,
    );
  }

  @override
  String toString() => 'MultiDataState(data: ${data.keys}, '
      'loading: $loadingKeys, errors: ${errors.keys})';
}