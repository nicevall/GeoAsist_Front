import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/evento_service.dart
import '../models/evento_model.dart';
import '../models/api_response_model.dart';
import '../models/event_statistics_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
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
  
  // 🧪 Test-specific constructor to create fresh instances
  EventoService._testInstance() {
    _loadingStates.clear();
  }
  
  // 🧪 Public method to create test instances (bypasses singleton)
  static EventoService createTestInstance() {
    return EventoService._testInstance();
  }

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
    
    logger.d('🔄 [$operation] Estado: $state ${error != null ? "Error: $error" : ""}');
  }

  Future<void> notifyEventCreated() async {
    await _notificationManager.showEventStartedNotification('Evento creado');
  }

  // ✅ ENHANCED: obtenerEventos with synchronized loading states
  Future<List<Evento>> obtenerEventos() async {
    const operation = 'obtenerEventos';
    
    try {
      _updateLoadingState(operation, EventoLoadingState.loading);
      logger.d('📋 Loading events from backend');

      final response = await _apiService.get(AppConstants.eventosEndpoint);

      logger.d('📡 Events response success: ${response.success}');
      logger.d('📄 Events response data available: ${response.data != null}');

      if (response.success && response.data != null) {
        final dynamic responseData = response.data;

        logger.d('🔍 Full response structure: $responseData');
        logger.d('🔍 Response data type: ${responseData.runtimeType}');

        List<dynamic> eventosList = <dynamic>[];

        // Handle different response structures
        if (responseData is Map<String, dynamic>) {
          // Case 1: Response is an object with internal array
          if (responseData.containsKey('data')) {
            final dataField = responseData['data'];
            if (dataField is List<dynamic>) {
              eventosList = dataField;
              logger.d(
                  '✅ Found array in "data": ${eventosList.length} events');
            } else {
              logger.d(
                  '❌ Field "data" is not an array: ${dataField.runtimeType}');
              return <Evento>[];
            }
          } else if (responseData.containsKey('eventos')) {
            final eventosField = responseData['eventos'];
            if (eventosField is List<dynamic>) {
              eventosList = eventosField;
              logger.d(
                  '✅ Found array in "eventos": ${eventosList.length} events');
            } else {
              logger.d(
                  '❌ Field "eventos" is not an array: ${eventosField.runtimeType}');
              return <Evento>[];
            }
          } else {
            logger.d(
                '❌ Response is object but contains neither "data" nor "eventos"');
            logger.d('🔍 Available keys: ${responseData.keys.toList()}');
            return <Evento>[];
          }
        } else if (responseData is List<dynamic>) {
          // Case 2: Response is directly an array
          eventosList = responseData;
          logger.d(
              '✅ Response is direct array: ${eventosList.length} events');
        } else {
          logger.d(
              '❌ Unsupported response type: ${responseData.runtimeType}');
          return <Evento>[];
        }

        // Process event list with soft delete filter FOR STUDENTS
        final eventos = <Evento>[];
        final excludedStates = ['eliminado', 'deleted', 'cancelado', 'inactivo', 'finalizado', 'en espera'];
        final problemEventIds = ['68a730152f90b7d2b0a8ffb6']; // IDs de eventos con problemas del servidor
        int filteredOutCount = 0;
        
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          logger.d('🔍 Processing event $i: ${eventoData.runtimeType}');

          if (eventoData is Map<String, dynamic> &&
              _isValidBackendEventData(eventoData)) {
            
            // 🚨 FILTRO SOFT DELETE: Verificar estado del evento
            final estado = eventoData['estado']?.toString().toLowerCase() ?? '';
            final nombre = eventoData['nombre'] ?? eventoData['titulo'] ?? 'Unknown';
            final eventId = eventoData['id']?.toString() ?? eventoData['_id']?.toString() ?? '';
            
            logger.d('🔍 CHECKING EVENT: "$nombre" (ID: $eventId) - estado: "$estado"');
            logger.d('🔍 EXCLUDED STATES: $excludedStates');
            logger.d('🔍 CONTAINS CHECK: ${excludedStates.contains(estado)}');
            
            // Filtrar por estado
            if (excludedStates.contains(estado)) {
              filteredOutCount++;
              logger.d('🚫 FILTERING OUT deleted event: "$nombre" (estado: $estado)');
              continue; // Saltar este evento
            }
            
            // Filtrar eventos problemáticos conocidos del servidor
            if (problemEventIds.contains(eventId)) {
              filteredOutCount++;
              logger.d('🚫 FILTERING OUT problematic server event: "$nombre" (ID: $eventId)');
              continue; // Saltar este evento problemático
            }
            
            try {
              final eventoMapeado = _mapBackendToFlutter(eventoData);
              final evento = Evento.fromJson(eventoMapeado);
              eventos.add(evento);
              logger.d('✅ Event added: "$nombre" (estado: $estado)');
            } catch (e) {
              logger.d('❌ Error mapping event $i: $e');
              logger.d('🔍 Event data: $eventoData');
            }
          } else {
            logger.d('❌ Invalid event data at index $i: $eventoData');
          }
        }

        if (filteredOutCount > 0) {
          logger.d('🗑️ Filtered out $filteredOutCount deleted/inactive events');
        }
        logger.d('✅ Total events loaded: ${eventos.length} (${eventosList.length} total, $filteredOutCount filtered out)');
        _updateLoadingState(operation, EventoLoadingState.success);
        return eventos;
      }

      logger.d('❌ Failed to load events: ${response.error}');
      _updateLoadingState(operation, EventoLoadingState.error, 
          error: response.error ?? 'Error desconocido al cargar eventos');
      return <Evento>[];
    } catch (e) {
      logger.d('❌ Exception loading events: $e');
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
      logger.d('🔍 Loading event by ID: $eventoId');

      final response =
          await _apiService.get('${AppConstants.eventosEndpoint}/$eventoId');

      logger.d('📡 Event by ID response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null && _isValidBackendEventData(eventoData)) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          logger.d('✅ Individual event parsed: ${evento.titulo}');
          _updateLoadingState(operation, EventoLoadingState.success);
          return evento;
        } else {
          logger.d('❌ Invalid event data for ID: $eventoId');
          _updateLoadingState(operation, EventoLoadingState.error, 
              error: 'Datos de evento inválidos');
          return null;
        }
      }

      logger.d('❌ Failed to load event: ${response.error}');
      _updateLoadingState(operation, EventoLoadingState.error, 
          error: response.error ?? 'Error cargando evento');
      return null;
    } catch (e) {
      logger.d('❌ Exception loading event: $e');
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
      logger.d('📝 Creating new event: $titulo');
      logger.d('📍 Location: $lugar ($latitud, $longitud)');
      logger.d('📅 Date: ${fecha.toIso8601String().split('T')[0]}');
      logger.d(
          '⏰ Time: ${horaInicio.hour}:${horaInicio.minute} - ${horaFinal.hour}:${horaFinal.minute}');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No session for event creation');
        return ApiResponse.error('No hay sesión activa');
      }

      logger.d('🎫 Token found, proceeding with event creation');

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
        'fechaInicio': horaInicio.toIso8601String(),
        'fechaFin': horaFinal.toIso8601String(),
        'politicasAsistencia': {
          'tiempoGracia': tiempoGracia,
          'maximoSalidas': maximoSalidas,
          'tiempoLimiteSalida': tiempoLimiteSalida,
          'verificacionContinua': verificacionContinua,
          'requiereJustificacion': requiereJustificacion,
        },
      };

      // ✅ NUEVO: Debug de fechas específicas
      logger.d('🔍 DEBUG FECHAS:');
      logger.d('   📅 horaInicio completa: ${horaInicio.toIso8601String()}');
      logger.d('   📅 horaFinal completa: ${horaFinal.toIso8601String()}');
      logger.d('   📅 fechaInicio enviada: ${horaInicio.toIso8601String()}');
      logger.d('   📅 fechaFin enviada: ${horaFinal.toIso8601String()}');
      
      logger.d('📦 Event creation payload: ${jsonEncode(body)}');
      logger.d('🌐 Endpoint: ${AppConstants.eventosEndpoint}/crear');

      final response = await _apiService.post(
        '/eventos/crear',  // ✅ CORRECTO: baseUrl ya incluye /api
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Create event response success: ${response.success}');
      logger.d('📄 Create event response data: ${response.data}');
      logger.d('💬 Create event response message: ${response.message}');
      logger.d('❌ Create event response error: ${response.error}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          logger.d('✅ Event created successfully');
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          return ApiResponse.success(evento, message: response.message);
        } else {
          logger.d('❌ No event data in creation response');
        }
      }

      logger.d('❌ Event creation failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error al crear evento');
    } catch (e) {
      logger.d('❌ Event creation exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse<Evento>> actualizarEvento(
    String eventoId,
    Map<String, dynamic> datosActualizados,
  ) async {
    try {
      logger.d('🔄 Updating event ID: $eventoId');
      logger.d('📝 Update data: $datosActualizados');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No session for event update');
        return ApiResponse.error('No hay sesión activa');
      }

      logger.d('🎫 Token found, proceeding with event update');

      final response = await _apiService.put(
        '/eventos/$eventoId',
        body: datosActualizados,
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Update event response success: ${response.success}');
      logger.d('📄 Update event response data: ${response.data}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null && _isValidBackendEventData(eventoData)) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          logger.d('✅ Event updated successfully: ${evento.titulo}');
          return ApiResponse.success(evento, message: response.message);
        } else {
          logger.d('❌ Invalid event data in update response');
        }
      }

      logger.d('❌ Event update failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error al actualizar evento');
    } catch (e) {
      logger.d('❌ Event update exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 1: Editar evento (funcionalidad esencial para profesors) - FASE B
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
      logger.d('📝 Editing event: $eventoId');
      logger.d('📝 New title: $titulo');
      logger.d('📍 New location: $lugar ($latitud, $longitud)');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No session for event edit');
        return ApiResponse.error('No hay sesión activa');
      }

      logger.d('🎫 Token found, proceeding with edit');

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
        'fechaInicio': horaInicio.toIso8601String(),
        'fechaFin': horaFinal.toIso8601String(),
        'politicasAsistencia': {
          'tiempoGracia': tiempoGracia,
          'maximoSalidas': maximoSalidas,
          'tiempoLimiteSalida': tiempoLimiteSalida,
          'verificacionContinua': verificacionContinua,
          'requiereJustificacion': requiereJustificacion,
        },
      };

      logger.d('📦 Edit event payload: ${jsonEncode(body)}');
      logger.d('🌐 Edit endpoint: /eventos/$eventoId');

      final response = await _apiService.put(
        '/eventos/$eventoId',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Edit response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          logger.d('✅ Event edited successfully: ${evento.titulo}');
          return ApiResponse.success(evento, message: response.message);
        } else {
          logger.d('❌ No event data in edit response');
        }
      }

      logger.d('❌ Event edit failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error editando evento');
    } catch (e) {
      logger.d('❌ Event edit exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 2: Eliminar evento - FASE B
  Future<ApiResponse<bool>> eliminarEvento(String eventoId) async {
    try {
      logger.d('🗑️ [FRONTEND] Intentando eliminar evento: $eventoId');
      logger.d('🔍 [FRONTEND] Longitud del ID: ${eventoId.length}');
      logger.d('🔍 [FRONTEND] ID válido format: ${eventoId.isNotEmpty && eventoId.length == 24}');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No session for event deletion');
        return ApiResponse.error('No hay sesión activa');
      }

      logger.d('🎫 Token found, proceeding with deletion');

      final response = await _apiService.delete(
        '/eventos/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Delete response success: ${response.success}');

      if (response.success) {
        logger.d('✅ Event deleted successfully: $eventoId');
        return ApiResponse.success(true,
            message: 'Evento eliminado exitosamente');
      }

      logger.d('❌ Event deletion failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error eliminando evento');
    } catch (e) {
      logger.d('❌ Event deletion exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 3: Obtener eventos específicos del profesor - FASE B
  Future<List<Evento>> obtenerEventosDocente(String profesorId) async {
    try {
      logger.d('👨‍🏫 Loading events for teacher: $profesorId');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No session for teacher events');
        return [];
      }

      logger.d('🎫 Token found, loading teacher events');

      final response = await _apiService.get(
        '/eventos/mis',
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Teacher events response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventos = await _procesarEventosResponse(response.data!);
        final eventosDocente =
            eventos.where((e) => e.creadoPor == profesorId).toList();
        logger.d('✅ Teacher events loaded: ${eventosDocente.length} events');
        return eventosDocente;
      }

      logger.d('❌ Failed to load teacher events: ${response.error}');
      return [];
    } catch (e) {
      logger.d('❌ Teacher events exception: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 4: Finalizar evento y generar reporte
  Future<ApiResponse<String>> finalizarEvento(String eventoId) async {
    try {
      logger.d('🏁 Finalizing event: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No session for event finalization');
        return ApiResponse.error('No hay sesión activa');
      }

      logger.d('🎫 Token found, proceeding with finalization');

      final response = await _apiService.post(
        '/eventos/$eventoId/finalizar',
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Finalize event response success: ${response.success}');

      if (response.success && response.data != null) {
        final reportUrl =
            response.data!['reporteUrl'] ?? response.data!['pdfUrl'];
        logger.d('✅ Event finalized, report generated: $reportUrl');
        return ApiResponse.success(reportUrl, message: response.message);
      }

      logger.d('❌ Event finalization failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error finalizando evento');
    } catch (e) {
      logger.d('❌ Event finalization exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // Método auxiliar reutilizable para procesar respuestas de eventos
  Future<List<Evento>> _procesarEventosResponse(
      dynamic data) async {
    try {
      logger.d('🔄 Processing events response data');

      List<dynamic> eventosList = <dynamic>[];

      // 🚨 NUEVO: Manejar cuando la respuesta es directamente un array
      if (data is List<dynamic>) {
        eventosList = data;
        logger.d('✅ Response is direct array: ${eventosList.length} events');
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          final dataField = data['data'];
          if (dataField is List<dynamic>) {
            eventosList = dataField;
          } else {
            logger.d('❌ Field "data" is not a List');
          }
        } else if (data.containsKey('eventos')) {
          final eventosField = data['eventos'];
          if (eventosField is List<dynamic>) {
            eventosList = eventosField;
          } else {
            logger.d('❌ Field "eventos" is not a List');
          }
        }
      }

      final eventos = <Evento>[];
      // FOR TEACHERS: Allow 'finalizado' and 'en espera' events for management
      final excludedStates = ['eliminado', 'deleted', 'cancelado', 'inactivo'];
      int filteredOutCount = 0;
      
      for (final eventoData in eventosList) {
        logger.d('🔍 TEACHER - Processing event data type: ${eventoData.runtimeType}');
        logger.d('🔍 TEACHER - Is Map check: ${eventoData is Map<String, dynamic>}');
        
        if (eventoData is Map<String, dynamic>) {
          logger.d('🔍 TEACHER - Event is Map, checking validity...');
          final isValid = _isValidBackendEventData(eventoData);
          logger.d('🔍 TEACHER - Event validity: $isValid');
          
          if (isValid) {
          
          // 🚨 FILTRO SOFT DELETE: Verificar estado del evento
          final estado = eventoData['estado']?.toString().toLowerCase() ?? '';
          final nombre = eventoData['nombre'] ?? eventoData['titulo'] ?? 'Unknown';
          
          logger.d('🔍 MIS EVENTOS - CHECKING EVENT: "$nombre" - estado: "$estado"');
          logger.d('🔍 MIS EVENTOS - EXCLUDED STATES: $excludedStates');
          logger.d('🔍 MIS EVENTOS - CONTAINS CHECK: ${excludedStates.contains(estado)}');
          
          if (excludedStates.contains(estado)) {
            filteredOutCount++;
            logger.d('🚫 FILTERING OUT deleted event: "$nombre" (estado: $estado)');
            continue; // Saltar este evento
          }
          
          try {
            final eventoMapeado = _mapBackendToFlutter(eventoData);
            final evento = Evento.fromJson(eventoMapeado);
            eventos.add(evento);
            logger.d('✅ Event added: "$nombre" (estado: $estado)');
          } catch (e) {
            logger.d('❌ Error processing event: $e');
          }
          } else {
            logger.d('⚠️ TEACHER - Event failed validation, skipping');
          }
        } else {
          logger.d('⚠️ TEACHER - Event is not a Map, skipping');
        }
      }

      if (filteredOutCount > 0) {
        logger.d('🗑️ Filtered out $filteredOutCount deleted/inactive events');
      }
      logger.d('✅ Processed ${eventos.length} events successfully (${eventosList.length} total, $filteredOutCount filtered out)');
      return eventos;
    } catch (e) {
      logger.d('❌ Exception processing events response: $e');
      return [];
    }
  }

  // 🎯 MÉTODOS PARA CONTROL DE EVENTOS EN TIEMPO REAL (FASE C)

  /// ✅ NOTA: La activación de eventos es AUTOMÁTICA via cron job
  /// El backend automáticamente cambia eventos de 'activo' a 'En proceso' según fecha/hora
  /// No es necesario activar/desactivar manualmente
  Future<bool> activarEvento(String eventoId) async {
    logger.d('⚠️ Activación de eventos es automática via cron job');
    logger.d('💡 Los eventos cambian automáticamente de "activo" a "En proceso" según fecha/hora');
    return false; // No implementado porque es automático
  }

  /// NOTA: La desactivación también es automática
  Future<bool> desactivarEvento(String eventoId) async {
    logger.d('⚠️ Desactivación de eventos es automática via cron job');
    logger.d('💡 Los eventos cambian automáticamente a "finalizado" según fecha/hora');
    return false; // No implementado porque es automático
  }

  /// Iniciar receso durante el evento
  Future<bool> iniciarReceso(String eventoId) async {
    try {
      logger.d('⏸️ Iniciando receso para evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No hay sesión activa para iniciar receso');
        return false;
      }

      final requestData = {
        'eventoId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
        'duration': 15, // 15 minutos por defecto
      };

      final response = await _apiService.post(
        '/eventos/$eventoId/receso/iniciar',
        body: requestData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        logger.d('✅ Receso iniciado exitosamente');
        return true;
      }

      logger.d('❌ Error iniciando receso: ${response.error}');
      return false;
    } catch (e) {
      logger.d('❌ Excepción iniciando receso: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Terminar receso en el evento
  Future<bool> terminarReceso(String eventoId) async {
    try {
      logger.d('▶️ Terminando receso para evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No hay sesión activa para terminar receso');
        return false;
      }

      final requestData = {
        'eventoId': eventoId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiService.post(
        '/eventos/$eventoId/receso/terminar',
        body: requestData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        logger.d('✅ Receso terminado exitosamente');
        return true;
      }

      logger.d('❌ Error terminando receso: ${response.error}');
      return false;
    } catch (e) {
      logger.d('❌ Excepción terminando receso: $e');
      return false;
    }
  }


  /// Obtener métricas en tiempo real de un evento específico
  Future<Map<String, dynamic>> obtenerMetricasEvento(String eventoId) async {
    try {
      logger.d('📊 Obteniendo métricas del evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No hay sesión activa para métricas');
        return {};
      }

      final response = await _apiService.get(
        '/dashboard/metrics/event/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final metricas = response.data!;
        logger.d('✅ Métricas obtenidas: ${metricas.keys}');
        return metricas;
      }

      logger.d('❌ Error obteniendo métricas: ${response.error}');
      return {};
    } catch (e) {
      logger.d('❌ Excepción obteniendo métricas: $e');
      return {};
    }
  }

  // Validación de datos de evento del backend
  bool _isValidBackendEventData(Map<String, dynamic> data) {
    // ✅ CORREGIDO: Verificar tanto '_id' como 'id'
    final hasId = data.containsKey('_id') || data.containsKey('id');
    if (!hasId || (data['_id'] == null && data['id'] == null)) {
      logger.d('❌ Missing required field: _id or id');
      return false;
    }

    // ✅ CORREGIDO: Verificar tanto 'nombre' como 'titulo'
    final hasTitle = data.containsKey('nombre') || data.containsKey('titulo');
    if (!hasTitle || (data['nombre'] == null && data['titulo'] == null)) {
      logger.d('❌ Missing required field: nombre or titulo');
      return false;
    }

    // ✅ MANTENER: Validar coordenadas (está bien)
    if (!data.containsKey('coordenadas') || data['coordenadas'] == null) {
      logger.d('❌ Missing required field: coordenadas');
      return false;
    }

    // Validar estructura de coordenadas
    final coordenadas = data['coordenadas'];
    if (coordenadas is! Map<String, dynamic> ||
        !coordenadas.containsKey('latitud') ||
        !coordenadas.containsKey('longitud')) {
      logger.d('❌ Invalid coordinates structure');
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
        'creadoPor': backendData['creadoPor'] ?? backendData['profesor'] ?? '',
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
      logger.d('❌ Error mapping backend data: $e');
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
    logger.d('🧹 Cleared loading state for: $operation');
  }

  /// Clear all loading states
  void clearAllLoadingStates() {
    _loadingStates.clear();
    if (!_stateController.isClosed) {
      _stateController.add(<String, EventoStateData>{});
    }
    logger.d('🧹 Cleared all loading states');
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
      logger.d('🌍 Loading public events');

      final response = await _apiService.get(AppConstants.eventosEndpoint);

      logger.d('📡 Public events response success: ${response.success}');

      if (response.success && response.data != null) {
        final eventos = await _procesarEventosResponse(response.data!);
        logger.d('✅ Public events loaded: ${eventos.length} events');
        return eventos;
      }

      logger.d('❌ Failed to load public events: ${response.error}');
      return [];
    } catch (e) {
      logger.d('❌ Public events exception: $e');
      return [];
    }
  }

  /// 🎯 ALIAS: Obtener eventos por creador (para dashboard del profesor)
  Future<List<Evento>> getEventosByCreador(String creadorId) async {
    return await obtenerEventosDocente(creadorId);
  }

  // 📊 EVENT STATISTICS: Get detailed event analytics
  Future<ApiResponse<EventStatistics>> getEventStatistics(String eventoId) async {
    try {
      logger.d('📊 [FRONTEND] Fetching statistics for event: $eventoId');
      
      final endpoint = AppConstants.eventStatisticsEndpoint.replaceAll('[eventId]', eventoId);
      
      final response = await _apiService.get(endpoint);
      
      logger.d('📡 Statistics response success: ${response.success}');
      
      if (response.success && response.data != null) {
        final estadisticas = EventStatistics.fromJson(response.data!);
        logger.d('✅ Event statistics loaded: ${estadisticas.totalStudents} students');
        return ApiResponse.success(estadisticas, message: response.message);
      }
      
      logger.d('❌ Event statistics failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error obteniendo estadísticas');
    } catch (e) {
      logger.d('❌ Event statistics exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 👥 EVENT STUDENTS: Get list of students enrolled in event
  Future<ApiResponse<List<StudentAttendanceStat>>> getEventStudents(String eventoId) async {
    try {
      logger.d('👥 [FRONTEND] Fetching students for event: $eventoId');
      
      final endpoint = '/eventos/$eventoId/students';
      
      final response = await _apiService.get(endpoint);
      
      logger.d('📡 Students response success: ${response.success}');
      
      if (response.success && response.data != null) {
        final studentsData = response.data!['students'] as List? ?? [];
        final students = studentsData
            .map((data) => StudentAttendanceStat.fromJson(data))
            .toList();
        
        logger.d('✅ Event students loaded: ${students.length} students');
        return ApiResponse.success(students, message: response.message);
      }
      
      logger.d('❌ Event students failed: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error obteniendo estudiantes');
    } catch (e) {
      logger.d('❌ Event students exception: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Dispose resources and cleanup
  void dispose() {
    logger.d('🧹 Disposing EventoService resources');
    clearAllLoadingStates();
    
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    
    logger.d('✅ EventoService disposed successfully');
  }
}
