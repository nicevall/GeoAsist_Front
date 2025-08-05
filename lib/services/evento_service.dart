// lib/services/evento_service.dart - VERSIÓN COMPLETA CORREGIDA
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
            debugPrint('❌ No se encontró array de eventos en el objeto');
            debugPrint('❌ Claves disponibles: ${responseData.keys.toList()}');
            return <Evento>[];
          }
        } else if (responseData is List<dynamic>) {
          // Caso 2: Respuesta es directamente un array
          eventosList = responseData;
          debugPrint(
              '✅ Respuesta directa como array: ${eventosList.length} eventos');
        } else {
          debugPrint(
              '❌ Tipo de respuesta no soportado: ${responseData.runtimeType}');
          return <Evento>[];
        }

        // ✅ CORREGIDO: Parseo de eventos con validación específica del backend
        final List<Evento> eventos = <Evento>[];
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          debugPrint('🔄 Procesando evento $i');

          if (eventoData is Map<String, dynamic>) {
            debugPrint('🔄 Claves del evento $i: ${eventoData.keys.toList()}');
            try {
              // ✅ VALIDAR campos específicos del backend
              if (_isValidBackendEventData(eventoData)) {
                // ✅ MAPEAR campos del backend a modelo Flutter
                final eventoMapeado = _mapBackendToFlutter(eventoData);
                final evento = Evento.fromJson(eventoMapeado);
                eventos.add(evento);
                debugPrint('✅ Evento parseado: ${evento.titulo}');
              } else {
                debugPrint(
                    '❌ Evento $i no tiene estructura válida del backend');
              }
            } catch (e) {
              debugPrint('❌ Error parseando evento $i: $e');
              debugPrint('❌ Datos del evento problemático: $eventoData');
            }
          } else {
            debugPrint(
                '❌ Elemento $i no es Map<String, dynamic>: ${eventoData.runtimeType}');
          }
        }

        debugPrint(
            '🎯 Total eventos parseados exitosamente: ${eventos.length}');
        return eventos;
      }

      debugPrint('❌ Respuesta no exitosa o datos nulos');
      return <Evento>[];
    } catch (e) {
      debugPrint('❌ Error general obteniendo eventos: $e');
      return <Evento>[];
    }
  }

  /// ✅ CORREGIDO: Validación específica para estructura del backend
  bool _isValidBackendEventData(Map<String, dynamic> data) {
    debugPrint('🔍 Validando evento con claves: ${data.keys.toList()}');

    // Verificar campos mínimos requeridos (flexible)
    final hasId = data.containsKey('_id') || data.containsKey('id');
    final hasNombre = data.containsKey('nombre') || data.containsKey('titulo');

    if (!hasId) {
      debugPrint('❌ Falta ID del evento');
      return false;
    }

    if (!hasNombre) {
      debugPrint('❌ Falta nombre/titulo del evento');
      return false;
    }

    // Validar fechas (al menos una debe existir)
    final hasFechas = data.containsKey('fechaInicio') ||
        data.containsKey('horaInicio') ||
        data.containsKey('fecha');

    if (!hasFechas) {
      debugPrint('❌ Faltan datos de fecha/hora');
      return false;
    }

    debugPrint('✅ Evento válido para procesamiento');
    return true;
  }

  /// ✅ CORREGIDO: Mapear campos del backend a estructura que espera Flutter
  Map<String, dynamic> _mapBackendToFlutter(Map<String, dynamic> backendData) {
    debugPrint('🔄 Mapeando evento del backend a Flutter');
    debugPrint('📥 Datos de entrada: $backendData');

    try {
      // Mapeo de ID
      final id = backendData['_id'] ?? backendData['id'] ?? '';

      // Mapeo de título/nombre
      final titulo =
          backendData['titulo'] ?? backendData['nombre'] ?? 'Evento sin título';

      // Mapeo de descripción
      final descripcion = backendData['descripcion'] ?? '';

      // Mapeo de ubicación/coordenadas
      Map<String, dynamic> ubicacion = {
        'latitud': -0.1805, // UIDE por defecto
        'longitud': -78.4680,
      };

      if (backendData.containsKey('coordenadas') &&
          backendData['coordenadas'] is Map) {
        final coords = backendData['coordenadas'] as Map<String, dynamic>;
        ubicacion = {
          'latitud': coords['latitud'] ?? -0.1805,
          'longitud': coords['longitud'] ?? -78.4680,
        };
      } else if (backendData.containsKey('ubicacion') &&
          backendData['ubicacion'] is Map) {
        final coords = backendData['ubicacion'] as Map<String, dynamic>;
        ubicacion = {
          'latitud': coords['latitud'] ?? -0.1805,
          'longitud': coords['longitud'] ?? -78.4680,
        };
      }

      // Mapeo de fechas y horas
      DateTime fechaBase = DateTime.now().add(const Duration(days: 1));
      DateTime horaInicioCompleta = fechaBase;
      DateTime horaFinalCompleta = fechaBase.add(const Duration(hours: 2));

      // Intentar parsear fechas del backend
      if (backendData.containsKey('fechaInicio') &&
          backendData.containsKey('horaInicio')) {
        try {
          final fechaInicio = DateTime.parse(backendData['fechaInicio']);
          final horaInicioStr = backendData['horaInicio'].toString();

          if (horaInicioStr.contains(':')) {
            final horaParts = horaInicioStr.split(':');
            final horas = int.parse(horaParts[0]);
            final minutos = int.parse(horaParts[1]);

            horaInicioCompleta = DateTime(
              fechaInicio.year,
              fechaInicio.month,
              fechaInicio.day,
              horas,
              minutos,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error parseando fechaInicio/horaInicio: $e');
        }
      }

      if (backendData.containsKey('fechaFin') &&
          backendData.containsKey('horaFin')) {
        try {
          final fechaFin = DateTime.parse(backendData['fechaFin']);
          final horaFinStr = backendData['horaFin'].toString();

          if (horaFinStr.contains(':')) {
            final horaParts = horaFinStr.split(':');
            final horas = int.parse(horaParts[0]);
            final minutos = int.parse(horaParts[1]);

            horaFinalCompleta = DateTime(
              fechaFin.year,
              fechaFin.month,
              fechaFin.day,
              horas,
              minutos,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error parseando fechaFin/horaFin: $e');
        }
      }

      // Mapeo de rango permitido
      double rangoPermitido = 100.0;
      if (backendData.containsKey('coordenadas') &&
          backendData['coordenadas'] is Map &&
          backendData['coordenadas']['radio'] != null) {
        rangoPermitido =
            (backendData['coordenadas']['radio'] as num).toDouble();
      } else if (backendData.containsKey('rangoPermitido')) {
        rangoPermitido = (backendData['rangoPermitido'] as num).toDouble();
      }

      final eventoMapeado = {
        '_id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'ubicacion': ubicacion,
        'fecha': horaInicioCompleta.toIso8601String(),
        'horaInicio': horaInicioCompleta.toIso8601String(),
        'horaFinal': horaFinalCompleta.toIso8601String(),
        'rangoPermitido': rangoPermitido,
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
    required double latitud,
    required double longitud,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFinal,
    double rangoPermitido = 100.0,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      // ✅ CORREGIDO: Formato que espera el backend
      final body = {
        'nombre': titulo, // titulo → nombre
        'tipo': 'clase', // NUEVO: campo requerido
        'lugar': 'UIDE Campus Principal', // NUEVO: campo requerido
        'descripcion': descripcion ?? '', // Mantener descripción
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
      };

      debugPrint('📤 Body corregido enviado al backend: $body');
      debugPrint('🌐 Endpoint usado: ${AppConstants.eventosEndpoint}/crear');
      debugPrint('🔑 Headers enviados: ${AppConstants.getAuthHeaders(token)}');

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

  Future<bool> eliminarEvento(String eventoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      debugPrint('🗑️ Eliminando evento ID: $eventoId');

      final response = await _apiService.delete(
        '${AppConstants.eventosEndpoint}/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Eliminar - Response success: ${response.success}');

      if (response.success) {
        debugPrint('✅ Evento eliminado exitosamente');
      } else {
        debugPrint('❌ Error eliminando evento: ${response.error}');
      }

      return response.success;
    } catch (e) {
      debugPrint('💥 Error eliminando evento: $e');
      return false;
    }
  }
}
