// lib/services/firebase/firebase_cloud_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:geo_asist_front/models/evento.dart';
import 'package:geo_asist_front/models/asistencia.dart';

/// Firebase Cloud Service - Direct Firebase Integration
/// Replaces HybridBackendService with native Firebase calls
class FirebaseCloudService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Firebase Functions region (optional)
  static void configureRegion([String region = 'us-central1']) {
    _functions.useFunctionsEmulator('localhost', 5001);
    logger.i('🔥 Firebase Functions configured for region: $region');
  }

  /// Health check using Cloud Function
  /// Replaces: GET /api/firestore/health
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      logger.i('🏥 Checking system health via Cloud Function');
      
      final callable = _functions.httpsCallable('healthCheck');
      final result = await callable.call();
      
      final healthData = Map<String, dynamic>.from(result.data ?? {});
      logger.i('✅ Health check successful: ${healthData['system']}');
      
      return healthData;
    } catch (e) {
      logger.e('❌ Health check failed', e);
      return {
        'success': false,
        'system': 'firebase_cloud_functions',
        'error': 'Health check failed: $e',
        'timestamp': DateTime.now().toIso8601String()
      };
    }
  }

  /// Send notification using Cloud Function
  /// Replaces: POST /api/firestore/send-notification
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? userId,
    String? eventId,
    String type = 'general',
    List<String>? tokens,
  }) async {
    try {
      logger.i('📤 Sending notification via Cloud Function');
      
      final callable = _functions.httpsCallable('sendNotification');
      final result = await callable.call({
        'title': title,
        'body': body,
        'userId': userId,
        'eventId': eventId,
        'type': type,
        'tokens': tokens,
      });
      
      final success = result.data['success'] ?? false;
      logger.i('📬 Notification sent: $success');
      
      return success;
    } catch (e) {
      logger.e('❌ Failed to send notification', e);
      return false;
    }
  }

  /// Process attendance using Cloud Function
  /// Replaces: POST /api/firestore/process-attendance
  static Future<Map<String, dynamic>> processAttendance({
    required double latitude,
    required double longitude,
    String? eventId,
    String action = 'checkin',
    double? accuracy,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      logger.i('📍 Processing attendance via Cloud Function');
      
      final callable = _functions.httpsCallable('processAttendance');
      final result = await callable.call({
        'latitude': latitude,
        'longitude': longitude,
        'eventId': eventId,
        'action': action,
        'accuracy': accuracy,
        'deviceInfo': deviceInfo,
      });
      
      final attendanceData = Map<String, dynamic>.from(result.data ?? {});
      logger.i('✅ Attendance processed: ${attendanceData['success']}');
      
      return attendanceData;
    } catch (e) {
      logger.e('❌ Failed to process attendance', e);
      return {
        'success': false,
        'attendanceProcessed': false,
        'error': 'Failed to process attendance: $e'
      };
    }
  }

  /// Get event statistics using Cloud Function
  /// Replaces: GET /api/firestore/event-statistics
  static Future<Map<String, dynamic>> getEventStatistics({
    String? eventId,
    Map<String, dynamic>? dateRange,
    bool detailed = false,
  }) async {
    try {
      logger.i('📊 Fetching event statistics via Cloud Function');
      
      final callable = _functions.httpsCallable('getEventStatistics');
      final result = await callable.call({
        'eventId': eventId,
        'dateRange': dateRange,
        'detailed': detailed,
      });
      
      final statsData = Map<String, dynamic>.from(result.data ?? {});
      logger.i('📈 Statistics fetched successfully');
      
      return statsData;
    } catch (e) {
      logger.e('❌ Failed to fetch statistics', e);
      return {
        'success': false,
        'error': 'Failed to fetch statistics: $e'
      };
    }
  }

  /// Get eventos directly from Firestore
  /// Replaces: GET /api/firestore/eventos
  static Future<List<Evento>> getEventos() async {
    try {
      logger.i('🎯 Fetching events from Firestore');
      
      final snapshot = await _firestore
          .collection('eventos')
          .orderBy('fechaInicio', descending: true)
          .get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromFirestore(doc))
          .toList();
      
      logger.i('✅ Fetched ${eventos.length} events from Firestore');
      return eventos;
    } catch (e) {
      logger.e('❌ Failed to fetch events', e);
      return [];
    }
  }

  /// Get active eventos directly from Firestore
  /// Replaces: GET /api/firestore/eventos?status=active
  static Future<List<Evento>> getActiveEventos() async {
    try {
      logger.i('🎯 Fetching active events from Firestore');
      
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('eventos')
          .where('estado', isEqualTo: 'activo')
          .where('fechaInicio', isLessThanOrEqualTo: now)
          .where('fechaFin', isGreaterThanOrEqualTo: now)
          .get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromFirestore(doc))
          .toList();
      
      logger.i('✅ Fetched ${eventos.length} active events');
      return eventos;
    } catch (e) {
      logger.e('❌ Failed to fetch active events', e);
      return [];
    }
  }

  /// Get user attendance records directly from Firestore
  /// Replaces: GET /api/firestore/user-attendance
  static Future<List<Asistencia>> getUserAttendance({
    String? userId,
    String? eventId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      userId ??= _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      logger.i('📋 Fetching user attendance from Firestore');
      
      Query query = _firestore
          .collection('asistencias')
          .where('usuarioId', isEqualTo: userId);

      if (eventId != null) {
        query = query.where('eventoId', isEqualTo: eventId);
      }

      if (startDate != null) {
        query = query.where('fecha', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('fecha', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query
          .orderBy('fecha', descending: true)
          .get();

      final asistencias = snapshot.docs
          .map((doc) => Asistencia.fromFirestore(doc))
          .toList();

      logger.i('✅ Fetched ${asistencias.length} attendance records');
      return asistencias;
    } catch (e) {
      logger.e('❌ Failed to fetch attendance records', e);
      return [];
    }
  }

  /// Create or update user profile directly in Firestore
  /// Replaces: POST /api/firestore/user-profile
  static Future<bool> updateUserProfile({
    required Map<String, dynamic> userData,
    String? userId,
  }) async {
    try {
      userId ??= _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      logger.i('👤 Updating user profile in Firestore');
      
      userData['ultimoLogin'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .set(userData, SetOptions(merge: true));

      logger.i('✅ User profile updated successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to update user profile', e);
      return false;
    }
  }

  /// Stream eventos in real-time
  /// Replaces WebSocket connection for eventos
  static Stream<List<Evento>> streamEventos() {
    logger.i('🔄 Starting real-time eventos stream');
    
    return _firestore
        .collection('eventos')
        .orderBy('fechaInicio', descending: true)
        .snapshots()
        .map((snapshot) {
          final eventos = snapshot.docs
              .map((doc) => Evento.fromFirestore(doc))
              .toList();
          
          logger.i('🔄 Received ${eventos.length} events from stream');
          return eventos;
        });
  }

  /// Stream user notifications in real-time
  /// Replaces: WebSocket notifications
  static Stream<List<Map<String, dynamic>>> streamNotifications({
    String? userId,
  }) {
    userId ??= _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.empty();
    }

    logger.i('🔔 Starting real-time notifications stream');
    
    return _firestore
        .collection('notificaciones')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
              .toList();
          
          logger.i('🔔 Received ${notifications.length} notifications');
          return notifications;
        });
  }

  /// Register FCM token for push notifications
  /// Replaces: POST /api/firestore/register-token
  static Future<bool> registerFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      logger.i('📱 Registering FCM token');
      
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .update({
            'fcmTokens': FieldValue.arrayUnion([token]),
            'ultimoTokenUpdate': FieldValue.serverTimestamp(),
          });

      logger.i('✅ FCM token registered successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to register FCM token', e);
      return false;
    }
  }

  /// Test connectivity to Firebase services
  static Future<Map<String, bool>> testConnectivity() async {
    final results = <String, bool>{};

    // Test Firestore
    try {
      await _firestore.collection('system').doc('test').get();
      results['firestore'] = true;
    } catch (e) {
      results['firestore'] = false;
    }

    // Test Functions
    try {
      await checkHealth();
      results['functions'] = true;
    } catch (e) {
      results['functions'] = false;
    }

    // Test Auth
    try {
      final user = _auth.currentUser;
      results['auth'] = user != null;
    } catch (e) {
      results['auth'] = false;
    }

    logger.i('🔍 Connectivity test results: $results');
    return results;
  }
}