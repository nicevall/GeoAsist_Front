// lib/core/bloc/base_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';

/// Base BLoC class that provides common functionality for all BLoCs
/// Includes centralized error handling and logging
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  @override
  void onError(Object error, StackTrace stackTrace) {
    // Centralized error handling
    _logError(runtimeType.toString(), error, stackTrace);
    super.onError(error, stackTrace);
  }

  @override
  void onTransition(Transition<Event, State> transition) {
    // Centralized state transition logging
    _logTransition(transition);
    super.onTransition(transition);
  }

  @override
  void onEvent(Event event) {
    // Centralized event logging
    _logEvent(event);
    super.onEvent(event);
  }

  void _logError(String blocName, Object error, StackTrace stackTrace) {
    logger.i('❌ [$blocName] Error: $error');
    logger.i('📍 StackTrace: $stackTrace');
  }

  void _logTransition(Transition<Event, State> transition) {
    logger.i('🔄 [$runtimeType] ${transition.currentState} -> ${transition.nextState}');
  }

  void _logEvent(Event event) {
    logger.i('🎯 [$runtimeType] Event: $event');
  }

  /// Helper method to emit multiple states in sequence
  void emitStates(Emitter<State> emit, List<State> states) {
    for (final state in states) {
      emit(state);
    }
  }

  /// Helper method to handle async operations with loading states
  Future<void> handleAsyncOperation<T>({
    required Emitter<State> emit,
    required Future<T> operation,
    required State loadingState,
    required State Function(T result) successState,
    required State Function(Object error) errorState,
  }) async {
    emit(loadingState);
    try {
      final result = await operation;
      emit(successState(result));
    } catch (error) {
      emit(errorState(error));
    }
  }
}

/// Base Cubit class for simpler state management scenarios
abstract class BaseCubit<State> extends Cubit<State> {
  BaseCubit(super.initialState);

  @override
  void onError(Object error, StackTrace stackTrace) {
    _logError(runtimeType.toString(), error, stackTrace);
    super.onError(error, stackTrace);
  }

  @override
  void onChange(Change<State> change) {
    _logChange(change);
    super.onChange(change);
  }

  void _logError(String cubitName, Object error, StackTrace stackTrace) {
    logger.i('❌ [$cubitName] Error: $error');
    logger.i('📍 StackTrace: $stackTrace');
  }

  void _logChange(Change<State> change) {
    logger.i('🔄 [$runtimeType] ${change.currentState} -> ${change.nextState}');
  }

  /// Helper method to handle async operations with loading states
  Future<void> handleAsyncOperation<T>({
    required Future<T> operation,
    required State loadingState,
    required State Function(T result) successState,
    required State Function(Object error) errorState,
  }) async {
    emit(loadingState);
    try {
      final result = await operation;
      emit(successState(result));
    } catch (error) {
      emit(errorState(error));
    }
  }

  /// Safe emit that checks if the cubit is not closed
  void safeEmit(State state) {
    if (!isClosed) {
      emit(state);
    }
  }
}