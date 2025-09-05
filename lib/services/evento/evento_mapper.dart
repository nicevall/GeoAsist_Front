// lib/services/evento/evento_mapper.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../../models/evento_model.dart';

/// ✅ MAPPER: Transformaciones de datos + Filtro Soft Delete
/// Responsabilidades:
/// - 🚨 CRÍTICO: Filtrar eventos eliminados (soft delete)
/// - Mapeo backend → frontend (Evento model)
/// - Mapeo frontend → backend (JSON)
/// - Validaciones de datos durante mapeo
class EventoMapper {
  static final EventoMapper _instance = EventoMapper._internal();
  factory EventoMapper() => _instance;
  EventoMapper._internal();

  /// 🚨 FILTRO CRÍTICO: Eventos eliminados NO deben aparecer
  static const List<String> _excludedStates = ['eliminado', 'deleted', 'cancelado', 'inactivo'];

  /// ✅ FILTRAR EVENTOS ACTIVOS (Método principal)
  /// Este método resuelve el problema de soft delete
  List<Evento> filterActiveEvents(List<dynamic> backendEvents) {
    logger.d('🔍 Filtering ${backendEvents.length} events for validity...');
    
    final validEvents = backendEvents
        .where((event) => _isEventValid(event))
        .map((event) => mapBackendToFlutter(event))
        .where((evento) => evento != null)
        .cast<Evento>()
        .toList();

    logger.d('✅ Filtered events: ${validEvents.length}/${backendEvents.length} valid');
    
    // Log eventos eliminados para debugging
    final eliminados = backendEvents.length - validEvents.length;
    if (eliminados > 0) {
      logger.d('🗑️ Filtered out $eliminados deleted/invalid events');
    }
    
    return validEvents;
  }

  /// 🚨 VALIDACIÓN CRÍTICA: Verificar si evento es válido (no eliminado)
  bool _isEventValid(dynamic eventData) {
    if (eventData == null || eventData is! Map<String, dynamic>) {
      logger.d('🚫 Event data is null or not a Map');
      return false;
    }

    final estado = eventData['estado']?.toString().toLowerCase() ?? '';
    final nombre = eventData['nombre'] ?? eventData['titulo'] ?? 'Unknown';
    
    logger.d('🔍 Validating event: "$nombre" with estado: "$estado"');
    logger.d('🔍 Excluded states: $_excludedStates');
    
    // 🚨 FILTRO PRINCIPAL: Rechazar eventos eliminados
    if (_excludedStates.contains(estado)) {
      logger.d('🚫 FILTERING OUT deleted event: $nombre (estado: $estado)');
      logger.d('🚫 State "$estado" is in excluded list: $_excludedStates');
      return false;
    }

    // Validaciones adicionales
    final id = eventData['_id'] ?? eventData['id'];
    if (id == null || id.toString().isEmpty) {
      logger.d('⚠️ Event "$nombre" missing ID, filtering out');
      return false;
    }

    logger.d('✅ Event "$nombre" is VALID (estado: $estado)');
    return true;
  }

  /// ✅ MAPEO BACKEND → FLUTTER
  Evento? mapBackendToFlutter(dynamic eventData) {
    try {
      if (eventData == null || eventData is! Map<String, dynamic>) {
        logger.d('⚠️ Invalid event data type');
        return null;
      }

      // Log proceso de mapeo
      final nombre = eventData['nombre'] ?? eventData['titulo'] ?? 'Unknown';
      logger.d('🔍 Processing event: ${eventData.runtimeType}');
      logger.d('✅ Event mapped successfully: $nombre');

      // Usar el factory method existente del modelo
      return Evento.fromJson(eventData);
    } catch (e) {
      final nombre = eventData?['nombre'] ?? eventData?['titulo'] ?? 'Unknown';
      logger.d('❌ Error mapping event "$nombre": $e');
      return null;
    }
  }

  /// ✅ MAPEO FLUTTER → BACKEND
  Map<String, dynamic> mapFlutterToBackend(Evento evento) {
    try {
      return {
        if (evento.id != null) '_id': evento.id,
        'nombre': evento.titulo,
        'titulo': evento.titulo, // Backward compatibility
        'tipo': evento.tipo,
        'lugar': evento.lugar,
        'descripcion': evento.descripcion,
        'estado': evento.estado,
        'isActive': evento.isActive,
        'coordenadas': {
          'latitud': evento.ubicacion.latitud,
          'longitud': evento.ubicacion.longitud,
          'radio': evento.rangoPermitido,
        },
        'fechaInicio': evento.fecha.toIso8601String(),
        'horaInicio': _formatTimeForBackend(evento.horaInicio),
        'horaFin': _formatTimeForBackend(evento.horaFinal),
        'fechaFin': evento.fecha.toIso8601String(), // Asumiendo evento de un día
        'creadoPor': evento.creadoPor,
        'capacidadMaxima': 100, // Default value
        'duracionDias': 1, // Default value
        'duracionHoras': _calculateDurationHours(evento.horaInicio, evento.horaFinal),
        'politicasAsistencia': {
          'tiempoGracia': 5,
          'maximoSalidas': 2,
          'tiempoLimiteSalida': 15,
          'verificacionContinua': false,
          'requiereJustificacion': true,
        },
      };
    } catch (e) {
      logger.d('❌ Error mapping Evento to backend: $e');
      rethrow;
    }
  }

  /// ✅ FILTRO PARA EVENTOS DE ESTUDIANTES
  /// Solo eventos activos y en espera son visibles para estudiantes
  List<Evento> filterStudentEvents(List<Evento> eventos) {
    final studentEvents = eventos
        .where((evento) => _isStudentVisible(evento))
        .toList();

    final filtered = eventos.length - studentEvents.length;
    if (filtered > 0) {
      logger.d('🎓 Filtered out $filtered inactive events for students');
    }
    
    logger.d('✅ Student events loaded: ${studentEvents.length} active events');
    return studentEvents;
  }

  /// ✅ VALIDAR SI EVENTO ES VISIBLE PARA ESTUDIANTES
  bool _isStudentVisible(Evento evento) {
    final estado = evento.estado.toLowerCase();
    
    // Solo mostrar eventos activos o en espera
    if (estado == 'activo' || estado == 'en espera') {
      return true;
    }
    
    // Log eventos filtrados para estudiantes
    logger.d('🚫 Event "${evento.titulo}" not visible to students (estado: $estado)');
    return false;
  }

  /// ✅ FILTRO PARA EVENTOS FINALIZADOS
  /// Usado para la liberación automática de estudiantes
  List<Evento> filterFinishedEvents(List<Evento> eventos) {
    final finishedEvents = eventos
        .where((evento) => _isEventFinished(evento))
        .toList();

    logger.d('🔄 Checking ${finishedEvents.length} finished events for student liberation');
    
    if (finishedEvents.isNotEmpty) {
      logger.d('📋 Finished events:');
      for (final evento in finishedEvents) {
        logger.d('  - ${evento.titulo} (${evento.id}) - Estado: ${evento.estado}');
      }
    }
    
    return finishedEvents;
  }

  /// ✅ VERIFICAR SI EVENTO ESTÁ FINALIZADO
  bool _isEventFinished(Evento evento) {
    final estado = evento.estado.toLowerCase();
    return estado == 'finalizado' || estado == 'finished';
  }

  /// ✅ FILTRAR POR ESTADOS ESPECÍFICOS
  List<Evento> filterByStates(List<Evento> eventos, List<String> allowedStates) {
    return eventos
        .where((evento) => allowedStates.contains(evento.estado.toLowerCase()))
        .toList();
  }

  /// ✅ ESTADÍSTICAS DE FILTRADO
  Map<String, int> getFilteringStats(List<dynamic> originalData, List<Evento> filteredEvents) {
    final stats = <String, int>{};
    
    stats['total_backend'] = originalData.length;
    stats['total_filtered'] = filteredEvents.length;
    stats['eliminated'] = originalData.length - filteredEvents.length;
    
    // Contar por estados
    final Map<String, int> stateCount = {};
    for (final event in originalData) {
      if (event is Map<String, dynamic>) {
        final estado = event['estado']?.toString() ?? 'unknown';
        stateCount[estado] = (stateCount[estado] ?? 0) + 1;
      }
    }
    
    stats.addAll(stateCount);
    
    return stats;
  }

  /// 🚨 VERIFICAR SI HAY EVENTOS ELIMINADOS
  /// Para debugging y monitoreo
  bool hasDeletedEvents(List<dynamic> backendEvents) {
    return backendEvents.any((event) {
      if (event is Map<String, dynamic>) {
        final estado = event['estado']?.toString().toLowerCase() ?? '';
        return _excludedStates.contains(estado);
      }
      return false;
    });
  }

  /// 📊 LOG DETALLADO DE EVENTOS ELIMINADOS
  void logDeletedEvents(List<dynamic> backendEvents) {
    final deletedEvents = backendEvents.where((event) {
      if (event is Map<String, dynamic>) {
        final estado = event['estado']?.toString().toLowerCase() ?? '';
        return _excludedStates.contains(estado);
      }
      return false;
    }).toList();

    if (deletedEvents.isNotEmpty) {
      logger.d('🗑️ Found ${deletedEvents.length} deleted events:');
      for (final event in deletedEvents) {
        if (event is Map<String, dynamic>) {
          final nombre = event['nombre'] ?? event['titulo'] ?? 'Unknown';
          final estado = event['estado'] ?? 'Unknown';
          final id = event['_id'] ?? event['id'] ?? 'Unknown';
          logger.d('  - $nombre (ID: $id, Estado: $estado)');
        }
      }
    }
  }

  /// ⚙️ UTILIDADES PRIVADAS

  /// Formatear tiempo para backend
  String _formatTimeForBackend(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Calcular duración en horas
  int _calculateDurationHours(DateTime inicio, DateTime fin) {
    return fin.difference(inicio).inHours;
  }

  /// 📊 VALIDACIÓN DE INTEGRIDAD DE DATOS
  bool validateEventIntegrity(Evento evento) {
    // Validaciones básicas
    if (evento.titulo.isEmpty) return false;
    if (evento.id == null || evento.id!.isEmpty) return false;
    if (_excludedStates.contains(evento.estado.toLowerCase())) return false;
    
    // Validaciones de fechas
    if (evento.horaFinal.isBefore(evento.horaInicio)) return false;
    
    // Validaciones de ubicación
    if (evento.ubicacion.latitud.abs() > 90) return false;
    if (evento.ubicacion.longitud.abs() > 180) return false;
    
    return true;
  }

  /// 🧹 LIMPIEZA DE DATOS
  void dispose() {
    logger.d('🧹 EventoMapper disposed');
  }
}