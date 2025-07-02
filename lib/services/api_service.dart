// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/api_response_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .get(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
          )
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .post(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .put(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .delete(
            uri,
            headers: headers ?? AppConstants.defaultHeaders,
          )
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          data,
          message: data['mensaje'] ?? data['message'] ?? 'Success',
        );
      } else {
        return ApiResponse.error(
          data['error'] ?? data['mensaje'] ?? 'Error desconocido',
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
