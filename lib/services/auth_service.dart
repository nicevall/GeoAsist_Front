// lib/services/auth_service.dart
import '../models/usuario_model.dart';
import '../models/auth_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<AuthResponse> login(String correo, String contrasena) async {
    try {
      debugPrint('🔐 Login attempt for: $correo');
      debugPrint('📍 Using endpoint: ${AppConstants.loginEndpoint}');

      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        body: {
          'correo': correo,
          'contrasena': contrasena,
        },
      );

      debugPrint('📡 Login response success: ${response.success}');
      debugPrint('📄 Login response data available: ${response.data != null}');

      if (response.success && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);

        debugPrint('✅ Auth response parsed - OK: ${authResponse.ok}');
        debugPrint('🎫 Token available: ${authResponse.token != null}');
        debugPrint('👤 User data available: ${authResponse.usuario != null}');

        if (authResponse.ok && authResponse.token != null) {
          debugPrint(
              '🎫 Token received: ${authResponse.token!.substring(0, 10)}...');

          // Guardar token y datos de usuario
          await _storageService.saveToken(authResponse.token!);
          debugPrint('💾 Token saved to storage');

          if (authResponse.usuario != null) {
            await _storageService.saveUser(authResponse.usuario!);
            debugPrint(
                '👤 User data saved: ${authResponse.usuario!.nombre} (${authResponse.usuario!.rol})');
          }

          debugPrint('✅ Login completed successfully');
        }

        return authResponse;
      } else {
        debugPrint('❌ Login failed - Response error: ${response.error}');
        return AuthResponse(
          ok: false,
          mensaje: response.error ?? AppConstants.invalidCredentialsMessage,
        );
      }
    } catch (e) {
      debugPrint('❌ Login exception: $e');
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
      debugPrint('📝 Registration attempt for: $correo');
      debugPrint('👤 User role: $rol');

      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        body: {
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
          'rol': rol,
        },
      );

      debugPrint('📡 Registration response success: ${response.success}');

      if (response.success) {
        debugPrint('✅ Registration completed successfully');
        return AuthResponse(
          ok: true,
          mensaje: response.message,
        );
      } else {
        debugPrint('❌ Registration failed: ${response.error}');
        return AuthResponse(
          ok: false,
          mensaje: response.error ?? 'Error al registrar usuario',
        );
      }
    } catch (e) {
      debugPrint('❌ Registration exception: $e');
      return AuthResponse(
        ok: false,
        mensaje: AppConstants.genericErrorMessage,
      );
    }
  }

  Future<Usuario?> getProfile(String userId) async {
    try {
      debugPrint('👤 Getting profile for user: $userId');
      debugPrint('🔍 Using endpoint: ${AppConstants.profileEndpoint}/$userId');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No token available for profile request');
        return null;
      }

      debugPrint('🎫 Token found, proceeding with profile request');

      final response = await _apiService.get(
        '${AppConstants.profileEndpoint}/$userId',
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Profile response success: ${response.success}');
      debugPrint(
          '📄 Profile response data available: ${response.data != null}');

      if (response.success && response.data != null) {
        final userData = response.data!['usuario'];
        if (userData != null) {
          final user = Usuario.fromJson(userData);
          debugPrint('✅ Profile loaded successfully: ${user.nombre}');
          return user;
        } else {
          debugPrint('❌ No user data in profile response');
        }
      } else {
        debugPrint('❌ Profile request failed: ${response.error}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Profile request exception: $e');
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      debugPrint('🔄 Updating user: $userId');
      debugPrint('📝 Update data: $userData');

      final token = await _storageService.getToken();
      if (token == null) {
        debugPrint('❌ No token available for user update');
        return false;
      }

      debugPrint('🎫 Token found, proceeding with user update');

      final response = await _apiService.put(
        '/usuarios/$userId',
        body: userData,
        headers: AppConstants.getAuthHeaders(token),
      );

      debugPrint('📡 Update user response success: ${response.success}');

      if (response.success) {
        debugPrint('✅ User updated successfully');
        return true;
      } else {
        debugPrint('❌ User update failed: ${response.error}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ User update exception: $e');
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('🚪 Logging out user');
    await _storageService.clearAll();
    debugPrint('🧹 Storage cleared successfully');
  }

  Future<bool> isLoggedIn() async {
    debugPrint('🔍 Checking if user is logged in');
    final token = await _storageService.getToken();
    final isLoggedIn = token != null;
    debugPrint('🔐 User logged in status: $isLoggedIn');
    return isLoggedIn;
  }

  Future<Usuario?> getCurrentUser() async {
    debugPrint('👤 Getting current user from storage');
    final user = await _storageService.getUser();
    debugPrint('👤 Current user: ${user?.nombre ?? 'No user found'}');
    return user;
  }
}
