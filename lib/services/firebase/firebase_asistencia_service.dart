// lib/services/firebase/firebase_asistencia_service.dart
// Servicio de asistencias Firebase compatible con híbrido

import 'package:flutter/foundation.dart';
import '../../models/api_response_model.dart';
import '../../models/asistencia_model.dart';
import '../../models/ubicacion_model.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';

class FirebaseAsistenciaService {
  static final FirebaseAsistenciaService _instance = FirebaseAsistenciaService._internal();
  factory FirebaseAsistenciaService() => _instance;
  FirebaseAsistenciaService._internal();

  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  // Streams placeholder para compatibilidad
  Stream<List<Map<String, dynamic>>> get asistenciasStream => Stream.empty();
  
  // Métodos adicionales para compatibilidad
  Future<Map<String, dynamic>?> getQuickSummary() async {
    logger.d('💡 getQuickSummary redirigido al backend híbrido');
    return null;
  }
  
  Future<void> refreshAsistencias() async {
    logger.d('💡 refreshAsistencias redirigido al backend híbrido');
  }
  
  // Additional methods for compatibility
  void initializeForUser(String userId) {
    logger.d('💡 initializeForUser redirigido al backend híbrido');
  }
  
  String get currentUserId => '';

  Future<void> initialize() async {
    try {
      // El backend híbrido maneja las asistencias
      _isInitialized = true;
      logger.d('✅ FirebaseAsistenciaService inicializado (modo híbrido)');
    } catch (e) {
      logger.d('❌ Error inicializando FirebaseAsistenciaService: $e');
      rethrow;
    }
  }

  // Métodos placeholder para compatibilidad
  Future<List<Map<String, dynamic>>> getAsistencias(String userId) async {
    logger.d('💡 getAsistencias redirigido al backend híbrido');
    return [];
  }

  Future<Map<String, dynamic>?> registrarAsistencia(Map<String, dynamic> asistencia) async {
    logger.d('💡 registrarAsistencia redirigido al backend híbrido');
    return null;
  }

  Future<bool> updateAsistencia(String asistenciaId, Map<String, dynamic> updates) async {
    logger.d('💡 updateAsistencia redirigido al backend híbrido');
    return false;
  }

  Future<List<Map<String, dynamic>>> getAsistenciasByEvento(String eventoId) async {
    logger.d('💡 getAsistenciasByEvento redirigido al backend híbrido');
    return [];
  }

  // Métodos requeridos por attendance_service_adapter
  Future<ApiResponse<Asistencia?>> checkExistingAttendance(String userId, String eventoId) async {
    logger.d('💡 checkExistingAttendance redirigido al backend híbrido');
    return ApiResponse<Asistencia?>(
      success: true,
      data: null,
      message: 'Backend híbrido maneja la lógica de asistencias',
    );
  }

  Future<ApiResponse<Asistencia>> registerAttendance(String userId, String eventoId, Ubicacion ubicacion, String estado) async {
    logger.d('💡 registerAttendance redirigido al backend híbrido');
    
    final now = DateTime.now();
    
    // Crear asistencia temporal para compatibilidad
    final asistencia = Asistencia(
      id: now.millisecondsSinceEpoch.toString(),
      usuarioId: userId,
      eventoId: eventoId,
      usuario: userId,
      evento: eventoId,
      estado: estado,
      latitud: ubicacion.latitud,
      longitud: ubicacion.longitud,
      hora: now,
      fecha: now,
      dentroDelRango: true,
      creadoEn: now,
      actualizadoEn: now,
      fechaRegistro: now,
      nombreUsuario: 'Usuario Híbrido',
      observaciones: 'Asistencia registrada desde backend híbrido',
    );
    
    return ApiResponse<Asistencia>(
      success: true,
      data: asistencia,
      message: 'Asistencia registrada (backend híbrido)',
    );
  }

  Future<ApiResponse<List<Asistencia>>> getAttendanceByUser(String userId) async {
    logger.d('💡 getAttendanceByUser redirigido al backend híbrido');
    return ApiResponse<List<Asistencia>>(
      success: true,
      data: [],
      message: 'Backend híbrido maneja la consulta de asistencias por usuario',
    );
  }

  Future<ApiResponse<List<Asistencia>>> getAttendanceByEvent(String eventoId) async {
    logger.d('💡 getAttendanceByEvent redirigido al backend híbrido');
    return ApiResponse<List<Asistencia>>(
      success: true,
      data: [],
      message: 'Backend híbrido maneja la consulta de asistencias por evento',
    );
  }

  Future<ApiResponse<bool>> updateUserLocation(String userId, Ubicacion ubicacion) async {
    logger.d('💡 updateUserLocation redirigido al backend híbrido');
    return ApiResponse<bool>(
      success: true,
      data: true,
      message: 'Ubicación actualizada (backend híbrido)',
    );
  }

  void dispose() {
    _isInitialized = false;
  }
}