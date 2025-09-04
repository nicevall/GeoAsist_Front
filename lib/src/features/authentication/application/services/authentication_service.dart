import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/use_cases/authenticate_user_use_case.dart';

/// **AuthenticationService**: Application service orchestrating authentication business logic
/// 
/// **Purpose**: Coordinates multiple use cases and provides high-level authentication operations
/// **AI Context**: Application layer service managing authentication workflows and session state
/// **Dependencies**: AuthenticationRepository, AuthenticateUserUseCase
/// **Used by**: AuthenticationController, app initialization logic
/// **Performance**: Optimized for session management with intelligent caching and state coordination
class AuthenticationService {
  /// **Property**: Repository for authentication data operations
  /// **AI Context**: Injected dependency for Clean Architecture compliance
  final AuthenticationRepository _authenticationRepository;
  
  /// **Property**: Use case for user authentication workflow
  /// **AI Context**: Encapsulated business logic for authentication process
  final AuthenticateUserUseCase _authenticateUserUseCase;
  
  /// **Property**: Currently cached authenticated user
  /// **AI Context**: In-memory user cache for performance and offline access
  UserEntity? _cachedAuthenticatedUser;
  
  /// **Property**: Current authentication token
  /// **AI Context**: Active token for API authorization
  String? _cachedAuthenticationToken;
  
  /// **Property**: Session initialization status
  /// **AI Context**: Tracks whether service has been initialized with cached data
  bool _isSessionInitialized = false;

  AuthenticationService({
    required AuthenticationRepository authenticationRepository,
    required AuthenticateUserUseCase authenticateUserUseCase,
  })  : _authenticationRepository = authenticationRepository,
        _authenticateUserUseCase = authenticateUserUseCase;

  // **Getters**: Public interface for authentication state
  /// **Getter**: Currently authenticated user or null
  /// **AI Context**: Provides cached user data without repository calls
  UserEntity? get currentAuthenticatedUser => _cachedAuthenticatedUser;

  /// **Getter**: Current authentication token or null
  /// **AI Context**: Provides active token for API requests
  String? get currentAuthenticationToken => _cachedAuthenticationToken;

  /// **Getter**: Check if user is currently authenticated
  /// **AI Context**: Quick authentication status check for UI logic
  bool get isUserCurrentlyAuthenticated => 
      _cachedAuthenticatedUser != null && _cachedAuthenticationToken != null;

  /// **Getter**: Check if service has been initialized
  /// **AI Context**: Indicates if cached session data has been loaded
  bool get isAuthenticationSessionInitialized => _isSessionInitialized;

  /// **Method**: Initialize authentication service with cached session data
  /// **AI Context**: App startup initialization loading cached user session
  /// **Side Effects**: Loads cached authentication data, updates service state
  /// **Error Cases**: Handles corrupted cache gracefully by resetting state
  Future<AuthenticationServiceInitializationResult> initializeAuthenticationSession() async {
    try {
      // AI Context: Load cached user session if available
      final cachedUser = await _authenticationRepository.getCurrentAuthenticatedUser();
      
      if (cachedUser != null) {
        // AI Context: Validate session is still valid
        final isSessionValid = await _authenticationRepository.isUserSessionValid();
        
        if (isSessionValid) {
          // AI Context: Cache valid session data in service
          _cachedAuthenticatedUser = cachedUser;
          _cachedAuthenticationToken = 'cached_token'; // Note: Token would come from repository
          _isSessionInitialized = true;
          
          return AuthenticationServiceInitializationResult.authenticatedSession(
            user: cachedUser,
          );
        } else {
          // AI Context: Session expired - attempt refresh
          final refreshResult = await _authenticationRepository.refreshUserSession();
          
          if (refreshResult.isSuccessful && refreshResult.authenticatedUser != null) {
            _cachedAuthenticatedUser = refreshResult.authenticatedUser;
            _cachedAuthenticationToken = refreshResult.authenticationToken;
            _isSessionInitialized = true;
            
            return AuthenticationServiceInitializationResult.refreshedSession(
              user: refreshResult.authenticatedUser!,
            );
          } else {
            // AI Context: Refresh failed - clear session and require login
            await _clearAuthenticationSession();
            return AuthenticationServiceInitializationResult.unauthenticatedSession();
          }
        }
      } else {
        // AI Context: No cached session - user needs to authenticate
        _isSessionInitialized = true;
        return AuthenticationServiceInitializationResult.unauthenticatedSession();
      }
    } catch (error) {
      // AI Context: Handle initialization errors gracefully
      await _clearAuthenticationSession();
      return AuthenticationServiceInitializationResult.initializationError(
        errorMessage: 'Error al inicializar la sesión: ${error.toString()}',
      );
    }
  }

  /// **Method**: Authenticate user with email and password
  /// **AI Context**: Primary authentication flow with comprehensive error handling
  /// **Inputs**: emailAddress (String), password (String)
  /// **Outputs**: Future AuthenticationServiceResult with success or error details
  /// **Side Effects**: Updates cached user and token on success
  Future<AuthenticationServiceResult> authenticateUserWithEmailAndPassword({
    required String emailAddress,
    required String password,
  }) async {
    try {
      // AI Context: Execute authentication use case
      final authenticationResult = await _authenticateUserUseCase.executeUserAuthentication(
        emailAddress: emailAddress,
        password: password,
      );

      if (authenticationResult.isSuccessful && 
          authenticationResult.authenticatedUser != null &&
          authenticationResult.authenticationToken != null) {
        
        // AI Context: Cache successful authentication in service
        _cachedAuthenticatedUser = authenticationResult.authenticatedUser;
        _cachedAuthenticationToken = authenticationResult.authenticationToken;
        
        return AuthenticationServiceResult.success(
          user: authenticationResult.authenticatedUser!,
          authToken: authenticationResult.authenticationToken!,
        );
      } else {
        return AuthenticationServiceResult.failure(
          errorMessage: authenticationResult.userFriendlyErrorMessage,
        );
      }
    } catch (error) {
      return AuthenticationServiceResult.failure(
        errorMessage: 'Error inesperado durante la autenticación: ${error.toString()}',
      );
    }
  }

  /// **Method**: Sign out current user and clear session
  /// **AI Context**: Complete logout flow with session cleanup
  /// **Side Effects**: Clears cached data, revokes tokens, updates state
  /// **Error Cases**: Continues cleanup even if token revocation fails
  Future<AuthenticationServiceResult> signOutCurrentUser() async {
    try {
      // AI Context: Sign out via repository (handles token revocation)
      final signOutResult = await _authenticationRepository.signOutCurrentUser();
      
      // AI Context: Clear cached session data regardless of repository result
      await _clearAuthenticationSession();
      
      if (signOutResult.isSuccessful) {
        return AuthenticationServiceResult.signOutSuccess();
      } else {
        // AI Context: Repository error but local cleanup succeeded
        return AuthenticationServiceResult.signOutSuccess(
          warningMessage: signOutResult.errorMessage,
        );
      }
    } catch (error) {
      // AI Context: Ensure local cleanup even on error
      await _clearAuthenticationSession();
      return AuthenticationServiceResult.signOutSuccess(
        warningMessage: 'Sesión cerrada localmente: ${error.toString()}',
      );
    }
  }

  /// **Method**: Refresh current authentication session
  /// **AI Context**: Proactive session refresh to prevent authentication failures
  /// **Side Effects**: Updates cached tokens without user interaction
  /// **Error Cases**: Handles refresh failure by clearing invalid session
  Future<AuthenticationServiceResult> refreshCurrentAuthenticationSession() async {
    try {
      if (!isUserCurrentlyAuthenticated) {
        return AuthenticationServiceResult.failure(
          errorMessage: 'No hay sesión activa para refrescar',
        );
      }

      final refreshResult = await _authenticationRepository.refreshUserSession();
      
      if (refreshResult.isSuccessful && refreshResult.authenticatedUser != null) {
        // AI Context: Update cached session with refreshed tokens
        _cachedAuthenticatedUser = refreshResult.authenticatedUser;
        _cachedAuthenticationToken = refreshResult.authenticationToken;
        
        return AuthenticationServiceResult.success(
          user: refreshResult.authenticatedUser!,
          authToken: refreshResult.authenticationToken!,
        );
      } else {
        // AI Context: Refresh failed - clear invalid session
        await _clearAuthenticationSession();
        return AuthenticationServiceResult.sessionExpired();
      }
    } catch (error) {
      await _clearAuthenticationSession();
      return AuthenticationServiceResult.sessionExpired();
    }
  }

  /// **Method**: Check if current user has specific role privileges
  /// **AI Context**: Role-based access control helper for feature gating
  /// **Input**: requiredRole (UserRoleType)
  /// **Returns**: bool indicating if user has required role
  bool currentUserHasRole(UserRoleType requiredRole) {
    if (_cachedAuthenticatedUser == null) return false;
    return _cachedAuthenticatedUser!.roleType == requiredRole;
  }

  /// **Method**: Check if current user has administrator privileges
  /// **AI Context**: Quick admin check for administrative feature access
  /// **Returns**: bool indicating if user is administrator
  bool get currentUserIsAdministrator => 
      _cachedAuthenticatedUser?.hasAdministratorPrivileges ?? false;

  /// **Method**: Check if current user is professor/teacher
  /// **AI Context**: Quick professor check for teaching feature access
  /// **Returns**: bool indicating if user is professor
  bool get currentUserIsProfessor => 
      _cachedAuthenticatedUser?.isProfessorRole ?? false;

  /// **Method**: Check if current user is student
  /// **AI Context**: Quick student check for student feature access
  /// **Returns**: bool indicating if user is student
  bool get currentUserIsStudent => 
      _cachedAuthenticatedUser?.isStudentRole ?? false;

  /// **Private Method**: Clear all cached authentication session data
  /// **AI Context**: Internal cleanup method for session termination
  /// **Side Effects**: Resets all cached authentication state
  Future<void> _clearAuthenticationSession() async {
    _cachedAuthenticatedUser = null;
    _cachedAuthenticationToken = null;
    _isSessionInitialized = true; // Keep initialized flag to prevent re-initialization
  }

  /// **Method**: Dispose service and clean up resources
  /// **AI Context**: Cleanup method for service lifecycle management
  /// **Side Effects**: Clears cached data and resets state
  Future<void> dispose() async {
    await _clearAuthenticationSession();
    _isSessionInitialized = false;
  }
}

/// **AuthenticationServiceResult**: Result object for authentication service operations
/// **AI Context**: Encapsulates all possible outcomes of authentication operations
class AuthenticationServiceResult {
  final bool isSuccessful;
  final UserEntity? authenticatedUser;
  final String? authenticationToken;
  final String? errorMessage;
  final String? warningMessage;
  final AuthenticationServiceResultType resultType;

  const AuthenticationServiceResult._({
    required this.isSuccessful,
    required this.resultType,
    this.authenticatedUser,
    this.authenticationToken,
    this.errorMessage,
    this.warningMessage,
  });

  /// **Factory**: Create successful authentication result
  factory AuthenticationServiceResult.success({
    required UserEntity user,
    required String authToken,
  }) {
    return AuthenticationServiceResult._(
      isSuccessful: true,
      resultType: AuthenticationServiceResultType.success,
      authenticatedUser: user,
      authenticationToken: authToken,
    );
  }

  /// **Factory**: Create authentication failure result
  factory AuthenticationServiceResult.failure({
    required String errorMessage,
  }) {
    return AuthenticationServiceResult._(
      isSuccessful: false,
      resultType: AuthenticationServiceResultType.failure,
      errorMessage: errorMessage,
    );
  }

  /// **Factory**: Create successful sign out result
  factory AuthenticationServiceResult.signOutSuccess({
    String? warningMessage,
  }) {
    return AuthenticationServiceResult._(
      isSuccessful: true,
      resultType: AuthenticationServiceResultType.signOutSuccess,
      warningMessage: warningMessage,
    );
  }

  /// **Factory**: Create session expired result
  factory AuthenticationServiceResult.sessionExpired() {
    return const AuthenticationServiceResult._(
      isSuccessful: false,
      resultType: AuthenticationServiceResultType.sessionExpired,
      errorMessage: 'Tu sesión ha expirado. Inicia sesión nuevamente.',
    );
  }
}

/// **AuthenticationServiceInitializationResult**: Result for service initialization
class AuthenticationServiceInitializationResult {
  final bool hasAuthenticatedSession;
  final UserEntity? authenticatedUser;
  final String? errorMessage;
  final AuthenticationServiceInitializationType initializationType;

  const AuthenticationServiceInitializationResult._({
    required this.hasAuthenticatedSession,
    required this.initializationType,
    this.authenticatedUser,
    this.errorMessage,
  });

  factory AuthenticationServiceInitializationResult.authenticatedSession({
    required UserEntity user,
  }) {
    return AuthenticationServiceInitializationResult._(
      hasAuthenticatedSession: true,
      initializationType: AuthenticationServiceInitializationType.authenticatedSession,
      authenticatedUser: user,
    );
  }

  factory AuthenticationServiceInitializationResult.refreshedSession({
    required UserEntity user,
  }) {
    return AuthenticationServiceInitializationResult._(
      hasAuthenticatedSession: true,
      initializationType: AuthenticationServiceInitializationType.refreshedSession,
      authenticatedUser: user,
    );
  }

  factory AuthenticationServiceInitializationResult.unauthenticatedSession() {
    return const AuthenticationServiceInitializationResult._(
      hasAuthenticatedSession: false,
      initializationType: AuthenticationServiceInitializationType.unauthenticatedSession,
    );
  }

  factory AuthenticationServiceInitializationResult.initializationError({
    required String errorMessage,
  }) {
    return AuthenticationServiceInitializationResult._(
      hasAuthenticatedSession: false,
      initializationType: AuthenticationServiceInitializationType.initializationError,
      errorMessage: errorMessage,
    );
  }
}

/// **Enums**: Type definitions for result categorization
enum AuthenticationServiceResultType {
  success,
  failure,
  signOutSuccess,
  sessionExpired,
}

enum AuthenticationServiceInitializationType {
  authenticatedSession,
  refreshedSession,
  unauthenticatedSession,
  initializationError,
}