// lib/services/background_location_service.dart
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  static const String taskName = "locationTracking";

  /// Inicializa el servicio de background
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  /// Inicia tracking continuo para un evento específico
  Future<void> startEventTracking(String eventoId) async {
    try {
      // Guardar el evento que se está tracking
      // TODO: Guardar evento activo para persistencia

      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: const Duration(seconds: 30), // ✅ OPTIMIZADO PARA A1.1
        initialDelay: const Duration(seconds: 30),
        inputData: {
          'eventoId': eventoId,
          'action': 'trackLocation',
        },
      );

      debugPrint('📍 Tracking iniciado para evento: $eventoId');
    } catch (e) {
      debugPrint('Error iniciando tracking: $e');
    }
  }

  /// Detiene tracking cuando el evento termina
  Future<void> stopEventTracking() async {
    try {
      await Workmanager().cancelByUniqueName(taskName);
      debugPrint('📍 Tracking detenido');
    } catch (e) {
      debugPrint('Error deteniendo tracking: $e');
    }
  }

  /// Pausa tracking durante receso
  Future<void> pauseTracking() async {
    // Cambiar la lógica del tracking, no cancelar completamente
    await Workmanager().registerPeriodicTask(
      "${taskName}_paused",
      "${taskName}_paused",
      frequency: const Duration(minutes: 15),
      inputData: {
        'action': 'pausedMode',
      },
    );
  }

  /// Reanuda tracking después del receso
  Future<void> resumeTracking(String eventoId) async {
    await Workmanager().cancelByUniqueName("${taskName}_paused");
    await startEventTracking(eventoId);
  }
}

/// Callback que se ejecuta en background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('📍 Background task ejecutándose: $task');

      switch (inputData?['action']) {
        case 'trackLocation':
          await _trackUserLocation(inputData?['eventoId']);
          break;
        case 'pausedMode':
          debugPrint('📍 Modo pausado - no verificando ubicación');
          break;
        default:
          debugPrint('📍 Acción desconocida: ${inputData?['action']}');
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Error en background task: $e');
      return Future.value(false);
    }
  });
}

/// Función que ejecuta el tracking real
Future<void> _trackUserLocation(String? eventoId) async {
  if (eventoId == null) return;

  try {
    // 1. Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('❌ Sin permisos de ubicación en background');
      return;
    }

    // 2. Obtener ubicación actual
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // 3. Enviar al backend
    final apiService = ApiService();
    final storageService = StorageService();

    final user = await storageService.getUser();
    if (user == null) return;

    final response = await apiService.post(
      AppConstants.locationEndpoint,
      body: {
        'userId': user.id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'eventoId': eventoId,
        'backgroundUpdate': true, // Indicar que es update de background
      },
    );

    if (response.success) {
      debugPrint('📍 Ubicación enviada desde background');

      // 4. Verificar si salió del perímetro
      final data = response.data;
      if (data != null && data['insideGeofence'] == false) {
        debugPrint(
            '⚠️ Usuario salió del perímetro - iniciando período de gracia');
        // Aquí podríamos enviar una notificación
      }
    }
  } catch (e) {
    debugPrint('❌ Error en tracking background: $e');
  }
}
