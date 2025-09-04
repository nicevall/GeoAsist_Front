import '../../domain/entities/user_entity.dart';

/// **UserModel**: Data Transfer Object for user authentication and API integration
/// 
/// **Purpose**: Handles JSON serialization/deserialization for user data from backend
/// **AI Context**: Bridge between external API and domain entities
/// **Dependencies**: UserEntity, UserRoleType
/// **Used by**: AuthenticationRepository, ApiService
/// **Performance**: Optimized for frequent JSON parsing operations
class UserModel extends UserEntity {
  const UserModel({
    required super.userIdentifier,
    required super.displayName,
    required super.emailAddress,
    required super.roleType,
    super.accountCreatedAt,
  });

  /// **Factory**: Create UserModel from backend JSON response
  /// **AI Context**: Parses API response with backend field names (correo, rol)
  /// **Input**: Map with String keys and dynamic values from HTTP response
  /// **Output**: UserModel with validated and parsed data
  /// **Error Cases**: Missing required fields, invalid role types
  factory UserModel.fromBackendJson(Map<String, dynamic> backendJson) {
    // AI Context: Handle multiple ID field formats from different endpoints
    final userId = backendJson['_id']?.toString() ?? 
                   backendJson['id']?.toString() ?? 
                   '';
                   
    if (userId.isEmpty) {
      throw ArgumentError('User ID is required but was empty or null');
    }

    // AI Context: Backend uses 'correo' instead of 'email'
    final emailAddress = backendJson['correo']?.toString() ?? '';
    if (emailAddress.isEmpty) {
      throw ArgumentError('Email address is required but was empty or null');
    }

    // AI Context: Backend uses 'rol' field with Spanish role names
    final backendRole = backendJson['rol']?.toString() ?? 'estudiante';
    final roleType = UserRoleType.fromBackendRole(backendRole);

    // AI Context: Parse optional timestamp with null safety
    DateTime? createdTimestamp;
    final creadoEnValue = backendJson['creadoEn'];
    if (creadoEnValue != null) {
      try {
        createdTimestamp = DateTime.parse(creadoEnValue.toString());
      } catch (e) {
        // AI Context: Log parsing error but don't fail the entire user creation
        createdTimestamp = null;
      }
    }

    return UserModel(
      userIdentifier: userId,
      displayName: backendJson['nombre']?.toString() ?? '',
      emailAddress: emailAddress,
      roleType: roleType,
      accountCreatedAt: createdTimestamp,
    );
  }

  /// **Method**: Convert UserModel to backend-compatible JSON
  /// **AI Context**: Serializes for API requests with backend field names
  /// **Output**: Map with String keys and dynamic values for HTTP request body
  /// **Side Effects**: None - pure data transformation
  Map<String, dynamic> toBackendJson() {
    return {
      'nombre': displayName,
      'correo': emailAddress, // AI Context: Backend expects 'correo' not 'email'
      'rol': roleType.backendRoleName, // AI Context: Convert enum to backend string
    };
  }

  /// **Method**: Convert to simplified JSON for local storage
  /// **AI Context**: Lighter format for SharedPreferences or local cache
  /// **Output**: Minimal JSON with essential fields only
  Map<String, dynamic> toLocalStorageJson() {
    return {
      'id': userIdentifier,
      'nombre': displayName,
      'correo': emailAddress,
      'rol': roleType.backendRoleName,
      'creadoEn': accountCreatedAt?.toIso8601String(),
    };
  }

  /// **Factory**: Create UserModel from local storage JSON
  /// **AI Context**: Parses data from SharedPreferences or local cache
  /// **Input**: Map with String keys and dynamic values from local storage
  /// **Output**: UserModel instance
  factory UserModel.fromLocalStorageJson(Map<String, dynamic> localJson) {
    return UserModel.fromBackendJson(localJson);
  }

  /// **Method**: Create copy of UserModel with modified properties
  /// **AI Context**: Immutable object pattern for state management
  /// **Override**: Extends parent copyWith to return UserModel type
  @override
  UserModel copyWith({
    String? userIdentifier,
    String? displayName,
    String? emailAddress,
    UserRoleType? roleType,
    DateTime? accountCreatedAt,
  }) {
    return UserModel(
      userIdentifier: userIdentifier ?? this.userIdentifier,
      displayName: displayName ?? this.displayName,
      emailAddress: emailAddress ?? this.emailAddress,
      roleType: roleType ?? this.roleType,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
    );
  }

  /// **Method**: Create empty/placeholder UserModel
  /// **AI Context**: Useful for initialization states and testing
  /// **Returns**: UserModel with safe default values
  static UserModel empty() {
    return const UserModel(
      userIdentifier: '',
      displayName: '',
      emailAddress: '',
      roleType: UserRoleType.student,
      accountCreatedAt: null,
    );
  }

  /// **Method**: Validate UserModel has required data
  /// **AI Context**: Ensures model is complete before API operations
  /// **Returns**: boolean indicating if all required fields are present
  bool get isValidForApiOperations {
    return userIdentifier.isNotEmpty && 
           displayName.isNotEmpty && 
           emailAddress.isNotEmpty &&
           emailAddress.contains('@');
  }
}