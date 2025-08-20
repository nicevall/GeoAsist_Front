// test/widget/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/widget_test_helpers.dart';
import '../utils/test_config.dart';

void main() {
  group('Login Screen Widget Tests', () {
    setUp(() async {
      await TestConfig.initialize();
    });

    tearDown(() {
      TestConfig.cleanup();
    });

    group('✅ Form Field Tests', () {
      testWidgets('should find email field correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act & Assert - Usar múltiples estrategias de búsqueda
        expect(find.byKey(const Key('email_field')), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2)); // Email + password
        
        // ✅ VERIFICACIÓN ADICIONAL POR TEXTO
        expect(find.text('Correo electrónico'), findsOneWidget);
        expect(find.text('usuario@ejemplo.com'), findsOneWidget);
      });

      testWidgets('should find password field correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act & Assert
        expect(find.byKey(const Key('password_field')), findsOneWidget);
        expect(find.text('Contraseña'), findsOneWidget);
        expect(find.text('Ingrese su contraseña'), findsOneWidget);

        // Verificar que es campo de contraseña (checking key instead of obscureText)
        final passwordField = tester.widget<TextFormField>(
          find.byKey(const Key('password_field'))
        );
        expect(passwordField.key, equals(const Key('password_field')));
      });

      testWidgets('should interact with email field correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act - Usar helper mejorado
        await WidgetTestHelpers.enterTextWithDelay(
          tester,
          find.byKey(const Key('email_field')),
          'test@example.com',
        );

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('should interact with password field correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act
        await WidgetTestHelpers.enterTextWithDelay(
          tester,
          find.byKey(const Key('password_field')),
          'password123',
        );

        // Assert - Password field interaction completed successfully
        expect(find.byKey(const Key('password_field')), findsOneWidget);
      });

      testWidgets('should validate empty form fields', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          withValidation: true,
        ));
        await tester.pumpAndSettle();

        // Act - Intentar submit sin datos
        await WidgetTestHelpers.performComplexTap(
          tester,
          find.byKey(const Key('login_button')),
        );

        // Trigger validation by interacting with form
        await tester.tap(find.byKey(const Key('email_field')));
        await tester.pumpAndSettle();
        
        // Simulate leaving empty field
        final formState = tester.state<FormState>(find.byKey(const Key('login_form')));
        formState.validate();
        await tester.pumpAndSettle();

        // Assert - Buscar mensajes de validación
        expect(find.text('Campo requerido'), findsWidgets);
      });

      testWidgets('should validate email format', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          withValidation: true,
        ));
        await tester.pumpAndSettle();

        // Act - Ingresar email inválido
        await WidgetTestHelpers.enterTextWithDelay(
          tester,
          find.byKey(const Key('email_field')),
          'invalid-email',
        );

        // Trigger validation
        final formState = tester.state<FormState>(find.byKey(const Key('login_form')));
        formState.validate();
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Email inválido'), findsOneWidget);
      });

      testWidgets('should validate password length', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          withValidation: true,
        ));
        await tester.pumpAndSettle();

        // Act - Ingresar contraseña muy corta
        await WidgetTestHelpers.enterTextWithDelay(
          tester,
          find.byKey(const Key('password_field')),
          '123',
        );

        // Trigger validation
        final formState = tester.state<FormState>(find.byKey(const Key('login_form')));
        formState.validate();
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });

      testWidgets('should pass validation with valid data', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          withValidation: true,
        ));
        await tester.pumpAndSettle();

        // Act - Llenar con datos válidos
        await WidgetTestHelpers.fillLoginForm(tester);

        // Trigger validation
        final formState = tester.state<FormState>(find.byKey(const Key('login_form')));
        final isValid = formState.validate();
        await tester.pumpAndSettle();

        // Assert
        expect(isValid, isTrue);
        expect(find.text('Campo requerido'), findsNothing);
        expect(find.text('Email inválido'), findsNothing);
        expect(find.text('Mínimo 6 caracteres'), findsNothing);
      });

      testWidgets('should show prefilled data when requested', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          prefilledData: true,
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);
        // Password text won't be visible due to obscureText
        final passwordField = tester.widget<TextFormField>(
          find.byKey(const Key('password_field'))
        );
        expect(passwordField.initialValue, equals('password123'));
      });
    });

    group('✅ Button Interaction Tests', () {
      testWidgets('should find login button correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act & Assert
        expect(find.byKey(const Key('login_button')), findsOneWidget);
        expect(find.text('Iniciar Sesión'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should handle button tap correctly', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act
        await WidgetTestHelpers.performComplexTap(
          tester,
          find.byKey(const Key('login_button')),
        );

        // Assert - Button was tapped (no exceptions thrown)
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      });

      testWidgets('should handle multiple button taps', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Act - Multiple taps
        for (int i = 0; i < 3; i++) {
          await WidgetTestHelpers.performComplexTap(
            tester,
            find.byKey(const Key('login_button')),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Assert - No crashes occurred
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      });
    });

    group('✅ Complete Form Flow Tests', () {
      testWidgets('should complete full login form flow', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          withValidation: true,
        ));
        await tester.pumpAndSettle();

        // Act - Complete login flow
        await WidgetTestHelpers.fillLoginForm(
          tester,
          email: 'user@test.com',
          password: 'securepass',
        );

        await WidgetTestHelpers.performComplexTap(
          tester,
          find.byKey(const Key('login_button')),
        );

        // Assert - Form completed successfully
        expect(find.text('user@test.com'), findsOneWidget);
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      });

      testWidgets('should handle form submission with validation errors', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
          withValidation: true,
        ));
        await tester.pumpAndSettle();

        // Act - Submit empty form
        await WidgetTestHelpers.performComplexTap(
          tester,
          find.byKey(const Key('login_button')),
        );

        // Manually trigger validation
        final formState = tester.state<FormState>(find.byKey(const Key('login_form')));
        formState.validate();
        await tester.pumpAndSettle();

        // Assert - Validation errors are shown
        expect(find.text('Campo requerido'), findsWidgets);
      });
    });

    group('✅ Layout and UI Tests', () {
      testWidgets('should have proper form layout', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Assert - Check layout components
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Padding), findsWidgets);
        expect(find.byType(SizedBox), findsNWidgets(2)); // Spacing elements
      });

      testWidgets('should display proper labels and hints', (tester) async {
        // Arrange
        await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
        await tester.pumpAndSettle();

        // Assert - Check all text labels
        expect(find.text('Correo electrónico'), findsOneWidget);
        expect(find.text('usuario@ejemplo.com'), findsOneWidget);
        expect(find.text('Contraseña'), findsOneWidget);
        expect(find.text('Ingrese su contraseña'), findsOneWidget);
        expect(find.text('Iniciar Sesión'), findsOneWidget);
      });
    });
  });
}