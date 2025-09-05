import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/session_persistence_service.dart
import 'dart:convert';
import 'dart:async';
import '../models/evento_model.dart';
import '../models/usuario_model.dart';
import '../models/attendance_state_model.dart';
import 'storage_service.dart';
import 'notifications/notification_manager.dart';

/// Servicio especializado para mantener la persistencia de sesiones activas de asistencia
/// Permite que el usuario pueda minimizar la app y seguir manteniendo su estado de asistencia
class SessionPersistenceService {
  static final SessionPersistenceService _instance = SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal();

  final StorageService _storageService = StorageService();
  final NotificationManager _notificationManager = NotificationManager();
  
  Timer? _persistenceTimer;
  bool _isInitialized = false;
  
  static const String _activeSessionKey = 'active_attendance_session_v2';
  static const String _sessionStateKey = 'session_attendance_state_v2';
  
  /// Inicializar el servicio de persistencia
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      logger.d('💾 Inicializando SessionPersistenceService');
      
      // Verificar si hay una sesión activa al iniciar la app
      await _checkForActiveSession();
      
      // Iniciar guardado periódico cada 30 segundos
      _startPeriodicSave();
      
      _isInitialized = true;
      logger.d('✅ SessionPersistenceService inicializado');
    } catch (e) {
      logger.d('❌ Error inicializando SessionPersistenceService: $e');
    }
  }

  /// Guardar sesión activa cuando el usuario inicia tracking
  Future<void> saveActiveSession({
    required Evento evento,
    required Usuario usuario,
    required AttendanceState state,
  }) async {
    try {
      logger.d('💾 Guardando sesión activa: ${evento.titulo}');
      
      final sessionData = ActiveSessionData(
        eventId: evento.id!,
        eventTitle: evento.titulo,
        eventStartTime: evento.fecha.copyWith(
          hour: evento.horaInicio.hour,
          minute: evento.horaInicio.minute,
        ),
        eventEndTime: evento.fecha.copyWith(
          hour: evento.horaFinal.hour,
          minute: evento.horaFinal.minute,
        ),
        userId: usuario.id,
        userName: usuario.nombre,
        startedAt: DateTime.now(),
        lastUpdate: DateTime.now(),
        isActive: true,
      );
      
      // Guardar datos de sesión
      await _storageService.saveData(_activeSessionKey, json.encode(sessionData.toJson()));
      
      // Guardar estado de asistencia
      await _saveAttendanceState(state);
      
      // Mostrar notificación persistente
      await _showPersistentNotification(sessionData);
      
      logger.d('✅ Sesión activa guardada exitosamente');
    } catch (e) {
      logger.d('❌ Error guardando sesión activa: $e');
    }
  }

  /// Actualizar estado de la sesión activa
  Future<void> updateSessionState(AttendanceState state) async {
    try {
      final sessionData = await getActiveSession();
      if (sessionData != null && sessionData.isActive) {
        // Actualizar timestamp
        final updatedSession = sessionData.copyWith(
          lastUpdate: DateTime.now(),
        );
        
        await _storageService.saveData(_activeSessionKey, json.encode(updatedSession.toJson()));
        await _saveAttendanceState(state);
        
        logger.d('💾 Estado de sesión actualizado');
      }
    } catch (e) {
      logger.d('❌ Error actualizando estado de sesión: $e');
    }
  }

  /// Obtener sesión activa si existe
  Future<ActiveSessionData?> getActiveSession() async {
    try {
      final data = await _storageService.getData(_activeSessionKey);
      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final session = ActiveSessionData.fromJson(json);
        
        // Verificar si la sesión sigue siendo válida (no más de 12 horas)
        final now = DateTime.now();
        final sessionDuration = now.difference(session.startedAt);
        
        if (sessionDuration.inHours > 12 || !session.isActive) {
          await clearActiveSession();
          return null;
        }
        
        return session;
      }
      return null;
    } catch (e) {
      logger.d('❌ Error obteniendo sesión activa: $e');
      return null;
    }
  }

  /// Obtener estado de asistencia guardado
  Future<AttendanceState?> getSavedAttendanceState() async {
    try {
      final data = await _storageService.getData(_sessionStateKey);
      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        return AttendanceState.fromJson(json);
      }
      return null;
    } catch (e) {
      logger.d('❌ Error obteniendo estado de asistencia: $e');
      return null;
    }
  }

  /// Finalizar sesión activa
  Future<void> clearActiveSession() async {
    try {
      await _storageService.removeData(_activeSessionKey);
      await _storageService.removeData(_sessionStateKey);
      
      // Cancelar notificación persistente
      await _notificationManager.cancelNotification(1000);
      
      logger.d('✅ Sesión activa limpiada');
    } catch (e) {
      logger.d('❌ Error limpiando sesión activa: $e');
    }
  }

  /// Verificar al iniciar la app si hay una sesión activa
  Future<ActiveSessionData?> _checkForActiveSession() async {
    try {
      final session = await getActiveSession();
      if (session != null) {
        logger.d('🔄 Sesión activa encontrada: ${session.eventTitle}');
        
        // Verificar si el evento aún está en tiempo válido
        final now = DateTime.now();
        if (now.isBefore(session.eventEndTime.add(Duration(hours: 1)))) {
          // Restaurar notificación persistente
          await _showPersistentNotification(session);
          return session;
        } else {
          // Limpiar sesión expirada
          await clearActiveSession();
        }
      }
      return null;
    } catch (e) {
      logger.d('❌ Error verificando sesión activa: $e');
      return null;
    }
  }

  /// Mostrar notificación persistente
  Future<void> _showPersistentNotification(ActiveSessionData session) async {
    try {
      final duration = DateTime.now().difference(session.startedAt);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      await _notificationManager.showPersistentAttendanceNotification(
        id: 1000,
        title: '🎯 Asistencia Activa',
        body: '${session.eventTitle}\n⏱️ Tiempo activo: ${hours}h ${minutes}m\n📱 Toca para volver a la app',
        payload: json.encode({
          'type': 'active_session',
          'eventId': session.eventId,
          'eventTitle': session.eventTitle,
        }),
      );
    } catch (e) {
      logger.d('❌ Error mostrando notificación persistente: $e');
    }
  }

  /// Guardar estado de asistencia
  Future<void> _saveAttendanceState(AttendanceState state) async {
    try {
      await _storageService.saveData(_sessionStateKey, json.encode(state.toJson()));
    } catch (e) {
      logger.d('❌ Error guardando estado de asistencia: $e');
    }
  }

  /// Iniciar guardado periódico
  void _startPeriodicSave() {
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final session = await getActiveSession();
      if (session != null && session.isActive) {
        // Actualizar timestamp de última actividad
        final updatedSession = session.copyWith(lastUpdate: DateTime.now());
        await _storageService.saveData(_activeSessionKey, json.encode(updatedSession.toJson()));
        
        // Actualizar notificación con tiempo transcurrido
        await _showPersistentNotification(updatedSession);
      }
    });
    
    logger.d('⏱️ Guardado periódico de sesión iniciado (cada 30s)');
  }

  /// Verificar si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final session = await getActiveSession();
    return session != null && session.isActive;
  }

  /// Pausar sesión (cuando la app va a background por mucho tiempo)
  Future<void> pauseSession() async {
    try {
      final session = await getActiveSession();
      if (session != null) {
        final pausedSession = session.copyWith(
          lastUpdate: DateTime.now(),
          // Agregar flag de pausa si es necesario
        );
        await _storageService.saveData(_activeSessionKey, json.encode(pausedSession.toJson()));
        logger.d('⏸️ Sesión pausada');
      }
    } catch (e) {
      logger.d('❌ Error pausando sesión: $e');
    }
  }

  /// Reanudar sesión
  Future<void> resumeSession() async {
    try {
      final session = await getActiveSession();
      if (session != null) {
        await _showPersistentNotification(session);
        logger.d('▶️ Sesión reanudada');
      }
    } catch (e) {
      logger.d('❌ Error reanudando sesión: $e');
    }
  }

  /// Detener el servicio
  void dispose() {
    _persistenceTimer?.cancel();
    _isInitialized = false;
    logger.d('🔄 SessionPersistenceService detenido');
  }
}

/// Modelo de datos para sesión activa
class ActiveSessionData {
  final String eventId;
  final String eventTitle;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
  final String userId;
  final String userName;
  final DateTime startedAt;
  final DateTime lastUpdate;
  final bool isActive;

  ActiveSessionData({
    required this.eventId,
    required this.eventTitle,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.userId,
    required this.userName,
    required this.startedAt,
    required this.lastUpdate,
    required this.isActive,
  });

  factory ActiveSessionData.fromJson(Map<String, dynamic> json) {
    return ActiveSessionData(
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String,
      eventStartTime: DateTime.parse(json['eventStartTime'] as String),
      eventEndTime: DateTime.parse(json['eventEndTime'] as String),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventStartTime': eventStartTime.toIso8601String(),
      'eventEndTime': eventEndTime.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'startedAt': startedAt.toIso8601String(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'isActive': isActive,
    };
  }

  ActiveSessionData copyWith({
    String? eventId,
    String? eventTitle,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
    String? userId,
    String? userName,
    DateTime? startedAt,
    DateTime? lastUpdate,
    bool? isActive,
  }) {
    return ActiveSessionData(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startedAt: startedAt ?? this.startedAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isActive: isActive ?? this.isActive,
    );
  }
}