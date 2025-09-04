// lib/services/attendance/grace_period_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/backend_sync_service.dart';
import '../notifications/notification_manager.dart';

/// ✅ GRACE PERIOD MANAGER: Períodos de gracia duales sin conflictos
/// Responsabilidades:
/// - Grace period para geofence (60 segundos) - solo para salidas de geocerca
/// - Grace period para app cerrada (30 segundos) - solo para cierre de app
/// - Timers separados sin conflictos entre sí
/// - Notificaciones específicas para cada tipo
/// - Cancelación individual de cada grace period
/// - Monitoreo independiente de cada timer
class GracePeriodManager {
  static final GracePeriodManager _instance = GracePeriodManager._internal();
  factory GracePeriodManager() => _instance;
  GracePeriodManager._internal();

  final NotificationManager _notificationManager = NotificationManager();
  final BackendSyncService _syncService = BackendSyncService();

  // ⚙️ CONFIGURACIÓN GRACE PERIODS
  static const Duration _geofenceGraceDuration = Duration(seconds: 60);
  static const Duration _appClosedGraceDuration = Duration(seconds: 30);

  // 🎯 TIMERS SEPARADOS (SIN CONFLICTOS)
  Timer? _geofenceGraceTimer;
  Timer? _appClosedGraceTimer;

  // 📊 ESTADO DE GRACE PERIODS
  bool _isGeofenceGraceActive = false;
  bool _isAppClosedGraceActive = false;
  DateTime? _geofenceGraceStarted;
  DateTime? _appClosedGraceStarted;
  int _geofenceGraceRemaining = 0;
  int _appClosedGraceRemaining = 0;

  // 🔄 STREAMS
  final StreamController<GracePeriodEvent> _gracePeriodController = 
      StreamController<GracePeriodEvent>.broadcast();

  /// Stream para escuchar eventos de grace period
  Stream<GracePeriodEvent> get gracePeriodStream => _gracePeriodController.stream;

  /// 🚨 INICIAR GRACE PERIOD PARA GEOFENCE (60 segundos)
  /// Solo para cuando el estudiante sale de la geocerca
  Future<void> startGeofenceGracePeriod() async {
    if (_isGeofenceGraceActive) {
      debugPrint('⚠️ Geofence grace period already active, ignoring');
      return;
    }

    debugPrint('🚨 Starting GEOFENCE grace period - 60 seconds');
    
    _isGeofenceGraceActive = true;
    _geofenceGraceStarted = DateTime.now();
    _geofenceGraceRemaining = _geofenceGraceDuration.inSeconds;

    // Notificación específica para geofence
    await _notificationManager.showAppClosedWarningNotification(
      _geofenceGraceDuration.inSeconds
    );
    
    // Sincronizar inicio de grace period con backend
    _syncService.addPendingOperation(SyncOperation(
      type: SyncOperationType.location,
      data: {
        'event': 'geofence_grace_started',
        'duration': _geofenceGraceDuration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
      method: 'POST',
    ));

    // Timer específico para geofence (60 segundos)
    _geofenceGraceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _geofenceGraceRemaining = _geofenceGraceDuration.inSeconds - timer.tick;

      // Emitir evento de progreso
      _emitGracePeriodEvent(GracePeriodEvent(
        type: GracePeriodEventType.geofenceProgress,
        remaining: _geofenceGraceRemaining,
        total: _geofenceGraceDuration.inSeconds,
      ));

      // Al terminar
      if (_geofenceGraceRemaining <= 0) {
        timer.cancel();
        _triggerGeofenceGraceExpired();
      }
    });

    // Emitir evento de inicio
    _emitGracePeriodEvent(GracePeriodEvent(
      type: GracePeriodEventType.geofenceStarted,
      remaining: _geofenceGraceRemaining,
      total: _geofenceGraceDuration.inSeconds,
    ));
  }

  /// 🚨 INICIAR GRACE PERIOD PARA APP CERRADA (30 segundos)
  /// Solo para cuando la app se cierra/va a background
  Future<void> startAppClosedGracePeriod() async {
    if (_isAppClosedGraceActive) {
      debugPrint('⚠️ App closed grace period already active, ignoring');
      return;
    }

    debugPrint('🚨 Starting APP CLOSED grace period - 30 seconds');
    
    _isAppClosedGraceActive = true;
    _appClosedGraceStarted = DateTime.now();
    _appClosedGraceRemaining = _appClosedGraceDuration.inSeconds;

    // Notificación específica para app cerrada
    await _notificationManager.showAppClosedWarningNotification(
      _appClosedGraceDuration.inSeconds
    );

    // Timer específico para app cerrada (30 segundos)
    _appClosedGraceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _appClosedGraceRemaining = _appClosedGraceDuration.inSeconds - timer.tick;

      // Emitir evento de progreso
      _emitGracePeriodEvent(GracePeriodEvent(
        type: GracePeriodEventType.appClosedProgress,
        remaining: _appClosedGraceRemaining,
        total: _appClosedGraceDuration.inSeconds,
      ));

      // Al terminar
      if (_appClosedGraceRemaining <= 0) {
        timer.cancel();
        _triggerAppClosedGraceExpired();
      }
    });

    // Emitir evento de inicio
    _emitGracePeriodEvent(GracePeriodEvent(
      type: GracePeriodEventType.appClosedStarted,
      remaining: _appClosedGraceRemaining,
      total: _appClosedGraceDuration.inSeconds,
    ));
  }

  /// ✅ CANCELAR GRACE PERIOD GEOFENCE
  /// Se llama cuando el estudiante regresa a la geocerca
  Future<void> cancelGeofenceGracePeriod() async {
    if (!_isGeofenceGraceActive) {
      debugPrint('✅ Geofence grace period not active, nothing to cancel');
      return;
    }

    debugPrint('✅ Canceling GEOFENCE grace period - student returned to area');
    
    _geofenceGraceTimer?.cancel();
    _geofenceGraceTimer = null;
    _isGeofenceGraceActive = false;
    _geofenceGraceStarted = null;
    _geofenceGraceRemaining = 0;

    // Notificación de cancelación
    // await _notificationManager.showGracePeriodCancelledNotification('regresó al área');

    // Emitir evento de cancelación
    _emitGracePeriodEvent(GracePeriodEvent(
      type: GracePeriodEventType.geofenceCancelled,
      remaining: 0,
      total: _geofenceGraceDuration.inSeconds,
    ));
  }

  /// ✅ CANCELAR GRACE PERIOD APP CERRADA
  /// Se llama cuando la app regresa a foreground
  Future<void> cancelAppClosedGracePeriod() async {
    if (!_isAppClosedGraceActive) {
      debugPrint('✅ App closed grace period not active, nothing to cancel');
      return;
    }

    debugPrint('✅ Canceling APP CLOSED grace period - app returned to foreground');
    
    _appClosedGraceTimer?.cancel();
    _appClosedGraceTimer = null;
    _isAppClosedGraceActive = false;
    _appClosedGraceStarted = null;
    _appClosedGraceRemaining = 0;

    // Notificación de cancelación
    // await _notificationManager.showGracePeriodCancelledNotification('abrió la app');

    // Emitir evento de cancelación
    _emitGracePeriodEvent(GracePeriodEvent(
      type: GracePeriodEventType.appClosedCancelled,
      remaining: 0,
      total: _appClosedGraceDuration.inSeconds,
    ));
  }

  /// 🚨 GEOFENCE GRACE PERIOD EXPIRADO
  void _triggerGeofenceGraceExpired() {
    debugPrint('🚨 GEOFENCE grace period EXPIRED - 60 seconds elapsed');
    
    _isGeofenceGraceActive = false;
    _geofenceGraceStarted = null;
    _geofenceGraceRemaining = 0;

    // Emitir evento de expiración
    _emitGracePeriodEvent(GracePeriodEvent(
      type: GracePeriodEventType.geofenceExpired,
      remaining: 0,
      total: _geofenceGraceDuration.inSeconds,
    ));
  }

  /// 🚨 APP CLOSED GRACE PERIOD EXPIRADO
  void _triggerAppClosedGraceExpired() {
    debugPrint('🚨 APP CLOSED grace period EXPIRED - 30 seconds elapsed');
    
    _isAppClosedGraceActive = false;
    _appClosedGraceStarted = null;
    _appClosedGraceRemaining = 0;

    // Emitir evento de expiración
    _emitGracePeriodEvent(GracePeriodEvent(
      type: GracePeriodEventType.appClosedExpired,
      remaining: 0,
      total: _appClosedGraceDuration.inSeconds,
    ));
  }

  /// 📊 OBTENER ESTADO ACTUAL
  GracePeriodStatus getCurrentStatus() {
    return GracePeriodStatus(
      isGeofenceGraceActive: _isGeofenceGraceActive,
      isAppClosedGraceActive: _isAppClosedGraceActive,
      geofenceGraceRemaining: _geofenceGraceRemaining,
      appClosedGraceRemaining: _appClosedGraceRemaining,
      geofenceGraceStarted: _geofenceGraceStarted,
      appClosedGraceStarted: _appClosedGraceStarted,
    );
  }

  /// ❓ ¿ALGÚN GRACE PERIOD ACTIVO?
  bool get hasAnyGracePeriodActive {
    return _isGeofenceGraceActive || _isAppClosedGraceActive;
  }

  /// ❓ ¿GRACE PERIOD GEOFENCE ACTIVO?
  bool get isGeofenceGraceActive => _isGeofenceGraceActive;

  /// ❓ ¿GRACE PERIOD APP CLOSED ACTIVO?
  bool get isAppClosedGraceActive => _isAppClosedGraceActive;

  /// ⏱️ TIEMPO RESTANTE GEOFENCE
  int get geofenceGraceRemaining => _geofenceGraceRemaining;

  /// ⏱️ TIEMPO RESTANTE APP CLOSED
  int get appClosedGraceRemaining => _appClosedGraceRemaining;

  /// 🔄 EMITIR EVENTO GRACE PERIOD
  void _emitGracePeriodEvent(GracePeriodEvent event) {
    if (!_gracePeriodController.isClosed) {
      _gracePeriodController.add(event);
    }
  }

  /// 🧹 CANCELAR TODOS LOS GRACE PERIODS
  Future<void> cancelAllGracePeriods() async {
    debugPrint('🧹 Canceling all grace periods');
    
    if (_isGeofenceGraceActive) {
      await cancelGeofenceGracePeriod();
    }
    
    if (_isAppClosedGraceActive) {
      await cancelAppClosedGracePeriod();
    }
  }

  /// 🧹 CLEANUP
  void dispose() {
    debugPrint('🧹 Disposing GracePeriodManager');
    
    _geofenceGraceTimer?.cancel();
    _appClosedGraceTimer?.cancel();
    _gracePeriodController.close();
    
    _isGeofenceGraceActive = false;
    _isAppClosedGraceActive = false;
    
    debugPrint('🧹 GracePeriodManager disposed');
  }
}

/// ✅ EVENTO DE GRACE PERIOD
class GracePeriodEvent {
  final GracePeriodEventType type;
  final int remaining;
  final int total;
  final DateTime timestamp;

  GracePeriodEvent({
    required this.type,
    required this.remaining,
    required this.total,
  }) : timestamp = DateTime.now();

  /// Porcentaje de progreso (0-100)
  double get progressPercentage {
    return total > 0 ? ((total - remaining) / total) * 100 : 0.0;
  }

  @override
  String toString() {
    return 'GracePeriodEvent(type: $type, remaining: ${remaining}s, '
           'progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}

/// ✅ TIPOS DE EVENTO GRACE PERIOD
enum GracePeriodEventType {
  // Geofence grace period (60s)
  geofenceStarted,
  geofenceProgress,
  geofenceCancelled,
  geofenceExpired,
  
  // App closed grace period (30s)
  appClosedStarted,
  appClosedProgress,
  appClosedCancelled,
  appClosedExpired,
}

/// ✅ ESTADO ACTUAL DE GRACE PERIODS
class GracePeriodStatus {
  final bool isGeofenceGraceActive;
  final bool isAppClosedGraceActive;
  final int geofenceGraceRemaining;
  final int appClosedGraceRemaining;
  final DateTime? geofenceGraceStarted;
  final DateTime? appClosedGraceStarted;

  const GracePeriodStatus({
    required this.isGeofenceGraceActive,
    required this.isAppClosedGraceActive,
    required this.geofenceGraceRemaining,
    required this.appClosedGraceRemaining,
    this.geofenceGraceStarted,
    this.appClosedGraceStarted,
  });

  /// ¿Algún grace period activo?
  bool get hasAnyActive => isGeofenceGraceActive || isAppClosedGraceActive;

  /// Grace period con mayor prioridad (menor tiempo restante)
  GracePeriodType? get activePriorityType {
    if (!hasAnyActive) return null;
    
    if (isGeofenceGraceActive && isAppClosedGraceActive) {
      // Si ambos están activos, priorizar el que menos tiempo tenga
      return geofenceGraceRemaining <= appClosedGraceRemaining 
          ? GracePeriodType.geofence 
          : GracePeriodType.appClosed;
    }
    
    if (isGeofenceGraceActive) return GracePeriodType.geofence;
    if (isAppClosedGraceActive) return GracePeriodType.appClosed;
    
    return null;
  }

  @override
  String toString() {
    return 'GracePeriodStatus(geofence: $isGeofenceGraceActive/${geofenceGraceRemaining}s, '
           'appClosed: $isAppClosedGraceActive/${appClosedGraceRemaining}s)';
  }
}

/// ✅ TIPOS DE GRACE PERIOD
enum GracePeriodType {
  geofence,   // 60 segundos para salida de geocerca
  appClosed,  // 30 segundos para app cerrada
}