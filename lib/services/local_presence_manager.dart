// lib/services/local_presence_manager.dart
// 🎯 SISTEMA DE PRESENCIA LOCAL (SIN BACKEND HEARTBEATS)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/evento_model.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

/// Estados de presencia local
enum LocalPresenceStatus {
  notStarted,       // No iniciado
  present,          // Presente y en geofence
  absent,           // Fuera del geofence
  warning,          // Advertencia (cerca del límite)
  disconnected,     // Sin GPS/conexión
  gracePeriod,      // En período de gracia
}

/// Gestor de presencia local que reemplaza heartbeats del backend
class LocalPresenceManager {
  static final LocalPresenceManager _instance = LocalPresenceManager._internal();
  factory LocalPresenceManager() => _instance;
  LocalPresenceManager._internal();

  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  
  // ⚙️ CONFIGURACIÓN
  static const Duration _checkInterval = Duration(seconds: 30); // Cada 30s como heartbeat
  // Unused field _warningDuration removed
  static const int _maxConsecutiveFailures = 3; // Máximo fallos GPS antes de advertencia
  
  // 🎯 ESTADO ACTUAL
  Timer? _presenceTimer;
  Evento? _currentEvent;
  LocalPresenceStatus _status = LocalPresenceStatus.notStarted;
  DateTime? _lastValidLocation;
  DateTime? _sessionStartTime;
  int _consecutiveFailures = 0;
  int _totalChecks = 0;
  int _successfulChecks = 0;
  
  // 📊 MÉTRICAS LOCALES
  final List<PresenceRecord> _presenceHistory = [];
  
  // 🔄 STREAMS
  final StreamController<LocalPresenceStatus> _statusController = 
      StreamController<LocalPresenceStatus>.broadcast();
      
  final StreamController<PresenceStats> _statsController = 
      StreamController<PresenceStats>.broadcast();

  /// Stream para escuchar cambios de estado
  Stream<LocalPresenceStatus> get statusStream => _statusController.stream;
  
  /// Stream para métricas de presencia
  Stream<PresenceStats> get statsStream => _statsController.stream;

  /// ✅ INICIAR MONITOREO DE PRESENCIA
  Future<void> startPresenceMonitoring(Evento event) async {
    debugPrint('🎯 Iniciando monitoreo de presencia local para: ${event.titulo}');
    
    _currentEvent = event;
    _sessionStartTime = DateTime.now();
    _consecutiveFailures = 0;
    _totalChecks = 0;
    _successfulChecks = 0;
    _presenceHistory.clear();
    
    // Verificación inicial
    await _checkPresence();
    
    // Configurar timer periódico
    _presenceTimer = Timer.periodic(_checkInterval, (timer) async {
      await _checkPresence();
    });
    
    _updateStatus(LocalPresenceStatus.present);
  }

  /// 🔍 VERIFICAR PRESENCIA ACTUAL
  Future<void> _checkPresence() async {
    if (_currentEvent == null) return;
    
    _totalChecks++;
    
    try {
      // Obtener ubicación actual
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        // Calcular distancia al evento
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _currentEvent!.ubicacion.latitud,
          _currentEvent!.ubicacion.longitud,
        );
        
        final isInGeofence = distance <= _currentEvent!.rangoPermitido;
        
        // Registrar en historial
        _presenceHistory.add(PresenceRecord(
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          distanceToEvent: distance,
          isInGeofence: isInGeofence,
          accuracy: position.accuracy,
        ));
        
        _lastValidLocation = DateTime.now();
        _consecutiveFailures = 0;
        _successfulChecks++;
        
        // Actualizar estado según ubicación
        if (isInGeofence) {
          _updateStatus(LocalPresenceStatus.present);
        } else {
          // Verificar si está cerca (warning zone)
          final warningDistance = _currentEvent!.rangoPermitido * 1.5;
          if (distance <= warningDistance) {
            _updateStatus(LocalPresenceStatus.warning);
          } else {
            _updateStatus(LocalPresenceStatus.absent);
          }
        }
        
        // Enviar métricas actualizadas
        _updateStats();
        
      } else {
        // Fallo al obtener ubicación
        _handleLocationFailure();
      }
      
    } catch (e) {
      debugPrint('❌ Error verificando presencia: $e');
      _handleLocationFailure();
    }
  }

  /// ⚠️ MANEJAR FALLO DE UBICACIÓN
  void _handleLocationFailure() {
    _consecutiveFailures++;
    
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _updateStatus(LocalPresenceStatus.disconnected);
    }
    
    _updateStats();
  }

  /// 📊 ACTUALIZAR ESTADÍSTICAS
  void _updateStats() {
    if (_sessionStartTime == null) return;
    
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime!);
    
    // Calcular tiempo en geofence
    final inGeofenceRecords = _presenceHistory.where((r) => r.isInGeofence);
    final estimatedPresenceTime = Duration(
      seconds: (inGeofenceRecords.length * _checkInterval.inSeconds),
    );
    
    final stats = PresenceStats(
      sessionDuration: sessionDuration,
      estimatedPresenceTime: estimatedPresenceTime,
      totalChecks: _totalChecks,
      successfulChecks: _successfulChecks,
      presencePercentage: _totalChecks > 0 
          ? (inGeofenceRecords.length / _totalChecks * 100).round()
          : 0,
      consecutiveFailures: _consecutiveFailures,
      lastValidLocation: _lastValidLocation,
    );
    
    _statsController.add(stats);
  }

  /// 🔄 ACTUALIZAR ESTADO
  void _updateStatus(LocalPresenceStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
      
      debugPrint('🎯 Estado presencia: ${newStatus.toString()}');
      
      // Guardar cambio de estado en historial
      _storageService.savePresenceStatusChange(
        eventId: _currentEvent?.id ?? '',
        status: newStatus.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// ⏸️ ACTIVAR PERÍODO DE GRACIA
  void activateGracePeriod({Duration duration = const Duration(minutes: 15)}) {
    debugPrint('⏸️ Activando período de gracia por ${duration.inMinutes} minutos');
    _updateStatus(LocalPresenceStatus.gracePeriod);
    
    // Volver a monitoreo normal después del grace period
    Timer(duration, () {
      if (_status == LocalPresenceStatus.gracePeriod) {
        _checkPresence(); // Verificar estado actual
      }
    });
  }

  /// 🛑 DETENER MONITOREO
  Future<void> stopPresenceMonitoring() async {
    debugPrint('🛑 Deteniendo monitoreo de presencia');
    
    _presenceTimer?.cancel();
    _presenceTimer = null;
    
    // Guardar resumen final de sesión
    if (_sessionStartTime != null && _currentEvent != null) {
      await _saveSessionSummary();
    }
    
    _currentEvent = null;
    _updateStatus(LocalPresenceStatus.notStarted);
  }

  /// 💾 GUARDAR RESUMEN DE SESIÓN
  Future<void> _saveSessionSummary() async {
    final summary = {
      'eventId': _currentEvent!.id,
      'eventTitle': _currentEvent!.titulo,
      'sessionStart': _sessionStartTime!.toIso8601String(),
      'sessionEnd': DateTime.now().toIso8601String(),
      'totalChecks': _totalChecks,
      'successfulChecks': _successfulChecks,
      'presenceRecords': _presenceHistory.length,
      'estimatedPresenceMinutes': (_presenceHistory.where((r) => r.isInGeofence).length * _checkInterval.inSeconds / 60).round(),
    };
    
    await _storageService.savePresenceSession(summary);
    debugPrint('💾 Sesión de presencia guardada');
  }

  /// 📊 OBTENER ESTADÍSTICAS ACTUALES
  PresenceStats? getCurrentStats() {
    if (_sessionStartTime == null) return null;
    
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime!);
    final inGeofenceRecords = _presenceHistory.where((r) => r.isInGeofence);
    
    return PresenceStats(
      sessionDuration: sessionDuration,
      estimatedPresenceTime: Duration(
        seconds: (inGeofenceRecords.length * _checkInterval.inSeconds),
      ),
      totalChecks: _totalChecks,
      successfulChecks: _successfulChecks,
      presencePercentage: _totalChecks > 0 
          ? (inGeofenceRecords.length / _totalChecks * 100).round()
          : 0,
      consecutiveFailures: _consecutiveFailures,
      lastValidLocation: _lastValidLocation,
    );
  }

  /// 🧹 DISPOSE
  void dispose() {
    _presenceTimer?.cancel();
    _statusController.close();
    _statsController.close();
  }
}

/// 📊 REGISTRO DE PRESENCIA
class PresenceRecord {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double distanceToEvent;
  final bool isInGeofence;
  final double accuracy;

  PresenceRecord({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceToEvent,
    required this.isInGeofence,
    required this.accuracy,
  });
}

/// 📈 ESTADÍSTICAS DE PRESENCIA
class PresenceStats {
  final Duration sessionDuration;
  final Duration estimatedPresenceTime;
  final int totalChecks;
  final int successfulChecks;
  final int presencePercentage;
  final int consecutiveFailures;
  final DateTime? lastValidLocation;

  PresenceStats({
    required this.sessionDuration,
    required this.estimatedPresenceTime,
    required this.totalChecks,
    required this.successfulChecks,
    required this.presencePercentage,
    required this.consecutiveFailures,
    this.lastValidLocation,
  });

  String get sessionDurationFormatted {
    final hours = sessionDuration.inHours;
    final minutes = sessionDuration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get presenceTimeFormatted {
    final hours = estimatedPresenceTime.inHours;
    final minutes = estimatedPresenceTime.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}