// lib/services/asistencia_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/asistencia_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'dart:io';

/// Servicio para manejar todas las operaciones de asistencia con el backend real
class AsistenciaService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // 🎯 MÉTODO 1: Registrar asistencia en el backend real
  Future<ApiResponse<Asistencia>> registrarAsistencia({
    required String eventoId,
    required String usuarioId,
    required double latitud,
    required double longitud,
    required String estado, // 'presente', 'ausente', 'tarde', 'receso'
    String? observaciones,
  }) async {
    try {
      debugPrint('✅ Registrando asistencia en backend real');
      debugPrint('📍 Evento: $eventoId, Usuario: $usuarioId');
      debugPrint('🌍 Ubicación: ($latitud, $longitud)');
      debugPrint('📊 Estado: $estado');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para registrar asistencia');
        return ApiResponse.error('No hay sesión activa');
      }

      final requestData = {
        'eventoId': eventoId,
        'usuarioId': usuarioId,
        'latitud': latitud,
        'longitud': longitud,
        'estado': estado,
        'fecha': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
        'hora': DateTime.now()
            .toIso8601String()
            .split('T')[1]
            .split('.')[0], // HH:MM:SS
        if (observaciones != null) 'observaciones': observaciones,
      };

      debugPrint('📦 Request data: $requestData');

      // ✅ CORREGIDO: Usar body en lugar de data
      final response = await _apiService.post(
        '/asistencia/registrar',
        body: requestData,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Response success: ${response.success}');

      if (response.success && response.data != null) {
        final asistenciaData = response.data!['asistencia'] ?? response.data!;
        final asistencia = Asistencia.fromJson(asistenciaData);

        debugPrint('✅ Asistencia registrada exitosamente: ${asistencia.id}');
        return ApiResponse.success(asistencia,
            message: 'Asistencia registrada exitosamente');
      }

      debugPrint('❌ Error registrando asistencia: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error registrando asistencia');
    } catch (e) {
      debugPrint('❌ Excepción registrando asistencia: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 2: Actualizar ubicación en tiempo real
  Future<ApiResponse<bool>> actualizarUbicacion({
    required String usuarioId,
    required String eventoId,
    required double latitud,
    required double longitud,
    double? precision,
    double? speed,
  }) async {
    try {
      debugPrint('📍 Actualizando ubicación en tiempo real');
      debugPrint('🌍 Usuario: $usuarioId en evento: $eventoId');
      debugPrint(
          '📊 Coords: ($latitud, $longitud), precisión: ${precision ?? 'N/A'}m');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para actualizar ubicación');
        return ApiResponse.error('No hay sesión activa');
      }

      final locationData = {
        'usuarioId': usuarioId,
        'eventoId': eventoId,
        'latitud': latitud,
        'longitud': longitud,
        'timestamp': DateTime.now().toIso8601String(),
        if (precision != null) 'precision': precision,
        if (speed != null) 'speed': speed,
      };

      // ✅ CORREGIDO: Usar body en lugar de data
      final response = await _apiService.post(
        '/location/update',
        body: locationData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Ubicación actualizada exitosamente');
        return ApiResponse.success(true, message: 'Ubicación actualizada');
      }

      debugPrint('❌ Error actualizando ubicación: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error actualizando ubicación');
    } catch (e) {
      debugPrint('❌ Excepción actualizando ubicación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 3: Obtener asistencias de un evento específico (para profesor)
  Future<List<Asistencia>> obtenerAsistenciasEvento(String eventoId) async {
    try {
      debugPrint('👥 Obteniendo asistencias del evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para obtener asistencias');
        return [];
      }

      final response = await _apiService.get(
        '/asistencia/evento/$eventoId',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Response success: ${response.success}');

      if (response.success && response.data != null) {
        final List<dynamic> asistenciasData =
            response.data!['asistencias'] ?? response.data!;
        final asistencias =
            asistenciasData.map((data) => Asistencia.fromJson(data)).toList();

        debugPrint('✅ Asistencias cargadas: ${asistencias.length} registros');
        return asistencias;
      }

      debugPrint('❌ Error obteniendo asistencias: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('❌ Excepción obteniendo asistencias: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 4: Obtener historial de asistencias de un usuario
  Future<List<Asistencia>> obtenerHistorialUsuario(String usuarioId) async {
    try {
      debugPrint(
          '📚 Obteniendo historial de asistencias del usuario: $usuarioId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para obtener historial');
        return [];
      }

      final response = await _apiService.get(
        '/asistencia/usuario/$usuarioId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final List<dynamic> asistenciasData =
            response.data!['asistencias'] ?? response.data!;
        final asistencias =
            asistenciasData.map((data) => Asistencia.fromJson(data)).toList();

        // Ordenar por fecha más reciente primero
        asistencias.sort((a, b) => b.fecha.compareTo(a.fecha));

        debugPrint('✅ Historial cargado: ${asistencias.length} registros');
        return asistencias;
      }

      debugPrint('❌ Error obteniendo historial: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('❌ Excepción obteniendo historial: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 5: Obtener estadísticas personales de asistencia
  Future<Map<String, dynamic>> obtenerEstadisticasPersonales(
      String usuarioId) async {
    try {
      debugPrint(
          '📊 Obteniendo estadísticas personales del usuario: $usuarioId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para obtener estadísticas');
        return {};
      }

      final response = await _apiService.get(
        '/dashboard/student/$usuarioId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final stats = response.data!;
        debugPrint('✅ Estadísticas cargadas: $stats');
        return stats;
      }

      debugPrint('❌ Error obteniendo estadísticas: ${response.error}');
      return {};
    } catch (e) {
      debugPrint('❌ Excepción obteniendo estadísticas: $e');
      return {};
    }
  }

  // 🎯 MÉTODO 6: Enviar justificación con link de documento
  Future<ApiResponse<bool>> enviarJustificacion({
    required String eventoId,
    required String usuarioId,
    required String linkDocumento,
    String? motivo,
  }) async {
    try {
      debugPrint('📄 Enviando justificación con link');
      debugPrint('🔗 Link: $linkDocumento');
      debugPrint('📝 Motivo: ${motivo ?? 'No especificado'}');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No hay sesión activa para enviar justificación');
        return ApiResponse.error('No hay sesión activa');
      }

      // Validar que sea un link válido
      if (!_esLinkValido(linkDocumento)) {
        debugPrint('❌ Link no válido: $linkDocumento');
        return ApiResponse.error('El link proporcionado no es válido');
      }

      // Usar el campo observaciones para almacenar la justificación
      final justificacionData = {
        'usuarioId': usuarioId,
        'eventoId': eventoId,
        'estado': 'justificado',
        'observaciones': jsonEncode({
          'tipo': 'justificacion',
          'linkDocumento': linkDocumento,
          'motivo': motivo,
          'fechaEnvio': DateTime.now().toIso8601String(),
        }),
        'fecha': DateTime.now().toIso8601String().split('T')[0],
        'hora': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
        'latitud': 0.0, // No relevante para justificaciones
        'longitud': 0.0,
      };

      // ✅ CORREGIDO: Usar body en lugar de data
      final response = await _apiService.post(
        '/asistencia/registrar',
        body: justificacionData,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('✅ Justificación enviada exitosamente');
        return ApiResponse.success(true,
            message: 'Justificación enviada exitosamente');
      }

      debugPrint('❌ Error enviando justificación: ${response.error}');
      return ApiResponse.error(
          response.error ?? 'Error enviando justificación');
    } catch (e) {
      debugPrint('❌ Excepción enviando justificación: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO 7: Obtener justificaciones de un usuario
  Future<List<Map<String, dynamic>>> obtenerJustificaciones(
      String usuarioId) async {
    try {
      debugPrint('📄 Obteniendo justificaciones del usuario: $usuarioId');

      final asistencias = await obtenerHistorialUsuario(usuarioId);
      final justificaciones = <Map<String, dynamic>>[];

      for (final asistencia in asistencias) {
        if (asistencia.observaciones != null &&
            asistencia.observaciones!.isNotEmpty) {
          try {
            final observacionesData = jsonDecode(asistencia.observaciones!);
            if (observacionesData['tipo'] == 'justificacion') {
              justificaciones.add({
                'id': asistencia.id,
                'eventoId': asistencia.eventoId,
                'linkDocumento': observacionesData['linkDocumento'],
                'motivo': observacionesData['motivo'],
                'fechaEnvio': observacionesData['fechaEnvio'],
                'estado': asistencia.estado,
                'fecha': asistencia.fecha,
              });
            }
          } catch (e) {
            // Observaciones que no son JSON válido se ignoran
            continue;
          }
        }
      }

      debugPrint('✅ Justificaciones encontradas: ${justificaciones.length}');
      return justificaciones;
    } catch (e) {
      debugPrint('❌ Error obteniendo justificaciones: $e');
      return [];
    }
  }

  // 🎯 MÉTODO 8: Stream para actualizaciones en tiempo real
  Stream<List<Asistencia>> subscribeToAsistenciaUpdates(
      String eventoId) async* {
    while (true) {
      try {
        final asistencias = await obtenerAsistenciasEvento(eventoId);
        yield asistencias;

        // Esperar 30 segundos antes de la siguiente actualización
        await Future.delayed(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('❌ Error en stream de asistencias: $e');
        yield [];
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }

  // 🎯 MÉTODO 9: Validar estado de asistencia en un evento
  Future<String?> validarEstadoAsistencia(
      String usuarioId, String eventoId) async {
    try {
      debugPrint('🔍 Validando estado de asistencia');
      debugPrint('👤 Usuario: $usuarioId, Evento: $eventoId');

      final asistencias = await obtenerAsistenciasEvento(eventoId);
      final asistenciaUsuario =
          asistencias.where((a) => a.usuarioId == usuarioId).toList();

      if (asistenciaUsuario.isEmpty) {
        debugPrint('📋 Usuario sin asistencia registrada');
        return null;
      }

      // Obtener la asistencia más reciente
      asistenciaUsuario.sort((a, b) => b.fecha.compareTo(a.fecha));
      final ultimaAsistencia = asistenciaUsuario.first;

      debugPrint('✅ Estado actual: ${ultimaAsistencia.estado}');
      return ultimaAsistencia.estado;
    } catch (e) {
      debugPrint('❌ Error validando estado: $e');
      return null;
    }
  }

  // 🎯 MÉTODO 10: Marcar usuario como ausente (para app lifecycle)
  Future<ApiResponse<bool>> marcarAusente({
    required String usuarioId,
    required String eventoId,
    required String motivo,
  }) async {
    try {
      debugPrint('❌ Marcando usuario como ausente');
      debugPrint('📱 Motivo: $motivo');

      return await registrarAsistencia(
        eventoId: eventoId,
        usuarioId: usuarioId,
        latitud: 0.0, // Ubicación no relevante para ausencia
        longitud: 0.0,
        estado: 'ausente',
        observaciones: motivo,
      ).then((response) {
        if (response.success) {
          return ApiResponse.success(true,
              message: 'Usuario marcado como ausente');
        }
        return ApiResponse.error(response.error ?? 'Error marcando ausencia');
      });
    } catch (e) {
      debugPrint('❌ Error marcando ausente: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Obtener métricas de un evento específico
  Future<ApiResponse<Map<String, dynamic>>> obtenerMetricasEvento(
      String eventoId) async {
    try {
      debugPrint('📊 Obteniendo métricas del evento: $eventoId');

      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.get(
        '/eventos/$eventoId/metricas',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }

      return ApiResponse.error(response.error ?? 'Error obteniendo métricas');
    } catch (e) {
      debugPrint('❌ Error obteniendo métricas del evento: $e');
      rethrow;
    }
  }

  Future<ApiResponse<bool>> enviarHeartbeat({
    required String usuarioId,
    required String eventoId,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.post(
        '/heartbeat',
        body: {
          'usuarioId': usuarioId,
          'eventoId': eventoId,
          'timestamp': DateTime.now().toIso8601String(),
          'appStatus': 'active',
          'platform': Platform.operatingSystem,
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        debugPrint('💓 Heartbeat enviado exitosamente');
        return ApiResponse.success(true);
      }

      debugPrint('❌ Error en heartbeat: ${response.error}');
      return ApiResponse.error(response.error ?? 'Error en heartbeat');
    } catch (e) {
      debugPrint('❌ Excepción en heartbeat: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // 🎯 MÉTODO CRÍTICO 2: Marcar ausente específicamente por cierre de app
  Future<ApiResponse<bool>> marcarAusentePorCierreApp({
    required String usuarioId,
    required String eventoId,
  }) async {
    try {
      debugPrint('🚨 Marcando ausente por cierre de app');

      final response = await registrarAsistencia(
        eventoId: eventoId,
        usuarioId: usuarioId,
        latitud: 0.0, // No aplica
        longitud: 0.0, // No aplica
        estado: 'ausente',
        observaciones: jsonEncode({
          'tipo': 'ausencia_automatica',
          'motivo': 'Aplicación cerrada durante tracking',
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        }),
      );

      if (response.success) {
        debugPrint('✅ Marcado como ausente por cierre de app');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(response.error ?? 'Error marcando ausente');
    } catch (e) {
      debugPrint('❌ Excepción marcando ausente: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  // 🎯 MÉTODO CRÍTICO 3: Registrar eventos específicos de geofence
  Future<ApiResponse<bool>> registrarEventoGeofence({
    required String usuarioId,
    required String eventoId,
    required bool entrando, // true = entrando, false = saliendo
    required double latitud,
    required double longitud,
  }) async {
    try {
      final tipoEvento = entrando ? 'entrada_area' : 'salida_area';
      debugPrint('📍 Registrando $tipoEvento de geofence');

      final response = await actualizarUbicacion(
        usuarioId: usuarioId,
        eventoId: eventoId,
        latitud: latitud,
        longitud: longitud,
      );

      if (response.success) {
        debugPrint('✅ Evento geofence registrado: $tipoEvento');
        return ApiResponse.success(true);
      }

      return ApiResponse.error(response.error ?? 'Error registrando geofence');
    } catch (e) {
      debugPrint('❌ Excepción registrando geofence: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  // 🔧 MÉTODOS UTILITARIOS

  bool _esLinkValido(String link) {
    // Validar que sea una URL válida
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return false;
    }

    // Validar dominios permitidos para documentos
    final dominiosPermitidos = [
      'drive.google.com',
      'docs.google.com',
      'onedrive.live.com',
      '1drv.ms',
      'dropbox.com',
      'docdroid.net',
      'scribd.com',
    ];

    return dominiosPermitidos.any((dominio) => uri.host.contains(dominio));
  }

  // Validar link de documento específico
  bool validarLinkValido(String url) {
    return _esLinkValido(url);
  }

  // Obtener dominios permitidos para UI
  List<String> get dominiosPermitidos => [
        'Google Drive (drive.google.com)',
        'Google Docs (docs.google.com)',
        'OneDrive (onedrive.live.com)',
        'OneDrive Short (1drv.ms)',
        'Dropbox (dropbox.com)',
        'DocDroid (docdroid.net)',
        'Scribd (scribd.com)',
      ];

  // Limpiar cache de asistencias (útil para debugging)
  void limpiarCache() {
    debugPrint('🧹 Limpiando cache de AsistenciaService');
    // En el futuro se puede implementar cache local si es necesario
  }

  // Obtener resumen de asistencias por estado
  Map<String, int> obtenerResumenEstados(List<Asistencia> asistencias) {
    final resumen = <String, int>{
      'presente': 0,
      'ausente': 0,
      'tarde': 0,
      'justificado': 0,
      'receso': 0,
    };

    for (final asistencia in asistencias) {
      resumen[asistencia.estado] = (resumen[asistencia.estado] ?? 0) + 1;
    }

    return resumen;
  }

  // Calcular porcentaje de asistencia de un usuario
  double calcularPorcentajeAsistencia(List<Asistencia> asistenciasUsuario) {
    if (asistenciasUsuario.isEmpty) return 0.0;

    final presentes = asistenciasUsuario
        .where((a) => a.estado == 'presente' || a.estado == 'tarde')
        .length;

    return (presentes / asistenciasUsuario.length) * 100;
  }
}
