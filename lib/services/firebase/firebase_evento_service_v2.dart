// lib/services/firebase/firebase_evento_service_v2.dart
// Updated Firebase Evento Service - Direct Firebase Integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:geo_asist_front/models/evento.dart';
import 'package:geo_asist_front/services/firebase/firebase_cloud_service.dart';

class FirebaseEventoServiceV2 {
  static final FirebaseEventoServiceV2 _instance = FirebaseEventoServiceV2._internal();
  factory FirebaseEventoServiceV2() => _instance;
  FirebaseEventoServiceV2._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  List<Evento> _cachedEventos = [];

  bool get isInitialized => _isInitialized;
  List<Evento> get cachedEventos => List.unmodifiable(_cachedEventos);
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Initialize the service
  Future<void> initialize() async {
    try {
      logger.i('🔥 Initializing Firebase Evento Service V2');
      
      // Test Firebase connectivity
      await FirebaseCloudService.testConnectivity();
      
      // Load initial eventos
      await refreshEventos();
      
      _isInitialized = true;
      logger.i('✅ Firebase Evento Service V2 initialized successfully');
    } catch (e) {
      logger.e('❌ Failed to initialize Firebase Evento Service V2', e);
      _isInitialized = false;
    }
  }

  /// Get all eventos from Firestore
  Future<List<Evento>> getEventos() async {
    try {
      logger.i('🎯 Fetching all eventos from Firestore');
      
      final snapshot = await _firestore
          .collection('eventos')
          .orderBy('fechaInicio', descending: true)
          .get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromFirestore(doc))
          .toList();
      
      _cachedEventos = eventos;
      logger.i('✅ Fetched ${eventos.length} eventos');
      
      return eventos;
    } catch (e) {
      logger.e('❌ Failed to fetch eventos', e);
      return _cachedEventos;
    }
  }

  /// Get active evento (current running event)
  Future<Evento?> getEventoActivo() async {
    try {
      logger.i('🎯 Fetching active evento from Firestore');
      
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('eventos')
          .where('estado', isEqualTo: 'activo')
          .where('fechaInicio', isLessThanOrEqualTo: now)
          .where('fechaFin', isGreaterThanOrEqualTo: now)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final evento = Evento.fromFirestore(snapshot.docs.first);
        logger.i('✅ Found active evento: ${evento.nombre}');
        return evento;
      }
      
      logger.i('ℹ️ No active evento found');
      return null;
    } catch (e) {
      logger.e('❌ Failed to fetch active evento', e);
      return null;
    }
  }

  /// Get eventos by status
  Future<List<Evento>> getEventosByStatus(String status) async {
    try {
      logger.i('🎯 Fetching eventos with status: $status');
      
      final snapshot = await _firestore
          .collection('eventos')
          .where('estado', isEqualTo: status)
          .orderBy('fechaInicio', descending: true)
          .get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromFirestore(doc))
          .toList();
      
      logger.i('✅ Found ${eventos.length} eventos with status: $status');
      return eventos;
    } catch (e) {
      logger.e('❌ Failed to fetch eventos by status', e);
      return [];
    }
  }

  /// Search eventos by query
  Future<List<Evento>> searchEventos(String query) async {
    try {
      logger.i('🔍 Searching eventos with query: $query');
      
      // Firebase doesn't support full-text search natively
      // Using basic string containment for now
      final allEventos = await getEventos();
      
      final filteredEventos = allEventos.where((evento) {
        final searchText = query.toLowerCase();
        return evento.nombre.toLowerCase().contains(searchText) ||
               evento.descripcion.toLowerCase().contains(searchText) ||
               evento.ubicacion.direccion.toLowerCase().contains(searchText);
      }).toList();
      
      logger.i('🔍 Found ${filteredEventos.length} eventos matching query');
      return filteredEventos;
    } catch (e) {
      logger.e('❌ Failed to search eventos', e);
      return [];
    }
  }

  /// Create new evento
  Future<bool> createEvento(Evento evento) async {
    try {
      logger.i('➕ Creating new evento: ${evento.nombre}');
      
      final eventData = evento.toFirestore();
      eventData['fechaCreacion'] = FieldValue.serverTimestamp();
      eventData['creadoPor'] = currentUserId;
      
      await _firestore.collection('eventos').add(eventData);
      
      // Refresh cache
      await refreshEventos();
      
      logger.i('✅ Evento created successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to create evento', e);
      return false;
    }
  }

  /// Update existing evento
  Future<bool> updateEvento(String eventoId, Map<String, dynamic> updates) async {
    try {
      logger.i('📝 Updating evento: $eventoId');
      
      updates['fechaModificacion'] = FieldValue.serverTimestamp();
      updates['modificadoPor'] = currentUserId;
      
      await _firestore
          .collection('eventos')
          .doc(eventoId)
          .update(updates);
      
      // Refresh cache
      await refreshEventos();
      
      logger.i('✅ Evento updated successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to update evento', e);
      return false;
    }
  }

  /// Delete evento (soft delete - change status)
  Future<bool> deleteEvento(String eventoId) async {
    try {
      logger.i('🗑️ Deleting evento: $eventoId');
      
      await _firestore
          .collection('eventos')
          .doc(eventoId)
          .update({
            'estado': 'eliminado',
            'fechaEliminacion': FieldValue.serverTimestamp(),
            'eliminadoPor': currentUserId,
          });
      
      // Refresh cache
      await refreshEventos();
      
      logger.i('✅ Evento deleted successfully');
      return true;
    } catch (e) {
      logger.e('❌ Failed to delete evento', e);
      return false;
    }
  }

  /// Get evento statistics using Cloud Function
  Future<Map<String, dynamic>?> getEventoStatistics(String eventoId) async {
    try {
      logger.i('📊 Fetching statistics for evento: $eventoId');
      
      return await FirebaseCloudService.getEventStatistics(
        eventId: eventoId,
        detailed: true,
      );
    } catch (e) {
      logger.e('❌ Failed to fetch evento statistics', e);
      return null;
    }
  }

  /// Refresh cached eventos
  Future<void> refreshEventos() async {
    try {
      logger.i('🔄 Refreshing eventos cache');
      await getEventos();
      logger.i('✅ Eventos cache refreshed');
    } catch (e) {
      logger.e('❌ Failed to refresh eventos', e);
    }
  }

  /// Stream eventos in real-time
  Stream<List<Evento>> get eventosStream {
    logger.i('🔄 Starting real-time eventos stream');
    
    return _firestore
        .collection('eventos')
        .where('estado', whereIn: ['activo', 'programado', 'completado'])
        .orderBy('fechaInicio', descending: true)
        .snapshots()
        .map((snapshot) {
          final eventos = snapshot.docs
              .map((doc) => Evento.fromFirestore(doc))
              .toList();
          
          // Update cache
          _cachedEventos = eventos;
          
          logger.i('🔄 Received ${eventos.length} eventos from stream');
          return eventos;
        });
  }

  /// Stream active evento in real-time
  Stream<Evento?> get eventoActivoStream {
    logger.i('🔄 Starting active evento stream');
    
    final now = DateTime.now();
    
    return _firestore
        .collection('eventos')
        .where('estado', isEqualTo: 'activo')
        .where('fechaInicio', isLessThanOrEqualTo: now)
        .where('fechaFin', isGreaterThanOrEqualTo: now)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final evento = Evento.fromFirestore(snapshot.docs.first);
            logger.i('🔄 Active evento: ${evento.nombre}');
            return evento;
          }
          
          logger.i('🔄 No active evento');
          return null;
        });
  }

  /// Get eventos for today
  Future<List<Evento>> getEventosHoy() async {
    try {
      logger.i('📅 Fetching eventos for today');
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('eventos')
          .where('fechaInicio', isGreaterThanOrEqualTo: startOfDay)
          .where('fechaInicio', isLessThanOrEqualTo: endOfDay)
          .orderBy('fechaInicio')
          .get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromFirestore(doc))
          .toList();
      
      logger.i('📅 Found ${eventos.length} eventos for today');
      return eventos;
    } catch (e) {
      logger.e('❌ Failed to fetch eventos for today', e);
      return [];
    }
  }

  /// Check if user can access evento (based on permissions)
  Future<bool> canUserAccessEvento(String eventoId, String? userId) async {
    try {
      userId ??= currentUserId;
      if (userId.isEmpty) return false;
      
      // Get user role from Firestore
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      final userRole = userData['role'] ?? 'student';
      
      // Admins and teachers can access all eventos
      if (userRole == 'admin' || userRole == 'teacher') {
        return true;
      }
      
      // Students can access public eventos or eventos they're enrolled in
      final eventoDoc = await _firestore
          .collection('eventos')
          .doc(eventoId)
          .get();
      
      if (!eventoDoc.exists) return false;
      
      final eventoData = eventoDoc.data()!;
      final isPublic = eventoData['publico'] ?? true;
      final enrolledUsers = List<String>.from(eventoData['usuariosInscritos'] ?? []);
      
      return isPublic || enrolledUsers.contains(userId);
    } catch (e) {
      logger.e('❌ Failed to check user access', e);
      return false;
    }
  }

  /// Cleanup service
  void dispose() {
    logger.i('🧹 Disposing Firebase Evento Service V2');
    _cachedEventos.clear();
    _isInitialized = false;
  }
}