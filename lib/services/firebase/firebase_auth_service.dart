// lib/services/firebase/firebase_auth_service.dart
// Servicio de autenticación Firebase compatible con híbrido

import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      logger.d('❌ Error en signIn: $e');
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      logger.d('❌ Error en createUser: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      logger.d('❌ Error en signOut: $e');
      rethrow;
    }
  }

  // Alias for compatibility
  Future<void> logout() async {
    await signOut();
  }

  // Additional getters for compatibility
  bool get isLoggedIn => isAuthenticated;
  String get currentUserId => currentUser?.uid ?? '';
  
  // Alias for compatibility
  Future<UserCredential?> loginWithEmailAndPassword(String email, String password) async {
    return await signInWithEmailAndPassword(email, password);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      logger.d('❌ Error en resetPassword: $e');
      rethrow;
    }
  }

  void dispose() {
    // Firebase Auth se maneja automáticamente
  }
}