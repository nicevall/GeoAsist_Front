// lib/widgets/event_status_banner.dart
// 🎯 BANNER SUPERIOR PARA MOSTRAR ESTADO DEL EVENTO EN TIEMPO REAL
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/evento_model.dart';
import '../models/student_notification_model.dart';
import '../services/student_notification_service.dart';
import '../services/websocket_student_service.dart';
import '../utils/colors.dart';

/// Estados posibles del evento desde la perspectiva del estudiante
enum EventStatus {
  notJoined, // No se ha unido al evento
  joining, // En proceso de unirse
  active, // Activo y tracking
  inBreak, // En receso
  outOfArea, // Fuera del área
  connectionLost, // Sin conexión
  ended, // Evento terminado
  error, // Error
}

/// Widget banner que muestra el estado actual del evento
class EventStatusBanner extends StatefulWidget {
  /// Evento actual
  final Evento? currentEvent;

  /// Estado inicial
  final EventStatus initialStatus;

  /// Callback cuando se toca el banner
  final VoidCallback? onTap;

  /// Si debe mostrar información detallada
  final bool showDetails;

  /// Si debe ser animado
  final bool animated;

  const EventStatusBanner({
    super.key,
    this.currentEvent,
    this.initialStatus = EventStatus.notJoined,
    this.onTap,
    this.showDetails = true,
    this.animated = true,
  });

  @override
  State<EventStatusBanner> createState() => _EventStatusBannerState();
}

class _EventStatusBannerState extends State<EventStatusBanner>
    with TickerProviderStateMixin {
  final StudentNotificationService _notificationService =
      StudentNotificationService();
  final WebSocketStudentService _webSocketService = WebSocketStudentService();

  // Estado del banner
  EventStatus _currentStatus = EventStatus.notJoined;
  String _statusMessage = '';
  String _detailMessage = '';
  DateTime? _lastUpdate;

  // Animaciones
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Subscriptions
  StreamSubscription<StudentNotification>? _notificationSubscription;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  // Timer para actualizaciones
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _initializeAnimations();
    _setupListeners();
    _updateStatusInfo();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    if (widget.animated) {
      _slideController.forward();
    }
  }

  void _setupListeners() {
    // Escuchar notificaciones para actualizar estado
    _notificationSubscription =
        _notificationService.newNotificationStream.listen(
      _handleNotification,
    );

    // Escuchar estado de conexión WebSocket
    _connectionSubscription = _webSocketService.connectionStateStream.listen(
      _handleConnectionStateChange,
    );
  }

  void _handleNotification(StudentNotification notification) {
    setState(() {
      _lastUpdate = DateTime.now();

      switch (notification.type) {
        case StudentNotificationType.joinedEvent:
          _currentStatus = EventStatus.active;
          break;
        case StudentNotificationType.eventStarted:
          if (_currentStatus == EventStatus.notJoined) {
            _currentStatus = EventStatus.notJoined;
          } else {
            _currentStatus = EventStatus.active;
          }
          break;
        case StudentNotificationType.breakStarted:
          _currentStatus = EventStatus.inBreak;
          break;
        case StudentNotificationType.breakEnded:
          _currentStatus = EventStatus.active;
          break;
        case StudentNotificationType.exitedArea:
          _currentStatus = EventStatus.outOfArea;
          break;
        case StudentNotificationType.enteredArea:
          _currentStatus = EventStatus.active;
          break;
        case StudentNotificationType.connectivityLost:
          _currentStatus = EventStatus.connectionLost;
          break;
        case StudentNotificationType.eventFinalized:
          _currentStatus = EventStatus.ended;
          break;
        default:
          break;
      }

      _updateStatusInfo();
      _updateAnimations();
    });
  }

  void _handleConnectionStateChange(WebSocketConnectionState state) {
    setState(() {
      _lastUpdate = DateTime.now();

      switch (state) {
        case WebSocketConnectionState.connecting:
          if (_currentStatus == EventStatus.notJoined) {
            _currentStatus = EventStatus.joining;
          }
          break;
        case WebSocketConnectionState.connected:
          if (_currentStatus == EventStatus.joining ||
              _currentStatus == EventStatus.connectionLost) {
            _currentStatus = EventStatus.active;
          }
          break;
        case WebSocketConnectionState.disconnected:
        case WebSocketConnectionState.error:
          if (_currentStatus != EventStatus.notJoined &&
              _currentStatus != EventStatus.ended) {
            _currentStatus = EventStatus.connectionLost;
          }
          break;
        case WebSocketConnectionState.reconnecting:
          _currentStatus = EventStatus.connectionLost;
          break;
      }

      _updateStatusInfo();
      _updateAnimations();
    });
  }

  void _updateStatusInfo() {
    switch (_currentStatus) {
      case EventStatus.notJoined:
        _statusMessage = 'No en evento';
        _detailMessage = 'Únete a un evento para comenzar el tracking';
        break;
      case EventStatus.joining:
        _statusMessage = 'Uniéndose...';
        _detailMessage = 'Conectando al evento';
        break;
      case EventStatus.active:
        _statusMessage = '🟢 Tracking Activo';
        _detailMessage =
            widget.currentEvent?.titulo ?? 'Asistencia siendo registrada';
        break;
      case EventStatus.inBreak:
        _statusMessage = '⏸️ En Receso';
        _detailMessage = 'Tracking pausado temporalmente';
        break;
      case EventStatus.outOfArea:
        _statusMessage = '⚠️ Fuera del Área';
        _detailMessage = 'Regresa al área del evento';
        break;
      case EventStatus.connectionLost:
        _statusMessage = '🔴 Sin Conexión';
        _detailMessage = 'Verificando conectividad...';
        break;
      case EventStatus.ended:
        _statusMessage = '🏁 Evento Finalizado';
        _detailMessage = 'Revisa tu historial de asistencia';
        break;
      case EventStatus.error:
        _statusMessage = '❌ Error';
        _detailMessage = 'Toca para reintentar';
        break;
    }
  }

  void _updateAnimations() {
    if (!widget.animated) return;

    // Pulsar para estados que requieren atención
    if (_shouldPulse()) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  bool _shouldPulse() {
    return _currentStatus == EventStatus.outOfArea ||
        _currentStatus == EventStatus.connectionLost ||
        _currentStatus == EventStatus.error;
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _updateStatusInfo();
        });
      }
    });
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case EventStatus.notJoined:
        return AppColors.textGray;
      case EventStatus.joining:
        return AppColors.primaryOrange;
      case EventStatus.active:
        return AppColors.successGreen;
      case EventStatus.inBreak:
        return AppColors.primaryOrange;
      case EventStatus.outOfArea:
        return AppColors.warningOrange;
      case EventStatus.connectionLost:
        return AppColors.errorRed;
      case EventStatus.ended:
        return AppColors.textGray;
      case EventStatus.error:
        return AppColors.errorRed;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case EventStatus.notJoined:
        return Icons.radio_button_unchecked;
      case EventStatus.joining:
        return Icons.sync;
      case EventStatus.active:
        return Icons.my_location;
      case EventStatus.inBreak:
        return Icons.pause_circle;
      case EventStatus.outOfArea:
        return Icons.location_off;
      case EventStatus.connectionLost:
        return Icons.wifi_off;
      case EventStatus.ended:
        return Icons.check_circle;
      case EventStatus.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == EventStatus.notJoined) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: widget.animated
          ? _slideAnimation
          : const AlwaysStoppedAnimation(Offset.zero),
      child: ScaleTransition(
        scale: widget.animated
            ? _pulseAnimation
            : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor().withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono de estado
                    _buildStatusIcon(),

                    const SizedBox(width: 12),

                    // Información de estado
                    Expanded(
                      child: _buildStatusInfo(),
                    ),

                    // Información adicional
                    if (widget.showDetails) _buildAdditionalInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getStatusIcon(),
        color: _getStatusColor(),
        size: 20,
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mensaje principal
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(),
          ),
        ),

        // Mensaje de detalle si está habilitado
        if (widget.showDetails && _detailMessage.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _detailMessage,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tiempo desde última actualización
        if (_lastUpdate != null)
          Text(
            _formatLastUpdate(_lastUpdate!),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textGray.withValues(alpha: 0.7),
            ),
          ),

        const SizedBox(height: 4),

        // Indicador de conexión WebSocket
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _webSocketService.isConnected
                ? AppColors.successGreen.withValues(alpha: 0.1)
                : AppColors.errorRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _webSocketService.isConnected
                      ? AppColors.successGreen
                      : AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _webSocketService.isConnected ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 8,
                  color: _webSocketService.isConnected
                      ? AppColors.successGreen
                      : AppColors.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }
}

/// Widget simplificado para mostrar solo el estado básico
class CompactEventStatusBanner extends StatelessWidget {
  final EventStatus status;
  final String? eventTitle;
  final VoidCallback? onTap;

  const CompactEventStatusBanner({
    super.key,
    required this.status,
    this.eventTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (status == EventStatus.notJoined) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getStatusColor().withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusMessage(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(),
              ),
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Icon(
                Icons.keyboard_arrow_right,
                color: _getStatusColor(),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case EventStatus.notJoined:
        return AppColors.textGray;
      case EventStatus.joining:
        return AppColors.primaryOrange;
      case EventStatus.active:
        return AppColors.successGreen;
      case EventStatus.inBreak:
        return AppColors.primaryOrange;
      case EventStatus.outOfArea:
        return AppColors.warningOrange;
      case EventStatus.connectionLost:
        return AppColors.errorRed;
      case EventStatus.ended:
        return AppColors.textGray;
      case EventStatus.error:
        return AppColors.errorRed;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case EventStatus.notJoined:
        return Icons.radio_button_unchecked;
      case EventStatus.joining:
        return Icons.sync;
      case EventStatus.active:
        return Icons.my_location;
      case EventStatus.inBreak:
        return Icons.pause_circle;
      case EventStatus.outOfArea:
        return Icons.location_off;
      case EventStatus.connectionLost:
        return Icons.wifi_off;
      case EventStatus.ended:
        return Icons.check_circle;
      case EventStatus.error:
        return Icons.error;
    }
  }

  String _getStatusMessage() {
    final eventText = eventTitle != null ? ' - $eventTitle' : '';

    switch (status) {
      case EventStatus.notJoined:
        return 'No en evento';
      case EventStatus.joining:
        return 'Uniéndose$eventText';
      case EventStatus.active:
        return 'Tracking activo$eventText';
      case EventStatus.inBreak:
        return 'En receso$eventText';
      case EventStatus.outOfArea:
        return 'Fuera del área$eventText';
      case EventStatus.connectionLost:
        return 'Sin conexión$eventText';
      case EventStatus.ended:
        return 'Evento finalizado$eventText';
      case EventStatus.error:
        return 'Error en tracking$eventText';
    }
  }
}
