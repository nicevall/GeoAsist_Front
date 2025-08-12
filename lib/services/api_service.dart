// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/api_response_model.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 🔍 DEBUG REQUEST
    debugPrint('🌐 API GET: $endpoint');
    debugPrint('📋 Headers: ${headers ?? 'Default headers'}');

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .get(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
          )
          .timeout(AppConstants.apiTimeout);

      stopwatch.stop();

      // 🔍 DEBUG RESPONSE
      debugPrint('⏱️ GET Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint(
          '✅ Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...[TRUNCATED]' : response.body}');

      return _handleResponse(response);
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ GET Error after ${stopwatch.elapsedMilliseconds}ms: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 🔍 DEBUG REQUEST
    debugPrint('🌐 API POST: $endpoint');
    debugPrint('📦 Body: ${body != null ? jsonEncode(body) : 'No body'}');
    debugPrint('📋 Headers: ${headers ?? 'Default headers'}');

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .post(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(AppConstants.apiTimeout);

      stopwatch.stop();

      // 🔍 DEBUG RESPONSE
      debugPrint('⏱️ POST Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint(
          '✅ Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...[TRUNCATED]' : response.body}');

      return _handleResponse(response);
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ POST Error after ${stopwatch.elapsedMilliseconds}ms: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 🔍 DEBUG REQUEST
    debugPrint('🌐 API PUT: $endpoint');
    debugPrint('📦 Body: ${body != null ? jsonEncode(body) : 'No body'}');
    debugPrint('📋 Headers: ${headers ?? 'Default headers'}');

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .put(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(AppConstants.apiTimeout);

      stopwatch.stop();

      // 🔍 DEBUG RESPONSE
      debugPrint('⏱️ PUT Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint(
          '✅ Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...[TRUNCATED]' : response.body}');

      return _handleResponse(response);
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ PUT Error after ${stopwatch.elapsedMilliseconds}ms: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 🔍 DEBUG REQUEST
    debugPrint('🌐 API DELETE: $endpoint');
    debugPrint('📋 Headers: ${headers ?? 'Default headers'}');

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .delete(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
          )
          .timeout(AppConstants.apiTimeout);

      stopwatch.stop();

      // 🔍 DEBUG RESPONSE
      debugPrint('⏱️ DELETE Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint(
          '✅ Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...[TRUNCATED]' : response.body}');

      return _handleResponse(response);
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ DELETE Error after ${stopwatch.elapsedMilliseconds}ms: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final dynamic rawData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Normalizar la respuesta para que siempre sea un Map
        Map<String, dynamic> data;

        if (rawData is List) {
          // Si el backend retorna un array directo, lo wrapeamos
          data = {'data': rawData};
        } else if (rawData is Map<String, dynamic>) {
          // Si ya es un Map, lo usamos directamente
          data = rawData;
        } else {
          // Caso inesperado, wrapeamos el valor
          data = {'data': rawData};
        }

        return ApiResponse.success(
          data,
          message: data['mensaje'] ?? data['message'] ?? 'Success',
        );
      } else {
        // Para errores, intentamos extraer el mensaje
        String errorMessage = 'Error desconocido';

        if (rawData is Map<String, dynamic>) {
          errorMessage = rawData['error'] ?? rawData['mensaje'] ?? errorMessage;
        }

        return ApiResponse.error(
          errorMessage,
          message: 'Error ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Error al procesar respuesta: ${response.body}',
        message: 'Parse Error',
      );
    }
  }

  String _handleError(dynamic error) {
    if (error is SocketException) {
      return AppConstants.networkErrorMessage;
    } else if (error is HttpException) {
      return 'Error HTTP: ${error.message}';
    } else {
      return 'Error: ${error.toString()}';
    }
  }

  void dispose() {
    _client.close();
  }
}
