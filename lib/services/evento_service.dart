// lib/services/evento_service.dart
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
        // El backend retorna directamente la lista de eventos
        final eventosData = response.data;
        if (eventosData is List) {
          return eventosData.map((evento) => Evento.fromJson(evento)).toList();
        } else if (eventosData is Map && eventosData.containsKey('eventos')) {
          final eventosList = eventosData['eventos'] as List;
          return eventosList.map((evento) => Evento.fromJson(evento)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener eventos: $e');
      return [];
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
      print('Error al obtener evento: $e');
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
