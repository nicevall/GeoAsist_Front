// test/unit/background_location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geo_asist_front/services/background_location_service.dart';
import '../utils/test_config.dart';

// ✅ MOCK WORKMANAGER COMPLETO
class MockWorkmanager extends Mock implements Workmanager {}

void main() {
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
      test('should initialize without throwing errors', () async {
        // Act & Assert - No debe tirar errores
        await service.initialize();
        
        // Verificar que Workmanager fue llamado
        verify(() => mockWorkmanager.initialize(
          any(),
        )).called(1);
        
        expect(service.isInitialized, isTrue);
      });

      test('should handle initialization failure gracefully', () async {
        // Arrange - Mock failure
        when(() => mockWorkmanager.initialize(
          any(),
        )).thenThrow(Exception('Workmanager init failed'));

        // Act & Assert
        await service.initialize();
        
        // Service should handle error internally
        expect(service.isInitialized, isFalse);
      });
    });

    group('✅ Task Management Tests', () {
      test('should register background tasks correctly', () async {
        // Arrange
        await service.initialize();

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
        await service.initialize();
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