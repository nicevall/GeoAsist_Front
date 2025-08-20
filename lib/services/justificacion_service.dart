// lib/services/justificacion_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/justificacion_model.dart';
import '../models/api_response_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/asistencia_service.dart';
import '../services/evento_service.dart';
import '../core/app_constants.dart';

/// 📄 SERVICIO COMPLETO DE GESTIÓN DE JUSTIFICACIONES
/// Integra con el backend existente usando el campo 'observaciones' de asistencia
class JustificacionService {
  static final JustificacionService _instance = JustificacionService._internal();
  factory JustificacionService() => _instance;
  JustificacionService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final EventoService _eventoService = EventoService();

  /// 📝 CREAR NUEVA JUSTIFICACIÓN
  Future<ApiResponse<bool>> crearJustificacion({
    required String eventoId,
    required String motivo,
    required String linkDocumento,
    required JustificacionTipo tipo,
    String? documentoNombre,
    Map<String, dynamic>? metadatos,
  }) async {
    try {
      debugPrint('📄 Creando nueva justificación');
      debugPrint('🎯 Evento: $eventoId');
      debugPrint('📝 Motivo: $motivo');
      debugPrint('🔗 Documento: $linkDocumento');
      debugPrint('📋 Tipo: ${tipo.displayName}');

      // Obtener usuario actual
      final usuario = await _storageService.getUser();
      if (usuario == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      // Validar datos de entrada
      final erroresValidacion = _validarDatosJustificacion(
        motivo: motivo,
        linkDocumento: linkDocumento,
      );

      if (erroresValidacion.isNotEmpty) {
        return ApiResponse.error('Datos inválidos: ${erroresValidacion.join(', ')}');
      }

      // Crear justificación usando el servicio de asistencia existente
      final resultado = await _asistenciaService.enviarJustificacion(
        eventoId: eventoId,
        usuarioId: usuario.id,
        linkDocumento: linkDocumento,
        motivo: motivo,
      );

      if (resultado.success) {
        debugPrint('✅ Justificación creada exitosamente');
        return ApiResponse.success(true, message: 'Justificación enviada correctamente');
      } else {
        debugPrint('❌ Error creando justificación: ${resultado.error}');
        return ApiResponse.error(resultado.error ?? 'Error al crear justificación');
      }
    } catch (e) {
      debugPrint('❌ Excepción creando justificación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 📋 OBTENER JUSTIFICACIONES DEL USUARIO ACTUAL
  Future<ApiResponse<List<Justificacion>>> obtenerMisJustificaciones() async {
    try {
      debugPrint('📄 Obteniendo justificaciones del usuario actual');

      final usuario = await _storageService.getUser();
      if (usuario == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      return await obtenerJustificacionesUsuario(usuario.id);
    } catch (e) {
      debugPrint('❌ Error obteniendo mis justificaciones: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 📋 OBTENER JUSTIFICACIONES DE UN USUARIO ESPECÍFICO
  Future<ApiResponse<List<Justificacion>>> obtenerJustificacionesUsuario(String usuarioId) async {
    try {
      debugPrint('📄 Obteniendo justificaciones del usuario: $usuarioId');

      // Usar el método existente del servicio de asistencia
      final justificacionesData = await _asistenciaService.obtenerJustificaciones(usuarioId);
      
      final List<Justificacion> justificaciones = [];

      // Procesar los datos y obtener información adicional de eventos
      for (final justData in justificacionesData) {
        try {
          // Obtener información del evento
          String? eventTitle;
          final evento = await _eventoService.obtenerEventoPorId(justData['eventoId']);
          if (evento != null) {
            eventTitle = evento.titulo;
          }

          // Crear objeto Justificacion desde los datos del backend
          final justificacion = _crearJustificacionDesdeBackend(justData, eventTitle);
          justificaciones.add(justificacion);
        } catch (e) {
          debugPrint('⚠️ Error procesando justificación: $e');
          continue; // Continuar con la siguiente
        }
      }

      // Ordenar por fecha más reciente primero
      justificaciones.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      debugPrint('✅ Justificaciones obtenidas: ${justificaciones.length}');
      return ApiResponse.success(justificaciones);
    } catch (e) {
      debugPrint('❌ Error obteniendo justificaciones: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 📋 OBTENER JUSTIFICACIONES POR EVENTO (PARA DOCENTES)
  Future<ApiResponse<List<Justificacion>>> obtenerJustificacionesEvento(String eventoId) async {
    try {
      debugPrint('📄 Obteniendo justificaciones del evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      // Obtener todas las asistencias del evento que tengan justificaciones
      final response = await _apiService.get(
        '/asistencia/evento/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (!response.success) {
        return ApiResponse.error(response.error ?? 'Error obteniendo asistencias');
      }

      final List<Justificacion> justificaciones = [];
      final asistenciasData = response.data?['asistencias'] as List? ?? [];

      // Obtener información del evento
      String? eventTitle;
      final evento = await _eventoService.obtenerEventoPorId(eventoId);
      if (evento != null) {
        eventTitle = evento.titulo;
      }

      for (final asistenciaData in asistenciasData) {
        if (asistenciaData['observaciones'] != null) {
          try {
            final observaciones = jsonDecode(asistenciaData['observaciones']);
            if (observaciones['tipo'] == 'justificacion') {
              final justificacion = _crearJustificacionDesdeBackend(
                asistenciaData, 
                eventTitle,
              );
              justificaciones.add(justificacion);
            }
          } catch (e) {
            debugPrint('⚠️ Error procesando justificación del evento: $e');
            continue;
          }
        }
      }

      // Ordenar por fecha más reciente primero
      justificaciones.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      debugPrint('✅ Justificaciones del evento obtenidas: ${justificaciones.length}');
      return ApiResponse.success(justificaciones);
    } catch (e) {
      debugPrint('❌ Error obteniendo justificaciones del evento: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 📊 OBTENER ESTADÍSTICAS DE JUSTIFICACIONES
  Future<ApiResponse<JustificacionStats>> obtenerEstadisticasUsuario(String usuarioId) async {
    try {
      final response = await obtenerJustificacionesUsuario(usuarioId);
      
      if (response.success) {
        final stats = JustificacionStats.fromList(response.data!);
        return ApiResponse.success(stats);
      } else {
        return ApiResponse.error(response.error ?? 'Error obteniendo estadísticas');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 🔄 ACTUALIZAR ESTADO DE JUSTIFICACIÓN (PARA DOCENTES/ADMIN)
  Future<ApiResponse<bool>> actualizarEstadoJustificacion({
    required String justificacionId,
    required JustificacionEstado nuevoEstado,
    String? comentarioDocente,
  }) async {
    try {
      debugPrint('🔄 Actualizando estado de justificación: $justificacionId');
      debugPrint('📊 Nuevo estado: ${nuevoEstado.displayName}');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      // Actualizar el estado en el backend
      final response = await _apiService.put(
        '/asistencia/$justificacionId',
        body: {
          'estado': nuevoEstado.value,
          'comentarioDocente': comentarioDocente,
          'fechaRevision': DateTime.now().toIso8601String(),
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Estado de justificación actualizado');
        return ApiResponse.success(true, message: 'Estado actualizado correctamente');
      } else {
        debugPrint('❌ Error actualizando estado: ${response.error}');
        return ApiResponse.error(response.error ?? 'Error actualizando estado');
      }
    } catch (e) {
      debugPrint('❌ Error actualizando estado de justificación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 🗑️ ELIMINAR JUSTIFICACIÓN (SOLO PENDIENTES)
  Future<ApiResponse<bool>> eliminarJustificacion(String justificacionId) async {
    try {
      debugPrint('🗑️ Eliminando justificación: $justificacionId');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.delete(
        '/asistencia/$justificacionId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Justificación eliminada');
        return ApiResponse.success(true, message: 'Justificación eliminada correctamente');
      } else {
        debugPrint('❌ Error eliminando justificación: ${response.error}');
        return ApiResponse.error(response.error ?? 'Error eliminando justificación');
      }
    } catch (e) {
      debugPrint('❌ Error eliminando justificación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// 🔍 BUSCAR JUSTIFICACIONES CON FILTROS
  Future<ApiResponse<List<Justificacion>>> buscarJustificaciones({
    String? usuarioId,
    String? eventoId,
    JustificacionTipo? tipo,
    JustificacionEstado? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      debugPrint('🔍 Buscando justificaciones con filtros');

      // Si se especifica un usuario, obtener sus justificaciones
      if (usuarioId != null) {
        final response = await obtenerJustificacionesUsuario(usuarioId);
        if (response.success) {
          var justificaciones = response.data!;
          
          // Aplicar filtros adicionales
          justificaciones = _aplicarFiltros(
            justificaciones,
            eventoId: eventoId,
            tipo: tipo,
            estado: estado,
            fechaDesde: fechaDesde,
            fechaHasta: fechaHasta,
          );

          return ApiResponse.success(justificaciones);
        } else {
          return response;
        }
      }

      // Si se especifica un evento, obtener justificaciones del evento
      if (eventoId != null) {
        final response = await obtenerJustificacionesEvento(eventoId);
        if (response.success) {
          var justificaciones = response.data!;
          
          // Aplicar filtros adicionales
          justificaciones = _aplicarFiltros(
            justificaciones,
            tipo: tipo,
            estado: estado,
            fechaDesde: fechaDesde,
            fechaHasta: fechaHasta,
          );

          return ApiResponse.success(justificaciones);
        } else {
          return response;
        }
      }

      return ApiResponse.error('Debe especificar al menos usuarioId o eventoId');
    } catch (e) {
      debugPrint('❌ Error buscando justificaciones: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Validar datos de entrada para justificación
  List<String> _validarDatosJustificacion({
    required String motivo,
    required String linkDocumento,
  }) {
    List<String> errores = [];

    if (motivo.trim().isEmpty) {
      errores.add('El motivo es requerido');
    } else if (motivo.trim().length < 10) {
      errores.add('El motivo debe tener al menos 10 caracteres');
    }

    if (linkDocumento.trim().isEmpty) {
      errores.add('El link del documento es requerido');
    } else {
      try {
        final uri = Uri.parse(linkDocumento);
        if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
          errores.add('El link debe ser una URL válida (http/https)');
        }
      } catch (e) {
        errores.add('El formato del link no es válido');
      }
    }

    return errores;
  }

  /// Crear objeto Justificacion desde datos del backend
  Justificacion _crearJustificacionDesdeBackend(
    Map<String, dynamic> backendData,
    String? eventTitle,
  ) {
    // Parsear observaciones
    Map<String, dynamic> observaciones = {};
    if (backendData['observaciones'] != null) {
      try {
        observaciones = jsonDecode(backendData['observaciones']);
      } catch (e) {
        debugPrint('⚠️ Error parseando observaciones: $e');
      }
    }

    return Justificacion(
      id: backendData['id']?.toString(),
      usuarioId: backendData['usuarioId']?.toString() ?? '',
      eventoId: backendData['eventoId']?.toString() ?? '',
      eventTitle: eventTitle,
      motivo: observaciones['motivo']?.toString() ?? 'Sin motivo especificado',
      linkDocumento: observaciones['linkDocumento']?.toString() ?? '',
      tipo: JustificacionTipo.fromString(observaciones['tipoJustificacion']?.toString()),
      estado: JustificacionEstado.fromString(backendData['estado']?.toString()),
      fechaCreacion: DateTime.tryParse(observaciones['fechaEnvio']?.toString() ?? '') ?? DateTime.now(),
      fechaRevision: backendData['fechaRevision'] != null 
          ? DateTime.tryParse(backendData['fechaRevision'].toString())
          : null,
      comentarioDocente: backendData['comentarioDocente']?.toString(),
      documentoNombre: observaciones['documentoNombre']?.toString(),
      usuarioNombre: backendData['usuarioNombre']?.toString(),
      metadatos: observaciones['metadatos'] as Map<String, dynamic>?,
    );
  }

  /// Aplicar filtros a lista de justificaciones
  List<Justificacion> _aplicarFiltros(
    List<Justificacion> justificaciones, {
    String? eventoId,
    JustificacionTipo? tipo,
    JustificacionEstado? estado,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) {
    var resultado = justificaciones;

    if (eventoId != null) {
      resultado = resultado.where((j) => j.eventoId == eventoId).toList();
    }

    if (tipo != null) {
      resultado = resultado.where((j) => j.tipo == tipo).toList();
    }

    if (estado != null) {
      resultado = resultado.where((j) => j.estado == estado).toList();
    }

    if (fechaDesde != null) {
      resultado = resultado.where((j) => 
        j.fechaCreacion.isAfter(fechaDesde) || j.fechaCreacion.isAtSameMomentAs(fechaDesde)
      ).toList();
    }

    if (fechaHasta != null) {
      resultado = resultado.where((j) => 
        j.fechaCreacion.isBefore(fechaHasta) || j.fechaCreacion.isAtSameMomentAs(fechaHasta)
      ).toList();
    }

    return resultado;
  }

  /// 📊 OBTENER RESUMEN DE JUSTIFICACIONES PARA DASHBOARD
  Future<Map<String, dynamic>> obtenerResumenJustificaciones(String usuarioId) async {
    try {
      final response = await obtenerJustificacionesUsuario(usuarioId);
      
      if (response.success) {
        final justificaciones = response.data!;
        final stats = JustificacionStats.fromList(justificaciones);
        
        return {
          'total': stats.total,
          'pendientes': stats.pendientes,
          'aprobadas': stats.aprobadas,
          'rechazadas': stats.rechazadas,
          'porcentajeAprobacion': stats.porcentajeAprobacion,
          'ultimaJustificacion': justificaciones.isNotEmpty 
              ? justificaciones.first.fechaCreacion.toIso8601String()
              : null,
        };
      } else {
        return {
          'total': 0,
          'pendientes': 0,
          'aprobadas': 0,
          'rechazadas': 0,
          'porcentajeAprobacion': 0.0,
          'ultimaJustificacion': null,
        };
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo resumen de justificaciones: $e');
      return {
        'total': 0,
        'pendientes': 0,
        'aprobadas': 0,
        'rechazadas': 0,
        'porcentajeAprobacion': 0.0,
        'ultimaJustificacion': null,
      };
    }
  }
}