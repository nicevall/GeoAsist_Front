import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/local_geofencing_service.dart
// 🎯 SERVICIO DE GEOFENCING LOCAL (SIN BACKEND)
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/evento_model.dart';
import '../services/location_service.dart';
import '../services/notifications/notification_manager.dart';

/// Estados de geofence
enum GeofenceStatus {
  unknown,
  inside,
  outside,
  approaching,
  leaving,
}

/// Resultado de verificación de geofence
class GeofenceResult {
  final bool isInside;
  final double distance;
  final double accuracy;
  final GeofenceStatus status;
  final DateTime timestamp;

  GeofenceResult({
    required this.isInside,
    required this.distance,
    required this.accuracy,
    required this.status,
    required this.timestamp,
  });
}

/// Servicio de geofencing completamente local
class LocalGeofencingService {
  static final LocalGeofencingService _instance = LocalGeofencingService._internal();
  factory LocalGeofencingService() => _instance;
  LocalGeofencingService._internal();

  final LocationService _locationService = LocationService();
  final NotificationManager _notificationManager = NotificationManager();

  // ⚙️ CONFIGURACIÓN
  static const Duration _checkInterval = Duration(seconds: 10);
  static const double _approachingThreshold = 1.5; // 1.5x del radio para "approaching"
  static const double _leavingThreshold = 1.2; // 1.2x del radio para "leaving"
  static const int _minConsecutiveChecks = 2; // Verificaciones consecutivas antes de cambiar estado

  // 🎯 ESTADO ACTUAL
  Timer? _geofenceTimer;
  Evento? _currentEvent;
  GeofenceStatus _currentStatus = GeofenceStatus.unknown;
  // Unused field _previousStatus removed
  int _consecutiveStatusCount = 0;
  double _lastDistance = 0.0;
  Position? _lastPosition;

  // 🔄 STREAMS
  final StreamController<GeofenceResult> _geofenceController = 
      StreamController<GeofenceResult>.broadcast();

  /// Stream para escuchar cambios de geofence
  Stream<GeofenceResult> get geofenceStream => _geofenceController.stream;

  /// ✅ INICIAR MONITOREO DE GEOFENCE
  Future<void> startGeofencing(Evento event) async {
    logger.d('🎯 Iniciando geofencing local para: ${event.titulo}');
    
    _currentEvent = event;
    _currentStatus = GeofenceStatus.unknown;
    _consecutiveStatusCount = 0;

    // Verificación inicial
    await _checkGeofence();

    // Configurar timer periódico
    _geofenceTimer = Timer.periodic(_checkInterval, (timer) async {
      await _checkGeofence();
    });
  }

  /// 🔍 VERIFICAR GEOFENCE
  Future<void> _checkGeofence() async {
    if (_currentEvent == null) return;

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        logger.d('⚠️ No se pudo obtener ubicación para geofence');
        return;
      }

      _lastPosition = position;

      // Calcular distancia al evento
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _currentEvent!.ubicacion.latitud,
        _currentEvent!.ubicacion.longitud,
      );

      _lastDistance = distance;
      final radius = _currentEvent!.rangoPermitido;

      // Determinar estado de geofence
      GeofenceStatus newStatus;
      bool isInside;

      if (distance <= radius) {
        newStatus = GeofenceStatus.inside;
        isInside = true;
      } else if (distance <= radius * _approachingThreshold) {
        newStatus = GeofenceStatus.approaching;
        isInside = false;
      } else if (distance <= radius * _leavingThreshold && _currentStatus == GeofenceStatus.inside) {
        newStatus = GeofenceStatus.leaving;
        isInside = false;
      } else {
        newStatus = GeofenceStatus.outside;
        isInside = false;
      }

      // Verificar cambios de estado consistentes
      if (newStatus == _currentStatus) {
        _consecutiveStatusCount++;
      } else {
        _consecutiveStatusCount = 1;
      }

      // Solo cambiar estado después de verificaciones consecutivas
      if (_consecutiveStatusCount >= _minConsecutiveChecks && newStatus != _currentStatus) {
        final previousStatus = _currentStatus;
        _currentStatus = newStatus;
        
        await _handleStatusChange(previousStatus, newStatus, isInside);
      }

      // Enviar resultado actual
      final result = GeofenceResult(
        isInside: isInside,
        distance: distance,
        accuracy: position.accuracy,
        status: _currentStatus,
        timestamp: DateTime.now(),
      );

      _geofenceController.add(result);

    } catch (e) {
      logger.d('❌ Error verificando geofence: $e');
    }
  }

  /// 🔄 MANEJAR CAMBIO DE ESTADO
  Future<void> _handleStatusChange(
    GeofenceStatus previous, 
    GeofenceStatus current, 
    bool isInside
  ) async {
    logger.d('🎯 Cambio geofence: $previous → $current (dentro: $isInside)');

    // Notificaciones basadas en cambios de estado
    switch (current) {
      case GeofenceStatus.inside:
        if (previous == GeofenceStatus.outside || previous == GeofenceStatus.approaching) {
          await _notificationManager.showGeofenceEnteredNotification(
            _currentEvent?.titulo ?? 'Evento'
          );
        }
        break;
        
      case GeofenceStatus.outside:
        if (previous == GeofenceStatus.inside || previous == GeofenceStatus.leaving) {
          await _notificationManager.showGeofenceExitedNotification(
            _currentEvent?.titulo ?? 'Evento'
          );
        }
        break;
        
      case GeofenceStatus.approaching:
        if (previous == GeofenceStatus.outside) {
          // Notificación opcional de acercamiento
          logger.d('📍 Acercándose al evento');
        }
        break;
        
      case GeofenceStatus.leaving:
        if (previous == GeofenceStatus.inside) {
          await _notificationManager.showCriticalWarningNotification(
            'Alerta de Ubicación',
            'Estás saliendo del área del evento'
          );
        }
        break;
        
      default:
        break;
    }
  }

  /// 📊 VERIFICACIÓN INSTANTÁNEA
  Future<GeofenceResult?> checkCurrentGeofence(Evento event) async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) return null;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        event.ubicacion.latitud,
        event.ubicacion.longitud,
      );

      final isInside = distance <= event.rangoPermitido;
      
      GeofenceStatus status;
      if (isInside) {
        status = GeofenceStatus.inside;
      } else if (distance <= event.rangoPermitido * _approachingThreshold) {
        status = GeofenceStatus.approaching;
      } else {
        status = GeofenceStatus.outside;
      }

      return GeofenceResult(
        isInside: isInside,
        distance: distance,
        accuracy: position.accuracy,
        status: status,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      logger.d('❌ Error verificando geofence instantáneo: $e');
      return null;
    }
  }

  /// 📍 OBTENER ESTADO ACTUAL
  GeofenceStatus get currentStatus => _currentStatus;
  double get lastDistance => _lastDistance;
  Position? get lastPosition => _lastPosition;

  /// 🛑 DETENER GEOFENCING
  void stopGeofencing() {
    logger.d('🛑 Deteniendo geofencing local');
    
    _geofenceTimer?.cancel();
    _geofenceTimer = null;
    _currentEvent = null;
    _currentStatus = GeofenceStatus.unknown;
    _consecutiveStatusCount = 0;
  }

  /// 🧹 DISPOSE
  void dispose() {
    stopGeofencing();
    _geofenceController.close();
  }

  /// 🎯 UTILIDADES ESTÁTICAS
  
  /// Calcular distancia entre dos puntos
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Verificar si está dentro del radio
  static bool isInsideRadius(
    double lat1, double lon1,
    double lat2, double lon2,
    double radiusMeters,
  ) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusMeters;
  }

  /// Formatear distancia para mostrar
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Calcular porcentaje de proximidad
  static double calculateProximityPercentage(double distance, double radius) {
    if (distance >= radius) return 0.0;
    return ((radius - distance) / radius * 100).clamp(0.0, 100.0);
  }
}