import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/security_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' show Encrypter, AES, IV, Encrypted;
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:crypto/crypto.dart';

/// ✅ PRODUCTION READY: Security Service with Encryption and Request Signing
/// Provides comprehensive security features for data protection and API security
class SecurityService {
  static const String _tag = 'SecurityService';
  
  // Secure storage configuration
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'geoasist_secure_prefs',
      preferencesKeyPrefix: 'geoasist_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.geoasist.app',
      accountName: 'geoasist_keychain',
    ),
  );
  
  // Encryption components
  static Encrypter? _encrypter;
  static encrypt_lib.Key? _signingKey;
  
  /// Initialize security service with encryption and signing
  static Future<void> initialize({String? encryptionKey, String? signingKey}) async {
    try {
      logger.d('$_tag: Initializing security service...');
      
      // Initialize encryption
      await _initializeEncryption(encryptionKey);
      
      // Initialize request signing
      await _initializeSigning(signingKey);
      
      logger.d('$_tag: Security service initialized successfully');
    } catch (e) {
      logger.d('$_tag: Failed to initialize security service: $e');
      rethrow;
    }
  }
  
  /// Initialize encryption components
  static Future<void> _initializeEncryption(String? providedKey) async {
    try {
      String encryptionKey;
      
      if (providedKey != null) {
        encryptionKey = providedKey;
      } else {
        // Try to retrieve existing key
        encryptionKey = await _secureStorage.read(key: 'encryption_key') ?? _generateEncryptionKey();
        
        // Store the key for future use
        await _secureStorage.write(key: 'encryption_key', value: encryptionKey);
      }
      
      final key = encrypt_lib.Key.fromBase64(encryptionKey);
      _encrypter = Encrypter(AES(key));
      
      logger.d('$_tag: Encryption initialized');
    } catch (e) {
      logger.d('$_tag: Failed to initialize encryption: $e');
      rethrow;
    }
  }
  
  /// Initialize signing components
  static Future<void> _initializeSigning(String? providedKey) async {
    try {
      String signingKeyStr;
      
      if (providedKey != null) {
        signingKeyStr = providedKey;
      } else {
        // Try to retrieve existing key
        signingKeyStr = await _secureStorage.read(key: 'signing_key') ?? _generateSigningKey();
        
        // Store the key for future use
        await _secureStorage.write(key: 'signing_key', value: signingKeyStr);
      }
      
      _signingKey = encrypt_lib.Key.fromBase64(signingKeyStr);
      
      logger.d('$_tag: Request signing initialized');
    } catch (e) {
      logger.d('$_tag: Failed to initialize signing: $e');
      rethrow;
    }
  }
  
  /// Generate a secure encryption key
  static String _generateEncryptionKey() {
    final key = encrypt_lib.Key.fromSecureRandom(32);
    return key.base64;
  }
  
  /// Generate a secure signing key
  static String _generateSigningKey() {
    final key = encrypt_lib.Key.fromSecureRandom(32);
    return key.base64;
  }
  
  /// Store authentication tokens securely
  static Future<void> storeAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await _secureStorage.write(key: 'auth_token', value: accessToken);
      
      if (refreshToken != null) {
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      }
      
      logger.d('$_tag: Authentication tokens stored securely');
    } catch (e) {
      logger.d('$_tag: Failed to store auth tokens: $e');
      rethrow;
    }
  }
  
  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      logger.d('$_tag: Failed to retrieve auth token: $e');
      return null;
    }
  }
  
  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: 'refresh_token');
    } catch (e) {
      logger.d('$_tag: Failed to retrieve refresh token: $e');
      return null;
    }
  }
  
  /// Clear authentication tokens
  static Future<void> clearAuthTokens() async {
    try {
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'refresh_token');
      
      logger.d('$_tag: Authentication tokens cleared');
    } catch (e) {
      logger.d('$_tag: Failed to clear auth tokens: $e');
      rethrow;
    }
  }
  
  /// Store user data securely
  static Future<void> storeUserData(String key, String value) async {
    try {
      if (_encrypter == null) {
        throw SecurityException('Encryption not initialized');
      }
      
      final iv = IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(value, iv: iv);
      final encryptedData = '${iv.base64}:${encrypted.base64}';
      
      await _secureStorage.write(key: 'user_$key', value: encryptedData);
    } catch (e) {
      logger.d('$_tag: Failed to store user data: $e');
      rethrow;
    }
  }
  
  /// Get user data securely
  static Future<String?> getUserData(String key) async {
    try {
      if (_encrypter == null) {
        throw SecurityException('Encryption not initialized');
      }
      
      final encryptedData = await _secureStorage.read(key: 'user_$key');
      if (encryptedData == null) return null;
      
      final parts = encryptedData.split(':');
      if (parts.length != 2) return null;
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      logger.d('$_tag: Failed to retrieve user data: $e');
      return null;
    }
  }
  
  /// Remove user data securely
  static Future<void> removeUserData(String key) async {
    try {
      await _secureStorage.delete(key: 'user_$key');
      logger.d('$_tag: Removed user data for key: $key');
    } catch (e) {
      logger.d('$_tag: Failed to remove user data: $e');
      rethrow;
    }
  }
  
  /// Sign API request
  static String signRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    String? body,
  }) {
    if (_signingKey == null) {
      throw SecurityException('API signing not initialized');
    }
    
    try {
      // Create signature payload
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final nonce = _generateNonce();
      
      // Build string to sign
      final stringToSign = _buildSignatureString(
        method: method,
        url: url,
        headers: headers,
        body: body,
        timestamp: timestamp,
        nonce: nonce,
      );
      
      // Create HMAC-SHA256 signature
      final key = _signingKey!.bytes;
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(utf8.encode(stringToSign));
      
      final signature = base64Encode(digest.bytes);
      
      return 'GeoAsist-HMAC-SHA256 $signature:$timestamp:$nonce';
    } catch (e) {
      logger.d('$_tag: Failed to sign request: $e');
      throw SecurityException('Request signing failed: $e');
    }
  }
  
  /// Generate cryptographically secure nonce
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
  
  /// Build signature string for HMAC
  static String _buildSignatureString({
    required String method,
    required String url,
    required Map<String, String> headers,
    String? body,
    required String timestamp,
    required String nonce,
  }) {
    final buffer = StringBuffer();
    
    // HTTP method
    buffer.write(method.toUpperCase());
    buffer.write('\n');
    
    // URL
    buffer.write(url);
    buffer.write('\n');
    
    // Sorted headers
    final sortedHeaders = headers.keys.toList()..sort();
    for (final key in sortedHeaders) {
      buffer.write('$key:${headers[key]}\n');
    }
    
    // Body hash (if present)
    if (body != null && body.isNotEmpty) {
      final bodyHash = sha256.convert(utf8.encode(body));
      buffer.write(base64Encode(bodyHash.bytes));
      buffer.write('\n');
    }
    
    // Timestamp and nonce
    buffer.write(timestamp);
    buffer.write('\n');
    buffer.write(nonce);
    
    return buffer.toString();
  }
  
  /// Get security configuration status
  static Future<SecurityStatus> getSecurityConfiguration() async {
    try {
      final hasStoredToken = await _secureStorage.read(key: 'auth_token') != null;
      final hasStoredRefreshToken = await _secureStorage.read(key: 'refresh_token') != null;
      
      return SecurityStatus(
        isEncryptionInitialized: _encrypter != null,
        isSigningInitialized: _signingKey != null,
        hasStoredToken: hasStoredToken,
        hasStoredRefreshToken: hasStoredRefreshToken,
        isAuthenticated: hasStoredToken,
      );
    } catch (e) {
      logger.d('$_tag: Failed to get security configuration: $e');
      return SecurityStatus(
        isEncryptionInitialized: false,
        isSigningInitialized: false,
        hasStoredToken: false,
        hasStoredRefreshToken: false,
        isAuthenticated: false,
      );
    }
  }

  /// Get authentication token (alias for getAuthToken)
  static Future<String?> getToken() async {
    return await getAuthToken();
  }

  /// Clear all authentication tokens (alias for clearAuthTokens)
  static Future<void> clearTokens() async {
    await clearAuthTokens();
  }

  /// Validate response signature
  static bool validateResponseSignature(dynamic responseData, String signature) {
    try {
      if (_signingKey == null) {
        logger.d('$_tag: Cannot validate response signature - signing not initialized');
        return false;
      }
      
      // Convert response data to string for signature validation
      final dataString = responseData != null ? json.encode(responseData) : '';
      
      // Extract signature components
      final parts = signature.split(':');
      if (parts.length < 2) {
        logger.d('$_tag: Invalid signature format');
        return false;
      }
      
      final signatureValue = parts[0];
      final timestamp = parts[1];
      
      // Build string to verify (simplified version)
      final stringToVerify = '$dataString:$timestamp';
      
      // Verify HMAC signature
      final key = _signingKey!.bytes;
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(utf8.encode(stringToVerify));
      final expectedSignature = base64Encode(digest.bytes);
      
      final isValid = signatureValue == expectedSignature;
      logger.d('$_tag: Response signature validation: ${isValid ? "PASS" : "FAIL"}');
      
      return isValid;
    } catch (e) {
      logger.d('$_tag: Response signature validation error: $e');
      return false;
    }
  }
}

/// Security status information
class SecurityStatus {
  final bool isEncryptionInitialized;
  final bool isSigningInitialized;
  final bool hasStoredToken;
  final bool hasStoredRefreshToken;
  final bool isAuthenticated;
  
  SecurityStatus({
    required this.isEncryptionInitialized,
    required this.isSigningInitialized,
    required this.hasStoredToken,
    required this.hasStoredRefreshToken,
    required this.isAuthenticated,
  });
  
  bool get isFullyConfigured => 
      isEncryptionInitialized && 
      isSigningInitialized && 
      hasStoredToken;
}

/// Security exception class
class SecurityException implements Exception {
  final String message;
  
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}