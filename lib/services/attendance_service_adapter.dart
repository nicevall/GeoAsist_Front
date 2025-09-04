// lib/services/attendance_service_adapter.dart
// Adapter to bridge old service interfaces with new Firebase services

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api_response_model.dart';
import '../models/asistencia_model.dart';
import '../models/evento_model.dart';
import '../models/ubicacion_model.dart';
import 'firebase/firebase_asistencia_service.dart';
import 'firebase/firebase_evento_service.dart';

/// Service adapter that provides the old interface while using new Firebase services
class AsistenciaService {
  final FirebaseAsistenciaService _firebaseAsistencia = FirebaseAsistenciaService();
  
  // Method expected by attendance_tracking_manager.dart
  Future<ApiResponse<Asistencia?>> checkExistingAttendance(String userId, String eventoId) async {
    try {
      final response = await _firebaseAsistencia.checkExistingAttendance(userId, eventoId);
      
      if (response.success) {
        return ApiResponse<Asistencia?>(
          success: true,
          data: response.data,
          message: response.message,
        );
      } else {
        return ApiResponse<Asistencia?>(
          success: false,
          message: response.errorMessage ?? 'Error verificando asistencia',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en checkExistingAttendance adapter: $e');
      return ApiResponse<Asistencia?>(
        success: false,
        message: 'Error verificando asistencia: $e',
      );
    }
  }

  // Method expected by attendance_tracking_manager.dart  
  Future<ApiResponse<Asistencia>> registerAttendance(
    String userId,
    String eventoId,
    double latitude,
    double longitude,
  ) async {
    try {
      // Create Ubicacion object from coordinates
      final ubicacion = Ubicacion(
        latitud: latitude,
        longitud: longitude,
      );
      
      final response = await _firebaseAsistencia.registerAttendance(
        userId,
        eventoId,
        ubicacion,
        'presente_a_tiempo', // Default attendance state
      );
      
      if (response.success && response.data != null) {
        return ApiResponse<Asistencia>(
          success: true,
          data: response.data!,
          message: response.message,
        );
      } else {
        return ApiResponse<Asistencia>(
          success: false,
          message: response.errorMessage ?? 'Error registrando asistencia',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en registerAttendance adapter: $e');
      return ApiResponse<Asistencia>(
        success: false,
        message: 'Error registrando asistencia: $e',
      );
    }
  }

  // Method expected by attendance_tracking_manager.dart
  Future<ApiResponse<List<Asistencia>>> getAttendanceByUser(String userId) async {
    try {
      final response = await _firebaseAsistencia.getAttendanceByUser(userId);
      
      if (response.success && response.data != null) {
        return ApiResponse<List<Asistencia>>(
          success: true,
          data: response.data!,
          message: response.message,
        );
      } else {
        return ApiResponse<List<Asistencia>>(
          success: false,
          message: response.errorMessage ?? 'Error obteniendo asistencias',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en getAttendanceByUser adapter: $e');
      return ApiResponse<List<Asistencia>>(
        success: false,
        message: 'Error obteniendo asistencias: $e',
      );
    }
  }

  // Additional methods for backward compatibility
  Future<ApiResponse<List<Asistencia>>> getAttendanceByEvent(String eventoId) async {
    try {
      final response = await _firebaseAsistencia.getAttendanceByEvent(eventoId);
      
      if (response.success && response.data != null) {
        return ApiResponse<List<Asistencia>>(
          success: true,
          data: response.data!,
          message: response.message,
        );
      } else {
        return ApiResponse<List<Asistencia>>(
          success: false,
          message: response.errorMessage ?? 'Error obteniendo asistencias del evento',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en getAttendanceByEvent adapter: $e');
      return ApiResponse<List<Asistencia>>(
        success: false,
        message: 'Error obteniendo asistencias del evento: $e',
      );
    }
  }

  // Method expected for location updates
  Future<ApiResponse<void>> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    try {
      // Create Ubicacion object from coordinates
      final ubicacion = Ubicacion(
        latitud: latitude,
        longitud: longitude,
      );
      
      final response = await _firebaseAsistencia.updateUserLocation(
        userId,
        ubicacion,
      );
      
      if (response.success) {
        return ApiResponse<void>(
          success: true,
          message: response.message,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.errorMessage ?? 'Error actualizando ubicación',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en updateUserLocation adapter: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Error actualizando ubicación: $e',
      );
    }
  }
}

/// Service adapter for EventoService
class EventoService {
  final FirebaseEventoService _firebaseEvento = FirebaseEventoService();
  
  // Method expected by attendance_tracking_manager.dart
  Future<ApiResponse<Evento?>> getEventoById(String eventoId) async {
    try {
      final response = await _firebaseEvento.getEventoById(eventoId);
      
      if (response != null && response.success) {
        return ApiResponse<Evento?>(
          success: true,
          data: response.data,
          message: response.message,
        );
      } else {
        return ApiResponse<Evento?>(
          success: false,
          message: response?.errorMessage ?? 'Error obteniendo evento',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en getEventoById adapter: $e');
      return ApiResponse<Evento?>(
        success: false,
        message: 'Error obteniendo evento: $e',
      );
    }
  }

  // Method expected by attendance_tracking_manager.dart
  Future<ApiResponse<Evento?>> getActiveEvent() async {
    try {
      final response = await _firebaseEvento.getActiveEvent();
      
      if (response != null && response.success) {
        return ApiResponse<Evento?>(
          success: true,
          data: response.data,
          message: response.message,
        );
      } else {
        return ApiResponse<Evento?>(
          success: false,
          message: response?.errorMessage ?? 'No hay eventos activos',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en getActiveEvent adapter: $e');
      return ApiResponse<Evento?>(
        success: false,
        message: 'Error obteniendo evento activo: $e',
      );
    }
  }
}