// lib/services/firebase/hybrid_backend_service.dart
// Servicio híbrido que conecta Flutter con el backend Node.js + Firebase

import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HybridBackendService {
  static final HybridBackendService _instance = HybridBackendService._internal();
  factory HybridBackendService() => _instance;
  HybridBackendService._internal();

  // CONFIGURACIÓN DEL BACKEND
  static const String _baseUrl = 'http://192.168.2.5:8080'; // Direct PC IP connection
  static const String _firestoreApiPath = '/api/firestore';
  
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  
  String? _userId;
  String? _userRole;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String get baseUrl => _baseUrl;
  String? get userId => _userId;

  /// 🚀 INICIALIZAR SERVICIO HÍBRIDO
  Future<void> initialize(String userId, String userRole) async {
    try {
      _userId = userId;
      _userRole = userRole;
      
      logger.d('🔥 Inicializando servicio híbrido para usuario: $userId');
      
      // 1. Verificar conectividad con backend
      final backendHealthy = await _checkBackendHealth();
      if (!backendHealthy) {
        throw Exception('Backend Node.js no disponible en $_baseUrl');
      }

      // 2. Inicializar Firebase Messaging
      await _messagingService.initialize(userId);
      
      // 3. Registrar token FCM en el backend
      final fcmToken = _messagingService.fcmToken;
      if (fcmToken != null) {
        await _registerTokenWithBackend(userId, fcmToken);
      }

      // 4. Configurar callbacks de messaging
      _setupMessagingCallbacks();
      
      _isInitialized = true;
      logger.d('✅ Servicio híbrido inicializado correctamente');
      
    } catch (e) {
      logger.d('❌ Error inicializando servicio híbrido: $e');
      rethrow;
    }
  }

  /// 🏥 VERIFICAR SALUD DEL BACKEND
  Future<bool> _checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_firestoreApiPath/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isHealthy = data['success'] == true && 
                         data['firestore'] == 'conectado';
                         
        logger.d('🏥 Backend health: ${isHealthy ? "✅ Saludable" : "⚠️ Problemas"}');
        return isHealthy;
      }
      
      return false;
    } catch (e) {
      logger.d('❌ Error verificando backend: $e');
      return false;
    }
  }

  /// 📱 REGISTRAR TOKEN FCM EN BACKEND
  Future<void> _registerTokenWithBackend(String userId, String fcmToken) async {
    try {
      logger.d('📱 Registrando token FCM en backend...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_firestoreApiPath/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          logger.d('✅ Token FCM registrado en backend');
          await _saveTokenLocally(fcmToken);
        } else {
          throw Exception('Backend rechazó el token: ${data['error']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
      
    } catch (e) {
      logger.d('❌ Error registrando token en backend: $e');
      // No hacer throw para evitar fallar la inicialización completa
    }
  }

  /// 💾 GUARDAR TOKEN LOCALMENTE
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      await prefs.setString('fcm_token_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      logger.d('❌ Error guardando token localmente: $e');
    }
  }

  /// 🎧 CONFIGURAR CALLBACKS DE MESSAGING
  void _setupMessagingCallbacks() {
    _messagingService.onTokenRefresh = (newToken) async {
      logger.d('🔄 Token FCM actualizado, enviando al backend...');
      if (_userId != null) {
        await _registerTokenWithBackend(_userId!, newToken);
      }
    };

    _messagingService.onMessageReceived = (message) {
      logger.d('📱 Mensaje recibido: ${message.notification?.title}');
      // Aquí puedes agregar lógica adicional para procesar mensajes
    };

    _messagingService.onMessageTapped = (message) {
      logger.d('👆 Notificación tocada: ${message.data}');
      // Agregar navegación o acciones específicas
    };
  }

  /// 🎯 ENVIAR UBICACIÓN PARA GEOFENCING AUTOMÁTICO
  Future<Map<String, dynamic>> sendLocationForGeofencing(Position position) async {
    if (!_isInitialized || _userId == null) {
      throw Exception('Servicio no inicializado o usuario no configurado');
    }

    try {
      logger.d('🎯 Enviando ubicación para geofencing: ${position.latitude}, ${position.longitude}');
      
      final requestData = {
        'userId': _userId!,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'bearing': position.heading,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$_firestoreApiPath/verify-attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.d('✅ Respuesta geofencing: ${data['success'] ? "Procesado" : "Sin eventos"}');
        return data;
      } else {
        throw Exception('Error HTTP: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      logger.d('❌ Error enviando ubicación: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🔔 ENVIAR NOTIFICACIÓN DE PRUEBA
  Future<bool> sendTestNotification(String title, String body) async {
    if (!_isInitialized || _userId == null) {
      throw Exception('Servicio no inicializado');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_firestoreApiPath/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId!,
          'title': title,
          'body': body,
          'data': {
            'type': 'test',
            'timestamp': DateTime.now().toIso8601String(),
          }
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
      
    } catch (e) {
      logger.d('❌ Error enviando notificación de prueba: $e');
      return false;
    }
  }

  /// 👤 SINCRONIZAR USUARIO CON FIRESTORE
  Future<Map<String, dynamic>?> syncUserWithFirestore() async {
    if (!_isInitialized || _userId == null) {
      throw Exception('Servicio no inicializado');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_firestoreApiPath/sync-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userId!}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['usuario'];
      }
      
      return null;
    } catch (e) {
      logger.d('❌ Error sincronizando usuario: $e');
      return null;
    }
  }

  /// 📊 OBTENER ESTADO DEL SERVICIO
  Future<Map<String, dynamic>> getServiceStatus() async {
    final backendHealthy = await _checkBackendHealth();
    
    return {
      'initialized': _isInitialized,
      'userId': _userId,
      'userRole': _userRole,
      'backendHealthy': backendHealthy,
      'fcmInitialized': _messagingService.isInitialized,
      'fcmToken': _messagingService.fcmToken?.substring(0, 20),
      'backendUrl': _baseUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 🧪 EJECUTAR PRUEBAS COMPLETAS
  Future<Map<String, dynamic>> runComprehensiveTest() async {
    logger.d('🧪 Ejecutando pruebas completas del servicio híbrido...');
    
    final results = <String, dynamic>{};
    
    // 1. Verificar backend
    results['backend_health'] = await _checkBackendHealth();
    
    // 2. Verificar token FCM
    results['fcm_token_available'] = _messagingService.fcmToken != null;
    
    // 3. Probar notificación
    if (_userId != null) {
      results['test_notification'] = await sendTestNotification(
        '🧪 Prueba del Sistema',
        'Prueba de integración híbrida exitosa'
      );
    }
    
    // 4. Probar sincronización de usuario
    final userSync = await syncUserWithFirestore();
    results['user_sync'] = userSync != null;
    
    // 5. Estado general
    results['overall_status'] = results.values.every((result) => result == true);
    results['timestamp'] = DateTime.now().toIso8601String();
    
    logger.d('🧪 Resultados de pruebas: $results');
    return results;
  }

  /// 🔄 OBTENER IP LOCAL AUTOMÁTICAMENTE (helper para configuración)
  static Future<String?> detectLocalIP() async {
    // Esta función ayuda a detectar la IP local para configurar el baseUrl
    // En producción, deberías configurar manualmente tu IP
    try {
      // Simulación - en una implementación real usarías network_info_plus
      return '192.168.1.100'; // Placeholder - cambiar por tu IP real
    } catch (e) {
      logger.d('❌ Error detectando IP local: $e');
      return null;
    }
  }

  /// 🚀 CONFIGURAR IP DEL BACKEND (para desarrollo)
  static void configureBackendIP(String ipAddress) {
    // Esta función permitiría cambiar la IP dinámicamente
    // Para implementación simple, cambiar la constante _baseUrl arriba
    logger.d('💡 Para cambiar la IP del backend, modifica _baseUrl en hybrid_backend_service.dart');
    logger.d('💡 IP sugerida: $ipAddress');
  }

  void dispose() {
    _isInitialized = false;
    _userId = null;
    _userRole = null;
    _messagingService.dispose();
  }
}

/// 🔧 CONFIGURACIÓN RÁPIDA
class HybridConfig {
  // CAMBIAR ESTAS CONFIGURACIONES SEGÚN TU RED LOCAL
  
  // 1. Encontrar tu IP local:
  //    Windows: ipconfig | findstr IPv4
  //    Mac/Linux: ifconfig | grep inet
  // 2. Cambiar la IP en _baseUrl arriba
  // 3. Asegurarse que el servidor Node.js esté corriendo en esa IP:80
  
  static const String defaultBackendIP = '192.168.1.100';
  static const int defaultBackendPort = 80;
  
  static String get backendUrl => 'http://$defaultBackendIP:$defaultBackendPort';
  
  static void showConfigurationHelp() {
    logger.d('📖 CONFIGURACIÓN DEL SERVICIO HÍBRIDO:');
    logger.d('1. Encuentra tu IP local:');
    logger.d('   Windows: ipconfig | findstr IPv4');
    logger.d('   Mac/Linux: ifconfig | grep inet');
    logger.d('2. Cambia _baseUrl en hybrid_backend_service.dart');
    logger.d('3. Inicia tu servidor Node.js: npm start');
    logger.d('4. Verifica que el backend responda en: $backendUrl/api/firestore/health');
  }
}