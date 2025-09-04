// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../core/api_endpoints.dart';
import '../core/error_handler.dart';
import '../models/api_response_model.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final ErrorHandler _errorHandler = ErrorHandler();

  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 🔍 DEBUG REQUEST
    debugPrint('🌐 API GET: $endpoint');
    debugPrint('📋 Headers: ${headers ?? 'Default headers'}');

    try {
      // Usar endpoints centralizados cuando sea posible
      final baseUrl = ApiEndpoints.baseUrl;
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await _client
          .get(
            uri,
            headers: headers ?? ApiEndpoints.defaultHeaders,
          )
          .timeout(ApiEndpoints.defaultTimeout);

      stopwatch.stop();

      // 🔍 DEBUG RESPONSE
      debugPrint('⏱️ GET Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint(
          '✅ Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...[TRUNCATED]' : response.body}');

      return _handleResponseEnhanced(response, stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      final appError = _errorHandler.handleError(e, context: 'GET $endpoint');
      debugPrint('❌ GET Error after ${stopwatch.elapsedMilliseconds}ms: ${appError.message}');
      return ApiResponse.error(appError.userFriendlyMessage);
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
      // Usar endpoints centralizados cuando sea posible
      final baseUrl = ApiEndpoints.baseUrl;
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await _client
          .post(
            uri,
            headers: headers ?? ApiEndpoints.defaultHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(ApiEndpoints.defaultTimeout);

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

  /// Método mejorado para manejar respuestas con ErrorHandler
  ApiResponse<Map<String, dynamic>> _handleResponseEnhanced(http.Response response, Duration responseTime) {
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
        // Usar ErrorHandler para clasificar errores HTTP
        final appError = _errorHandler.handleHttpError(response, context: 'api_response');
        
        return ApiResponse.error(
          appError.userFriendlyMessage,
          message: 'Error ${response.statusCode}',
        );
      }
    } catch (e) {
      final appError = _errorHandler.handleError(e, context: 'response_parsing');
      return ApiResponse.error(
        appError.userFriendlyMessage,
        message: 'Parse Error',
      );
    }
  }
  
  /// Método legacy para compatibilidad
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    return _handleResponseEnhanced(response, Duration.zero);
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
