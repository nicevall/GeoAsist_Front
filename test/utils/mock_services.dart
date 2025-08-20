// test/utils/mock_services.dart

import 'dart:async';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:geo_asist_front/services/location_service.dart';
import 'package:geo_asist_front/services/asistencia_service.dart';
import 'package:geo_asist_front/services/permission_service.dart';
import 'package:geo_asist_front/services/storage_service.dart';
import 'package:geo_asist_front/services/notifications/notification_manager.dart';
import 'package:geo_asist_front/services/teacher_notification_service.dart';
import 'package:geo_asist_front/services/student_notification_service.dart';
import 'package:geo_asist_front/services/background_location_service.dart';
import 'package:geo_asist_front/services/api_service.dart';
import 'package:geo_asist_front/services/evento_service.dart';
import 'package:geo_asist_front/services/justificacion_service.dart';
import 'package:geo_asist_front/services/dashboard_service.dart';
import 'package:geo_asist_front/models/evento_model.dart';
import 'package:geo_asist_front/models/usuario_model.dart';
import 'package:geo_asist_front/models/api_response_model.dart';
import 'test_helpers.dart';

// =============================================================================
// CORE SERVICE MOCKS
// =============================================================================

class MockLocationService extends Mock implements LocationService {
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  Position? _currentPosition;
  
  Stream<Position> get positionStream => _positionController.stream;
  
  void simulateLocationChange(Position position) {
    _currentPosition = position;
    _positionController.add(position);
  }
  
  @override
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    return _currentPosition ?? TestHelpers.createMockPosition();
  }
  
  @override
  void dispose() {
    _positionController.close();
  }
}

class MockAsistenciaService extends Mock implements AsistenciaService {}

class MockPermissionService extends Mock implements PermissionService {
  bool _locationPermissionGranted = true;
  bool _backgroundPermissionGranted = true;
  bool _notificationPermissionGranted = true;
  
  void setLocationPermission(bool granted) => _locationPermissionGranted = granted;
  void setBackgroundPermission(bool granted) => _backgroundPermissionGranted = granted;
  void setNotificationPermission(bool granted) => _notificationPermissionGranted = granted;
  
  @override
  Future<bool> validateAllPermissionsForTracking() async {
    return _locationPermissionGranted && _backgroundPermissionGranted && _notificationPermissionGranted;
  }
}

class MockStorageService extends Mock implements StorageService {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<void> saveUser(Usuario user) async {
    _storage['user'] = user.toJson();
  }
  
  @override
  Future<Usuario?> getUser() async {
    final userData = _storage['user'] as Map<String, dynamic>?;
    return userData != null ? Usuario.fromJson(userData) : null;
  }
  
  @override
  Future<void> saveToken(String token) async {
    _storage['token'] = token;
  }
  
  @override
  Future<String?> getToken() async {
    return _storage['token'] as String?;
  }
  
  void clearStorage() {
    _storage.clear();
  }
}

class MockNotificationManager extends Mock implements NotificationManager {
  final List<String> _notificationHistory = [];
  
  List<String> get notificationHistory => List.unmodifiable(_notificationHistory);
  
  @override
  Future<void> showEventStartedNotification(String eventTitle) async {
    _notificationHistory.add('event_started:$eventTitle');
  }
  
  @override
  Future<void> showGeofenceEnteredNotification(String eventTitle) async {
    _notificationHistory.add('geofence_entered:$eventTitle');
  }
  
  @override
  Future<void> showGeofenceExitedNotification(String eventTitle) async {
    _notificationHistory.add('geofence_exited:$eventTitle');
  }
  
  @override
  Future<void> showGracePeriodStartedNotification({
    required int remainingSeconds, 
    String? eventName
  }) async {
    _notificationHistory.add('grace_period_started:$remainingSeconds');
  }
  
  // ✅ CORREGIR: Signature correcta con parámetros nombrados
  @override
  Future<void> showAttendanceRegisteredNotification({
    String? eventName,
    String? status,
  }) async {
    _notificationHistory.add('attendance_registered:$eventName:$status');
  }
  
  @override
  Future<void> clearAllNotifications() async {
    _notificationHistory.add('clear_all');
  }
  
  void clearHistory() {
    _notificationHistory.clear();
  }
}

// =============================================================================
// ADVANCED SERVICE MOCKS
// =============================================================================

class MockTeacherNotificationService extends Mock implements TeacherNotificationService {}

class MockStudentNotificationService extends Mock implements StudentNotificationService {}

class MockBackgroundLocationService extends Mock implements BackgroundLocationService {
  bool _isTracking = false;
  bool _isInitialized = false;
  String? _currentEventId;

  // ✅ AGREGAR: Métodos requeridos por la interfaz actual
  @override
  Map<String, dynamic> getTrackingStatus() {
    return {
      'isInitialized': _isInitialized,
      'isTracking': _isTracking,
      'hasActiveTimer': _isTracking,
      'hasLocationService': true,
      'instanceHash': hashCode,
      'currentEventId': _currentEventId,
      'isPaused': false,
    };
  }

  @override
  Future<bool> startContinuousTracking({
    required String userId,
    required String eventoId,
    Duration interval = const Duration(minutes: 2),
  }) async {
    _isTracking = true;
    _currentEventId = eventoId;
    debugPrint('🔋 Mock: Background tracking started for event $eventoId');
    return true;
  }

  @override
  void stopTracking() {
    _isTracking = false;
    _currentEventId = null;
    debugPrint('🔋 Mock: Background tracking stopped');
  }

  @override
  Future<void> startEventTracking(String eventoId) async {
    _isTracking = true;
    _currentEventId = eventoId;
    debugPrint('🔋 Mock: Event tracking started for $eventoId');
  }

  @override
  Future<void> stopEventTracking() async {
    _isTracking = false;
    _currentEventId = null;
    debugPrint('🔋 Mock: Event tracking stopped');
  }

  @override
  Future<void> pauseTracking() async {
    debugPrint('🔋 Mock: Tracking paused');
  }

  @override
  Future<void> resumeTracking(String eventoId) async {
    _currentEventId = eventoId;
    debugPrint('🔋 Mock: Tracking resumed for $eventoId');
  }

  @override
  bool get isTracking => _isTracking;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> dispose() async {
    _isTracking = false;
    _isInitialized = false;
    _currentEventId = null;
    debugPrint('🔋 Mock: BackgroundLocationService disposed');
  }

  // ✅ MÉTODO PARA TESTING
  static MockBackgroundLocationService createInitialized() {
    final mock = MockBackgroundLocationService();
    mock._isInitialized = true;
    return mock;
  }
}

class MockApiService extends Mock implements ApiService {
  final Map<String, dynamic> _responses = {};
  bool _isOnline = true;
  
  void setOffline() => _isOnline = false;
  void setOnline() => _isOnline = true;
  
  void setMockResponse(String endpoint, dynamic response) {
    _responses[endpoint] = response;
  }
  
  @override
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    if (!_isOnline) {
      throw Exception('Network error - offline');
    }
    
    final response = _responses[endpoint];
    if (response != null) {
      return ApiResponse.success(response);
    }
    
    return TestHelpers.createSuccessResponse();
  }
  
  @override
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (!_isOnline) {
      throw Exception('Network error - offline');
    }
    
    final response = _responses[endpoint];
    if (response != null) {
      return ApiResponse.success(response);
    }
    
    return TestHelpers.createSuccessResponse();
  }
}

class MockEventoService extends Mock implements EventoService {
  List<Evento> _eventos = [];
  
  void setMockEventos(List<Evento> eventos) {
    _eventos = eventos;
  }
  
  @override
  Future<List<Evento>> obtenerEventos() async {
    return _eventos;
  }
  
  @override
  Future<Evento?> obtenerEventoPorId(String id) async {
    try {
      return _eventos.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}

class MockJustificacionService extends Mock implements JustificacionService {}

class MockDashboardService extends Mock implements DashboardService {}

// =============================================================================
// FLUTTER SPECIFIC MOCKS
// =============================================================================

class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

// =============================================================================
// MOCK FACTORY AND SETUP
// =============================================================================

class MockServiceFactory {
  static MockLocationService createLocationService() {
    final mock = MockLocationService();
    
    // Setup default behaviors
    when(() => mock.getCurrentPosition())
        .thenAnswer((_) async => TestHelpers.createMockPosition());
    
    when(() => mock.updateUserLocationComplete(
      userId: any(named: 'userId'),
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      eventoId: any(named: 'eventoId'),
    )).thenAnswer((_) async => TestHelpers.createMockLocationResponse());
    
    return mock;
  }
  
  static MockAsistenciaService createAsistenciaService() {
    final mock = MockAsistenciaService();
    
    // Setup default behaviors
    when(() => mock.registrarAsistencia(
      eventoId: any(named: 'eventoId'),
      usuarioId: any(named: 'usuarioId'),
      latitud: any(named: 'latitud'),
      longitud: any(named: 'longitud'),
      estado: any(named: 'estado'),
    )).thenAnswer((_) async => TestHelpers.createSuccessResponse());
    
    when(() => mock.enviarHeartbeat(
      usuarioId: any(named: 'usuarioId'),
      eventoId: any(named: 'eventoId'),
      isAppActive: any(named: 'isAppActive'),
      isInGracePeriod: any(named: 'isInGracePeriod'),
      gracePeriodRemaining: any(named: 'gracePeriodRemaining'),
    )).thenAnswer((_) async => TestHelpers.createSuccessResponse());
    
    return mock;
  }
  
  static MockPermissionService createPermissionService({
    bool allPermissionsGranted = true,
  }) {
    final mock = MockPermissionService();
    
    when(() => mock.validateAllPermissionsForTracking())
        .thenAnswer((_) async => allPermissionsGranted);
    
    when(() => mock.requestLocationPermissions())
        .thenAnswer((_) async => LocationPermissionResult.granted);
    
    when(() => mock.requestBackgroundPermission())
        .thenAnswer((_) async => allPermissionsGranted);
    
    return mock;
  }
  
  static MockStorageService createStorageService({
    Usuario? initialUser,
    String? initialToken,
  }) {
    final mock = MockStorageService();
    
    if (initialUser != null) {
      mock.saveUser(initialUser);
    }
    
    if (initialToken != null) {
      mock.saveToken(initialToken);
    }
    
    return mock;
  }
  
  static MockNotificationManager createNotificationManager() {
    final mock = MockNotificationManager();
    
    // Setup default behaviors
    when(() => mock.initialize()).thenAnswer((_) async {});
    when(() => mock.showEventStartedNotification(any()))
        .thenAnswer((_) async {});
    when(() => mock.showTrackingActiveNotification())
        .thenAnswer((_) async {});
    when(() => mock.clearAllNotifications())
        .thenAnswer((_) async {});
    
    return mock;
  }
}

// =============================================================================
// TEST SCENARIO BUILDERS
// =============================================================================

class TestScenarioBuilder {
  late MockLocationService _locationService;
  late MockAsistenciaService _asistenciaService;
  late MockPermissionService _permissionService;
  late MockStorageService _storageService;
  late MockNotificationManager _notificationManager;
  
  TestScenarioBuilder() {
    _locationService = MockServiceFactory.createLocationService();
    _asistenciaService = MockServiceFactory.createAsistenciaService();
    _permissionService = MockServiceFactory.createPermissionService();
    _storageService = MockServiceFactory.createStorageService();
    _notificationManager = MockServiceFactory.createNotificationManager();
  }
  
  TestScenarioBuilder withUser(Usuario user) {
    _storageService.saveUser(user);
    return this;
  }
  
  TestScenarioBuilder withPermissionsDenied() {
    when(() => _permissionService.validateAllPermissionsForTracking())
        .thenAnswer((_) async => false);
    return this;
  }
  
  TestScenarioBuilder withLocationInsideGeofence() {
    _locationService.simulateLocationChange(
      TestHelpers.createPositionInsideGeofence()
    );
    return this;
  }
  
  TestScenarioBuilder withLocationOutsideGeofence() {
    _locationService.simulateLocationChange(
      TestHelpers.createPositionOutsideGeofence()
    );
    return this;
  }
  
  TestScenarioBuilder withNetworkError() {
    when(() => _asistenciaService.registrarAsistencia(
      eventoId: any(named: 'eventoId'),
      usuarioId: any(named: 'usuarioId'),
      latitud: any(named: 'latitud'),
      longitud: any(named: 'longitud'),
      estado: any(named: 'estado'),
    )).thenThrow(Exception('Network error'));
    
    return this;
  }
  
  TestScenarioBuilder withGPSDisabled() {
    when(() => _locationService.getCurrentPosition())
        .thenThrow(Exception('Location services disabled'));
    return this;
  }
  
  Map<String, dynamic> build() {
    return {
      'locationService': _locationService,
      'asistenciaService': _asistenciaService,
      'permissionService': _permissionService,
      'storageService': _storageService,
      'notificationManager': _notificationManager,
    };
  }
}

// =============================================================================
// VERIFICATION HELPERS
// =============================================================================

class MockVerificationHelper {
  static void verifyAttendanceRegistered(MockAsistenciaService mock, {
    required String eventoId,
    required String usuarioId,
  }) {
    verify(() => mock.registrarAsistencia(
      eventoId: eventoId,
      usuarioId: usuarioId,
      latitud: any(named: 'latitud'),
      longitud: any(named: 'longitud'),
      estado: 'presente',
    )).called(1);
  }
  
  static void verifyHeartbeatSent(MockAsistenciaService mock, {
    required String eventoId,
    required String usuarioId,
  }) {
    verify(() => mock.enviarHeartbeat(
      usuarioId: usuarioId,
      eventoId: eventoId,
      isAppActive: any(named: 'isAppActive'),
      isInGracePeriod: any(named: 'isInGracePeriod'),
      gracePeriodRemaining: any(named: 'gracePeriodRemaining'),
    )).called(greaterThan(0));
  }
  
  static void verifyNotificationShown(MockNotificationManager mock, String type) {
    expect(
      mock.notificationHistory.any((notification) => notification.contains(type)),
      isTrue,
    );
  }
  
  static void verifyLocationUpdatesCalled(MockLocationService mock, {
    int minCalls = 1,
  }) {
    verify(() => mock.updateUserLocationComplete(
      userId: any(named: 'userId'),
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      eventoId: any(named: 'eventoId'),
    )).called(greaterThanOrEqualTo(minCalls));
  }
}

// =============================================================================
// CLEANUP HELPER
// =============================================================================

class MockCleanupHelper {
  static void cleanupAllMocks() {
    // Reset any global state
    TestHelpers.resetMockServices();
  }
  
  static void disposeMockServices(Map<String, dynamic> services) {
    final locationService = services['locationService'] as MockLocationService?;
    locationService?.dispose();
  }
}