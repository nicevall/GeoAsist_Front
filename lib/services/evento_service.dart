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

// lib/services/evento_service.dart - Sección corregida

  Future<List<Evento>> obtenerEventos() async {
    try {
      final response = await _apiService.get(AppConstants.eventosEndpoint);

      if (response.success && response.data != null) {
        final responseData = response.data!;

        // Inicializar lista vacía
        List<dynamic> eventosList = <dynamic>[];

        // Verificar el tipo de respuesta del backend con manejo seguro
        if (responseData is List) {
          // Caso 1: El backend retorna directamente una lista de eventos
          eventosList = List<dynamic>.from(responseData as Iterable);
        } else {
          // Caso 2: El backend retorna un objeto que contiene la lista
          // CAMBIO: Removemos la verificación redundante 'is Map<String, dynamic>'
          final eventosData = responseData['eventos'];
          if (eventosData != null && eventosData is List) {
            eventosList = List<dynamic>.from(eventosData);
          } else {
            // Si responseData es un Map pero no tiene la estructura esperada,
            // podría ser un solo evento, así que lo convertimos en lista
            eventosList = <dynamic>[responseData];
          }
        }

        // Resto del código permanece igual...
        final List<Evento> eventos = <Evento>[];
        for (int i = 0; i < eventosList.length; i++) {
          final eventoData = eventosList[i];
          if (eventoData is Map<String, dynamic>) {
            try {
              final evento = Evento.fromJson(eventoData);
              eventos.add(evento);
            } catch (e) {
              debugPrint('Error al parsear evento en índice $i: $e');
            }
          } else {
            debugPrint(
                'Elemento en índice $i no es un Map válido: $eventoData');
          }
        }

        debugPrint('Se obtuvieron ${eventos.length} eventos exitosamente');
        return eventos;
      }

      debugPrint('Respuesta no exitosa o datos nulos');
      return <Evento>[];
    } catch (e) {
      debugPrint('Error al obtener eventos: $e');
      return <Evento>[];
    }
  }

  Future<Evento?> obtenerEventoPorId(String eventoId) async {
    try {
      final response =
          await _apiService.get('${AppConstants.eventosEndpoint}/$eventoId');

      if (response.success && response.data != null) {
        return Evento.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener evento: $e');
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
        'titulo': titulo,
        'descripcion': descripcion,
        'ubicacion': {
          'latitud': latitud,
          'longitud': longitud,
        },
        'fecha': fecha.toIso8601String(),
        'horaInicio': horaInicio.toIso8601String(),
        'horaFinal': horaFinal.toIso8601String(),
        'rangoPermitido': rangoPermitido,
      };

      final response = await _apiService.post(
        '${AppConstants.eventosEndpoint}/crear',
        body: body,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          final evento = Evento.fromJson(eventoData);
          return ApiResponse.success(evento, message: response.message);
        }
      }

      return ApiResponse.error(response.error ?? 'Error al crear evento');
    } catch (e) {
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

      final response = await _apiService.put(
        '${AppConstants.eventosEndpoint}/$eventoId',
        body: datosActualizados,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final eventoData = response.data!['evento'];
        if (eventoData != null) {
          final evento = Evento.fromJson(eventoData);
          return ApiResponse.success(evento, message: response.message);
        }
      }

      return ApiResponse.error(response.error ?? 'Error al actualizar evento');
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<bool> eliminarEvento(String eventoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      final response = await _apiService.delete(
        '${AppConstants.eventosEndpoint}/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }
}
