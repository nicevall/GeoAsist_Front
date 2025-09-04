import '../models/user_model.dart';

/// **AuthenticationApiDataSource**: External API interface for authentication operations
/// 
/// **Purpose**: Defines contract for authentication API calls without HTTP implementation details
/// **AI Context**: Data source abstraction for Clean Architecture boundary
/// **Dependencies**: UserModel only
/// **Implementation**: Concrete implementation handles HTTP client details
/// **Performance**: Interface only - implementation optimizes network calls
abstract class AuthenticationApiDataSource {
  /// **Method**: Login user with credentials via API endpoint
  /// **AI Context**: Primary authentication endpoint integration
  /// **Inputs**: emailAddress (String), password (String)
  /// **Outputs**: Future ApiAuthenticationResponse with user data and tokens
  /// **Side Effects**: None - pure API call
  /// **Error Cases**: NetworkException, ServerException, AuthenticationException
  Future<ApiAuthenticationResponse> authenticateUserWithApiCredentials({
    required String emailAddress,
    required String password,
  });

  /// **Method**: Register new user account via API endpoint
  /// **AI Context**: Account creation with backend validation
  /// **Inputs**: userData Map with String keys and dynamic values containing user information
  /// **Outputs**: Future ApiRegistrationResponse with created user data
  /// **Side Effects**: Triggers email verification process on backend
  /// **Error Cases**: ValidationException, DuplicateEmailException, ServerException
  Future<ApiRegistrationResponse> registerUserAccountWithApi({
    required Map<String, dynamic> userRegistrationData,
  });

  /// **Method**: Refresh authentication tokens via API
  /// **AI Context**: Token refresh without re-authentication
  /// **Inputs**: refreshToken (String)
  /// **Outputs**: Future ApiTokenRefreshResponse with new tokens
  /// **Side Effects**: Invalidates old refresh token
  /// **Error Cases**: InvalidTokenException, ExpiredTokenException
  Future<ApiTokenRefreshResponse> refreshAuthenticationTokens({
    required String refreshToken,
  });

  /// **Method**: Sign out user and revoke tokens via API
  /// **AI Context**: Clean logout with token revocation
  /// **Inputs**: authToken (String)
  /// **Outputs**: Future ApiSignOutResponse indicating success
  /// **Side Effects**: Revokes all user tokens on server
  /// **Error Cases**: NetworkException, TokenException
  Future<ApiSignOutResponse> signOutUserFromApi({
    required String authenticationToken,
  });

  /// **Method**: Request password reset email via API
  /// **AI Context**: Password recovery flow initiation
  /// **Inputs**: emailAddress (String)
  /// **Outputs**: Future ApiPasswordResetResponse indicating email sent
  /// **Side Effects**: Triggers password reset email on backend
  /// **Error Cases**: UserNotFoundException, EmailServiceException
  Future<ApiPasswordResetResponse> requestPasswordResetEmail({
    required String emailAddress,
  });

  /// **Method**: Verify user email with token via API
  /// **AI Context**: Email verification completion
  /// **Inputs**: verificationToken (String)
  /// **Outputs**: Future ApiEmailVerificationResponse with verification status
  /// **Side Effects**: Activates user account if successful
  /// **Error Cases**: InvalidTokenException, AlreadyVerifiedException
  Future<ApiEmailVerificationResponse> verifyUserEmailWithToken({
    required String verificationToken,
  });
}

/// **ApiAuthenticationResponse**: Response object for authentication API calls
/// **AI Context**: Encapsulates API response data with type safety
class ApiAuthenticationResponse {
  final bool isSuccessful;
  final UserModel? authenticatedUser;
  final String? authenticationToken;
  final String? refreshToken;
  final String? errorMessage;
  final int? statusCode;

  const ApiAuthenticationResponse({
    required this.isSuccessful,
    this.authenticatedUser,
    this.authenticationToken,
    this.refreshToken,
    this.errorMessage,
    this.statusCode,
  });

  /// **Factory**: Create successful authentication response
  factory ApiAuthenticationResponse.success({
    required UserModel user,
    required String authToken,
    required String refreshToken,
  }) {
    return ApiAuthenticationResponse(
      isSuccessful: true,
      authenticatedUser: user,
      authenticationToken: authToken,
      refreshToken: refreshToken,
      statusCode: 200,
    );
  }

  /// **Factory**: Create failed authentication response
  factory ApiAuthenticationResponse.failure({
    required String errorMessage,
    required int statusCode,
  }) {
    return ApiAuthenticationResponse(
      isSuccessful: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }
}

/// **ApiRegistrationResponse**: Response object for user registration API calls
class ApiRegistrationResponse {
  final bool isSuccessful;
  final UserModel? registeredUser;
  final String? errorMessage;
  final int? statusCode;
  final bool requiresEmailVerification;

  const ApiRegistrationResponse({
    required this.isSuccessful,
    this.registeredUser,
    this.errorMessage,
    this.statusCode,
    this.requiresEmailVerification = false,
  });

  factory ApiRegistrationResponse.success({
    required UserModel user,
    bool requiresEmailVerification = true,
  }) {
    return ApiRegistrationResponse(
      isSuccessful: true,
      registeredUser: user,
      statusCode: 201,
      requiresEmailVerification: requiresEmailVerification,
    );
  }

  factory ApiRegistrationResponse.failure({
    required String errorMessage,
    required int statusCode,
  }) {
    return ApiRegistrationResponse(
      isSuccessful: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }
}

/// **Additional Response Types**: For other API operations
class ApiTokenRefreshResponse {
  final bool isSuccessful;
  final String? newAuthenticationToken;
  final String? newRefreshToken;
  final String? errorMessage;

  const ApiTokenRefreshResponse({
    required this.isSuccessful,
    this.newAuthenticationToken,
    this.newRefreshToken,
    this.errorMessage,
  });
}

class ApiSignOutResponse {
  final bool isSuccessful;
  final String? errorMessage;

  const ApiSignOutResponse({
    required this.isSuccessful,
    this.errorMessage,
  });
}

class ApiPasswordResetResponse {
  final bool emailSent;
  final String? errorMessage;

  const ApiPasswordResetResponse({
    required this.emailSent,
    this.errorMessage,
  });
}

class ApiEmailVerificationResponse {
  final bool isVerified;
  final String? errorMessage;

  const ApiEmailVerificationResponse({
    required this.isVerified,
    this.errorMessage,
  });
}

/// **API Exception Types**: Specific exceptions for different API errors
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
}

class ValidationException implements Exception {
  final String message;
  final List<String>? validationErrors;
  const ValidationException(this.message, {this.validationErrors});
}

class DuplicateEmailException implements Exception {
  final String message;
  const DuplicateEmailException(this.message);
}

class InvalidTokenException implements Exception {
  final String message;
  const InvalidTokenException(this.message);
}

class ExpiredTokenException implements Exception {
  final String message;
  const ExpiredTokenException(this.message);
}

class UserNotFoundException implements Exception {
  final String message;
  const UserNotFoundException(this.message);
}

class EmailServiceException implements Exception {
  final String message;
  const EmailServiceException(this.message);
}

class AlreadyVerifiedException implements Exception {
  final String message;
  const AlreadyVerifiedException(this.message);
}