// lib/services/auth_service.dart
import '../models/usuario_model.dart';
import '../models/auth_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<AuthResponse> login(String correo, String contrasena) async {
    try {
      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        body: {
          'correo': correo,
          'contrasena': contrasena,
        },
      );

      if (response.success && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);

        if (authResponse.ok && authResponse.token != null) {
          // Guardar token y datos de usuario
          await _storageService.saveToken(authResponse.token!);
          if (authResponse.usuario != null) {
            await _storageService.saveUser(authResponse.usuario!);
          }
        }

        return authResponse;
      } else {
        return AuthResponse(
          ok: false,
          mensaje: response.error ?? AppConstants.invalidCredentialsMessage,
        );
      }
    } catch (e) {
      return AuthResponse(
        ok: false,
        mensaje: AppConstants.genericErrorMessage,
      );
    }
  }

  Future<AuthResponse> register(
    String nombre,
    String correo,
    String contrasena,
    String rol,
  ) async {
    try {
      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        body: {
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
          'rol': rol,
        },
      );

      if (response.success) {
        return AuthResponse(
          ok: true,
          mensaje: response.message,
        );
      } else {
        return AuthResponse(
          ok: false,
          mensaje: response.error ?? 'Error al registrar usuario',
        );
      }
    } catch (e) {
      return AuthResponse(
        ok: false,
        mensaje: AppConstants.genericErrorMessage,
      );
    }
  }

  Future<Usuario?> getProfile(String userId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return null;

      final response = await _apiService.get(
        '${AppConstants.profileEndpoint}/$userId',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final userData = response.data!['usuario'];
        if (userData != null) {
          return Usuario.fromJson(userData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      final response = await _apiService.put(
        '/usuarios/$userId',
        body: userData,
        headers: AppConstants.getAuthHeaders(token),
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  Future<Usuario?> getCurrentUser() async {
    return await _storageService.getUser();
  }
}
