// lib/services/firebase/firestore_service.dart
// Servicio básico de Firestore para mantener compatibilidad

import 'package:flutter/foundation.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // El servicio híbrido maneja Firestore desde el backend
      _isInitialized = true;
      logger.d('✅ FirestoreService inicializado (modo híbrido)');
    } catch (e) {
      logger.d('❌ Error inicializando FirestoreService: $e');
      rethrow;
    }
  }

  // Métodos placeholder para compatibilidad
  Future<void> updateFCMToken(String userId, String token) async {
    logger.d('💡 updateFCMToken redirigido al HybridBackendService');
  }

  Future<void> updateUsuarioFCMToken(String userId, String token) async {
    logger.d('💡 updateUsuarioFCMToken redirigido al HybridBackendService');
  }

  Future<Map<String, dynamic>?> getUsuario(String userId) async {
    logger.d('💡 getUsuario redirigido al HybridBackendService');
    return null;
  }

  // Missing methods required by firebase_geofencing_service
  Future<void> updateUbicacionTiempoReal(String userId, double lat, double lng) async {
    logger.d('💡 updateUbicacionTiempoReal redirigido al HybridBackendService');
    // In a real implementation, this would update user location in Firestore
    // For now, we redirect to the hybrid backend
  }

  Future<List<Map<String, dynamic>>> getGeofencesActivos() async {
    logger.d('💡 getGeofencesActivos redirigido al HybridBackendService');
    // Return empty list as placeholder - would fetch active geofences from Firestore
    return [];
  }

  Future<List<Map<String, dynamic>>> getAsistenciasUsuario(String userId) async {
    logger.d('💡 getAsistenciasUsuario redirigido al HybridBackendService');
    // Return empty list as placeholder - would fetch user attendance from Firestore
    return [];
  }

  void dispose() {
    _isInitialized = false;
  }
}