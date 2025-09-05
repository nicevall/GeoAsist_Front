// lib/shared/widgets/app_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Standardized card component for the GeoAsist application
/// Provides consistent elevation, border radius, and padding
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;
  final double? elevation;
  final Color? backgroundColor;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final AppCardType type;
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = true,
    this.elevation,
    this.backgroundColor,
    this.shadowColor,
    this.borderRadius,
    this.border,
    this.type = AppCardType.standard,
    this.semanticLabel,
  });

  /// Standard card constructor
  const AppCard.standard({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) : this(
         key: key,
         child: child,
         padding: padding,
         margin: margin,
         onTap: onTap,
         type: AppCardType.standard,
         semanticLabel: semanticLabel,
       );

  /// Event card constructor with specific styling
  const AppCard.event({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) : this(
         key: key,
         child: child,
         padding: padding,
         margin: margin,
         onTap: onTap,
         type: AppCardType.event,
         semanticLabel: semanticLabel,
       );

  /// Attendance card constructor with specific styling
  const AppCard.attendance({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) : this(
         key: key,
         child: child,
         padding: padding,
         margin: margin,
         onTap: onTap,
         type: AppCardType.attendance,
         semanticLabel: semanticLabel,
       );

  /// Outlined card constructor
  const AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) : this(
         key: key,
         child: child,
         padding: padding,
         margin: margin,
         onTap: onTap,
         type: AppCardType.outlined,
         elevated: false,
         semanticLabel: semanticLabel,
       );

  @override
  Widget build(BuildContext context) {
    final cardProperties = _getCardProperties();
    
    Widget card = Container(
      margin: margin ?? cardProperties.margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? cardProperties.backgroundColor,
        borderRadius: borderRadius ?? cardProperties.borderRadius,
        border: border ?? cardProperties.border,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: shadowColor ?? cardProperties.shadowColor,
                  blurRadius: elevation ?? cardProperties.elevation,
                  offset: Offset(0, (elevation ?? cardProperties.elevation) / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? cardProperties.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? cardProperties.borderRadius,
          splashColor: cardProperties.splashColor,
          highlightColor: cardProperties.highlightColor,
          child: Container(
            padding: padding ?? cardProperties.padding,
            child: child,
          ),
        ),
      ),
    );

    // Add semantics if provided
    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }

  _CardProperties _getCardProperties() {
    switch (type) {
      case AppCardType.standard:
        return const _CardProperties(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          elevation: 2,
          shadowColor: Colors.black12,
          splashColor: Colors.black12,
          highlightColor: Colors.black05,
        );
      case AppCardType.event:
        return const _CardProperties(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          backgroundColor: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black12,
          splashColor: AppColors.primary12,
          highlightColor: AppColors.primary05,
        );
      case AppCardType.attendance:
        return const _CardProperties(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          elevation: 1,
          shadowColor: Colors.black12,
          splashColor: AppColors.success12,
          highlightColor: AppColors.success05,
        );
      case AppCardType.outlined:
        return const _CardProperties(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(BorderSide(color: AppColors.outline)),
          elevation: 0,
          shadowColor: Colors.transparent,
          splashColor: Colors.black12,
          highlightColor: Colors.black05,
        );
    }
  }
}

/// Card type enumeration
enum AppCardType {
  standard,
  event,
  attendance,
  outlined,
}

/// Internal class for card properties
class _CardProperties {
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final Border? border;
  final double elevation;
  final Color shadowColor;
  final Color splashColor;
  final Color highlightColor;

  const _CardProperties({
    required this.padding,
    required this.margin,
    required this.backgroundColor,
    required this.borderRadius,
    this.border,
    required this.elevation,
    required this.shadowColor,
    required this.splashColor,
    required this.highlightColor,
  });
}

/// Extension on AppColors for card-specific colors
extension AppColorsCard on AppColors {
  static const Color primary05 = Color(0x0D4ECDC4); // 5% opacity
  static const Color primary12 = Color(0x1F4ECDC4); // 12% opacity
  static const Color success05 = Color(0x0D4CAF50); // 5% opacity
  static const Color success12 = Color(0x1F4CAF50); // 12% opacity
  static const Color outline = Color(0xFFE0E0E0);
  static const Color black05 = Color(0x0D000000); // 5% black
  static const Color black12 = Color(0x1F000000); // 12% black
}