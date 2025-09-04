// lib/services/evento/evento_service.dart - COORDINADOR MODULAR
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/evento_model.dart';
import '../../models/api_response_model.dart';
import '../../core/backend_sync_service.dart';
import '../../core/error_handler.dart';
import '../../utils/haversine_calculator.dart';
import '../storage_service.dart';
import '../notifications/notification_manager.dart';
import 'evento_repository.dart';
import 'evento_mapper.dart';
import 'evento_validator.dart';

/// ✅ COORDINADOR PRINCIPAL: EventoService Modular
/// Responsabilidades:
/// - Punto de entrada único para el frontend
/// - Coordina entre validator, repository y mapper
/// - Mantiene estados de loading
/// - Expone API pública consistente
/// - 🚨 GARANTIZA que eventos eliminados NO lleguen al frontend
class EventoService {
  static final EventoService _instance = EventoService._internal();
  factory EventoService() => _instance;
  EventoService._internal();

  // ✅ MÓDULOS ESPECIALIZADOS
  final EventoRepository _repository = EventoRepository();
  final EventoMapper _mapper = EventoMapper();
  final EventoValidator _validator = EventoValidator();
  
  // ✅ SERVICIOS AUXILIARES
  final StorageService _storageService = StorageService();
  final NotificationManager _notificationManager = NotificationManager();
  final BackendSyncService _syncService = BackendSyncService();
  final ErrorHandler _errorHandler = ErrorHandler();

  // ✅ ESTADOS DE LOADING
  final Map<String, EventoStateData> _loadingStates = {};
  final StreamController<Map<String, EventoStateData>> _stateController = 
      StreamController<Map<String, EventoStateData>>.broadcast();

  /// Stream para escuchar cambios de estado
  Stream<Map<String, EventoStateData>> get loadingStatesStream => _stateController.stream;

  /// Obtener estado actual de una operación
  EventoLoadingState getLoadingState(String operation) {
    return _loadingStates[operation]?.state ?? EventoLoadingState.idle;
  }

  /// Obtener error de una operación
  String? getError(String operation) {
    return _loadingStates[operation]?.error;
  }

  /// ✅ OBTENER TODOS LOS EVENTOS (CON FILTRO SOFT DELETE)
  Future<List<Evento>> obtenerEventos() async {
    const operation = 'obtenerEventos';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      debugPrint('📋 Loading events from backend with enhanced sync');
      
      // 1. Obtener datos del backend con manejo de errores mejorado
      final backendEvents = await _errorHandler.executeWithRetry(() async {
        return await _repository.fetchAllEvents();
      }, context: 'fetching_all_events');
      
      // 2. 🚨 FILTRAR EVENTOS ELIMINADOS
      final eventos = _mapper.filterActiveEvents(backendEvents);
      
      // 3. Validar distancias usando Haversine exacto
      for (final evento in eventos) {
        HaversineCalculator.validateGeofenceRadius(evento.rangoPermitido);
      }
      
      // 4. Log estadísticas de filtrado
      final stats = _mapper.getFilteringStats(backendEvents, eventos);
      debugPrint('🌍 Filtered out ${stats['eliminado'] ?? 0} deleted events from results');
      debugPrint('✅ Valid events after filtering: ${eventos.length}');
      
      // 5. Sincronizar con backend service
      if (_syncService.isOnline) {
        _syncService.addPendingOperation(SyncOperation(
          type: SyncOperationType.event,
          data: {'operation': 'fetch_events', 'count': eventos.length},
          method: 'GET',
        ));
      }
      
      _updateLoadingState(operation, EventoLoadingState.success);
      return eventos;
    } catch (e) {
      final appError = _errorHandler.handleError(e, context: operation);
      debugPrint('❌ Error in obtenerEventos: ${appError.message}');
      _updateLoadingState(operation, EventoLoadingState.error, error: appError.userFriendlyMessage);
      return [];
    }
  }

  /// ✅ OBTENER EVENTOS PARA ESTUDIANTES (SOLO ACTIVOS/EN ESPERA)
  Future<List<Evento>> obtenerEventosParaEstudiantes() async {
    const operation = 'obtenerEventosParaEstudiantes';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      debugPrint('🎓 Loading active events for students');
      
      // 1. Obtener todos los eventos (ya filtrados sin eliminados)
      final allEvents = await obtenerEventos();
      
      // 2. Filtrar solo los visibles para estudiantes
      final studentEvents = _mapper.filterStudentEvents(allEvents);
      
      // 3. Liberar estudiantes de eventos terminados
      await _liberarEstudiantesDeEventosTerminados(allEvents);
      
      _updateLoadingState(operation, EventoLoadingState.success);
      return studentEvents;
    } catch (e) {
      debugPrint('❌ Error in obtenerEventosParaEstudiantes: $e');
      _updateLoadingState(operation, EventoLoadingState.error, error: e.toString());
      return [];
    }
  }

  /// ✅ OBTENER EVENTO POR ID (NULL SI ELIMINADO)
  Future<Evento?> obtenerEventoPorId(String eventoId) async {
    const operation = 'obtenerEventoPorId';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      debugPrint('🔍 Fetching event by ID: $eventoId');
      
      // 1. Obtener del backend
      final backendEvent = await _repository.fetchEventById(eventoId);
      
      if (backendEvent == null) {
        _updateLoadingState(operation, EventoLoadingState.success);
        return null;
      }
      
      // 2. Verificar que no esté eliminado
      final eventos = _mapper.filterActiveEvents([backendEvent]);
      
      if (eventos.isEmpty) {
        debugPrint('🚫 Event $eventoId is deleted, returning null');
        _updateLoadingState(operation, EventoLoadingState.success);
        return null;
      }
      
      _updateLoadingState(operation, EventoLoadingState.success);
      return eventos.first;
    } catch (e) {
      debugPrint('❌ Error in obtenerEventoPorId: $e');
      _updateLoadingState(operation, EventoLoadingState.error, error: e.toString());
      return null;
    }
  }

  /// ✅ OBTENER EVENTOS POR CREADOR (DOCENTE)
  Future<List<Evento>> getEventosByCreador(String creadorId) async {
    const operation = 'getEventosByCreador';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      debugPrint('👩‍🏫 Loading events for teacher: $creadorId');
      
      // 1. Obtener del backend
      final backendEvents = await _repository.fetchEventsByTeacher(creadorId);
      
      // 2. 🚨 FILTRAR EVENTOS ELIMINADOS
      final eventos = _mapper.filterActiveEvents(backendEvents);
      
      debugPrint('✅ Teacher events loaded: ${eventos.length} (filtered from ${backendEvents.length})');
      
      _updateLoadingState(operation, EventoLoadingState.success);
      return eventos;
    } catch (e) {
      debugPrint('❌ Error in getEventosByCreador: $e');
      _updateLoadingState(operation, EventoLoadingState.error, error: e.toString());
      return [];
    }
  }

  /// ✅ CREAR NUEVO EVENTO
  Future<ApiResponse<Evento>> crearEvento({
    required String titulo,
    required String tipo,
    required String lugar,
    required String descripcion,
    required double latitud,
    required double longitud,
    required double radio,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFin,
  }) async {
    const operation = 'crearEvento';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      // 1. Validar coordenadas y radio usando Haversine
      HaversineCalculator.validateGeofenceRadius(radio);
      
      // 2. Obtener usuario actual
      final usuario = await _storageService.getUser();
      
      // 3. Crear objeto evento
      final evento = Evento.crear(
        titulo: titulo,
        tipo: tipo,
        lugar: lugar,
        descripcion: descripcion,
        latitud: latitud,
        longitud: longitud,
        radio: radio,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        creadoPor: usuario?.id ?? '',
      );
      
      // 4. Validar
      final validation = _validator.validateEventCreation(evento, usuario);
      if (!validation.isValid) {
        _updateLoadingState(operation, EventoLoadingState.error, error: validation.message);
        return ApiResponse<Evento>(
          success: false,
          message: validation.message,
        );
      }
      
      // 5. Mapear a formato backend
      final backendData = _mapper.mapFlutterToBackend(evento);
      
      // 6. Crear en backend con retry automático
      final response = await _errorHandler.executeWithRetry(() async {
        return await _repository.createEvent(backendData);
      }, context: operation);
      
      if (response.success && response.data != null) {
        // 7. Mapear respuesta a Evento
        final eventos = _mapper.filterActiveEvents([response.data!]);
        final createdEvento = eventos.isNotEmpty ? eventos.first : null;
        
        if (createdEvento != null) {
          // 8. Sincronizar con backend service
          _syncService.addPendingOperation(SyncOperation(
            type: SyncOperationType.event,
            data: backendData,
            method: 'POST',
          ));
          
          // 9. Notificar
          await _notificationManager.showEventStartedNotification('Evento creado: ${createdEvento.titulo}');
        }
        
        _updateLoadingState(operation, EventoLoadingState.success);
        return ApiResponse<Evento>(
          success: true,
          data: createdEvento,
          message: response.message,
        );
      } else {
        final appError = _errorHandler.handleError(response.message, context: operation);
        _updateLoadingState(operation, EventoLoadingState.error, error: appError.userFriendlyMessage);
        return ApiResponse<Evento>(
          success: false,
          message: appError.userFriendlyMessage,
        );
      }
    } catch (e) {
      final appError = _errorHandler.handleError(e, context: operation);
      debugPrint('❌ Error in crearEvento: ${appError.message}');
      _updateLoadingState(operation, EventoLoadingState.error, error: appError.userFriendlyMessage);
      return ApiResponse<Evento>(
        success: false,
        message: appError.userFriendlyMessage,
      );
    }
  }

  /// ✅ EDITAR EVENTO EXISTENTE
  Future<ApiResponse<Evento>> editarEvento(Evento evento) async {
    const operation = 'editarEvento';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      // 1. Obtener usuario actual
      final usuario = await _storageService.getUser();
      
      // 2. Validar
      final validation = _validator.validateEventUpdate(evento, usuario);
      if (!validation.isValid) {
        _updateLoadingState(operation, EventoLoadingState.error, error: validation.message);
        return ApiResponse<Evento>(
          success: false,
          message: validation.message,
        );
      }
      
      // 3. Mapear a formato backend
      final backendData = _mapper.mapFlutterToBackend(evento);
      
      // 4. Actualizar en backend
      final response = await _repository.updateEvent(evento.id!, backendData);
      
      if (response.success && response.data != null) {
        // 5. Mapear respuesta
        final eventos = _mapper.filterActiveEvents([response.data!]);
        final updatedEvento = eventos.isNotEmpty ? eventos.first : null;
        
        _updateLoadingState(operation, EventoLoadingState.success);
        return ApiResponse<Evento>(
          success: true,
          data: updatedEvento,
          message: response.message,
        );
      } else {
        _updateLoadingState(operation, EventoLoadingState.error, error: response.message);
        return ApiResponse<Evento>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in editarEvento: $e');
      _updateLoadingState(operation, EventoLoadingState.error, error: e.toString());
      return ApiResponse<Evento>(
        success: false,
        message: 'Error inesperado: $e',
      );
    }
  }

  /// ✅ ELIMINAR EVENTO (SOFT DELETE)
  Future<ApiResponse<bool>> eliminarEvento(String eventoId) async {
    const operation = 'eliminarEvento';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      // 1. Obtener usuario actual
      final usuario = await _storageService.getUser();
      
      // 2. Validar
      final validation = _validator.validateEventDeletion(eventoId, usuario);
      if (!validation.isValid) {
        _updateLoadingState(operation, EventoLoadingState.error, error: validation.message);
        return ApiResponse<bool>(
          success: false,
          data: false,
          message: validation.message,
        );
      }
      
      // 3. Eliminar en backend (soft delete)
      final response = await _repository.deleteEvent(eventoId);
      
      _updateLoadingState(operation, EventoLoadingState.success);
      return response;
    } catch (e) {
      debugPrint('❌ Error in eliminarEvento: $e');
      _updateLoadingState(operation, EventoLoadingState.error, error: e.toString());
      return ApiResponse<bool>(
        success: false,
        data: false,
        message: 'Error inesperado: $e',
      );
    }
  }

  /// ✅ TOGGLE ESTADO ACTIVO
  Future<bool> toggleEventoActive(String eventoId, bool isActive) async {
    const operation = 'toggleEventoActive';
    _updateLoadingState(operation, EventoLoadingState.loading);

    try {
      // 1. Obtener usuario actual
      final usuario = await _storageService.getUser();
      
      // 2. Validar
      final validation = _validator.validateToggleActive(eventoId, isActive, usuario);
      if (!validation.isValid) {
        debugPrint('❌ Toggle validation failed: ${validation.message}');
        _updateLoadingState(operation, EventoLoadingState.error, error: validation.message);
        return false;
      }
      
      // 3. Toggle en backend
      final success = await _repository.toggleEventActive(eventoId, isActive);
      
      _updateLoadingState(operation, EventoLoadingState.success);
      return success;
    } catch (e) {
      debugPrint('❌ Error in toggleEventoActive: $e');
      _updateLoadingState(operation, EventoLoadingState.error, error: e.toString());
      return false;
    }
  }

  /// ✅ OBTENER MÉTRICAS DE EVENTO
  Future<Map<String, dynamic>> obtenerMetricasEvento(String eventoId) async {
    try {
      final metrics = await _repository.fetchEventMetrics(eventoId);
      return metrics ?? {};
    } catch (e) {
      debugPrint('❌ Error fetching event metrics: $e');
      return {};
    }
  }

  /// ✅ LIBERAR ESTUDIANTES DE EVENTOS TERMINADOS
  Future<void> _liberarEstudiantesDeEventosTerminados(List<Evento> allEvents) async {
    try {
      // 1. Filtrar eventos finalizados
      final eventosTerminados = _mapper.filterFinishedEvents(allEvents);
      
      if (eventosTerminados.isEmpty) {
        debugPrint('📝 No finished events found for student liberation');
        return;
      }
      
      // 2. Obtener claves de storage relacionadas con eventos
      final storageKeys = await _storageService.getAllKeys();
      final eventKeys = storageKeys.where((key) => key.startsWith('student_event_')).toList();
      
      debugPrint('📚 Student storage keys related to events:');
      for (final key in eventKeys) {
        debugPrint('  - $key');
      }
      
      // 3. Limpiar datos de eventos finalizados
      for (final evento in eventosTerminados) {
        final eventKey = 'student_event_${evento.id}';
        if (eventKeys.contains(eventKey)) {
          await _storageService.removeData(eventKey);
          debugPrint('🧹 Cleaned up data for finished event: ${evento.titulo}');
        }
      }
      
      // 4. Verificar estado actual del estudiante
      final currentEventData = await _storageService.getData('current_student_event');
      debugPrint('🔍 Current student event data: $currentEventData');
      
      if (currentEventData == null) {
        debugPrint('📝 No current event data found for student');
      }
      
    } catch (e) {
      debugPrint('❌ Error liberating students from finished events: $e');
    }
  }

  /// ⚙️ UTILIDADES PRIVADAS

  /// Actualizar estado de loading
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

  /// 🧹 CLEANUP
  void dispose() {
    _stateController.close();
    _repository.dispose();
    _mapper.dispose();
    _validator.dispose();
    debugPrint('🧹 EventoService disposed');
  }
}

/// ✅ ESTADOS DE LOADING (mantener compatibilidad)
enum EventoLoadingState {
  idle,
  loading,
  success,
  error,
}

/// ✅ DATOS DE ESTADO (mantener compatibilidad)
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