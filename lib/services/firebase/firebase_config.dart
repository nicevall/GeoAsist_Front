// lib/services/firebase/firebase_config.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseConfig {
  static late FirebaseApp _app;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Verificar si Firebase ya está inicializado
      if (_isInitialized) {
        logger.d('⚠️ Firebase ya está inicializado, omitiendo...');
        return;
      }
      
      // Verificar si ya existe una app por defecto (inicializada automáticamente)
      try {
        _app = Firebase.app();
        _isInitialized = true;
        logger.d('✅ Firebase ya estaba inicializado automáticamente');
        
        // Solo configurar FCM si no está configurado
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        return;
      } catch (e) {
        // No existe, intentamos inicializarlo manualmente
        logger.d('🔄 Inicializando Firebase manualmente...');
      }
      
      // Intentar inicialización manual solo si no existe
      try {
        _app = await Firebase.initializeApp();
        _isInitialized = true;
        logger.d('✅ Firebase inicializado manualmente sin opciones específicas');
      } catch (e) {
        // Si falla sin opciones, intentar con opciones específicas
        logger.d('🔄 Intentando con opciones específicas...');
        _app = await Firebase.initializeApp(
          options: _getFirebaseOptions(),
        );
        _isInitialized = true;
        logger.d('✅ Firebase inicializado con opciones específicas');
      }
      
      // Configurar FCM background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
    } catch (e) {
      logger.d('❌ Error inicializando Firebase: $e');
      logger.d('⚠️ Continuando en modo de recuperación...');
      // No relanzar el error, permitir que la app funcione en modo offline
      _isInitialized = false;
    }
  }

  static FirebaseOptions _getFirebaseOptions() {
    // IMPORTANTE: Reemplazar con tus propias credenciales de Firebase
    // Obtener de Firebase Console > Project Settings > General > Your apps
    return const FirebaseOptions(
      apiKey: 'tu-api-key-aqui', // Reemplazar con tu API Key
      appId: 'tu-app-id-aqui', // Reemplazar con tu App ID  
      messagingSenderId: 'tu-sender-id-aqui', // Reemplazar con tu Sender ID
      projectId: 'geo-asist-movil', // Tu Project ID
      storageBucket: 'geo-asist-movil.appspot.com', // Tu Storage Bucket
      authDomain: 'geo-asist-movil.firebaseapp.com', // Tu Auth Domain
    );
  }

  static FirebaseApp get app {
    if (!_isInitialized) {
      throw Exception('Firebase no ha sido inicializado. Llama a FirebaseConfig.initialize() primero.');
    }
    return _app;
  }
}

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No inicializar Firebase aquí, ya está inicializado
  
  logger.d('📱 Mensaje FCM recibido en background: ${message.messageId}');
  logger.d('📱 Título: ${message.notification?.title}');
  logger.d('📱 Cuerpo: ${message.notification?.body}');
  logger.d('📱 Data: ${message.data}');

  // Procesar mensaje según tipo
  final tipo = message.data['tipo'];
  switch (tipo) {
    case 'asistencia_automatica':
      await _procesarAsistenciaAutomatica(message);
      break;
    case 'recordatorio':
      await _procesarRecordatorio(message);
      break;
    case 'evento_iniciado':
      await _procesarEventoIniciado(message);
      break;
    default:
      logger.d('📱 Tipo de mensaje no reconocido: $tipo');
  }
}

Future<void> _procesarAsistenciaAutomatica(RemoteMessage message) async {
  final eventoId = message.data['eventoId'];
  final estado = message.data['estado'];
  
  logger.d('✅ Procesando asistencia automática: $estado para evento $eventoId');
  
  // Aquí podrías actualizar datos locales, mostrar notificación personalizada, etc.
}

Future<void> _procesarRecordatorio(RemoteMessage message) async {
  final eventoId = message.data['eventoId'];
  final minutosRestantes = message.data['minutosRestantes'];
  
  logger.d('⏰ Recordatorio: $minutosRestantes minutos para evento $eventoId');
}

Future<void> _procesarEventoIniciado(RemoteMessage message) async {
  final eventoId = message.data['eventoId'];
  
  logger.d('🚀 Evento iniciado: $eventoId');
  
  // Aquí podrías iniciar tracking automático si está habilitado
}