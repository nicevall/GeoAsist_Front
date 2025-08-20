// test/utils/widget_test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/storage_service.dart';
import 'package:geo_asist_front/services/asistencia_service.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/permission_service.dart';
import 'package:geo_asist_front/services/background_service.dart';
import 'package:geo_asist_front/utils/connectivity_manager.dart';

class WidgetTestHelpers {
  
  /// ✅ CREAR APP COMPLETA PARA WIDGET TESTS
  static Widget createTestApp({
    Widget? home,
    String? initialRoute,
    Map<String, WidgetBuilder>? routes,
    bool setupProviders = true,
  }) {
    return MaterialApp(
      title: 'Test App',
      home: setupProviders 
        ? MultiProvider(
            providers: _createTestProviders(),
            child: home ?? Container(),
          )
        : home ?? Container(),
      initialRoute: initialRoute,
      routes: routes ?? {},
      debugShowCheckedModeBanner: false,
      // ✅ CONFIGURACIÓN CRÍTICA PARA TESTS
      navigatorObservers: [],
      theme: ThemeData(
        // ✅ TEMA CONSISTENTE PARA TESTS
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
  }

  /// ✅ PROVIDERS PARA TESTS
  static List<Provider> _createTestProviders() {
    return [
      Provider<StudentAttendanceManager>(
        create: (_) => StudentAttendanceManager(),
      ),
      Provider<NotificationManager>(
        create: (_) => NotificationManager(),
      ),
      Provider<ConnectivityManager>(
        create: (_) => ConnectivityManager(),
      ),
      Provider<LocationService>(
        create: (_) => LocationService(),
      ),
      Provider<StorageService>(
        create: (_) => StorageService(),
      ),
      Provider<BackgroundService>(
        create: (_) => BackgroundService(),
      ),
      Provider<AsistenciaService>(
        create: (_) => AsistenciaService(),
      ),
      Provider<EventoService>(
        create: (_) => EventoService(),
      ),
      Provider<PermissionService>(
        create: (_) => PermissionService(),
      ),
    ];
  }

  /// ✅ HELPER PARA FORMULARIOS DE LOGIN
  static Widget createLoginFormTest({
    bool withValidation = true,
    bool prefilledData = false,
  }) {
    return createTestApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: const Key('login_form'),
            child: Column(
              children: [
                // ✅ CAMPOS ESPECÍFICOS PARA TESTS
                TextFormField(
                  key: const Key('email_field'),
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'usuario@ejemplo.com',
                  ),
                  initialValue: prefilledData ? 'test@example.com' : null,
                  validator: withValidation ? (value) {
                    if (value?.isEmpty ?? true) return 'Campo requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  } : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password_field'),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Ingrese su contraseña',
                  ),
                  initialValue: prefilledData ? 'password123' : null,
                  obscureText: true,
                  validator: withValidation ? (value) {
                    if (value?.isEmpty ?? true) return 'Campo requerido';
                    if (value!.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  } : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: () {
                    // Mock login action
                    debugPrint('Login button pressed');
                  },
                  child: const Text('Iniciar Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ HELPER PARA TESTS DE NAVEGACIÓN
  static Widget createNavigationTest({
    required List<Widget> screens,
    int initialIndex = 0,
  }) {
    return createTestApp(
      home: DefaultTabController(
        length: screens.length,
        initialIndex: initialIndex,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Navigation Test'),
            bottom: TabBar(
              tabs: screens.asMap().entries.map((entry) {
                return Tab(
                  key: Key('tab_${entry.key}'),
                  text: 'Screen ${entry.key + 1}',
                );
              }).toList(),
            ),
          ),
          body: TabBarView(children: screens),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event),
                label: 'Events',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ HELPER PARA MAPVIEWSCREEN CON PARÁMETROS SEGUROS
  static Widget createMapViewTest({
    String userName = 'Test User',
    String eventoId = 'test_event_123',
    bool isStudentMode = true,
    bool bypassSecurity = true,
  }) {
    return createTestApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Map View - $userName'),
        ),
        body: Column(
          children: [
            Text('User: $userName'),
            Text('Event: $eventoId'),
            Text('Mode: ${isStudentMode ? "Student" : "Teacher"}'),
            if (!bypassSecurity) 
              const Text('ACCESO DIRECTO NO PERMITIDO')
            else
              const Expanded(
                child: Center(
                  child: Text('Map Container'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ✅ HELPER PARA ENCONTRAR ELEMENTOS CON RETRY
  static Future<Finder> findWithRetry(
    WidgetTester tester,
    Finder finder, {
    int maxAttempts = 5,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      await tester.pumpAndSettle(delay);
      
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
      
      attempts++;
      debugPrint('🔍 Intento $attempts/$maxAttempts buscando elemento');
      
      if (attempts < maxAttempts) {
        await Future.delayed(delay);
      }
    }
    
    throw TestFailure('No se encontró elemento después de $maxAttempts intentos');
  }

  /// ✅ HELPER PARA INTERACCIONES COMPLEJAS
  static Future<void> performComplexTap(
    WidgetTester tester,
    Finder finder, {
    bool useRetry = true,
  }) async {
    if (useRetry) {
      final retryFinder = await findWithRetry(tester, finder);
      await tester.tap(retryFinder);
    } else {
      await tester.tap(finder);
    }
    await tester.pumpAndSettle();
  }

  /// ✅ HELPER PARA TEXTO COMPLEJO
  static Future<void> enterTextWithDelay(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    // Ensure the field is visible and tappable
    final retryFinder = await findWithRetry(tester, finder);
    
    await tester.tap(retryFinder);
    await tester.pumpAndSettle();
    
    // Limpiar campo primero
    await tester.enterText(retryFinder, '');
    await tester.pumpAndSettle(delay);
    
    // Ingresar texto nuevo
    await tester.enterText(retryFinder, text);
    await tester.pumpAndSettle(delay);
  }

  /// ✅ HELPER PARA FORMULARIO COMPLETO
  static Future<void> fillLoginForm(
    WidgetTester tester, {
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    await enterTextWithDelay(
      tester,
      find.byKey(const Key('email_field')),
      email,
    );

    await enterTextWithDelay(
      tester,
      find.byKey(const Key('password_field')),
      password,
    );
  }

  /// ✅ HELPER PARA VALIDAR FORMULARIO
  static Future<void> submitFormAndValidate(
    WidgetTester tester, {
    bool expectErrors = false,
  }) async {
    await performComplexTap(
      tester,
      find.byKey(const Key('login_button')),
    );

    if (expectErrors) {
      // Verificar que aparecen errores de validación
      await tester.pumpAndSettle();
      expect(find.text('Campo requerido'), findsWidgets);
    } else {
      // Verificar que no hay errores
      await tester.pumpAndSettle();
      expect(find.text('Login button pressed'), findsNothing);
    }
  }

  /// ✅ HELPER PARA CREAR WIDGETS MOCK
  static Widget createMockScreen({
    String title = 'Mock Screen',
    List<Widget>? children,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: children ?? [
          Center(child: Text('$title Content')),
        ],
      ),
    );
  }

  /// ✅ HELPER PARA PRUEBAS DE RESPONSIVE DESIGN
  static Widget createResponsiveTest({
    required Widget child,
    Size? screenSize,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize ?? const Size(400, 800),
        ),
        child: child,
      ),
    );
  }

  /// ✅ HELPER PARA ENCONTRAR MÚLTIPLES ESTRATEGIAS
  static Finder findByMultipleStrategies({
    Key? key,
    String? text,
    Type? widgetType,
    String? tooltip,
  }) {
    // Try each finder strategy in order
    if (key != null) {
      final keyFinder = find.byKey(key);
      if (keyFinder.evaluate().isNotEmpty) return keyFinder;
    }
    
    if (text != null) {
      final textFinder = find.text(text);
      if (textFinder.evaluate().isNotEmpty) return textFinder;
      
      final textContainingFinder = find.textContaining(text);
      if (textContainingFinder.evaluate().isNotEmpty) return textContainingFinder;
    }
    
    if (widgetType != null) {
      final typeFinder = find.byType(widgetType);
      if (typeFinder.evaluate().isNotEmpty) return typeFinder;
    }
    
    if (tooltip != null) {
      final tooltipFinder = find.byTooltip(tooltip);
      if (tooltipFinder.evaluate().isNotEmpty) return tooltipFinder;
    }
    
    // Return the first finder as fallback
    if (key != null) return find.byKey(key);
    if (text != null) return find.text(text);
    if (widgetType != null) return find.byType(widgetType);
    if (tooltip != null) return find.byTooltip(tooltip);
    
    throw ArgumentError('At least one search parameter must be provided');
  }
}