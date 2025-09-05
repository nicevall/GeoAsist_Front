// lib/services/firebase/firebase_auth_service_v2.dart
// Updated Firebase Auth Service - Direct Firebase Integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:geo_asist_front/services/firebase/firebase_cloud_service.dart';

class FirebaseAuthServiceV2 {
  static final FirebaseAuthServiceV2 _instance = FirebaseAuthServiceV2._internal();
  factory FirebaseAuthServiceV2() => _instance;
  FirebaseAuthServiceV2._internal();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Initialize the auth service
  Future<void> initialize() async {
    try {
      logger.i('🔐 Initializing Firebase Auth Service V2');
      
      // Set up auth state listener
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      // Register FCM token if user is already logged in
      if (isAuthenticated) {
        await _registerFCMToken();
        await _syncUserLastLogin();
      }
      
      _isInitialized = true;
      logger.i('✅ Firebase Auth Service V2 initialized successfully');
    } catch (e) {
      logger.e('❌ Failed to initialize Firebase Auth Service V2', e);
      _isInitialized = false;
    }
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      logger.i('👤 User signed in: ${user.email}');
      await _registerFCMToken();
      await _syncUserLastLogin();
      await _syncUserData(user);
    } else {
      logger.i('👤 User signed out');
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      logger.i('🔐 Signing in user: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await _syncUserData(credential.user!);
        await _registerFCMToken();
        logger.i('✅ User signed in successfully');
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      logger.e('❌ Sign in failed: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      logger.e('❌ Unexpected sign in error', e);
      return null;
    }
  }

  /// Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
    Map<String, dynamic>? additionalUserData,
  }) async {
    try {
      logger.i('👤 Creating new user: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }
        
        // Create user document with additional data
        await _createUserDocument(credential.user!, additionalUserData);
        
        // Send email verification
        await credential.user!.sendEmailVerification();
        
        await _registerFCMToken();
        logger.i('✅ User created successfully');
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      logger.e('❌ User creation failed: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      logger.e('❌ Unexpected user creation error', e);
      return null;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      logger.i('🚪 Signing out user');
      
      // Remove FCM token from user document
      if (currentUserId != null) {
        await _removeFCMToken();
      }
      
      await _auth.signOut();
      logger.i('✅ User signed out successfully');
    } catch (e) {
      logger.e('❌ Sign out failed', e);
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      logger.i('📧 Sending password reset email to: $email');
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      logger.i('✅ Password reset email sent successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      logger.e('❌ Password reset failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      logger.e('❌ Unexpected password reset error', e);
      return false;
    }
  }

  /// Update user password
  Future<bool> updatePassword(String newPassword) async {
    try {
      if (!isAuthenticated) {
        logger.w('⚠️ No user authenticated for password update');
        return false;
      }
      
      logger.i('🔐 Updating user password');
      
      await _auth.currentUser!.updatePassword(newPassword);
      
      logger.i('✅ Password updated successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      logger.e('❌ Password update failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      logger.e('❌ Unexpected password update error', e);
      return false;
    }
  }

  /// Update user email
  Future<bool> updateEmail(String newEmail) async {
    try {
      if (!isAuthenticated) {
        logger.w('⚠️ No user authenticated for email update');
        return false;
      }
      
      logger.i('📧 Updating user email to: $newEmail');
      
      await _auth.currentUser!.updateEmail(newEmail.trim());
      
      // Update user document
      await _firestore
          .collection('usuarios')
          .doc(currentUserId!)
          .update({
            'email': newEmail.trim(),
            'emailVerified': false,
            'fechaModificacion': FieldValue.serverTimestamp(),
          });
      
      // Send verification email for new address
      await _auth.currentUser!.sendEmailVerification();
      
      logger.i('✅ Email updated successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      logger.e('❌ Email update failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      logger.e('❌ Unexpected email update error', e);
      return false;
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      if (!isAuthenticated) {
        logger.w('⚠️ No user authenticated for email verification');
        return false;
      }
      
      logger.i('📧 Sending email verification');
      
      await _auth.currentUser!.sendEmailVerification();
      
      logger.i('✅ Email verification sent successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to send email verification', e);
      return false;
    }
  }

  /// Reload current user data
  Future<void> reloadUser() async {
    try {
      if (!isAuthenticated) return;
      
      logger.i('🔄 Reloading user data');
      
      await _auth.currentUser!.reload();
      
      // Update user document with latest data
      await _syncUserData(_auth.currentUser!);
      
      logger.i('✅ User data reloaded');
    } catch (e) {
      logger.e('❌ Failed to reload user data', e);
    }
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      userId ??= currentUserId;
      if (userId == null) {
        logger.w('⚠️ No user ID provided for profile fetch');
        return null;
      }
      
      logger.i('👤 Fetching user profile: $userId');
      
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        logger.i('✅ User profile fetched successfully');
        return userDoc.data();
      } else {
        logger.w('⚠️ User profile not found');
        return null;
      }
    } catch (e) {
      logger.e('❌ Failed to fetch user profile', e);
      return null;
    }
  }

  /// Update user profile in Firestore
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (!isAuthenticated) {
        logger.w('⚠️ No user authenticated for profile update');
        return false;
      }
      
      logger.i('👤 Updating user profile');
      
      profileData['fechaModificacion'] = FieldValue.serverTimestamp();
      
      await FirebaseCloudService.updateUserProfile(
        userData: profileData,
        userId: currentUserId,
      );
      
      logger.i('✅ User profile updated successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to update user profile', e);
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      if (!isAuthenticated) {
        logger.w('⚠️ No user authenticated for account deletion');
        return false;
      }
      
      logger.i('🗑️ Deleting user account');
      
      final userId = currentUserId!;
      
      // Mark user as deleted in Firestore (cleanup will be handled by Cloud Function)
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .update({
            'estado': 'eliminado',
            'fechaEliminacion': FieldValue.serverTimestamp(),
          });
      
      // Delete Firebase Auth user
      await _auth.currentUser!.delete();
      
      logger.i('✅ User account deleted successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      logger.e('❌ Account deletion failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      logger.e('❌ Unexpected account deletion error', e);
      return false;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, Map<String, dynamic>? additionalData) async {
    try {
      logger.i('📄 Creating user document in Firestore');
      
      final userRecord = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'Usuario',
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'role': 'student', // Default role
        'estado': 'activo',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'ultimoLogin': FieldValue.serverTimestamp(),
        'configuraciones': {
          'notificacionesEnabled': true,
          'ubicacionEnabled': false,
          'temaOscuro': false,
        },
        'estadisticas': {
          'eventosAsistidos': 0,
          'horasAcumuladas': 0,
          'racha': 0,
        },
        'fcmTokens': [],
        'metadata': {
          'createdBy': 'flutter_app',
          'version': '2.0.0',
        },
        ...?additionalData,
      };
      
      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .set(userRecord);
      
      logger.i('✅ User document created successfully');
    } catch (e) {
      logger.e('❌ Failed to create user document', e);
    }
  }

  /// Sync user data to Firestore
  Future<void> _syncUserData(User user) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'emailVerified': user.emailVerified,
            'ultimoLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      logger.d('📄 User data synced to Firestore');
    } catch (e) {
      logger.e('❌ Failed to sync user data', e);
    }
  }

  /// Update last login timestamp
  Future<void> _syncUserLastLogin() async {
    try {
      if (currentUserId == null) return;
      
      await _firestore
          .collection('usuarios')
          .doc(currentUserId!)
          .update({
            'ultimoLogin': FieldValue.serverTimestamp(),
          });
      
      logger.d('⏰ Last login timestamp updated');
    } catch (e) {
      logger.e('❌ Failed to update last login', e);
    }
  }

  /// Register FCM token
  Future<void> _registerFCMToken() async {
    try {
      if (currentUserId == null) return;
      
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseCloudService.registerFCMToken(token);
        logger.d('📱 FCM token registered');
      }
    } catch (e) {
      logger.e('❌ Failed to register FCM token', e);
    }
  }

  /// Remove FCM token
  Future<void> _removeFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && currentUserId != null) {
        await _firestore
            .collection('usuarios')
            .doc(currentUserId!)
            .update({
              'fcmTokens': FieldValue.arrayRemove([token]),
            });
        
        logger.d('📱 FCM token removed');
      }
    } catch (e) {
      logger.e('❌ Failed to remove FCM token', e);
    }
  }

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get user document stream
  Stream<Map<String, dynamic>?> get userProfileStream {
    if (!isAuthenticated) {
      return Stream.value(null);
    }
    
    return _firestore
        .collection('usuarios')
        .doc(currentUserId!)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data();
          }
          return null;
        });
  }

  /// Check if user has specific role
  Future<bool> hasRole(String role) async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return false;
      
      final userRole = profile['role'] ?? 'student';
      return userRole == role;
    } catch (e) {
      logger.e('❌ Failed to check user role', e);
      return false;
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin() async => await hasRole('admin');

  /// Check if user is teacher
  Future<bool> isTeacher() async => await hasRole('teacher');

  /// Cleanup service
  void dispose() {
    logger.i('🧹 Disposing Firebase Auth Service V2');
    _isInitialized = false;
  }
}