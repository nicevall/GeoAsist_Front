// test/utils/test_instance_factory.dart
// 🏭 Test Instance Factory for Singleton Services
// Provides clean instances for testing to avoid stream controller lifecycle issues

import 'dart:async';

import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/background_location_service.dart';

/// Factory for creating test instances of singleton services
/// Prevents "Cannot add new events after calling close" errors
class TestInstanceFactory {
  static final Map<Type, dynamic> _testInstances = {};
  static final Set<Type> _disposedTypes = {};

  /// Creates or returns a fresh test instance of StudentAttendanceManager
  static StudentAttendanceManager createStudentAttendanceManager() {
    final type = StudentAttendanceManager;
    
    if (_disposedTypes.contains(type) || !_testInstances.containsKey(type)) {
      _testInstances[type] = _createFreshStudentAttendanceManager();
      _disposedTypes.remove(type);
    }
    
    return _testInstances[type] as StudentAttendanceManager;
  }

  /// Creates or returns a fresh test instance of EventoService
  static EventoService createEventoService() {
    final type = EventoService;
    
    if (_disposedTypes.contains(type) || !_testInstances.containsKey(type)) {
      _testInstances[type] = _createFreshEventoService();
      _disposedTypes.remove(type);
    }
    
    return _testInstances[type] as EventoService;
  }

  /// Creates or returns a fresh test instance of LocationService
  static LocationService createLocationService({dynamic apiService}) {
    final type = LocationService;
    
    // If apiService is provided, always create fresh instance to avoid cache issues
    if (apiService != null || _disposedTypes.contains(type) || !_testInstances.containsKey(type)) {
      _testInstances[type] = _createFreshLocationService(apiService: apiService);
      _disposedTypes.remove(type);
    }
    
    return _testInstances[type] as LocationService;
  }

  /// Creates or returns a fresh test instance of BackgroundLocationService
  static BackgroundLocationService createBackgroundLocationService() {
    final type = BackgroundLocationService;
    
    if (_disposedTypes.contains(type) || !_testInstances.containsKey(type)) {
      _testInstances[type] = _createFreshBackgroundLocationService();
      _disposedTypes.remove(type);
    }
    
    return _testInstances[type] as BackgroundLocationService;
  }

  /// Safely dispose a service instance and mark it for recreation
  static Future<void> disposeService<T>() async {
    final type = T;
    
    if (_testInstances.containsKey(type)) {
      final instance = _testInstances[type];
      
      try {
        // Call dispose if available
        if (instance.dispose != null) {
          await instance.dispose();
        }
      } catch (e) {
        // Ignore dispose errors in tests
      }
      
      _testInstances.remove(type);
      _disposedTypes.add(type);
    }
  }

  /// Dispose all cached instances
  static Future<void> disposeAll() async {
    final types = [
      StudentAttendanceManager,
      EventoService,
      LocationService,
      BackgroundLocationService,
    ];

    for (final type in types) {
      if (_testInstances.containsKey(type)) {
        final instance = _testInstances[type];
        
        try {
          if (instance.dispose != null) {
            await instance.dispose();
          }
        } catch (e) {
          // Ignore dispose errors in tests
        }
      }
    }

    _testInstances.clear();
    _disposedTypes.addAll(types);
  }

  /// Reset the factory state
  static void reset() {
    _testInstances.clear();
    _disposedTypes.clear();
  }

  /// Check if a service type is marked as disposed
  static bool isDisposed<T>() {
    return _disposedTypes.contains(T);
  }

  /// Get current test instance without creating new one
  static T? getCurrentInstance<T>() {
    return _testInstances[T] as T?;
  }

  // Private factory methods that create fresh instances
  
  static StudentAttendanceManager _createFreshStudentAttendanceManager() {
    // Force a completely new instance by using test factory method
    // This bypasses the singleton pattern for testing
    return StudentAttendanceManager.createTestInstance();
  }

  static EventoService _createFreshEventoService() {
    return EventoService.createTestInstance();
  }

  static LocationService _createFreshLocationService({dynamic apiService}) {
    return LocationService.createTestInstance(apiService: apiService);
  }

  static BackgroundLocationService _createFreshBackgroundLocationService() {
    return BackgroundLocationService.createTestInstance();
  }
}

/// Test instance factory provides fresh instances that won't have 
/// stream controller lifecycle conflicts between tests

/// Test wrapper for singleton services
/// Provides isolated instances for each test
class TestServiceWrapper<T> {
  T? _instance;
  final T Function() _factory;

  TestServiceWrapper(this._factory);

  T get instance {
    _instance ??= _factory();
    return _instance!;
  }

  Future<void> dispose() async {
    if (_instance != null) {
      try {
        final disposable = _instance as dynamic;
        if (disposable.dispose != null) {
          await disposable.dispose();
        }
      } catch (e) {
        // Ignore dispose errors in tests
      }
      _instance = null;
    }
  }

  void reset() {
    _instance = null;
  }
}

/// Extension to provide test-safe singleton access
extension TestSafeService on Object {
  /// Get a test-safe instance that won't have stream controller conflicts
  static T testInstance<T>() {
    switch (T) {
      case StudentAttendanceManager _:
        return TestInstanceFactory.createStudentAttendanceManager() as T;
      case EventoService _:
        return TestInstanceFactory.createEventoService() as T;
      case LocationService _:
        return TestInstanceFactory.createLocationService() as T;
      case BackgroundLocationService _:
        return TestInstanceFactory.createBackgroundLocationService() as T;
      default:
        throw UnsupportedError('No test factory for type $T');
    }
  }
}