// lib/services/evento_service.dart
import '../models/evento_model.dart';
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class EventoService {
  static final EventoService _instance = EventoService._internal();
  factory EventoService() => _instance;
  EventoService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<List<Evento>> obtenerEventos() async {
    try {
      debugPrint('📋 Loading events from backend');

      final response = await _apiService.get(AppConstants.eventosEndpoint);

      debugPrint('📡 Events response success: ${response.success}');
      debugPrint('📄 Events response data available: ${response.data != null}');

      if (response.success && response.data != null) {
        final dynamic responseData = response.data;

        debugPrint('🔍 Full response structure: $responseData');
        debugPrint('🔍 Response data type: ${responseData.runtimeType}');

        List<dynamic> eventosList = <dynamic>[];

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Case 1: Response is an object with internal array
          if (responseData.containsKey('data')) {
            final dataField = responseData['data'];
            if (dataField is List<dynamic>) {
              eventosList = dataField;
              debugPrint(
                  '✅ Found array in "data": ${eventosList.length} events');
            } else {
              debugPrint(
                  '❌ Field "data" is not an array: ${dataField.runtimeType}');
              return <Evento>[];
            }
          } else if (responseData.containsKey('eventos')) {
            final eventosField = responseData['eventos'];
            if (eventosField is List<dynamic>) {
              eventosList = eventosField;
              debugPrint(
                  '✅ Found array in "eventos": ${eventosList.length} events');
            } else {
              debugPrint(
                  '❌ Field "eventos" is not an array: ${eventosField.runtimeType}');
              return <Evento>[];
            }
          } else {
            debugPrint(
                '❌ Response is object but contains neither "data" nor "eventos"');
            debugPrint('🔍 Available keys: ${responseData.keys.toList()}');
            return <Evento>[];
          }
        } else if (responseData is List<dynamic>) {
          // Case 2: Response is directly an array
          eventosList = responseData;
          debugPrint(
              '✅ Response is direct array: ${eventosList.length} events');
        } else {
          debugPrint(
              '❌ Unsupported response type: ${responseData.runtimeType}');
          return <Evento>[];
        }

        // Process event list
        final eventos = <Evento>[];
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          debugPrint('🔍 Processing event $i: ${eventoData.runtimeType}');

          if (eventoData is Map<String, dynamic> &&
              _isValidBackendEventData(eventoData)) {
            try {
              final eventoMapeado = _mapBackendToFlutter(eventoData);
              final evento = Evento.fromJson(eventoMapeado);
              eventos.add(evento);
              debugPrint('✅ Event mapped successfully: ${evento.titulo}');
            } catch (e) {
              debugPrint('❌ Error mapping event $i: $e');
              debugPrint('🔍 Event data: $eventoData');
            }
          } else {
            debugPrint('❌ Invalid event data at index $i: $eventoData');
          }
        }

        debugPrint('✅ Total events loaded: ${eventos.length}');
        return eventos;
      }

      debugPrint('❌ Failed to load events: ${response.error}');
      return <Evento>[];
    } catch (e) {
      debugPrint('❌ Exception loading events: $e');
      return <Evento>[];
    }
  }

  Future<Evento?> obtenerEventoPorId(String eventoId) async {
    try {
      debugPrint('🔍 Loading event by ID: $eventoId');

      final response =
          await _apiService.get('${AppConstants.eventosEndpoint}/$eventoId');

      debugPrint('📡 Event by ID response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null && _isValidBackendEventData(eventoData)) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          debugPrint('✅ Individual event parsed: ${evento.titulo}');
          return evento;
        } else {
          debugPrint('❌ Invalid event data for ID: $eventoId');
          return null;
        }
      }

      debugPrint('❌ Failed to load event: ${response.error}');
      return null;
    } catch (e) {
      debugPrint('❌ Exception loading event: $e');
      return null;
    }
  }

  Future<ApiResponse<Evento>> crearEvento({
    required String titulo,
    String? descripcion,
    required String tipo,
    required String lugar,
    required int capacidadMaxima,
    required double latitud,
    required double longitud,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFinal,
    double rangoPermitido = 100.0,
    int tiempoGracia = 10,
    int maximoSalidas = 3,
    int tiempoLimiteSalida = 15,
    bool verificacionContinua = true,
    bool requiereJustificacion = false,
  }) async {
    try {
      debugPrint('📝 Creating new event: $titulo');
      debugPrint('📍 Location: $lugar ($latitud, $longitud)');
      debugPrint('📅 Date: ${fecha.toIso8601String().split('T')[0]}');
      debugPrint(
          '⏰ Time: ${horaInicio.hour}:${horaInicio.minute} - ${horaFinal.hour}:${horaFinal.minute}');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for event creation');
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🎫 Token found, proceeding with event creation');

      // Backend expected format
      final body = {
        'nombre': titulo,
        'tipo': tipo,
        'lugar': lugar,
        'descripcion': descripcion ?? '',
        'capacidadMaxima': capacidadMaxima,
        'coordenadas': {
          'latitud': latitud,
          'longitud': longitud,
          'radio': rangoPermitido,
        },
        'fechaInicio': fecha.toIso8601String().split('T')[0],
        'fechaFin': fecha.toIso8601String().split('T')[0],
        'horaInicio':
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
        'horaFin':
            '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}',
        'politicasAsistencia': {
          'tiempoGracia': tiempoGracia,
          'maximoSalidas': maximoSalidas,
          'tiempoLimiteSalida': tiempoLimiteSalida,
          'verificacionContinua': verificacionContinua,
          'requiereJustificacion': requiereJustificacion,
        },
      };

      debugPrint('📦 Event creation payload: ${jsonEncode(body)}');
      debugPrint('🌐 Endpoint: ${AppConstants.eventosEndpoint}/crear');

      final response = await _apiService.post(
        '${AppConstants.eventosEndpoint}/crear',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Create event response success: ${response.success}');
      debugPrint('📄 Create event response data: ${response.data}');
      debugPrint('💬 Create event response message: ${response.message}');
      debugPrint('❌ Create event response error: ${response.error}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          debugPrint('✅ Event created successfully');
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          return ApiResponse.success(evento, message: response.message);
        } else {
          debugPrint('❌ No event data in creation response');
        }
      }

      debugPrint('❌ Event creation failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error al crear evento');
    } catch (e) {
      debugPrint('❌ Event creation exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse<Evento>> actualizarEvento(
    String eventoId,
    Map<String, dynamic> datosActualizados,
  ) async {
    try {
      debugPrint('🔄 Updating event ID: $eventoId');
      debugPrint('📝 Update data: $datosActualizados');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for event update');
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🎫 Token found, proceeding with event update');

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId',
        body: datosActualizados,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Update event response success: ${response.success}');
      debugPrint('📄 Update event response data: ${response.data}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null && _isValidBackendEventData(eventoData)) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          debugPrint('✅ Event updated successfully: ${evento.titulo}');
          return ApiResponse.success(evento, message: response.message);
        } else {
          debugPrint('❌ Invalid event data in update response');
        }
      }

      debugPrint('❌ Event update failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error al actualizar evento');
    } catch (e) {
      debugPrint('❌ Event update exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 1: Editar evento (funcionalidad esencial para docentes) - FASE B
  Future<ApiResponse<Evento>> editarEvento({
    required String eventoId,
    required String titulo,
    String? descripcion,
    required String tipo,
    required String lugar,
    required int capacidadMaxima,
    required double latitud,
    required double longitud,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFinal,
    double rangoPermitido = 100.0,
    int tiempoGracia = 1,
    int maximoSalidas = 3,
    int tiempoLimiteSalida = 30,
    bool verificacionContinua = true,
    bool requiereJustificacion = false,
  }) async {
    try {
      debugPrint('📝 Editing event: $eventoId');
      debugPrint('📝 New title: $titulo');
      debugPrint('📍 New location: $lugar ($latitud, $longitud)');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for event edit');
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🎫 Token found, proceeding with edit');

      final body = {
        'nombre': titulo,
        'tipo': tipo,
        'lugar': lugar,
        'descripcion': descripcion ?? '',
        'capacidadMaxima': capacidadMaxima,
        'coordenadas': {
          'latitud': latitud,
          'longitud': longitud,
          'radio': rangoPermitido,
        },
        'fechaInicio': fecha.toIso8601String().split('T')[0],
        'fechaFin': fecha.toIso8601String().split('T')[0],
        'horaInicio':
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
        'horaFin':
            '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}',
        'politicasAsistencia': {
          'tiempoGracia': tiempoGracia,
          'maximoSalidas': maximoSalidas,
          'tiempoLimiteSalida': tiempoLimiteSalida,
          'verificacionContinua': verificacionContinua,
          'requiereJustificacion': requiereJustificacion,
        },
      };

      debugPrint('📦 Edit event payload: ${jsonEncode(body)}');
      debugPrint('🌐 Edit endpoint: /eventos/$eventoId');

      final response = await _apiService.put(
        '/eventos/$eventoId',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Edit response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          debugPrint('✅ Event edited successfully: ${evento.titulo}');
          return ApiResponse.success(evento, message: response.message);
        } else {
          debugPrint('❌ No event data in edit response');
        }
      }

      debugPrint('❌ Event edit failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error editando evento');
    } catch (e) {
      debugPrint('❌ Event edit exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 2: Eliminar evento - FASE B
  Future<ApiResponse<bool>> eliminarEvento(String eventoId) async {
    try {
      debugPrint('🗑️ Deleting event: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for event deletion');
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🎫 Token found, proceeding with deletion');

      final response = await _apiService.delete(
        '/eventos/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Delete response success: ${response.success}');

      if (response.success) {
        debugPrint('✅ Event deleted successfully: $eventoId');
        return ApiResponse.success(true,
            message: 'Evento eliminado exitosamente');
      }

      debugPrint('❌ Event deletion failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error eliminando evento');
    } catch (e) {
      debugPrint('❌ Event deletion exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 3: Obtener eventos específicos del docente - FASE B
  Future<List<Evento>> obtenerEventosDocente(String docenteId) async {
    try {
      debugPrint('👨‍🏫 Loading events for teacher: $docenteId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for teacher events');
        return [];
      }

      debugPrint('🎫 Token found, loading teacher events');

      final response = await _apiService.get(
        '/eventos/mis',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Teacher events response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventos = await _procesarEventosResponse(response.data!);
        final eventosDocente =
            eventos.where((e) => e.creadoPor == docenteId).toList();
        debugPrint('✅ Teacher events loaded: ${eventosDocente.length} events');
        return eventosDocente;
      }

      debugPrint('❌ Failed to load teacher events: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('❌ Teacher events exception: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 4: Finalizar evento y generar reporte
  Future<ApiResponse<String>> finalizarEvento(String eventoId) async {
    try {
      debugPrint('🏁 Finalizing event: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No session for event finalization');
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🎫 Token found, proceeding with finalization');

      final response = await _apiService.post(
        '/eventos/$eventoId/finalizar',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Finalize event response success: ${response.success}');

      if (response.success && response.data != null) {
        final reportUrl =
            response.data!['reporteUrl'] ?? response.data!['pdfUrl'];
        debugPrint('✅ Event finalized, report generated: $reportUrl');
        return ApiResponse.success(reportUrl, message: response.message);
      }

      debugPrint('❌ Event finalization failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error finalizando evento');
    } catch (e) {
      debugPrint('❌ Event finalization exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // Método auxiliar reutilizable para procesar respuestas de eventos
  Future<List<Evento>> _procesarEventosResponse(
      Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Processing events response data');

      List<dynamic> eventosList = <dynamic>[];

      if (data.containsKey('data')) {
        final dataField = data['data'];
        if (dataField is List<dynamic>) {
          eventosList = dataField;
        } else {
          debugPrint('❌ Field "data" is not a List');
        }
      } else if (data.containsKey('eventos')) {
        final eventosField = data['eventos'];
        if (eventosField is List<dynamic>) {
          eventosList = eventosField;
        } else {
          debugPrint('❌ Field "eventos" is not a List');
        }
      }

      final eventos = <Evento>[];
      for (final eventoData in eventosList) {
        if (eventoData is Map<String, dynamic> &&
            _isValidBackendEventData(eventoData)) {
          try {
            final eventoMapeado = _mapBackendToFlutter(eventoData);
            final evento = Evento.fromJson(eventoMapeado);
            eventos.add(evento);
          } catch (e) {
            debugPrint('❌ Error processing event: $e');
          }
        }
      }

      debugPrint('✅ Processed ${eventos.length} events successfully');
      return eventos;
    } catch (e) {
      debugPrint('❌ Exception processing events response: $e');
      return [];
    }
  }

  // Validación de datos de evento del backend
  bool _isValidBackendEventData(Map<String, dynamic> data) {
    final requiredFields = ['id', 'nombre', 'coordenadas'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        debugPrint('❌ Missing required field: $field');
        return false;
      }
    }

    // Validar coordenadas
    final coordenadas = data['coordenadas'];
    if (coordenadas is! Map<String, dynamic> ||
        !coordenadas.containsKey('latitud') ||
        !coordenadas.containsKey('longitud')) {
      debugPrint('❌ Invalid coordinates structure');
      return false;
    }

    return true;
  }

  // Mapeo de estructura backend a estructura Flutter
  Map<String, dynamic> _mapBackendToFlutter(Map<String, dynamic> backendData) {
    try {
      final coordenadas = backendData['coordenadas'] as Map<String, dynamic>;

      return {
        'id': backendData['id'],
        'titulo':
            backendData['nombre'] ?? backendData['titulo'] ?? 'Sin título',
        'descripcion': backendData['descripcion'] ?? '',
        'tipo': backendData['tipo'] ?? 'clase',
        'lugar': backendData['lugar'] ?? 'Sin ubicación',
        'capacidadMaxima': backendData['capacidadMaxima'] ?? 30,
        'rangoPermitido': coordenadas['radio']?.toDouble() ?? 100.0,
        'ubicacion': {
          'latitud': coordenadas['latitud']?.toDouble() ?? 0.0,
          'longitud': coordenadas['longitud']?.toDouble() ?? 0.0,
        },
        'fecha': backendData['fechaInicio'] ??
            DateTime.now().toIso8601String().split('T')[0],
        'horaInicio': backendData['horaInicio'] ?? '08:00',
        'horaFinal':
            backendData['horaFin'] ?? backendData['horaFinal'] ?? '10:00',
        'estado': backendData['estado'] ?? 'programado',
        'creadoPor': backendData['creadoPor'] ?? backendData['docente'] ?? '',
        'creadoEn': backendData['creadoEn'] ?? DateTime.now().toIso8601String(),
        'politicasAsistencia': backendData['politicasAsistencia'] ??
            {
              'tiempoGracia': 10,
              'maximoSalidas': 3,
              'tiempoLimiteSalida': 30,
              'verificacionContinua': true,
              'requiereJustificacion': false,
            },
      };
    } catch (e) {
      debugPrint('❌ Error mapping backend data: $e');
      rethrow;
    }
  }
}
