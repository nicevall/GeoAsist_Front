// lib/services/evento_service.dart - VERSIÓN COMPLETA FASE B
import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class EventoService {
  static final EventoService _instance = EventoService._internal();
  factory EventoService() => _instance;
  EventoService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<List<Evento>> obtenerEventos() async {
    try {
      final response = await _apiService.get(AppConstants.eventosEndpoint);

      if (response.success && response.data != null) {
        final dynamic responseData = response.data;

        debugPrint('🔍 Estructura completa de respuesta: $responseData');
        debugPrint('🔍 Tipo de responseData: ${responseData.runtimeType}');

        List<dynamic> eventosList = <dynamic>[];

        // ✅ CORREGIDO: Manejo correcto de tipos sin errores
        if (responseData is Map<String, dynamic>) {
          // Caso 1: Respuesta es un objeto con array interno
          if (responseData.containsKey('data')) {
            final dataField = responseData['data'];
            if (dataField is List<dynamic>) {
              eventosList = dataField;
              debugPrint(
                  '✅ Encontrado array en "data": ${eventosList.length} eventos');
            } else {
              debugPrint(
                  '❌ El campo "data" no es un array: ${dataField.runtimeType}');
              return <Evento>[];
            }
          } else if (responseData.containsKey('eventos')) {
            final eventosField = responseData['eventos'];
            if (eventosField is List<dynamic>) {
              eventosList = eventosField;
              debugPrint(
                  '✅ Encontrado array en "eventos": ${eventosList.length} eventos');
            } else {
              debugPrint(
                  '❌ El campo "eventos" no es un array: ${eventosField.runtimeType}');
              return <Evento>[];
            }
          } else {
            debugPrint(
                '❌ Respuesta es objeto pero no contiene "data" ni "eventos"');
            debugPrint('🔍 Claves disponibles: ${responseData.keys.toList()}');
            return <Evento>[];
          }
        } else if (responseData is List<dynamic>) {
          // Caso 2: Respuesta es directamente un array
          eventosList = responseData;
          debugPrint(
              '✅ Respuesta es array directo: ${eventosList.length} eventos');
        } else {
          debugPrint(
              '❌ Tipo de respuesta no soportado: ${responseData.runtimeType}');
          return <Evento>[];
        }

        // Procesar la lista de eventos
        final eventos = <Evento>[];
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          debugPrint('🔍 Procesando evento $i: $eventoData');

          if (eventoData is Map<String, dynamic>) {
            if (_isValidBackendEventData(eventoData)) {
              try {
                final eventoMapeado = _mapBackendToFlutter(eventoData);
                final evento = Evento.fromJson(eventoMapeado);
                eventos.add(evento);
                debugPrint('✅ Evento $i parseado: ${evento.titulo}');
              } catch (e) {
                debugPrint('⚠️ Error parseando evento $i: $e');
                debugPrint('📄 Datos del evento problemático: $eventoData');
              }
            } else {
              debugPrint('⚠️ Evento $i no tiene datos válidos');
            }
          } else {
            debugPrint(
                '⚠️ Evento $i no es un objeto válido: ${eventoData.runtimeType}');
          }
        }

        debugPrint('✅ Total eventos parseados exitosamente: ${eventos.length}');
        return eventos;
      } else {
        debugPrint('❌ Error en respuesta: ${response.error}');
        return <Evento>[];
      }
    } catch (e) {
      debugPrint('💥 Error crítico obteniendo eventos: $e');
      return <Evento>[];
    }
  }

  bool _isValidBackendEventData(Map<String, dynamic> data) {
    return data.containsKey('_id') &&
        (data.containsKey('titulo') || data.containsKey('nombre'));
  }

  Map<String, dynamic> _mapBackendToFlutter(Map<String, dynamic> backendData) {
    try {
      debugPrint(
          '🔄 Mapeando evento: ${backendData['titulo'] ?? backendData['nombre']}');

      // Coordenadas/ubicación
      final coordenadas =
          backendData['coordenadas'] ?? backendData['ubicacion'];
      double latitud = -0.1805; // Default UIDE
      double longitud = -78.4680; // Default UIDE

      if (coordenadas is Map<String, dynamic>) {
        latitud = (coordenadas['latitud'] ?? coordenadas['lat'])?.toDouble() ??
            latitud;
        longitud =
            (coordenadas['longitud'] ?? coordenadas['lng'])?.toDouble() ??
                longitud;
      }

      // Fechas y horas
      DateTime fechaInicio = DateTime.now().add(const Duration(days: 1));
      DateTime fechaFinal =
          DateTime.now().add(const Duration(days: 1, hours: 2));

      // Procesar fechas del backend
      if (backendData.containsKey('fechaInicio') &&
          backendData['fechaInicio'] != null) {
        try {
          fechaInicio = DateTime.parse(backendData['fechaInicio'].toString());
        } catch (e) {
          debugPrint('⚠️ Error parseando fechaInicio: $e');
        }
      }

      if (backendData.containsKey('fechaFin') &&
          backendData['fechaFin'] != null) {
        try {
          fechaFinal = DateTime.parse(backendData['fechaFin'].toString());
        } catch (e) {
          debugPrint('⚠️ Error parseando fechaFin: $e');
        }
      }

      // Combinar fecha con hora si están separadas
      if (backendData.containsKey('horaInicio') &&
          backendData['horaInicio'] != null) {
        try {
          final horaInicio = backendData['horaInicio'].toString();
          final parts = horaInicio.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            fechaInicio = DateTime(
              fechaInicio.year,
              fechaInicio.month,
              fechaInicio.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error parseando horaInicio: $e');
        }
      }

      if (backendData.containsKey('horaFin') &&
          backendData['horaFin'] != null) {
        try {
          final horaFin = backendData['horaFin'].toString();
          final parts = horaFin.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            fechaFinal = DateTime(
              fechaFinal.year,
              fechaFinal.month,
              fechaFinal.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error parseando horaFin: $e');
        }
      }

      final eventoMapeado = {
        '_id': backendData['_id'] ?? backendData['id'] ?? '',
        'titulo': backendData['titulo'] ??
            backendData['nombre'] ??
            'Evento sin título',
        'descripcion': backendData['descripcion'] ?? '',
        'ubicacion': {
          'latitud': latitud,
          'longitud': longitud,
        },
        'fecha': fechaInicio.toIso8601String(),
        'horaInicio': fechaInicio.toIso8601String(),
        'horaFinal': fechaFinal.toIso8601String(),
        'rangoPermitido':
            (coordenadas?['radio'] ?? backendData['rangoPermitido'] ?? 100.0)
                .toDouble(),
        'creadoPor': backendData['creadorId'] ?? backendData['creadoPor'] ?? '',
        'createdAt': backendData['createdAt'],
        'updatedAt': backendData['updatedAt'],
      };

      debugPrint('📤 Evento mapeado exitosamente: ${eventoMapeado['titulo']}');
      return eventoMapeado;
    } catch (e) {
      debugPrint('❌ Error en mapeo: $e');
      // Devolver estructura mínima válida
      return {
        '_id': backendData['_id'] ?? backendData['id'] ?? '',
        'titulo': backendData['titulo'] ??
            backendData['nombre'] ??
            'Evento sin título',
        'descripcion': backendData['descripcion'] ?? '',
        'ubicacion': {
          'latitud': -0.1805,
          'longitud': -78.4680,
        },
        'fecha': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'horaInicio':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'horaFinal': DateTime.now()
            .add(const Duration(days: 1, hours: 2))
            .toIso8601String(),
        'rangoPermitido': 100.0,
        'creadoPor': '',
        'createdAt': null,
        'updatedAt': null,
      };
    }
  }

  Future<Evento?> obtenerEventoPorId(String eventoId) async {
    try {
      debugPrint('🔍 Obteniendo evento por ID: $eventoId');
      final response =
          await _apiService.get('${AppConstants.eventosEndpoint}/$eventoId');

      debugPrint('📡 Evento por ID - Success: ${response.success}');
      debugPrint('📄 Evento por ID - Data: ${response.data}');

      if (response.success && response.data != null) {
        if (_isValidBackendEventData(response.data!)) {
          final eventoMapeado = _mapBackendToFlutter(response.data!);
          final evento = Evento.fromJson(eventoMapeado);
          debugPrint('✅ Evento individual parseado: ${evento.titulo}');
          return evento;
        } else {
          debugPrint('❌ Datos de evento inválidos para ID: $eventoId');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('💥 Error al obtener evento: $e');
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
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      // ✅ CORREGIDO: Formato que espera el backend
      final body = {
        'nombre': titulo,
        'tipo': tipo,
        'lugar': lugar,
        'descripcion': descripcion ?? '',
        'capacidadMaxima': capacidadMaxima,
        'coordenadas': {
          // ubicacion → coordenadas
          'latitud': latitud,
          'longitud': longitud,
          'radio': rangoPermitido, // rangoPermitido → radio
        },
        'fechaInicio':
            fecha.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
        'fechaFin':
            fecha.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
        'horaInicio':
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}', // HH:mm
        'horaFin':
            '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}', // HH:mm
        'politicasAsistencia': {
          'tiempoGracia': tiempoGracia,
          'maximoSalidas': maximoSalidas,
          'tiempoLimiteSalida': tiempoLimiteSalida,
          'verificacionContinua': verificacionContinua,
          'requiereJustificacion': requiereJustificacion,
        },
      };

      debugPrint('📤 Body corregido enviado al backend: $body');
      debugPrint('🌐 Endpoint usado: ${AppConstants.eventosEndpoint}/crear');

      final response = await _apiService.post(
        '${AppConstants.eventosEndpoint}/crear',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Crear evento - Response success: ${response.success}');
      debugPrint('📄 Crear evento - Response data: ${response.data}');
      debugPrint('💬 Crear evento - Response message: ${response.message}');
      debugPrint('❌ Crear evento - Response error: ${response.error}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          debugPrint('✅ Evento creado exitosamente');
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          return ApiResponse.success(evento, message: response.message);
        } else {
          debugPrint('❌ No se encontró evento en la respuesta');
        }
      }

      return ApiResponse.error(response.error ?? 'Error al crear evento');
    } catch (e) {
      debugPrint('💥 Error de conexión creando evento: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse<Evento>> actualizarEvento(
    String eventoId,
    Map<String, dynamic> datosActualizados,
  ) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      debugPrint('🔄 Actualizando evento ID: $eventoId');
      debugPrint('📝 Datos a actualizar: $datosActualizados');

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId',
        body: datosActualizados,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Actualizar - Response success: ${response.success}');
      debugPrint('📄 Actualizar - Response data: ${response.data}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null && _isValidBackendEventData(eventoData)) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          debugPrint('✅ Evento actualizado exitosamente');
          return ApiResponse.success(evento, message: response.message);
        }
      }

      return ApiResponse.error(response.error ?? 'Error al actualizar evento');
    } catch (e) {
      debugPrint('💥 Error actualizando evento: $e');
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
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

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

      final response = await _apiService.put(
        '/eventos/$eventoId',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          final eventoMapeado = _mapBackendToFlutter(eventoData);
          final evento = Evento.fromJson(eventoMapeado);
          return ApiResponse.success(evento, message: response.message);
        }
      }

      return ApiResponse.error(response.error ?? 'Error editando evento');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 2: Eliminar evento - FASE B
  Future<ApiResponse<bool>> eliminarEvento(String eventoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.delete(
        '/eventos/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        return ApiResponse.success(true,
            message: 'Evento eliminado exitosamente');
      }

      return ApiResponse.error(response.error ?? 'Error eliminando evento');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 3: Obtener eventos específicos del docente - FASE B
  Future<List<Evento>> obtenerEventosDocente(String docenteId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return [];

      final response = await _apiService.get(
        '/eventos/mis',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        // Procesar respuesta similar a obtenerEventos()
        final eventos = await _procesarEventosResponse(response.data!);
        return eventos.where((e) => e.creadoPor == docenteId).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo eventos del docente: $e');
      return [];
    }
  }

  // Método auxiliar reutilizable - FASE B
  Future<List<Evento>> _procesarEventosResponse(
      Map<String, dynamic> data) async {
    try {
      List<dynamic> eventosList = <dynamic>[];

      // ✅ CORREGIDO: Verificación de tipos adecuada
      if (data.containsKey('data')) {
        final dataField = data['data'];
        if (dataField is List<dynamic>) {
          eventosList = dataField;
        } else {
          debugPrint(
              '❌ Campo "data" no es una lista: ${dataField.runtimeType}');
        }
      } else if (data.containsKey('eventos')) {
        final eventosField = data['eventos'];
        if (eventosField is List<dynamic>) {
          eventosList = eventosField;
        } else {
          debugPrint(
              '❌ Campo "eventos" no es una lista: ${eventosField.runtimeType}');
        }
      } else {
        // ✅ CORREGIDO: No intentar asignar directamente data a eventosList
        debugPrint('❌ Respuesta no contiene "data" ni "eventos"');
        debugPrint('🔍 Claves disponibles: ${data.keys.toList()}');
        return <Evento>[];
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
            debugPrint('⚠️ Error parseando evento: $e');
          }
        }
      }

      return eventos;
    } catch (e) {
      debugPrint('❌ Error procesando respuesta de eventos: $e');
      return <Evento>[];
    }
  }
}
