// test/integration/app_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/integration_test_helpers.dart';

void main() {
  group('App Flow Integration Tests', () {
    setUp(() async {
      await IntegrationTestHelpers.setupIntegrationTest();
    });

    tearDown(() {
      IntegrationTestHelpers.cleanupIntegrationTest();
    });

    group('✅ Basic App Flow Tests', () {
      testWidgets('should initialize app successfully', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.initializeApp(tester);

        // Assert
        expect(find.text('Integration Test App'), findsOneWidget);
      });

      testWidgets('should handle login flow correctly', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performLogin(tester);

        // Assert - Login form was displayed and interacted with
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('should navigate between screens', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performCompleteFlow(
          tester,
          screens: ['Home', 'Events', 'Profile'],
        );

        // Assert - Navigation completed successfully
        expect(find.text('Profile Screen'), findsOneWidget);
      });
    });

    group('✅ Form Integration Tests', () {
      testWidgets('should handle form submission with valid data', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performFormTest(
          tester,
          formData: {
            'email': 'valid@email.com',
            'password': 'validpassword123',
          },
        );

        // Assert - Form was filled and submitted successfully
        expect(find.text('valid@email.com'), findsOneWidget);
      });

      testWidgets('should handle form validation errors', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performFormTest(
          tester,
          formData: {
            'email': '',
            'password': '',
          },
          expectValidation: true,
        );

        // Assert - Empty form was handled appropriately
        expect(find.text(''), findsWidgets);
      });

      testWidgets('should handle invalid email format', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performFormTest(
          tester,
          formData: {
            'email': 'invalid-email',
            'password': 'password123',
          },
          expectValidation: true,
        );

        // Assert - Invalid email was handled
        expect(find.text('invalid-email'), findsOneWidget);
      });
    });

    group('✅ Map View Integration Tests', () {
      testWidgets('should display map view for student mode', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performMapViewTest(
          tester,
          userName: 'Student Integration Test',
          eventoId: 'integration_evento_456',
          isStudentMode: true,
        );

        // Assert
        expect(find.textContaining('Student Integration Test'), findsOneWidget);
        expect(find.textContaining('integration_evento_456'), findsOneWidget);
        expect(find.text('Mode: Student'), findsOneWidget);
      });

      testWidgets('should display map view for teacher mode', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performMapViewTest(
          tester,
          userName: 'Teacher Integration Test',
          eventoId: 'integration_evento_789',
          isStudentMode: false,
        );

        // Assert
        expect(find.textContaining('Teacher Integration Test'), findsOneWidget);
        expect(find.textContaining('integration_evento_789'), findsOneWidget);
        expect(find.text('Mode: Teacher'), findsOneWidget);
      });

      testWidgets('should handle map view with special characters', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performMapViewTest(
          tester,
          userName: 'María José & João',
          eventoId: 'evento-2024_matemática@grupo1',
          isStudentMode: true,
        );

        // Assert
        expect(find.textContaining('María José & João'), findsOneWidget);
        expect(find.textContaining('evento-2024_matemática@grupo1'), findsOneWidget);
      });
    });

    group('✅ Error Handling Integration Tests', () {
      testWidgets('should handle error scenarios gracefully', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performErrorScenarioTest(
          tester,
          errorMessage: 'Network Connection Failed',
          shouldRecover: true,
        );

        // Assert
        expect(find.text('Error Scenario Test'), findsOneWidget);
        expect(find.text('Network Connection Failed'), findsOneWidget);
        expect(find.text('Recover'), findsOneWidget);
      });

      testWidgets('should handle non-recoverable errors', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performErrorScenarioTest(
          tester,
          errorMessage: 'Critical System Error',
          shouldRecover: false,
        );

        // Assert
        expect(find.text('Error Scenario Test'), findsOneWidget);
        expect(find.text('Critical System Error'), findsOneWidget);
        expect(find.text('Recover'), findsNothing);
      });
    });

    group('✅ Performance Integration Tests', () {
      testWidgets('should meet performance requirements', (tester) async {
        // Arrange & Act - Test that rendering is fast enough
        await IntegrationTestHelpers.performPerformanceTest(
          tester,
          iterations: 5,
          maxRenderTime: const Duration(milliseconds: 200),
        );

        // Assert - Test completed without exceeding time limits
        // Performance assertions are handled within the helper
      });

      testWidgets('should handle repeated widget creation/destruction', (tester) async {
        // Arrange & Act
        await IntegrationTestHelpers.performMemoryTest(
          tester,
          cycles: 3,
        );

        // Assert - Memory test completed without crashes
        // This test verifies that widgets can be created and destroyed repeatedly
      });
    });

    group('✅ Complex Flow Integration Tests', () {
      testWidgets('should handle complete user journey', (tester) async {
        // Arrange - Complete user flow
        
        // Act - Initialize app
        await IntegrationTestHelpers.initializeApp(tester);
        
        // Act - Login
        await IntegrationTestHelpers.performLogin(
          tester,
          email: 'integration@test.com',
          password: 'integration123',
        );
        
        // Act - Navigate to different screens
        await IntegrationTestHelpers.performCompleteFlow(
          tester,
          screens: ['Dashboard', 'Events', 'Map', 'Profile'],
        );
        
        // Act - Test map view
        await IntegrationTestHelpers.performMapViewTest(
          tester,
          userName: 'Integration Journey User',
          eventoId: 'journey_event_2024',
        );

        // Assert - Complete journey was successful
        expect(find.textContaining('Integration Journey User'), findsOneWidget);
      });

      testWidgets('should handle multiple form submissions', (tester) async {
        // Test multiple form interactions
        final formDataSets = [
          {'email': 'user1@test.com', 'password': 'password1'},
          {'email': 'user2@test.com', 'password': 'password2'},
          {'email': 'user3@test.com', 'password': 'password3'},
        ];

        for (final formData in formDataSets) {
          await IntegrationTestHelpers.performFormTest(
            tester,
            formData: formData,
          );
          
          // Verify each form submission
          expect(find.text(formData['email']!), findsOneWidget);
        }
      });
    });

    group('✅ Edge Case Integration Tests', () {
      testWidgets('should handle empty or null data gracefully', (tester) async {
        // Test with empty strings
        await IntegrationTestHelpers.performMapViewTest(
          tester,
          userName: '',
          eventoId: '',
          isStudentMode: true,
        );

        // Assert - Empty data handled gracefully
        expect(find.text('User: '), findsOneWidget);
        expect(find.text('Event: '), findsOneWidget);
      });

      testWidgets('should handle very long text inputs', (tester) async {
        const longText = 'Este es un texto extremadamente largo que debería ser manejado correctamente por la aplicación sin causar problemas de rendimiento o visualización';
        
        await IntegrationTestHelpers.performMapViewTest(
          tester,
          userName: longText,
          eventoId: longText,
        );

        // Assert - Long text handled without crashes
        expect(find.textContaining(longText), findsWidgets);
      });

      testWidgets('should handle rapid user interactions', (tester) async {
        // Test rapid tapping and interactions
        await IntegrationTestHelpers.performCompleteFlow(
          tester,
          screens: ['Screen1', 'Screen2', 'Screen3'],
        );

        // Perform rapid navigation
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byKey(Key('tab_$i')));
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Assert - Rapid interactions handled gracefully
        expect(find.text('Screen3 Screen'), findsOneWidget);
      });
    });
  });
}