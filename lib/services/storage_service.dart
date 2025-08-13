// lib/services/storage_service.dart
import 'dart:convert';
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
}
