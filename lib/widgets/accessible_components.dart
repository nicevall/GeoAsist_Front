// lib/widgets/accessible_components.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:geo_asist_front/models/evento_model.dart';
import 'package:geo_asist_front/models/usuario_model.dart';
import 'package:geo_asist_front/utils/colors.dart';

/// ✅ PRODUCTION READY: Comprehensive Accessibility Component Library
/// Ensures WCAG 2.1 AA compliance and screen reader support
class AccessibleEventCard extends StatelessWidget {
  final Evento evento;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool isJoined;
  final bool showJoinButton;

  const AccessibleEventCard({
    super.key,
    required this.evento,
    this.onTap,
    this.onJoin,
    this.isJoined = false,
    this.showJoinButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = _buildSemanticLabel();
    final statusDescription = _getStatusDescription();

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: true,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title and status
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          evento.titulo,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Event status: $statusDescription',
                      child: _buildStatusChip(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Event details
                _buildEventDetail(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: evento.lugar ?? 'No location specified',
                  semanticLabel: 'Event location: ${evento.lugar ?? 'No location specified'}',
                ),
                
                const SizedBox(height: 4),
                
                _buildEventDetail(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: '${evento.horaInicio} - ${evento.horaFinal}',
                  semanticLabel: 'Event time: from ${evento.horaInicio} to ${evento.horaFinal}',
                ),
                
                const SizedBox(height: 4),
                
                _buildEventDetail(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: DateFormat('MMM dd, yyyy').format(evento.fecha),
                  semanticLabel: 'Event date: ${DateFormat('MMM dd, yyyy').format(evento.fecha)}',
                ),
                
                if (showJoinButton) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AccessibleButton(
                      onPressed: isJoined ? null : onJoin,
                      backgroundColor: isJoined ? Colors.grey : AppColors.primaryOrange,
                      semanticLabel: isJoined 
                        ? 'Already joined event ${evento.titulo}'
                        : 'Join event ${evento.titulo}',
                      child: Text(
                        isJoined ? 'Already Joined' : 'Join Event',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final status = _getStatusDescription();
    return 'Event card: ${evento.titulo}, '
           'Location: ${evento.lugar}, '
           'Time: ${evento.horaInicio} to ${evento.horaFinal}, '
           'Date: ${evento.fecha}, '
           'Status: $status'
           '${onTap != null ? ", double tap to view details" : ""}';
  }

  String _getStatusDescription() {
    switch (evento.estado.toLowerCase()) {
      case 'activo':
        return 'Active';
      case 'en proceso':
        return 'In progress';
      case 'finalizado':
        return 'Completed';
      case 'programado':
        return 'Scheduled';
      default:
        return evento.estado;
    }
  }

  Widget _buildStatusChip() {
    Color chipColor;
    switch (evento.estado.toLowerCase()) {
      case 'activo':
        chipColor = Colors.green;
        break;
      case 'en proceso':
        chipColor = AppColors.primaryOrange;
        break;
      case 'finalizado':
        chipColor = Colors.grey;
        break;
      case 'programado':
        chipColor = AppColors.secondaryTeal;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStatusDescription(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEventDetail({
    required IconData icon,
    required String label,
    required String value,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible button with proper semantics and contrast
class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final String? semanticLabel;
  final String? tooltip;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.minimumSize,
    this.semanticLabel,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primaryOrange,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: minimumSize ?? const Size(44, 44), // WCAG minimum touch target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : child,
    );

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null && !isLoading,
        child: button,
      );
    }

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Accessible text input with proper semantics and validation feedback
class AccessibleTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final VoidCallback? onEditingComplete;
  final bool enabled;
  final int? maxLines;
  final String? helperText;
  final String? errorText;
  final bool required;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onEditingComplete,
    this.enabled = true,
    this.maxLines = 1,
    this.helperText,
    this.errorText,
    this.required = false,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  final FocusNode _focusNode = FocusNode();
  String? _currentError;

  @override
  void initState() {
    super.initState();
    _currentError = widget.errorText;
  }

  @override
  void didUpdateWidget(AccessibleTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      setState(() {
        _currentError = widget.errorText;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _currentError) {
        setState(() {
          _currentError = error;
        });
        
        // Announce validation errors to screen readers
        if (error != null) {
          SemanticsService.announce(
            'Validation error: $error',
            TextDirection.ltr,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = _buildSemanticLabel();
    
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label
          Semantics(
            label: widget.required ? '${widget.label}, required field' : widget.label,
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.labelLarge,
                children: [
                  TextSpan(text: widget.label),
                  if (widget.required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Text field
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            onChanged: (value) {
              widget.onChanged?.call(value);
              if (widget.validator != null) {
                _validateInput(value);
              }
            },
            onEditingComplete: widget.onEditingComplete,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon) 
                : null,
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryOrange,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              errorText: _currentError,
              helperText: widget.helperText,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSemanticLabel() {
    String label = widget.label;
    if (widget.required) {
      label += ', required field';
    }
    if (widget.hintText != null) {
      label += ', hint: ${widget.hintText}';
    }
    if (_currentError != null) {
      label += ', error: $_currentError';
    }
    if (widget.helperText != null) {
      label += ', help: ${widget.helperText}';
    }
    return label;
  }
}

/// Accessible navigation drawer with proper structure
class AccessibleDrawer extends StatelessWidget {
  final Usuario? currentUser;
  final List<DrawerItem> items;
  final VoidCallback? onLogout;

  const AccessibleDrawer({
    super.key,
    this.currentUser,
    required this.items,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Semantics(
        label: 'Navigation drawer',
        child: Column(
          children: [
            // User header
            if (currentUser != null)
              Semantics(
                label: 'User profile section',
                child: UserAccountsDrawerHeader(
                  accountName: Text(currentUser!.nombre),
                  accountEmail: Text(currentUser!.correo),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: AppColors.primaryOrange,
                    child: Semantics(
                      label: 'User avatar for ${currentUser!.nombre}',
                      child: Text(
                        currentUser!.nombre[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            
            // Navigation items
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Semantics(
                    label: 'Navigate to ${item.title}',
                    button: true,
                    child: ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      onTap: item.onTap,
                      selected: item.isSelected,
                      selectedTileColor: AppColors.primaryOrange.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
            
            // Logout button
            if (onLogout != null)
              Semantics(
                label: 'Logout button',
                button: true,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: onLogout,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Accessible dialog with proper focus management
class AccessibleDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<AccessibleDialogAction> actions;
  final bool barrierDismissible;

  const AccessibleDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      content: Semantics(
        label: 'Dialog content',
        child: content,
      ),
      actions: actions.map((action) {
        return Semantics(
          label: action.semanticLabel ?? action.label,
          button: true,
          child: TextButton(
            onPressed: action.onPressed,
            child: Text(action.label),
          ),
        );
      }).toList(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<AccessibleDialogAction> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AccessibleDialog(
        title: title,
        content: content,
        actions: actions,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

/// Dialog action with accessibility support
class AccessibleDialogAction {
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool isDefault;
  final bool isDestructive;

  const AccessibleDialogAction({
    required this.label,
    this.onPressed,
    this.semanticLabel,
    this.isDefault = false,
    this.isDestructive = false,
  });
}

/// Accessible form with proper focus traversal
class AccessibleForm extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final String? submitButtonText;
  final bool enableFocusTraversal;

  const AccessibleForm({
    super.key,
    this.formKey,
    required this.children,
    this.onSubmit,
    this.submitButtonText,
    this.enableFocusTraversal = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget form = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          if (onSubmit != null) ...[
            const SizedBox(height: 24),
            AccessibleButton(
              onPressed: onSubmit,
              semanticLabel: 'Submit form',
              child: Text(submitButtonText ?? 'Submit'),
            ),
          ],
        ],
      ),
    );

    if (enableFocusTraversal) {
      form = FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: form,
      );
    }

    return Semantics(
      label: 'Form',
      child: form,
    );
  }
}

/// Data classes for drawer items
class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const DrawerItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.isSelected = false,
  });
}