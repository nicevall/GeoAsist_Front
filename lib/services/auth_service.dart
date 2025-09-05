import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/auth_service.dart
import '../models/usuario_model.dart';
import '../models/auth_response_model.dart';
import '../core/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'firebase/firebase_messaging_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  Future<AuthResponse> login(String correo, String contrasena) async {
    try {
      logger.d('🔐 Login attempt for: $correo');
      logger.d('📍 Using endpoint: ${AppConstants.loginEndpoint}');

      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        body: {
          'correo': correo,
          'contrasena': contrasena,
        },
      );

      logger.d('📡 Login response success: ${response.success}');
      logger.d('📄 Login response data available: ${response.data != null}');

      if (response.success && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);

        logger.d('✅ Auth response parsed - OK: ${authResponse.ok}');
        logger.d('🎫 Token available: ${authResponse.token != null}');
        logger.d('👤 User data available: ${authResponse.usuario != null}');

        if (authResponse.ok && authResponse.token != null) {
          logger.d(
              '🎫 Token received: ${authResponse.token!.substring(0, 10)}...');

          // Guardar token y datos de usuario
          await _storageService.saveToken(authResponse.token!);
          logger.d('💾 Token saved to storage');

          if (authResponse.usuario != null) {
            await _storageService.saveUser(authResponse.usuario!);
            logger.d(
                '👤 User data saved: ${authResponse.usuario!.nombre} (${authResponse.usuario!.rol})');
            
            // ✅ PHASE 3: Initialize FCM with backend API registration
            await _initializeFirebaseMessaging(authResponse.usuario!.id);
          }

          logger.d('✅ Login completed successfully');
        }

        return authResponse;
      } else {
        logger.d('❌ Login failed - Response error: ${response.error}');
        return AuthResponse(
          ok: false,
          mensaje: response.error ?? AppConstants.invalidCredentialsMessage,
        );
      }
    } catch (e) {
      logger.d('❌ Login exception: $e');
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
      logger.d('📝 Registration attempt for: $correo');
      logger.d('👤 User role: $rol');

      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        body: {
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
          'rol': rol,
        },
      );

      logger.d('📡 Registration response success: ${response.success}');

      if (response.success) {
        logger.d('✅ Registration completed successfully');
        return AuthResponse(
          ok: true,
          mensaje: response.message,
        );
      } else {
        logger.d('❌ Registration failed: ${response.error}');
        return AuthResponse(
          ok: false,
          mensaje: response.error ?? 'Error al registrar usuario',
        );
      }
    } catch (e) {
      logger.d('❌ Registration exception: $e');
      return AuthResponse(
        ok: false,
        mensaje: AppConstants.genericErrorMessage,
      );
    }
  }

  Future<Usuario?> getProfile(String userId) async {
    try {
      logger.d('👤 Getting profile for user: $userId');
      logger.d('🔍 Using endpoint: ${AppConstants.profileEndpoint}/$userId');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No token available for profile request');
        return null;
      }

      logger.d('🎫 Token found, proceeding with profile request');

      final response = await _apiService.get(
        '${AppConstants.profileEndpoint}/$userId',
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Profile response success: ${response.success}');
      logger.d(
          '📄 Profile response data available: ${response.data != null}');

      if (response.success && response.data != null) {
        final userData = response.data!['usuario'];
        if (userData != null) {
          final user = Usuario.fromJson(userData);
          logger.d('✅ Profile loaded successfully: ${user.nombre}');
          return user;
        } else {
          logger.d('❌ No user data in profile response');
        }
      } else {
        logger.d('❌ Profile request failed: ${response.error}');
      }
      return null;
    } catch (e) {
      logger.d('❌ Profile request exception: $e');
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      logger.d('🔄 Updating user: $userId');
      logger.d('📝 Update data: $userData');

      final token = await _storageService.getToken();
      if (token == null) {
        logger.d('❌ No token available for user update');
        return false;
      }

      logger.d('🎫 Token found, proceeding with user update');

      final response = await _apiService.put(
        '/usuarios/$userId',
        body: userData,
        headers: AppConstants.getAuthHeaders(token),
      );

      logger.d('📡 Update user response success: ${response.success}');

      if (response.success) {
        logger.d('✅ User updated successfully');
        return true;
      } else {
        logger.d('❌ User update failed: ${response.error}');
        return false;
      }
    } catch (e) {
      logger.d('❌ User update exception: $e');
      return false;
    }
  }

  Future<void> logout() async {
    logger.d('🚪 Logging out user');
    await _storageService.clearAll();
    logger.d('🧹 Storage cleared successfully');
  }

  Future<bool> isLoggedIn() async {
    logger.d('🔍 Checking if user is logged in');
    final token = await _storageService.getToken();
    final isLoggedIn = token != null;
    logger.d('🔐 User logged in status: $isLoggedIn');
    return isLoggedIn;
  }

  Future<Usuario?> getCurrentUser() async {
    logger.d('👤 Getting current user from storage');
    final user = await _storageService.getUser();
    logger.d('👤 Current user: ${user?.nombre ?? 'No user found'}');
    return user;
  }

  Future<String?> getToken() async {
    logger.d('🎫 Getting token from storage');
    final token = await _storageService.getToken();
    logger.d('🎫 Token available: ${token != null}');
    return token;
  }

  // ✅ PHASE 3: Initialize FCM with backend registration after login
  Future<void> _initializeFirebaseMessaging(String userId) async {
    try {
      logger.d('🔔 Initializing Firebase Messaging for user: $userId');
      
      // Initialize FCM service with user ID
      // This will register the token with both Firestore and Backend API
      await _messagingService.initialize(userId);
      
      logger.d('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      logger.d('⚠️ Firebase Messaging initialization failed: $e');
      // Don't throw - FCM failure shouldn't prevent login
    }
  }
}
