// lib/services/firebase/hybrid_location_service.dart
// Servicio de ubicación híbrido que integra con el backend Node.js

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'hybrid_backend_service.dart';

class HybridLocationService {
  static final HybridLocationService _instance = HybridLocationService._internal();
  factory HybridLocationService() => _instance;
  HybridLocationService._internal();

  final HybridBackendService _backendService = HybridBackendService();
  
  StreamSubscription<Position>? _locationSubscription;
  Position? _lastKnownPosition;
  DateTime? _lastGeofenceCheck;
  
  bool _isTracking = false;
  bool _isInitialized = false;
  
  // Configuración de seguimiento
  static const Duration _locationUpdateInterval = Duration(seconds: 10);
  static const Duration _geofenceCheckInterval = Duration(seconds: 30);
  // Unused field _significantDistanceChange removed

  // Callbacks
  Function(Position)? onLocationUpdate;
  Function(Map<String, dynamic>)? onGeofenceResult;
  Function(String)? onError;
  Function(Map<String, dynamic>)? onAttendanceRegistered;

  // Getters
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// 🚀 INICIALIZAR SERVICIO DE UBICACIÓN
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Servicio de ubicación ya está inicializado');
      return;
    }

    try {
      debugPrint('🌍 Inicializando servicio de ubicación híbrido...');

      // 1. Verificar y solicitar permisos
      final permissionsGranted = await _requestLocationPermissions();
      if (!permissionsGranted) {
        throw Exception('Permisos de ubicación no concedidos');
      }

      // 2. Verificar que el servicio de ubicación esté habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Servicios de ubicación deshabilitados');
      }

      // 3. Obtener ubicación inicial
      _lastKnownPosition = await _getCurrentLocation();
      
      _isInitialized = true;
      debugPrint('✅ Servicio de ubicación inicializado correctamente');
      
    } catch (e) {
      debugPrint('❌ Error inicializando servicio de ubicación: $e');
      rethrow;
    }
  }

  /// 🔐 SOLICITAR PERMISOS DE UBICACIÓN
  Future<bool> _requestLocationPermissions() async {
    try {
      // Verificar permisos actuales
      LocationPermission permission = await Geolocator.checkPermission();
      
      // Solicitar permisos si es necesario
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Verificar permisos de fondo si está disponible
      if (Platform.isAndroid) {
        final backgroundLocationStatus = await Permission.locationAlways.status;
        if (backgroundLocationStatus.isDenied) {
          debugPrint('⚠️ Permisos de ubicación en segundo plano no concedidos');
          // Nota: En producción, podrías solicitar estos permisos aquí
        }
      }

      final isGranted = permission == LocationPermission.whileInUse || 
                       permission == LocationPermission.always;
      
      debugPrint('🔐 Permisos de ubicación: ${isGranted ? "✅ Concedidos" : "❌ Denegados"}');
      return isGranted;
      
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// 📍 OBTENER UBICACIÓN ACTUAL
  Future<Position> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación actual: $e');
      
      // Fallback: intentar con ubicación de menor precisión
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e2) {
        debugPrint('❌ Error en fallback de ubicación: $e2');
        rethrow;
      }
    }
  }

  /// 🎯 INICIAR SEGUIMIENTO DE UBICACIÓN CON GEOFENCING
  Future<void> startLocationTracking({
    bool enableBackgroundTracking = false,
    bool enableGeofencing = true,
  }) async {
    if (!_isInitialized) {
      throw Exception('Servicio no inicializado');
    }

    if (_isTracking) {
      debugPrint('⚠️ El seguimiento ya está activo');
      return;
    }

    try {
      debugPrint('🎯 Iniciando seguimiento de ubicación...');
      debugPrint('   - Geofencing: ${enableGeofencing ? "✅ Habilitado" : "❌ Deshabilitado"}');
      debugPrint('   - Segundo plano: ${enableBackgroundTracking ? "✅ Habilitado" : "❌ Deshabilitado"}');

      // Configuración de seguimiento
      final LocationSettings locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros
        intervalDuration: _locationUpdateInterval,
        foregroundNotificationConfig: enableBackgroundTracking
            ? const ForegroundNotificationConfig(
                notificationText: 'GeoAsist está monitoreando tu ubicación para el registro de asistencia',
                notificationTitle: 'Seguimiento de Asistencia Activo',
                enableWakeLock: true,
              )
            : null,
      );

      // Iniciar stream de ubicación
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _handleLocationUpdate,
        onError: (error) {
          debugPrint('❌ Error en stream de ubicación: $error');
          onError?.call(error.toString());
        },
      );

      _isTracking = true;
      debugPrint('✅ Seguimiento de ubicación iniciado');
      
    } catch (e) {
      debugPrint('❌ Error iniciando seguimiento: $e');
      rethrow;
    }
  }

  /// 📍 MANEJAR ACTUALIZACIÓN DE UBICACIÓN
  void _handleLocationUpdate(Position position) async {
    try {
      _lastKnownPosition = position;
      
      debugPrint('📍 Nueva ubicación: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (±${position.accuracy.toStringAsFixed(1)}m)');
      
      // Callback de actualización
      onLocationUpdate?.call(position);

      // Verificar si necesitamos hacer geofencing
      final shouldCheckGeofence = _shouldCheckGeofence(position);
      
      if (shouldCheckGeofence) {
        await _performGeofenceCheck(position);
      }
      
    } catch (e) {
      debugPrint('❌ Error procesando ubicación: $e');
      onError?.call(e.toString());
    }
  }

  /// 🎯 VERIFICAR SI DEBE HACER GEOFENCING
  bool _shouldCheckGeofence(Position position) {
    // Verificar intervalo de tiempo
    final now = DateTime.now();
    if (_lastGeofenceCheck != null) {
      final timeSinceLastCheck = now.difference(_lastGeofenceCheck!);
      if (timeSinceLastCheck < _geofenceCheckInterval) {
        return false; // Muy pronto para otra verificación
      }
    }

    // Verificar distancia significativa (opcional)
    // Este check podría omitirse para hacer geofencing más frecuente
    
    return true;
  }

  /// 🎯 REALIZAR VERIFICACIÓN DE GEOFENCING
  Future<void> _performGeofenceCheck(Position position) async {
    try {
      debugPrint('🎯 Realizando verificación de geofencing...');
      
      _lastGeofenceCheck = DateTime.now();
      
      // Enviar ubicación al backend para geofencing
      final result = await _backendService.sendLocationForGeofencing(position);
      
      debugPrint('📋 Resultado geofencing: ${result['success']}');
      
      // Callback con resultado
      onGeofenceResult?.call(result);
      
      // Si se registró asistencia automática, notificar
      if (result['success'] == true && result['resultados'] != null) {
        final resultados = result['resultados'] as List?;
        if (resultados != null && resultados.isNotEmpty) {
          for (final resultado in resultados) {
            if (resultado['accion'] == 'registrada') {
              onAttendanceRegistered?.call(resultado);
              debugPrint('🎉 Asistencia registrada automáticamente: ${resultado['eventoNombre']}');
            }
          }
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error en verificación de geofencing: $e');
      onError?.call('Error en geofencing: $e');
    }
  }

  /// ⏸️ PAUSAR SEGUIMIENTO
  Future<void> pauseLocationTracking() async {
    if (!_isTracking) {
      debugPrint('⚠️ El seguimiento no está activo');
      return;
    }

    await _locationSubscription?.cancel();
    _isTracking = false;
    
    debugPrint('⏸️ Seguimiento de ubicación pausado');
  }

  /// ▶️ REANUDAR SEGUIMIENTO
  Future<void> resumeLocationTracking() async {
    if (_isTracking) {
      debugPrint('⚠️ El seguimiento ya está activo');
      return;
    }

    await startLocationTracking();
  }

  /// ⏹️ DETENER SEGUIMIENTO
  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    _lastGeofenceCheck = null;
    
    debugPrint('⏹️ Seguimiento de ubicación detenido');
  }

  /// 🎯 VERIFICACIÓN MANUAL DE GEOFENCING
  Future<Map<String, dynamic>?> checkGeofenceManually() async {
    if (!_isInitialized) {
      throw Exception('Servicio no inicializado');
    }

    try {
      debugPrint('🎯 Verificación manual de geofencing...');
      
      // Obtener ubicación actual
      final position = await _getCurrentLocation();
      _lastKnownPosition = position;
      
      // Realizar verificación
      final result = await _backendService.sendLocationForGeofencing(position);
      
      debugPrint('📋 Resultado verificación manual: ${result['success']}');
      return result;
      
    } catch (e) {
      debugPrint('❌ Error en verificación manual: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 📊 OBTENER ESTADO DEL SERVICIO
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _isInitialized,
      'tracking': _isTracking,
      'lastPosition': _lastKnownPosition != null ? {
        'latitude': _lastKnownPosition!.latitude,
        'longitude': _lastKnownPosition!.longitude,
        'accuracy': _lastKnownPosition!.accuracy,
        'timestamp': _lastKnownPosition!.timestamp.toIso8601String(),
      } : null,
      'lastGeofenceCheck': _lastGeofenceCheck?.toIso8601String(),
      'locationServiceEnabled': null, // Se verificará de forma async
    };
  }

  /// 🧪 REALIZAR PRUEBA COMPLETA
  Future<Map<String, dynamic>> runLocationTest() async {
    debugPrint('🧪 Realizando prueba completa del servicio de ubicación...');
    
    final results = <String, dynamic>{};
    
    try {
      // 1. Verificar inicialización
      results['service_initialized'] = _isInitialized;
      
      // 2. Verificar permisos
      results['permissions_granted'] = await _requestLocationPermissions();
      
      // 3. Verificar servicio de ubicación
      results['location_service_enabled'] = await Geolocator.isLocationServiceEnabled();
      
      // 4. Obtener ubicación actual
      try {
        final position = await _getCurrentLocation();
        results['current_location'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
        results['location_obtained'] = true;
        
        // 5. Probar geofencing
        if (_backendService.isInitialized) {
          final geofenceResult = await _backendService.sendLocationForGeofencing(position);
          results['geofence_test'] = geofenceResult['success'] ?? false;
        } else {
          results['geofence_test'] = false;
          results['geofence_error'] = 'Backend service not initialized';
        }
        
      } catch (e) {
        results['location_obtained'] = false;
        results['location_error'] = e.toString();
      }
      
      // 6. Estado general
      results['overall_status'] = results['service_initialized'] == true &&
                                 results['permissions_granted'] == true &&
                                 results['location_service_enabled'] == true &&
                                 results['location_obtained'] == true;
      
    } catch (e) {
      results['test_error'] = e.toString();
      results['overall_status'] = false;
    }
    
    results['timestamp'] = DateTime.now().toIso8601String();
    debugPrint('🧪 Resultados prueba ubicación: $results');
    
    return results;
  }

  void dispose() {
    stopLocationTracking();
    _isInitialized = false;
    _lastKnownPosition = null;
    _lastGeofenceCheck = null;
  }
}

/// 🎯 CONFIGURACIÓN DE GEOFENCING
class GeofencingConfig {
  static const Duration defaultUpdateInterval = Duration(seconds: 10);
  static const Duration defaultGeofenceInterval = Duration(seconds: 30);
  static const double defaultDistanceFilter = 5.0;
  static const LocationAccuracy defaultAccuracy = LocationAccuracy.high;
  
  // Configuraciones por rol de usuario
  static const Map<String, Map<String, dynamic>> roleBasedSettings = {
    'estudiante': {
      'updateInterval': 10, // segundos
      'geofenceInterval': 30, // segundos
      'accuracy': LocationAccuracy.high,
      'distanceFilter': 5.0,
    },
    'profesor': {
      'updateInterval': 30, // menos frecuente
      'geofenceInterval': 60,
      'accuracy': LocationAccuracy.medium,
      'distanceFilter': 10.0,
    },
    'admin': {
      'updateInterval': 60, // mínimo tracking
      'geofenceInterval': 120,
      'accuracy': LocationAccuracy.medium,
      'distanceFilter': 20.0,
    },
  };
  
  static Map<String, dynamic> getSettingsForRole(String role) {
    return roleBasedSettings[role] ?? roleBasedSettings['estudiante']!;
  }
}