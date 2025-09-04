import '../models/user_model.dart';

/// **AuthenticationLocalDataSource**: Local storage interface for authentication data
/// 
/// **Purpose**: Defines contract for local authentication data persistence
/// **AI Context**: Data source abstraction for offline-first architecture
/// **Dependencies**: UserModel only
/// **Implementation**: Concrete implementation handles SharedPreferences/Secure storage
/// **Performance**: Interface only - implementation optimizes local storage operations
abstract class AuthenticationLocalDataSource {
  /// **Method**: Cache authenticated user data locally
  /// **AI Context**: Persist user session for offline access
  /// **Inputs**: user (UserModel), authToken (String), refreshToken (String)
  /// **Outputs**: Future void indicating successful storage
  /// **Side Effects**: Writes to local storage (SharedPreferences/Secure storage)
  /// **Error Cases**: StorageException, SecurityException
  Future<void> cacheAuthenticatedUserData({
    required UserModel user,
    required String authenticationToken,
    required String refreshToken,
  });

  /// **Method**: Retrieve cached user authentication data
  /// **AI Context**: Get stored user session for app initialization
  /// **Outputs**: Future LocalAuthenticationData or null with cached data
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: StorageException, CorruptedDataException
  Future<LocalAuthenticationData?> getCachedAuthenticationData();

  /// **Method**: Check if valid authentication data exists locally
  /// **AI Context**: Quick validation without loading full user data
  /// **Outputs**: Future bool indicating if valid session exists
  /// **Side Effects**: None - validation only
  /// **Error Cases**: None - returns false on any error
  Future<bool> hasValidAuthenticationCache();

  /// **Method**: Clear all cached authentication data
  /// **AI Context**: Clean logout - remove all stored session data
  /// **Outputs**: Future void indicating successful cleanup
  /// **Side Effects**: Removes all authentication data from local storage
  /// **Error Cases**: StorageException (non-critical)
  Future<void> clearAllAuthenticationCache();

  /// **Method**: Update cached authentication tokens
  /// **AI Context**: Refresh tokens without changing user data
  /// **Inputs**: newAuthToken (String), newRefreshToken (String)
  /// **Outputs**: Future void indicating successful update
  /// **Side Effects**: Updates only token data in local storage
  /// **Error Cases**: StorageException, MissingUserDataException
  Future<void> updateCachedAuthenticationTokens({
    required String newAuthenticationToken,
    required String newRefreshToken,
  });

  /// **Method**: Get stored refresh token for session renewal
  /// **AI Context**: Retrieve refresh token for automatic authentication renewal
  /// **Outputs**: Future String or null with refresh token if not expired
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: StorageException, ExpiredTokenException
  Future<String?> getCachedRefreshToken();

  /// **Method**: Check if refresh token is expired
  /// **AI Context**: Validate refresh token without network call
  /// **Outputs**: Future bool indicating if token is still valid
  /// **Side Effects**: None - validation only
  /// **Error Cases**: None - returns true (expired) on any error
  Future<bool> isRefreshTokenExpired();

  /// **Method**: Store user preferences and settings
  /// **AI Context**: Cache user-specific app preferences locally
  /// **Inputs**: preferences Map with String keys and dynamic values
  /// **Outputs**: Future void indicating successful storage
  /// **Side Effects**: Writes preferences to local storage
  /// **Error Cases**: StorageException
  Future<void> cacheUserPreferences(Map<String, dynamic> userPreferences);

  /// **Method**: Get cached user preferences
  /// **AI Context**: Retrieve user preferences for app personalization
  /// **Outputs**: Future Map with String keys and dynamic values containing preferences or empty map
  /// **Side Effects**: None - read-only operation
  /// **Error Cases**: None - returns empty map on error
  Future<Map<String, dynamic>> getCachedUserPreferences();
}

/// **LocalAuthenticationData**: Container for cached authentication information
/// **AI Context**: Value object for complete local authentication state
class LocalAuthenticationData {
  /// **Property**: Cached user entity with profile information
  /// **AI Context**: Complete user data for offline access
  final UserModel cachedUser;
  
  /// **Property**: Current authentication token for API calls
  /// **AI Context**: Active token for authenticated requests
  final String authenticationToken;
  
  /// **Property**: Refresh token for session renewal
  /// **AI Context**: Token for automatic authentication refresh
  final String refreshToken;
  
  /// **Property**: Timestamp when data was cached
  /// **AI Context**: Used for cache invalidation and freshness validation
  final DateTime cacheTimestamp;
  
  /// **Property**: Timestamp when tokens expire
  /// **AI Context**: Used for automatic token refresh scheduling
  final DateTime? tokenExpirationTimestamp;

  const LocalAuthenticationData({
    required this.cachedUser,
    required this.authenticationToken,
    required this.refreshToken,
    required this.cacheTimestamp,
    this.tokenExpirationTimestamp,
  });

  /// **Method**: Check if cached data is still fresh
  /// **AI Context**: Determine if cache should be refreshed from server
  /// **Returns**: boolean indicating if data is within freshness threshold
  bool get isCacheDataFresh {
    final cacheDuration = DateTime.now().difference(cacheTimestamp);
    const maxCacheAge = Duration(hours: 24); // AI Context: 24-hour cache freshness
    return cacheDuration < maxCacheAge;
  }

  /// **Method**: Check if authentication tokens are expired
  /// **AI Context**: Validate tokens without network call
  /// **Returns**: boolean indicating if tokens need refresh
  bool get areTokensExpired {
    if (tokenExpirationTimestamp == null) return false;
    return DateTime.now().isAfter(tokenExpirationTimestamp!);
  }

  /// **Method**: Check if tokens will expire soon
  /// **AI Context**: Proactive token refresh to prevent auth failures
  /// **Returns**: boolean indicating if tokens should be refreshed preemptively
  bool get shouldRefreshTokensProactively {
    if (tokenExpirationTimestamp == null) return false;
    final timeUntilExpiration = tokenExpirationTimestamp!.difference(DateTime.now());
    const refreshThreshold = Duration(minutes: 15); // AI Context: Refresh 15 minutes before expiry
    return timeUntilExpiration < refreshThreshold;
  }

  /// **Method**: Convert to JSON for local storage
  /// **AI Context**: Serialization for SharedPreferences or secure storage
  /// **Returns**: Map with String keys and dynamic values for storage
  Map<String, dynamic> toStorageJson() {
    return {
      'user': cachedUser.toLocalStorageJson(),
      'authToken': authenticationToken,
      'refreshToken': refreshToken,
      'cacheTimestamp': cacheTimestamp.toIso8601String(),
      'tokenExpiration': tokenExpirationTimestamp?.toIso8601String(),
    };
  }

  /// **Factory**: Create from stored JSON data
  /// **AI Context**: Deserialization from local storage
  /// **Input**: Map with String keys and dynamic values from storage
  /// **Returns**: LocalAuthenticationData instance
  factory LocalAuthenticationData.fromStorageJson(Map<String, dynamic> storageJson) {
    return LocalAuthenticationData(
      cachedUser: UserModel.fromLocalStorageJson(
        Map<String, dynamic>.from(storageJson['user'] ?? {}),
      ),
      authenticationToken: storageJson['authToken']?.toString() ?? '',
      refreshToken: storageJson['refreshToken']?.toString() ?? '',
      cacheTimestamp: DateTime.parse(storageJson['cacheTimestamp'] ?? DateTime.now().toIso8601String()),
      tokenExpirationTimestamp: storageJson['tokenExpiration'] != null
          ? DateTime.parse(storageJson['tokenExpiration'])
          : null,
    );
  }

  /// **Method**: Create copy with updated tokens
  /// **AI Context**: Immutable update pattern for token refresh
  /// **Returns**: New LocalAuthenticationData with updated tokens
  LocalAuthenticationData copyWithNewTokens({
    required String newAuthenticationToken,
    required String newRefreshToken,
    DateTime? newTokenExpiration,
  }) {
    return LocalAuthenticationData(
      cachedUser: cachedUser,
      authenticationToken: newAuthenticationToken,
      refreshToken: newRefreshToken,
      cacheTimestamp: DateTime.now(), // AI Context: Update cache timestamp on token refresh
      tokenExpirationTimestamp: newTokenExpiration ?? tokenExpirationTimestamp,
    );
  }
}

/// **Local Storage Exception Types**: Specific exceptions for local storage errors
class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
}

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);
}

class CorruptedDataException implements Exception {
  final String message;
  const CorruptedDataException(this.message);
}

class MissingUserDataException implements Exception {
  final String message;
  const MissingUserDataException(this.message);
}