// lib/services/firebase/firebase_geofencing_service.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'firestore_service.dart';

class FirebaseGeofencingService {
  static final FirebaseGeofencingService _instance = FirebaseGeofencingService._internal();
  factory FirebaseGeofencingService() => _instance;
  FirebaseGeofencingService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  
  // Estado del servicio
  bool _isMonitoring = false;
  Timer? _locationTimer;
  String? _currentUserId;
  List<EventoGeofence> _activeGeofences = [];

  // Callbacks
  Function(String eventoId, DetectionResult result)? onGeofenceEnter;
  Function(String eventoId, DetectionResult result)? onGeofenceExit;
  Function(Position position)? onLocationUpdate;
  Function(String error)? onError;

  bool get isMonitoring => _isMonitoring;
  List<EventoGeofence> get activeGeofences => _activeGeofences;

  // 🚀 INICIAR MONITOREO DE GEOFENCES
  Future<void> startMonitoring(String userId) async {
    if (_isMonitoring) {
      logger.d('⚠️ Geofencing ya está activo');
      return;
    }

    try {
      _currentUserId = userId;
      await _loadActiveGeofences();
      _startLocationTracking();
      _isMonitoring = true;
      
      logger.d('✅ Monitoreo de geofences iniciado para usuario: $userId');
    } catch (e) {
      logger.d('❌ Error iniciando monitoreo: $e');
      onError?.call('Error iniciando geofencing: $e');
    }
  }

  // 🛑 DETENER MONITOREO
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _locationTimer?.cancel();
    _activeGeofences.clear();
    _currentUserId = null;
    
    logger.d('🛑 Monitoreo de geofences detenido');
  }

  // 📍 TRACKING DE UBICACIÓN
  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateLocation();
    });
    
    // Primera actualización inmediata
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    if (!_isMonitoring || _currentUserId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Position updated successfully
      onLocationUpdate?.call(position);

      // Actualizar ubicación en Firestore (dispara Cloud Function)
      await _firestoreService.updateUbicacionTiempoReal(
        _currentUserId!,
        position.latitude,
        position.longitude,
      );

      // Verificar geofences localmente también
      await _checkAllGeofences(position);
      
    } catch (e) {
      logger.d('❌ Error actualizando ubicación: $e');
      onError?.call('Error obteniendo ubicación: $e');
    }
  }

  // 🎯 CARGAR GEOFENCES ACTIVOS
  Future<void> _loadActiveGeofences() async {
    try {
      final geofences = await _firestoreService.getGeofencesActivos();
      _activeGeofences = geofences.map((data) => EventoGeofence.fromMap(data)).toList();
      logger.d('📊 Cargados ${_activeGeofences.length} geofences activos');
    } catch (e) {
      logger.d('❌ Error cargando geofences: $e');
    }
  }

  // 🔍 VERIFICAR TODOS LOS GEOFENCES
  Future<void> _checkAllGeofences(Position position) async {
    for (final geofence in _activeGeofences) {
      final result = await _processGeofence(position, geofence);
      
      // Solo notificar cambios de estado significativos
      if (result.stateChanged) {
        if (result.isInside) {
          onGeofenceEnter?.call(geofence.eventoId, result);
        } else {
          onGeofenceExit?.call(geofence.eventoId, result);
        }
      }
    }
  }

  // 🧠 PROCESAMIENTO INTELIGENTE DE GEOFENCE
  Future<DetectionResult> _processGeofence(Position position, EventoGeofence geofence) async {
    final userId = _currentUserId!;
    
    // 1. ALGORITMO ESTRICTO
    final strict = await _strictAlgorithm(position, geofence);
    
    // 2. ALGORITMO RELAJADO
    final relaxed = await _relaxedAlgorithm(position, geofence);
    
    // 3. ALGORITMO ADAPTATIVO
    final adaptive = await _adaptiveAlgorithm(position, geofence, userId);
    
    // 4. ALGORITMO ML-ENHANCED
    final mlEnhanced = await _mlEnhancedAlgorithm(position, geofence, userId);

    // CONSENSO DE ALGORITMOS
    final algorithms = [strict, relaxed, adaptive, mlEnhanced];
    final insideCount = algorithms.where((a) => a.isInside).length;
    final avgConfidence = algorithms.map((a) => a.confidence).reduce((a, b) => a + b) / 4;
    
    final finalResult = DetectionResult(
      isInside: insideCount >= 2 && avgConfidence >= 0.6, // Consenso de mayoría
      confidence: avgConfidence,
      distance: strict.distance,
      algorithm: 'consensus',
      stateChanged: geofence.lastDetection?.isInside != (insideCount >= 2),
      details: {
        'strict': strict.toMap(),
        'relaxed': relaxed.toMap(),
        'adaptive': adaptive.toMap(),
        'ml_enhanced': mlEnhanced.toMap(),
        'consensus_count': insideCount,
        'avg_confidence': avgConfidence,
      },
    );

    // Actualizar último resultado
    geofence.lastDetection = finalResult;
    
    return finalResult;
  }

  // 🎯 ALGORITMO ESTRICTO
  Future<DetectionResult> _strictAlgorithm(Position position, EventoGeofence geofence) async {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      geofence.centro.latitud,
      geofence.centro.longitud,
    );

    return DetectionResult(
      isInside: distance <= geofence.radio,
      confidence: distance <= geofence.radio ? 1.0 : 0.0,
      distance: distance,
      algorithm: 'strict',
      stateChanged: false, // Se calcula en el nivel superior
    );
  }

  // 🎯 ALGORITMO RELAJADO (+20% TOLERANCIA)
  Future<DetectionResult> _relaxedAlgorithm(Position position, EventoGeofence geofence) async {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      geofence.centro.latitud,
      geofence.centro.longitud,
    );

    final relaxedRadius = geofence.radio * 1.2;
    final confidence = max(0.0, 1.0 - (distance / relaxedRadius));

    return DetectionResult(
      isInside: distance <= relaxedRadius,
      confidence: confidence,
      distance: distance,
      algorithm: 'relaxed',
      stateChanged: false,
    );
  }

  // 🎯 ALGORITMO ADAPTATIVO (SEGÚN GPS ACCURACY)
  Future<DetectionResult> _adaptiveAlgorithm(
    Position position, 
    EventoGeofence geofence, 
    String userId,
  ) async {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      geofence.centro.latitud,
      geofence.centro.longitud,
    );

    // Ajustar radio según precisión GPS
    double adaptedRadius = geofence.radio;
    final gpsAccuracy = position.accuracy;
    
    if (gpsAccuracy > 20) {
      adaptedRadius *= 1.5; // GPS impreciso = más tolerante
    } else if (gpsAccuracy < 5) {
      adaptedRadius *= 0.9; // GPS preciso = más estricto
    }

    // Factor de confianza considerando GPS accuracy
    final confidence = max(0.0, 1.0 - (distance / (adaptedRadius + gpsAccuracy)));

    return DetectionResult(
      isInside: distance <= adaptedRadius,
      confidence: confidence,
      distance: distance,
      algorithm: 'adaptive',
      stateChanged: false,
      details: {
        'gps_accuracy': gpsAccuracy,
        'adapted_radius': adaptedRadius,
        'original_radius': geofence.radio,
      },
    );
  }

  // 🤖 ALGORITMO ML-ENHANCED (CON HISTORIAL)
  Future<DetectionResult> _mlEnhancedAlgorithm(
    Position position,
    EventoGeofence geofence,
    String userId,
  ) async {
    final adaptiveResult = await _adaptiveAlgorithm(position, geofence, userId);
    
    double behaviorScore = 0.5; // Score base
    
    try {
      // Obtener historial de asistencias del usuario
      final asistencias = await _firestoreService.getAsistenciasUsuario(userId);
      
      if (asistencias.isNotEmpty) {
        // Calcular score de comportamiento
        final onTimeCount = asistencias.where((a) => 
          a['estado'] == 'presente_a_tiempo' || a['estado'] == 'presente_temprano'
        ).length;
        
        behaviorScore = onTimeCount / asistencias.length;
      }
    } catch (e) {
      logger.d('⚠️ Error obteniendo historial de asistencias: $e');
      // Mantener el score base de 0.5
    }

    // Combinar detección geográfica (70%) + comportamiento histórico (30%)
    final finalConfidence = (adaptiveResult.confidence * 0.7) + (behaviorScore * 0.3);

    return DetectionResult(
      isInside: adaptiveResult.isInside,
      confidence: finalConfidence,
      distance: adaptiveResult.distance,
      algorithm: 'ml_enhanced',
      stateChanged: false,
      details: {
        ...adaptiveResult.details ?? {},
        'behavior_score': behaviorScore,
        'base_confidence': adaptiveResult.confidence,
        'final_confidence': finalConfidence,
      },
    );
  }

  // 🎯 VERIFICACIÓN MANUAL DE GEOFENCE
  Future<DetectionResult?> checkGeofenceForEvent(String eventoId, Position position) async {
    final geofence = _activeGeofences.where((g) => g.eventoId == eventoId).firstOrNull;
    if (geofence == null) return null;

    return await _processGeofence(position, geofence);
  }

  // 🔄 REFRESCAR GEOFENCES
  Future<void> refreshGeofences() async {
    await _loadActiveGeofences();
  }

  void dispose() {
    stopMonitoring();
  }
}

// 📊 MODELOS PARA GEOFENCING

class EventoGeofence {
  final String eventoId;
  final GeofenceCenter centro;
  final double radio;
  final bool isActive;
  DetectionResult? lastDetection;

  EventoGeofence({
    required this.eventoId,
    required this.centro,
    required this.radio,
    required this.isActive,
    this.lastDetection,
  });

  factory EventoGeofence.fromMap(Map<String, dynamic> map) {
    return EventoGeofence(
      eventoId: map['eventoId'] ?? '',
      centro: GeofenceCenter.fromMap(map['centro'] ?? {}),
      radio: (map['radio'] as num?)?.toDouble() ?? 100.0,
      isActive: map['isActive'] ?? false,
    );
  }
}

class GeofenceCenter {
  final double latitud;
  final double longitud;

  GeofenceCenter({
    required this.latitud,
    required this.longitud,
  });

  factory GeofenceCenter.fromMap(Map<String, dynamic> map) {
    return GeofenceCenter(
      latitud: (map['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (map['longitud'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DetectionResult {
  final bool isInside;
  final double confidence;
  final double distance;
  final String algorithm;
  final bool stateChanged;
  final Map<String, dynamic>? details;

  DetectionResult({
    required this.isInside,
    required this.confidence,
    required this.distance,
    required this.algorithm,
    required this.stateChanged,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'isInside': isInside,
      'confidence': confidence,
      'distance': distance,
      'algorithm': algorithm,
      'stateChanged': stateChanged,
      'details': details,
    };
  }

  @override
  String toString() {
    return 'DetectionResult(isInside: $isInside, confidence: ${confidence.toStringAsFixed(2)}, '
           'distance: ${distance.toStringAsFixed(1)}m, algorithm: $algorithm)';
  }
}