// test/unit/student_attendance_manager_comprehensive_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';

import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/asistencia_service.dart';
import 'package:geo_asist_front/services/permission_service.dart';
import 'package:geo_asist_front/services/storage_service.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import 'package:geo_asist_front/services/teacher_notification_service.dart';
import 'package:geo_asist_front/models/attendance_state_model.dart';
import '../utils/test_helpers.dart';

// Mock classes using mocktail
class MockLocationService extends Mock implements LocationService {}
class MockAsistenciaService extends Mock implements AsistenciaService {}
class MockPermissionService extends Mock implements PermissionService {}
class MockStorageService extends Mock implements StorageService {}
class MockNotificationManager extends Mock implements NotificationManager {}
class MockTeacherNotificationService extends Mock implements TeacherNotificationService {}

void main() {
  group('StudentAttendanceManager Comprehensive Tests', () {
    late StudentAttendanceManager attendanceManager;
    late MockLocationService mockLocationService;
    late MockAsistenciaService mockAsistenciaService;
    late MockPermissionService mockPermissionService;
    late MockStorageService mockStorageService;
    late MockNotificationManager mockNotificationManager;
    late MockTeacherNotificationService mockTeacherNotificationService;

    setUp(() {
      // Initialize mocks
      mockLocationService = MockLocationService();
      mockAsistenciaService = MockAsistenciaService();
      mockPermissionService = MockPermissionService();
      mockStorageService = MockStorageService();
      mockNotificationManager = MockNotificationManager();
      mockTeacherNotificationService = MockTeacherNotificationService();

      // Get singleton instance and reset state
      attendanceManager = StudentAttendanceManager();
      
      // Register fallback values for mocktail
      registerFallbackValue(TestHelpers.createMockUser());
      registerFallbackValue(TestHelpers.createMockEvento());
      registerFallbackValue(TestHelpers.createSuccessResponse());
    });

    tearDown(() async {
      // Clean up after each test
      await attendanceManager.dispose();
      TestHelpers.resetMockServices();
    });

    group('Initialization Tests', () {
      test('should initialize successfully with valid permissions', () async {
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        when(() => mockStorageService.getUser())
            .thenAnswer((_) async => TestHelpers.createMockUser());
        when(() => mockNotificationManager.initialize())
            .thenAnswer((_) async {});

        // Act
        await attendanceManager.initialize(autoStart: false);

        // Assert
        verify(() => mockNotificationManager.initialize()).called(1);
        verify(() => mockPermissionService.validateAllPermissionsForTracking()).called(1);
        verify(() => mockStorageService.getUser()).called(1);
      });

      test('should throw exception when permissions are not granted', () async {
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => false);
        when(() => mockNotificationManager.initialize())
            .thenAnswer((_) async {});

        // Act & Assert
        expect(
          () => attendanceManager.initialize(autoStart: false),
          throwsException,
        );
      });

      test('should auto-start tracking when autoStart is true and eventId provided', () async {
        // Arrange
        final mockUser = TestHelpers.createMockUser();
        
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        when(() => mockStorageService.getUser())
            .thenAnswer((_) async => mockUser);
        when(() => mockNotificationManager.initialize())
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showEventStartedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showTrackingActiveNotification())
            .thenAnswer((_) async {});

        // Mock evento service (would need actual implementation)
        // For this test, we'll focus on the initialization logic

        // Act
        await attendanceManager.initialize(
          autoStart: true,
          eventId: 'test_event_123',
          userId: 'user_123',
        );

        // Assert
        verify(() => mockNotificationManager.initialize()).called(1);
      });
    });

    group('Event Tracking Tests', () {
      test('should start event tracking successfully', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();
        
        when(() => mockNotificationManager.showEventStartedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showTrackingActiveNotification())
            .thenAnswer((_) async {});
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createMockPosition());
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse());

        // Set current user
        attendanceManager.currentState.copyWith(currentUser: mockUser);

        // Act
        await attendanceManager.startEventTracking(mockEvent);

        // Assert
        expect(attendanceManager.currentState.trackingStatus, TrackingStatus.active);
        expect(attendanceManager.currentState.currentEvent, mockEvent);
        verify(() => mockNotificationManager.showEventStartedNotification(mockEvent.titulo)).called(1);
        verify(() => mockNotificationManager.showTrackingActiveNotification()).called(1);
      });

      test('should handle location updates and process backend response', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();
        final mockPosition = TestHelpers.createMockPosition();
        final mockLocationResponse = TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        );

        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => mockPosition);
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => mockLocationResponse);

        // Set initial state
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          trackingStatus: TrackingStatus.active,
        );

        // Act
        await attendanceManager.startEventTracking(mockEvent);

        // Assert
        verify(() => mockLocationService.getCurrentPosition()).called(greaterThan(0));
        verify(() => mockLocationService.updateUserLocationComplete(
          userId: mockUser.id,
          latitude: mockPosition.latitude,
          longitude: mockPosition.longitude,
          eventoId: mockEvent.id!,
        )).called(greaterThan(0));
      });
    });

    group('Geofence Management Tests', () {
      test('should handle geofence entry correctly', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        when(() => mockNotificationManager.showGeofenceEnteredNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockAsistenciaService.registrarEventoGeofence(
          usuarioId: any(named: 'usuarioId'),
          eventoId: any(named: 'eventoId'),
          entrando: any(named: 'entrando'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
        )).thenAnswer((_) async => TestHelpers.createSuccessResponse());

        // Set state with user outside geofence initially
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          isInsideGeofence: false,
        );

        // Act - simulate entering geofence
        await attendanceManager.startEventTracking(mockEvent);

        // Assert
        verify(() => mockNotificationManager.showGeofenceEnteredNotification(mockEvent.titulo))
            .called(greaterThan(0));
      });

      test('should handle geofence exit and start grace period', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        when(() => mockNotificationManager.showGeofenceExitedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showGracePeriodStartedNotification(
          remainingSeconds: any(named: 'remainingSeconds'),
        )).thenAnswer((_) async {});
        when(() => mockTeacherNotificationService.notifyStudentLeftArea(
          studentName: any(named: 'studentName'),
          eventTitle: any(named: 'eventTitle'),
          eventId: any(named: 'eventId'),
          timeOutside: any(named: 'timeOutside'),
        )).thenAnswer((_) async {});
        when(() => mockAsistenciaService.registrarEventoGeofence(
          usuarioId: any(named: 'usuarioId'),
          eventoId: any(named: 'eventoId'),
          entrando: any(named: 'entrando'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
        )).thenAnswer((_) async => TestHelpers.createSuccessResponse());

        // Set state with user inside geofence initially
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          isInsideGeofence: true,
        );

        // Mock location response showing user is now outside
        final mockLocationResponse = TestHelpers.createMockLocationResponse(
          insideGeofence: false,
        );

        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => mockLocationResponse);

        // Act
        await attendanceManager.startEventTracking(mockEvent);

        // The geofence exit logic would be triggered during location updates
        // This test verifies the setup is correct
        verify(() => mockNotificationManager.showGeofenceExitedNotification(mockEvent.titulo))
            .called(greaterThan(0));
      });
    });

    group('Grace Period Tests', () {
      test('should handle grace period countdown', () {
        fakeAsync((async) {
          // Arrange
          when(() => mockNotificationManager.showGracePeriodStartedNotification(
            remainingSeconds: any(named: 'remainingSeconds'),
          )).thenAnswer((_) async {});

          // Track state changes
          final List<AttendanceState> stateChanges = [];
          attendanceManager.stateStream.listen((state) {
            stateChanges.add(state);
          });

          // Act - This would normally be called internally when user exits geofence
          // For testing, we'll simulate the grace period directly
          
          // Simulate 5 seconds of grace period countdown
          async.elapse(Duration(seconds: 5));

          // Assert
          // Verify grace period logic is working
          // In a real implementation, you'd verify the countdown behavior
        });
      });

      test('should cancel grace period when user returns to geofence', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        when(() => mockNotificationManager.clearAllNotifications())
            .thenAnswer((_) async {});

        // Set state with active grace period
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          isInGracePeriod: true,
          gracePeriodRemaining: 20,
        );

        // Mock returning to geofence
        final mockLocationResponse = TestHelpers.createMockLocationResponse(
          insideGeofence: true,
        );

        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => mockLocationResponse);

        // Act
        await attendanceManager.startEventTracking(mockEvent);

        // Assert grace period cancellation logic
        verify(() => mockNotificationManager.clearAllNotifications()).called(greaterThan(0));
      });
    });

    group('Attendance Registration Tests', () {
      test('should register attendance successfully when conditions are met', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        when(() => mockAsistenciaService.registrarAsistencia(
          eventoId: any(named: 'eventoId'),
          usuarioId: any(named: 'usuarioId'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          estado: any(named: 'estado'),
        )).thenAnswer((_) async => TestHelpers.createSuccessResponse());

        when(() => mockNotificationManager.showAttendanceRegisteredNotification())
            .thenAnswer((_) async {});

        when(() => mockTeacherNotificationService.notifyStudentJoined(
          studentName: any(named: 'studentName'),
          eventTitle: any(named: 'eventTitle'),
          eventId: any(named: 'eventId'),
          currentAttendance: any(named: 'currentAttendance'),
          totalStudents: any(named: 'totalStudents'),
        )).thenAnswer((_) async {});

        // Set state where attendance can be registered
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          canRegisterAttendance: true,
          isInsideGeofence: true,
        );

        // Act
        final result = await attendanceManager.registerAttendanceWithBackend();

        // Assert
        expect(result, isTrue);
        verify(() => mockAsistenciaService.registrarAsistencia(
          eventoId: mockEvent.id!,
          usuarioId: mockUser.id,
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          estado: 'presente',
        )).called(1);
        verify(() => mockNotificationManager.showAttendanceRegisteredNotification()).called(1);
        verify(() => mockTeacherNotificationService.notifyStudentJoined(
          studentName: mockUser.nombre,
          eventTitle: mockEvent.titulo,
          eventId: mockEvent.id!,
          currentAttendance: any(named: 'currentAttendance'),
          totalStudents: any(named: 'totalStudents'),
        )).called(1);
      });

      test('should fail to register attendance when conditions not met', () async {
        // Arrange - set state where attendance cannot be registered
        attendanceManager.currentState.copyWith(
          canRegisterAttendance: false,
        );

        // Act
        final result = await attendanceManager.registerAttendanceWithBackend();

        // Assert
        expect(result, isFalse);
        verifyNever(() => mockAsistenciaService.registrarAsistencia(
          eventoId: any(named: 'eventoId'),
          usuarioId: any(named: 'usuarioId'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          estado: any(named: 'estado'),
        ));
      });
    });

    group('App Lifecycle Tests', () {
      test('should handle app resumed correctly', () {
        // Arrange
        when(() => mockNotificationManager.clearAllNotifications())
            .thenAnswer((_) async {});

        // Set grace period active
        attendanceManager.currentState.copyWith(
          isInGracePeriod: true,
          gracePeriodRemaining: 15,
        );

        // Act
        attendanceManager.handleAppLifecycleChange(AppLifecycleState.resumed);

        // Assert - grace period should be cancelled
        // In a real implementation, verify the grace period cancellation
        verify(() => mockNotificationManager.clearAllNotifications()).called(greaterThan(0));
      });

      test('should handle app paused without triggering grace period', () {
        // Arrange
        when(() => mockNotificationManager.showBackgroundTrackingNotification())
            .thenAnswer((_) async {});

        // Act
        attendanceManager.handleAppLifecycleChange(AppLifecycleState.paused);

        // Assert - should continue background tracking without penalty
        verify(() => mockNotificationManager.showBackgroundTrackingNotification())
            .called(greaterThan(0));
      });

      test('should trigger grace period when app is detached', () {
        // Arrange
        when(() => mockNotificationManager.showAppClosedWarningNotification(any()))
            .thenAnswer((_) async {});

        // Act
        attendanceManager.handleAppLifecycleChange(AppLifecycleState.detached);

        // Assert - should trigger 30-second grace period
        verify(() => mockNotificationManager.showAppClosedWarningNotification(30))
            .called(greaterThan(0));
      });
    });

    group('Heartbeat Tests', () {
      test('should send heartbeat successfully', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        when(() => mockAsistenciaService.enviarHeartbeat(
          usuarioId: any(named: 'usuarioId'),
          eventoId: any(named: 'eventoId'),
          isAppActive: any(named: 'isAppActive'),
          isInGracePeriod: any(named: 'isInGracePeriod'),
          gracePeriodRemaining: any(named: 'gracePeriodRemaining'),
        )).thenAnswer((_) async => TestHelpers.createSuccessResponse());

        // Set state for active tracking
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          trackingStatus: TrackingStatus.active,
        );

        // Act
        await attendanceManager.sendHeartbeatToBackend();

        // Assert
        verify(() => mockAsistenciaService.enviarHeartbeat(
          usuarioId: mockUser.id,
          eventoId: mockEvent.id!,
          isAppActive: any(named: 'isAppActive'),
          isInGracePeriod: any(named: 'isInGracePeriod'),
          gracePeriodRemaining: any(named: 'gracePeriodRemaining'),
        )).called(1);
      });

      test('should handle heartbeat failure', () async {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        when(() => mockAsistenciaService.enviarHeartbeat(
          usuarioId: any(named: 'usuarioId'),
          eventoId: any(named: 'eventoId'),
          isAppActive: any(named: 'isAppActive'),
          isInGracePeriod: any(named: 'isInGracePeriod'),
          gracePeriodRemaining: any(named: 'gracePeriodRemaining'),
        )).thenAnswer((_) async => TestHelpers.createErrorResponse());

        when(() => mockNotificationManager.showAppClosedWarningNotification(any()))
            .thenAnswer((_) async {});

        // Set state for active tracking
        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          trackingStatus: TrackingStatus.active,
        );

        // Act
        await attendanceManager.sendHeartbeatToBackend();

        // Assert
        verify(() => mockNotificationManager.showAppClosedWarningNotification(30))
            .called(greaterThan(0));
      });
    });

    group('Memory Management Tests', () {
      test('should dispose resources properly without memory leaks', () async {
        // Arrange
        when(() => mockNotificationManager.clearAllNotifications())
            .thenAnswer((_) async {});

        // Start some tracking to create resources
        final mockEvent = TestHelpers.createMockEvento();
        await attendanceManager.startEventTracking(mockEvent);

        // Act
        await attendanceManager.dispose();

        // Assert
        verify(() => mockNotificationManager.clearAllNotifications()).called(greaterThan(0));
        expect(attendanceManager.currentState.trackingStatus, TrackingStatus.stopped);
      });

      test('should handle stream subscriptions properly', () async {
        // Arrange
        final stateStreamSubscription = attendanceManager.stateStream.listen((_) {});
        final locationStreamSubscription = attendanceManager.locationStream.listen((_) {});

        // Act
        await attendanceManager.dispose();

        // Assert - streams should be closed
        // This would be verified in a real implementation with stream state checking
        await stateStreamSubscription.cancel();
        await locationStreamSubscription.cancel();
      });
    });

    group('Permission Validation Tests', () {
      test('should validate permissions before tracking', () async {
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);

        // Act
        final result = await attendanceManager.validatePermissionsBeforeTracking();

        // Assert
        expect(result, isTrue);
        verify(() => mockPermissionService.validateAllPermissionsForTracking()).called(1);
      });

      test('should handle permission validation failure', () async {
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => false);
        when(() => mockNotificationManager.showCriticalAppLifecycleWarning())
            .thenAnswer((_) async {});

        // Act
        final result = await attendanceManager.validatePermissionsBeforeTracking();

        // Assert
        expect(result, isFalse);
        verify(() => mockNotificationManager.showCriticalAppLifecycleWarning()).called(1);
      });
    });

    group('State Management Tests', () {
      test('should emit state changes through stream', () async {
        // Arrange
        final List<AttendanceState> emittedStates = [];
        final subscription = attendanceManager.stateStream.listen((state) {
          emittedStates.add(state);
        });

        // Act
        final mockEvent = TestHelpers.createMockEvento();
        await attendanceManager.startEventTracking(mockEvent);

        // Wait for async operations
        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(emittedStates.length, greaterThan(0));
        expect(emittedStates.any((state) => state.trackingStatus == TrackingStatus.active), isTrue);

        // Cleanup
        await subscription.cancel();
      });

      test('should provide current state info correctly', () {
        // Arrange
        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          trackingStatus: TrackingStatus.active,
          isInsideGeofence: true,
          distanceToEvent: 50.0,
        );

        // Act
        final stateInfo = attendanceManager.getCurrentStateInfo();

        // Assert
        expect(stateInfo['event'], contains('Test Event'));
        expect(stateInfo['tracking'], contains('active'));
        expect(stateInfo['insideGeofence'], isTrue);
        expect(stateInfo['distance'], contains('50.0'));
      });
    });

    group('Error Handling Tests', () {
      test('should handle location service errors gracefully', () async {
        // Arrange
        when(() => mockLocationService.getCurrentPosition())
            .thenThrow(Exception('GPS unavailable'));

        final mockEvent = TestHelpers.createMockEvento();

        // Act
        await attendanceManager.startEventTracking(mockEvent);

        // Assert - should not crash and should handle error
        expect(attendanceManager.currentState.trackingStatus, isNot(TrackingStatus.error));
      });

      test('should handle backend API errors', () async {
        // Arrange
        when(() => mockAsistenciaService.registrarAsistencia(
          eventoId: any(named: 'eventoId'),
          usuarioId: any(named: 'usuarioId'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          estado: any(named: 'estado'),
        )).thenThrow(Exception('Network error'));

        final mockEvent = TestHelpers.createMockEvento();
        final mockUser = TestHelpers.createMockUser();

        attendanceManager.currentState.copyWith(
          currentUser: mockUser,
          currentEvent: mockEvent,
          canRegisterAttendance: true,
        );

        // Act
        final result = await attendanceManager.registerAttendanceWithBackend();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}