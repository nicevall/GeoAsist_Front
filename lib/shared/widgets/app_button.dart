// lib/shared/widgets/app_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Standard button component for the GeoAsist application
/// Provides consistent styling and behavior across the app
class AppButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final String? semanticLabel;
  final String? tooltip;

  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.semanticLabel,
    this.tooltip,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  /// Primary button constructor
  const AppButton.primary({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isExpanded = false,
    IconData? icon,
    String? semanticLabel,
    String? tooltip,
  }) : this(
         key: key,
         text: text,
         child: child,
         onPressed: onPressed,
         type: AppButtonType.primary,
         size: size,
         isLoading: isLoading,
         isExpanded: isExpanded,
         icon: icon,
         semanticLabel: semanticLabel,
         tooltip: tooltip,
       );

  /// Secondary button constructor
  const AppButton.secondary({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isExpanded = false,
    IconData? icon,
    String? semanticLabel,
    String? tooltip,
  }) : this(
         key: key,
         text: text,
         child: child,
         onPressed: onPressed,
         type: AppButtonType.secondary,
         size: size,
         isLoading: isLoading,
         isExpanded: isExpanded,
         icon: icon,
         semanticLabel: semanticLabel,
         tooltip: tooltip,
       );

  /// Outline button constructor
  const AppButton.outline({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isExpanded = false,
    IconData? icon,
    String? semanticLabel,
    String? tooltip,
  }) : this(
         key: key,
         text: text,
         child: child,
         onPressed: onPressed,
         type: AppButtonType.outline,
         size: size,
         isLoading: isLoading,
         isExpanded: isExpanded,
         icon: icon,
         semanticLabel: semanticLabel,
         tooltip: tooltip,
       );

  /// Text button constructor
  const AppButton.text({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isExpanded = false,
    IconData? icon,
    String? semanticLabel,
    String? tooltip,
  }) : this(
         text: text,
         child: child,
         onPressed: onPressed,
         type: AppButtonType.text,
         size: size,
         isLoading: isLoading,
         isExpanded: isExpanded,
         icon: icon,
         semanticLabel: semanticLabel,
         tooltip: tooltip,
       );

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final buttonChild = _buildButtonChild();
    
    Widget button = _buildButton(buttonStyle, buttonChild);

    // Add semantics
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null && !isLoading,
        child: button,
      );
    }

    // Add tooltip
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    // Make expanded if needed
    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(ButtonStyle style, Widget child) {
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
    }
  }

  ButtonStyle _getButtonStyle() {
    final sizes = _getSizeProperties();
    final colors = _getColorProperties();

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.disabledColor;
          }
          return colors.backgroundColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.disabledForegroundColor;
          }
          return colors.foregroundColor;
        },
      ),
      overlayColor: WidgetStateProperty.all(colors.overlayColor),
      side: colors.borderColor != null 
        ? WidgetStateProperty.all(BorderSide(color: colors.borderColor!))
        : null,
      padding: WidgetStateProperty.all(sizes.padding),
      minimumSize: WidgetStateProperty.all(sizes.minimumSize),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.borderRadius),
        ),
      ),
      elevation: WidgetStateProperty.resolveWith<double>(
        (states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.pressedElevation;
          }
          return colors.elevation;
        },
      ),
      textStyle: WidgetStateProperty.all(sizes.textStyle),
    );
  }

  Widget _buildButtonChild() {
    if (isLoading) {
      return SizedBox(
        height: _getSizeProperties().iconSize,
        width: _getSizeProperties().iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getColorProperties().foregroundColor ?? AppColors.onPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      final iconWidget = Icon(icon, size: _getSizeProperties().iconSize);
      if (text != null || child != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            child ?? Text(text!),
          ],
        );
      }
      return iconWidget;
    }

    return child ?? Text(text!);
  }

  _SizeProperties _getSizeProperties() {
    switch (size) {
      case AppButtonSize.small:
        return const _SizeProperties(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size(64, 32),
          textStyle: AppTextStyles.labelSmall,
          iconSize: 16,
          borderRadius: 6,
        );
      case AppButtonSize.medium:
        return const _SizeProperties(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: Size(88, 44),
          textStyle: AppTextStyles.labelMedium,
          iconSize: 20,
          borderRadius: 8,
        );
      case AppButtonSize.large:
        return const _SizeProperties(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: Size(120, 56),
          textStyle: AppTextStyles.labelLarge,
          iconSize: 24,
          borderRadius: 10,
        );
    }
  }

  _ColorProperties _getColorProperties() {
    switch (type) {
      case AppButtonType.primary:
        return const _ColorProperties(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          overlayColor: Colors.white12,
          disabledColor: Color(0xFFE0E0E0),
          disabledForegroundColor: Color(0xFF9E9E9E),
          elevation: 2,
          pressedElevation: 4,
        );
      case AppButtonType.secondary:
        return const _ColorProperties(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          overlayColor: Colors.white12,
          disabledColor: Color(0xFFE0E0E0),
          disabledForegroundColor: Color(0xFF9E9E9E),
          elevation: 2,
          pressedElevation: 4,
        );
      case AppButtonType.outline:
        return const _ColorProperties(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          overlayColor: Color(0x1A4ECDC4),
          borderColor: AppColors.primary,
          disabledColor: Colors.transparent,
          disabledForegroundColor: Color(0xFF9E9E9E),
          elevation: 0,
          pressedElevation: 0,
        );
      case AppButtonType.text:
        return const _ColorProperties(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          overlayColor: Color(0x1A4ECDC4),
          disabledColor: Colors.transparent,
          disabledForegroundColor: Color(0xFF9E9E9E),
          elevation: 0,
          pressedElevation: 0,
        );
    }
  }
}

/// Button type enumeration
enum AppButtonType {
  primary,
  secondary,
  outline,
  text,
}

/// Button size enumeration
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Internal class for size properties
class _SizeProperties {
  final EdgeInsets padding;
  final Size minimumSize;
  final TextStyle textStyle;
  final double iconSize;
  final double borderRadius;

  const _SizeProperties({
    required this.padding,
    required this.minimumSize,
    required this.textStyle,
    required this.iconSize,
    required this.borderRadius,
  });
}

/// Internal class for color properties
class _ColorProperties {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? overlayColor;
  final Color? borderColor;
  final Color? disabledColor;
  final Color? disabledForegroundColor;
  final double elevation;
  final double pressedElevation;

  const _ColorProperties({
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.borderColor,
    this.disabledColor,
    this.disabledForegroundColor,
    required this.elevation,
    required this.pressedElevation,
  });
}