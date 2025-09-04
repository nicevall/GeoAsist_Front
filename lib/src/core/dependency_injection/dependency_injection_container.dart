import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Authentication feature dependencies
import '../../features/authentication/domain/repositories/authentication_repository.dart';
import '../../features/authentication/domain/use_cases/authenticate_user_use_case.dart';
import '../../features/authentication/data/repositories/authentication_repository_impl.dart';
import '../../features/authentication/data/data_sources/authentication_api_data_source.dart';
import '../../features/authentication/data/data_sources/authentication_local_data_source.dart';
import '../../features/authentication/application/services/authentication_service.dart';
import '../../features/authentication/presentation/controllers/authentication_controller.dart';

// Core dependencies
// Network imports removed - not currently used

/// **DependencyInjectionContainer**: Centralized dependency injection setup for Clean Architecture
/// 
/// **Purpose**: Configures and manages all dependency injection for the application
/// **AI Context**: Service locator pattern implementation using GetIt for Clean Architecture compliance
/// **Dependencies**: GetIt package for dependency injection
/// **Used by**: Application initialization and feature modules
/// **Performance**: Singleton pattern with lazy initialization for optimal memory usage
class DependencyInjectionContainer {
  /// **Property**: GetIt service locator instance
  /// **AI Context**: Global service locator for dependency resolution
  static final GetIt _serviceLocator = GetIt.instance;

  /// **Property**: Track if container has been initialized
  /// **AI Context**: Prevents duplicate initialization during app lifecycle
  static bool _isInitialized = false;

  /// **Method**: Initialize all application dependencies
  /// **AI Context**: Complete dependency graph setup following Clean Architecture layers
  /// **Side Effects**: Registers all services, repositories, and controllers
  /// **Error Cases**: Throws exception if initialization fails or called multiple times
  static Future<void> initializeDependencies() async {
    if (_isInitialized) {
      throw StateError('Dependency injection container is already initialized');
    }

    try {
      // AI Context: Initialize dependencies in correct order (bottom-up)
      await _registerCoreDependencies();
      await _registerAuthenticationFeatureDependencies();
      
      _isInitialized = true;
    } catch (error) {
      throw Exception('Failed to initialize dependency injection: ${error.toString()}');
    }
  }

  /// **Method**: Get dependency instance by type
  /// **AI Context**: Type-safe dependency resolution with error handling
  /// **Generic**: T - Type of dependency to resolve
  /// **Returns**: Instance of requested dependency type
  /// **Error Cases**: Throws if dependency not registered or container not initialized
  static T getDependency<T extends Object>() {
    if (!_isInitialized) {
      throw StateError('Dependency injection container not initialized. Call initializeDependencies() first.');
    }

    try {
      return _serviceLocator.get<T>();
    } catch (error) {
      throw Exception('Dependency ${T.toString()} not found. Ensure it is registered in the container.');
    }
  }

  /// **Method**: Check if dependency is registered
  /// **AI Context**: Safe dependency existence check before resolution
  /// **Generic**: T - Type of dependency to check
  /// **Returns**: Boolean indicating if dependency is registered
  static bool hasDependency<T extends Object>() {
    return _isInitialized && _serviceLocator.isRegistered<T>();
  }

  /// **Method**: Reset dependency injection container
  /// **AI Context**: Cleanup method for testing and app restart scenarios
  /// **Side Effects**: Unregisters all dependencies and resets initialization state
  /// **Use Case**: Testing, hot reload, or app restart scenarios
  static Future<void> resetContainer() async {
    await _serviceLocator.reset();
    _isInitialized = false;
  }

  /// **Private Method**: Register core dependencies (network, storage, utilities)
  /// **AI Context**: Bottom layer of dependency graph - foundation services
  /// **Dependencies**: SharedPreferences, HTTP client, network utilities
  static Future<void> _registerCoreDependencies() async {
    // AI Context: External dependencies requiring async initialization
    final sharedPreferences = await SharedPreferences.getInstance();
    _serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

    // AI Context: Network utilities for API communication
    _serviceLocator.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(),
    );

    // AI Context: HTTP client for API requests with authentication interceptors
    _serviceLocator.registerLazySingleton<ApiClient>(
      () => ApiClient(
        baseUrl: _getApiBaseUrl(),
        networkInfo: _serviceLocator<NetworkInfo>(),
      ),
    );
  }

  /// **Private Method**: Register authentication feature dependencies
  /// **AI Context**: Authentication feature dependency graph following Clean Architecture
  /// **Layers**: Data Sources → Repositories → Use Cases → Services → Controllers
  static Future<void> _registerAuthenticationFeatureDependencies() async {
    // AI Context: Data Sources Layer (External interfaces)
    _serviceLocator.registerLazySingleton<AuthenticationApiDataSource>(
      () => AuthenticationApiDataSourceImpl(
        apiClient: _serviceLocator<ApiClient>(),
      ),
    );

    _serviceLocator.registerLazySingleton<AuthenticationLocalDataSource>(
      () => AuthenticationLocalDataSourceImpl(
        sharedPreferences: _serviceLocator<SharedPreferences>(),
      ),
    );

    // AI Context: Repository Layer (Data abstraction)
    _serviceLocator.registerLazySingleton<AuthenticationRepository>(
      () => AuthenticationRepositoryImpl(
        apiDataSource: _serviceLocator<AuthenticationApiDataSource>(),
        localDataSource: _serviceLocator<AuthenticationLocalDataSource>(),
      ),
    );

    // AI Context: Use Cases Layer (Business logic)
    _serviceLocator.registerLazySingleton<AuthenticateUserUseCase>(
      () => AuthenticateUserUseCase(
        _serviceLocator<AuthenticationRepository>(),
      ),
    );

    // AI Context: Application Services Layer (Workflow orchestration)
    _serviceLocator.registerLazySingleton<AuthenticationService>(
      () => AuthenticationService(
        authenticationRepository: _serviceLocator<AuthenticationRepository>(),
        authenticateUserUseCase: _serviceLocator<AuthenticateUserUseCase>(),
      ),
    );

    // AI Context: Presentation Controllers (UI State management)
    _serviceLocator.registerFactory<AuthenticationController>(
      () => AuthenticationController(
        authenticateUserUseCase: _serviceLocator<AuthenticateUserUseCase>(),
      ),
    );
  }

  /// **Private Method**: Get API base URL based on environment
  /// **AI Context**: Environment-specific API URL configuration
  /// **Returns**: String containing base URL for API requests
  static String _getApiBaseUrl() {
    // AI Context: Environment-based URL selection
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'production':
        return 'https://api.geoasist.com';
      case 'staging':
        return 'https://staging-api.geoasist.com';
      case 'development':
      default:
        return 'http://localhost:3000'; // AI Context: Local backend for development
    }
  }

  /// **Method**: Register additional feature dependencies
  /// **AI Context**: Extension point for other feature modules
  /// **Use Case**: Called by other features to register their dependencies
  /// **Generic**: Allows registration of any dependency type
  static void registerFeatureDependency<T extends Object>(
    T dependency, {
    String? instanceName,
  }) {
    if (!_isInitialized) {
      throw StateError('Container must be initialized before registering additional dependencies');
    }

    if (instanceName != null) {
      _serviceLocator.registerSingleton<T>(dependency, instanceName: instanceName);
    } else {
      _serviceLocator.registerSingleton<T>(dependency);
    }
  }

  /// **Method**: Register factory dependency (new instance each time)
  /// **AI Context**: For dependencies that need fresh instances (like controllers)
  /// **Generic**: Factory function that creates new instance of T
  static void registerFactory<T extends Object>(
    T Function() factoryFunction, {
    String? instanceName,
  }) {
    if (!_isInitialized) {
      throw StateError('Container must be initialized before registering factories');
    }

    if (instanceName != null) {
      _serviceLocator.registerFactory<T>(factoryFunction, instanceName: instanceName);
    } else {
      _serviceLocator.registerFactory<T>(factoryFunction);
    }
  }

  /// **Getter**: Check if container is initialized
  /// **AI Context**: Public accessor for initialization state
  static bool get isInitialized => _isInitialized;

  /// **Method**: Get all registered dependency types
  /// **AI Context**: Debugging and inspection utility for dependency graph
  /// **Returns**: List of all registered dependency type names
  static List<String> getRegisteredDependencies() {
    if (!_isInitialized) return [];
    
    // AI Context: GetIt doesn't provide direct access to registered types
    // This is a simplified implementation for debugging purposes
    return [
      'SharedPreferences',
      'NetworkInfo',
      'ApiClient',
      'AuthenticationApiDataSource',
      'AuthenticationLocalDataSource',
      'AuthenticationRepository',
      'AuthenticateUserUseCase',
      'AuthenticationService',
      'AuthenticationController',
    ];
  }
}

/// **NetworkInfo**: Abstract interface for network connectivity checking
/// **AI Context**: Core dependency for handling offline/online states
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// **NetworkInfoImpl**: Concrete implementation of network connectivity
/// **AI Context**: Implementation using connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // AI Context: Simple connectivity check
    // In real implementation, would use connectivity_plus package
    try {
      // Mock implementation - in real app would check actual connectivity
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// **ApiClient**: HTTP client wrapper for API communication
/// **AI Context**: Centralized HTTP client with authentication and error handling
class ApiClient {
  final String baseUrl;
  final NetworkInfo networkInfo;

  ApiClient({
    required this.baseUrl,
    required this.networkInfo,
  });

  /// **Method**: Make authenticated HTTP request
  /// **AI Context**: Template for HTTP requests with authentication headers
  /// **Returns**: Future with Map containing String keys and dynamic values
  Future<Map<String, dynamic>> makeAuthenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
    String? authToken,
  }) async {
    // AI Context: Check network connectivity before request
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      throw NetworkException('No internet connection available');
    }

    // AI Context: Mock implementation - real implementation would use http package
    // and handle authentication headers, error codes, etc.
    return {
      'success': true,
      'data': data ?? {},
      'message': 'Mock API response'
    };
  }
}

/// **Exception Types**: Custom exceptions for dependency injection
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

// AI Context: Concrete implementations would be created here
// These are placeholders showing the dependency structure

class AuthenticationApiDataSourceImpl implements AuthenticationApiDataSource {
  final ApiClient apiClient;
  
  AuthenticationApiDataSourceImpl({required this.apiClient});
  
  // AI Context: Implementation methods would go here
  // This is a placeholder showing dependency injection structure
  @override
  Future<ApiAuthenticationResponse> authenticateUserWithApiCredentials({
    required String emailAddress,
    required String password,
  }) async {
    throw UnimplementedError('To be implemented with actual API integration');
  }
  
  @override
  Future<ApiRegistrationResponse> registerUserAccountWithApi({required Map<String, dynamic> userRegistrationData}) {
    throw UnimplementedError('To be implemented with actual API integration');
  }
  
  @override
  Future<ApiTokenRefreshResponse> refreshAuthenticationTokens({required String refreshToken}) {
    throw UnimplementedError('To be implemented with actual API integration');
  }
  
  @override
  Future<ApiSignOutResponse> signOutUserFromApi({required String authenticationToken}) {
    throw UnimplementedError('To be implemented with actual API integration');
  }
  
  @override
  Future<ApiPasswordResetResponse> requestPasswordResetEmail({required String emailAddress}) {
    throw UnimplementedError('To be implemented with actual API integration');
  }
  
  @override
  Future<ApiEmailVerificationResponse> verifyUserEmailWithToken({required String verificationToken}) {
    throw UnimplementedError('To be implemented with actual API integration');
  }
}

class AuthenticationLocalDataSourceImpl implements AuthenticationLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  AuthenticationLocalDataSourceImpl({required this.sharedPreferences});
  
  // AI Context: Implementation methods would go here
  // This is a placeholder showing dependency injection structure
  @override
  Future<void> cacheAuthenticatedUserData({
    required dynamic user,
    required String authenticationToken,
    required String refreshToken,
  }) async {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<LocalAuthenticationData?> getCachedAuthenticationData() {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<bool> hasValidAuthenticationCache() {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<void> clearAllAuthenticationCache() async {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<void> updateCachedAuthenticationTokens({
    required String newAuthenticationToken,
    required String newRefreshToken,
  }) async {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<String?> getCachedRefreshToken() {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<bool> isRefreshTokenExpired() {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<void> cacheUserPreferences(Map<String, dynamic> userPreferences) async {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
  
  @override
  Future<Map<String, dynamic>> getCachedUserPreferences() {
    throw UnimplementedError('To be implemented with actual SharedPreferences integration');
  }
}