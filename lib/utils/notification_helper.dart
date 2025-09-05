// lib/utils/notification_helper.dart
// 🎯 HELPER DE NOTIFICACIONES FASE C - Sistema básico funcional
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  // 🎯 CONFIGURACIÓN DE NOTIFICACIONES
  static const String channelId = 'geo_asist_attendance';
  static const String channelName = 'Asistencia Geolocalizada';
  static const String channelDescription =
      'Notificaciones del sistema de asistencia';

  // Estado de inicialización
  bool _isInitialized = false;
  final bool _hasPermissions = false;

  // 🎯 INICIALIZACIÓN
  Future<void> initialize() async {
    logger.d('🔔 Inicializando NotificationHelper');

    try {
      // Inicialización básica - implementación real en Fase C
      _isInitialized = true;
      logger.d('✅ NotificationHelper inicializado');
    } catch (e) {
      logger.d('❌ Error inicializando notificaciones: $e');
    }
  }

  // 🎯 MÉTODOS PÚBLICOS PARA NOTIFICACIONES

  Future<void> showEventActiveNotification({
    required String eventName,
    required String eventId,
  }) async {
    if (!_isInitialized) {
      logger.d('⚠️ NotificationHelper no inicializado');
      return;
    }

    logger.d('🔔 Mostrando notificación de evento activo: $eventName');

    // Vibración háptica
    _triggerHapticFeedback('medium');

    _logNotification('Evento Activo', 'Tracking iniciado para: $eventName');
  }

  Future<void> showGeofenceEnteredNotification({
    required String eventName,
  }) async {
    if (!_isInitialized) return;

    logger.d('🔔 Usuario ingresó al geofence: $eventName');

    _triggerHapticFeedback('medium');
    _logNotification('Área del Evento', 'Has ingresado al área de $eventName');
  }

  Future<void> showGeofenceExitedNotification({
    required String eventName,
    required double distanceMeters,
  }) async {
    if (!_isInitialized) return;

    logger.d('🔔 Usuario salió del geofence: $eventName');

    _triggerHapticFeedback('heavy');
    _logNotification(
      'Fuera del Área',
      'Has salido del área de $eventName (${distanceMeters.toStringAsFixed(0)}m)',
    );
  }

  Future<void> showGracePeriodStartedNotification({
    required String eventName,
    required int gracePeriodSeconds,
  }) async {
    if (!_isInitialized) return;

    logger.d('🔔 Período de gracia iniciado: ${gracePeriodSeconds}s');

    _triggerHapticFeedback('heavy');
    _logNotification(
      'Período de Gracia',
      'Tienes ${gracePeriodSeconds}s para regresar al área de $eventName',
    );
  }

  Future<void> showGracePeriodExpiredNotification({
    required String eventName,
  }) async {
    if (!_isInitialized) return;

    logger.d('🔔 Período de gracia expirado: $eventName');

    _triggerHapticFeedback('error');
    _logNotification(
      'Gracia Expirada',
      'El período de gracia ha terminado para $eventName',
    );
  }

  Future<void> showTrackingPausedNotification() async {
    if (!_isInitialized) return;

    logger.d('🔔 Tracking pausado para receso');

    _triggerHapticFeedback('light');
    _logNotification('Receso Iniciado', 'El tracking ha sido pausado');
  }

  Future<void> showTrackingResumedNotification() async {
    if (!_isInitialized) return;

    logger.d('🔔 Tracking reanudado después del receso');

    _triggerHapticFeedback('light');
    _logNotification('Receso Terminado', 'El tracking ha sido reanudado');
  }

  Future<void> showAttendanceRegisteredNotification({
    required String eventName,
  }) async {
    if (!_isInitialized) return;

    logger.d('🔔 Asistencia registrada: $eventName');

    _triggerHapticFeedback('success');
    _logNotification(
      'Asistencia Registrada',
      'Tu asistencia ha sido registrada para $eventName',
    );
  }

  Future<void> showConnectionErrorNotification() async {
    if (!_isInitialized) return;

    logger.d('🔔 Error de conexión detectado');

    _triggerHapticFeedback('error');
    _logNotification('Error de Conexión', 'Problema conectando al servidor');
  }

  // 🎯 LIMPIEZA DE NOTIFICACIONES

  Future<void> clearAllNotifications() async {
    logger.d('🧹 Limpiando todas las notificaciones');
    // Implementación real será agregada en Fase C
  }

  Future<void> clearNotification(int notificationId) async {
    logger.d('🧹 Limpiando notificación: $notificationId');
    // Implementación real será agregada en Fase C
  }

  // 🎯 MÉTODOS PRIVADOS

  void _triggerHapticFeedback(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        HapticFeedback.lightImpact();
        break;
      case 'medium':
        HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        HapticFeedback.heavyImpact();
        break;
      case 'success':
        HapticFeedback.mediumImpact();
        break;
      case 'error':
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  void _logNotification(String title, String body) {
    final timestamp = DateTime.now().toIso8601String();
    logger.d('📱 [$timestamp] $title: $body');
  }

  // 🎯 GETTERS PÚBLICOS

  bool get isInitialized => _isInitialized;
  bool get hasPermissions => _hasPermissions;
}
