// test/widget/map_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/widget_test_helpers.dart';
import '../utils/test_config.dart';

void main() {
  group('Map View Widget Tests', () {
    setUp(() async {
      await TestConfig.initialize();
    });

    tearDown(() {
      TestConfig.cleanup();
    });

    group('✅ Basic Rendering Tests', () {
      testWidgets('should render map view without crashes', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest());
        await tester.pumpAndSettle();

        // Assert - Check basic components
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        
        // ✅ VERIFICAR QUE NO HAY REDIRECCIONES DE SEGURIDAD
        expect(find.textContaining('ACCESO DIRECTO NO PERMITIDO'), findsNothing);
        expect(find.text('Map Container'), findsOneWidget);
      });

      testWidgets('should display user name correctly', (tester) async {
        // Arrange
        const testUserName = 'Juan Test User';
        
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          userName: testUserName,
        ));
        await tester.pumpAndSettle();

        // Assert - Check that user name appears in multiple places
        expect(find.textContaining(testUserName), findsWidgets);
        
        // Also check in app bar
        expect(find.text('Map View - $testUserName'), findsOneWidget);
        expect(find.text('User: $testUserName'), findsOneWidget);
      });

      testWidgets('should display event ID correctly', (tester) async {
        // Arrange
        const testEventId = 'evento_especial_456';
        
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          eventoId: testEventId,
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Event: $testEventId'), findsOneWidget);
      });

      testWidgets('should handle student mode correctly', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          isStudentMode: true,
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Mode: Student'), findsOneWidget);
      });

      testWidgets('should handle teacher mode correctly', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          isStudentMode: false,
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Mode: Teacher'), findsOneWidget);
      });
    });

    group('✅ Security and Permission Tests', () {
      testWidgets('should bypass security when testMode enabled', (tester) async {
        // Arrange - Security bypassed (default)
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          bypassSecurity: true,
        ));
        await tester.pumpAndSettle();

        // Assert - No security redirections
        expect(find.textContaining('ACCESO DIRECTO NO PERMITIDO'), findsNothing);
        expect(find.text('Map Container'), findsOneWidget);
      });

      testWidgets('should show security warning when security enabled', (tester) async {
        // Arrange - Security enabled
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          bypassSecurity: false,
        ));
        await tester.pumpAndSettle();

        // Assert - Security warning shown
        expect(find.text('ACCESO DIRECTO NO PERMITIDO'), findsOneWidget);
        expect(find.text('Map Container'), findsNothing);
      });
    });

    group('✅ Layout and UI Component Tests', () {
      testWidgets('should have proper layout structure', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest());
        await tester.pumpAndSettle();

        // Assert - Check layout structure
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
      });

      testWidgets('should display all required text elements', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          userName: 'Test User',
          eventoId: 'test_event_123',
          isStudentMode: true,
        ));
        await tester.pumpAndSettle();

        // Assert - Check all text elements
        expect(find.textContaining('Map View'), findsOneWidget);
        expect(find.text('User: Test User'), findsOneWidget);
        expect(find.text('Event: test_event_123'), findsOneWidget);
        expect(find.text('Mode: Student'), findsOneWidget);
        expect(find.text('Map Container'), findsOneWidget);
      });
    });

    group('✅ Interactive Elements Tests', () {
      testWidgets('should find and interact with app bar', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          userName: 'Interactive User',
        ));
        await tester.pumpAndSettle();

        // Act - Try to interact with app bar
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);

        // Tap on app bar title
        await tester.tap(find.text('Map View - Interactive User'));
        await tester.pumpAndSettle();

        // Assert - No crashes occurred
        expect(find.text('Map View - Interactive User'), findsOneWidget);
      });
    });

    group('✅ Edge Cases and Error Handling', () {
      testWidgets('should handle empty user name', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          userName: '',
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Map View - '), findsOneWidget);
        expect(find.text('User: '), findsOneWidget);
      });

      testWidgets('should handle empty event ID', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
          eventoId: '',
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Event: '), findsOneWidget);
      });
    });
  });
}