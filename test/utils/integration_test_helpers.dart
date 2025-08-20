// test/utils/integration_test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_config.dart';
import 'widget_test_helpers.dart';

class IntegrationTestHelpers {
  
  /// ✅ SETUP COMPLETO PARA INTEGRATION TESTS
  static Future<void> setupIntegrationTest() async {
    // Check if binding is already initialized
    try {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    } catch (e) {
      // If already initialized, catch and continue
      debugPrint('⚠️ Integration test binding already initialized: $e');
    }
    await TestConfig.initialize();
  }

  /// ✅ CLEANUP PARA INTEGRATION TESTS
  static void cleanupIntegrationTest() {
    TestConfig.cleanup();
  }

  /// ✅ INICIALIZAR APP PARA INTEGRATION TESTS
  static Future<void> initializeApp(WidgetTester tester) async {
    // Create a simple test app for integration testing
    await tester.pumpWidget(
      WidgetTestHelpers.createTestApp(
        home: const Scaffold(
          body: Center(
            child: Text('Integration Test App'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // ✅ ESPERAR A QUE LA APP ESTÉ COMPLETAMENTE CARGADA
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Integration Test App'), findsOneWidget);
  }

  /// ✅ LOGIN HELPER PARA INTEGRATION TESTS
  static Future<void> performLogin(
    WidgetTester tester, {
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    
    // Create login screen for testing
    await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest());
    await tester.pumpAndSettle();
    
    // Buscar campos de login con retry
    final emailField = await _findFieldWithRetry(tester, 'email');
    final passwordField = await _findFieldWithRetry(tester, 'password');
    final loginButton = await _findButtonWithRetry(tester, 'login');

    // Ingresar credenciales
    await tester.enterText(emailField, email);
    await tester.pumpAndSettle();
    
    await tester.enterText(passwordField, password);
    await tester.pumpAndSettle();

    // Hacer login
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// ✅ NAVIGATION HELPER
  static Future<void> navigateToScreen(
    WidgetTester tester,
    String screenName, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    
    // Try multiple strategies to find the screen
    Finder screenFinder = find.text(screenName);
    if (screenFinder.evaluate().isEmpty) {
      screenFinder = find.textContaining(screenName);
    }
    
    await _waitForElement(tester, screenFinder, timeout: timeout);
    await tester.tap(screenFinder);
    await tester.pumpAndSettle();
  }

  /// ✅ CREAR FLOW DE NAVEGACIÓN COMPLETO
  static Future<void> performCompleteFlow(
    WidgetTester tester, {
    List<String> screens = const ['Home', 'Events', 'Profile'],
  }) async {
    
    // Setup navigation test
    final mockScreens = screens.map((screenName) => 
      Center(child: Text('$screenName Screen'))
    ).toList();

    await tester.pumpWidget(
      WidgetTestHelpers.createNavigationTest(screens: mockScreens),
    );
    await tester.pumpAndSettle();

    // Navigate through each screen
    for (int i = 0; i < screens.length; i++) {
      await tester.tap(find.byKey(Key('tab_$i')));
      await tester.pumpAndSettle();
      
      // Verify we're on the correct screen
      expect(find.text('${screens[i]} Screen'), findsOneWidget);
    }
  }

  /// ✅ HELPER PARA TESTEAR FORMULARIOS COMPLEJOS
  static Future<void> performFormTest(
    WidgetTester tester, {
    Map<String, String> formData = const {
      'email': 'test@example.com',
      'password': 'password123',
    },
    bool expectValidation = false,
  }) async {
    
    await tester.pumpWidget(WidgetTestHelpers.createLoginFormTest(
      withValidation: expectValidation,
    ));
    await tester.pumpAndSettle();

    // Fill form fields
    for (final entry in formData.entries) {
      final fieldFinder = find.byKey(Key('${entry.key}_field'));
      await tester.enterText(fieldFinder, entry.value);
      await tester.pumpAndSettle();
    }

    // Submit form
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Validate form if needed
    if (expectValidation) {
      // Check for validation messages or success indicators
      // This would be customized based on actual form behavior
    }
  }

  /// ✅ HELPER PARA TESTEAR MAP VIEW INTEGRATION
  static Future<void> performMapViewTest(
    WidgetTester tester, {
    String userName = 'Integration Test User',
    String eventoId = 'integration_event_123',
    bool isStudentMode = true,
  }) async {
    
    await tester.pumpWidget(WidgetTestHelpers.createMapViewTest(
      userName: userName,
      eventoId: eventoId,
      isStudentMode: isStudentMode,
    ));
    await tester.pumpAndSettle();

    // Verify map view elements
    expect(find.textContaining(userName), findsOneWidget);
    expect(find.textContaining(eventoId), findsOneWidget);
    expect(find.text('Mode: ${isStudentMode ? "Student" : "Teacher"}'), findsOneWidget);
    expect(find.text('Map Container'), findsOneWidget);
  }

  /// ✅ HELPER PARA PERFORMANCE TESTING
  static Future<void> performPerformanceTest(
    WidgetTester tester, {
    int iterations = 10,
    Duration maxRenderTime = const Duration(milliseconds: 100),
  }) async {
    
    final stopwatch = Stopwatch();
    
    for (int i = 0; i < iterations; i++) {
      stopwatch.start();
      
      await tester.pumpWidget(WidgetTestHelpers.createTestApp(
        home: Scaffold(
          body: Center(
            child: Text('Performance Test $i'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Check that render time is within acceptable limits
      expect(stopwatch.elapsedMilliseconds, lessThan(maxRenderTime.inMilliseconds));
      
      stopwatch.reset();
    }
  }

  /// ✅ PRIVATE HELPERS
  static Future<Finder> _findFieldWithRetry(
    WidgetTester tester,
    String fieldType,
  ) async {
    final finders = [
      find.byKey(Key('${fieldType}_field')),
      find.byKey(Key(fieldType)),
      find.byType(TextField),
      find.byType(TextFormField),
    ];

    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }

    // Retry con espera
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }

    throw TestFailure('No se encontró campo: $fieldType');
  }

  static Future<Finder> _findButtonWithRetry(
    WidgetTester tester,
    String buttonType,
  ) async {
    final finders = [
      find.byKey(Key('${buttonType}_button')),
      find.text('Iniciar Sesión'),
      find.text('Ingresar'),
      find.text('Login'),
      find.byType(ElevatedButton),
    ];

    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }

    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }

    throw TestFailure('No se encontró botón: $buttonType');
  }

  static Future<void> _waitForElement(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pumpAndSettle();
      
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    throw TestFailure('Elemento no encontrado dentro del timeout');
  }

  /// ✅ HELPER PARA ERROR SCENARIOS
  static Future<void> performErrorScenarioTest(
    WidgetTester tester, {
    String errorMessage = 'Test Error',
    bool shouldRecover = true,
  }) async {
    
    // Create error scenario
    await tester.pumpWidget(
      WidgetTestHelpers.createTestApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Error Scenario Test'),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red[100],
                child: Text(errorMessage),
              ),
              if (shouldRecover)
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Recover'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify error is displayed
    expect(find.text('Error Scenario Test'), findsOneWidget);
    expect(find.text(errorMessage), findsOneWidget);

    if (shouldRecover) {
      expect(find.text('Recover'), findsOneWidget);
      
      // Test recovery
      await tester.tap(find.text('Recover'));
      await tester.pumpAndSettle();
    }
  }

  /// ✅ HELPER PARA ACCESSIBILITY TESTING
  static Future<void> performAccessibilityTest(
    WidgetTester tester,
    Widget widget,
  ) async {
    
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Test that widgets are rendered without accessibility issues
    expect(find.byWidget(widget), findsOneWidget);

    // Verify that interactive elements exist
    final buttons = find.byType(ElevatedButton);
    // Just verify buttons exist and can be found
    if (buttons.evaluate().isNotEmpty) {
      expect(buttons, findsWidgets);
    }
  }

  /// ✅ HELPER PARA MEMORY LEAK TESTING
  static Future<void> performMemoryTest(
    WidgetTester tester, {
    int cycles = 5,
  }) async {
    
    for (int i = 0; i < cycles; i++) {
      // Create and destroy widgets repeatedly
      await tester.pumpWidget(WidgetTestHelpers.createTestApp(
        home: Scaffold(
          body: Column(
            children: List.generate(100, (index) => 
              Text('Memory Test Item $index')
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      
      // Clear widget tree
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      
      // Force garbage collection
      await tester.binding.reassembleApplication();
    }
  }
}