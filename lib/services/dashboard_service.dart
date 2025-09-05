import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/dashboard_service.dart
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

      // Obtener el rol del usuario para usar el endpoint correcto
      final userRole = await _storageService.getUserRole();
      
      String endpoint;
      if (userRole == AppConstants.estudianteRole) {
        endpoint = AppConstants.studentDashboardEndpoint;
      } else {
        endpoint = AppConstants.dashboardEndpoint; // Para admin y profesor
      }

      final response = await _apiService.get(
        endpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        // El backend retorna un array de métricas
        final metricsData = response.data!['metrics'] ?? response.data!['data'] ?? response.data;

        if (metricsData is List) {
          return metricsData
              .map((json) => DashboardMetric.fromJson(json))
              .toList();
        }
      }
      return null;
    } catch (e) {
      // ✅ CORREGIDO: Usar logger en lugar de debugPrint
      logger.d('Error al obtener métricas: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRawMetrics() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      // Obtener el rol del usuario para usar el endpoint correcto
      final userRole = await _storageService.getUserRole();
      
      String endpoint;
      if (userRole == AppConstants.estudianteRole) {
        endpoint = AppConstants.studentDashboardEndpoint;
      } else {
        endpoint = AppConstants.dashboardEndpoint; // Para admin y profesor
      }

      final response = await _apiService.get(
        endpoint,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      // ✅ CORREGIDO: Usar logger en lugar de debugPrint
      logger.d('Error al obtener métricas: $e');
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
      // ✅ CORREGIDO: Usar logger en lugar de debugPrint
      logger.d('Error al actualizar métrica: $e');
      return false;
    }
  }

  // 🎯 MÉTODO 1: Métricas específicas por evento
  Future<Map<String, dynamic>?> getEventMetrics(String eventId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        '${AppConstants.dashboardEventMetrics}/$eventId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      logger.d('Error obteniendo métricas del evento: $e');
      return null;
    }
  }

  // 🎯 MÉTODO 2: Vista general del dashboard
  Future<Map<String, dynamic>?> getDashboardOverview() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        AppConstants.dashboardOverview,
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      logger.d('Error obteniendo overview del dashboard: $e');
      return null;
    }
  }
}
