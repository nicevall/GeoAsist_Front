// test/smoke_tests.dart - Tests básicos de sanidad que DEBEN pasar siempre
// 🎯 SMOKE TESTS: Tests críticos que establecen la base funcional mínima
// Si estos fallan, indica problemas fundamentales que impiden otros tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:geo_asist_front/core/geo_assist_app.dart';
import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/storage_service.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import 'package:geo_asist_front/core/app_constants.dart';
import 'utils/test_config.dart';

void main() {
  group('🚨 SMOKE TESTS - Must Always Pass', () {
    setUp(() async {
      await TestConfig.initialize();
    });

    tearDown(() {
      TestConfig.cleanup();
    });

    group('🏗️ App Infrastructure Tests', () {
      testWidgets('app starts without crashing', (tester) async {
        // Test básico: la app debe iniciar sin crashear
        bool appStarted = false;
        
        try {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                Provider<StudentAttendanceManager>(
                  create: (_) => StudentAttendanceManager(),
                ),
                Provider<NotificationManager>(
                  create: (_) => NotificationManager(),
                ),
              ],
              child: const GeoAssistApp(),
            ),
          );
          
          await tester.pump(const Duration(milliseconds: 100));
          appStarted = true;
        } catch (e) {
          debugPrint('App start error: $e');
          appStarted = false;
        }
        
        expect(appStarted, true, reason: 'App debe iniciar sin crashear');
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('MaterialApp is properly configured', (tester) async {
        await tester.pumpWidget(
          TestConfig.wrapWithProviders(Container()),
        );
        
        await tester.pump();
        
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });

    group('🔧 Provider Infrastructure Tests', () {
      testWidgets('core providers are accessible', (tester) async {
        StudentAttendanceManager? attendanceManager;
        NotificationManager? notificationManager;
        LocationService? locationService;
        StorageService? storageService;
        
        await tester.pumpWidget(
          TestConfig.wrapWithProviders(
            Builder(
              builder: (context) {
                try {
                  attendanceManager = Provider.of<StudentAttendanceManager>(
                    context, 
                    listen: false
                  );
                  notificationManager = Provider.of<NotificationManager>(
                    context, 
                    listen: false
                  );
                  locationService = Provider.of<LocationService>(
                    context, 
                    listen: false
                  );
                  storageService = Provider.of<StorageService>(
                    context, 
                    listen: false
                  );
                } catch (e) {
                  debugPrint('Provider access error: $e');
                }
                
                return Container();
              },
            ),
          ),
        );
        
        await tester.pump();
        
        expect(attendanceManager, isNotNull, reason: 'StudentAttendanceManager debe estar disponible');
        expect(notificationManager, isNotNull, reason: 'NotificationManager debe estar disponible');
        expect(locationService, isNotNull, reason: 'LocationService debe estar disponible');
        expect(storageService, isNotNull, reason: 'StorageService debe estar disponible');
      });

      testWidgets('providers work without throwing exceptions', (tester) async {
        bool providersWorking = true;
        
        await tester.pumpWidget(
          TestConfig.wrapWithProviders(
            Builder(
              builder: (context) {
                try {
                  // Test acceso básico a métodos de providers
                  final attendanceManager = Provider.of<StudentAttendanceManager>(
                    context, 
                    listen: false
                  );
                  
                  // Verificar que el singleton funciona
                  final stateInfo = attendanceManager.getCurrentStateInfo();
                  expect(stateInfo, isA<Map<String, dynamic>>());
                  
                  // Test basic method access without complex functionality
                  
                } catch (e) {
                  debugPrint('Provider method error: $e');
                  providersWorking = false;
                }
                
                return Container();
              },
            ),
          ),
        );
        
        await tester.pump();
        
        expect(providersWorking, true, reason: 'Provider methods deben funcionar sin excepciones');
      });
    });

    group('🧭 Navigation Infrastructure Tests', () {
      testWidgets('basic navigation setup works', (tester) async {
        await tester.pumpWidget(
          TestConfig.wrapWithProviders(Container()),
        );
        
        await tester.pumpAndSettle();
        
        // Verificar que el router está configurado
        expect(AppRouter.navigatorKey, isNotNull);
        expect(AppRouter.navigatorKey.currentState, isNotNull);
      });

      testWidgets('app constants are accessible', (tester) async {
        // Test básico: constantes de rutas deben estar definidas
        expect(AppConstants.loginRoute, isNotNull);
        expect(AppConstants.loginRoute, isA<String>());
        expect(AppConstants.loginRoute.isNotEmpty, true);
      });
    });

    group('🔋 Service Singletons Tests', () {
      test('StudentAttendanceManager is singleton', () {
        final instance1 = StudentAttendanceManager();
        final instance2 = StudentAttendanceManager();
        
        expect(identical(instance1, instance2), true, 
               reason: 'StudentAttendanceManager debe ser singleton');
      });

      test('services have required methods', () {
        final attendanceManager = StudentAttendanceManager();
        
        // Test métodos básicos sin llamar funcionalidad compleja
        expect(attendanceManager.getCurrentStateInfo, isA<Function>());
        
        // Test que el método básico funciona
        final stateInfo = attendanceManager.getCurrentStateInfo();
        expect(stateInfo, isA<Map<String, dynamic>>());
      });
    });

    group('📱 Platform Integration Smoke Tests', () {
      testWidgets('app handles platform channel mocks', (tester) async {
        bool platformChannelsWorking = true;
        
        await tester.pumpWidget(
          TestConfig.wrapWithProviders(
            Builder(
              builder: (context) {
                try {
                  // Test básico de que los mocks están configurados
                  final locationService = Provider.of<LocationService>(context, listen: false);
                  expect(locationService, isNotNull);
                } catch (e) {
                  debugPrint('Platform channel error: $e');
                  platformChannelsWorking = false;
                }
                
                return Container();
              },
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        expect(platformChannelsWorking, true, 
               reason: 'Platform channels deben estar mockeados correctamente');
      });
    });
  });
}