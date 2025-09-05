// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/bloc/base_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object> get props => [];
}

class AuthSignInEvent extends AuthEvent {
  final String email;
  final String password;
  
  const AuthSignInEvent({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

class AuthSignOutEvent extends AuthEvent {
  const AuthSignOutEvent();
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

class AuthRefreshTokenEvent extends AuthEvent {
  const AuthRefreshTokenEvent();
}

class AuthUpdateProfileEvent extends AuthEvent {
  final Map<String, dynamic> profileData;
  
  const AuthUpdateProfileEvent(this.profileData);
  
  @override
  List<Object> get props => [profileData];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  
  const AuthLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final String? code;
  
  const AuthError({
    required this.message,
    this.code,
  });
  
  @override
  List<Object?> get props => [message, code];
}

class AuthProfileUpdated extends AuthState {
  final AuthUser user;
  
  const AuthProfileUpdated(this.user);
  
  @override
  List<Object> get props => [user];
}

// User model
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isEmailVerified;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isEmailVerified = false,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
  });
  
  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    isEmailVerified,
    avatarUrl,
    createdAt,
    lastLoginAt,
  ];
  
  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isEmailVerified,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
  
  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null 
        ? DateTime.parse(map['lastLoginAt']) 
        : null,
    );
  }
}

// BLoC Implementation
class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  // This would normally be injected via dependency injection
  // final AuthRepository _authRepository;
  
  AuthBloc(/* this._authRepository */) : super(const AuthInitial()) {
    on<AuthSignInEvent>(_onSignIn);
    on<AuthSignOutEvent>(_onSignOut);
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthRefreshTokenEvent>(_onRefreshToken);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
  }
  
  Future<void> _onSignIn(AuthSignInEvent event, Emitter<AuthState> emit) async {
    await handleAsyncOperation<AuthUser>(
      emit: emit,
      operation: _performSignIn(event.email, event.password),
      loadingState: const AuthLoading(message: 'Iniciando sesión...'),
      successState: (user) => AuthAuthenticated(user),
      errorState: (error) => AuthError(
        message: _getErrorMessage(error),
        code: _getErrorCode(error),
      ),
    );
  }
  
  Future<void> _onSignOut(AuthSignOutEvent event, Emitter<AuthState> emit) async {
    await handleAsyncOperation<void>(
      emit: emit,
      operation: _performSignOut(),
      loadingState: const AuthLoading(message: 'Cerrando sesión...'),
      successState: (_) => const AuthUnauthenticated(),
      errorState: (error) => AuthError(
        message: _getErrorMessage(error),
        code: _getErrorCode(error),
      ),
    );
  }
  
  Future<void> _onCheckStatus(AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Verificando sesión...'));
    
    try {
      final result = await _checkAuthStatus();
      if (result.isSuccess) {
        emit(AuthAuthenticated((result as Success<AuthUser>).value));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (error) {
      emit(AuthError(
        message: _getErrorMessage(error),
        code: _getErrorCode(error),
      ));
    }
  }
  
  Future<void> _onRefreshToken(AuthRefreshTokenEvent event, Emitter<AuthState> emit) async {
    try {
      final result = await _refreshToken();
      if (result.isSuccess) {
        final currentState = state;
        if (currentState is AuthAuthenticated) {
          // Token refreshed successfully, no state change needed
          // Could emit a temporary success state if needed
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (error) {
      emit(AuthError(
        message: _getErrorMessage(error),
        code: _getErrorCode(error),
      ));
    }
  }
  
  Future<void> _onUpdateProfile(AuthUpdateProfileEvent event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await handleAsyncOperation<AuthUser>(
        emit: emit,
        operation: _updateProfile(currentState.user.id, event.profileData),
        loadingState: const AuthLoading(message: 'Actualizando perfil...'),
        successState: (user) => AuthProfileUpdated(user),
        errorState: (error) => AuthError(
          message: _getErrorMessage(error),
          code: _getErrorCode(error),
        ),
      );
    }
  }
  
  // Mock implementations - these would use real repositories
  Future<AuthUser> _performSignIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      throw AuthFailure.invalidCredentials();
    }
    
    // Mock successful login
    return AuthUser(
      id: 'user123',
      email: email,
      name: 'Usuario Demo',
      role: 'student',
      isEmailVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
  }
  
  Future<void> _performSignOut() async {
    await Future.delayed(const Duration(seconds: 1));
    // Clear local storage, tokens, etc.
  }
  
  Future<Result<AuthUser>> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    // Check if user is authenticated
    return const Failure(AuthFailure(message: 'Not authenticated'));
  }
  
  Future<Result<void>> _refreshToken() async {
    await Future.delayed(const Duration(seconds: 1));
    // Refresh authentication token
    return Success(null);
  }
  
  Future<AuthUser> _updateProfile(String userId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    // Update user profile
    return AuthUser(
      id: userId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      isEmailVerified: data['isEmailVerified'] ?? false,
      avatarUrl: data['avatarUrl'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
  }
  
  String _getErrorMessage(Object error) {
    if (error is AuthFailure) {
      return error.message;
    } else if (error is NetworkFailure) {
      return error.message;
    } else {
      return 'An unexpected error occurred';
    }
  }
  
  String? _getErrorCode(Object error) {
    if (error is AuthFailure) {
      return error.code;
    } else if (error is NetworkFailure) {
      return error.code;
    }
    return null;
  }
}