// lib/services/asistencia/heartbeat_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api_service.dart';
// Unused import removed: api_response_model.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';

/// ✅ HEARTBEAT MANAGER: Heartbeats críticos cada 30 segundos
/// Responsabilidades:
/// - Heartbeat obligatorio cada 30 segundos al backend
/// - Session management con IDs únicos
/// - Retry automático con exponential backoff
/// - Estado de app (foreground/background)
/// - Validación de grace periods activos
/// - Manejo de fallas de conexión
class HeartbeatManager {
  static final HeartbeatManager _instance = HeartbeatManager._internal();
  factory HeartbeatManager() => _instance;
  HeartbeatManager._internal();

  final ApiService _apiService = ApiService();

  // ⚙️ CONFIGURACIÓN DE HEARTBEAT (simplified - unused fields removed)
  // Unused field _maxRetries removed
  // Unused field _baseRetryDelayMs removed
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // 🎯 ESTADO DEL HEARTBEAT
  Timer? _heartbeatTimer;
  String? _sessionId;
  int _heartbeatSequence = 0;
  // Unused field _isAppInForeground removed
  bool _isInGracePeriod = false;
  String? _currentEventId;
  bool _isActive = false;

  // 📊 MÉTRICAS DE HEARTBEAT
  final int _successfulHeartbeats = 0;
  final int _failedHeartbeats = 0;
  DateTime? _lastSuccessfulHeartbeat;
  DateTime? _lastFailedHeartbeat;

  // 🔄 STREAMS
  final StreamController<HeartbeatStatus> _statusController = 
      StreamController<HeartbeatStatus>.broadcast();

  /// Stream para escuchar cambios de estado del heartbeat
  Stream<HeartbeatStatus> get statusStream => _statusController.stream;

  /// ⚠️ HEARTBEAT TEMPORALMENTE DESHABILITADO
  Future<void> startHeartbeat({
    required String eventoId,
    bool isInGracePeriod = false,
  }) async {
    // ⚠️ IMPORTAR LA CONSTANTE
    const bool heartbeatEnabled = false; // Backend endpoint no existe
    
    if (!heartbeatEnabled) {
      logger.d('⚠️ Heartbeat DISABLED - Backend endpoint /asistencia/heartbeat no existe');
      _updateStatus(HeartbeatStatus.disabled);
      return;
    }
    
    // NOTE: Heartbeat functionality disabled until backend endpoint is implemented
  }

  /// ✅ DETENER HEARTBEAT MANAGER
  Future<void> stopHeartbeat() async {
    logger.d('💓 Stopping heartbeat manager');
    
    _isActive = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    // Enviar heartbeat final
    if (_sessionId != null && _currentEventId != null) {
      await _sendFinalHeartbeat();
    }
    
    _currentEventId = null;
    _sessionId = null;
    _heartbeatSequence = 0;
    
    _updateStatus(HeartbeatStatus.stopped);
  }

  /// ✅ ACTUALIZAR ESTADO DE APP
  void updateAppState({
    required bool isInForeground,
    bool? isInGracePeriod,
  }) {
    logger.d('📱 App state updated - Foreground: $isInForeground, Grace: ${isInGracePeriod ?? _isInGracePeriod}');
    
    // Removed assignment to unused field _isAppInForeground
    if (isInGracePeriod != null) {
      _isInGracePeriod = isInGracePeriod;
    }
  }

  // Unused method _sendHeartbeat removed

  // Unused method _sendHeartbeatWithRetry removed

  /// 🔚 HEARTBEAT FINAL
  Future<void> _sendFinalHeartbeat() async {
    logger.d('🔚 Sending final heartbeat');
    
    try {
      final finalData = {
        'sessionId': _sessionId,
        'sequence': _heartbeatSequence + 1,
        'eventoId': _currentEventId,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'final',
      };

      await _apiService.post('/asistencia/heartbeat', body: finalData)
          .timeout(_timeoutDuration);
      
      logger.d('✅ Final heartbeat sent successfully');
      
    } catch (e) {
      logger.d('❌ Final heartbeat failed: $e');
    }
  }

  // Unused method _handleHeartbeatFailure removed

  // Unused method _generateSessionId removed

  /// 📊 OBTENER MÉTRICAS
  HeartbeatMetrics getMetrics() {
    return HeartbeatMetrics(
      successfulHeartbeats: _successfulHeartbeats,
      failedHeartbeats: _failedHeartbeats,
      lastSuccessfulHeartbeat: _lastSuccessfulHeartbeat,
      lastFailedHeartbeat: _lastFailedHeartbeat,
      currentSequence: _heartbeatSequence,
      sessionId: _sessionId,
      isActive: _isActive,
    );
  }

  /// 🔄 ACTUALIZAR ESTADO
  void _updateStatus(HeartbeatStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// 🧹 CLEANUP
  void dispose() {
    logger.d('🧹 Disposing HeartbeatManager');
    
    _isActive = false;
    _heartbeatTimer?.cancel();
    _statusController.close();
    
    logger.d('🧹 HeartbeatManager disposed');
  }
}

/// ✅ ESTADOS DEL HEARTBEAT
enum HeartbeatStatus {
  inactive,    // No iniciado
  active,      // Funcionando normalmente
  failing,     // Fallos intermitentes
  critical,    // Múltiples fallos
  stopped,     // Detenido intencionalmente
  disabled,    // Deshabilitado por configuración
}

/// ✅ MÉTRICAS DEL HEARTBEAT
class HeartbeatMetrics {
  final int successfulHeartbeats;
  final int failedHeartbeats;
  final DateTime? lastSuccessfulHeartbeat;
  final DateTime? lastFailedHeartbeat;
  final int currentSequence;
  final String? sessionId;
  final bool isActive;

  const HeartbeatMetrics({
    required this.successfulHeartbeats,
    required this.failedHeartbeats,
    this.lastSuccessfulHeartbeat,
    this.lastFailedHeartbeat,
    required this.currentSequence,
    this.sessionId,
    required this.isActive,
  });

  /// Porcentaje de éxito
  double get successRate {
    final total = successfulHeartbeats + failedHeartbeats;
    return total > 0 ? (successfulHeartbeats / total) * 100 : 0.0;
  }

  /// ¿Está funcionando bien?
  bool get isHealthy => successRate >= 80.0 && failedHeartbeats < 5;

  @override
  String toString() {
    return 'HeartbeatMetrics(successful: $successfulHeartbeats, failed: $failedHeartbeats, '
           'success rate: ${successRate.toStringAsFixed(1)}%, active: $isActive)';
  }
}