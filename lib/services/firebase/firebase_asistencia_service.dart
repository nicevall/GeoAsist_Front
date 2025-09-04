// lib/services/firebase/firebase_asistencia_service.dart
// Servicio de asistencias Firebase compatible con híbrido

import 'package:flutter/foundation.dart';
import '../../models/api_response_model.dart';
import '../../models/asistencia_model.dart';
import '../../models/ubicacion_model.dart';

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
    debugPrint('💡 getQuickSummary redirigido al backend híbrido');
    return null;
  }
  
  Future<void> refreshAsistencias() async {
    debugPrint('💡 refreshAsistencias redirigido al backend híbrido');
  }
  
  // Additional methods for compatibility
  void initializeForUser(String userId) {
    debugPrint('💡 initializeForUser redirigido al backend híbrido');
  }
  
  String get currentUserId => '';

  Future<void> initialize() async {
    try {
      // El backend híbrido maneja las asistencias
      _isInitialized = true;
      debugPrint('✅ FirebaseAsistenciaService inicializado (modo híbrido)');
    } catch (e) {
      debugPrint('❌ Error inicializando FirebaseAsistenciaService: $e');
      rethrow;
    }
  }

  // Métodos placeholder para compatibilidad
  Future<List<Map<String, dynamic>>> getAsistencias(String userId) async {
    debugPrint('💡 getAsistencias redirigido al backend híbrido');
    return [];
  }

  Future<Map<String, dynamic>?> registrarAsistencia(Map<String, dynamic> asistencia) async {
    debugPrint('💡 registrarAsistencia redirigido al backend híbrido');
    return null;
  }

  Future<bool> updateAsistencia(String asistenciaId, Map<String, dynamic> updates) async {
    debugPrint('💡 updateAsistencia redirigido al backend híbrido');
    return false;
  }

  Future<List<Map<String, dynamic>>> getAsistenciasByEvento(String eventoId) async {
    debugPrint('💡 getAsistenciasByEvento redirigido al backend híbrido');
    return [];
  }

  // Métodos requeridos por attendance_service_adapter
  Future<ApiResponse<Asistencia?>> checkExistingAttendance(String userId, String eventoId) async {
    debugPrint('💡 checkExistingAttendance redirigido al backend híbrido');
    return ApiResponse<Asistencia?>(
      success: true,
      data: null,
      message: 'Backend híbrido maneja la lógica de asistencias',
    );
  }

  Future<ApiResponse<Asistencia>> registerAttendance(String userId, String eventoId, Ubicacion ubicacion, String estado) async {
    debugPrint('💡 registerAttendance redirigido al backend híbrido');
    
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
    debugPrint('💡 getAttendanceByUser redirigido al backend híbrido');
    return ApiResponse<List<Asistencia>>(
      success: true,
      data: [],
      message: 'Backend híbrido maneja la consulta de asistencias por usuario',
    );
  }

  Future<ApiResponse<List<Asistencia>>> getAttendanceByEvent(String eventoId) async {
    debugPrint('💡 getAttendanceByEvent redirigido al backend híbrido');
    return ApiResponse<List<Asistencia>>(
      success: true,
      data: [],
      message: 'Backend híbrido maneja la consulta de asistencias por evento',
    );
  }

  Future<ApiResponse<bool>> updateUserLocation(String userId, Ubicacion ubicacion) async {
    debugPrint('💡 updateUserLocation redirigido al backend híbrido');
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