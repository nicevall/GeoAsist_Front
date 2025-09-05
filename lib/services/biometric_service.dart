import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/biometric_service.dart
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
// iOS import removed for Android-only build
import 'security_service.dart';

/// ✅ PRODUCTION READY: Biometric Authentication Service
/// Provides secure biometric authentication with fallback mechanisms
class BiometricService {
  static const String _tag = 'BiometricService';
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Biometric authentication configuration
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const int _maxBiometricAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 5);
  
  // Attempt tracking
  static const String _failedAttemptsKey = 'biometric_failed_attempts';
  static const String _lockoutTimeKey = 'biometric_lockout_time';
  
  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;
      
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isEnrolled = await _localAuth.getAvailableBiometrics();
      
      logger.d('$_tag: Device supported: $isAvailable, Can authenticate: $canAuthenticate, Enrolled: ${isEnrolled.isNotEmpty}');
      return canAuthenticate && isEnrolled.isNotEmpty;
    } catch (e) {
      logger.d('$_tag: Error checking biometric availability: $e');
      return false;
    }
  }
  
  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      logger.d('$_tag: Error getting available biometrics: $e');
      return [];
    }
  }
  
  /// Authenticate using biometrics
  static Future<BiometricAuthResult> authenticateWithBiometrics({
    String? reason,
    bool stickyAuth = true,
    bool sensitiveTransaction = true,
    bool biometricOnly = false,
  }) async {
    try {
      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }
      
      // Check if user has enabled biometric authentication
      final isBiometricEnabled = await _isBiometricEnabled();
      if (!isBiometricEnabled && !await _promptEnableBiometric()) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notEnabled,
          errorMessage: 'Biometric authentication is not enabled',
        );
      }
      
      // Perform biometric authentication
      final authResult = await _performBiometricAuth(
        reason: reason ?? 'Please authenticate to continue',
        stickyAuth: stickyAuth,
        sensitiveTransaction: sensitiveTransaction,
        biometricOnly: biometricOnly,
      );
      
      if (authResult.success) {
        await _onBiometricSuccess();
      } else {
        await _onBiometricFailure(authResult.errorType ?? BiometricErrorType.unknown);
      }
      
      return authResult;
    } catch (e) {
      logger.d('$_tag: Biometric authentication error: $e');
      return BiometricAuthResult(
        success: false,
        errorType: BiometricErrorType.unknown,
        errorMessage: 'An unexpected error occurred during authentication',
      );
    }
  }
  
  /// Perform the actual biometric authentication
  static Future<BiometricAuthResult> _performBiometricAuth({
    required String reason,
    required bool stickyAuth,
    required bool sensitiveTransaction,
    required bool biometricOnly,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
        ),
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'GeoAsist Authentication',
            biometricHint: 'Verify your identity to continue',
            biometricNotRecognized: 'Biometric not recognized. Try again.',
            biometricRequiredTitle: 'Biometric Authentication Required',
            biometricSuccess: 'Authentication successful',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device Credential Required',
            deviceCredentialsSetupDescription: 'Please set up device credentials to continue',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Biometric authentication is not set up on your device. Go to Settings to set it up.',
          ),
        ],
      );
      
      if (authenticated) {
        logger.d('$_tag: Biometric authentication successful');
        return BiometricAuthResult(success: true);
      } else {
        logger.d('$_tag: Biometric authentication failed');
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.authenticationFailed,
          errorMessage: 'Authentication failed. Please try again.',
        );
      }
    } on PlatformException catch (e) {
      logger.d('$_tag: Platform exception during biometric auth: ${e.code} - ${e.message}');
      return _handlePlatformException(e);
    }
  }
  
  /// Handle platform-specific exceptions
  static BiometricAuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      case 'NotEnrolled':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notEnrolled,
          errorMessage: 'No biometric credentials are enrolled on this device',
        );
      case 'LockedOut':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.lockedOut,
          errorMessage: 'Biometric authentication is temporarily locked due to too many failed attempts',
        );
      case 'PermanentlyLockedOut':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.permanentlyLockedOut,
          errorMessage: 'Biometric authentication is permanently locked. Please use device passcode.',
        );
      case 'BiometricOnlyNotSupported':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.biometricOnlyNotSupported,
          errorMessage: 'Device does not support biometric-only authentication',
        );
      case 'UserCancel':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userCancel,
          errorMessage: 'Authentication was cancelled by user',
        );
      case 'UserFallback':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userFallback,
          errorMessage: 'User chose to use device passcode instead',
        );
      default:
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.unknown,
          errorMessage: e.message ?? 'An unknown error occurred during authentication',
        );
    }
  }
  
  /// Enable biometric authentication
  static Future<bool> enableBiometricAuth() async {
    try {
      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        logger.d('$_tag: Cannot enable biometric - not available');
        return false;
      }
      
      // Test biometric authentication
      final testResult = await authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login for GeoAsist',
        biometricOnly: true,
      );
      
      if (testResult.success) {
        await SecurityService.storeUserData(_biometricEnabledKey, 'true');
        
        // Store the type of biometric that was used
        final availableBiometrics = await getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          await SecurityService.storeUserData(
            _biometricTypeKey, 
            availableBiometrics.first.name,
          );
        }
        
        logger.d('$_tag: Biometric authentication enabled successfully');
        return true;
      } else {
        logger.d('$_tag: Failed to enable biometric authentication: ${testResult.errorMessage}');
        return false;
      }
    } catch (e) {
      logger.d('$_tag: Error enabling biometric authentication: $e');
      return false;
    }
  }
  
  /// Disable biometric authentication
  static Future<void> disableBiometricAuth() async {
    try {
      await SecurityService.storeUserData(_biometricEnabledKey, 'false');
      logger.d('$_tag: Biometric authentication disabled');
    } catch (e) {
      logger.d('$_tag: Error disabling biometric authentication: $e');
    }
  }
  
  /// Check if biometric authentication is enabled
  static Future<bool> _isBiometricEnabled() async {
    try {
      final enabled = await SecurityService.getUserData(_biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      logger.d('$_tag: Error checking if biometric is enabled: $e');
      return false;
    }
  }
  
  /// Check if user has biometric authentication enabled
  static Future<bool> isBiometricEnabled() async {
    return await _isBiometricEnabled();
  }
  
  /// Prompt user to enable biometric authentication
  static Future<bool> _promptEnableBiometric() async {
    // This would typically show a dialog to the user
    // For now, return false to require explicit enabling
    logger.d('$_tag: User needs to explicitly enable biometric authentication');
    return false;
  }
  
  /// Handle successful biometric authentication
  static Future<void> _onBiometricSuccess() async {
    logger.d('$_tag: Biometric authentication successful');
    
    // Clear any lockout data on successful authentication
    await _clearLockoutData();
  }
  
  /// Handle failed biometric authentication
  static Future<void> _onBiometricFailure(BiometricErrorType errorType) async {
    logger.d('$_tag: Biometric authentication failed: ${errorType.name}');
    
    // Only track failed attempts for authentication failures, not cancellations
    if (errorType == BiometricErrorType.authenticationFailed) {
      await _incrementFailedAttempts();
    }
  }
  
  /// Increment failed attempts counter
  static Future<void> _incrementFailedAttempts() async {
    try {
      final currentAttemptsStr = await SecurityService.getUserData(_failedAttemptsKey) ?? '0';
      final currentAttempts = int.tryParse(currentAttemptsStr) ?? 0;
      final newAttempts = currentAttempts + 1;
      
      await SecurityService.storeUserData(_failedAttemptsKey, newAttempts.toString());
      
      // If max attempts reached, set lockout time
      if (newAttempts >= _maxBiometricAttempts) {
        final lockoutTime = DateTime.now().add(_lockoutDuration);
        await SecurityService.storeUserData(_lockoutTimeKey, lockoutTime.toIso8601String());
        logger.d('$_tag: Max biometric attempts reached. Locked out until $lockoutTime');
      }
      
      logger.d('$_tag: Failed attempts: $newAttempts/$_maxBiometricAttempts');
    } catch (e) {
      logger.d('$_tag: Error tracking failed attempts: $e');
    }
  }
  
  /// Check if biometric authentication is currently locked out
  static Future<bool> isLockedOut() async {
    try {
      final lockoutTimeStr = await SecurityService.getUserData(_lockoutTimeKey);
      if (lockoutTimeStr == null) return false;
      
      final lockoutTime = DateTime.tryParse(lockoutTimeStr);
      if (lockoutTime == null) return false;
      
      final isLockedOut = DateTime.now().isBefore(lockoutTime);
      
      // If lockout has expired, clear the lockout data
      if (!isLockedOut) {
        await _clearLockoutData();
      }
      
      return isLockedOut;
    } catch (e) {
      logger.d('$_tag: Error checking lockout status: $e');
      return false;
    }
  }
  
  /// Clear lockout data after successful authentication or expired lockout
  static Future<void> _clearLockoutData() async {
    try {
      await SecurityService.removeUserData(_failedAttemptsKey);
      await SecurityService.removeUserData(_lockoutTimeKey);
      logger.d('$_tag: Cleared biometric lockout data');
    } catch (e) {
      logger.d('$_tag: Error clearing lockout data: $e');
    }
  }
  
  /// Get biometric configuration
  static Future<BiometricConfig> getBiometricConfig() async {
    return BiometricConfig(
      isAvailable: await isBiometricAvailable(),
      isEnabled: await _isBiometricEnabled(),
      availableBiometrics: await getAvailableBiometrics(),
      enabledBiometricType: await SecurityService.getUserData(_biometricTypeKey),
    );
  }
  
  /// Validate biometric integrity
  static Future<bool> validateBiometricIntegrity() async {
    try {
      // Check if biometric enrollment has changed
      final availableBiometrics = await getAvailableBiometrics();
      final storedBiometricType = await SecurityService.getUserData(_biometricTypeKey);
      
      if (storedBiometricType != null) {
        final hasStoredType = availableBiometrics
            .any((type) => type.name == storedBiometricType);
        
        if (!hasStoredType) {
          logger.d('$_tag: Biometric configuration changed - disabling');
          await disableBiometricAuth();
          return false;
        }
      }
      
      return true;
    } catch (e) {
      logger.d('$_tag: Error validating biometric integrity: $e');
      return false;
    }
  }
  
  /// Reset biometric configuration
  static Future<void> resetBiometricConfig() async {
    try {
      await SecurityService.storeUserData(_biometricEnabledKey, 'false');
      await SecurityService.storeUserData(_biometricTypeKey, '');
      logger.d('$_tag: Biometric configuration reset');
    } catch (e) {
      logger.d('$_tag: Error resetting biometric configuration: $e');
    }
  }
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String? errorMessage;
  
  BiometricAuthResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });
  
  @override
  String toString() {
    return 'BiometricAuthResult{success: $success, errorType: $errorType, errorMessage: $errorMessage}';
  }
}

/// Biometric error types
enum BiometricErrorType {
  notAvailable,
  notEnabled,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  biometricOnlyNotSupported,
  userCancel,
  userFallback,
  authenticationFailed,
  unknown,
}

/// Biometric configuration
class BiometricConfig {
  final bool isAvailable;
  final bool isEnabled;
  final List<BiometricType> availableBiometrics;
  final String? enabledBiometricType;
  
  BiometricConfig({
    required this.isAvailable,
    required this.isEnabled,
    required this.availableBiometrics,
    this.enabledBiometricType,
  });
  
  bool get canAuthenticate => isAvailable && isEnabled;
  
  String get biometricTypeDisplayName {
    if (enabledBiometricType == null) return 'Not configured';
    
    switch (enabledBiometricType!) {
      case 'fingerprint':
        return 'Fingerprint';
      case 'face':
        return 'Face ID';
      case 'iris':
        return 'Iris';
      case 'weak':
        return 'Screen Lock';
      case 'strong':
        return 'Strong Biometric';
      default:
        return 'Biometric';
    }
  }
}

/// Extension for BiometricType enum
extension BiometricTypeExtension on BiometricType {
  String get displayName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Screen Lock';
      case BiometricType.strong:
        return 'Strong Biometric';
    }
  }
  
  String get description {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Use your fingerprint to authenticate';
      case BiometricType.face:
        return 'Use Face ID to authenticate';
      case BiometricType.iris:
        return 'Use iris recognition to authenticate';
      case BiometricType.weak:
        return 'Use your device screen lock to authenticate';
      case BiometricType.strong:
        return 'Use strong biometric authentication';
    }
  }
}