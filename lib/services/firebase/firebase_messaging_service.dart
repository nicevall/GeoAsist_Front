// lib/services/firebase/firebase_messaging_service.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import '../api_service.dart';
import '../pre_registration_notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;
  String? _fcmToken;

  // Callbacks
  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageTapped;
  Function(String token)? onTokenRefresh;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // 🚀 INICIALIZAR FCM
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      logger.d('⚠️ FCM ya está inicializado');
      return;
    }

    try {
      // 1. Solicitar permisos
      await _requestPermissions();
      
      // 2. Configurar notificaciones locales
      await _setupLocalNotifications();
      
      // 3. Obtener y guardar token FCM
      await _setupFCMToken(userId);
      
      // 4. Configurar listeners
      _setupMessageHandlers();
      
      _isInitialized = true;
      logger.d('✅ Firebase Messaging inicializado correctamente');
    } catch (e) {
      logger.d('❌ Error inicializando FCM: $e');
      rethrow;
    }
  }

  // 🔐 SOLICITAR PERMISOS
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    logger.d('📱 Permisos FCM: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw Exception('Permisos de notificaciones no concedidos');
    }
  }

  // 🔔 CONFIGURAR NOTIFICACIONES LOCALES
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Crear canal para Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Canal para asistencias
    const asistenciaChannel = AndroidNotificationChannel(
      'asistencia_channel',
      'Notificaciones de Asistencia',
      description: 'Notificaciones relacionadas con el registro de asistencia',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    // Canal para recordatorios
    const recordatorioChannel = AndroidNotificationChannel(
      'recordatorio_channel',
      'Recordatorios de Eventos',
      description: 'Recordatorios de eventos próximos',
      importance: Importance.high,
    );

    // Canal para eventos
    const eventosChannel = AndroidNotificationChannel(
      'eventos_channel',
      'Eventos del Sistema',
      description: 'Notificaciones de cambios en eventos',
      importance: Importance.defaultImportance,
    );

    // ✅ NUEVO: Canal para eventos pre-registrados
    const eventStartChannel = AndroidNotificationChannel(
      'event_start_channel',
      'Inicio de Eventos',
      description: 'Notificaciones cuando un evento pre-registrado está por comenzar',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(asistenciaChannel);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(recordatorioChannel);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eventosChannel);

    // ✅ NUEVO: Crear canal para eventos pre-registrados
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eventStartChannel);
  }

  // 🎫 CONFIGURAR TOKEN FCM
  Future<void> _setupFCMToken(String userId) async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        logger.d('📱 FCM Token obtenido: ${_fcmToken!.substring(0, 20)}...');
        
        // ✅ PHASE 3: Registrar token tanto en Firestore como en Backend API
        await Future.wait([
          // 1. Guardar en Firestore (método existente)
          _firestoreService.updateUsuarioFCMToken(userId, _fcmToken!),
          // 2. Registrar en Backend API (nueva integración)
          _registerTokenWithBackend(userId, _fcmToken!),
        ]);
        
        // Suscribirse a temas relevantes
        await _subscribeToTopics(userId);
      }

      // Listener para cambios de token
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        onTokenRefresh?.call(newToken);
        
        // ✅ PHASE 3: Actualizar token en ambos servicios
        await Future.wait([
          _firestoreService.updateUsuarioFCMToken(userId, newToken),
          _registerTokenWithBackend(userId, newToken),
        ]);
        
        logger.d('🔄 FCM Token actualizado en ambos servicios');
      });
      
    } catch (e) {
      logger.d('❌ Error configurando token FCM: $e');
    }
  }

  // 📢 SUSCRIBIRSE A TEMAS
  Future<void> _subscribeToTopics(String userId) async {
    try {
      // Obtener datos del usuario para suscripciones inteligentes
      final userResponse = await _firestoreService.getUsuario(userId);
      
      if (userResponse != null) {
        final usuario = userResponse;
        
        // Suscripción por rol
        if (usuario['rol'] != null) {
          await _messaging.subscribeToTopic('rol_${usuario['rol']}');
          logger.d('📢 Suscrito al tema: rol_${usuario['rol']}');
        }
        
        // Suscripción por materias (si aplica)
        // if (usuario.materias != null) {
        //   for (final materia in usuario.materias!) {
        //     await _messaging.subscribeToTopic('materia_$materia');
        //   }
        // }
        
        // Tema general
        await _messaging.subscribeToTopic('todos_usuarios');
        logger.d('📢 Suscrito al tema: todos_usuarios');
      }
    } catch (e) {
      logger.d('❌ Error suscribiéndose a temas: $e');
    }
  }

  // 🎧 CONFIGURAR HANDLERS DE MENSAJES
  void _setupMessageHandlers() {
    // Mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Mensajes cuando se toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Verificar si se abrió desde notificación
    _checkInitialMessage();
  }

  // 📱 MANEJAR MENSAJE EN FOREGROUND
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logger.d('📱 Mensaje FCM en foreground: ${message.messageId}');
    logger.d('📱 Título: ${message.notification?.title}');
    logger.d('📱 Cuerpo: ${message.notification?.body}');
    
    onMessageReceived?.call(message);
    
    // Mostrar notificación local personalizada
    await _showLocalNotification(message);
  }

  // 👆 MANEJAR TOQUE EN NOTIFICACIÓN
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    logger.d('👆 App abierta desde notificación: ${message.messageId}');
    onMessageTapped?.call(message);
    
    // Procesar acción según tipo de mensaje
    await _processNotificationAction(message);
  }

  // 🔍 VERIFICAR MENSAJE INICIAL
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      logger.d('🚀 App iniciada desde notificación: ${initialMessage.messageId}');
      await _processNotificationAction(initialMessage);
    }
  }

  // 🔔 MOSTRAR NOTIFICACIÓN LOCAL PERSONALIZADA
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Determinar canal según tipo
    String channelId = 'geoasist_default';
    String channelName = 'GeoAsist General';
    
    final tipo = message.data['tipo'];
    switch (tipo) {
      case 'asistencia_automatica':
        channelId = 'asistencia_channel';
        channelName = 'Asistencias';
        break;
      case 'recordatorio':
      case 'recordatorio_urgente':
        channelId = 'recordatorio_channel';
        channelName = 'Recordatorios';
        break;
      case 'evento_iniciado':
      case 'cambio_evento':
        channelId = 'eventos_channel';
        channelName = 'Eventos';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  // 🎯 PROCESAR ACCIÓN DE NOTIFICACIÓN
  Future<void> _processNotificationAction(RemoteMessage message) async {
    final tipo = message.data['tipo'];
    final eventoId = message.data['eventoId'];
    
    logger.d('🎯 Procesando acción: $tipo para evento: $eventoId');
    
    switch (tipo) {
      case 'asistencia_automatica':
        // Navegar a pantalla de asistencias o mostrar detalles
        break;
      case 'recordatorio':
      case 'recordatorio_urgente':
        // Navegar a detalles del evento o iniciar tracking
        break;
      case 'evento_iniciado':
        // Navegar a tracking automático
        break;
      case 'cambio_evento':
        // Mostrar detalles del cambio
        break;
    }
  }

  // 🔔 TOQUE EN NOTIFICACIÓN LOCAL
  void _onLocalNotificationTapped(NotificationResponse response) {
    logger.d('👆 Notificación local tocada: ${response.payload}');
    
    if (response.payload != null) {
      // ✅ NUEVO: Manejar notificaciones de pre-registro
      _handleNotificationPayload(response.payload!);
    }
  }

  /// ✅ NUEVO: Manejar diferentes tipos de payload de notificaciones
  Future<void> _handleNotificationPayload(String payload) async {
    try {
      // Verificar si es una notificación de pre-registro
      if (payload.contains('event_started')) {
        // Delegar al servicio de pre-registro
        await _handlePreRegistrationNotification(payload);
      } else {
        logger.d('🔄 Payload de notificación no reconocido: $payload');
      }
    } catch (e) {
      logger.d('❌ Error manejando payload de notificación: $e');
    }
  }

  /// ✅ NUEVO: Manejar notificaciones de eventos pre-registrados
  Future<void> _handlePreRegistrationNotification(String payload) async {
    try {
      await PreRegistrationNotificationService.handleNotificationTap(payload);
    } catch (e) {
      logger.d('❌ Error manejando notificación de pre-registro: $e');
    }
  }

  // 📨 ENVIAR NOTIFICACIÓN DE PRUEBA
  Future<void> sendTestNotification() async {
    if (_fcmToken == null) {
      logger.d('❌ No hay token FCM disponible');
      return;
    }

    await _localNotifications.show(
      999,
      '🧪 Notificación de Prueba',
      'El sistema de notificaciones está funcionando correctamente',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // 🎫 SUSCRIPCIONES A TEMAS
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      logger.d('📢 Suscrito al tema: $topic');
    } catch (e) {
      logger.d('❌ Error suscribiendo al tema $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      logger.d('📢 Desuscrito del tema: $topic');
    } catch (e) {
      logger.d('❌ Error desuscribiendo del tema $topic: $e');
    }
  }

  // 🔄 ACTUALIZAR TOKEN
  Future<void> refreshToken(String userId) async {
    try {
      await _messaging.deleteToken();
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null) {
        await _firestoreService.updateUsuarioFCMToken(userId, _fcmToken!);
        logger.d('🔄 Token FCM actualizado exitosamente');
      }
    } catch (e) {
      logger.d('❌ Error actualizando token: $e');
    }
  }

  // ✅ PHASE 3: Registrar token FCM en Backend API
  Future<void> _registerTokenWithBackend(String userId, String fcmToken) async {
    try {
      logger.d('📡 Registrando FCM token en backend API...');
      
      final response = await _apiService.post(
        '/firestore/register-token',
        body: {
          'userId': userId,
          'fcmToken': fcmToken,
          'platform': 'android',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response.success) {
        logger.d('✅ FCM token registrado exitosamente en backend API');
      } else {
        logger.d('⚠️ Backend rechazó el token: ${response.error}');
        // No lanzar excepción para evitar fallar la inicialización completa
      }
      
    } catch (e) {
      logger.d('❌ Error registrando token en backend: $e');
      // No lanzar excepción para evitar fallar la inicialización completa
      // El token se guarda en Firestore de todos modos
    }
  }

  void dispose() {
    _isInitialized = false;
    _fcmToken = null;
  }
}