import '../entities/user_entity.dart';

/// **AuthenticationRepository**: Domain interface for user authentication operations
/// 
/// **Purpose**: Defines contract for authentication data operations without implementation details
/// **AI Context**: Clean Architecture boundary between domain and data layers
/// **Dependencies**: UserEntity only
/// **Implementation**: Concrete implementation in data layer
/// **Performance**: Interface only - implementation handles optimization
abstract class AuthenticationRepository {
  /// **Method**: Authenticate user with email and password credentials
  /// **AI Context**: Primary login flow with credential validation
  /// **Inputs**: emailAddress (String), password (String)
  /// **Outputs**: Future AuthenticationResult with user data or error
  /// **Side Effects**: May cache user session data locally
  /// **Error Cases**: InvalidCredentials, NetworkError, ServerError
  Future<AuthenticationResult> authenticateUserWithCredentials({
    required String emailAddress,
    required String password,
  });

  /// **Method**: Register new user account with validation
  /// **AI Context**: Account creation flow with email verification
  /// **Inputs**: userName (String), emailAddress (String), password (String), role (UserRoleType)
  /// **Outputs**: Future RegistrationResult with created user or validation errors
  /// **Side Effects**: Triggers email verification process
  /// **Error Cases**: EmailAlreadyExists, WeakPassword, InvalidEmail
  Future<RegistrationResult> registerUserAccount({
    required String userName,
    required String emailAddress, 
    required String password,
    required UserRoleType roleType,
  });

  /// **Method**: Sign out current authenticated user
  /// **AI Context**: Clears user session and authentication tokens
  /// **Outputs**: Future SignOutResult indicating success or failure
  /// **Side Effects**: Clears local storage, revokes tokens
  /// **Error Cases**: TokenRevocationError, NetworkError
  Future<SignOutResult> signOutCurrentUser();

  /// **Method**: Get currently authenticated user if session is valid
  /// **AI Context**: Retrieves cached user data without network call
  /// **Outputs**: Future UserEntity or null if not authenticated
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: ExpiredSession, CorruptedCache
  Future<UserEntity?> getCurrentAuthenticatedUser();

  /// **Method**: Refresh authentication session with stored refresh token
  /// **AI Context**: Extends user session without requiring re-login
  /// **Outputs**: Future AuthenticationResult with refreshed tokens
  /// **Side Effects**: Updates stored authentication tokens
  /// **Error Cases**: InvalidRefreshToken, SessionExpired
  Future<AuthenticationResult> refreshUserSession();

  /// **Method**: Request password reset for user email
  /// **AI Context**: Initiates password recovery flow via email
  /// **Inputs**: emailAddress (String)
  /// **Outputs**: Future PasswordResetResult indicating email sent status
  /// **Side Effects**: Sends password reset email
  /// **Error Cases**: UserNotFound, EmailServiceError
  Future<PasswordResetResult> requestPasswordResetForEmail(String emailAddress);

  /// **Method**: Verify email address with verification token
  /// **AI Context**: Completes email verification during registration
  /// **Inputs**: verificationToken (String)
  /// **Outputs**: Future EmailVerificationResult indicating verification status
  /// **Side Effects**: Activates user account if successful
  /// **Error Cases**: InvalidToken, ExpiredToken, AlreadyVerified
  Future<EmailVerificationResult> verifyEmailWithToken(String verificationToken);

  /// **Method**: Check if user authentication session is still valid
  /// **AI Context**: Validates current session without refreshing
  /// **Outputs**: Future bool indicating if session is active
  /// **Side Effects**: None - validation only
  /// **Error Cases**: NetworkTimeout (returns false)
  Future<bool> isUserSessionValid();
}

/// **AuthenticationResult**: Result object for authentication operations
/// **AI Context**: Encapsulates success/failure state with user data or errors
class AuthenticationResult {
  final bool isSuccessful;
  final UserEntity? authenticatedUser;
  final String? authenticationToken;
  final String? refreshToken;
  final AuthenticationError? error;

  const AuthenticationResult._({
    required this.isSuccessful,
    this.authenticatedUser,
    this.authenticationToken,
    this.refreshToken,
    this.error,
  });

  /// **Factory**: Create successful authentication result
  factory AuthenticationResult.success({
    required UserEntity user,
    required String authToken,
    required String refreshToken,
  }) {
    return AuthenticationResult._(
      isSuccessful: true,
      authenticatedUser: user,
      authenticationToken: authToken,
      refreshToken: refreshToken,
    );
  }

  /// **Factory**: Create failed authentication result with error
  factory AuthenticationResult.failure(AuthenticationError error) {
    return AuthenticationResult._(
      isSuccessful: false,
      error: error,
    );
  }
}

/// **RegistrationResult**: Result object for user registration operations
class RegistrationResult {
  final bool isSuccessful;
  final UserEntity? registeredUser;
  final RegistrationError? error;
  final bool requiresEmailVerification;

  const RegistrationResult._({
    required this.isSuccessful,
    this.registeredUser,
    this.error,
    this.requiresEmailVerification = false,
  });

  factory RegistrationResult.success({
    required UserEntity user,
    bool requiresEmailVerification = true,
  }) {
    return RegistrationResult._(
      isSuccessful: true,
      registeredUser: user,
      requiresEmailVerification: requiresEmailVerification,
    );
  }

  factory RegistrationResult.failure(RegistrationError error) {
    return RegistrationResult._(
      isSuccessful: false,
      error: error,
    );
  }
}

/// **Result Objects**: Additional result types for other operations
class SignOutResult {
  final bool isSuccessful;
  final String? errorMessage;
  
  const SignOutResult._(this.isSuccessful, [this.errorMessage]);
  
  factory SignOutResult.success() => const SignOutResult._(true);
  factory SignOutResult.failure(String error) => SignOutResult._(false, error);
}

class PasswordResetResult {
  final bool emailSent;
  final String? errorMessage;
  
  const PasswordResetResult._(this.emailSent, [this.errorMessage]);
  
  factory PasswordResetResult.success() => const PasswordResetResult._(true);
  factory PasswordResetResult.failure(String error) => PasswordResetResult._(false, error);
}

class EmailVerificationResult {
  final bool isVerified;
  final String? errorMessage;
  
  const EmailVerificationResult._(this.isVerified, [this.errorMessage]);
  
  factory EmailVerificationResult.success() => const EmailVerificationResult._(true);
  factory EmailVerificationResult.failure(String error) => EmailVerificationResult._(false, error);
}

/// **Error Types**: Specific error types for authentication operations
enum AuthenticationError {
  invalidCredentials,
  networkError,
  serverError,
  sessionExpired,
  unknownError,
}

enum RegistrationError {
  emailAlreadyExists,
  weakPassword,
  invalidEmail,
  networkError,
  serverError,
  unknownError,
}