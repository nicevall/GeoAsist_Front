import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/event_automation_service.dart
// 🎯 SERVICIO DE AUTOMATIZACIÓN DE EVENTOS CON WEBSOCKET
import 'dart:async';
import '../services/websocket_service.dart';
import '../services/local_presence_manager.dart';
import '../services/local_geofencing_service.dart';
import '../services/notifications/notification_manager.dart';
import '../services/storage_service.dart';
import '../models/evento_model.dart';

/// Estados de automatización de eventos
enum EventAutomationStatus {
  inactive,       // Sin eventos monitoreados
  monitoring,     // Monitoreando eventos
  eventActive,    // Evento en curso
  eventPaused,    // Evento pausado (En espera)
  eventFinished,  // Evento finalizado
}

/// Servicio que coordina la automatización completa
class EventAutomationService {
  static final EventAutomationService _instance = EventAutomationService._internal();
  factory EventAutomationService() => _instance;
  EventAutomationService._internal();

  final WebSocketService _webSocketService = WebSocketService.instance;
  final LocalPresenceManager _presenceManager = LocalPresenceManager();
  final LocalGeofencingService _geofencingService = LocalGeofencingService();
  final NotificationManager _notificationManager = NotificationManager();
  final StorageService _storageService = StorageService();

  // 🎯 ESTADO ACTUAL
  EventAutomationStatus _status = EventAutomationStatus.inactive;
  Evento? _currentEvent;
  String? _currentUserId;
  StreamSubscription? _webSocketSubscription;
  StreamSubscription? _presenceSubscription;
  StreamSubscription? _geofenceSubscription;

  // 🔄 STREAMS
  final StreamController<EventAutomationStatus> _statusController = 
      StreamController<EventAutomationStatus>.broadcast();

  /// Stream para escuchar cambios de estado de automatización
  Stream<EventAutomationStatus> get statusStream => _statusController.stream;

  /// ✅ INICIAR AUTOMATIZACIÓN PARA UN EVENTO
  Future<void> startEventAutomation(Evento event) async {
    logger.d('🤖 Iniciando automatización para evento: ${event.titulo}');
    
    _currentEvent = event;
    _currentUserId = await _storageService.getUserId();

    // 1. Conectar WebSocket para recibir cambios automáticos
    await _setupWebSocketConnection();
    
    // 2. Iniciar monitoreo local de presencia
    await _startLocalMonitoring();
    
    // 3. Configurar listeners para coordinar servicios
    _setupAutomationListeners();

    _updateStatus(EventAutomationStatus.monitoring);
    
    logger.d('✅ Automatización iniciada - Esperando cambios del backend');
  }

  /// 🔗 CONFIGURAR CONEXIÓN WEBSOCKET
  Future<void> _setupWebSocketConnection() async {
    try {
      final userId = _currentUserId;
      final eventId = _currentEvent?.id;
      
      if (userId != null && eventId != null) {
        await _webSocketService.connectToEvent(
          eventId: eventId,
          userId: userId,
          userRole: await _storageService.getUserRole() ?? 'estudiante',
        );
        
        // Escuchar mensajes WebSocket
        _webSocketSubscription = _webSocketService.messageStream.listen(
          _handleWebSocketMessage,
          onError: (error) {
            logger.d('❌ Error WebSocket: $error');
          },
        );
      }
    } catch (e) {
      logger.d('❌ Error configurando WebSocket: $e');
    }
  }

  /// 📱 INICIAR MONITOREO LOCAL
  Future<void> _startLocalMonitoring() async {
    if (_currentEvent == null) return;

    try {
      // Iniciar presence manager (reemplaza heartbeats)
      await _presenceManager.startPresenceMonitoring(_currentEvent!);
      
      // Iniciar geofencing local
      await _geofencingService.startGeofencing(_currentEvent!);
      
      logger.d('✅ Monitoreo local iniciado');
    } catch (e) {
      logger.d('❌ Error iniciando monitoreo local: $e');
    }
  }

  /// 🎧 CONFIGURAR LISTENERS DE AUTOMATIZACIÓN
  void _setupAutomationListeners() {
    // Listener de presencia local
    _presenceSubscription = _presenceManager.statusStream.listen((status) {
      _handlePresenceChange(status);
    });

    // Listener de geofencing local
    _geofenceSubscription = _geofencingService.geofenceStream.listen((result) {
      _handleGeofenceChange(result);
    });
  }

  /// 📨 MANEJAR MENSAJES WEBSOCKET (AUTOMATIZACIÓN)
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    
    switch (messageType) {
      case 'event-status':
        _handleEventStatusChange(data);
        break;
      default:
        logger.d('📨 Mensaje WebSocket no manejado: $messageType');
    }
  }

  /// 📢 MANEJAR CAMBIO DE ESTADO DE EVENTO (AUTOMATIZACIÓN BACKEND)
  void _handleEventStatusChange(Map<String, dynamic> data) {
    final newStatus = data['estado'] as String?;
    final eventId = data['evento'] as String?;
    
    if (eventId != _currentEvent?.id) {
      logger.d('⚠️ Cambio de estado para evento diferente, ignorando');
      return;
    }

    logger.d('🎯 AUTOMATIZACIÓN: Evento cambió a estado "$newStatus"');

    switch (newStatus) {
      case 'En proceso':
        _handleEventStartedAutomatically();
        break;
      case 'finalizado':
        _handleEventEndedAutomatically();
        break;
      case 'En espera':
        _handleEventPausedAutomatically();
        break;
      case 'cancelado':
        _handleEventCancelledAutomatically();
        break;
    }
  }

  /// 🟢 EVENTO INICIADO AUTOMÁTICAMENTE POR CRON
  void _handleEventStartedAutomatically() {
    logger.d('🟢 AUTOMATIZACIÓN: Evento iniciado por cron del backend');
    
    _updateStatus(EventAutomationStatus.eventActive);
    
    // Notificar al usuario
    _notificationManager.showEventStartedNotification(
      _currentEvent?.titulo ?? 'Evento'
    );

    // Activar tracking si es estudiante
    _activateStudentTracking();
  }

  /// 🔴 EVENTO FINALIZADO AUTOMÁTICAMENTE POR CRON
  void _handleEventEndedAutomatically() {
    logger.d('🔴 AUTOMATIZACIÓN: Evento finalizado por cron del backend');
    
    _updateStatus(EventAutomationStatus.eventFinished);
    
    // Notificar al usuario
    _notificationManager.showEventEndedNotification(
      _currentEvent?.id ?? 'evento'
    );

    // Detener tracking
    _deactivateTracking();

    // Auto-detener automatización después de 5 minutos
    Timer(const Duration(minutes: 5), () {
      stopEventAutomation();
    });
  }

  /// ⏸️ EVENTO PAUSADO (CONTINÚA MAÑANA)
  void _handleEventPausedAutomatically() {
    logger.d('⏸️ AUTOMATIZACIÓN: Evento pausado hasta mañana');
    
    _updateStatus(EventAutomationStatus.eventPaused);
    
    // Pausar tracking pero mantener conectividad
    _pauseTracking();
  }

  /// ❌ EVENTO CANCELADO
  void _handleEventCancelledAutomatically() {
    logger.d('❌ AUTOMATIZACIÓN: Evento cancelado');
    
    // Detener todo inmediatamente
    stopEventAutomation();
  }

  /// 🎯 ACTIVAR TRACKING DE ESTUDIANTE
  void _activateStudentTracking() async {
    final userRole = await _storageService.getUserRole();
    
    if (userRole == 'estudiante') {
      logger.d('🎯 Activando tracking de estudiante automáticamente');
      
      // El LocalPresenceManager ya está corriendo
      // Solo notificar que pueden registrar asistencia
      _notificationManager.showTrackingActiveNotification();
    }
  }

  /// 🛑 DESACTIVAR TRACKING
  void _deactivateTracking() {
    logger.d('🛑 Desactivando tracking');
    
    _presenceManager.stopPresenceMonitoring();
    _geofencingService.stopGeofencing();
  }

  /// ⏸️ PAUSAR TRACKING
  void _pauseTracking() {
    logger.d('⏸️ Pausando tracking');
    
    // Pausar pero no detener completamente
    _presenceManager.activateGracePeriod(duration: const Duration(hours: 12));
  }

  /// 📍 MANEJAR CAMBIOS DE PRESENCIA LOCAL
  void _handlePresenceChange(LocalPresenceStatus status) {
    switch (status) {
      case LocalPresenceStatus.present:
        logger.d('✅ Usuario presente en el evento');
        break;
      case LocalPresenceStatus.absent:
        logger.d('❌ Usuario ausente del evento');
        break;
      case LocalPresenceStatus.warning:
        logger.d('⚠️ Usuario cerca del límite');
        break;
      case LocalPresenceStatus.disconnected:
        logger.d('📵 Sin conexión GPS');
        break;
      default:
        break;
    }
  }

  /// 🎯 MANEJAR CAMBIOS DE GEOFENCING LOCAL
  void _handleGeofenceChange(GeofenceResult result) {
    if (result.isInside) {
      logger.d('🎯 Usuario dentro del geofence');
    } else {
      logger.d('📍 Usuario fuera del geofence (${result.distance.round()}m)');
    }
  }

  /// 🔄 ACTUALIZAR ESTADO
  void _updateStatus(EventAutomationStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
      
      logger.d('🤖 Estado automatización: ${newStatus.toString()}');
    }
  }

  /// 🛑 DETENER AUTOMATIZACIÓN
  Future<void> stopEventAutomation() async {
    logger.d('🛑 Deteniendo automatización de eventos');

    // Cerrar WebSocket
    await _webSocketService.disconnect();
    
    // Detener monitoring local
    _deactivateTracking();
    
    // Cancelar subscripciones
    await _webSocketSubscription?.cancel();
    await _presenceSubscription?.cancel();
    await _geofenceSubscription?.cancel();

    _currentEvent = null;
    _currentUserId = null;
    
    _updateStatus(EventAutomationStatus.inactive);
    
    logger.d('✅ Automatización detenida completamente');
  }

  /// 📊 GETTERS DE ESTADO
  EventAutomationStatus get currentStatus => _status;
  Evento? get currentEvent => _currentEvent;
  bool get isActive => _status != EventAutomationStatus.inactive;

  /// 🧹 DISPOSE
  void dispose() {
    stopEventAutomation();
    _statusController.close();
  }
}