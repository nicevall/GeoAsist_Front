// test/unit/stream_lifecycle_test.dart
// 🧪 Stream Controller Lifecycle Tests
// Tests to validate that TestInstanceFactory resolves "Cannot add new events after calling close" errors

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/background_location_service.dart';

import '../utils/test_instance_factory.dart';
import '../utils/test_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🔄 Stream Controller Lifecycle Tests', () {
    setUpAll(() async {
      await TestConfig.initialize();
    });

    setUp(() {
      TestInstanceFactory.reset();
    });

    tearDown(() async {
      await TestInstanceFactory.disposeAll();
    });

    group('StudentAttendanceManager Stream Lifecycle', () {
      test('should handle multiple fresh instances without stream conflicts', () async {
        // Create first instance and interact with its stream
        final manager1 = TestInstanceFactory.createStudentAttendanceManager();
        final stateStream1 = manager1.stateStream;
        
        expect(manager1, isNotNull);
        expect(stateStream1, isNotNull);
        
        // Get initial state
        final initialState = manager1.currentState;
        expect(initialState, isNotNull);

        // Dispose the first instance
        await TestInstanceFactory.disposeService<StudentAttendanceManager>();

        // Create second instance - should be completely fresh
        final manager2 = TestInstanceFactory.createStudentAttendanceManager();
        final stateStream2 = manager2.stateStream;
        
        expect(manager2, isNotNull);
        expect(stateStream2, isNotNull);
        
        // Should be able to access state without "Cannot add new events" error
        final secondState = manager2.currentState;
        expect(secondState, isNotNull);
        
        // Should be able to get state info without errors
        final stateInfo = manager2.getCurrentStateInfo();
        expect(stateInfo, isNotNull);
        expect(stateInfo, isA<Map<String, dynamic>>());
      });

      test('should handle stream subscriptions safely', () async {
        final manager = TestInstanceFactory.createStudentAttendanceManager();
        
        // Subscribe to stream
        final subscription = manager.stateStream.listen((state) {
          // Listen to state changes
        });
        
        expect(subscription, isNotNull);
        
        // Cancel subscription safely
        await subscription.cancel();
        
        // Should still be able to access current state
        final state = manager.currentState;
        expect(state, isNotNull);
      });

      test('should handle rapid creation and disposal', () async {
        for (int i = 0; i < 5; i++) {
          final manager = TestInstanceFactory.createStudentAttendanceManager();
          
          // Access stream and state
          final stream = manager.stateStream;
          final state = manager.currentState;
          
          expect(stream, isNotNull);
          expect(state, isNotNull);
          
          // Dispose
          await TestInstanceFactory.disposeService<StudentAttendanceManager>();
        }
      });
    });

    group('EventoService Stream Lifecycle', () {
      test('should handle fresh instances without stream conflicts', () async {
        // Create first instance
        final service1 = TestInstanceFactory.createEventoService();
        final stream1 = service1.loadingStatesStream;
        
        expect(service1, isNotNull);
        expect(stream1, isNotNull);
        
        // Access state management methods
        final states = service1.getAllLoadingStates();
        expect(states, isNotNull);

        // Dispose the first instance
        await TestInstanceFactory.disposeService<EventoService>();

        // Create second instance - should be completely fresh
        final service2 = TestInstanceFactory.createEventoService();
        final stream2 = service2.loadingStatesStream;
        
        expect(service2, isNotNull);
        expect(stream2, isNotNull);
        
        // Should be able to access methods without conflicts
        final states2 = service2.getAllLoadingStates();
        expect(states2, isNotNull);
      });

      test('should handle loading state management', () async {
        final service = TestInstanceFactory.createEventoService();
        
        // Access loading states
        final states = service.getAllLoadingStates();
        expect(states, isA<Map>());
        
        // Check operations
        expect(service.hasLoadingOperations, isA<bool>());
        expect(service.operationsWithErrors, isA<List<String>>());
        
        // Clear states
        service.clearAllLoadingStates();
        
        final clearedStates = service.getAllLoadingStates();
        expect(clearedStates.isEmpty, isTrue);
      });
    });

    group('LocationService Stream Lifecycle', () {
      test('should handle fresh instances without performance conflicts', () async {
        // Create first instance
        final service1 = TestInstanceFactory.createLocationService();
        
        expect(service1, isNotNull);
        
        // Access performance stats
        final stats1 = service1.getPerformanceStats();
        expect(stats1, isA<Map<String, dynamic>>());

        // Dispose the first instance
        await TestInstanceFactory.disposeService<LocationService>();

        // Create second instance - should be completely fresh
        final service2 = TestInstanceFactory.createLocationService();
        
        expect(service2, isNotNull);
        
        // Should have fresh performance stats
        final stats2 = service2.getPerformanceStats();
        expect(stats2, isA<Map<String, dynamic>>());
      });
    });

    group('BackgroundLocationService Stream Lifecycle', () {
      test('should handle fresh instances without tracking conflicts', () async {
        // Create first instance
        final service1 = TestInstanceFactory.createBackgroundLocationService();
        
        expect(service1, isNotNull);
        
        // Access tracking status
        final status1 = service1.getTrackingStatus();
        expect(status1, isA<Map<String, dynamic>>());
        expect(status1['isTracking'], isFalse);

        // Dispose the first instance
        await TestInstanceFactory.disposeService<BackgroundLocationService>();

        // Create second instance - should be completely fresh
        final service2 = TestInstanceFactory.createBackgroundLocationService();
        
        expect(service2, isNotNull);
        
        // Should have fresh tracking status
        final status2 = service2.getTrackingStatus();
        expect(status2, isA<Map<String, dynamic>>());
        expect(status2['isTracking'], isFalse);
      });
    });

    group('Cross-Service Integration Tests', () {
      test('should handle multiple services simultaneously', () async {
        final manager = TestInstanceFactory.createStudentAttendanceManager();
        final eventoService = TestInstanceFactory.createEventoService();
        final locationService = TestInstanceFactory.createLocationService();
        final backgroundService = TestInstanceFactory.createBackgroundLocationService();
        
        // All services should be accessible
        expect(manager, isNotNull);
        expect(eventoService, isNotNull);
        expect(locationService, isNotNull);
        expect(backgroundService, isNotNull);
        
        // Access their methods without conflicts
        expect(manager.currentState, isNotNull);
        expect(eventoService.getAllLoadingStates(), isNotNull);
        expect(locationService.getPerformanceStats(), isNotNull);
        expect(backgroundService.getTrackingStatus(), isNotNull);
        
        // Dispose all
        await TestInstanceFactory.disposeAll();
        
        // Should be able to create fresh instances
        final freshManager = TestInstanceFactory.createStudentAttendanceManager();
        expect(freshManager, isNotNull);
        expect(freshManager.currentState, isNotNull);
      });

      test('should prevent stream controller conflicts between tests', () async {
        // Simulate scenario that would cause "Cannot add new events after calling close"
        
        // Test 1: Create and use services
        final manager1 = TestInstanceFactory.createStudentAttendanceManager();
        final subscription1 = manager1.stateStream.listen((_) {});
        
        // Simulate test cleanup
        await subscription1.cancel();
        await TestInstanceFactory.disposeService<StudentAttendanceManager>();
        
        // Test 2: Create new services (this would fail with regular singletons)
        final manager2 = TestInstanceFactory.createStudentAttendanceManager();
        
        // This should NOT throw "Cannot add new events after calling close"
        expect(() => manager2.currentState, returnsNormally);
        expect(() => manager2.getCurrentStateInfo(), returnsNormally);
        
        final subscription2 = manager2.stateStream.listen((_) {});
        expect(subscription2, isNotNull);
        
        await subscription2.cancel();
      });
    });

    group('Factory State Management', () {
      test('should track disposed services correctly', () {
        expect(TestInstanceFactory.isDisposed<StudentAttendanceManager>(), isFalse);
        
        final manager = TestInstanceFactory.createStudentAttendanceManager();
        expect(manager, isNotNull);
        expect(TestInstanceFactory.getCurrentInstance<StudentAttendanceManager>(), isNotNull);
      });

      test('should reset factory state correctly', () async {
        final manager = TestInstanceFactory.createStudentAttendanceManager();
        expect(manager, isNotNull);
        
        TestInstanceFactory.reset();
        
        expect(TestInstanceFactory.isDisposed<StudentAttendanceManager>(), isFalse);
        expect(TestInstanceFactory.getCurrentInstance<StudentAttendanceManager>(), isNull);
      });
    });
  });
}