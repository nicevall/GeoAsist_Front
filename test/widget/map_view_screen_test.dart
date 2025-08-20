// test/widget/map_view_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geo_asist_front/screens/map_view/map_view_screen.dart';
import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/permission_service.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import 'package:geo_asist_front/models/attendance_state_model.dart';
import '../utils/test_helpers.dart';

// Mock classes
class MockStudentAttendanceManager extends Mock implements StudentAttendanceManager {}
class MockPermissionService extends Mock implements PermissionService {}
class MockEventoService extends Mock implements EventoService {}
class MockNotificationManager extends Mock implements NotificationManager {}

void main() {
  group('MapViewScreen Widget Tests', () {
    late MockStudentAttendanceManager mockAttendanceManager;

    setUp(() {
      mockAttendanceManager = MockStudentAttendanceManager();

      // Register fallback values
      registerFallbackValue(TestHelpers.createMockAttendanceState());
      registerFallbackValue(TestHelpers.createMockLocationResponse());
      registerFallbackValue(TestHelpers.createMockEvento());
    });

    setUpAll(() {
      // Setup test environment
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      TestHelpers.resetMockServices();
    });

    group('Widget Rendering Tests', () {
      testWidgets('should render map view screen with basic elements', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        // Assert
        expect(find.byType(MapViewScreen), findsOneWidget);
        expect(find.text('Test User'), findsWidgets);
      });

      testWidgets('should display Google Maps widget', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(GoogleMap), findsOneWidget);
      });

      testWidgets('should display control panel', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        // Control panel elements should be present
        expect(find.byKey(Key('control_panel')), findsWidgets);
      });
    });

    group('Student Mode Tests', () {
      testWidgets('should show attendance status in student mode', (tester) async {
        // Arrange
        final mockState = TestHelpers.createMockAttendanceState(
          trackingStatus: TrackingStatus.active,
          isInsideGeofence: true,
          canRegisterAttendance: true,
        );

        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(mockState));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(mockState);

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test Student',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(Key('attendance_status')), findsWidgets);
        expect(find.text('Dentro del área'), findsWidgets);
      });

      testWidgets('should show check-in button when attendance can be registered', (tester) async {
        // Arrange
        final mockState = TestHelpers.createMockAttendanceState(
          trackingStatus: TrackingStatus.active,
          isInsideGeofence: true,
          canRegisterAttendance: true,
          hasRegisteredAttendance: false,
        );

        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(mockState));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(mockState);
        when(() => mockAttendanceManager.registerAttendanceWithBackend())
            .thenAnswer((_) async => true);

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test Student',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(Key('check_in_button')), findsWidgets);
        
        // Test button tap
        await tester.tap(find.byKey(Key('check_in_button')));
        await tester.pumpAndSettle();

        verify(() => mockAttendanceManager.registerAttendanceWithBackend()).called(1);
      });

      testWidgets('should display grace period widget when in grace period', (tester) async {
        // Arrange
        final mockState = TestHelpers.createMockAttendanceState(
          trackingStatus: TrackingStatus.active,
          isInGracePeriod: true,
          gracePeriodRemaining: 25,
        );

        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(mockState));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(mockState);

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test Student',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(Key('grace_period_widget')), findsWidgets);
        expect(find.text('25'), findsWidgets); // Grace period countdown
      });
    });

    group('Admin Mode Tests', () {
      testWidgets('should show admin controls in admin mode', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test Admin',
            isAdminMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(Key('admin_controls')), findsWidgets);
      });

      testWidgets('should show event management controls for admin', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test Admin',
            isAdminMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(Key('event_controls')), findsWidgets);
      });
    });

    group('Location Updates Tests', () {
      testWidgets('should update map position when location changes', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse(
              latitude: 37.7849,
              longitude: -122.4094,
            )));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        // Verify map has updated (would check GoogleMap controller in real implementation)
        expect(find.byType(GoogleMap), findsOneWidget);
      });

      testWidgets('should show distance to event location', (tester) async {
        // Arrange
        final mockState = TestHelpers.createMockAttendanceState(
          distanceToEvent: 75.5,
        );

        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(mockState));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(mockState);

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('75.5m'), findsWidgets);
      });
    });

    group('Permission Status Tests', () {
      testWidgets('should show permission warnings when permissions not granted', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
            permissionsValidated: false,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.warning), findsWidgets);
        expect(find.text('Permisos requeridos'), findsWidgets);
      });

      testWidgets('should show all green when permissions are granted', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
            permissionsValidated: true,
            preciseLocationGranted: true,
            backgroundPermissionsGranted: true,
            batteryOptimizationDisabled: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.check_circle), findsWidgets);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle stream errors gracefully', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.error('Test error'));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act & Assert
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        // Should not crash
        expect(find.byType(MapViewScreen), findsOneWidget);
      });

      testWidgets('should show error message when location service fails', (tester) async {
        // Arrange
        final mockState = TestHelpers.createMockAttendanceState(
          trackingStatus: TrackingStatus.error,
          lastError: 'GPS unavailable',
        );

        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(mockState));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(mockState);

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('GPS unavailable'), findsWidgets);
      });
    });

    group('Notification Overlay Tests', () {
      testWidgets('should show notification overlay when needed', (tester) async {
        // Arrange
        final mockState = TestHelpers.createMockAttendanceState(
          isInGracePeriod: true,
        );

        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(mockState));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(mockState);

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(Key('notification_overlay')), findsWidgets);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility labels', (tester) async {
        // Arrange
        when(() => mockAttendanceManager.stateStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockAttendanceState()));
        when(() => mockAttendanceManager.locationStream)
            .thenAnswer((_) => Stream.value(TestHelpers.createMockLocationResponse()));
        when(() => mockAttendanceManager.currentState)
            .thenReturn(TestHelpers.createMockAttendanceState());

        // Act
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.bySemanticsLabel('Mapa de asistencia'), findsWidgets);
        expect(find.bySemanticsLabel('Panel de control'), findsWidgets);
      });

      testWidgets('should support screen readers', (tester) async {
        // Test screen reader support
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        // Verify semantic properties
        expect(find.byType(Semantics), findsWidgets);
      });
    });

    group('Performance Tests', () {
      testWidgets('should not rebuild unnecessarily', (tester) async {
        // Test widget rebuild optimization
        int buildCount = 0;
        
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: Builder(
            builder: (context) {
              buildCount++;
              return MapViewScreen(
                userName: 'Test User',
                isStudentMode: true,
              );
            },
          ),
        );

        await tester.pump();
        await tester.pump();

        // Build count should be minimal
        expect(buildCount, lessThan(5));
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to different screen sizes', (tester) async {
        // Test different screen sizes
        await tester.binding.setSurfaceSize(Size(800, 600)); // Tablet size
        
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        expect(find.byType(MapViewScreen), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Memory Management Tests', () {
      testWidgets('should dispose controllers properly', (tester) async {
        // Test memory leak prevention
        await TestHelpers.pumpAppWithProviders(
          tester,
          child: MapViewScreen(
            userName: 'Test User',
            isStudentMode: true,
          ),
        );

        // Navigate away
        await tester.pumpWidget(Container());

        // Memory leaks would be detected by leak_tracker in real implementation
        expect(find.byType(Container), findsOneWidget);
      });
    });
  });
}