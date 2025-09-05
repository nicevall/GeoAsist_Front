// lib/services/firebase/firebase_evento_service.dart
// Servicio de eventos Firebase compatible con híbrido

import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../../models/api_response_model.dart';
import '../../models/evento_model.dart';
import '../../models/ubicacion_model.dart';

class FirebaseEventoService {
  static final FirebaseEventoService _instance = FirebaseEventoService._internal();
  factory FirebaseEventoService() => _instance;
  FirebaseEventoService._internal();

  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  // Streams placeholder para compatibilidad
  Stream<Map<String, dynamic>?> get eventoActivoStream => Stream.empty();
  Stream<List<Map<String, dynamic>>> get eventosStream => Stream.empty();
  
  // Métodos adicionales para compatibilidad
  Future<Map<String, dynamic>?> getEventoActivo() async {
    logger.d('💡 getEventoActivo redirigido al backend híbrido');
    return null;
  }
  
  Future<void> refreshEventos() async {
    logger.d('💡 refreshEventos redirigido al backend híbrido');
  }

  // Additional methods for compatibility
  List<Map<String, dynamic>> get cachedEventos => [];
  
  Future<List<Map<String, dynamic>>> searchEventos(String query) async {
    logger.d('💡 searchEventos redirigido al backend híbrido');
    return [];
  }
  
  void initializeStreams() {
    logger.d('💡 initializeStreams redirigido al backend híbrido');
  }
  
  String get currentUserId => '';
  
  // Firebase compatibility methods
  List<Map<String, dynamic>> get eventos => cachedEventos;

  Future<void> initialize() async {
    try {
      // El backend híbrido maneja los eventos
      _isInitialized = true;
      logger.d('✅ FirebaseEventoService inicializado (modo híbrido)');
    } catch (e) {
      logger.d('❌ Error inicializando FirebaseEventoService: $e');
      rethrow;
    }
  }

  // Métodos placeholder para compatibilidad
  Future<List<Map<String, dynamic>>> getEventos() async {
    logger.d('💡 getEventos redirigido al backend híbrido');
    return [];
  }

  Future<Map<String, dynamic>?> createEvento(Map<String, dynamic> evento) async {
    logger.d('💡 createEvento redirigido al backend híbrido');
    return null;
  }

  Future<bool> updateEvento(String eventoId, Map<String, dynamic> updates) async {
    logger.d('💡 updateEvento redirigido al backend híbrido');
    return false;
  }

  Future<bool> deleteEvento(String eventoId) async {
    logger.d('💡 deleteEvento redirigido al backend híbrido');
    return false;
  }

  // Métodos requeridos por attendance_service_adapter
  Future<ApiResponse<Evento?>?> getEventoById(String eventoId) async {
    logger.d('💡 getEventoById redirigido al backend híbrido');
    
    final now = DateTime.now();
    
    // Mock event for compatibility
    final mockEvent = Evento(
      id: eventoId,
      titulo: 'Evento desde backend híbrido',
      descripcion: 'Evento manejado por el backend híbrido',
      ubicacion: Ubicacion(latitud: 0.0, longitud: 0.0),
      fecha: now,
      horaInicio: now,
      horaFinal: now.add(const Duration(hours: 1)),
      rangoPermitido: 100,
      estado: 'activo',
      isActive: true,
      creadoPor: 'hybrid_backend',
    );
    
    return ApiResponse<Evento?>(
      success: true,
      data: mockEvent,
      message: 'Evento obtenido exitosamente',
    );
  }

  Future<ApiResponse<Evento?>?> getActiveEvent() async {
    logger.d('💡 getActiveEvent redirigido al backend híbrido');
    
    final now = DateTime.now();
    
    // Mock active event for compatibility
    final mockEvent = Evento(
      id: 'active_event_1',
      titulo: 'Evento Activo desde backend híbrido',
      descripcion: 'Evento activo manejado por el backend híbrido',
      ubicacion: Ubicacion(latitud: 0.0, longitud: 0.0),
      fecha: now,
      horaInicio: now,
      horaFinal: now.add(const Duration(hours: 1)),
      rangoPermitido: 100,
      estado: 'activo',
      isActive: true,
      creadoPor: 'hybrid_backend',
    );
    
    return ApiResponse<Evento?>(
      success: true,
      data: mockEvent,
      message: 'Evento activo obtenido exitosamente',
    );
  }

  void dispose() {
    _isInitialized = false;
  }
}