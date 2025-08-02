import '../models/api_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';

class EmailVerificationService {
  static final EmailVerificationService _instance =
      EmailVerificationService._internal();
  factory EmailVerificationService() => _instance;
  EmailVerificationService._internal();

  final ApiService _apiService = ApiService();

  Future<ApiResponse<bool>> verifyEmailCode(String email, String code) async {
    try {
      final response = await _apiService.post(
        AppConstants.verifyEmailEndpoint,
        body: {
          'correo': email,
          'codigo': code,
        },
      );

      if (response.success) {
        return ApiResponse.success(true, message: response.message);
      } else {
        return ApiResponse.error(response.error ?? 'Error al verificar código');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  Future<ApiResponse<bool>> resendVerificationCode(String email) async {
    try {
      final response = await _apiService.post(
        AppConstants.resendCodeEndpoint,
        body: {
          'correo': email,
        },
      );

      if (response.success) {
        return ApiResponse.success(true, message: response.message);
      } else {
        return ApiResponse.error(response.error ?? 'Error al reenviar código');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }
}
