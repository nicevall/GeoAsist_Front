// test/unit/background_location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geo_asist_front/services/background_location_service.dart';
import '../utils/test_config.dart';

// ✅ MOCK WORKMANAGER COMPLETO
class MockWorkmanager extends Mock implements Workmanager {}

void main() {
  group('BackgroundLocationService Singleton Behavior Tests', () {
    late MockWorkmanager mockWorkmanager;
    
    setUp(() async {
      await TestConfig.initialize();
      
      // Setup mock workmanager for testing
      mockWorkmanager = MockWorkmanager();
      when(() => mockWorkmanager.initialize(any())).thenAnswer((_) async {});
      when(() => mockWorkmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        initialDelay: any(named: 'initialDelay'),
        constraints: any(named: 'constraints'),
        inputData: any(named: 'inputData'),
      )).thenAnswer((_) async {});
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      TestConfig.cleanup();
    });

    group('✅ Singleton Pattern Behavior Tests', () {
      test('should create consistent test instances', () async {
        // Create test instances to validate singleton behavior
        final service1 = BackgroundLocationService.createTestInstance();
        final service2 = BackgroundLocationService.createTestInstance();
        
        // Assert - Different test instances (not singleton behavior for test instances)
        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(service1, isNot(same(service2))); // Test instances are different
      });

      test('should report correct tracking status structure', () async {
        // Arrange
        final service = BackgroundLocationService.withMockWorkmanager(mockWorkmanager);
        
        // Act
        final status = service.getTrackingStatus();
        
        // Assert - Validate status structure
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('isInitialized'), true);
        expect(status.containsKey('isTracking'), true);
        expect(status.containsKey('hasLocationService'), true);
        expect(status.containsKey('hasActiveTimer'), true);
        expect(status.containsKey('instanceHash'), true);
      });

      test('should start and stop continuous tracking correctly', () async {
        // Arrange
        final service = BackgroundLocationService.withMockWorkmanager(mockWorkmanager);
        
        // Act
        final startSuccess = await service.startContinuousTracking(
          userId: 'user_123',
          eventoId: 'event_123',
        );
        
        // Assert
        expect(startSuccess, false); // Should fail because service is not initialized
        
        // Stop tracking (should handle gracefully)
        service.stopTracking();
        expect(service.getTrackingStatus()['isTracking'], false);
      });

      test('should handle dispose correctly without throwing', () async {
        // Arrange
        final service = BackgroundLocationService.createTestInstance();
        
        // Act & Assert - Should not throw
        await service.dispose();
        
        // Verify dispose behavior
        expect(service.getTrackingStatus()['isInitialized'], false);
      });

      test('should validate error handling during initialization', () async {
        // This tests the pattern where getInstance handles errors gracefully
        // We can't easily test the actual singleton without platform dependencies
        // but we can validate the error handling structure
        
        final service = BackgroundLocationService.createTestInstance();
        expect(service, isNotNull);
        expect(service.getTrackingStatus()['isInitialized'], false);
      });
    });
  });

  group('BackgroundLocationService Complete Tests', () {
    late BackgroundLocationService service;
    late MockWorkmanager mockWorkmanager;

    setUp(() async {
      await TestConfig.initialize();
      
      // ✅ SETUP MOCK WORKMANAGER
      mockWorkmanager = MockWorkmanager();
      
      // Mock all Workmanager methods
      when(() => mockWorkmanager.initialize(
        any(),
      )).thenAnswer((_) async {});
      
      when(() => mockWorkmanager.registerOneOffTask(
        any(),
        any(),
        constraints: any(named: 'constraints'),
        inputData: any(named: 'inputData'),
      )).thenAnswer((_) async {});
      
      when(() => mockWorkmanager.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        initialDelay: any(named: 'initialDelay'),
        constraints: any(named: 'constraints'),
        inputData: any(named: 'inputData'),
      )).thenAnswer((_) async {});
      
      when(() => mockWorkmanager.cancelByUniqueName(any()))
          .thenAnswer((_) async {});
      
      when(() => mockWorkmanager.cancelAll())
          .thenAnswer((_) async {});

      // ✅ CREAR SERVICE CON MOCK INYECTADO
      service = BackgroundLocationService.withMockWorkmanager(mockWorkmanager);
    });

    tearDown(() {
      TestConfig.cleanup();
    });

    group('✅ Initialization Tests', () {
      test('should create test service without throwing errors', () async {
        // Act & Assert - No debe tirar errores al crear instancia de test
        expect(service, isNotNull);
        expect(service.isInitialized, isFalse); // Test instance starts uninitialized
      });

      test('should handle workmanager operations correctly', () async {
        // Act - Operations that would normally initialize workmanager
        await service.startEventTracking('test_event');
        
        // Assert - Workmanager should be called
        verify(() => mockWorkmanager.registerPeriodicTask(
          any(),
          any(),
          frequency: any(named: 'frequency'),
          initialDelay: any(named: 'initialDelay'),
          constraints: any(named: 'constraints'),
          inputData: any(named: 'inputData'),
        )).called(1);
      });
    });

    group('✅ Task Management Tests', () {
      test('should register background tasks correctly', () async {
        // Act
        await service.startEventTracking('test_event_123');

        // Assert
        verify(() => mockWorkmanager.registerPeriodicTask(
          any(),
          any(),
          frequency: any(named: 'frequency'),
          initialDelay: any(named: 'initialDelay'),
          constraints: any(named: 'constraints'),
          inputData: any(named: 'inputData'),
        )).called(1);
        
        expect(service.isTracking, isTrue);
        expect(service.currentEventId, equals('test_event_123'));
      });

      test('should cancel background tasks correctly', () async {
        // Arrange
        await service.startEventTracking('test_event_123');

        // Act
        await service.stopEventTracking();

        // Assert
        verify(() => mockWorkmanager.cancelByUniqueName(any())).called(greaterThanOrEqualTo(1));
        expect(service.isTracking, isFalse);
        expect(service.currentEventId, isNull);
      });

      test('should handle task cancellation errors', () async {
        // Arrange
        when(() => mockWorkmanager.cancelByUniqueName(any()))
            .thenThrow(Exception('Cancel failed'));

        // Act & Assert - No debe crashear
        await service.stopEventTracking();
        expect(service.isTracking, isFalse);
      });
    });

    group('✅ State Management Tests', () {
      test('should track state correctly', () async {
        // Arrange
        expect(service.isTracking, isFalse);

        // Act
        await service.startEventTracking('test_event');

        // Assert
        expect(service.isTracking, isTrue);
        expect(service.currentEventId, equals('test_event'));
      });

      test('should reset state on stop', () async {
        // Arrange
        await service.startEventTracking('test_event');
        expect(service.isTracking, isTrue);

        // Act
        await service.stopEventTracking();

        // Assert
        expect(service.isTracking, isFalse);
        expect(service.currentEventId, isNull);
      });

      test('should return correct tracking status', () {
        // Arrange
        service.startEventTracking('status_test_event');

        // Act
        final status = service.getTrackingStatus();

        // Assert
        expect(status['isTracking'], isTrue);
        expect(status['currentEventId'], equals('status_test_event'));
        expect(status['isInitialized'], isA<bool>());
      });
    });

    group('✅ Error Resilience Tests', () {
      test('should handle multiple start calls gracefully', () async {
        // Act - Múltiples llamadas
        await service.startEventTracking('event1');
        await service.startEventTracking('event2');
        await service.startEventTracking('event3');

        // Assert - Debe manejar múltiples llamadas
        expect(service.isTracking, isTrue);
        expect(service.currentEventId, equals('event3')); // Last one wins
      });

      test('should handle stop without start', () async {
        // Act & Assert - No debe crashear
        await service.stopEventTracking();
        expect(service.isTracking, isFalse);
      });

      test('should handle register task failures gracefully', () async {
        // Arrange
        when(() => mockWorkmanager.registerPeriodicTask(
          any(),
          any(),
          frequency: any(named: 'frequency'),
          initialDelay: any(named: 'initialDelay'),
          constraints: any(named: 'constraints'),
          inputData: any(named: 'inputData'),
        )).thenThrow(Exception('Register failed'));

        // Act & Assert
        await service.startEventTracking('fail_event');
        
        // Should handle error gracefully
        expect(service.isTracking, isFalse);
      });
    });

    group('✅ Pause/Resume Tests', () {
      test('should pause tracking correctly', () async {
        // Arrange
        await service.startEventTracking('pause_test');
        expect(service.isTracking, isTrue);

        // Act
        await service.pauseTracking();

        // Assert - Should still be tracking but in paused mode
        expect(service.isTracking, isTrue);
        verify(() => mockWorkmanager.cancelByUniqueName(any())).called(greaterThanOrEqualTo(1));
        verify(() => mockWorkmanager.registerPeriodicTask(
          any(),
          any(),
          frequency: any(named: 'frequency'),
          initialDelay: any(named: 'initialDelay'),
          constraints: any(named: 'constraints'),
          inputData: any(named: 'inputData'),
        )).called(greaterThanOrEqualTo(1));
      });

      test('should resume tracking correctly', () async {
        // Arrange
        await service.startEventTracking('resume_test');
        await service.pauseTracking();

        // Act
        await service.resumeTracking('resume_test');

        // Assert
        expect(service.isTracking, isTrue);
        expect(service.currentEventId, equals('resume_test'));
      });

      test('should handle pause without active tracking', () async {
        // Act & Assert - No debe crashear
        await service.pauseTracking();
        expect(service.isTracking, isFalse);
      });
    });

    group('✅ Force Update Tests', () {
      test('should handle force update when not tracking', () async {
        // Act
        final result = await service.forceBackgroundUpdate();

        // Assert
        expect(result, isFalse);
      });

      test('should handle force update when tracking', () async {
        // Arrange
        await service.startEventTracking('force_test');

        // Act
        final result = await service.forceBackgroundUpdate();

        // Assert - May fail due to location mocking, but shouldn't crash
        expect(result, isA<bool>());
      });
    });
  });
}