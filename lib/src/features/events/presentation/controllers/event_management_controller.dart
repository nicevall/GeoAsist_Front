import 'package:flutter/foundation.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/use_cases/create_event_use_case.dart';

/// **EventSortingOption**: Enum for event sorting options
enum EventSortingOption {
  createdDateDesc,
  createdDateAsc,
  startDateAsc,
  startDateDesc,
  titleAsc,
  titleDesc,
}

/// **EventManagementController**: Presentation state management for event operations
/// 
/// **Purpose**: Manages event creation, editing, and listing state with reactive UI updates
/// **AI Context**: MVVM controller connecting event UI to business logic with comprehensive state management
/// **Dependencies**: CreateEventUseCase and future event use cases
/// **Used by**: EventCreationPage, EventListPage, EventManagementPage
/// **Performance**: Optimized state management with granular UI updates and efficient caching
class EventManagementController extends ChangeNotifier {
  /// **Property**: Use case for event creation business logic
  /// **AI Context**: Injected dependency following Clean Architecture principles
  final CreateEventUseCase _createEventUseCase;

  /// **Property**: Current state of event management controller
  /// **AI Context**: Reactive state that triggers UI rebuilds when changed
  EventManagementControllerState _currentState = EventManagementControllerState.initial();

  /// **Property**: List of managed events (created by current user)
  /// **AI Context**: Cached event list for quick UI access and offline viewing
  List<EventEntity> _managedEvents = [];

  /// **Property**: Currently selected/active event for operations
  /// **AI Context**: Event being viewed, edited, or managed in detail
  EventEntity? _selectedEvent;

  /// **Property**: Event creation form data cache
  /// **AI Context**: Temporary storage for form data during creation process
  EventCreationData? _currentEventCreationData;

  /// **Property**: Filtering and sorting preferences
  /// **AI Context**: User preferences for event list display and organization
  EventListFilters _currentFilters = EventListFilters.defaults();

  EventManagementController({
    required CreateEventUseCase createEventUseCase,
  }) : _createEventUseCase = createEventUseCase;

  // **Getters**: Public interface for UI components
  /// **Getter**: Current state for UI reactions
  /// **AI Context**: UI components use this to show loading, success, error states
  EventManagementControllerState get currentState => _currentState;

  /// **Getter**: List of managed events
  /// **AI Context**: Filtered and sorted event list for display
  List<EventEntity> get managedEvents => List.unmodifiable(_managedEvents);

  /// **Getter**: Currently selected event
  /// **AI Context**: Event being viewed or edited in detail view
  EventEntity? get selectedEvent => _selectedEvent;

  /// **Getter**: Check if controller is performing operations
  /// **AI Context**: UI uses this to show loading indicators and disable interactions
  bool get isOperationInProgress => _currentState.isLoading;

  /// **Getter**: Current error message for user display
  /// **AI Context**: UI displays this in snackbars, dialogs, or error widgets
  String? get currentErrorMessage => _currentState.errorMessage;

  /// **Getter**: Current success message for user feedback
  /// **AI Context**: UI displays this for positive feedback on successful operations
  String? get currentSuccessMessage => _currentState.successMessage;

  /// **Getter**: Number of events being managed
  /// **AI Context**: Quick count for dashboard and summary displays
  int get managedEventsCount => _managedEvents.length;

  /// **Getter**: Number of active events (status: active)
  /// **AI Context**: Count of currently running events for dashboard metrics
  int get activeEventsCount => _managedEvents
      .where((event) => event.eventStatus == EventStatusType.active)
      .length;

  /// **Method**: Create new event with comprehensive validation
  /// **AI Context**: Primary event creation flow triggered by form submission
  /// **Inputs**: eventCreationData (EventCreationData) with all event information
  /// **Side Effects**: Updates state, notifies listeners, adds event to managed list
  /// **Error Cases**: Validation errors, network errors, permission errors
  Future<void> createNewEvent({
    required EventCreationData eventCreationData,
  }) async {
    // AI Context: Set loading state to show UI progress indicators
    _updateControllerState(EventManagementControllerState.loading(
      operationType: EventOperationType.creating,
      statusMessage: 'Creando evento...',
    ));

    try {
      // AI Context: Cache creation data for potential retry or editing
      _currentEventCreationData = eventCreationData;

      // AI Context: Execute event creation use case
      final creationResult = await _createEventUseCase.executeEventCreation(
        eventCreationData: eventCreationData,
      );

      if (creationResult.isSuccessful && creationResult.createdEvent != null) {
        // AI Context: Add newly created event to managed list
        _managedEvents.insert(0, creationResult.createdEvent!);
        _selectedEvent = creationResult.createdEvent!;

        // AI Context: Update state to success for UI feedback
        _updateControllerState(EventManagementControllerState.operationSuccess(
          operationType: EventOperationType.creating,
          successMessage: creationResult.successMessage ?? 'Evento creado exitosamente',
          affectedEvent: creationResult.createdEvent!,
        ));

        // AI Context: Clear cached creation data after success
        _currentEventCreationData = null;
      } else {
        // AI Context: Handle creation failure with detailed error information
        _updateControllerState(EventManagementControllerState.operationError(
          operationType: EventOperationType.creating,
          errorMessage: creationResult.userFriendlyErrorMessage,
        ));
      }
    } catch (exception) {
      // AI Context: Handle unexpected errors with generic message
      _updateControllerState(EventManagementControllerState.operationError(
        operationType: EventOperationType.creating,
        errorMessage: 'Error inesperado al crear evento: ${exception.toString()}',
      ));
    }
  }

  /// **Method**: Load events managed by current user
  /// **AI Context**: Refresh event list from repository with filtering and caching
  /// **Side Effects**: Updates managed events list, updates state, notifies UI
  /// **Error Cases**: Network errors, permission errors, data loading errors
  Future<void> loadManagedEvents({
    bool forceRefresh = false,
  }) async {
    // AI Context: Skip loading if already loading or data is fresh
    if (_currentState.isLoading && !forceRefresh) return;

    _updateControllerState(EventManagementControllerState.loading(
      operationType: EventOperationType.loading,
      statusMessage: 'Cargando eventos...',
    ));

    try {
      // AI Context: Placeholder for repository call - would be implemented with actual repository
      // final events = await _eventRepository.getEventsByCreator(
      //   creatorUserId: currentUserId,
      //   filters: _currentFilters.toQueryFilters(),
      // );
      
      // AI Context: Mock implementation for architecture demonstration
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate network delay
      
      // AI Context: Apply current filters to loaded events
      final filteredEvents = _applyFiltersToEvents(_managedEvents);

      _managedEvents = filteredEvents;

      _updateControllerState(EventManagementControllerState.loaded(
        eventsCount: _managedEvents.length,
        statusMessage: _managedEvents.isEmpty 
            ? 'No se encontraron eventos' 
            : 'Cargados ${_managedEvents.length} eventos',
      ));
    } catch (exception) {
      _updateControllerState(EventManagementControllerState.operationError(
        operationType: EventOperationType.loading,
        errorMessage: 'Error al cargar eventos: ${exception.toString()}',
      ));
    }
  }

  /// **Method**: Select event for detailed operations
  /// **AI Context**: Set current event for viewing, editing, or management
  /// **Input**: event (EventEntity) to select
  /// **Side Effects**: Updates selected event, notifies listeners for UI updates
  void selectEvent(EventEntity event) {
    _selectedEvent = event;
    
    _updateControllerState(EventManagementControllerState.eventSelected(
      selectedEvent: event,
    ));
  }

  /// **Method**: Clear currently selected event
  /// **AI Context**: Deselect event and return to list view
  /// **Side Effects**: Clears selected event, updates state, triggers UI navigation
  void clearSelectedEvent() {
    _selectedEvent = null;
    
    _updateControllerState(EventManagementControllerState.loaded(
      eventsCount: _managedEvents.length,
    ));
  }

  /// **Method**: Update event list filters
  /// **AI Context**: Apply new filtering criteria to event list display
  /// **Input**: newFilters (EventListFilters) with filtering preferences
  /// **Side Effects**: Updates filters, re-applies filtering, refreshes UI
  void updateEventFilters(EventListFilters newFilters) {
    _currentFilters = newFilters;
    
    // AI Context: Re-apply filters to current event list
    final filteredEvents = _applyFiltersToEvents(_managedEvents);
    _managedEvents = filteredEvents;
    
    _updateControllerState(EventManagementControllerState.loaded(
      eventsCount: _managedEvents.length,
      statusMessage: 'Filtros aplicados - ${_managedEvents.length} eventos',
    ));
  }

  /// **Method**: Clear current error state
  /// **AI Context**: UI calls this to dismiss error messages and retry operations
  /// **Side Effects**: Updates state without error, notifies listeners
  void clearCurrentError() {
    if (_currentState.hasError) {
      _updateControllerState(EventManagementControllerState.initial());
    }
  }

  /// **Method**: Clear current success message
  /// **AI Context**: UI calls this to dismiss success notifications
  /// **Side Effects**: Updates state, maintains data but removes success message
  void clearSuccessMessage() {
    if (_currentState.hasSuccessMessage) {
      _updateControllerState(EventManagementControllerState.loaded(
        eventsCount: _managedEvents.length,
      ));
    }
  }

  /// **Method**: Retry last failed operation
  /// **AI Context**: Convenience method to retry operations after errors
  /// **Side Effects**: Re-executes last operation with cached data
  Future<void> retryLastOperation() async {
    if (_currentEventCreationData != null) {
      await createNewEvent(eventCreationData: _currentEventCreationData!);
    } else {
      await loadManagedEvents(forceRefresh: true);
    }
  }

  /// **Method**: Reset controller to initial state
  /// **AI Context**: Called during logout, navigation reset, or testing
  /// **Side Effects**: Clears all cached data and resets to initial state
  void resetController() {
    _managedEvents.clear();
    _selectedEvent = null;
    _currentEventCreationData = null;
    _currentFilters = EventListFilters.defaults();
    _updateControllerState(EventManagementControllerState.initial());
  }

  /// **Method**: Get event statistics for dashboard display
  /// **AI Context**: Calculate metrics from managed events for UI summaries
  /// **Returns**: EventManagementStatistics with calculated metrics
  EventManagementStatistics getEventStatistics() {
    final totalEvents = _managedEvents.length;
    final activeEvents = _managedEvents
        .where((event) => event.eventStatus == EventStatusType.active)
        .length;
    final draftEvents = _managedEvents
        .where((event) => event.eventStatus == EventStatusType.draft)
        .length;
    final completedEvents = _managedEvents
        .where((event) => event.eventStatus == EventStatusType.completed)
        .length;
    
    final totalParticipants = _managedEvents
        .fold<int>(0, (sum, event) => sum + event.currentRegisteredCount);

    return EventManagementStatistics(
      totalEventsManaged: totalEvents,
      activeEventsCount: activeEvents,
      draftEventsCount: draftEvents,
      completedEventsCount: completedEvents,
      totalParticipantsAcrossEvents: totalParticipants,
    );
  }

  /// **Private Method**: Apply current filters to event list
  /// **AI Context**: Filter and sort event list based on user preferences
  /// **Input**: events List of EventEntity to filter
  /// **Returns**: List of EventEntity filtered and sorted events
  List<EventEntity> _applyFiltersToEvents(List<EventEntity> events) {
    var filteredEvents = events.toList();

    // AI Context: Apply status filter
    if (_currentFilters.statusFilter != null) {
      filteredEvents = filteredEvents
          .where((event) => event.eventStatus == _currentFilters.statusFilter)
          .toList();
    }

    // AI Context: Apply event type filter
    if (_currentFilters.typeFilter != null) {
      filteredEvents = filteredEvents
          .where((event) => event.eventType == _currentFilters.typeFilter)
          .toList();
    }

    // AI Context: Apply date range filter
    if (_currentFilters.startDateFilter != null) {
      filteredEvents = filteredEvents
          .where((event) => event.scheduleInfo.eventStartDateTime
              .isAfter(_currentFilters.startDateFilter!))
          .toList();
    }

    if (_currentFilters.endDateFilter != null) {
      filteredEvents = filteredEvents
          .where((event) => event.scheduleInfo.eventEndDateTime
              .isBefore(_currentFilters.endDateFilter!))
          .toList();
    }

    // AI Context: Apply sorting
    switch (_currentFilters.sortBy) {
      case EventSortingOption.createdDateDesc:
        filteredEvents.sort((a, b) => b.eventCreatedAt.compareTo(a.eventCreatedAt));
        break;
      case EventSortingOption.createdDateAsc:
        filteredEvents.sort((a, b) => a.eventCreatedAt.compareTo(b.eventCreatedAt));
        break;
      case EventSortingOption.startDateAsc:
        filteredEvents.sort((a, b) => a.scheduleInfo.eventStartDateTime
            .compareTo(b.scheduleInfo.eventStartDateTime));
        break;
      case EventSortingOption.startDateDesc:
        filteredEvents.sort((a, b) => b.scheduleInfo.eventStartDateTime
            .compareTo(a.scheduleInfo.eventStartDateTime));
        break;
      case EventSortingOption.titleAsc:
        filteredEvents.sort((a, b) => a.eventTitle.compareTo(b.eventTitle));
        break;
      case EventSortingOption.titleDesc:
        filteredEvents.sort((a, b) => b.eventTitle.compareTo(a.eventTitle));
        break;
      // Default case removed - unreachable
    }

    // AI Context: Apply max results limit
    if (_currentFilters.maxResults != null) {
      filteredEvents = filteredEvents.take(_currentFilters.maxResults!).toList();
    }

    return filteredEvents;
  }

  /// **Private Method**: Update controller state and notify listeners
  /// **AI Context**: Centralized state update with automatic UI notification
  /// **Input**: newState (EventManagementControllerState)
  /// **Side Effects**: Updates internal state, calls notifyListeners()
  void _updateControllerState(EventManagementControllerState newState) {
    _currentState = newState;
    notifyListeners(); // AI Context: Trigger UI rebuild for state-dependent widgets
  }

  @override
  void dispose() {
    // AI Context: Clean up resources when controller is disposed
    _managedEvents.clear();
    _selectedEvent = null;
    _currentEventCreationData = null;
    super.dispose();
  }
}

/// **EventManagementControllerState**: Immutable state object for event management UI
/// **AI Context**: Value object representing all possible event management states
class EventManagementControllerState {
  final EventManagementStateType stateType;
  final EventOperationType? operationType;
  final String? statusMessage;
  final String? errorMessage;
  final String? successMessage;
  final EventEntity? affectedEvent;
  final int? eventsCount;

  const EventManagementControllerState._({
    required this.stateType,
    this.operationType,
    this.statusMessage,
    this.errorMessage,
    this.successMessage,
    this.affectedEvent,
    this.eventsCount,
  });

  /// **Factory**: Create initial state
  factory EventManagementControllerState.initial() {
    return const EventManagementControllerState._(
      stateType: EventManagementStateType.initial,
    );
  }

  /// **Factory**: Create loading state
  factory EventManagementControllerState.loading({
    required EventOperationType operationType,
    String? statusMessage,
  }) {
    return EventManagementControllerState._(
      stateType: EventManagementStateType.loading,
      operationType: operationType,
      statusMessage: statusMessage,
    );
  }

  /// **Factory**: Create loaded state
  factory EventManagementControllerState.loaded({
    required int eventsCount,
    String? statusMessage,
  }) {
    return EventManagementControllerState._(
      stateType: EventManagementStateType.loaded,
      eventsCount: eventsCount,
      statusMessage: statusMessage,
    );
  }

  /// **Factory**: Create event selected state
  factory EventManagementControllerState.eventSelected({
    required EventEntity selectedEvent,
  }) {
    return EventManagementControllerState._(
      stateType: EventManagementStateType.eventSelected,
      affectedEvent: selectedEvent,
    );
  }

  /// **Factory**: Create operation success state
  factory EventManagementControllerState.operationSuccess({
    required EventOperationType operationType,
    required String successMessage,
    EventEntity? affectedEvent,
  }) {
    return EventManagementControllerState._(
      stateType: EventManagementStateType.operationSuccess,
      operationType: operationType,
      successMessage: successMessage,
      affectedEvent: affectedEvent,
    );
  }

  /// **Factory**: Create operation error state
  factory EventManagementControllerState.operationError({
    required EventOperationType operationType,
    required String errorMessage,
  }) {
    return EventManagementControllerState._(
      stateType: EventManagementStateType.error,
      operationType: operationType,
      errorMessage: errorMessage,
    );
  }

  // **Convenience Getters**: Boolean checks for UI logic
  bool get isInitial => stateType == EventManagementStateType.initial;
  bool get isLoading => stateType == EventManagementStateType.loading;
  bool get isLoaded => stateType == EventManagementStateType.loaded;
  bool get hasEventSelected => stateType == EventManagementStateType.eventSelected;
  bool get hasError => stateType == EventManagementStateType.error;
  bool get hasSuccessMessage => stateType == EventManagementStateType.operationSuccess;
  bool get allowsUserInteraction => !isLoading;
}

/// **Supporting Classes**: Filtering, statistics, and operational data

/// **EventListFilters**: User preferences for event list display
class EventListFilters {
  final EventStatusType? statusFilter;
  final EventType? typeFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final int? maxResults;
  final EventSortingOption sortBy;

  const EventListFilters({
    this.statusFilter,
    this.typeFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.maxResults,
    this.sortBy = EventSortingOption.startDateAsc,
  });

  factory EventListFilters.defaults() {
    return const EventListFilters(
      sortBy: EventSortingOption.startDateAsc,
      maxResults: 100,
    );
  }

  EventListFilters copyWith({
    EventStatusType? statusFilter,
    EventType? typeFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
    int? maxResults,
    EventSortingOption? sortBy,
  }) {
    return EventListFilters(
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      startDateFilter: startDateFilter ?? this.startDateFilter,
      endDateFilter: endDateFilter ?? this.endDateFilter,
      maxResults: maxResults ?? this.maxResults,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// **EventManagementStatistics**: Calculated metrics for dashboard display
class EventManagementStatistics {
  final int totalEventsManaged;
  final int activeEventsCount;
  final int draftEventsCount;
  final int completedEventsCount;
  final int totalParticipantsAcrossEvents;

  const EventManagementStatistics({
    required this.totalEventsManaged,
    required this.activeEventsCount,
    required this.draftEventsCount,
    required this.completedEventsCount,
    required this.totalParticipantsAcrossEvents,
  });

  double get activeEventsPercentage => totalEventsManaged > 0
      ? (activeEventsCount / totalEventsManaged) * 100
      : 0.0;

  double get averageParticipantsPerEvent => totalEventsManaged > 0
      ? totalParticipantsAcrossEvents / totalEventsManaged
      : 0.0;
}

/// **Enums**: State types and operation categories
enum EventManagementStateType {
  initial,
  loading,
  loaded,
  eventSelected,
  operationSuccess,
  error,
}

enum EventOperationType {
  creating,
  updating,
  deleting,
  loading,
  statusChanging,
}