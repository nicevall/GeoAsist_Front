// lib/services/certificate_pinning.dart
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Certificate pinning implementation using HttpOverrides
class CertificatePinningOverrides extends HttpOverrides {
  final Set<String> allowedCertificateHashes;
  
  CertificatePinningOverrides(this.allowedCertificateHashes);
  
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Get certificate hash (SHA-256)
        final certBytes = cert.der;
        final certHash = sha256.convert(certBytes).toString();
        
        debugPrint('SecureApiClient: Validating certificate for $host:$port');
        debugPrint('SecureApiClient: Certificate SHA-256: $certHash');
        
        // Check if certificate hash is in allowed list
        final isAllowed = allowedCertificateHashes.contains(certHash);
        
        if (!isAllowed) {
          debugPrint('SecureApiClient: Certificate validation failed - hash not in allowed list');
          debugPrint('SecureApiClient: Allowed hashes: ${allowedCertificateHashes.join(', ')}');
        } else {
          debugPrint('SecureApiClient: Certificate validation passed');
        }
        
        return isAllowed;
      };
  }
}