// lib/services/dashboard_service.dart
import 'package:flutter/foundation.dart';
import '../core/app_constants.dart';
import '../models/dashboard_metric_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<List<DashboardMetric>?> getMetrics() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        AppConstants.dashboardEndpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        // El backend retorna un array de métricas
        final metricsData = response.data!['data'] ?? response.data;

        if (metricsData is List) {
          return metricsData
              .map((json) => DashboardMetric.fromJson(json))
              .toList();
        }
      }
      return null;
    } catch (e) {
      // ✅ CORREGIDO: Usar debugPrint en lugar de print
      debugPrint('Error al obtener métricas: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRawMetrics() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        AppConstants.dashboardEndpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      // ✅ CORREGIDO: Usar debugPrint en lugar de print
      debugPrint('Error al obtener métricas: $e');
      return null;
    }
  }

  Future<bool> updateMetric(String metric, num value) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      final response = await _apiService.post(
        AppConstants.dashboardEndpoint,
        body: {
          'metric': metric,
          'value': value,
        },
        headers: AppConstants.getAuthHeaders(token),
      );

      return response.success;
    } catch (e) {
      // ✅ CORREGIDO: Usar debugPrint en lugar de print
      debugPrint('Error al actualizar métrica: $e');
      return false;
    }
  }

  // 🎯 MÉTODO 1: Métricas específicas por evento
  Future<Map<String, dynamic>?> getEventMetrics(String eventId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        '/dashboard/metrics/event/$eventId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo métricas del evento: $e');
      return null;
    }
  }

  // 🎯 MÉTODO 2: Vista general del dashboard
  Future<Map<String, dynamic>?> getDashboardOverview() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        '/dashboard/overview',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo overview del dashboard: $e');
      return null;
    }
  }
}
