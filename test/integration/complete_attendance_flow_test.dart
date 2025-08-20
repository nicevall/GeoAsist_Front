// test/integration/complete_attendance_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:geo_asist_front/main.dart' as app;
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/asistencia_service.dart';
import 'package:geo_asist_front/services/permission_service.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import '../utils/test_helpers.dart';

// Mock services for integration testing
class MockLocationService extends Mock implements LocationService {}
class MockAsistenciaService extends Mock implements AsistenciaService {}
class MockPermissionService extends Mock implements PermissionService {}
class MockNotificationManager extends Mock implements NotificationManager {}

void main() {
  // NOTA: No usar IntegrationTestWidgetsFlutterBinding.ensureInitialized() aquí 
  // porque ya está inicializado en flutter_test_config.dart

  group('Complete Attendance Flow Integration Tests', () {
    late MockLocationService mockLocationService;
    late MockAsistenciaService mockAsistenciaService;
    late MockPermissionService mockPermissionService;
    late MockNotificationManager mockNotificationManager;

    setUp(() {
      mockLocationService = MockLocationService();
      mockAsistenciaService = MockAsistenciaService();
      mockPermissionService = MockPermissionService();
      mockNotificationManager = MockNotificationManager();

      // Register fallback values
      registerFallbackValue(TestHelpers.createMockUser());
      registerFallbackValue(TestHelpers.createMockEvento());
      registerFallbackValue(TestHelpers.createSuccessResponse());
    });

    tearDown(() {
      TestHelpers.resetMockServices();
    });

    group('End-to-End Attendance Scenarios', () {
      testWidgets('Complete successful attendance registration flow', (tester) async {
        // This test simulates a complete student attendance flow
        
        // Arrange - Setup mocks for successful flow
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        when(() => mockAsistenciaService.registrarAsistencia(
          eventoId: any(named: 'eventoId'),
          usuarioId: any(named: 'usuarioId'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          estado: any(named: 'estado'),
        )).thenAnswer((_) async => TestHelpers.createSuccessResponse());

        when(() => mockNotificationManager.initialize())
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showEventStartedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showTrackingActiveNotification())
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showAttendanceRegisteredNotification())
            .thenAnswer((_) async {});

        // Act - Start the app
        app.main();
        await tester.pumpAndSettle();

        // Step 1: Login
        await _performLogin(tester);

        // Step 2: Navigate to event
        await _navigateToEvent(tester);

        // Step 3: Start attendance tracking
        await _startAttendanceTracking(tester);

        // Step 4: Verify user is inside geofence
        await _verifyInsideGeofence(tester);

        // Step 5: Register attendance
        await _registerAttendance(tester);

        // Step 6: Verify successful registration
        await _verifyAttendanceRegistered(tester);

        // Assert - Verify complete flow
        expect(find.text('Asistencia registrada'), findsOneWidget);
        verify(() => mockAsistenciaService.registrarAsistencia(
          eventoId: any(named: 'eventoId'),
          usuarioId: any(named: 'usuarioId'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          estado: 'presente',
        )).called(1);
      });

      testWidgets('Geofence violation and grace period recovery flow', (tester) async {
        // Test scenario where student leaves geofence and returns within grace period
        
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        
        // Initially inside geofence
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        when(() => mockNotificationManager.initialize()).thenAnswer((_) async {});
        when(() => mockNotificationManager.showEventStartedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showTrackingActiveNotification())
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showGeofenceExitedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showGracePeriodStartedNotification(
          remainingSeconds: any(named: 'remainingSeconds'),
        )).thenAnswer((_) async {});
        when(() => mockNotificationManager.showGeofenceEnteredNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.clearAllNotifications())
            .thenAnswer((_) async {});

        // Act
        app.main();
        await tester.pumpAndSettle();

        await _performLogin(tester);
        await _navigateToEvent(tester);
        await _startAttendanceTracking(tester);

        // Step 1: Verify inside geofence initially
        expect(find.text('Dentro del área'), findsOneWidget);

        // Step 2: Simulate leaving geofence
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: false,
          eventActive: true,
          eventStarted: true,
        ));

        await tester.pump(Duration(seconds: 35)); // Trigger location update
        await tester.pumpAndSettle();

        // Step 3: Verify grace period started
        expect(find.text('Período de gracia'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);

        // Step 4: Simulate returning to geofence within grace period
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        await tester.pump(Duration(seconds: 35)); // Trigger location update
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Dentro del área'), findsOneWidget);
        expect(find.text('Período de gracia'), findsNothing);
        verify(() => mockNotificationManager.clearAllNotifications()).called(greaterThan(0));
      });

      testWidgets('Permission denied and recovery flow', (tester) async {
        // Test scenario where permissions are denied initially then granted
        
        // Arrange - Initially deny permissions
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => false);
        
        when(() => mockNotificationManager.initialize()).thenAnswer((_) async {});
        when(() => mockNotificationManager.showCriticalAppLifecycleWarning())
            .thenAnswer((_) async {});

        // Act
        app.main();
        await tester.pumpAndSettle();

        await _performLogin(tester);

        // Try to start tracking with denied permissions
        await tester.tap(find.text('Iniciar Tracking'));
        await tester.pumpAndSettle();

        // Assert permission error shown
        expect(find.text('Permisos requeridos'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);

        // Simulate granting permissions
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        // Retry tracking
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        // Assert successful tracking start
        expect(find.text('Tracking activo'), findsOneWidget);
      });
    });

    group('Background App Lifecycle Tests', () {
      testWidgets('App backgrounding and foregrounding flow', (tester) async {
        // Test app lifecycle during attendance tracking
        
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        when(() => mockNotificationManager.initialize()).thenAnswer((_) async {});
        when(() => mockNotificationManager.showEventStartedNotification(any()))
            .thenAnswer((_) async {});
        when(() => mockNotificationManager.showBackgroundTrackingNotification())
            .thenAnswer((_) async {});

        // Act
        app.main();
        await tester.pumpAndSettle();

        await _performLogin(tester);
        await _navigateToEvent(tester);
        await _startAttendanceTracking(tester);

        // Simulate app going to background
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/lifecycle',
          (data) async => null,
        );

        // Trigger lifecycle change to paused
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();

        // Verify background tracking notification
        verify(() => mockNotificationManager.showBackgroundTrackingNotification())
            .called(greaterThan(0));

        // Simulate app coming back to foreground
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Assert tracking continues normally
        expect(find.text('Tracking activo'), findsOneWidget);
      });
    });

    group('Network Connectivity Tests', () {
      testWidgets('Offline and online recovery flow', (tester) async {
        // Test offline functionality and sync when back online
        
        // Arrange - Start with online connectivity
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        when(() => mockNotificationManager.initialize()).thenAnswer((_) async {});

        // Act
        app.main();
        await tester.pumpAndSettle();

        await _performLogin(tester);
        await _navigateToEvent(tester);
        await _startAttendanceTracking(tester);

        // Simulate network loss
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenThrow(Exception('Network error'));

        await tester.pump(Duration(seconds: 35)); // Wait for update attempt
        await tester.pumpAndSettle();

        // Verify offline handling (location updates should be queued)
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);

        // Simulate network recovery
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        await tester.pump(Duration(seconds: 35)); // Wait for update attempt
        await tester.pumpAndSettle();

        // Assert successful recovery
        expect(find.byIcon(Icons.cloud_off), findsNothing);
        expect(find.text('Conectado'), findsOneWidget);
      });
    });

    group('Error Handling and Recovery Tests', () {
      testWidgets('GPS unavailable and recovery flow', (tester) async {
        // Test GPS disabled scenario and recovery
        
        // Arrange - GPS initially unavailable
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        when(() => mockLocationService.getCurrentPosition())
            .thenThrow(Exception('Location services disabled'));

        when(() => mockNotificationManager.initialize()).thenAnswer((_) async {});

        // Act
        app.main();
        await tester.pumpAndSettle();

        await _performLogin(tester);
        await _navigateToEvent(tester);

        // Try to start tracking
        await tester.tap(find.text('Iniciar Tracking'));
        await tester.pumpAndSettle();

        // Assert GPS error shown
        expect(find.text('GPS no disponible'), findsOneWidget);
        expect(find.byIcon(Icons.location_off), findsOneWidget);

        // Simulate GPS becoming available
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        // Retry tracking
        await tester.tap(find.text('Reintentar GPS'));
        await tester.pumpAndSettle();

        // Assert successful recovery
        expect(find.text('Tracking activo'), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });
    });

    group('Performance and Memory Tests', () {
      testWidgets('Long running attendance session test', (tester) async {
        // Test app stability during extended attendance tracking
        
        // Arrange
        when(() => mockPermissionService.validateAllPermissionsForTracking())
            .thenAnswer((_) async => true);
        when(() => mockLocationService.getCurrentPosition())
            .thenAnswer((_) async => TestHelpers.createPositionInsideGeofence());
        when(() => mockLocationService.updateUserLocationComplete(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          eventoId: any(named: 'eventoId'),
        )).thenAnswer((_) async => TestHelpers.createMockLocationResponse(
          insideGeofence: true,
          eventActive: true,
          eventStarted: true,
        ));

        when(() => mockNotificationManager.initialize()).thenAnswer((_) async {});
        when(() => mockNotificationManager.showEventStartedNotification(any()))
            .thenAnswer((_) async {});

        // Act
        app.main();
        await tester.pumpAndSettle();

        await _performLogin(tester);
        await _navigateToEvent(tester);
        await _startAttendanceTracking(tester);

        // Simulate extended tracking period
        for (int i = 0; i < 120; i++) { // 2 hours of updates every 30 seconds
          await tester.pump(Duration(seconds: 30));
          
          // Verify app remains stable
          expect(find.text('Tracking activo'), findsOneWidget);
          
          // Simulate some location variations
          if (i % 10 == 0) {
            await tester.pumpAndSettle();
          }
        }

        // Assert no memory leaks or crashes
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
  });
}

// Helper methods for integration tests
Future<void> _performLogin(WidgetTester tester) async {
  // Find and fill login form
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();
}

Future<void> _navigateToEvent(WidgetTester tester) async {
  // Navigate to event screen
  await tester.tap(find.text('Eventos Disponibles'));
  await tester.pumpAndSettle();
  
  // Select first available event
  await tester.tap(find.byKey(Key('event_card_0')));
  await tester.pumpAndSettle();
}

Future<void> _startAttendanceTracking(WidgetTester tester) async {
  // Start attendance tracking
  await tester.tap(find.text('Iniciar Tracking'));
  await tester.pumpAndSettle();
}

Future<void> _verifyInsideGeofence(WidgetTester tester) async {
  // Wait for location update and verify inside geofence
  await tester.pump(Duration(seconds: 35));
  await tester.pumpAndSettle();
  
  expect(find.text('Dentro del área'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
}

Future<void> _registerAttendance(WidgetTester tester) async {
  // Register attendance
  await tester.tap(find.byKey(Key('check_in_button')));
  await tester.pumpAndSettle();
}

Future<void> _verifyAttendanceRegistered(WidgetTester tester) async {
  // Verify attendance was registered successfully
  expect(find.text('Asistencia registrada'), findsOneWidget);
  expect(find.byIcon(Icons.check), findsOneWidget);
}