import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/use_cases/authenticate_user_use_case.dart';

/// **AuthenticationController**: Presentation state management for authentication UI
/// 
/// **Purpose**: Manages authentication state and UI interactions using ChangeNotifier pattern
/// **AI Context**: MVVM controller connecting UI to business logic with reactive state updates
/// **Dependencies**: AuthenticateUserUseCase
/// **Used by**: LoginPage, RegisterPage, authentication widgets
/// **Performance**: Optimized state management with granular UI updates
class AuthenticationController extends ChangeNotifier {
  /// **Property**: Use case for authentication business logic
  /// **AI Context**: Injected dependency following Clean Architecture principles
  final AuthenticateUserUseCase _authenticateUserUseCase;

  /// **Property**: Current authentication state of the controller
  /// **AI Context**: Reactive state that triggers UI rebuilds when changed
  AuthenticationControllerState _currentState = AuthenticationControllerState.initial();

  /// **Property**: Currently authenticated user entity
  /// **AI Context**: User data accessible to UI components
  UserEntity? _authenticatedUser;

  /// **Property**: Current authentication token for API calls
  /// **AI Context**: Token used by HTTP interceptors and API clients
  String? _authenticationToken;

  AuthenticationController({
    required AuthenticateUserUseCase authenticateUserUseCase,
  }) : _authenticateUserUseCase = authenticateUserUseCase;

  // **Getters**: Public interface for UI components
  /// **Getter**: Current authentication state for UI reactions
  /// **AI Context**: UI components use this to show loading, success, error states
  AuthenticationControllerState get currentState => _currentState;

  /// **Getter**: Currently authenticated user or null
  /// **AI Context**: UI uses this to show user profile, role-based features
  UserEntity? get authenticatedUser => _authenticatedUser;

  /// **Getter**: Authentication token for API requests
  /// **AI Context**: HTTP clients use this for authorization headers
  String? get authenticationToken => _authenticationToken;

  /// **Getter**: Check if user is currently authenticated
  /// **AI Context**: UI uses this for navigation guards and feature access
  bool get isUserAuthenticated => _authenticatedUser != null && _authenticationToken != null;

  /// **Getter**: Check if authentication operation is in progress
  /// **AI Context**: UI uses this to show loading indicators and disable forms
  bool get isAuthenticationInProgress => _currentState.isLoading;

  /// **Getter**: Current error message for user display
  /// **AI Context**: UI displays this in snackbars, dialogs, or error widgets
  String? get currentErrorMessage => _currentState.errorMessage;

  /// **Method**: Execute user authentication with email and password
  /// **AI Context**: Primary authentication flow triggered by login form submission
  /// **Inputs**: emailAddress (String), password (String)
  /// **Side Effects**: Updates state, notifies listeners, caches tokens
  /// **Error Cases**: Invalid credentials, network errors, validation failures
  Future<void> authenticateUserWithEmailAndPassword({
    required String emailAddress,
    required String password,
  }) async {
    // AI Context: Set loading state to show UI progress indicators
    _updateAuthenticationState(AuthenticationControllerState.loading());

    try {
      // AI Context: Execute authentication use case with user input
      final authenticationResult = await _authenticateUserUseCase.executeUserAuthentication(
        emailAddress: emailAddress,
        password: password,
      );

      if (authenticationResult.isSuccessful) {
        // AI Context: Store successful authentication data
        _authenticatedUser = authenticationResult.authenticatedUser;
        _authenticationToken = authenticationResult.authenticationToken;

        // AI Context: Update state to success for UI navigation
        _updateAuthenticationState(AuthenticationControllerState.authenticated(
          user: _authenticatedUser!,
          authToken: _authenticationToken!,
        ));
      } else {
        // AI Context: Handle authentication failure with user-friendly message
        _updateAuthenticationState(AuthenticationControllerState.error(
          errorMessage: authenticationResult.userFriendlyErrorMessage,
        ));
      }
    } catch (exception) {
      // AI Context: Handle unexpected errors with generic message
      _updateAuthenticationState(AuthenticationControllerState.error(
        errorMessage: 'Error inesperado: ${exception.toString()}',
      ));
    }
  }

  /// **Method**: Sign out current user and clear authentication state
  /// **AI Context**: Logout flow triggered by user action or session expiration
  /// **Side Effects**: Clears user data, revokes tokens, updates state
  Future<void> signOutCurrentUser() async {
    try {
      // AI Context: Clear authentication data immediately for security
      _authenticatedUser = null;
      _authenticationToken = null;

      // AI Context: Update state to unauthenticated for UI navigation
      _updateAuthenticationState(AuthenticationControllerState.unauthenticated());

      // AI Context: Note - Token revocation would be handled by repository
    } catch (exception) {
      // AI Context: Even on error, clear local authentication state
      _authenticatedUser = null;
      _authenticationToken = null;
      _updateAuthenticationState(AuthenticationControllerState.unauthenticated());
    }
  }

  /// **Method**: Clear current error state
  /// **AI Context**: UI calls this to dismiss error messages and retry operations
  /// **Side Effects**: Updates state without error, notifies listeners
  void clearCurrentError() {
    if (_currentState.hasError) {
      _updateAuthenticationState(AuthenticationControllerState.initial());
    }
  }

  /// **Method**: Initialize controller with cached authentication data
  /// **AI Context**: App startup initialization with potential auto-login
  /// **Inputs**: cachedUser (UserEntity?), cachedToken (String?)
  /// **Side Effects**: Updates state based on cached data validity
  void initializeWithCachedAuthentication({
    UserEntity? cachedUser,
    String? cachedToken,
  }) {
    if (cachedUser != null && cachedToken != null) {
      _authenticatedUser = cachedUser;
      _authenticationToken = cachedToken;
      
      _updateAuthenticationState(AuthenticationControllerState.authenticated(
        user: cachedUser,
        authToken: cachedToken,
      ));
    } else {
      _updateAuthenticationState(AuthenticationControllerState.unauthenticated());
    }
  }

  /// **Method**: Reset controller to initial state
  /// **AI Context**: Called during app reset or development testing
  /// **Side Effects**: Clears all data and resets to initial state
  void resetControllerToInitialState() {
    _authenticatedUser = null;
    _authenticationToken = null;
    _updateAuthenticationState(AuthenticationControllerState.initial());
  }

  /// **Private Method**: Update authentication state and notify listeners
  /// **AI Context**: Centralized state update with automatic UI notification
  /// **Input**: newState (AuthenticationControllerState)
  /// **Side Effects**: Updates internal state, calls notifyListeners()
  void _updateAuthenticationState(AuthenticationControllerState newState) {
    _currentState = newState;
    notifyListeners(); // AI Context: Trigger UI rebuild for state-dependent widgets
  }

  @override
  void dispose() {
    // AI Context: Clean up resources when controller is disposed
    super.dispose();
  }
}

/// **AuthenticationControllerState**: Immutable state object for authentication UI state
/// **AI Context**: Value object representing all possible authentication states
class AuthenticationControllerState {
  /// **Property**: Type of current authentication state
  /// **AI Context**: Determines UI behavior and component visibility
  final AuthenticationStateType stateType;

  /// **Property**: Authenticated user data when state is authenticated
  /// **AI Context**: Available only when authentication is successful
  final UserEntity? authenticatedUser;

  /// **Property**: Authentication token when state is authenticated
  /// **AI Context**: Used for API authorization in authenticated state
  final String? authenticationToken;

  /// **Property**: Error message when state is error
  /// **AI Context**: User-friendly error message for UI display
  final String? errorMessage;

  const AuthenticationControllerState._({
    required this.stateType,
    this.authenticatedUser,
    this.authenticationToken,
    this.errorMessage,
  });

  /// **Factory**: Create initial state (app startup)
  /// **AI Context**: Default state before any authentication attempt
  factory AuthenticationControllerState.initial() {
    return const AuthenticationControllerState._(
      stateType: AuthenticationStateType.initial,
    );
  }

  /// **Factory**: Create loading state (authentication in progress)
  /// **AI Context**: State during API call to show loading indicators
  factory AuthenticationControllerState.loading() {
    return const AuthenticationControllerState._(
      stateType: AuthenticationStateType.loading,
    );
  }

  /// **Factory**: Create authenticated state (login successful)
  /// **AI Context**: State after successful authentication with user data
  factory AuthenticationControllerState.authenticated({
    required UserEntity user,
    required String authToken,
  }) {
    return AuthenticationControllerState._(
      stateType: AuthenticationStateType.authenticated,
      authenticatedUser: user,
      authenticationToken: authToken,
    );
  }

  /// **Factory**: Create unauthenticated state (logout or session expired)
  /// **AI Context**: State when user needs to authenticate
  factory AuthenticationControllerState.unauthenticated() {
    return const AuthenticationControllerState._(
      stateType: AuthenticationStateType.unauthenticated,
    );
  }

  /// **Factory**: Create error state (authentication failed)
  /// **AI Context**: State when authentication fails with error message
  factory AuthenticationControllerState.error({
    required String errorMessage,
  }) {
    return AuthenticationControllerState._(
      stateType: AuthenticationStateType.error,
      errorMessage: errorMessage,
    );
  }

  // **Convenience Getters**: Boolean checks for UI logic
  /// **Getter**: Check if state is initial
  bool get isInitial => stateType == AuthenticationStateType.initial;

  /// **Getter**: Check if authentication is loading
  bool get isLoading => stateType == AuthenticationStateType.loading;

  /// **Getter**: Check if user is authenticated
  bool get isAuthenticated => stateType == AuthenticationStateType.authenticated;

  /// **Getter**: Check if user is unauthenticated
  bool get isUnauthenticated => stateType == AuthenticationStateType.unauthenticated;

  /// **Getter**: Check if state has error
  bool get hasError => stateType == AuthenticationStateType.error;

  /// **Getter**: Check if state allows user interaction
  /// **AI Context**: UI uses this to enable/disable forms and buttons
  bool get allowsUserInteraction => !isLoading;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthenticationControllerState &&
           other.stateType == stateType &&
           other.authenticatedUser == authenticatedUser &&
           other.authenticationToken == authenticationToken &&
           other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      stateType,
      authenticatedUser,
      authenticationToken,
      errorMessage,
    );
  }

  @override
  String toString() {
    return 'AuthenticationControllerState{type: $stateType, user: ${authenticatedUser?.displayName}, error: $errorMessage}';
  }
}

/// **AuthenticationStateType**: Enum defining all possible authentication states
/// **AI Context**: Type-safe state enumeration for pattern matching in UI
enum AuthenticationStateType {
  /// **State**: Initial state before any authentication attempt
  /// **AI Context**: Shows welcome screen or initial login form
  initial,

  /// **State**: Authentication request in progress
  /// **AI Context**: Shows loading indicators, disables forms
  loading,

  /// **State**: User successfully authenticated
  /// **AI Context**: Shows authenticated UI, enables protected features
  authenticated,

  /// **State**: User not authenticated (logout or session expired)
  /// **AI Context**: Shows login form, redirects to authentication
  unauthenticated,

  /// **State**: Authentication failed with error
  /// **AI Context**: Shows error message, allows retry
  error,
}