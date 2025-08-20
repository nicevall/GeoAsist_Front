// lib/services/notification_settings_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_settings_model.dart';
import '../models/api_response_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../core/app_constants.dart';

/// ⚙️ SERVICIO DE CONFIGURACIÓN DE NOTIFICACIONES
/// Gestiona todas las preferencias de notificaciones del usuario
class NotificationSettingsService {
  static final NotificationSettingsService _instance = NotificationSettingsService._internal();
  factory NotificationSettingsService() => _instance;
  NotificationSettingsService._internal();

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  static const String _settingsKey = 'notification_settings';
  static const String _lastSyncKey = 'notification_settings_last_sync';

  NotificationSettings? _cachedSettings;

  /// 📥 CARGAR CONFIGURACIONES
  Future<ApiResponse<NotificationSettings>> loadSettings() async {
    try {
      debugPrint('⚙️ Cargando configuraciones de notificaciones');

      // Intentar cargar desde caché primero
      if (_cachedSettings != null) {
        debugPrint('✅ Configuraciones cargadas desde caché');
        return ApiResponse.success(_cachedSettings!);
      }

      // Cargar desde almacenamiento local
      final localSettings = await _loadFromLocal();
      if (localSettings != null) {
        _cachedSettings = localSettings;
        debugPrint('✅ Configuraciones cargadas desde almacenamiento local');
        
        // Sincronizar con servidor en background (sin esperar)
        _syncWithServer();
        
        return ApiResponse.success(localSettings);
      }

      // Si no hay configuraciones locales, cargar desde servidor
      final serverResponse = await _loadFromServer();
      if (serverResponse.success) {
        _cachedSettings = serverResponse.data!;
        await _saveToLocal(serverResponse.data!);
        debugPrint('✅ Configuraciones cargadas desde servidor');
        return serverResponse;
      }

      // Si todo falla, usar configuraciones por defecto
      final defaultSettings = NotificationSettings.defaultSettings();
      _cachedSettings = defaultSettings;
      await _saveToLocal(defaultSettings);
      debugPrint('✅ Usando configuraciones por defecto');
      
      return ApiResponse.success(defaultSettings);
    } catch (e) {
      debugPrint('❌ Error cargando configuraciones: $e');
      
      // En caso de error, usar configuraciones por defecto
      final defaultSettings = NotificationSettings.defaultSettings();
      return ApiResponse.success(defaultSettings);
    }
  }

  /// 💾 GUARDAR CONFIGURACIONES
  Future<ApiResponse<bool>> saveSettings(NotificationSettings settings) async {
    try {
      debugPrint('💾 Guardando configuraciones de notificaciones');

      // Validar configuraciones
      final validationErrors = _validateSettings(settings);
      if (validationErrors.isNotEmpty) {
        return ApiResponse.error('Configuraciones inválidas: ${validationErrors.join(', ')}');
      }

      // Guardar en caché
      _cachedSettings = settings;

      // Guardar localmente
      await _saveToLocal(settings);
      debugPrint('✅ Configuraciones guardadas localmente');

      // Intentar sincronizar con servidor
      final syncResult = await _saveToServer(settings);
      if (syncResult.success) {
        debugPrint('✅ Configuraciones sincronizadas con servidor');
      } else {
        debugPrint('⚠️ No se pudo sincronizar con servidor: ${syncResult.error}');
        // No es un error crítico, las configuraciones locales funcionan
      }

      return ApiResponse.success(true, message: 'Configuraciones guardadas');
    } catch (e) {
      debugPrint('❌ Error guardando configuraciones: $e');
      return ApiResponse.error('Error guardando configuraciones: $e');
    }
  }

  /// 🔄 SINCRONIZAR CON SERVIDOR
  Future<ApiResponse<bool>> syncSettings() async {
    try {
      debugPrint('🔄 Sincronizando configuraciones con servidor');

      final serverSettings = await _loadFromServer();
      if (serverSettings.success) {
        _cachedSettings = serverSettings.data!;
        await _saveToLocal(serverSettings.data!);
        debugPrint('✅ Configuraciones sincronizadas');
        return ApiResponse.success(true, message: 'Configuraciones sincronizadas');
      } else {
        return ApiResponse.error(serverSettings.error ?? 'Error sincronizando');
      }
    } catch (e) {
      debugPrint('❌ Error sincronizando configuraciones: $e');
      return ApiResponse.error('Error de sincronización: $e');
    }
  }

  /// 🔄 RESTABLECER A VALORES POR DEFECTO
  Future<ApiResponse<bool>> resetToDefaults() async {
    try {
      debugPrint('🔄 Restableciendo configuraciones por defecto');

      final defaultSettings = NotificationSettings.defaultSettings();
      final result = await saveSettings(defaultSettings);
      
      if (result.success) {
        debugPrint('✅ Configuraciones restablecidas');
        return ApiResponse.success(true, message: 'Configuraciones restablecidas');
      } else {
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error restableciendo configuraciones: $e');
      return ApiResponse.error('Error restableciendo configuraciones: $e');
    }
  }

  /// 📊 OBTENER ESTADÍSTICAS DE USO
  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      if (_cachedSettings == null) {
        await loadSettings();
      }

      final settings = _cachedSettings!;
      
      return {
        'notificationsEnabled': settings.enabled,
        'categoriesEnabled': {
          'events': settings.eventSettings.enabled,
          'attendance': settings.attendanceSettings.enabled,
          'system': settings.systemSettings.enabled,
          'justifications': settings.justificationSettings.enabled,
          'teacher': settings.teacherSettings.enabled,
        },
        'quietHoursEnabled': settings.quietHours.enabled,
        'soundEnabled': settings.soundEnabled,
        'vibrationEnabled': settings.vibrationEnabled,
        'maxNotificationsPerHour': settings.maxNotificationsPerHour,
        'groupSimilarNotifications': settings.groupSimilarNotifications,
        'defaultPriority': settings.defaultPriority.displayName,
        'lastModified': await _storageService.getData(_lastSyncKey),
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// 🔍 VERIFICAR SI NOTIFICACIÓN DEBE MOSTRARSE
  Future<bool> shouldShowNotification({
    required String category,
    required String type,
    required NotificationPriority priority,
    DateTime? scheduledTime,
  }) async {
    try {
      if (_cachedSettings == null) {
        await loadSettings();
      }

      final settings = _cachedSettings!;

      // Verificar si las notificaciones están habilitadas globalmente
      if (!settings.enabled) return false;

      // Verificar horarios silenciosos
      if (settings.quietHours.enabled && _isInQuietHours(settings.quietHours, scheduledTime)) {
        // Permitir solo notificaciones urgentes si está configurado
        if (!settings.quietHours.allowUrgentNotifications || priority != NotificationPriority.urgent) {
          return false;
        }
      }

      // Verificar configuraciones por categoría
      switch (category.toLowerCase()) {
        case 'event':
          if (!settings.eventSettings.enabled) return false;
          return _checkEventNotification(settings.eventSettings, type);
        
        case 'attendance':
          if (!settings.attendanceSettings.enabled) return false;
          return _checkAttendanceNotification(settings.attendanceSettings, type);
        
        case 'system':
          if (!settings.systemSettings.enabled) return false;
          return _checkSystemNotification(settings.systemSettings, type);
        
        case 'justification':
          if (!settings.justificationSettings.enabled) return false;
          return _checkJustificationNotification(settings.justificationSettings, type);
        
        case 'teacher':
          if (!settings.teacherSettings.enabled) return false;
          return _checkTeacherNotification(settings.teacherSettings, type);
        
        default:
          return true; // Permitir por defecto para categorías no reconocidas
      }
    } catch (e) {
      debugPrint('❌ Error verificando notificación: $e');
      return true; // Permitir por defecto en caso de error
    }
  }

  /// 📤 EXPORTAR CONFIGURACIONES
  Future<ApiResponse<String>> exportSettings() async {
    try {
      if (_cachedSettings == null) {
        await loadSettings();
      }

      final settingsJson = _cachedSettings!.toJson();
      final exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settingsJson,
      };

      final exportString = jsonEncode(exportData);
      return ApiResponse.success(exportString, message: 'Configuraciones exportadas');
    } catch (e) {
      debugPrint('❌ Error exportando configuraciones: $e');
      return ApiResponse.error('Error exportando configuraciones: $e');
    }
  }

  /// 📥 IMPORTAR CONFIGURACIONES
  Future<ApiResponse<bool>> importSettings(String importData) async {
    try {
      debugPrint('📥 Importando configuraciones');

      final data = jsonDecode(importData);
      
      // Validar formato
      if (data['version'] == null || data['settings'] == null) {
        return ApiResponse.error('Formato de importación inválido');
      }

      // Crear configuraciones desde datos importados
      final settings = NotificationSettings.fromJson(data['settings']);
      
      // Guardar configuraciones importadas
      final saveResult = await saveSettings(settings);
      
      if (saveResult.success) {
        debugPrint('✅ Configuraciones importadas exitosamente');
        return ApiResponse.success(true, message: 'Configuraciones importadas');
      } else {
        return saveResult;
      }
    } catch (e) {
      debugPrint('❌ Error importando configuraciones: $e');
      return ApiResponse.error('Error importando configuraciones: $e');
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Cargar desde almacenamiento local
  Future<NotificationSettings?> _loadFromLocal() async {
    try {
      final settingsJson = await _storageService.getData(_settingsKey);
      if (settingsJson != null) {
        final data = jsonDecode(settingsJson);
        return NotificationSettings.fromJson(data);
      }
    } catch (e) {
      debugPrint('❌ Error cargando configuraciones locales: $e');
    }
    return null;
  }

  /// Guardar en almacenamiento local
  Future<void> _saveToLocal(NotificationSettings settings) async {
    try {
      final settingsJson = jsonEncode(settings.toJson());
      await _storageService.saveData(_settingsKey, settingsJson);
      await _storageService.saveData(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error guardando configuraciones locales: $e');
    }
  }

  /// Cargar desde servidor
  Future<ApiResponse<NotificationSettings>> _loadFromServer() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.get(
        '/usuarios/notification-settings',
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success && response.data != null) {
        final settings = NotificationSettings.fromJson(response.data!['settings']);
        return ApiResponse.success(settings);
      } else {
        return ApiResponse.error(response.error ?? 'Error cargando desde servidor');
      }
    } catch (e) {
      debugPrint('❌ Error cargando desde servidor: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Guardar en servidor
  Future<ApiResponse<bool>> _saveToServer(NotificationSettings settings) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse.error('No hay sesión activa');
      }

      final response = await _apiService.put(
        '/usuarios/notification-settings',
        body: {'settings': settings.toJson()},
        headers: AppConstants.getAuthHeaders(token),
      );

      if (response.success) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(response.error ?? 'Error guardando en servidor');
      }
    } catch (e) {
      debugPrint('❌ Error guardando en servidor: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Sincronizar con servidor en background
  void _syncWithServer() {
    Future.microtask(() async {
      try {
        await syncSettings();
      } catch (e) {
        debugPrint('❌ Error sincronizando en background: $e');
      }
    });
  }

  /// Validar configuraciones
  List<String> _validateSettings(NotificationSettings settings) {
    List<String> errors = [];

    if (settings.maxNotificationsPerHour < 1 || settings.maxNotificationsPerHour > 100) {
      errors.add('Máximo de notificaciones por hora debe estar entre 1 y 100');
    }

    if (settings.eventSettings.reminderMinutes < 1 || settings.eventSettings.reminderMinutes > 1440) {
      errors.add('Minutos de recordatorio debe estar entre 1 y 1440');
    }

    return errors;
  }

  /// Verificar si está en horario silencioso
  bool _isInQuietHours(QuietHoursSettings quietHours, DateTime? time) {
    if (!quietHours.enabled || time == null) return false;

    final now = time;
    final currentDay = now.weekday;
    
    if (!quietHours.activeDays.contains(currentDay)) return false;

    final currentTime = TimeOfDay.fromDateTime(now);
    
    // Manejar horarios que cruzan medianoche
    if (quietHours.startTime.hour > quietHours.endTime.hour) {
      return _isTimeAfter(currentTime, quietHours.startTime) || 
             _isTimeBefore(currentTime, quietHours.endTime);
    } else {
      return _isTimeAfter(currentTime, quietHours.startTime) && 
             _isTimeBefore(currentTime, quietHours.endTime);
    }
  }

  /// Verificar si un tiempo está después de otro
  bool _isTimeAfter(TimeOfDay current, TimeOfDay reference) {
    return current.hour > reference.hour || 
           (current.hour == reference.hour && current.minute >= reference.minute);
  }

  /// Verificar si un tiempo está antes de otro
  bool _isTimeBefore(TimeOfDay current, TimeOfDay reference) {
    return current.hour < reference.hour || 
           (current.hour == reference.hour && current.minute <= reference.minute);
  }

  /// Verificar notificaciones de eventos
  bool _checkEventNotification(EventNotificationSettings settings, String type) {
    switch (type.toLowerCase()) {
      case 'reminder': return settings.reminderBefore;
      case 'starting': return settings.eventStarting;
      case 'ending': return settings.eventEnding;
      case 'canceled': return settings.eventCanceled;
      case 'updated': return settings.eventUpdated;
      default: return true;
    }
  }

  /// Verificar notificaciones de asistencia
  bool _checkAttendanceNotification(AttendanceNotificationSettings settings, String type) {
    switch (type.toLowerCase()) {
      case 'entry': return settings.entryConfirmation;
      case 'exit': return settings.exitWarning;
      case 'back': return settings.backInArea;
      case 'late': return settings.lateArrival;
      case 'absence': return settings.absenceDetected;
      case 'gps': return settings.gpsIssues;
      default: return true;
    }
  }

  /// Verificar notificaciones del sistema
  bool _checkSystemNotification(SystemNotificationSettings settings, String type) {
    switch (type.toLowerCase()) {
      case 'update': return settings.appUpdates;
      case 'maintenance': return settings.maintenanceAlerts;
      case 'security': return settings.securityAlerts;
      case 'backup': return settings.backupReminders;
      case 'storage': return settings.storageWarnings;
      default: return true;
    }
  }

  /// Verificar notificaciones de justificaciones
  bool _checkJustificationNotification(JustificationNotificationSettings settings, String type) {
    switch (type.toLowerCase()) {
      case 'status': return settings.statusUpdates;
      case 'approved': return settings.approvalNotifications;
      case 'rejected': return settings.rejectionNotifications;
      case 'reminder': return settings.reminderToSubmit;
      case 'document': return settings.documentReminders;
      default: return true;
    }
  }

  /// Verificar notificaciones de docente
  bool _checkTeacherNotification(TeacherNotificationSettings settings, String type) {
    switch (type.toLowerCase()) {
      case 'student_joined': return settings.studentJoinedEvent;
      case 'student_left': return settings.studentLeftArea;
      case 'late_arrival': return settings.lateArrivals;
      case 'absence': return settings.absenceAlerts;
      case 'justification': return settings.justificationReceived;
      case 'metrics': return settings.eventMetrics;
      default: return true;
    }
  }

  /// Obtener configuraciones actuales (cached)
  NotificationSettings? get currentSettings => _cachedSettings;

  /// Limpiar caché
  void clearCache() {
    _cachedSettings = null;
  }
}