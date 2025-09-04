// lib/screens/attendance/managers/attendance_tracking_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/storage_service.dart';
import '../../../services/attendance_service_adapter.dart';
import '../../../services/permission_service.dart';
import '../../../services/notifications/notification_manager.dart';
import '../../../models/usuario_model.dart';
import '../../../models/evento_model.dart';
import '../../../models/asistencia_model.dart';

class AttendanceTrackingManager {
  // Servicios
  final StorageService _storageService = StorageService();
  final EventoService _eventoService = EventoService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final PermissionService _permissionService = PermissionService();
  final NotificationManager _notificationManager = NotificationManager();

  // Estado del tracking
  bool _isTrackingActive = false;
  bool _isInGeofence = false;
  bool _hasPermissions = false;
  String? _errorMessage;

  // Datos del tracking
  Usuario? _currentUser;
  Evento? _activeEvent;
  List<Asistencia> _attendanceHistory = [];
  Position? _currentPosition;
  String _trackingStatus = 'inactive';

  // Timers y contadores
  Timer? _positionUpdateTimer;
  Timer? _heartbeatTimer;
  Timer? _geofenceGraceTimer;
  Timer? _appClosedGraceTimer;
  int _geofenceSecondsRemaining = 0;
  int _appClosedSecondsRemaining = 0;
  final Duration _timeInEvent = Duration.zero;
  int _exitWarningCount = 0;

  // Estadísticas en tiempo real
  double _distanceFromCenter = 0.0;
  double _currentAccuracy = 0.0;
  String _lastUpdateTime = '';

  // Permisos críticos
  bool _showingPermissionDialog = false;
  bool _allPermissionsGranted = false;
  Map<String, bool> _permissionStatus = {};

  // Callbacks para UI
  VoidCallback? onStateChanged;
  Function(String)? onError;

  // Getters
  bool get isTrackingActive => _isTrackingActive;
  bool get isInGeofence => _isInGeofence;
  bool get hasPermissions => _hasPermissions;
  String? get errorMessage => _errorMessage;
  Usuario? get currentUser => _currentUser;
  Evento? get activeEvent => _activeEvent;
  List<Asistencia> get attendanceHistory => _attendanceHistory;
  Position? get currentPosition => _currentPosition;
  String get trackingStatus => _trackingStatus;
  double get distanceFromCenter => _distanceFromCenter;
  double get currentAccuracy => _currentAccuracy;
  String get lastUpdateTime => _lastUpdateTime;
  Duration get timeInEvent => _timeInEvent;
  int get exitWarningCount => _exitWarningCount;
  int get geofenceSecondsRemaining => _geofenceSecondsRemaining;
  int get appClosedSecondsRemaining => _appClosedSecondsRemaining;

  Future<void> initialize({String? eventoId}) async {
    try {
      _errorMessage = null;
      await _loadUserData();
      await _checkCriticalPermissions();
      
      if (_hasPermissions) {
        await _loadActiveEvent(eventoId);
        await _loadAttendanceHistory();
        _notifyStateChanged();
      }
    } catch (e) {
      _errorMessage = 'Error inicializando: $e';
      _notifyError(_errorMessage!);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        _currentUser = Usuario.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error cargando datos de usuario: $e');
    }
  }

  Future<void> _checkCriticalPermissions() async {
    try {
      _permissionStatus = await _permissionService.checkAllPermissions();
      _allPermissionsGranted = _permissionStatus.values.every((granted) => granted);
      _hasPermissions = _allPermissionsGranted;
      
      if (!_hasPermissions && !_showingPermissionDialog) {
        _showingPermissionDialog = true;
        await _requestMissingPermissions();
      }
    } catch (e) {
      debugPrint('Error verificando permisos: $e');
      _hasPermissions = false;
    }
  }

  Future<void> _requestMissingPermissions() async {
    try {
      final permissionsResult = await _permissionService.requestAllPermissions();
      _hasPermissions = permissionsResult.values.every((granted) => granted);
      _showingPermissionDialog = false;
      
      if (!_hasPermissions) {
        _errorMessage = 'Permisos requeridos no concedidos';
        _notifyError(_errorMessage!);
      }
    } catch (e) {
      _showingPermissionDialog = false;
      _errorMessage = 'Error solicitando permisos: $e';
      _notifyError(_errorMessage!);
    }
  }

  Future<void> _loadActiveEvent(String? eventoId) async {
    try {
      if (eventoId != null) {
        // Cargar evento específico
        final response = await _eventoService.getEventoById(eventoId);
        if (response.success && response.data != null) {
          _activeEvent = response.data;
        }
      } else {
        // Buscar evento activo actual
        final response = await _eventoService.getActiveEvent();
        if (response.success && response.data != null) {
          _activeEvent = response.data;
        }
      }
    } catch (e) {
      debugPrint('Error cargando evento activo: $e');
    }
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      if (_currentUser != null) {
        final response = await _asistenciaService.getAttendanceByUser(_currentUser!.id);
        if (response.success && response.data != null) {
          _attendanceHistory = response.data!;
        }
      }
    } catch (e) {
      debugPrint('Error cargando historial de asistencias: $e');
    }
  }

  Future<void> startTracking() async {
    if (!_hasPermissions) {
      await _checkCriticalPermissions();
      if (!_hasPermissions) return;
    }

    if (_activeEvent == null) {
      _errorMessage = 'No hay evento activo para rastrear';
      _notifyError(_errorMessage!);
      return;
    }

    try {
      _isTrackingActive = true;
      _trackingStatus = 'active';
      _startLocationUpdates();
      _startHeartbeat();
      _notifyStateChanged();

      // Notificar inicio de tracking
      await _notificationManager.showLocal(
        'Seguimiento iniciado',
        'Rastreando asistencia para ${_activeEvent!.titulo}',
      );
    } catch (e) {
      _errorMessage = 'Error iniciando tracking: $e';
      _notifyError(_errorMessage!);
    }
  }

  Future<void> stopTracking() async {
    try {
      _isTrackingActive = false;
      _trackingStatus = 'inactive';
      _stopAllTimers();
      _notifyStateChanged();

      // Notificar fin de tracking
      await _notificationManager.showLocal(
        'Seguimiento detenido',
        'El rastreo de asistencia ha sido detenido',
      );
    } catch (e) {
      debugPrint('Error deteniendo tracking: $e');
    }
  }

  void _startLocationUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePosition();
    });
    
    // Primera actualización inmediata
    _updatePosition();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _updatePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      _currentPosition = position;
      _currentAccuracy = position.accuracy;
      _lastUpdateTime = DateTime.now().toString().substring(11, 19);

      if (_activeEvent != null) {
        _calculateDistanceAndGeofence(position);
        await _checkGeofenceStatus();
      }

      _notifyStateChanged();
    } catch (e) {
      debugPrint('Error actualizando posición: $e');
      _trackingStatus = 'error';
      _notifyStateChanged();
    }
  }

  void _calculateDistanceAndGeofence(Position position) {
    if (_activeEvent == null) return;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _activeEvent!.ubicacion.latitud,
      _activeEvent!.ubicacion.longitud,
    );

    _distanceFromCenter = distance;
    final wasInGeofence = _isInGeofence;
    _isInGeofence = distance <= _activeEvent!.rangoPermitido;

    // Detectar cambios de estado del geofence
    if (wasInGeofence != _isInGeofence) {
      _handleGeofenceStateChange();
    }
  }

  Future<void> _checkGeofenceStatus() async {
    if (_activeEvent == null || _currentUser == null) return;

    try {
      // Verificar si ya hay asistencia registrada
      final response = await _asistenciaService.checkExistingAttendance(
        _currentUser!.id,
        _activeEvent!.id!,
      );

      if (response.success && response.data == null && _isInGeofence) {
        // No hay asistencia y está en geofence - registrar automáticamente
        await _registerAutomaticAttendance();
      }
    } catch (e) {
      debugPrint('Error verificando estado de geofence: $e');
    }
  }

  Future<void> _registerAutomaticAttendance() async {
    if (_currentPosition == null || _activeEvent == null || _currentUser == null) {
      return;
    }

    try {
      final response = await _asistenciaService.registerAttendance(
        _currentUser!.id,
        _activeEvent!.id!,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (response.success) {
        await _notificationManager.showLocal(
          'Asistencia registrada',
          'Tu asistencia ha sido registrada automáticamente',
        );
        
        // Recargar historial
        await _loadAttendanceHistory();
        _notifyStateChanged();
      }
    } catch (e) {
      debugPrint('Error registrando asistencia automática: $e');
    }
  }

  void _handleGeofenceStateChange() {
    if (_isInGeofence) {
      _trackingStatus = 'inside';
      _exitWarningCount = 0;
      _geofenceGraceTimer?.cancel();
    } else {
      _trackingStatus = 'outside';
      _startGeofenceGracePeriod();
    }
  }

  void _startGeofenceGracePeriod() {
    _geofenceSecondsRemaining = 300; // 5 minutos de gracia
    _geofenceGraceTimer?.cancel();
    
    _geofenceGraceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _geofenceSecondsRemaining--;
      
      if (_geofenceSecondsRemaining <= 0) {
        timer.cancel();
        _handleGeofenceViolation();
      } else if (_geofenceSecondsRemaining % 60 == 0) {
        // Advertencia cada minuto
        _showGeofenceWarning();
      }
      
      _notifyStateChanged();
    });
  }

  void _handleGeofenceViolation() {
    _exitWarningCount++;
    _trackingStatus = 'violation';
    
    _notificationManager.showLocal(
      'Fuera del área de evento',
      'Has salido del área del evento. Regresa para mantener tu asistencia.',
    );
    
    _notifyStateChanged();
  }

  void _showGeofenceWarning() {
    final minutesRemaining = (_geofenceSecondsRemaining / 60).ceil();
    _notificationManager.showLocal(
      'Advertencia de ubicación',
      'Regresa al área del evento en $minutesRemaining minutos',
    );
  }

  Future<void> _sendHeartbeat() async {
    if (!_isTrackingActive || _currentPosition == null || _currentUser == null) {
      return;
    }

    try {
      // Enviar ubicación actual al backend
      await _asistenciaService.updateUserLocation(
        _currentUser!.id,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentPosition!.accuracy,
      );
    } catch (e) {
      debugPrint('Error enviando heartbeat: $e');
    }
  }

  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  void _handleAppPaused() {
    if (_isTrackingActive) {
      _startAppClosedGracePeriod();
    }
  }

  void _handleAppResumed() {
    _appClosedGraceTimer?.cancel();
    _appClosedSecondsRemaining = 0;
    
    if (_isTrackingActive) {
      // Reiniciar updates de posición
      _startLocationUpdates();
    }
  }

  void _handleAppDetached() {
    _stopAllTimers();
  }

  void _startAppClosedGracePeriod() {
    _appClosedSecondsRemaining = 600; // 10 minutos de gracia
    _appClosedGraceTimer?.cancel();
    
    _appClosedGraceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _appClosedSecondsRemaining--;
      
      if (_appClosedSecondsRemaining <= 0) {
        timer.cancel();
        _handleAppClosedViolation();
      }
    });
  }

  void _handleAppClosedViolation() {
    _notificationManager.showLocal(
      'Aplicación cerrada demasiado tiempo',
      'Abre la aplicación para continuar el seguimiento de asistencia',
    );
  }

  void _stopAllTimers() {
    _positionUpdateTimer?.cancel();
    _heartbeatTimer?.cancel();
    _geofenceGraceTimer?.cancel();
    _appClosedGraceTimer?.cancel();
  }

  Future<void> refreshData() async {
    try {
      await _loadActiveEvent(null);
      await _loadAttendanceHistory();
      _notifyStateChanged();
    } catch (e) {
      _errorMessage = 'Error refrescando datos: $e';
      _notifyError(_errorMessage!);
    }
  }


  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  void _notifyError(String error) {
    onError?.call(error);
  }

  void dispose() {
    _stopAllTimers();
  }
}