import '../entities/user_entity.dart';
import '../repositories/authentication_repository.dart';

/// **AuthenticateUserUseCase**: Business logic for user authentication flow
/// 
/// **Purpose**: Orchestrates user login process with validation and error handling
/// **AI Context**: Single responsibility use case following Clean Architecture principles
/// **Dependencies**: AuthenticationRepository interface only
/// **Used by**: AuthenticationController, LoginBloc
/// **Performance**: Lightweight use case optimized for frequent login attempts
class AuthenticateUserUseCase {
  /// **Property**: Repository dependency for data operations
  /// **AI Context**: Injected dependency following Dependency Inversion Principle
  final AuthenticationRepository _authenticationRepository;

  const AuthenticateUserUseCase(this._authenticationRepository);

  /// **Method**: Execute user authentication with email and password
  /// **AI Context**: Main use case execution method with comprehensive validation
  /// **Inputs**: emailAddress (String), password (String)
  /// **Outputs**: Future AuthenticationUseCaseResult with user or error details
  /// **Side Effects**: May cache authentication tokens and user session
  /// **Error Cases**: InvalidCredentials, NetworkError, ValidationError
  Future<AuthenticationUseCaseResult> executeUserAuthentication({
    required String emailAddress,
    required String password,
  }) async {
    // AI Context: Pre-validation of input parameters before repository call
    final validationResult = _validateAuthenticationInputs(
      emailAddress: emailAddress,
      password: password,
    );

    if (!validationResult.isValid) {
      return AuthenticationUseCaseResult.validationFailure(
        validationErrors: validationResult.errorMessages,
      );
    }

    try {
      // AI Context: Delegate to repository for actual authentication
      final authenticationResult = await _authenticationRepository
          .authenticateUserWithCredentials(
        emailAddress: emailAddress.trim().toLowerCase(),
        password: password,
      );

      if (authenticationResult.isSuccessful) {
        return AuthenticationUseCaseResult.success(
          authenticatedUser: authenticationResult.authenticatedUser!,
          authenticationToken: authenticationResult.authenticationToken!,
        );
      } else {
        return AuthenticationUseCaseResult.authenticationFailure(
          error: authenticationResult.error!,
        );
      }
    } catch (exception) {
      // AI Context: Handle unexpected exceptions with user-friendly messages
      return AuthenticationUseCaseResult.unexpectedError(
        errorMessage: 'Error inesperado durante la autenticación: ${exception.toString()}',
      );
    }
  }

  /// **Method**: Validate authentication input parameters
  /// **AI Context**: Internal validation logic for email and password format
  /// **Inputs**: emailAddress (String), password (String)
  /// **Returns**: ValidationResult indicating if inputs are valid
  /// **Side Effects**: None - pure validation function
  AuthenticationInputValidationResult _validateAuthenticationInputs({
    required String emailAddress,
    required String password,
  }) {
    final List<String> validationErrors = [];

    // AI Context: Email format validation with comprehensive regex
    if (emailAddress.trim().isEmpty) {
      validationErrors.add('La dirección de correo electrónico es obligatoria');
    } else if (!_isValidEmailFormat(emailAddress.trim())) {
      validationErrors.add('El formato de correo electrónico no es válido');
    }

    // AI Context: Password validation with security requirements
    if (password.isEmpty) {
      validationErrors.add('La contraseña es obligatoria');
    } else if (password.length < 6) {
      validationErrors.add('La contraseña debe tener al menos 6 caracteres');
    }

    return AuthenticationInputValidationResult(
      isValid: validationErrors.isEmpty,
      errorMessages: validationErrors,
    );
  }

  /// **Method**: Validate email format using comprehensive regex pattern
  /// **AI Context**: Email validation that handles most common email formats
  /// **Input**: email (String) to validate
  /// **Returns**: boolean indicating if email format is valid
  bool _isValidEmailFormat(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// **AuthenticationUseCaseResult**: Result object for authentication use case operations
/// **AI Context**: Encapsulates all possible outcomes of authentication process
class AuthenticationUseCaseResult {
  final bool isSuccessful;
  final UserEntity? authenticatedUser;
  final String? authenticationToken;
  final AuthenticationError? authenticationError;
  final List<String>? validationErrors;
  final String? unexpectedErrorMessage;

  const AuthenticationUseCaseResult._({
    required this.isSuccessful,
    this.authenticatedUser,
    this.authenticationToken,
    this.authenticationError,
    this.validationErrors,
    this.unexpectedErrorMessage,
  });

  /// **Factory**: Create successful authentication result
  factory AuthenticationUseCaseResult.success({
    required UserEntity authenticatedUser,
    required String authenticationToken,
  }) {
    return AuthenticationUseCaseResult._(
      isSuccessful: true,
      authenticatedUser: authenticatedUser,
      authenticationToken: authenticationToken,
    );
  }

  /// **Factory**: Create validation failure result
  factory AuthenticationUseCaseResult.validationFailure({
    required List<String> validationErrors,
  }) {
    return AuthenticationUseCaseResult._(
      isSuccessful: false,
      validationErrors: validationErrors,
    );
  }

  /// **Factory**: Create authentication failure result
  factory AuthenticationUseCaseResult.authenticationFailure({
    required AuthenticationError error,
  }) {
    return AuthenticationUseCaseResult._(
      isSuccessful: false,
      authenticationError: error,
    );
  }

  /// **Factory**: Create unexpected error result
  factory AuthenticationUseCaseResult.unexpectedError({
    required String errorMessage,
  }) {
    return AuthenticationUseCaseResult._(
      isSuccessful: false,
      unexpectedErrorMessage: errorMessage,
    );
  }

  /// **Method**: Get user-friendly error message for display
  /// **AI Context**: Converts technical errors into user-friendly Spanish messages
  String get userFriendlyErrorMessage {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return validationErrors!.join('\n');
    }

    if (authenticationError != null) {
      switch (authenticationError!) {
        case AuthenticationError.invalidCredentials:
          return 'Credenciales incorrectas. Verifica tu correo y contraseña.';
        case AuthenticationError.networkError:
          return 'Error de conexión. Verifica tu conexión a internet.';
        case AuthenticationError.serverError:
          return 'Error del servidor. Intenta nuevamente más tarde.';
        case AuthenticationError.sessionExpired:
          return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        case AuthenticationError.unknownError:
          return 'Error desconocido. Contacta al soporte técnico.';
      }
    }

    if (unexpectedErrorMessage != null) {
      return unexpectedErrorMessage!;
    }

    return 'Error desconocido durante la autenticación';
  }
}

/// **AuthenticationInputValidationResult**: Internal validation result
/// **AI Context**: Simple result object for input validation operations
class AuthenticationInputValidationResult {
  final bool isValid;
  final List<String> errorMessages;

  const AuthenticationInputValidationResult({
    required this.isValid,
    required this.errorMessages,
  });
}