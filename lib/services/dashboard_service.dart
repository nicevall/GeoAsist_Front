// lib/services/dashboard_service.dart - ARCHIVO CORREGIDO
import 'package:flutter/foundation.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>?> getMetrics() async {
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
}
