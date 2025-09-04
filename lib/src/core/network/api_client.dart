// lib/src/core/network/api_client.dart
// HTTP client wrapper for API communication

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/api_response_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _baseUrl;
  Map<String, String> _defaultHeaders = {};

  void initialize({
    required String baseUrl,
    Map<String, String>? defaultHeaders,
  }) {
    _baseUrl = baseUrl;
    _defaultHeaders = defaultHeaders ?? {};
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await _client.get(
        uri,
        headers: {..._defaultHeaders, ...?headers},
      );
      return _parseResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ..._defaultHeaders,
          ...?headers
        },
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final baseUri = Uri.parse(_baseUrl ?? 'http://localhost:8080');
    final uri = baseUri.resolve(endpoint);
    
    if (queryParameters != null) {
      return uri.replace(queryParameters: queryParameters);
    }
    return uri;
  }

  ApiResponse<T> _parseResponse<T>(http.Response response) {
    return ApiResponse.fromHttpResponse(
      response.body,
      response.statusCode,
      headers: response.headers,
    );
  }

  void dispose() {
    _client.close();
  }
}