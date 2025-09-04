// lib/services/storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import '../core/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // 🎯 MÉTODOS EXISTENTES PARA AUTENTICACIÓN

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveUser(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(usuario.toJson());
    await prefs.setString(AppConstants.userDataKey, userJson);
    await prefs.setString(AppConstants.userRoleKey, usuario.rol);
    await prefs.setString(AppConstants.userIdKey, usuario.id);
  }

  Future<Usuario?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        return Usuario.fromJson(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  // Alias method for backward compatibility
  Future<Map<String, dynamic>?> getUserData() async {
    final user = await getUser();
    return user?.toJson();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.userIdKey);
  }

  // ✅ NUEVOS MÉTODOS GENÉRICOS PARA CUALQUIER TIPO DE DATO

  /// Guardar cualquier tipo de dato como String
  Future<void> saveData(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      throw Exception('Error guardando datos: $e');
    }
  }

  /// Obtener datos como String
  Future<String?> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      throw Exception('Error obteniendo datos: $e');
    }
  }

  /// Guardar datos booleanos
  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      throw Exception('Error guardando boolean: $e');
    }
  }

  /// Obtener datos booleanos
  Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      throw Exception('Error obteniendo boolean: $e');
    }
  }

  // 🎯 MÉTODOS PARA LOCAL PRESENCE MANAGER

  /// Guardar cambio de estado de presencia
  Future<void> savePresenceStatusChange({
    required String eventId,
    required String status,
    required DateTime timestamp,
  }) async {
    try {
      final key = 'presence_status_${eventId}_${timestamp.millisecondsSinceEpoch}';
      final data = {
        'eventId': eventId,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };
      await saveData(key, json.encode(data));
    } catch (e) {
      throw Exception('Error guardando cambio de estado: $e');
    }
  }

  /// Guardar resumen de sesión de presencia
  Future<void> savePresenceSession(Map<String, dynamic> summary) async {
    try {
      final eventId = summary['eventId'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = 'presence_session_${eventId}_$timestamp';
      await saveData(key, json.encode(summary));
    } catch (e) {
      throw Exception('Error guardando sesión de presencia: $e');
    }
  }

  /// Obtener todas las sesiones de presencia
  Future<List<Map<String, dynamic>>> getAllPresenceSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('presence_session_'));
      
      final sessions = <Map<String, dynamic>>[];
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          sessions.add(json.decode(data));
        }
      }
      
      return sessions;
    } catch (e) {
      throw Exception('Error obteniendo sesiones de presencia: $e');
    }
  }

  /// Guardar datos numéricos enteros
  Future<void> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e) {
      throw Exception('Error guardando entero: $e');
    }
  }

  /// Obtener datos numéricos enteros
  Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      throw Exception('Error obteniendo entero: $e');
    }
  }

  /// Guardar datos numéricos decimales
  Future<void> saveDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (e) {
      throw Exception('Error guardando decimal: $e');
    }
  }

  /// Obtener datos numéricos decimales
  Future<double?> getDouble(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(key);
    } catch (e) {
      throw Exception('Error obteniendo decimal: $e');
    }
  }

  /// Guardar lista de strings
  Future<void> saveStringList(String key, List<String> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, value);
    } catch (e) {
      throw Exception('Error guardando lista: $e');
    }
  }

  /// Obtener lista de strings
  Future<List<String>?> getStringList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key);
    } catch (e) {
      throw Exception('Error obteniendo lista: $e');
    }
  }

  /// Guardar objeto JSON (serializado automáticamente)
  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = json.encode(value);
      await saveData(key, jsonString);
    } catch (e) {
      throw Exception('Error guardando JSON: $e');
    }
  }

  /// Obtener objeto JSON (deserializado automáticamente)
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await getData(key);
      if (jsonString != null) {
        return json.decode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo JSON: $e');
    }
  }

  /// Verificar si existe una clave
  Future<bool> hasKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      throw Exception('Error verificando clave: $e');
    }
  }

  /// Remover una clave específica
  Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      throw Exception('Error removiendo datos: $e');
    }
  }

  /// Remover múltiples claves
  Future<void> removeMultipleKeys(List<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Error removiendo múltiples claves: $e');
    }
  }

  /// Obtener todas las claves almacenadas
  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys();
    } catch (e) {
      throw Exception('Error obteniendo todas las claves: $e');
    }
  }

  /// Limpiar storage completo (incluyendo datos de auth)
  Future<void> clearAllStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Error limpiando storage completo: $e');
    }
  }

  /// ✅ MÉTODOS ESPECÍFICOS PARA NOTIFICACIONES (USADOS POR STUDENTNOTIFICATIONSERVICE)

  /// Guardar configuración de notificaciones
  Future<void> saveNotificationConfig(String key, bool value) async {
    await saveBool('notification_$key', value);
  }

  /// Obtener configuración de notificaciones
  Future<bool> getNotificationConfig(String key,
      {bool defaultValue = true}) async {
    final value = await getBool('notification_$key');
    return value ?? defaultValue;
  }

  /// Guardar preferencias específicas de usuario
  Future<void> saveUserPreferences(
      String userId, Map<String, dynamic> preferences) async {
    await saveJson('user_preferences_$userId', preferences);
  }

  /// Obtener preferencias específicas de usuario
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    return await getJson('user_preferences_$userId');
  }

  /// Guardar datos de notificaciones
  Future<void> saveNotifications(
      List<Map<String, dynamic>> notifications) async {
    final notificationsJson = json.encode(notifications);
    await saveData('student_notifications', notificationsJson);
  }

  /// Obtener datos de notificaciones
  Future<List<Map<String, dynamic>>?> getNotifications() async {
    try {
      final notificationsJson = await getData('student_notifications');
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = json.decode(notificationsJson);
        return notificationsList.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo notificaciones: $e');
    }
  }

  /// ✅ MÉTODOS DE ESTADÍSTICAS Y DEBUGGING

  /// Obtener estadísticas de uso del storage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      final stats = <String, dynamic>{
        'totalKeys': allKeys.length,
        'keysByPrefix': <String, int>{},
        'totalSize': 0,
      };

      // Agrupar por prefijos
      final keysByPrefix = <String, int>{};
      int totalSize = 0;

      for (final key in allKeys) {
        final value = prefs.get(key);
        if (value != null) {
          // Calcular tamaño aproximado
          final size = value.toString().length;
          totalSize += size;

          // Agrupar por prefijo
          final prefix = key.split('_').first;
          keysByPrefix[prefix] = (keysByPrefix[prefix] ?? 0) + 1;
        }
      }

      stats['keysByPrefix'] = keysByPrefix;
      stats['totalSize'] = totalSize;

      return stats;
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }

  /// Exportar todos los datos del storage (para backup)
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final exportData = <String, dynamic>{};

      for (final key in allKeys) {
        final value = prefs.get(key);
        if (value != null) {
          exportData[key] = value;
        }
      }

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'totalKeys': allKeys.length,
        'data': exportData,
      };
    } catch (e) {
      throw Exception('Error exportando datos: $e');
    }
  }

  /// Importar datos al storage (desde backup)
  Future<void> importData(Map<String, dynamic> importData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = importData['data'] as Map<String, dynamic>?;

      if (data != null) {
        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;

          // Guardar según el tipo de dato
          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is List<String>) {
            await prefs.setStringList(key, value);
          }
        }
      }
    } catch (e) {
      throw Exception('Error importando datos: $e');
    }
  }

  /// ✅ MÉTODO DE LIMPIEZA ESPECÍFICA PARA TESTING
  Future<void> clearTestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // Remover solo claves de testing/desarrollo
      final testKeys = allKeys
          .where((key) =>
              key.startsWith('test_') ||
              key.startsWith('dev_') ||
              key.startsWith('demo_'))
          .toList();

      for (final key in testKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Error limpiando datos de testing: $e');
    }
  }

  // 🎯 MÉTODOS ADICIONALES PARA CONNECTIVITY SERVICE
  
  /// Generic get method for string values
  Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  
  /// Generic save method for string values
  Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
  
  /// Get list of maps from storage
  Future<List<dynamic>?> getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getString(key);
    if (listJson != null) {
      try {
        return json.decode(listJson) as List<dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  /// Save list of maps to storage
  Future<void> saveList(String key, List<dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = json.encode(list);
    await prefs.setString(key, listJson);
  }
  
  /// Get object from storage
  Future<Map<String, dynamic>?> getObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final objectJson = prefs.getString(key);
    if (objectJson != null) {
      try {
        return json.decode(objectJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  /// Save object to storage
  Future<void> saveObject(String key, dynamic object) async {
    final prefs = await SharedPreferences.getInstance();
    final objectJson = json.encode(object);
    await prefs.setString(key, objectJson);
  }

  // ✅ MÉTODOS ESPECÍFICOS PARA PRE-REGISTRO DE EVENTOS
  static const String _preRegisteredEventsKey = 'pre_registered_events';

  /// Obtener lista de eventos pre-registrados
  Future<List<String>?> getPreRegisteredEvents() async {
    try {
      return await getStringList(_preRegisteredEventsKey);
    } catch (e) {
      debugPrint('❌ Error obteniendo pre-registros: $e');
      return null;
    }
  }

  /// Guardar lista de eventos pre-registrados
  Future<void> savePreRegisteredEvents(List<String> eventIds) async {
    try {
      await saveStringList(_preRegisteredEventsKey, eventIds);
      debugPrint('✅ Pre-registros guardados: ${eventIds.length} eventos');
    } catch (e) {
      debugPrint('❌ Error guardando pre-registros: $e');
      throw Exception('Error guardando pre-registros: $e');
    }
  }

  /// Verificar si un evento está pre-registrado
  Future<bool> isEventPreRegistered(String eventId) async {
    try {
      final preRegistros = await getPreRegisteredEvents() ?? <String>[];
      return preRegistros.contains(eventId);
    } catch (e) {
      debugPrint('❌ Error verificando pre-registro: $e');
      return false;
    }
  }

  /// Remover un evento de pre-registros
  Future<void> removePreRegisteredEvent(String eventId) async {
    try {
      final preRegistros = await getPreRegisteredEvents() ?? <String>[];
      preRegistros.remove(eventId);
      await savePreRegisteredEvents(preRegistros);
      debugPrint('✅ Evento removido de pre-registros: $eventId');
    } catch (e) {
      debugPrint('❌ Error removiendo pre-registro: $e');
      throw Exception('Error removiendo pre-registro: $e');
    }
  }

  /// Limpiar todos los pre-registros
  Future<void> clearPreRegisteredEvents() async {
    try {
      await removeData(_preRegisteredEventsKey);
      debugPrint('✅ Pre-registros limpiados');
    } catch (e) {
      debugPrint('❌ Error limpiando pre-registros: $e');
      throw Exception('Error limpiando pre-registros: $e');
    }
  }

  // ✅ MÉTODO PARA CREAR USUARIO DE PRUEBA
  /// Crear y guardar usuario de prueba si no existe
  Future<Usuario> createTestUserIfNeeded() async {
    try {
      // Verificar si ya hay un usuario
      Usuario? existingUser = await getUser();
      if (existingUser != null && existingUser.id.isNotEmpty) {
        debugPrint('✅ Usuario existente encontrado: ${existingUser.nombre}');
        return existingUser;
      }

      // Crear usuario de prueba
      final testUser = Usuario(
        id: 'TEST_USER_${DateTime.now().millisecondsSinceEpoch}',
        nombre: 'Usuario de Prueba',
        correo: 'test@example.com',
        rol: 'estudiante',
      );

      await saveUser(testUser);
      debugPrint('✅ Usuario de prueba creado: ${testUser.nombre} (ID: ${testUser.id})');
      
      return testUser;
    } catch (e) {
      debugPrint('❌ Error creando usuario de prueba: $e');
      throw Exception('Error creando usuario de prueba: $e');
    }
  }
}
