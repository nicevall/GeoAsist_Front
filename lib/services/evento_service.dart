// lib/services/evento_service.dart
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

  /// Obtener eventos públicos (para estudiantes) o todos los eventos (para admin)
  Future<List<Evento>> obtenerEventos({bool soloMisEventos = false}) async {
    try {
      String endpoint = AppConstants.eventosEndpoint;
      Map<String, String>? headers;

      if (soloMisEventos) {
        // Para docentes: obtener solo sus eventos
        final token = await _storageService.getToken();
        if (token != null) {
          endpoint = '${AppConstants.eventosEndpoint}/mis';
          headers = AppConstants.getAuthHeaders(token);
        }
      }

      debugPrint('🌐 Llamando endpoint: $endpoint');
      debugPrint('🔑 Headers: $headers');

      final response = await _apiService.get(endpoint, headers: headers);

      debugPrint('📡 Response success: ${response.success}');
      debugPrint('📦 Response data type: ${response.data.runtimeType}');
      debugPrint('📄 Response data: ${response.data}');

      if (response.success && response.data != null) {
        final responseData = response.data!;
        List<dynamic> eventosList = <dynamic>[];

        // Verificar el tipo de respuesta del backend con manejo seguro
        if (responseData is List) {
          debugPrint(
              '📋 Respuesta es lista directa con ${responseData.length} elementos');
          eventosList = List<dynamic>.from(responseData as Iterable);
        } else {
          debugPrint('📋 Respuesta es objeto, buscando array interno...');
          final eventosData = responseData['eventos'];
          if (eventosData != null && eventosData is List) {
            debugPrint(
                '📋 Encontrado array "eventos" con ${eventosData.length} elementos');
            eventosList = List<dynamic>.from(eventosData);
          } else {
            debugPrint('📋 No se encontró array, tratando como evento único');
            eventosList = <dynamic>[responseData];
          }
        }

        debugPrint('🔢 Total elementos a procesar: ${eventosList.length}');

        // ✅ CORREGIDO: Parseo más robusto con validaciones mejoradas
        final List<Evento> eventos = <Evento>[];
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          debugPrint('🔄 Procesando evento $i: ${eventoData.runtimeType}');

          if (eventoData is Map<String, dynamic>) {
            try {
              // ✅ VALIDAR campos requeridos antes del parsing
              if (_isValidEventData(eventoData)) {
                final evento = Evento.fromJson(eventoData);
                eventos.add(evento);
                debugPrint(
                    '✅ Evento $i parseado exitosamente: ${evento.titulo}');
              } else {
                debugPrint('❌ Evento $i no pasó validación');
              }
            } catch (e) {
              debugPrint('❌ Error parseando evento $i: $e');
              debugPrint('📄 Datos problemáticos: $eventoData');
            }
          } else {
            debugPrint(
                '❌ Elemento $i no es Map válido: ${eventoData.runtimeType}');
          }
        }

        debugPrint('🎯 Eventos finales parseados: ${eventos.length}');
        return eventos;
      }

      debugPrint('❌ Respuesta no exitosa o datos nulos');
      return <Evento>[];
    } catch (e) {
      debugPrint('💥 Error general obteniendo eventos: $e');
      return <Evento>[];
    }
  }

  /// Método específico para docentes - obtener solo sus eventos
  Future<List<Evento>> obtenerMisEventos() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('No hay token para obtener eventos del docente');
        return <Evento>[];
      }

      debugPrint('🌐 Obteniendo MIS eventos...');
      final response = await _apiService.get(
        '${AppConstants.eventosEndpoint}/mis',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Mis eventos - Response success: ${response.success}');
      debugPrint('📄 Mis eventos - Response data: ${response.data}');

      if (response.success && response.data != null) {
        final responseData = response.data!;
        List<dynamic> eventosList = <dynamic>[];

        if (responseData is List) {
          debugPrint(
              '📋 Mis eventos: lista directa con ${responseData.length} elementos');
          eventosList = List<dynamic>.from(responseData as Iterable);
        } else {
          debugPrint('📋 Mis eventos: buscando en objeto...');
          final eventosData = responseData['eventos'];
          if (eventosData != null && eventosData is List) {
            debugPrint(
                '📋 Encontrado array "eventos" con ${eventosData.length} elementos');
            eventosList = List<dynamic>.from(eventosData);
          } else {
            debugPrint('📋 Tratando como evento único');
            eventosList = <dynamic>[responseData];
          }
        }

        final List<Evento> eventos = <Evento>[];
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          if (eventoData is Map<String, dynamic>) {
            try {
              if (_isValidEventData(eventoData)) {
                final evento = Evento.fromJson(eventoData);
                eventos.add(evento);
                debugPrint('✅ Mi evento $i parseado: ${evento.titulo}');
              }
            } catch (e) {
              debugPrint('❌ Error parseando mi evento $i: $e');
            }
          }
        }

        debugPrint('🎯 Total mis eventos parseados: ${eventos.length}');
        return eventos;
      }

      return <Evento>[];
    } catch (e) {
      debugPrint('💥 Error al obtener mis eventos: $e');
      return <Evento>[];
    }
  }

  /// ✅ MEJORADO: Validación más flexible para compatibilidad con backend
  bool _isValidEventData(Map<String, dynamic> data) {
    // Debug: Mostrar qué campos tiene el evento
    debugPrint('🔍 Evento recibido: ${data.keys.toList()}');
    debugPrint('📝 Contenido: $data');

    // Campos posibles para título (backend puede usar cualquiera)
    final titleFields = ['titulo', 'nombre', 'title', 'name'];

    bool hasTitle = false;
    for (String field in titleFields) {
      if (data.containsKey(field) &&
          data[field] != null &&
          data[field].toString().isNotEmpty) {
        hasTitle = true;
        debugPrint('✅ Título encontrado en campo: $field = ${data[field]}');
        break;
      }
    }

    if (!hasTitle) {
      debugPrint(
          '❌ Campo título/nombre faltante. Campos disponibles: ${data.keys.toList()}');
      return false;
    }

    // Validar fechas/horarios (al menos uno debe existir)
    final dateFields = [
      'fecha',
      'fechaInicio',
      'horaInicio',
      'startDate',
      'date'
    ];
    bool hasDate = false;
    for (String field in dateFields) {
      if (data.containsKey(field) && data[field] != null) {
        hasDate = true;
        debugPrint('✅ Fecha encontrada en campo: $field = ${data[field]}');
        break;
      }
    }

    if (!hasDate) {
      debugPrint('⚠️ Sin fechas válidas, pero permitiendo el evento');
      // No bloquear por fechas - el modelo puede manejar valores por defecto
    }

    // Validar ubicación/coordenadas (opcional - el modelo tiene valores por defecto)
    if (data.containsKey('ubicacion') && data['ubicacion'] != null) {
      final ubicacion = data['ubicacion'];
      if (ubicacion is Map<String, dynamic>) {
        if (!ubicacion.containsKey('latitud') ||
            !ubicacion.containsKey('longitud')) {
          debugPrint('⚠️ Ubicación incompleta - usando valores por defecto');
        } else {
          debugPrint(
              '✅ Ubicación válida: lat=${ubicacion['latitud']}, lng=${ubicacion['longitud']}');
        }
      }
    } else if (data.containsKey('coordenadas') && data['coordenadas'] != null) {
      final coordenadas = data['coordenadas'];
      if (coordenadas is Map<String, dynamic>) {
        if (!coordenadas.containsKey('latitud') ||
            !coordenadas.containsKey('longitud')) {
          debugPrint('⚠️ Coordenadas incompletas - usando valores por defecto');
        } else {
          debugPrint(
              '✅ Coordenadas válidas: lat=${coordenadas['latitud']}, lng=${coordenadas['longitud']}');
        }
      }
    } else {
      debugPrint('⚠️ Sin ubicación - usando valores por defecto (UIDE)');
    }

    debugPrint('✅ Evento válido para parseo');
    return true;
  }

  Future<Evento?> obtenerEventoPorId(String eventoId) async {
    try {
      debugPrint('🔍 Obteniendo evento por ID: $eventoId');
      final response =
          await _apiService.get('${AppConstants.eventosEndpoint}/$eventoId');

      debugPrint('📡 Evento por ID - Success: ${response.success}');
      debugPrint('📄 Evento por ID - Data: ${response.data}');

      if (response.success && response.data != null) {
        // ✅ VALIDAR antes de parsear
        if (_isValidEventData(response.data!)) {
          final evento = Evento.fromJson(response.data!);
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

      final body = {
        'nombre': titulo, // titulo → nombre
        'tipo': 'clase', // NUEVO: tipo requerido por backend
        'fechaInicio':
            fecha.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
        'fechaFin':
            fecha.toIso8601String().split('T')[0], // Solo fecha YYYY-MM-DD
        'horaInicio':
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}', // HH:mm
        'horaFin':
            '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}', // HH:mm
        'lugar': 'UIDE Campus Principal', // NUEVO: lugar requerido
        'descripcion': descripcion ?? '', // Mantener descripción
        'coordenadas': {
          // ubicacion → coordenadas
          'latitud': latitud,
          'longitud': longitud,
          'radio': rangoPermitido, // rangoPermitido → radio
        },
      };

      // ✅ AGREGADO: Debug del body
      debugPrint('🚀 Creando evento...');
      debugPrint('📤 Body enviado al backend: $body');
      debugPrint('🌐 Endpoint usado: ${AppConstants.eventosEndpoint}/crear');
      debugPrint('🔑 Headers enviados: ${AppConstants.getAuthHeaders(token)}');

      final response = await _apiService.post(
        '${AppConstants.eventosEndpoint}/crear',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      // ✅ AGREGADO: Debug completo de la respuesta del backend
      debugPrint('📡 Crear evento - Response success: ${response.success}');
      debugPrint('📄 Crear evento - Response data: ${response.data}');
      debugPrint('💬 Crear evento - Response message: ${response.message}');
      debugPrint('❌ Crear evento - Response error: ${response.error}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          debugPrint('✅ Evento creado exitosamente');
          final evento = Evento.fromJson(eventoData);
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
      debugPrint('📝 Datos originales: $datosActualizados');

      // Transformar datos al formato del backend antes de enviar
      final transformedData = <String, dynamic>{};
      if (datosActualizados.containsKey('titulo')) {
        transformedData['nombre'] = datosActualizados['titulo'];
      }
      if (datosActualizados.containsKey('ubicacion')) {
        transformedData['coordenadas'] = {
          'latitud': datosActualizados['ubicacion']['latitud'],
          'longitud': datosActualizados['ubicacion']['longitud'],
          'radio': datosActualizados['rangoPermitido'] ?? 100.0,
        };
      }
      // Copiar el resto de campos
      transformedData.addAll(datosActualizados);
      transformedData.remove('titulo');
      transformedData.remove('ubicacion');
      transformedData.remove('rangoPermitido');

      debugPrint('📤 Datos transformados: $transformedData');

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId',
        body: transformedData,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Actualizar - Response success: ${response.success}');
      debugPrint('📄 Actualizar - Response data: ${response.data}');

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null && _isValidEventData(eventoData)) {
          final evento = Evento.fromJson(eventoData);
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
