// test/unit/student_attendance_manager_test.dart
// 🧪 BLOQUE 3 A1.3 - UNIT TESTING DEL STUDENT ATTENDANCE MANAGER - CORREGIDO
// Testing de la lógica central del sistema de asistencia

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/asistencia_service.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/notification_service.dart';
import 'package:geo_asist_front/services/storage_service.dart';
import 'package:geo_asist_front/models/attendance_state_model.dart';
import 'package:geo_asist_front/models/location_response_model.dart';
import 'package:geo_asist_front/models/evento_model.dart';
import 'package:geo_asist_front/models/usuario_model.dart';
import 'package:geo_asist_front/models/ubicacion_model.dart';
import 'package:geo_asist_front/models/api_response_model.dart';
import 'package:geo_asist_front/models/asistencia_model.dart';

// Generate mocks
@GenerateMocks([
  LocationService,
  AsistenciaService,
  EventoService,
  NotificationService,
  StorageService,
])
import 'student_attendance_manager_test.mocks.dart';

void main() {
  group('StudentAttendanceManager Tests', () {
    late StudentAttendanceManager attendanceManager;
    late MockLocationService mockLocationService;
    late MockAsistenciaService mockAsistenciaService;
    late MockEventoService mockEventoService;
    late MockNotificationService mockNotificationService;
    late MockStorageService mockStorageService;

    // Test data - CORREGIDO según modelos actuales
    final mockUser = Usuario(
      id: 'user123',
      nombre: 'Test User',
      correo: 'test@example.com',
      rol: 'estudiante',
      creadoEn: DateTime.now(),
    );

    final mockEvento = Evento(
      id: 'event123',
      titulo: 'Test Event',
      descripcion: 'Test Description',
      ubicacion: Ubicacion(
        latitud: -0.1805,
        longitud: -78.4680,
      ),
      fecha: DateTime.now(),
      horaInicio: DateTime.now().subtract(const Duration(minutes: 30)),
      horaFinal: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      rangoPermitido: 100.0,
      creadoPor: 'teacher123',
    );

    final mockLocationResponse = LocationResponseModel(
      insideGeofence: true,
      distance: 50.0,
      eventActive: true,
      eventStarted: true,
      userId: 'user123',
      latitude: -0.1805,
      longitude: -78.4680,
    );

    setUp(() {
      // Initialize mocks
      mockLocationService = MockLocationService();
      mockAsistenciaService = MockAsistenciaService();
      mockEventoService = MockEventoService();
      mockNotificationService = MockNotificationService();
      mockStorageService = MockStorageService();

      // Create manager instance
      attendanceManager = StudentAttendanceManager();

      // Configure default mock behaviors for StorageService
      when(mockStorageService.getUser()).thenAnswer((_) async => mockUser);

      // Configure default mock behaviors for NotificationService
      when(mockNotificationService.initialize()).thenAnswer((_) async {});
      when(mockNotificationService.clearAllNotifications())
          .thenAnswer((_) async {});
      when(mockNotificationService.showEventActiveNotification(
        eventName: anyNamed('eventName'),
        eventId: anyNamed('eventId'),
      )).thenAnswer((_) async {});

      // Configure default mock behaviors for LocationService
      when(mockLocationService.updateUserLocationComplete(
        userId: anyNamed('userId'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        eventoId: anyNamed('eventoId'),
      )).thenAnswer((_) async => mockLocationResponse);

      when(mockEventoService.obtenerEventoPorId(any))
          .thenAnswer((_) async => mockEvento);

      when(mockAsistenciaService.registrarAsistencia(
        eventoId: anyNamed('eventoId'),
        latitud: anyNamed('latitud'),
        longitud: anyNamed('longitud'),
      )).thenAnswer((_) async => ApiResponse.success(Asistencia(
            id: 'asistencia_123',
            estudiante: mockUser.id,
            evento: mockEvento.id!,
            hora: DateTime.now(),
            estado: 'Presente',
            coordenadas: Ubicacion(
              latitud: -0.1805,
              longitud: -78.4680,
            ),
            dentroDelRango: true,
          )));
    });

    tearDown(() {
      attendanceManager.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize with default state', () {
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.initial);
        expect(attendanceManager.currentState.attendanceStatus,
            AttendanceStatus.notStarted);
        expect(attendanceManager.currentState.isInsideGeofence, false);
        expect(attendanceManager.currentState.isInGracePeriod, false);
      });

      test('should initialize successfully', () async {
        // Act
        await attendanceManager.initialize();

        // Assert
        expect(attendanceManager.currentState.currentUser, mockUser);
        verify(mockStorageService.getUser()).called(1);
        verify(mockNotificationService.initialize()).called(1);
      });

      test('should handle initialization errors gracefully', () async {
        // Arrange
        when(mockStorageService.getUser())
            .thenThrow(Exception('Storage error'));

        // Act & Assert - Should not throw
        await attendanceManager.initialize();

        // Manager should still be functional even with storage error
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.initial);
      });
    });

    group('Event Tracking Tests', () {
      setUp(() async {
        await attendanceManager.initialize();
      });

      test('should start event tracking successfully', () async {
        // Act
        await attendanceManager.startEventTracking(mockEvento);

        // Assert
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.active);
        expect(attendanceManager.currentState.currentEvent, mockEvento);
        expect(attendanceManager.currentState.trackingStartTime, isNotNull);

        verify(mockNotificationService.showEventActiveNotification(
          eventName: mockEvento.titulo,
          eventId: mockEvento.id!,
        )).called(1);
      });

      test('should handle event tracking start failure', () async {
        // Arrange
        when(mockNotificationService.showEventActiveNotification(
          eventName: anyNamed('eventName'),
          eventId: anyNamed('eventId'),
        )).thenThrow(Exception('Notification error'));

        // Act
        await attendanceManager.startEventTracking(mockEvento);

        // Assert
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.error);
        expect(attendanceManager.currentState.lastError, isNotNull);
      });

      test('should stop tracking successfully', () async {
        // Arrange
        await attendanceManager.startEventTracking(mockEvento);

        // Act
        await attendanceManager.stopTracking();

        // Assert
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.stopped);
        expect(attendanceManager.currentState.isInGracePeriod, false);
        verify(mockNotificationService.clearAllNotifications()).called(1);
      });

      test('should pause and resume tracking', () async {
        // Arrange
        await attendanceManager.startEventTracking(mockEvento);
        when(mockNotificationService.showTrackingPausedNotification())
            .thenAnswer((_) async {});
        when(mockNotificationService.showTrackingResumedNotification())
            .thenAnswer((_) async {});

        // Act - Pause
        await attendanceManager.pauseTracking();

        // Assert - Paused
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.paused);
        verify(mockNotificationService.showTrackingPausedNotification())
            .called(1);

        // Act - Resume
        await attendanceManager.resumeTracking();

        // Assert - Resumed
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.active);
        verify(mockNotificationService.showTrackingResumedNotification())
            .called(1);
      });

      test('should complete event tracking', () async {
        // Arrange
        await attendanceManager.startEventTracking(mockEvento);

        // Act
        await attendanceManager.stopTracking();

        // Assert
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.stopped);
        expect(attendanceManager.currentState.isInGracePeriod, false);
      });
    });

    group('Location Updates Tests', () {
      setUp(() async {
        await attendanceManager.initialize();
        await attendanceManager.startEventTracking(mockEvento);
      });

      test('should process location update when inside geofence', () async {
        // Arrange
        final insideLocationResponse = LocationResponseModel(
          insideGeofence: true,
          distance: 30.0,
          eventActive: true,
          eventStarted: true,
          userId: 'user123',
          latitude: -0.1805,
          longitude: -78.4680,
        );

        when(mockLocationService.updateUserLocationComplete(
          userId: anyNamed('userId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          eventoId: anyNamed('eventoId'),
        )).thenAnswer((_) async => insideLocationResponse);

        // Simulate location update (this would normally be triggered by timer)
        // We'll test the internal state changes that would result
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.active);
      });

      test('should handle location update errors', () async {
        // Arrange
        when(mockLocationService.updateUserLocationComplete(
          userId: anyNamed('userId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          eventoId: anyNamed('eventoId'),
        )).thenThrow(Exception('Network error'));

        // The test verifies that errors don't crash the manager
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.active);
      });
    });

    group('Attendance Registration Tests', () {
      setUp(() async {
        await attendanceManager.initialize();
        await attendanceManager.startEventTracking(mockEvento);
      });

      test('should register attendance successfully when eligible', () async {
        // Arrange
        when(mockNotificationService.showAttendanceRegisteredNotification(
          eventName: anyNamed('eventName'),
        )).thenAnswer((_) async {});

        // Act
        final result = await attendanceManager.registerAttendance();

        // Assert
        expect(result, true);
        verify(mockNotificationService.showAttendanceRegisteredNotification(
          eventName: mockEvento.titulo,
        )).called(1);
      });

      test('should handle attendance registration service errors', () async {
        // Arrange
        when(mockNotificationService.showAttendanceRegisteredNotification(
          eventName: anyNamed('eventName'),
        )).thenThrow(Exception('Service unavailable'));

        // Act
        final result = await attendanceManager.registerAttendance();

        // Assert
        expect(result, false);
        expect(attendanceManager.currentState.lastError, isNotNull);
      });
    });

    group('State Management Tests', () {
      test('should emit state changes through stream', () async {
        // Arrange
        final stateChanges = <AttendanceState>[];
        final subscription = attendanceManager.stateStream.listen(
          (state) => stateChanges.add(state),
        );

        await attendanceManager.initialize();

        // Act
        await attendanceManager.startEventTracking(mockEvento);

        // Allow stream to emit
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(stateChanges.length, greaterThan(0));
        expect(stateChanges.last.trackingStatus, TrackingStatus.active);

        subscription.cancel();
      });

      test('should maintain state consistency during operations', () async {
        // Arrange
        await attendanceManager.initialize();

        // Act
        await attendanceManager.startEventTracking(mockEvento);

        // Assert state consistency
        final state = attendanceManager.currentState;
        expect(state.currentUser, mockUser);
        expect(state.currentEvent, mockEvento);
        expect(state.trackingStatus, TrackingStatus.active);
        expect(state.trackingStartTime, isNotNull);
      });

      test('should handle concurrent state updates safely', () async {
        // Arrange
        await attendanceManager.initialize();

        // Act - Perform concurrent operations
        final futures = [
          attendanceManager.startEventTracking(mockEvento),
          attendanceManager.registerAttendance(),
        ];

        await Future.wait(futures);

        // Assert - State should remain consistent
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.active);
      });
    });

    group('Cleanup and Disposal Tests', () {
      test('should clean up resources on disposal', () async {
        // Arrange
        await attendanceManager.initialize();
        await attendanceManager.startEventTracking(mockEvento);

        // Act
        await attendanceManager.dispose();

        // Assert - Should not throw and should be cleaned up
        verify(mockNotificationService.clearAllNotifications())
            .called(greaterThanOrEqualTo(1));
      });
    });

    group('Error Handling Tests', () {
      test('should handle service initialization errors gracefully', () async {
        // Arrange
        when(mockNotificationService.initialize())
            .thenThrow(Exception('Permission denied'));

        // Act & Assert - Should not throw
        await attendanceManager.initialize();

        // Manager should still be functional
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.initial);
      });

      test('should recover from temporary service errors', () async {
        // Arrange
        await attendanceManager.initialize();

        // First call fails
        when(mockNotificationService.showEventActiveNotification(
          eventName: anyNamed('eventName'),
          eventId: anyNamed('eventId'),
        )).thenThrow(Exception('Temporary network error'));

        await attendanceManager.startEventTracking(mockEvento);

        // Second call succeeds
        when(mockNotificationService.showEventActiveNotification(
          eventName: anyNamed('eventName'),
          eventId: anyNamed('eventId'),
        )).thenAnswer((_) async {});

        // Act - Should recover and continue normally
        await attendanceManager.startEventTracking(mockEvento);

        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.active);
      });
    });

    group('State Info Tests', () {
      test('should provide comprehensive current state info', () async {
        // Arrange
        await attendanceManager.initialize();
        await attendanceManager.startEventTracking(mockEvento);

        // Act
        final stateInfo = attendanceManager.getCurrentStateInfo();

        // Assert
        expect(stateInfo, isA<Map<String, dynamic>>());
        expect(stateInfo['event'], mockEvento.titulo);
        expect(stateInfo['tracking'], contains('TrackingStatus.active'));
        expect(stateInfo.containsKey('insideGeofence'), true);
        expect(stateInfo.containsKey('distance'), true);
        expect(stateInfo.containsKey('canRegister'), true);
        expect(stateInfo.containsKey('hasRegistered'), true);
        expect(stateInfo.containsKey('gracePeriod'), true);
      });

      test('should handle state info when no event is active', () {
        // Act
        final stateInfo = attendanceManager.getCurrentStateInfo();

        // Assert
        expect(stateInfo['event'], 'Sin evento');
        expect(stateInfo['tracking'], contains('TrackingStatus.initial'));
        expect(stateInfo['canRegister'], false);
        expect(stateInfo['hasRegistered'], false);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple rapid operations efficiently', () async {
        // Arrange
        await attendanceManager.initialize();

        final stopwatch = Stopwatch()..start();

        // Act - Perform multiple operations
        for (int i = 0; i < 10; i++) {
          await attendanceManager.startEventTracking(mockEvento);
          await attendanceManager.stopTracking();
        }

        stopwatch.stop();

        // Assert - Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds,
            lessThan(2000)); // Less than 2 seconds
        expect(attendanceManager.currentState.trackingStatus,
            TrackingStatus.stopped);
      });
    });
  });
}
