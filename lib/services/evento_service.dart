// lib/services/evento_service.dart
import '../models/evento_model.dart';
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'notifications/notification_manager.dart';

/// ✅ ENHANCED: Loading states for better synchronization
enum EventoLoadingState {
  idle,
  loading,
  success,
  error,
}

/// ✅ ENHANCED: Loading state data
class EventoStateData {
  final EventoLoadingState state;
  final String? error;
  final DateTime lastUpdate;

  const EventoStateData({
    required this.state,
    this.error,
    required this.lastUpdate,
  });

  EventoStateData copyWith({
    EventoLoadingState? state,
    String? error,
    DateTime? lastUpdate,
  }) {
    return EventoStateData(
      state: state ?? this.state,
      error: error ?? this.error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class EventoService {
  static final EventoService _instance = EventoService._internal();
  factory EventoService() => _instance;
  EventoService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final NotificationManager _notificationManager = NotificationManager();

  // ✅ ENHANCED: Loading state management
  final Map<String, EventoStateData> _loadingStates = {};
  final StreamController<Map<String, EventoStateData>> _stateController = 
      StreamController<Map<String, EventoStateData>>.broadcast();

  /// Stream to listen to loading state changes
  Stream<Map<String, EventoStateData>> get loadingStatesStream => _stateController.stream;

  /// Get current loading state for an operation
  EventoLoadingState getLoadingState(String operation) {
    return _loadingStates[operation]?.state ?? EventoLoadingState.idle;
  }

  /// Get error for an operation
  String? getError(String operation) {
    return _loadingStates[operation]?.error;
  }

  /// Update loading state and notify listeners
  void _updateLoadingState(String operation, EventoLoadingState state, {String? error}) {
    _loadingStates[operation] = EventoStateData(
      state: state,
      error: error,
      lastUpdate: DateTime.now(),
    );
    
    if (!_stateController.isClosed) {
      _stateController.add(Map.from(_loadingStates));
    }
    
    debugPrint('🔄 [$operation] Estado: $state ${error != null ? "Error: $error" : ""}');
  }

  Future<void> notifyEventCreated() async {
    await _notificationManager.showEventStartedNotification('Evento creado');
  }

  // ✅ ENHANCED: obtenerEventos with synchronized loading states
  Future<List<Evento>> obtenerEventos() async {
    const operation = 'obtenerEventos';
    
    try {
      _updateLoadingState(operation, EventoLoadingState.loading);
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
        _updateLoadingState(operation, EventoLoadingState.success);
        return eventos;
      }

      debugPrint('❌ Failed to load events: ${response.error}');
      _updateLoadingState(operation, EventoLoadingState.error, 
          error: response.error ?? 'Error desconocido al cargar eventos');
      return <Evento>[];
    } catch (e) {
      debugPrint('❌ Exception loading events: $e');
      _updateLoadingState(operation, EventoLoadingState.error, 
          error: 'Excepción: $e');
      return <Evento>[];
    }
  }

  // ✅ ENHANCED: obtenerEventoPorId with synchronized loading states
  Future<Evento?> obtenerEventoPorId(String eventoId) async {
    final operation = 'obtenerEventoPorId_$eventoId';
    
    try {
      _updateLoadingState(operation, EventoLoadingState.loading);
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
          _updateLoadingState(operation, EventoLoadingState.success);
          return evento;
        } else {
          debugPrint('❌ Invalid event data for ID: $eventoId');
          _updateLoadingState(operation, EventoLoadingState.error, 
              error: 'Datos de evento inválidos');
          return null;
        }
      }

      debugPrint('❌ Failed to load event: ${response.error}');
      _updateLoadingState(operation, EventoLoadingState.error, 
          error: response.error ?? 'Error cargando evento');
      return null;
    } catch (e) {
      debugPrint('❌ Exception loading event: $e');
      _updateLoadingState(operation, EventoLoadingState.error, 
          error: 'Excepción: $e');
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
      debugPrint('🌐 Edit endpoint: ${AppConstants.eventosEndpoint}/$eventoId');

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId',
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
        '${AppConstants.eventosEndpoint}/$eventoId',
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
        '${AppConstants.eventosEndpoint}/mis',
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
        '${AppConstants.eventosEndpoint}/$eventoId/finalizar',
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

  // 🎯 MÉTODOS PARA CONTROL DE EVENTOS EN TIEMPO REAL (FASE C)

  /// ✅ Activar evento (permite que estudiantes se unan)
  Future<bool> activarEvento(String eventoId) async {
    try {
      debugPrint('▶️ Activando evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para activar evento');
        return false;
      }

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId/activar',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Evento activado exitosamente');
        return true;
      }

      debugPrint('❌ Error activando evento: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('❌ Excepción activando evento: $e');
      return false;
    }
  }

  /// Desactivar evento
  Future<bool> desactivarEvento(String eventoId) async {
    try {
      debugPrint('⏹️ Desactivando evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para desactivar evento');
        return false;
      }

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId/desactivar',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Evento desactivado exitosamente');
        return true;
      }

      debugPrint('❌ Error desactivando evento: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('❌ Excepción desactivando evento: $e');
      return false;
    }
  }

  /// Iniciar receso durante el evento
  Future<bool> iniciarReceso(String eventoId) async {
    try {
      debugPrint('⏸️ Iniciando receso para evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para iniciar receso');
        return false;
      }

      final requestData = {
        'eventoId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
        'duration': 15, // 15 minutos por defecto
      };

      final response = await _apiService.post(
        '${AppConstants.eventosEndpoint}/$eventoId/receso/iniciar',
        body: requestData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Receso iniciado exitosamente');
        return true;
      }

      debugPrint('❌ Error iniciando receso: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('❌ Excepción iniciando receso: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Terminar receso en el evento
  Future<bool> terminarReceso(String eventoId) async {
    try {
      debugPrint('▶️ Terminando receso para evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para terminar receso');
        return false;
      }

      final requestData = {
        'eventoId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiService.post(
        '${AppConstants.eventosEndpoint}/$eventoId/receso/terminar',
        body: requestData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Receso terminado exitosamente');
        return true;
      }

      debugPrint('❌ Error terminando receso: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('❌ Excepción terminando receso: $e');
      return false;
    }
  }

  Future<bool> toggleEventoActive(String eventoId, bool isActive) async {
    try {
      debugPrint(
          '🔄 Alternando estado del evento $eventoId a: ${isActive ? "ACTIVO" : "INACTIVO"}');

      if (isActive) {
        return await activarEvento(eventoId);
      } else {
        return await desactivarEvento(eventoId);
      }
    } catch (e) {
      debugPrint('❌ Error alternando estado del evento: $e');
      return false;
    }
  }

  /// Obtener métricas en tiempo real de un evento específico
  Future<Map<String, dynamic>> obtenerMetricasEvento(String eventoId) async {
    try {
      debugPrint('📊 Obteniendo métricas del evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para métricas');
        return {};
      }

      final response = await _apiService.get(
        '${AppConstants.eventosEndpoint}/$eventoId/metricas',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final metricas = response.data!;
        debugPrint('✅ Métricas obtenidas: ${metricas.keys}');
        return metricas;
      }

      debugPrint('❌ Error obteniendo métricas: ${response.error}');
      return {};
    } catch (e) {
      debugPrint('❌ Excepción obteniendo métricas: $e');
      return {};
    }
  }

  // Validación de datos de evento del backend
  bool _isValidBackendEventData(Map<String, dynamic> data) {
    // ✅ CORREGIDO: Verificar tanto '_id' como 'id'
    final hasId = data.containsKey('_id') || data.containsKey('id');
    if (!hasId || (data['_id'] == null && data['id'] == null)) {
      debugPrint('❌ Missing required field: _id or id');
      return false;
    }

    // ✅ CORREGIDO: Verificar tanto 'nombre' como 'titulo'
    final hasTitle = data.containsKey('nombre') || data.containsKey('titulo');
    if (!hasTitle || (data['nombre'] == null && data['titulo'] == null)) {
      debugPrint('❌ Missing required field: nombre or titulo');
      return false;
    }

    // ✅ MANTENER: Validar coordenadas (está bien)
    if (!data.containsKey('coordenadas') || data['coordenadas'] == null) {
      debugPrint('❌ Missing required field: coordenadas');
      return false;
    }

    // Validar estructura de coordenadas
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
      // ✅ CORREGIDO: Usar el ID correcto
      final eventoId = backendData['_id'] ?? backendData['id'] ?? '';

      // ✅ CORREGIDO: Usar el título correcto
      final titulo =
          backendData['titulo'] ?? backendData['nombre'] ?? 'Sin título';

      final coordenadas = backendData['coordenadas'] as Map<String, dynamic>;

      return {
        'id': eventoId,
        'titulo': titulo,
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

  // ✅ ENHANCED: Loading state management utilities

  /// Clear loading state for a specific operation
  void clearLoadingState(String operation) {
    _loadingStates.remove(operation);
    if (!_stateController.isClosed) {
      _stateController.add(Map.from(_loadingStates));
    }
    debugPrint('🧹 Cleared loading state for: $operation');
  }

  /// Clear all loading states
  void clearAllLoadingStates() {
    _loadingStates.clear();
    if (!_stateController.isClosed) {
      _stateController.add(<String, EventoStateData>{});
    }
    debugPrint('🧹 Cleared all loading states');
  }

  /// Get all current loading states (for debugging)
  Map<String, EventoStateData> getAllLoadingStates() {
    return Map.from(_loadingStates);
  }

  /// Check if any operation is currently loading
  bool get hasLoadingOperations {
    return _loadingStates.values.any((state) => state.state == EventoLoadingState.loading);
  }

  /// Get all operations with errors
  List<String> get operationsWithErrors {
    return _loadingStates.entries
        .where((entry) => entry.value.state == EventoLoadingState.error)
        .map((entry) => entry.key)
        .toList();
  }

  // 🎯 MÉTODO 5: Obtener eventos públicos (para justificaciones) - FASE B
  Future<List<Evento>> obtenerEventosPublicos() async {
    try {
      debugPrint('🌍 Loading public events');

      final response = await _apiService.get(AppConstants.eventosEndpoint);

      debugPrint('📡 Public events response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventos = await _procesarEventosResponse(response.data!);
        debugPrint('✅ Public events loaded: ${eventos.length} events');
        return eventos;
      }

      debugPrint('❌ Failed to load public events: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('❌ Public events exception: $e');
      return [];
    }
  }

  /// 🎯 ALIAS: Obtener eventos por creador (para dashboard del profesor)
  Future<List<Evento>> getEventosByCreador(String creadorId) async {
    return await obtenerEventosDocente(creadorId);
  }

  /// Dispose resources and cleanup
  void dispose() {
    debugPrint('🧹 Disposing EventoService resources');
    clearAllLoadingStates();
    
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    
    debugPrint('✅ EventoService disposed successfully');
  }
}
