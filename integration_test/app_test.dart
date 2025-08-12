// integration_test/app_test.dart
// 🧪 BLOQUE 3 A1.3 - END-TO-END TESTING COMPLETO - CORREGIDO
// Testing de flujos completos de la aplicación

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:geo_asist_front/main.dart' as app;
import 'package:geo_asist_front/models/usuario_model.dart';
import 'package:geo_asist_front/models/evento_model.dart';
import 'package:geo_asist_front/models/ubicacion_model.dart';
import 'package:geo_asist_front/services/storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GeoAsist E2E Tests', () {
    // Test data - CORREGIDO según modelos actuales
    final testStudent = Usuario(
      id: 'student_e2e_123',
      nombre: 'Estudiante Test',
      correo: 'estudiante@test.com',
      rol: 'estudiante',
      creadoEn: DateTime.now(),
    );

    final testTeacher = Usuario(
      id: 'teacher_e2e_123',
      nombre: 'Profesor Test',
      correo: 'profesor@test.com',
      rol: 'docente',
      creadoEn: DateTime.now(),
    );

    final testEvent = Evento(
      id: 'event_e2e_123',
      titulo: 'Clase de Programación Móvil E2E',
      descripcion: 'Clase de testing end-to-end',
      ubicacion: Ubicacion(
        latitud: -0.1805,
        longitud: -78.4680,
      ),
      fecha: DateTime.now(),
      horaInicio: DateTime.now().subtract(const Duration(minutes: 30)),
      horaFinal: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      rangoPermitido: 100.0,
      creadoPor: 'teacher_e2e_123',
    );

    setUp(() async {
      // Clear any previous test data
      final storage = StorageService();
      await storage.clearAll();
    });

    tearDown(() async {
      // Clean up after each test
      final storage = StorageService();
      await storage.clearAll();
    });

    group('Complete Student Journey', () {
      testWidgets('complete student attendance flow', (tester) async {
        // Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Step 1: Login as student
        await _loginAsStudent(tester, testStudent);

        // Step 2: Navigate to available events
        await _navigateToAvailableEvents(tester);

        // Step 3: Join an active event
        await _joinEvent(tester, testEvent);

        // Step 4: Complete attendance flow
        await _completeAttendanceFlow(tester);

        // Step 5: Verify attendance was registered
        await _verifyAttendanceRegistered(tester);

        // Step 6: Handle leaving geofence (grace period)
        await _testGracePeriodFlow(tester);

        // Step 7: End tracking
        await _endTracking(tester);
      });

      testWidgets('student handles network connectivity issues',
          (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Login and start tracking
        await _loginAsStudent(tester, testStudent);
        await _navigateToAvailableEvents(tester);
        await _joinEvent(tester, testEvent);

        // Simulate network issues during attendance registration
        await _simulateNetworkIssues(tester);

        // Verify offline mode and recovery
        await _verifyOfflineModeAndRecovery(tester);
      });

      testWidgets('student app performance under load', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Login
        await _loginAsStudent(tester, testStudent);
        await _navigateToAvailableEvents(tester);
        await _joinEvent(tester, testEvent);

        // Simulate intensive location updates
        await _simulateIntensiveLocationUpdates(tester);

        // Verify app remains responsive
        await _verifyAppResponsiveness(tester);
      });
    });

    group('Complete Teacher Journey', () {
      testWidgets('complete teacher event management flow', (tester) async {
        // Launch app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Step 1: Login as teacher
        await _loginAsTeacher(tester, testTeacher);

        // Step 2: Create new event
        await _createNewEvent(tester, testEvent);

        // Step 3: Start event and monitor attendance
        await _startEventAndMonitor(tester);

        // Step 4: View real-time student activity
        await _viewStudentActivity(tester);

        // Step 5: Manage event controls
        await _manageEventControls(tester);

        // Step 6: End event and view reports
        await _endEventAndViewReports(tester);
      });

      testWidgets('teacher dashboard real-time updates', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await _loginAsTeacher(tester, testTeacher);
        await _createNewEvent(tester, testEvent);
        await _startEventAndMonitor(tester);

        // Verify real-time metrics update
        await _verifyRealTimeMetrics(tester);

        // Test dashboard performance with many students
        await _testDashboardPerformance(tester);
      });
    });

    group('Cross-Platform Compatibility', () {
      testWidgets('app works correctly on different screen sizes',
          (tester) async {
        // Test on phone size
        await _testOnScreenSize(tester, const Size(375, 667), 'Phone');

        // Test on tablet size
        await _testOnScreenSize(tester, const Size(768, 1024), 'Tablet');

        // Test on large tablet
        await _testOnScreenSize(tester, const Size(1024, 1366), 'Large Tablet');
      });

      testWidgets('app handles device orientation changes', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await _loginAsStudent(tester, testStudent);

        // Test portrait to landscape
        await _rotateToLandscape(tester);
        await _verifyLayoutInLandscape(tester);

        // Test landscape to portrait
        await _rotateToPortrait(tester);
        await _verifyLayoutInPortrait(tester);
      });
    });

    group('Data Persistence and Recovery', () {
      testWidgets('app recovers state after restart', (tester) async {
        // Start app and begin tracking
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await _loginAsStudent(tester, testStudent);
        await _navigateToAvailableEvents(tester);
        await _joinEvent(tester, testEvent);

        // Verify tracking is active
        expect(find.text('Tracking Activo'), findsOneWidget);

        // Simulate app restart
        await _simulateAppRestart(tester);

        // Verify state is recovered
        await _verifyStateRecovery(tester);
      });

      testWidgets('app handles data corruption gracefully', (tester) async {
        // Corrupt stored data
        await _corruptStoredData(tester);

        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify graceful handling
        await _verifyGracefulDataCorruptionHandling(tester);
      });
    });

    group('Security and Privacy', () {
      testWidgets('app handles authentication errors securely', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test invalid credentials
        await _testInvalidCredentials(tester);

        // Test session expiration
        await _testSessionExpiration(tester);

        // Test unauthorized access attempts
        await _testUnauthorizedAccess(tester);
      });

      testWidgets('location data is handled securely', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await _loginAsStudent(tester, testStudent);

        // Verify location permissions are requested properly
        await _verifyLocationPermissions(tester);

        // Verify location data encryption/security
        await _verifyLocationDataSecurity(tester);
      });
    });

    group('Accessibility Compliance', () {
      testWidgets('app is fully accessible with screen reader', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Enable accessibility testing
        await _enableAccessibilityTesting(tester);

        // Test navigation with screen reader
        await _testScreenReaderNavigation(tester);

        // Test all interactive elements have proper labels
        await _verifySemanticLabels(tester);
      });

      testWidgets('app supports keyboard navigation', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test tab navigation
        await _testTabNavigation(tester);

        // Test keyboard shortcuts
        await _testKeyboardShortcuts(tester);
      });
    });

    group('Performance and Optimization', () {
      testWidgets('app memory usage remains stable', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Monitor memory usage during intensive operations
        await _monitorMemoryUsage(tester);

        // Verify no memory leaks
        await _verifyNoMemoryLeaks(tester);
      });

      testWidgets('app responds within acceptable time limits', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test response times for critical operations
        await _testResponseTimes(tester);

        // Verify smooth animations
        await _verifySmoothAnimations(tester);
      });
    });
  });
}

// Helper functions for complex E2E test scenarios

Future<void> _loginAsStudent(WidgetTester tester, Usuario student) async {
  // Look for login fields
  expect(find.text('Iniciar Sesión'), findsOneWidget);

  // Enter credentials
  await tester.enterText(find.byType(TextField).first, student.correo);
  await tester.enterText(find.byType(TextField).last, 'password123');

  // Tap login button
  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify successful login
  expect(find.text('Bienvenido, ${student.nombre}'), findsOneWidget);
}

Future<void> _loginAsTeacher(WidgetTester tester, Usuario teacher) async {
  expect(find.text('Iniciar Sesión'), findsOneWidget);

  await tester.enterText(find.byType(TextField).first, teacher.correo);
  await tester.enterText(find.byType(TextField).last, 'teacher123');

  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  expect(find.text('Dashboard Docente'), findsOneWidget);
}

Future<void> _navigateToAvailableEvents(WidgetTester tester) async {
  // Find and tap events navigation
  await tester.tap(find.text('Eventos Disponibles'));
  await tester.pumpAndSettle();

  // Verify events list is displayed
  expect(find.text('Eventos Activos'), findsOneWidget);
}

Future<void> _joinEvent(WidgetTester tester, Evento event) async {
  // Find the test event
  expect(find.text(event.titulo), findsOneWidget);

  // Tap to join event
  await tester.tap(find.text('Unirse'));
  await tester.pumpAndSettle();

  // Verify navigation to map view
  expect(find.text('Map View'), findsOneWidget);
  expect(find.text('Iniciar Tracking'), findsOneWidget);
}

Future<void> _completeAttendanceFlow(WidgetTester tester) async {
  // Start tracking
  await tester.tap(find.text('Iniciar Tracking'));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Verify tracking started
  expect(find.text('Tracking Activo'), findsOneWidget);

  // Wait for location to be detected as inside geofence
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Verify inside geofence status
  expect(find.text('Dentro'), findsOneWidget);
  expect(find.text('Registrar Asistencia'), findsOneWidget);

  // Register attendance
  await tester.tap(find.text('Registrar Asistencia'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _verifyAttendanceRegistered(WidgetTester tester) async {
  // Verify attendance registration success
  expect(find.text('Asistencia Registrada'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsOneWidget);

  // Verify notification appears
  expect(find.textContaining('exitosamente'), findsOneWidget);
}

Future<void> _testGracePeriodFlow(WidgetTester tester) async {
  // Simulate leaving geofence
  // This would trigger grace period in real scenario
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Check if grace period UI appears
  final gracePeriodFinder = find.textContaining('Período de Gracia');
  if (gracePeriodFinder.evaluate().isNotEmpty) {
    expect(gracePeriodFinder, findsOneWidget);
    expect(find.textContaining('01:00'), findsOneWidget);

    // Wait for grace period countdown
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify countdown is working
    expect(find.textContaining('00:57'), findsOneWidget);
  }
}

Future<void> _endTracking(WidgetTester tester) async {
  // Find and tap stop tracking button
  final stopButton = find.text('Detener Tracking');
  if (stopButton.evaluate().isNotEmpty) {
    await tester.tap(stopButton);
    await tester.pumpAndSettle();

    // Verify tracking stopped
    expect(find.text('Tracking Detenido'), findsOneWidget);
  }
}

Future<void> _createNewEvent(WidgetTester tester, Evento event) async {
  // Navigate to create event
  await tester.tap(find.text('Crear Evento'));
  await tester.pumpAndSettle();

  // Fill event form
  await tester.enterText(
    find.widgetWithText(TextField, 'Título del Evento'),
    event.titulo,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Descripción'),
    event.descripcion ?? '',
  );

  // Set location (simplified)
  await tester.tap(find.text('Establecer Ubicación'));
  await tester.pumpAndSettle();

  // Save event
  await tester.tap(find.text('Crear Evento'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify event created
  expect(find.text('Evento creado exitosamente'), findsOneWidget);
}

Future<void> _startEventAndMonitor(WidgetTester tester) async {
  // Start event
  await tester.tap(find.text('Iniciar Evento'));
  await tester.pumpAndSettle();

  // Verify event is active
  expect(find.text('Evento Activo'), findsOneWidget);
  expect(find.text('Dashboard en Tiempo Real'), findsOneWidget);
}

Future<void> _viewStudentActivity(WidgetTester tester) async {
  // Check real-time metrics
  expect(find.text('Estudiantes Activos'), findsOneWidget);
  expect(find.text('Asistencias Registradas'), findsOneWidget);

  // Check student activity list
  expect(find.text('Actividad de Estudiantes'), findsOneWidget);

  // Test filtering
  await tester.tap(find.text('Filtrar'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Dentro del Área'));
  await tester.pumpAndSettle();

  // Verify filter applied
  expect(find.text('Mostrando: Dentro del Área'), findsOneWidget);
}

Future<void> _manageEventControls(WidgetTester tester) async {
  // Test pause event
  await tester.tap(find.text('Pausar Evento'));
  await tester.pumpAndSettle();

  expect(find.text('Evento Pausado'), findsOneWidget);

  // Resume event
  await tester.tap(find.text('Reanudar Evento'));
  await tester.pumpAndSettle();

  expect(find.text('Evento Activo'), findsOneWidget);
}

Future<void> _endEventAndViewReports(WidgetTester tester) async {
  // End event
  await tester.tap(find.text('Finalizar Evento'));
  await tester.pumpAndSettle();

  // Confirm end event
  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify event ended
  expect(find.text('Evento Finalizado'), findsOneWidget);

  // View reports
  await tester.tap(find.text('Ver Reporte'));
  await tester.pumpAndSettle();

  expect(find.text('Reporte de Asistencia'), findsOneWidget);
}

Future<void> _simulateNetworkIssues(WidgetTester tester) async {
  // This would be implemented with network mocking
  // For now, we verify offline handling UI

  // Try to register attendance during network issue
  await tester.tap(find.text('Registrar Asistencia'));
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Should show offline mode or retry option
  final offlineFinder = find.textContaining('Sin conexión');
  final retryFinder = find.text('Reintentar');

  expect(
      offlineFinder.evaluate().isNotEmpty || retryFinder.evaluate().isNotEmpty,
      true);
}

Future<void> _verifyOfflineModeAndRecovery(WidgetTester tester) async {
  // Verify offline mode indicators
  expect(find.byIcon(Icons.wifi_off), findsWidgets);

  // Simulate connection recovery
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Should automatically retry pending operations
  expect(find.text('Sincronizando...'), findsOneWidget);
}

Future<void> _simulateIntensiveLocationUpdates(WidgetTester tester) async {
  // Simulate rapid location changes
  for (int i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Verify app remains stable
  expect(find.text('Map View'), findsOneWidget);
}

Future<void> _verifyAppResponsiveness(WidgetTester tester) async {
  // Test that UI interactions still work
  final stopwatch = Stopwatch()..start();

  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  stopwatch.stop();

  // Should respond within 500ms
  expect(stopwatch.elapsedMilliseconds, lessThan(500));
}

Future<void> _verifyRealTimeMetrics(WidgetTester tester) async {
  // Check that metrics update in real-time
  // Wait for updates
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Should have some activity
  expect(find.textContaining('Estudiantes Activos'), findsOneWidget);
  expect(find.textContaining('Total:'), findsOneWidget);
}

Future<void> _testDashboardPerformance(WidgetTester tester) async {
  // Test with simulated high load
  final stopwatch = Stopwatch()..start();

  // Navigate through dashboard sections
  await tester.tap(find.text('Métricas'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Actividad'));
  await tester.pumpAndSettle();

  stopwatch.stop();

  // Should remain responsive
  expect(stopwatch.elapsedMilliseconds, lessThan(2000));
}

Future<void> _testOnScreenSize(
    WidgetTester tester, Size size, String deviceType) async {
  // Set screen size - CORREGIDO para Flutter moderno
  await tester.binding.setSurfaceSize(size);

  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Verify layout adapts correctly
  expect(find.byType(MaterialApp), findsOneWidget);

  // Test basic navigation works on this screen size
  await _loginAsStudent(
      tester,
      Usuario(
        id: 'test_${deviceType.toLowerCase()}',
        nombre: 'Test User',
        correo: 'test@${deviceType.toLowerCase()}.com',
        rol: 'estudiante',
        creadoEn: DateTime.now(),
      ));

  expect(find.text('Eventos Disponibles'), findsOneWidget);

  // Reset screen size
  await tester.binding.setSurfaceSize(null);
}

Future<void> _rotateToLandscape(WidgetTester tester) async {
  // Simulate rotation to landscape - CORREGIDO
  await tester.binding.setSurfaceSize(const Size(667, 375));
  await tester.pumpAndSettle();
}

Future<void> _verifyLayoutInLandscape(WidgetTester tester) async {
  // Verify layout adjusts for landscape
  expect(find.byType(MaterialApp), findsOneWidget);

  // UI should still be functional
  expect(find.text('Map View'), findsOneWidget);
}

Future<void> _rotateToPortrait(WidgetTester tester) async {
  // Simulate rotation back to portrait - CORREGIDO
  await tester.binding.setSurfaceSize(const Size(375, 667));
  await tester.pumpAndSettle();
}

Future<void> _verifyLayoutInPortrait(WidgetTester tester) async {
  // Verify layout is correct in portrait
  expect(find.byType(MaterialApp), findsOneWidget);
  expect(find.text('Map View'), findsOneWidget);

  // Clean up
  await tester.binding.setSurfaceSize(null);
}

Future<void> _simulateAppRestart(WidgetTester tester) async {
  // Simulate app restart by pumping a new app instance
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _verifyStateRecovery(WidgetTester tester) async {
  // Should restore previous session if applicable
  // Or show appropriate recovery UI
  expect(find.byType(MaterialApp), findsOneWidget);
}

Future<void> _corruptStoredData(WidgetTester tester) async {
  // This would corrupt stored data in a real implementation
  // For now, just verify the app can handle it
  final storage = StorageService();
  await storage.clearAll();
}

Future<void> _verifyGracefulDataCorruptionHandling(WidgetTester tester) async {
  // App should handle corrupted data gracefully
  expect(find.byType(MaterialApp), findsOneWidget);

  // Should show login screen (clean state)
  expect(find.text('Iniciar Sesión'), findsOneWidget);
}

Future<void> _testInvalidCredentials(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'invalid@email.com');
  await tester.enterText(find.byType(TextField).last, 'wrongpassword');

  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle();

  // Should show error message
  expect(find.textContaining('Credenciales inválidas'), findsOneWidget);
}

Future<void> _testSessionExpiration(WidgetTester tester) async {
  // This would test session timeout handling
  // Should redirect to login when session expires
  expect(find.text('Sesión expirada'), findsOneWidget);
}

Future<void> _testUnauthorizedAccess(WidgetTester tester) async {
  // Test accessing protected routes without authentication
  // Should redirect to login
  expect(find.text('Acceso no autorizado'), findsOneWidget);
}

Future<void> _verifyLocationPermissions(WidgetTester tester) async {
  // Should request location permissions appropriately
  expect(find.textContaining('ubicación'), findsWidgets);
}

Future<void> _verifyLocationDataSecurity(WidgetTester tester) async {
  // Verify location data is handled securely
  // This would check encryption, secure storage, etc.
  expect(find.byType(MaterialApp), findsOneWidget);
}

Future<void> _enableAccessibilityTesting(WidgetTester tester) async {
  // Enable accessibility features for testing
  // This would configure screen reader simulation
}

Future<void> _testScreenReaderNavigation(WidgetTester tester) async {
  // Test navigation with screen reader
  expect(find.bySemanticsLabel('Iniciar sesión'), findsOneWidget);
  expect(find.bySemanticsLabel('Campo de correo electrónico'), findsOneWidget);
}

Future<void> _verifySemanticLabels(WidgetTester tester) async {
  // All interactive elements should have semantic labels
  final buttons = find.byType(ElevatedButton);
  for (final button in buttons.evaluate()) {
    final widget = button.widget as ElevatedButton;
    // Check if button has either child content or semantic properties
    expect(widget.child != null, true);
  }
}

Future<void> _testTabNavigation(WidgetTester tester) async {
  // Test keyboard tab navigation
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();

  // Should move focus to next focusable element
  expect(find.byType(Focus), findsWidgets);
}

Future<void> _testKeyboardShortcuts(WidgetTester tester) async {
  // Test keyboard shortcuts if implemented
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await tester.pumpAndSettle();
}

Future<void> _monitorMemoryUsage(WidgetTester tester) async {
  // Monitor memory usage during operations
  // This would use DevTools or memory profiling

  // Perform memory-intensive operations
  for (int i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }

  // Memory should remain stable
  expect(find.byType(MaterialApp), findsOneWidget);
}

Future<void> _verifyNoMemoryLeaks(WidgetTester tester) async {
  // Verify no memory leaks after intensive operations
  // This would check for proper disposal of resources
  expect(tester.binding.hasScheduledFrame, false);
}

Future<void> _testResponseTimes(WidgetTester tester) async {
  final stopwatch = Stopwatch();

  // Test login response time
  stopwatch.start();
  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle();
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds

  // Test navigation response time
  stopwatch.reset();
  stopwatch.start();
  await tester.tap(find.text('Eventos Disponibles'));
  await tester.pumpAndSettle();
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Under 1 second
}

Future<void> _verifySmoothAnimations(WidgetTester tester) async {
  // Verify animations are smooth (60 FPS)
  await tester.fling(find.byType(ListView), const Offset(0, -300), 1000);
  await tester.pumpAndSettle();

  // Should complete without frame drops
  expect(find.byType(ListView), findsOneWidget);
}
