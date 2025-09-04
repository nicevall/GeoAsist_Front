// lib/services/pre_registration_notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../services/storage_service.dart';
import '../services/notifications/notification_manager.dart';
import '../utils/app_router.dart';

/// Servicio especializado para manejar pre-registros y notificaciones automáticas
class PreRegistrationNotificationService {
  static final PreRegistrationNotificationService _instance = 
      PreRegistrationNotificationService._internal();
  factory PreRegistrationNotificationService() => _instance;
  PreRegistrationNotificationService._internal();

  final StorageService _storageService = StorageService();
  final NotificationManager _notificationManager = NotificationManager();
  
  Timer? _checkTimer;
  List<PreRegistrationItem> _preRegistrations = [];
  bool _isInitialized = false;

  // IDs específicos para notificaciones de pre-registro
  static const int _preRegistrationBaseId = 2000;

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('📝 Inicializando PreRegistrationNotificationService');
      
      // Cargar pre-registros existentes
      await _loadPreRegistrations();
      
      // Iniciar verificación periódica cada minuto
      _startPeriodicCheck();
      
      _isInitialized = true;
      debugPrint('✅ PreRegistrationNotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando PreRegistrationNotificationService: $e');
    }
  }

  /// Agregar un nuevo pre-registro
  Future<void> addPreRegistration(Evento evento, Usuario usuario) async {
    try {
      debugPrint('📝 Agregando pre-registro: ${evento.titulo} para ${usuario.nombre}');

      final preRegItem = PreRegistrationItem(
        eventId: evento.id!,
        eventTitle: evento.titulo,
        eventStartTime: evento.fecha.copyWith(
          hour: evento.horaInicio.hour,
          minute: evento.horaInicio.minute,
        ),
        userId: usuario.id,
        userName: usuario.nombre,
        createdAt: DateTime.now(),
        isNotified: false,
      );

      _preRegistrations.add(preRegItem);
      await _savePreRegistrations();

      debugPrint('✅ Pre-registro agregado exitosamente');
    } catch (e) {
      debugPrint('❌ Error agregando pre-registro: $e');
      throw Exception('Error agregando pre-registro: $e');
    }
  }

  /// Remover un pre-registro
  Future<void> removePreRegistration(String eventId) async {
    try {
      _preRegistrations.removeWhere((item) => item.eventId == eventId);
      await _savePreRegistrations();
      debugPrint('✅ Pre-registro removido: $eventId');
    } catch (e) {
      debugPrint('❌ Error removiendo pre-registro: $e');
    }
  }

  /// Obtener todos los pre-registros del usuario actual
  Future<List<PreRegistrationItem>> getPreRegistrations() async {
    final currentUser = await _storageService.getUser();
    if (currentUser == null) return [];

    return _preRegistrations
        .where((item) => item.userId == currentUser.id)
        .toList();
  }

  /// Verificar si un evento está pre-registrado
  Future<bool> isEventPreRegistered(String eventId) async {
    final currentUser = await _storageService.getUser();
    if (currentUser == null) return false;

    return _preRegistrations.any((item) => 
        item.eventId == eventId && item.userId == currentUser.id);
  }

  /// Verificación periódica de eventos que deben notificarse
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkEventsThatShouldNotify();
    });
    debugPrint('⏱️ Verificación periódica de pre-registros iniciada');
  }

  /// Verificar eventos que deben generar notificación
  Future<void> _checkEventsThatShouldNotify() async {
    try {
      final now = DateTime.now();
      final eventsToNotify = <PreRegistrationItem>[];

      for (final preReg in _preRegistrations) {
        if (preReg.isNotified) continue;

        // Notificar 5 minutos antes del evento
        final notifyTime = preReg.eventStartTime.subtract(const Duration(minutes: 5));
        
        if (now.isAfter(notifyTime)) {
          eventsToNotify.add(preReg);
        }
      }

      if (eventsToNotify.isNotEmpty) {
        debugPrint('📢 ${eventsToNotify.length} eventos requieren notificación');
        for (final event in eventsToNotify) {
          await _sendEventStartNotification(event);
        }
      }
    } catch (e) {
      debugPrint('❌ Error verificando eventos: $e');
    }
  }

  /// Enviar notificación de inicio de evento
  Future<void> _sendEventStartNotification(PreRegistrationItem preReg) async {
    try {
      debugPrint('📢 Enviando notificación para: ${preReg.eventTitle}');

      final notificationId = _preRegistrationBaseId + preReg.eventId.hashCode.abs() % 1000;
      
      // Crear payload con información del evento
      final payload = json.encode({
        'type': 'event_started',
        'eventId': preReg.eventId,
        'eventTitle': preReg.eventTitle,
        'action': 'navigate_to_attendance'
      });

      await _notificationManager.showEventStartNotification(
        id: notificationId,
        title: '🎯 ${preReg.eventTitle}',
        body: '¡El evento está por comenzar! Toca para unirte al tracking de asistencia.',
        payload: payload,
      );

      // Marcar como notificado
      preReg.isNotified = true;
      await _savePreRegistrations();

      debugPrint('✅ Notificación enviada para: ${preReg.eventTitle}');
    } catch (e) {
      debugPrint('❌ Error enviando notificación: $e');
    }
  }

  /// Manejar tap en notificación (llamado desde main.dart)
  static Future<void> handleNotificationTap(String payload) async {
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      if (type == 'event_started') {
        final eventId = data['eventId'] as String;
        final eventTitle = data['eventTitle'] as String;
        
        debugPrint('🎯 Navegando a attendance para evento: $eventTitle');
        
        // Navegar directamente al attendance tracking
        AppRouter.goToAttendanceTracking(
          eventoId: eventId,
        );
      }
    } catch (e) {
      debugPrint('❌ Error manejando tap de notificación: $e');
    }
  }

  /// Cargar pre-registros desde storage
  Future<void> _loadPreRegistrations() async {
    try {
      const key = 'pre_registrations_v2';
      final data = await _storageService.getData(key);
      
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        _preRegistrations = jsonList
            .map((json) => PreRegistrationItem.fromJson(json))
            .toList();
        
        debugPrint('📋 Cargados ${_preRegistrations.length} pre-registros');
      }
    } catch (e) {
      debugPrint('❌ Error cargando pre-registros: $e');
      _preRegistrations = [];
    }
  }

  /// Guardar pre-registros en storage
  Future<void> _savePreRegistrations() async {
    try {
      const key = 'pre_registrations_v2';
      final jsonList = _preRegistrations.map((item) => item.toJson()).toList();
      await _storageService.saveData(key, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error guardando pre-registros: $e');
    }
  }

  /// Limpiar pre-registros expirados (eventos que ya terminaron)
  Future<void> cleanupExpiredPreRegistrations() async {
    try {
      final now = DateTime.now();
      final originalCount = _preRegistrations.length;
      
      // Remover eventos que terminaron hace más de 1 día
      _preRegistrations.removeWhere((item) {
        final eventEndTime = item.eventStartTime.add(const Duration(hours: 4)); // Asumir 4h duración máxima
        return now.isAfter(eventEndTime.add(const Duration(days: 1)));
      });

      if (_preRegistrations.length != originalCount) {
        await _savePreRegistrations();
        debugPrint('🧹 Limpieza completada: ${originalCount - _preRegistrations.length} pre-registros expirados removidos');
      }
    } catch (e) {
      debugPrint('❌ Error en limpieza: $e');
    }
  }

  /// Detener el servicio
  void dispose() {
    _checkTimer?.cancel();
    _isInitialized = false;
    debugPrint('🔄 PreRegistrationNotificationService detenido');
  }
}

/// Modelo para almacenar información de pre-registro
class PreRegistrationItem {
  final String eventId;
  final String eventTitle;
  final DateTime eventStartTime;
  final String userId;
  final String userName;
  final DateTime createdAt;
  bool isNotified;

  PreRegistrationItem({
    required this.eventId,
    required this.eventTitle,
    required this.eventStartTime,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.isNotified = false,
  });

  factory PreRegistrationItem.fromJson(Map<String, dynamic> json) {
    return PreRegistrationItem(
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String,
      eventStartTime: DateTime.parse(json['eventStartTime'] as String),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isNotified: json['isNotified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventStartTime': eventStartTime.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'isNotified': isNotified,
    };
  }
}