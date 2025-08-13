// lib/widgets/student_notification_widget.dart
// 🔔 WIDGET PARA MOSTRAR NOTIFICACIONES FLOTANTES DE ESTUDIANTES
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/student_notification_model.dart';
import '../services/student_notification_service.dart';
import '../utils/colors.dart';

/// Widget para mostrar notificaciones flotantes en la pantalla
class StudentNotificationWidget extends StatefulWidget {
  /// Widget hijo que será envuelto
  final Widget child;

  /// Posición de las notificaciones flotantes
  final NotificationPosition position;

  /// Máximo número de notificaciones visibles simultáneamente
  final int maxVisibleNotifications;

  const StudentNotificationWidget({
    super.key,
    required this.child,
    this.position = NotificationPosition.top,
    this.maxVisibleNotifications = 3,
  });

  @override
  State<StudentNotificationWidget> createState() =>
      _StudentNotificationWidgetState();
}

class _StudentNotificationWidgetState extends State<StudentNotificationWidget>
    with TickerProviderStateMixin {
  final StudentNotificationService _notificationService =
      StudentNotificationService();
  StreamSubscription<StudentNotification>? _notificationSubscription;

  /// Lista de notificaciones visibles con sus controladores de animación
  final List<_NotificationItem> _visibleNotifications = [];

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _clearAllNotifications();
    super.dispose();
  }

  /// Configurar listener para nuevas notificaciones
  void _setupNotificationListener() {
    _notificationSubscription =
        _notificationService.newNotificationStream.listen(
      _showNotification,
      onError: (error) {
        debugPrint('❌ Error en stream de notificaciones: $error');
      },
    );
  }

  /// Mostrar nueva notificación
  void _showNotification(StudentNotification notification) {
    // No mostrar si ya hay demasiadas notificaciones
    if (_visibleNotifications.length >= widget.maxVisibleNotifications) {
      _removeOldestNotification();
    }

    // Crear controlador de animación para esta notificación
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final slideAnimation = Tween<Offset>(
      begin: _getInitialOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    ));

    final opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    // Crear item de notificación
    final notificationItem = _NotificationItem(
      notification: notification,
      animationController: animationController,
      slideAnimation: slideAnimation,
      opacityAnimation: opacityAnimation,
    );

    setState(() {
      _visibleNotifications.add(notificationItem);
    });

    // Iniciar animación de entrada
    animationController.forward();

    // Programar auto-cierre si no es persistente
    if (!notification.isPersistent && notification.autoCloseDelay != null) {
      Timer(notification.autoCloseDelay!, () {
        _removeNotification(notificationItem);
      });
    }
  }

  /// Obtener offset inicial según la posición
  Offset _getInitialOffset() {
    switch (widget.position) {
      case NotificationPosition.top:
        return const Offset(0, -1);
      case NotificationPosition.bottom:
        return const Offset(0, 1);
      case NotificationPosition.left:
        return const Offset(-1, 0);
      case NotificationPosition.right:
        return const Offset(1, 0);
    }
  }

  /// Remover notificación más antigua
  void _removeOldestNotification() {
    if (_visibleNotifications.isNotEmpty) {
      _removeNotification(_visibleNotifications.first);
    }
  }

  /// Remover notificación específica
  void _removeNotification(_NotificationItem item) {
    if (!_visibleNotifications.contains(item)) return;

    // Animar salida
    item.animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _visibleNotifications.remove(item);
        });
        item.dispose();
      }
    });
  }

  /// Limpiar todas las notificaciones
  void _clearAllNotifications() {
    for (final item in _visibleNotifications) {
      item.dispose();
    }
    _visibleNotifications.clear();
  }

  /// Manejar tap en notificación
  void _handleNotificationTap(_NotificationItem item) {
    // Marcar como leída
    _notificationService.markAsRead(item.notification.id);

    // Ejecutar acción si existe
    if (item.notification.onActionPressed != null) {
      item.notification.onActionPressed!();
    }

    // Remover notificación
    _removeNotification(item);
  }

  /// Manejar swipe para cerrar
  void _handleNotificationDismiss(_NotificationItem item) {
    _removeNotification(item);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Widget hijo principal
        widget.child,

        // Overlay de notificaciones
        if (_visibleNotifications.isNotEmpty) _buildNotificationsOverlay(),
      ],
    );
  }

  /// Construir overlay de notificaciones
  Widget _buildNotificationsOverlay() {
    return Positioned.fill(
      child: SafeArea(
        child: Container(
          padding: _getNotificationsPadding(),
          child: Column(
            mainAxisAlignment: _getMainAxisAlignment(),
            children: _visibleNotifications.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildFloatingNotification(item),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Obtener padding para las notificaciones según posición
  EdgeInsets _getNotificationsPadding() {
    const defaultPadding = 16.0;

    switch (widget.position) {
      case NotificationPosition.top:
        return const EdgeInsets.only(
          top: defaultPadding,
          left: defaultPadding,
          right: defaultPadding,
        );
      case NotificationPosition.bottom:
        return const EdgeInsets.only(
          bottom: defaultPadding,
          left: defaultPadding,
          right: defaultPadding,
        );
      case NotificationPosition.left:
        return const EdgeInsets.only(
          left: defaultPadding,
          top: defaultPadding,
          bottom: defaultPadding,
        );
      case NotificationPosition.right:
        return const EdgeInsets.only(
          right: defaultPadding,
          top: defaultPadding,
          bottom: defaultPadding,
        );
    }
  }

  /// Obtener alineación principal según posición
  MainAxisAlignment _getMainAxisAlignment() {
    switch (widget.position) {
      case NotificationPosition.top:
        return MainAxisAlignment.start;
      case NotificationPosition.bottom:
        return MainAxisAlignment.end;
      case NotificationPosition.left:
      case NotificationPosition.right:
        return MainAxisAlignment.center;
    }
  }

  /// Construir notificación flotante individual
  Widget _buildFloatingNotification(_NotificationItem item) {
    return SlideTransition(
      position: item.slideAnimation,
      child: FadeTransition(
        opacity: item.opacityAnimation,
        child: Dismissible(
          key: Key(item.notification.id),
          direction: _getDismissDirection(),
          onDismissed: (_) => _handleNotificationDismiss(item),
          child: GestureDetector(
            onTap: () => _handleNotificationTap(item),
            child: _FloatingNotificationCard(
              notification: item.notification,
            ),
          ),
        ),
      ),
    );
  }

  /// Obtener dirección de dismiss según posición
  DismissDirection _getDismissDirection() {
    switch (widget.position) {
      case NotificationPosition.top:
      case NotificationPosition.bottom:
        return DismissDirection.horizontal;
      case NotificationPosition.left:
      case NotificationPosition.right:
        return DismissDirection.vertical;
    }
  }
}

/// Item de notificación con sus animaciones
class _NotificationItem {
  final StudentNotification notification;
  final AnimationController animationController;
  final Animation<Offset> slideAnimation;
  final Animation<double> opacityAnimation;

  _NotificationItem({
    required this.notification,
    required this.animationController,
    required this.slideAnimation,
    required this.opacityAnimation,
  });

  void dispose() {
    animationController.dispose();
  }
}

/// Card de notificación flotante
class _FloatingNotificationCard extends StatelessWidget {
  final StudentNotification notification;

  const _FloatingNotificationCard({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 350,
        minHeight: 60,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: notification.displayColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono
                _buildIcon(),
                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: _buildContent(),
                ),

                // Botón de acción o cierre
                if (notification.actionButtonText != null)
                  _buildActionButton(context)
                else
                  _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Obtener color de fondo según prioridad
  Color _getBackgroundColor() {
    switch (notification.priority) {
      case NotificationPriority.critical:
        return Colors.red.shade50;
      case NotificationPriority.high:
        return Colors.orange.shade50;
      case NotificationPriority.normal:
        return Colors.blue.shade50;
      case NotificationPriority.low:
        return Colors.grey.shade100;
    }
  }

  /// Construir icono de la notificación
  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: notification.displayColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        notification.displayIcon,
        color: notification.displayColor,
        size: 20,
      ),
    );
  }

  /// Construir contenido de la notificación
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título
        Text(
          notification.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // Mensaje
        Text(
          notification.message,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
            height: 1.3,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        // Información del evento si está disponible
        if (notification.eventDescription.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            notification.eventDescription,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textGray.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Construir botón de acción
  Widget _buildActionButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: ElevatedButton(
        onPressed: notification.onActionPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: notification.displayColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(60, 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          notification.actionButtonText!,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Construir botón de cierre
  Widget _buildCloseButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: () {
          // El cierre se maneja en el widget padre
        },
        icon: Icon(
          Icons.close,
          size: 16,
          color: AppColors.textGray,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
      ),
    );
  }
}

/// Posiciones donde pueden aparecer las notificaciones
enum NotificationPosition {
  top,
  bottom,
  left,
  right,
}

/// Widget helper para mostrar notificaciones en una lista
class StudentNotificationList extends StatefulWidget {
  /// Altura máxima de la lista
  final double? maxHeight;

  /// Callback cuando se toca una notificación
  final Function(StudentNotification)? onNotificationTap;

  const StudentNotificationList({
    super.key,
    this.maxHeight,
    this.onNotificationTap,
  });

  @override
  State<StudentNotificationList> createState() =>
      _StudentNotificationListState();
}

class _StudentNotificationListState extends State<StudentNotificationList> {
  final StudentNotificationService _notificationService =
      StudentNotificationService();
  StreamSubscription<List<StudentNotification>>? _notificationsSubscription;
  List<StudentNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _setupNotificationsListener();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationsListener() {
    _notificationsSubscription =
        _notificationService.notificationsStream.listen(
      (notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      constraints: widget.maxHeight != null
          ? BoxConstraints(maxHeight: widget.maxHeight!)
          : null,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationListItem(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí cuando estés en un evento',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationListItem(StudentNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _notificationService.removeNotification(notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.grey.shade50
              : notification.displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : notification.displayColor.withValues(alpha: 0.2),
          ),
        ),
        child: ListTile(
          leading: Icon(
            notification.displayIcon,
            color: notification.displayColor,
            size: 24,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textGray.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notification.displayColor,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            if (!notification.isRead) {
              _notificationService.markAsRead(notification.id);
            }
            widget.onNotificationTap?.call(notification);
          },
        ),
      ),
    );
  }
}
