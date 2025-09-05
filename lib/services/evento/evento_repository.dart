// lib/services/evento/evento_repository.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/api_response_model.dart';
import '../api_service.dart';

/// ✅ REPOSITORY: Capa de acceso a datos del backend
/// Responsabilidades:
/// - Llamadas HTTP al backend
/// - Manejo de errores de red
/// - Retry logic y timeouts
/// - Parsing inicial de responses
class EventoRepository {
  static final EventoRepository _instance = EventoRepository._internal();
  factory EventoRepository() => _instance;
  EventoRepository._internal();

  final ApiService _apiService = ApiService();

  // ⚙️ CONFIGURACIÓN DE RETRY

  /// ✅ GET /eventos - Obtener todos los eventos del backend
  Future<List<dynamic>> fetchAllEvents() async {
    logger.d('🌐 API GET: /eventos');

    try {
      final response = await _apiService.get('/eventos');

      logger.d('📊 Status Code: ${response.success ? 'Success' : 'Error'}');
      logger.d('✅ Response data available: ${response.data != null}');

      if (response.success) {
        final data = response.data;
        
        logger.d('📡 Events response success: ${response.success}');
        logger.d('📄 Events response data available: ${data != null}');

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final eventsList = data['data'];
          if (eventsList is List) {
            logger.d('✅ Found array in "data": ${eventsList.length} events');
            return eventsList;
          }
        } else if (data is List) {
          final dataList = data as List<dynamic>;
          logger.d('✅ Found array: ${dataList.length} events');
          return dataList;
        }
        
        logger.d('⚠️ No events array found in response');
        return [];
      } else {
        throw Exception('API Error: ${response.message}');
      }
    } catch (e) {
      logger.d('❌ Error fetching events: $e');
      throw _handleApiError(e);
    }
  }

  /// ✅ GET /eventos/:id - Obtener evento específico
  Future<Map<String, dynamic>?> fetchEventById(String eventoId) async {
    logger.d('🔍 Fetching event by ID: $eventoId');

    try {
      final response = await _apiService.get('/eventos/$eventoId');

      logger.d('📊 Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          logger.d('✅ Event found: ${data['nombre'] ?? data['titulo'] ?? 'Unknown'}');
          return data;
        }
      }
      
      logger.d('❌ Event not found or invalid response');
      return null;
    } catch (e) {
      logger.d('❌ Error fetching event $eventoId: $e');
      throw _handleApiError(e);
    }
  }

  /// ✅ GET /eventos/profesor/:id - Eventos del profesor
  Future<List<dynamic>> fetchEventsByTeacher(String profesorId) async {
    logger.d('👩‍🏫 Fetching events for teacher: $profesorId');

    try {
      final response = await _apiService.get('/eventos/mis');

      logger.d('📊 Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        final data = response.data;
        if (data is List) {
          final dataList = data as List<dynamic>;
          logger.d('✅ Teacher events found: ${dataList.length}');
          
          // 🔍 DEBUG: Log estados de todos los eventos
          logger.d('🔍 DEBUGGING EVENT STATES FROM BACKEND:');
          for (int i = 0; i < dataList.length; i++) {
            final event = dataList[i];
            if (event is Map<String, dynamic>) {
              final nombre = event['nombre'] ?? event['titulo'] ?? 'Unknown';
              final estado = event['estado'] ?? 'No estado';
              final id = event['_id'] ?? event['id'] ?? 'No ID';
              logger.d('🔍 Event $i: "$nombre" (ID: $id) - Estado: "$estado"');
            }
          }
          logger.d('🔍 END EVENT STATES DEBUG');
          
          return dataList;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          final eventsList = data['data'];
          if (eventsList is List) {
            logger.d('✅ Teacher events found in data: ${eventsList.length}');
            return eventsList;
          }
        }
      }
      
      logger.d('⚠️ No events found for teacher');
      return [];
    } catch (e) {
      logger.d('❌ Error fetching teacher events: $e');
      throw _handleApiError(e);
    }
  }

  /// ✅ POST /eventos - Crear nuevo evento
  Future<ApiResponse<Map<String, dynamic>>> createEvent(Map<String, dynamic> eventoData) async {
    logger.d('🆕 Creating new event: ${eventoData['nombre'] ?? eventoData['titulo']}');

    try {
      final response = await _apiService.post('/eventos/crear', body: eventoData);

      logger.d('📊 Create Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        logger.d('✅ Event created successfully');
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data,
          message: response.message,
        );
      } else {
        logger.d('❌ Event creation failed: ${response.message}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      logger.d('❌ Error creating event: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  /// ✅ PUT /eventos/:id - Editar evento existente
  Future<ApiResponse<Map<String, dynamic>>> updateEvent(String eventoId, Map<String, dynamic> eventoData) async {
    logger.d('✏️ Updating event: $eventoId');

    try {
      final response = await _apiService.put('/eventos/$eventoId', body: eventoData);

      logger.d('📊 Update Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        logger.d('✅ Event updated successfully');
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data,
          message: response.message,
        );
      } else {
        logger.d('❌ Event update failed: ${response.message}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      logger.d('❌ Error updating event: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  /// ✅ DELETE /eventos/:id - Soft delete evento
  Future<ApiResponse<bool>> deleteEvent(String eventoId) async {
    logger.d('🗑️ Soft deleting event: $eventoId');

    try {
      final response = await _apiService.delete('/eventos/$eventoId');

      logger.d('📊 Delete Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        logger.d('✅ Event soft deleted successfully');
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: response.message,
        );
      } else {
        logger.d('❌ Event deletion failed: ${response.message}');
        return ApiResponse<bool>(
          success: false,
          data: false,
          message: response.message,
        );
      }
    } catch (e) {
      logger.d('❌ Error deleting event: $e');
      return ApiResponse<bool>(
        success: false,
        data: false,
        message: _getErrorMessage(e),
      );
    }
  }

  /// ✅ PUT /eventos/:id/toggle - Toggle estado activo
  Future<bool> toggleEventActive(String eventoId, bool isActive) async {
    logger.d('🔄 Toggling event active state: $eventoId → $isActive');

    try {
      final response = await _apiService.put('/eventos/$eventoId/toggle', body: {'isActive': isActive});

      logger.d('📊 Toggle Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        logger.d('✅ Event state toggled successfully');
        return true;
      } else {
        logger.d('❌ Event toggle failed: ${response.message}');
        return false;
      }
    } catch (e) {
      logger.d('❌ Error toggling event state: $e');
      return false;
    }
  }

  /// ✅ GET /eventos/:id/metrics - Métricas del evento
  Future<Map<String, dynamic>?> fetchEventMetrics(String eventoId) async {
    logger.d('📊 Fetching metrics for event: $eventoId');

    try {
      final response = await _apiService.get('/dashboard/metrics/event/$eventoId');

      logger.d('📊 Metrics Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          logger.d('✅ Event metrics found');
          return data;
        }
      }
      
      logger.d('⚠️ No metrics found for event');
      return null;
    } catch (e) {
      logger.d('❌ Error fetching event metrics: $e');
      return null;
    }
  }

  /// ✅ GET /eventos/publicos - Eventos públicos para estudiantes
  Future<List<dynamic>> fetchPublicEvents() async {
    logger.d('🎓 Fetching public events for students');

    try {
      final response = await _apiService.get('/eventos');

      logger.d('📊 Public Events Status Code: ${response.success ? 'Success' : 'Error'}');

      if (response.success) {
        final data = response.data;
        if (data is List) {
          final dataList = data as List<dynamic>;
          logger.d('✅ Public events found: ${dataList.length}');
          return dataList;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          final eventsList = data['data'];
          if (eventsList is List) {
            logger.d('✅ Public events found in data: ${eventsList.length}');
            return eventsList;
          }
        }
      }
      
      logger.d('⚠️ No public events found');
      return [];
    } catch (e) {
      logger.d('❌ Error fetching public events: $e');
      throw _handleApiError(e);
    }
  }

  /// ⚙️ UTILIDADES PRIVADAS

  /// Manejo centralizado de errores de API
  Exception _handleApiError(dynamic error) {
    if (error is TimeoutException) {
      return Exception('Timeout: La conexión tardó demasiado');
    } else if (error.toString().contains('SocketException')) {
      return Exception('Sin conexión a internet');
    } else if (error.toString().contains('FormatException')) {
      return Exception('Error en formato de respuesta del servidor');
    } else {
      return Exception('Error de red: ${error.toString()}');
    }
  }

  /// Obtener mensaje de error legible
  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'La conexión tardó demasiado. Verifica tu internet.';
    } else if (error.toString().contains('SocketException')) {
      return 'Sin conexión a internet. Verifica tu conexión.';
    } else if (error.toString().contains('FormatException')) {
      return 'Error del servidor. Inténtalo más tarde.';
    } else {
      return 'Error inesperado. Inténtalo de nuevo.';
    }
  }


  /// 🧹 Cleanup resources
  void dispose() {
    // Cleanup any resources if needed
    logger.d('🧹 EventoRepository disposed');
  }
}