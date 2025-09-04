/// **UserEntity**: Core business entity for user authentication and authorization
/// 
/// **Purpose**: Represents the fundamental user domain object with role-based access
/// **AI Context**: This entity defines user properties and business rules for authentication
/// **Dependencies**: None (Pure domain entity)
/// **Used by**: AuthenticationRepository, UserUseCase
/// **Performance**: Lightweight value object optimized for frequent access
class UserEntity {
  /// **Property**: User unique identifier from backend database
  /// **AI Context**: Primary key for user identification across system
  final String userIdentifier;
  
  /// **Property**: User display name for UI and notifications
  /// **AI Context**: Human-readable name for user identification
  final String displayName;
  
  /// **Property**: User email address for communication and login
  /// **AI Context**: Unique login credential and contact method
  final String emailAddress;
  
  /// **Property**: User role determining app permissions and features
  /// **AI Context**: Role-based access control - admin, profesor, estudiante only
  final UserRoleType roleType;
  
  /// **Property**: Account creation timestamp for audit purposes
  /// **AI Context**: Used for account age validation and audit trails
  final DateTime? accountCreatedAt;

  const UserEntity({
    required this.userIdentifier,
    required this.displayName,
    required this.emailAddress,
    required this.roleType,
    this.accountCreatedAt,
  });

  /// **Method**: Check if user has administrator privileges
  /// **AI Context**: Determines if user can access admin-only features
  /// **Returns**: boolean indicating admin status
  bool get hasAdministratorPrivileges => roleType == UserRoleType.administrator;
  
  /// **Method**: Check if user is a professor/teacher
  /// **AI Context**: Determines if user can create events and manage students
  /// **Returns**: boolean indicating professor status
  bool get isProfessorRole => roleType == UserRoleType.professor;
  
  /// **Method**: Check if user is a student
  /// **AI Context**: Determines if user can attend events and mark attendance
  /// **Returns**: boolean indicating student status
  bool get isStudentRole => roleType == UserRoleType.student;

  /// **Method**: Create copy of user entity with modified properties
  /// **AI Context**: Immutable object pattern for state management
  UserEntity copyWith({
    String? userIdentifier,
    String? displayName,
    String? emailAddress,
    UserRoleType? roleType,
    DateTime? accountCreatedAt,
  }) {
    return UserEntity(
      userIdentifier: userIdentifier ?? this.userIdentifier,
      displayName: displayName ?? this.displayName,
      emailAddress: emailAddress ?? this.emailAddress,
      roleType: roleType ?? this.roleType,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
           other.userIdentifier == userIdentifier &&
           other.displayName == displayName &&
           other.emailAddress == emailAddress &&
           other.roleType == roleType &&
           other.accountCreatedAt == accountCreatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      userIdentifier,
      displayName,
      emailAddress,
      roleType,
      accountCreatedAt,
    );
  }

  @override
  String toString() {
    return 'UserEntity{id: $userIdentifier, name: $displayName, role: $roleType}';
  }
}

/// **Enum**: User role types supported by the system
/// **AI Context**: Defines the three role-based access control levels
/// **Values**: administrator, professor, student (matching backend)
enum UserRoleType {
  /// **Role**: System administrator with full access
  /// **AI Context**: Can manage all users, events, and system settings
  administrator,
  
  /// **Role**: Professor/teacher who creates and manages events
  /// **AI Context**: Can create events, manage attendance, view reports
  professor,
  
  /// **Role**: Student who attends events and marks attendance
  /// **AI Context**: Can view events, mark attendance, submit justifications
  student;

  /// **Method**: Convert enum to backend-compatible string
  /// **AI Context**: Ensures consistent role naming with backend system
  String get backendRoleName {
    switch (this) {
      case UserRoleType.administrator:
        return 'admin';
      case UserRoleType.professor:
        return 'profesor';
      case UserRoleType.student:
        return 'estudiante';
    }
  }

  /// **Method**: Create enum from backend role string
  /// **AI Context**: Parses backend role response into type-safe enum
  static UserRoleType fromBackendRole(String backendRole) {
    switch (backendRole.toLowerCase()) {
      case 'admin':
        return UserRoleType.administrator;
      case 'profesor':
        return UserRoleType.professor;
      case 'estudiante':
        return UserRoleType.student;
      default:
        throw ArgumentError('Unknown role: $backendRole');
    }
  }
}