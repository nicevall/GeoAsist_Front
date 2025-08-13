// lib/widgets/notifications/notification_overlay.dart
// 🚨 OVERLAY PARA NOTIFICACIONES CRÍTICAS DE ESTUDIANTES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../../models/student_notification_model.dart';
import '../../services/student_notification_service.dart';
import '../../utils/colors.dart';
import '../../services/notifications/student_notification_types.dart';

/// Overlay modal para mostrar notificaciones críticas que requieren atención inmediata
class NotificationOverlay extends StatefulWidget {
  /// Notificación a mostrar
  final StudentNotification notification;

  /// Callback cuando se cierra el overlay
  final VoidCallback? onDismiss;

  /// Callback cuando se ejecuta la acción principal
  final VoidCallback? onAction;

  /// Si permite cerrar tocando fuera del overlay
  final bool dismissible;

  /// Duración del countdown si es aplicable
  final Duration? countdownDuration;

  const NotificationOverlay({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onAction,
    this.dismissible = true,
    this.countdownDuration,
  });

  /// Mostrar overlay crítico como modal
  static Future<void> showCritical({
    required BuildContext context,
    required StudentNotification notification,
    VoidCallback? onDismiss,
    VoidCallback? onAction,
    bool dismissible = false,
    Duration? countdownDuration,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => NotificationOverlay(
        notification: notification,
        onDismiss: onDismiss,
        onAction: onAction,
        dismissible: dismissible,
        countdownDuration: countdownDuration,
      ),
    );
  }

  /// Mostrar overlay de advertencia de cierre de app
  static Future<void> showAppClosedWarning({
    required BuildContext context,
    required String eventTitle,
    required String eventId,
    required int secondsRemaining,
    VoidCallback? onReopenApp,
  }) async {
    final notification = StudentNotificationFactory.appClosedWarning(
      eventTitle: eventTitle,
      eventId: eventId,
      secondsRemaining: secondsRemaining,
    );

    return showCritical(
      context: context,
      notification: notification,
      dismissible: false,
      countdownDuration: Duration(seconds: secondsRemaining),
      onAction: onReopenApp,
    );
  }

  /// Mostrar overlay de pérdida de conectividad
  static Future<void> showConnectivityLost({
    required BuildContext context,
    required String eventTitle,
    required String eventId,
    VoidCallback? onRetry,
  }) async {
    final notification = StudentNotificationFactory.connectivityLost(
      eventTitle: eventTitle,
      eventId: eventId,
    );

    return showCritical(
      context: context,
      notification: notification,
      dismissible: true,
      onAction: onRetry,
    );
  }

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _setupCountdown();
    _triggerHapticFeedback();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    // Animación de escala para entrada
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Animación de shake para notificaciones urgentes
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Animación de pulso para elementos críticos
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    // Iniciar animación de entrada
    _scaleController.forward();

    // Para notificaciones críticas, agregar shake
    if (widget.notification.isCritical) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _shakeController.repeat(reverse: true);
        }
      });
    }

    // Pulso continuo para notificaciones que requieren acción
    if (widget.notification.requiresAction) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _setupCountdown() {
    if (widget.countdownDuration != null) {
      _remainingSeconds = widget.countdownDuration!.inSeconds;

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;

            if (_remainingSeconds <= 0) {
              timer.cancel();
              _handleTimeout();
            }
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _triggerHapticFeedback() {
    if (widget.notification.isCritical) {
      HapticFeedback.heavyImpact();

      // Vibración adicional crítica
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _handleTimeout() {
    if (widget.dismissible) {
      _handleDismiss();
    }
  }

  void _handleDismiss() {
    _scaleController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  void _handleAction() {
    widget.onAction?.call();
    _handleDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.dismissible,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: widget.notification.isCritical
                      ? Offset(_shakeAnimation.value, 0)
                      : Offset.zero,
                  child: _buildOverlayContent(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 350,
        minHeight: 200,
      ),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: widget.notification.displayColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con icono y título
          _buildHeader(),

          // Contenido principal
          _buildContent(),

          // Countdown si aplica
          if (_remainingSeconds > 0) _buildCountdown(),

          // Botones de acción
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.notification.displayColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          // Icono animado
          ScaleTransition(
            scale: widget.notification.requiresAction
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.notification.displayColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.notification.displayIcon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Título y prioridad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.notification.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        widget.notification.displayColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.notification.priority.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.notification.displayColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón de cierre si es dismissible
          if (widget.dismissible)
            IconButton(
              onPressed: _handleDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: AppColors.textGray,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensaje principal
          Text(
            widget.notification.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),

          // Información del evento si está disponible
          if (widget.notification.eventDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.notification.eventDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Datos adicionales si existen
          if (widget.notification.additionalData != null)
            _buildAdditionalData(),
        ],
      ),
    );
  }

  Widget _buildAdditionalData() {
    final data = widget.notification.additionalData!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '${entry.key}: ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Tiempo restante: $_remainingSeconds segundos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Botón secundario (cerrar/cancelar)
          if (widget.dismissible)
            Expanded(
              child: OutlinedButton(
                onPressed: _handleDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textGray,
                  side: BorderSide(color: AppColors.lightGray),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),

          if (widget.dismissible &&
              widget.notification.actionButtonText != null)
            const SizedBox(width: 12),

          // Botón principal (acción)
          if (widget.notification.actionButtonText != null)
            Expanded(
              flex: widget.dismissible ? 2 : 1,
              child: ElevatedButton(
                onPressed: _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.notification.displayColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.notification.actionButtonText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget helper para mostrar overlay directamente en el widget tree
class NotificationOverlayProvider extends StatefulWidget {
  final Widget child;

  const NotificationOverlayProvider({
    super.key,
    required this.child,
  });

  @override
  State<NotificationOverlayProvider> createState() =>
      _NotificationOverlayProviderState();
}

class _NotificationOverlayProviderState
    extends State<NotificationOverlayProvider> {
  final StudentNotificationService _notificationService =
      StudentNotificationService();
  StreamSubscription<StudentNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    _notificationSubscription =
        _notificationService.newNotificationStream.listen(
      _handleNotification,
    );
  }

  void _handleNotification(StudentNotification notification) {
    // Solo mostrar overlays para notificaciones críticas
    if (!notification.isCritical && !notification.requiresAction) {
      return;
    }

    // Verificar que el context esté disponible
    if (!mounted) return;

    // Mostrar overlay apropiado según el tipo
    switch (notification.type) {
      case StudentNotificationType.appClosedWarning:
        _showAppClosedWarning(notification);
        break;
      case StudentNotificationType.connectivityLost:
        _showConnectivityLostOverlay(notification);
        break;
      case StudentNotificationType.exitedArea:
        _showExitedAreaOverlay(notification);
        break;
      default:
        if (notification.isCritical) {
          _showGenericCriticalOverlay(notification);
        }
        break;
    }
  }

  void _showAppClosedWarning(StudentNotification notification) {
    // Extraer segundos restantes del mensaje si es posible
    final RegExp regex = RegExp(r'(\d+)s restantes');
    final match = regex.firstMatch(notification.message);
    final secondsRemaining =
        match != null ? int.tryParse(match.group(1)!) ?? 30 : 30;

    NotificationOverlay.showAppClosedWarning(
      context: context,
      eventTitle: notification.eventTitle ?? 'Evento',
      eventId: notification.eventId ?? '',
      secondsRemaining: secondsRemaining,
      onReopenApp: notification.onActionPressed,
    );
  }

  void _showConnectivityLostOverlay(StudentNotification notification) {
    NotificationOverlay.showConnectivityLost(
      context: context,
      eventTitle: notification.eventTitle ?? 'Evento',
      eventId: notification.eventId ?? '',
      onRetry: notification.onActionPressed,
    );
  }

  void _showExitedAreaOverlay(StudentNotification notification) {
    NotificationOverlay.showCritical(
      context: context,
      notification: notification,
      dismissible: true,
      onAction: notification.onActionPressed,
    );
  }

  void _showGenericCriticalOverlay(StudentNotification notification) {
    NotificationOverlay.showCritical(
      context: context,
      notification: notification,
      dismissible: !notification.isPersistent,
      onAction: notification.onActionPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
