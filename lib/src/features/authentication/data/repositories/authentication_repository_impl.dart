import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../data_sources/authentication_api_data_source.dart';
import '../data_sources/authentication_local_data_source.dart';

/// **AuthenticationRepositoryImpl**: Concrete implementation of authentication repository
/// 
/// **Purpose**: Orchestrates data operations between API and local storage for authentication
/// **AI Context**: Implementation of Clean Architecture repository pattern with offline-first approach
/// **Dependencies**: AuthenticationApiDataSource, AuthenticationLocalDataSource
/// **Used by**: Authentication use cases via dependency injection
/// **Performance**: Optimized for offline-first with intelligent caching and network fallback
class AuthenticationRepositoryImpl implements AuthenticationRepository {
  /// **Property**: API data source for remote authentication operations
  /// **AI Context**: Handles all network-based authentication operations
  final AuthenticationApiDataSource _apiDataSource;
  
  /// **Property**: Local data source for offline authentication persistence
  /// **AI Context**: Manages cached user sessions and offline access
  final AuthenticationLocalDataSource _localDataSource;

  const AuthenticationRepositoryImpl({
    required AuthenticationApiDataSource apiDataSource,
    required AuthenticationLocalDataSource localDataSource,
  })  : _apiDataSource = apiDataSource,
        _localDataSource = localDataSource;

  /// **Method**: Authenticate user with credentials using API and cache result
  /// **AI Context**: Primary authentication flow with automatic caching
  /// **Implementation**: API call + local cache on success
  @override
  Future<AuthenticationResult> authenticateUserWithCredentials({
    required String emailAddress,
    required String password,
  }) async {
    try {
      // AI Context: Attempt authentication via API first
      final apiResponse = await _apiDataSource.authenticateUserWithApiCredentials(
        emailAddress: emailAddress,
        password: password,
      );

      if (apiResponse.isSuccessful && apiResponse.authenticatedUser != null) {
        // AI Context: Cache successful authentication for offline access
        await _localDataSource.cacheAuthenticatedUserData(
          user: apiResponse.authenticatedUser!,
          authenticationToken: apiResponse.authenticationToken!,
          refreshToken: apiResponse.refreshToken!,
        );

        return AuthenticationResult.success(
          user: apiResponse.authenticatedUser!,
          authToken: apiResponse.authenticationToken!,
          refreshToken: apiResponse.refreshToken!,
        );
      } else {
        // AI Context: Convert API error to domain error
        final domainError = _mapApiErrorToDomainError(apiResponse);
        return AuthenticationResult.failure(domainError);
      }
    } on NetworkException catch (_) {
      // AI Context: Network error - try cached authentication if available
      final cachedData = await _localDataSource.getCachedAuthenticationData();
      if (cachedData != null && cachedData.isCacheDataFresh) {
        return AuthenticationResult.success(
          user: cachedData.cachedUser,
          authToken: cachedData.authenticationToken,
          refreshToken: cachedData.refreshToken,
        );
      }
      return AuthenticationResult.failure(AuthenticationError.networkError);
    } on AuthenticationException catch (_) {
      return AuthenticationResult.failure(AuthenticationError.invalidCredentials);
    } on Exception catch (_) {
      return AuthenticationResult.failure(AuthenticationError.unknownError);
    }
  }

  /// **Method**: Register new user account with validation and verification
  /// **AI Context**: Account creation flow with email verification trigger
  @override
  Future<RegistrationResult> registerUserAccount({
    required String userName,
    required String emailAddress,
    required String password,
    required UserRoleType roleType,
  }) async {
    try {
      // AI Context: Prepare registration data with backend field names
      final registrationData = {
        'nombre': userName,
        'correo': emailAddress, // AI Context: Backend expects 'correo' not 'email'
        'password': password,
        'rol': roleType.backendRoleName, // AI Context: Convert enum to backend string
      };

      final apiResponse = await _apiDataSource.registerUserAccountWithApi(
        userRegistrationData: registrationData,
      );

      if (apiResponse.isSuccessful && apiResponse.registeredUser != null) {
        return RegistrationResult.success(
          user: apiResponse.registeredUser!,
          requiresEmailVerification: apiResponse.requiresEmailVerification,
        );
      } else {
        // AI Context: Convert API registration errors to domain errors
        final domainError = _mapRegistrationApiErrorToDomainError(apiResponse);
        return RegistrationResult.failure(domainError);
      }
    } on ValidationException {
      // AI Context: Handle validation errors from API
      return RegistrationResult.failure(RegistrationError.invalidEmail);
    } on DuplicateEmailException catch (_) {
      return RegistrationResult.failure(RegistrationError.emailAlreadyExists);
    } on NetworkException catch (_) {
      return RegistrationResult.failure(RegistrationError.networkError);
    } on Exception catch (_) {
      return RegistrationResult.failure(RegistrationError.unknownError);
    }
  }

  /// **Method**: Sign out current user and clear all cached data
  /// **AI Context**: Clean logout with token revocation and cache cleanup
  @override
  Future<SignOutResult> signOutCurrentUser() async {
    try {
      // AI Context: Get current token for API revocation
      final cachedData = await _localDataSource.getCachedAuthenticationData();
      
      if (cachedData != null) {
        // AI Context: Attempt to revoke token on server
        try {
          await _apiDataSource.signOutUserFromApi(
            authenticationToken: cachedData.authenticationToken,
          );
        } catch (_) {
          // AI Context: Continue with local cleanup even if API call fails
        }
      }

      // AI Context: Always clear local cache regardless of API result
      await _localDataSource.clearAllAuthenticationCache();
      
      return SignOutResult.success();
    } catch (e) {
      // AI Context: Even on error, try to clear local cache
      try {
        await _localDataSource.clearAllAuthenticationCache();
      } catch (_) {}
      
      return SignOutResult.failure('Error durante el cierre de sesión: ${e.toString()}');
    }
  }

  /// **Method**: Get currently authenticated user from cache or refresh if expired
  /// **AI Context**: Smart user retrieval with automatic token refresh
  @override
  Future<UserEntity?> getCurrentAuthenticatedUser() async {
    try {
      final cachedData = await _localDataSource.getCachedAuthenticationData();
      
      if (cachedData == null) {
        return null; // AI Context: No cached user found
      }

      // AI Context: Check if tokens need proactive refresh
      if (cachedData.shouldRefreshTokensProactively) {
        try {
          await _refreshTokensInBackground(cachedData);
        } catch (_) {
          // AI Context: Continue with current tokens if refresh fails
        }
      }

      return cachedData.cachedUser;
    } catch (_) {
      return null; // AI Context: Return null on any error to trigger re-authentication
    }
  }

  /// **Method**: Refresh authentication session using stored refresh token
  /// **AI Context**: Token refresh without user re-authentication
  @override
  Future<AuthenticationResult> refreshUserSession() async {
    try {
      final cachedData = await _localDataSource.getCachedAuthenticationData();
      
      if (cachedData == null || cachedData.refreshToken.isEmpty) {
        return AuthenticationResult.failure(AuthenticationError.sessionExpired);
      }

      final refreshResponse = await _apiDataSource.refreshAuthenticationTokens(
        refreshToken: cachedData.refreshToken,
      );

      if (refreshResponse.isSuccessful && 
          refreshResponse.newAuthenticationToken != null &&
          refreshResponse.newRefreshToken != null) {
        
        // AI Context: Update cached tokens without changing user data
        await _localDataSource.updateCachedAuthenticationTokens(
          newAuthenticationToken: refreshResponse.newAuthenticationToken!,
          newRefreshToken: refreshResponse.newRefreshToken!,
        );

        return AuthenticationResult.success(
          user: cachedData.cachedUser,
          authToken: refreshResponse.newAuthenticationToken!,
          refreshToken: refreshResponse.newRefreshToken!,
        );
      } else {
        // AI Context: Refresh failed - clear cache and require re-authentication
        await _localDataSource.clearAllAuthenticationCache();
        return AuthenticationResult.failure(AuthenticationError.sessionExpired);
      }
    } on InvalidTokenException catch (_) {
      await _localDataSource.clearAllAuthenticationCache();
      return AuthenticationResult.failure(AuthenticationError.sessionExpired);
    } on ExpiredTokenException catch (_) {
      await _localDataSource.clearAllAuthenticationCache();
      return AuthenticationResult.failure(AuthenticationError.sessionExpired);
    } catch (_) {
      return AuthenticationResult.failure(AuthenticationError.unknownError);
    }
  }

  /// **Method**: Request password reset email for user
  /// **AI Context**: Password recovery flow via email
  @override
  Future<PasswordResetResult> requestPasswordResetForEmail(String emailAddress) async {
    try {
      final response = await _apiDataSource.requestPasswordResetEmail(
        emailAddress: emailAddress,
      );

      if (response.emailSent) {
        return PasswordResetResult.success();
      } else {
        return PasswordResetResult.failure(
          response.errorMessage ?? 'Error al enviar correo de recuperación',
        );
      }
    } on UserNotFoundException catch (_) {
      return PasswordResetResult.failure(
        'No se encontró una cuenta con este correo electrónico',
      );
    } on EmailServiceException catch (_) {
      return PasswordResetResult.failure(
        'Error en el servicio de correo. Intenta más tarde',
      );
    } on NetworkException catch (_) {
      return PasswordResetResult.failure(
        'Error de conexión. Verifica tu conexión a internet',
      );
    } catch (_) {
      return PasswordResetResult.failure('Error inesperado');
    }
  }

  /// **Method**: Verify user email with verification token
  /// **AI Context**: Complete email verification process
  @override
  Future<EmailVerificationResult> verifyEmailWithToken(String verificationToken) async {
    try {
      final response = await _apiDataSource.verifyUserEmailWithToken(
        verificationToken: verificationToken,
      );

      if (response.isVerified) {
        return EmailVerificationResult.success();
      } else {
        return EmailVerificationResult.failure(
          response.errorMessage ?? 'Error al verificar el correo electrónico',
        );
      }
    } on InvalidTokenException catch (_) {
      return EmailVerificationResult.failure('Token de verificación inválido');
    } on AlreadyVerifiedException catch (_) {
      return EmailVerificationResult.failure('El correo ya está verificado');
    } on NetworkException catch (_) {
      return EmailVerificationResult.failure('Error de conexión');
    } catch (_) {
      return EmailVerificationResult.failure('Error inesperado');
    }
  }

  /// **Method**: Check if user session is valid without refresh
  /// **AI Context**: Quick session validation for app initialization
  @override
  Future<bool> isUserSessionValid() async {
    try {
      final cachedData = await _localDataSource.getCachedAuthenticationData();
      
      if (cachedData == null) return false;
      
      // AI Context: Consider session valid if cache is fresh and tokens not expired
      return cachedData.isCacheDataFresh && !cachedData.areTokensExpired;
    } catch (_) {
      return false; // AI Context: Return false on any error for security
    }
  }

  /// **Private Method**: Refresh tokens in background without blocking UI
  /// **AI Context**: Proactive token refresh to prevent auth failures
  Future<void> _refreshTokensInBackground(LocalAuthenticationData cachedData) async {
    try {
      final refreshResponse = await _apiDataSource.refreshAuthenticationTokens(
        refreshToken: cachedData.refreshToken,
      );

      if (refreshResponse.isSuccessful && 
          refreshResponse.newAuthenticationToken != null &&
          refreshResponse.newRefreshToken != null) {
        
        await _localDataSource.updateCachedAuthenticationTokens(
          newAuthenticationToken: refreshResponse.newAuthenticationToken!,
          newRefreshToken: refreshResponse.newRefreshToken!,
        );
      }
    } catch (_) {
      // AI Context: Silent failure - will retry on next operation
    }
  }

  /// **Private Method**: Map API authentication errors to domain errors
  /// **AI Context**: Convert data layer exceptions to domain layer errors
  AuthenticationError _mapApiErrorToDomainError(ApiAuthenticationResponse response) {
    switch (response.statusCode) {
      case 401:
        return AuthenticationError.invalidCredentials;
      case 500:
      case 502:
      case 503:
        return AuthenticationError.serverError;
      default:
        return AuthenticationError.unknownError;
    }
  }

  /// **Private Method**: Map API registration errors to domain errors
  /// **AI Context**: Convert registration-specific API errors to domain errors
  RegistrationError _mapRegistrationApiErrorToDomainError(ApiRegistrationResponse response) {
    switch (response.statusCode) {
      case 409:
        return RegistrationError.emailAlreadyExists;
      case 400:
        return RegistrationError.weakPassword;
      case 422:
        return RegistrationError.invalidEmail;
      case 500:
      case 502:
      case 503:
        return RegistrationError.serverError;
      default:
        return RegistrationError.unknownError;
    }
  }
}