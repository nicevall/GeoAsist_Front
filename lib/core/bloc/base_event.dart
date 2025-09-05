// lib/core/bloc/base_event.dart
import 'package:equatable/equatable.dart';

/// Base event class that all BLoC events should extend
/// Provides Equatable implementation for event comparison
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];
}

/// Generic load event
class LoadEvent extends BaseEvent {
  final Map<String, dynamic>? filters;
  final bool forceRefresh;

  const LoadEvent({
    this.filters,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [filters, forceRefresh];

  @override
  String toString() => 'LoadEvent(filters: $filters, forceRefresh: $forceRefresh)';
}

/// Generic refresh event
class RefreshEvent extends BaseEvent {
  const RefreshEvent();

  @override
  String toString() => 'RefreshEvent';
}

/// Generic reset event
class ResetEvent extends BaseEvent {
  const ResetEvent();

  @override
  String toString() => 'ResetEvent';
}

/// Generic search event
class SearchEvent extends BaseEvent {
  final String query;
  final Map<String, dynamic>? filters;

  const SearchEvent({
    required this.query,
    this.filters,
  });

  @override
  List<Object?> get props => [query, filters];

  @override
  String toString() => 'SearchEvent(query: $query, filters: $filters)';
}

/// Generic create event
class CreateEvent<T> extends BaseEvent {
  final T data;

  const CreateEvent(this.data);

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'CreateEvent(data: $data)';
}

/// Generic update event
class UpdateEvent<T> extends BaseEvent {
  final String id;
  final T data;

  const UpdateEvent({
    required this.id,
    required this.data,
  });

  @override
  List<Object?> get props => [id, data];

  @override
  String toString() => 'UpdateEvent(id: $id, data: $data)';
}

/// Generic delete event
class DeleteEvent extends BaseEvent {
  final String id;

  const DeleteEvent(this.id);

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'DeleteEvent(id: $id)';
}

/// Generic load by ID event
class LoadByIdEvent extends BaseEvent {
  final String id;

  const LoadByIdEvent(this.id);

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'LoadByIdEvent(id: $id)';
}

/// Pagination events
class LoadMoreEvent extends BaseEvent {
  const LoadMoreEvent();

  @override
  String toString() => 'LoadMoreEvent';
}

class LoadPageEvent extends BaseEvent {
  final int page;

  const LoadPageEvent(this.page);

  @override
  List<Object?> get props => [page];

  @override
  String toString() => 'LoadPageEvent(page: $page)';
}

/// Filter events
class ApplyFilterEvent extends BaseEvent {
  final Map<String, dynamic> filters;

  const ApplyFilterEvent(this.filters);

  @override
  List<Object?> get props => [filters];

  @override
  String toString() => 'ApplyFilterEvent(filters: $filters)';
}

class ClearFiltersEvent extends BaseEvent {
  const ClearFiltersEvent();

  @override
  String toString() => 'ClearFiltersEvent';
}

/// Sort events
class SortEvent extends BaseEvent {
  final String field;
  final bool ascending;

  const SortEvent({
    required this.field,
    this.ascending = true,
  });

  @override
  List<Object?> get props => [field, ascending];

  @override
  String toString() => 'SortEvent(field: $field, ascending: $ascending)';
}

/// Batch operations
class BatchCreateEvent<T> extends BaseEvent {
  final List<T> items;

  const BatchCreateEvent(this.items);

  @override
  List<Object?> get props => [items];

  @override
  String toString() => 'BatchCreateEvent(items: ${items.length})';
}

class BatchUpdateEvent<T> extends BaseEvent {
  final Map<String, T> updates;

  const BatchUpdateEvent(this.updates);

  @override
  List<Object?> get props => [updates];

  @override
  String toString() => 'BatchUpdateEvent(updates: ${updates.length})';
}

class BatchDeleteEvent extends BaseEvent {
  final List<String> ids;

  const BatchDeleteEvent(this.ids);

  @override
  List<Object?> get props => [ids];

  @override
  String toString() => 'BatchDeleteEvent(ids: ${ids.length})';
}