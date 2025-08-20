// test/utils/test_helpers.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:geo_asist_front/models/evento_model.dart';
import 'package:geo_asist_front/models/usuario_model.dart';
import 'package:geo_asist_front/models/attendance_state_model.dart';
import 'package:geo_asist_front/models/location_response_model.dart';
import 'package:geo_asist_front/models/api_response_model.dart';
import 'package:geo_asist_front/utils/app_router.dart';
import 'package:geo_asist_front/core/app_constants.dart';
import 'package:geo_asist_front/services/student_attendance_manager.dart';
import 'test_config.dart';
import 'package:geo_asist_front/models/ubicacion_model.dart';

class TestHelpers {
  /// Creates a mock Position for testing
  static Position createMockPosition({
    double latitude = 37.7749,
    double longitude = -122.4194,
    DateTime? timestamp,
    double accuracy = 5.0,
    double altitude = 0.0,
    double heading = 0.0,
    double speed = 0.0,
    double speedAccuracy = 0.0,
    double altitudeAccuracy = 0.0,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: accuracy,
      altitude: altitude,
      altitudeAccuracy: altitudeAccuracy,
      heading: heading,
      headingAccuracy: 0.0,
      speed: speed,
      speedAccuracy: speedAccuracy,
    );
  }

  /// Creates a mock LocationResponseModel for testing
  static LocationResponseModel createMockLocationResponse({
    double latitude = 37.7749,
    double longitude = -122.4194,
    bool insideGeofence = true,
    double distance = 50.0,
    bool eventActive = true,
    bool eventStarted = true,
    String userId = 'test_user_123',
  }) {
    return LocationResponseModel(
      insideGeofence: insideGeofence,
      distance: distance,
      eventActive: eventActive,
      eventStarted: eventStarted,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a mock Evento for testing
  static Evento createMockEvento({
    String? id = 'test_event_123',
    String titulo = 'Test Event',
    String? descripcion = 'Test event description',
    DateTime? fecha,
    DateTime? horaInicio,
    DateTime? horaFinal,
    double? latitud = 37.7749,
    double? longitud = -122.4194,
    double rangoPermitido = 100.0,
    String? lugar = 'Test Location',
    int duracionMinutos = 120,
  }) {
    final now = DateTime.now();
    final ubicacion = Ubicacion(
      latitud: latitud ?? 37.7749,
      longitud: longitud ?? -122.4194,
    );
    
    return Evento(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      fecha: fecha ?? now.subtract(Duration(minutes: 10)),
      horaInicio: horaInicio ?? now.subtract(Duration(minutes: 10)),
      horaFinal: horaFinal ?? now.add(Duration(hours: 2)),
      ubicacion: ubicacion,
      rangoPermitido: rangoPermitido,
      duracionMinutos: duracionMinutos,
      estado: 'activo',
      isActive: true,
    );
  }

  /// Creates a mock Usuario for testing
  static Usuario createMockUser({
    String id = 'user_123',
    String nombre = 'Test User',
    String correo = 'test@example.com',
    String rol = 'estudiante',
  }) {
    return Usuario(
      id: id,
      nombre: nombre,
      correo: correo,
      rol: rol,
    );
  }

  /// Creates a mock AttendanceState for testing
  static AttendanceState createMockAttendanceState({
    Usuario? currentUser,
    Evento? currentEvent,
    TrackingStatus trackingStatus = TrackingStatus.stopped,
    AttendanceStatus attendanceStatus = AttendanceStatus.notStarted,
    bool isInsideGeofence = false,
    double userLatitude = 37.7749,
    double userLongitude = -122.4194,
    double distanceToEvent = 100.0,
    bool canRegisterAttendance = false,
    bool hasRegisteredAttendance = false,
    bool isInGracePeriod = false,
    int gracePeriodRemaining = 0,
    bool hasViolatedBoundary = false,
    DateTime? lastLocationUpdate,
    DateTime? trackingStartTime,
    DateTime? attendanceRegisteredTime,
    String? lastError,
  }) {
    return AttendanceState(
      currentUser: currentUser ?? createMockUser(),
      currentEvent: currentEvent ?? createMockEvento(),
      trackingStatus: trackingStatus,
      attendanceStatus: attendanceStatus,
      isInsideGeofence: isInsideGeofence,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      distanceToEvent: distanceToEvent,
      canRegisterAttendance: canRegisterAttendance,
      hasRegisteredAttendance: hasRegisteredAttendance,
      isInGracePeriod: isInGracePeriod,
      gracePeriodRemaining: gracePeriodRemaining,
      hasViolatedBoundary: hasViolatedBoundary,
      lastLocationUpdate: lastLocationUpdate,
      trackingStartTime: trackingStartTime,
      attendanceRegisteredTime: attendanceRegisteredTime,
      lastError: lastError,
    );
  }

  /// Creates positions inside geofence for testing
  static Position createPositionInsideGeofence({
    double centerLat = 37.7749,
    double centerLng = -122.4194,
    double radiusMeters = 100.0,
  }) {
    // Generate a random position within the geofence
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * radiusMeters * 0.8; // 80% of radius to ensure inside

    final lat = centerLat + (distance * cos(angle)) / 111320;
    final lng = centerLng + (distance * sin(angle)) / (111320 * cos(centerLat * pi / 180));

    return createMockPosition(latitude: lat, longitude: lng);
  }

  /// Creates positions outside geofence for testing
  static Position createPositionOutsideGeofence({
    double centerLat = 37.7749,
    double centerLng = -122.4194,
    double radiusMeters = 100.0,
  }) {
    // Generate a position outside the geofence
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = radiusMeters * (1.5 + random.nextDouble()); // At least 1.5x the radius

    final lat = centerLat + (distance * cos(angle)) / 111320;
    final lng = centerLng + (distance * sin(angle)) / (111320 * cos(centerLat * pi / 180));

    return createMockPosition(latitude: lat, longitude: lng);
  }

  /// Helper to pump widget with providers for testing
  static Future<void> pumpAppWithProviders(
    WidgetTester tester, {
    required Widget child,
    List<ChangeNotifierProvider>? providers,
    List<Provider>? simpleProviders,
  }) async {
    // Usar TestConfig para configuración completa con providers
    await tester.pumpWidget(
      TestConfig.wrapWithProvidersOnly(child),
    );
    
    // Wait for providers to initialize
    await tester.pumpAndSettle();
  }

  /// Helper específico para screens que necesitan providers
  static Future<void> pumpScreenWithProviders(
    WidgetTester tester, {
    required Widget screen,
  }) async {
    await tester.pumpWidget(
      TestConfig.wrapWithProvidersOnly(screen),
    );
    
    // Wait for providers to initialize
    await tester.pumpAndSettle();
  }

  /// Helper para tests de navegación con routing completo
  static Future<void> pumpAppForNavigation(
    WidgetTester tester, {
    String initialRoute = AppConstants.loginRoute,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: TestConfig.getTestProviders(),
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: initialRoute,
        ),
      ),
    );
    
    await tester.pumpAndSettle();
  }

  /// Mock para StudentAttendanceManager en tests
  static StudentAttendanceManager createMockAttendanceManager() {
    final manager = StudentAttendanceManager();
    // Configurar estado inicial para tests
    return manager;
  }

  /// Wait for stream to emit a specific value
  static Future<T> waitForStreamValue<T>(
    Stream<T> stream,
    bool Function(T) predicate, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<T>();
    late StreamSubscription<T> subscription;

    subscription = stream.listen((value) {
      if (predicate(value)) {
        completer.complete(value);
        subscription.cancel();
      }
    });

    // Set a timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(TimeoutException('Stream timeout', timeout));
      }
    });

    return completer.future;
  }

  /// Helper for testing with fake async
  static void runWithFakeAsync(void Function(FakeAsync) test) {
    fakeAsync((fakeAsync) {
      test(fakeAsync);
    });
  }

  /// Mock API response for successful operation
  static ApiResponse<T> createSuccessResponse<T>({
    T? data,
    String message = 'Success',
  }) {
    return ApiResponse.success(
      data ?? {} as T,
      message: message,
    );
  }

  /// Mock API response for error
  static ApiResponse<T> createErrorResponse<T>({
    String message = 'Error occurred',
    T? data,
  }) {
    return ApiResponse.error(
      message,
      message: message,
    );
  }

  /// Calculate distance between two positions for testing geofence logic
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Verify position is within geofence
  static bool isPositionInGeofence(
    Position position,
    double centerLat,
    double centerLng,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      centerLat,
      centerLng,
    );
    return distance <= radiusMeters;
  }

  /// Create a sequence of positions simulating movement
  static List<Position> createMovementPath({
    required Position start,
    required Position end,
    int steps = 10,
  }) {
    final positions = <Position>[];
    
    for (int i = 0; i <= steps; i++) {
      final ratio = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      
      positions.add(createMockPosition(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now().add(Duration(seconds: i * 30)),
      ));
    }
    
    return positions;
  }

  /// Setup mock services for testing
  static void setupMockServices() {
    // This would be implemented with your actual dependency injection
    // For now, this is a placeholder for future implementation
  }

  /// Reset mock services after testing
  static void resetMockServices() {
    // Reset any global state or mocks
  }

  /// Generate test coverage data
  static Map<String, dynamic> generateCoverageReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'test_run_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'total_lines': 0, // Would be calculated from actual coverage
      'covered_lines': 0,
      'coverage_percentage': 0.0,
    };
  }
}

/// Test data builder for complex objects
class LocationTestDataBuilder {
  double _latitude = 37.7749;
  double _longitude = -122.4194;
  DateTime? _timestamp;
  double _accuracy = 5.0;

  LocationTestDataBuilder withLatitude(double latitude) {
    _latitude = latitude;
    return this;
  }

  LocationTestDataBuilder withLongitude(double longitude) {
    _longitude = longitude;
    return this;
  }

  LocationTestDataBuilder withTimestamp(DateTime timestamp) {
    _timestamp = timestamp;
    return this;
  }

  LocationTestDataBuilder withAccuracy(double accuracy) {
    _accuracy = accuracy;
    return this;
  }

  LocationTestDataBuilder inSanFrancisco() {
    _latitude = 37.7749;
    _longitude = -122.4194;
    return this;
  }

  LocationTestDataBuilder inNewYork() {
    _latitude = 40.7128;
    _longitude = -74.0060;
    return this;
  }

  Position build() => TestHelpers.createMockPosition(
    latitude: _latitude,
    longitude: _longitude,
    timestamp: _timestamp,
    accuracy: _accuracy,
  );
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for positions within a certain distance
  static Matcher isWithinDistanceOf(Position expected, double maxDistance) {
    return predicate<Position>(
      (actual) {
        final distance = TestHelpers.calculateDistance(
          actual.latitude,
          actual.longitude,
          expected.latitude,
          expected.longitude,
        );
        return distance <= maxDistance;
      },
      'Position within ${maxDistance}m of expected location',
    );
  }

  /// Matcher for geofence validation
  static Matcher isInsideGeofence(double centerLat, double centerLng, double radius) {
    return predicate<Position>(
      (position) => TestHelpers.isPositionInGeofence(
        position,
        centerLat,
        centerLng,
        radius,
      ),
      'Position inside geofence',
    );
  }

  /// Matcher for AttendanceState status
  static Matcher hasTrackingStatus(TrackingStatus expected) {
    return predicate<AttendanceState>(
      (state) => state.trackingStatus == expected,
      'AttendanceState with tracking status $expected',
    );
  }
}

/// Memory leak testing utilities
class MemoryLeakTestHelper {
  static void verifyNoMemoryLeaks(VoidCallback testAction) {
    // This would integrate with leak_tracker_flutter_testing
    // For now, this is a placeholder for memory leak detection
    testAction();
  }
}