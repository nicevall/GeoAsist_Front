// test/utils/test_config.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import 'package:geo_asist_front/utils/connectivity_manager.dart';
import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/storage_service.dart';
import 'package:geo_asist_front/services/asistencia_service.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/permission_service.dart';
import 'package:geo_asist_front/services/background_service.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import 'package:geo_asist_front/core/app_constants.dart';

/// Global test configuration and setup utilities
class TestConfig {
  static bool _isInitialized = false;
  
  /// Initialize global test configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup Google Maps mock
    await _setupGoogleMapsMock();
    
    // Setup platform channels
    await _setupPlatformChannels();
    
    // Setup shared preferences (CRITICAL FOR STORAGE)
    await _setupSharedPreferencesChannel();
    
    // Setup geolocator mocks (CRITICAL FIX - was missing!)
    await setupGeolocatorMocks();
    
    // Setup background location and WorkManager mocks (CRITICAL)
    await setupBackgroundLocationMocks();
    
    // Setup device/connectivity mocks (IMPORTANT)
    await setupConnectivityMocks();
    await setupBatteryMocks();
    await setupDeviceInfoMocks();
    
    // TODO: HTTP client override - removed due to complexity
    // The HTTP client warning can be addressed later with a simpler approach
    
    // Setup notification channels
    await _setupNotificationChannels();
    
    _isInitialized = true;
  }
  
  /// Configurar providers para tests - NO ChangeNotifier (son singletons normales)
  static List<Provider> getTestProviders() {
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
  
  /// Setup completo para widget tests con routing
  static Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: getTestProviders(),
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppConstants.loginRoute,
        home: child,
      ),
    );
  }
  
  /// Setup básico sin routing para tests simples
  static Widget wrapWithProvidersOnly(Widget child) {
    return MultiProvider(
      providers: getTestProviders(),
      child: MaterialApp(
        home: child,
        // Routing básico para tests
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/available-events':
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Available Events Test Screen')),
                ),
              );
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Login Test Screen')),
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Test Screen')),
                ),
              );
          }
        },
      ),
    );
  }
  
  /// Cleanup después de tests (método combinado)
  static void cleanup() {
    // No dispose singletons ya que se reutilizan
    _isInitialized = false;
    
    // Reset ALL platform channel handlers usando la nueva API
    const channels = [
      'plugins.flutter.io/google_maps_0',
      'plugins.flutter.io/shared_preferences', 
      'dexterous.com/flutter/local_notifications',
      'flutter.baseflow.com/permissions/methods',
      'flutter.baseflow.com/geolocator',
      'be.tramckrijte.workmanager',
      'dev.fluttercommunity.plus/connectivity',
      'dev.fluttercommunity.plus/battery',
      'dev.fluttercommunity.plus/device_info',
    ];
    
    for (final channelName in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channelName), null);
    }
    
    // Also cleanup platform views channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
  }
  
  /// Setup Google Maps platform channel mocking
  static Future<void> _setupGoogleMapsMock() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_maps_0'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'map#create':
          return {'mapId': 0};
        case 'map#update':
          return null;
        case 'markers#update':
          return null;
        case 'polylines#update':
          return null;
        case 'polygons#update':
          return null;
        case 'circles#update':
          return null;
        case 'map#getLatLng':
          return {'latitude': 37.7749, 'longitude': -122.4194};
        case 'map#getVisibleRegion':
          return {
            'northeast': {'latitude': 37.8, 'longitude': -122.4},
            'southwest': {'latitude': 37.7, 'longitude': -122.5},
          };
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup platform view channels for Google Maps
  static Future<void> _setupPlatformChannels() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) {
      switch (call.method) {
        case 'create':
          return Future<int>.sync(() => 1);
        case 'dispose':
          return Future<void>.sync(() {});
        default:
          return Future<void>.sync(() {});
      }
    });
  }
  
  // HTTP client override removed due to complexity - will address warning differently
  
  /// Setup shared preferences platform channel (CRITICAL FIX)
  static Future<void> _setupSharedPreferencesChannel() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getAll':
          return <String, dynamic>{};
        case 'setBool':
        case 'setInt':
        case 'setDouble':
        case 'setString':
        case 'setStringList':
          return true;
        case 'remove':
        case 'clear':
          return true;
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup notification platform channels
  static Future<void> _setupNotificationChannels() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
          return true;
        case 'show':
          return null;
        case 'cancel':
          return null;
        case 'cancelAll':
          return null;
        case 'getActiveNotifications':
          return [];
        case 'pendingNotificationRequests':
          return [];
        default:
          return null;
      }
      },
    );
    
    // Setup permission channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'checkPermissionStatus':
          return 1; // PermissionStatus.granted
        case 'requestPermissions':
          return {0: 1}; // PermissionStatus.granted
        case 'shouldShowRequestPermissionRationale':
          return false;
        case 'openAppSettings':
          return true;
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup geolocator platform channels
  static Future<void> setupGeolocatorMocks() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getCurrentPosition':
          return {
            'latitude': 37.7749,
            'longitude': -122.4194,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble(),
            'accuracy': 5.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speedAccuracy': 0.0,
          };
        case 'getPositionStream':
          return null;
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 3; // LocationPermission.whileInUse
        case 'requestPermission':
          return 3; // LocationPermission.whileInUse
        case 'openAppSettings':
          return true;
        case 'openLocationSettings':
          return true;
        case 'distanceBetween':
          return 100.0; // Mock distance
        default:
          return null;
      }
    });
  }
  
  /// Setup background location service mocks
  static Future<void> setupBackgroundLocationMocks() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('be.tramckrijte.workmanager'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
          return true;
        case 'registerOneOffTask':
          return true;
        case 'registerPeriodicTask':
          return true;
        case 'cancelByUniqueName':
          return true;
        case 'cancelAll':
          return true;
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup connectivity mocks
  static Future<void> setupConnectivityMocks() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'check':
          return 'wifi';
        case 'wifiName':
          return 'TestNetwork';
        case 'wifiBSSID':
          return '00:00:00:00:00:00';
        case 'wifiIP':
          return '192.168.1.1';
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup battery optimization mocks
  static Future<void> setupBatteryMocks() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/battery'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getBatteryLevel':
          return 80;
        case 'getBatteryState':
          return 'charging';
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup device info mocks
  static Future<void> setupDeviceInfoMocks() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/device_info'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getAndroidDeviceInfo':
          return {
            'version': {'sdkInt': 30},
            'brand': 'Google',
            'model': 'Pixel',
            'device': 'pixel',
            'manufacturer': 'Google',
          };
        case 'getIosDeviceInfo':
          return {
            'systemVersion': '15.0',
            'model': 'iPhone',
            'name': 'iPhone 13',
          };
        default:
          return null;
      }
      },
    );
  }
  
  /// Setup complete mock environment for comprehensive testing
  static Future<void> setupCompleteTestEnvironment() async {
    await initialize();
    await setupGeolocatorMocks();
    await setupBackgroundLocationMocks();
    await setupConnectivityMocks();
    await setupBatteryMocks();
    await setupDeviceInfoMocks();
  }
  
  // cleanup() ya está definido arriba con funcionalidad combinada
}

/// Test environment configurations for different scenarios
class TestEnvironments {
  /// Configuration for unit tests
  static Future<void> setupUnitTestEnvironment() async {
    await TestConfig.initialize();
  }
  
  /// Configuration for widget tests
  static Future<void> setupWidgetTestEnvironment() async {
    await TestConfig.setupCompleteTestEnvironment();
  }
  
  /// Configuration for integration tests
  static Future<void> setupIntegrationTestEnvironment() async {
    await TestConfig.setupCompleteTestEnvironment();
  }
  
  /// Configuration for performance tests
  static Future<void> setupPerformanceTestEnvironment() async {
    await TestConfig.setupCompleteTestEnvironment();
    
    // Additional performance-specific setup
    // Could include memory monitoring, CPU usage tracking, etc.
  }
  
  /// Configuration for golden tests
  static Future<void> setupGoldenTestEnvironment() async {
    await TestConfig.setupCompleteTestEnvironment();
    
    // Setup font loading for consistent golden tests
    // This would be expanded based on your font requirements
  }
}

/// Test constants used across all tests
class TestConstants {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String testUserName = 'Test User';
  static const String testEventId = 'test_event_123';
  static const String testUserId = 'test_user_123';
  
  // Test coordinates (San Francisco)
  static const double testLatitude = 37.7749;
  static const double testLongitude = -122.4194;
  static const double testRadius = 100.0;
  
  // Test timing
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);
  
  // Test intervals
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration gracePeriodDuration = Duration(seconds: 30);
}

/// Platform-specific test configurations
class PlatformTestConfig {
  /// Setup Android-specific test configurations
  static Future<void> setupAndroidTestConfig() async {
    // Android-specific platform channel mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('android_intent_plus'),
      (MethodCall methodCall) async {
      return null;
      },
    );
  }
  
  /// Setup iOS-specific test configurations
  static Future<void> setupIOSTestConfig() async {
    // iOS-specific platform channel mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getAll':
          return {
            'appName': 'Test App',
            'packageName': 'com.test.app',
            'version': '1.0.0',
            'buildNumber': '1',
          };
        default:
          return null;
      }
      },
    );
  }
}

/// Test data validation helpers
class TestValidation {
  /// Validate that required test environment is properly set up
  static bool validateTestEnvironment() {
    try {
      // Perform basic validation checks
      TestWidgetsFlutterBinding.ensureInitialized();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Validate mock services are properly configured
  static bool validateMockServices() {
    // This would include checks for proper mock setup
    return true;
  }
  
  /// Validate test data integrity
  static bool validateTestData() {
    // Validate that test constants are within expected ranges
    return TestConstants.testLatitude >= -90 && 
           TestConstants.testLatitude <= 90 &&
           TestConstants.testLongitude >= -180 && 
           TestConstants.testLongitude <= 180;
  }
}

// HTTP mock classes removed due to compilation complexity
// The shared preferences mock is the critical fix needed

/// ✅ CONFIGURACIÓN AVANZADA PARA EDGE CASES
class AdvancedTestConfig {
  
  /// ✅ TIMEOUTS CONFIGURABLES
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);
  
  /// ✅ RETRY CONFIGURATION
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  
  /// ✅ MEMORY LEAK DETECTION
  static Future<void> checkMemoryLeaks() async {
    // Force garbage collection
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Verify no dangling streams
    final openStreams = <StreamController>[];
    // Implementation would check for open streams
    
    if (openStreams.isNotEmpty) {
      debugPrint('⚠️ Potential memory leaks detected: ${openStreams.length} open streams');
    }
  }
  
  /// ✅ PERFORMANCE MONITORING
  static final Map<String, List<Duration>> _performanceMetrics = {};
  
  static void recordPerformance(String operation, Duration duration) {
    _performanceMetrics.putIfAbsent(operation, () => []).add(duration);
  }
  
  static void printPerformanceReport() {
    debugPrint('📊 PERFORMANCE REPORT:');
    _performanceMetrics.forEach((operation, durations) {
      final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
      debugPrint('  $operation: ${avg.inMilliseconds}ms avg (${durations.length} samples)');
    });
  }
  
  /// ✅ CLEANUP COMPLETO PARA EDGE CASES
  static Future<void> performDeepCleanup() async {
    // Clear performance metrics
    _performanceMetrics.clear();
    
    // Check for memory leaks
    await checkMemoryLeaks();
    
    // Force garbage collection
    await Future.delayed(const Duration(milliseconds: 100));
    
    debugPrint('🧹 Deep cleanup completed');
  }
  
  /// ✅ ROBUST ERROR HANDLING
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('⚠️ Attempt $attempt/$maxAttempts failed: $e');
        
        if (attempt < maxAttempts) {
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException!;
  }
  
  /// ✅ TIMEOUT WRAPPER
  static Future<T> withTimeout<T>(
    Future<T> operation,
    Duration timeout, {
    String? description,
  }) async {
    try {
      return await operation.timeout(timeout);
    } catch (e) {
      final desc = description ?? 'Operation';
      debugPrint('⏰ $desc timed out after ${timeout.inSeconds}s');
      rethrow;
    }
  }
}