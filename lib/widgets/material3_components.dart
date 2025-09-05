// lib/widgets/material3_components.dart
import 'package:flutter/material.dart';

/// 🎨 NUEVOS WIDGETS ANDROID 15 MATERIAL 3
/// Implementa los componentes más recientes de Material Design 3
class Material3Components {
  static const String _version = 'Android 15 Material 3';

  /// Badge moderno con soporte para notificaciones
  static Widget modernBadge({
    required Widget child,
    String? label,
    int? count,
    Color? backgroundColor,
    Color? textColor,
    bool isSmall = false,
  }) {
    return Badge(
      label: label != null 
        ? Text(label)
        : count != null 
          ? Text('$count')
          : null,
      backgroundColor: backgroundColor ?? const Color(0xFF6750A4),
      textColor: textColor ?? Colors.white,
      isLabelVisible: label != null || count != null,
      smallSize: isSmall ? 8 : 16,
      child: child,
    );
  }

  /// Segmented Button moderno
  static Widget modernSegmentedButton<T>({
    required Set<T> selected,
    required List<ButtonSegment<T>> segments,
    required ValueChanged<Set<T>> onSelectionChanged,
    bool multiSelectionEnabled = false,
    bool showSelectedIcon = true,
  }) {
    return SegmentedButton<T>(
      segments: segments,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      showSelectedIcon: showSelectedIcon,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE8DEF8);
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFF79747E)),
        ),
      ),
    );
  }

  /// Date Picker moderno con Material 3
  static Future<DateTime?> modernDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      helpText: helpText ?? 'Seleccionar fecha',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6750A4),
              onPrimary: Colors.white,
              surface: const Color(0xFFFEF7FF),
              onSurface: const Color(0xFF1C1B1F),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Time Picker moderno
  static Future<TimeOfDay?> modernTimePicker({
    required BuildContext context,
    TimeOfDay? initialTime,
    String? helpText,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      helpText: helpText ?? 'Seleccionar hora',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFFFEF7FF),
              hourMinuteTextColor: const Color(0xFF1C1B1F),
              dayPeriodTextColor: const Color(0xFF6750A4),
              dialHandColor: const Color(0xFF6750A4),
              dialBackgroundColor: const Color(0xFFE8DEF8),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Card moderna con elevación dinámica
  static Widget modernCard({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? elevation,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Material(
        color: backgroundColor ?? const Color(0xFFFEF7FF),
        elevation: elevation ?? 1,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// FAB extendido moderno
  static Widget modernFAB({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
    bool isExtended = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (isExtended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : null,
        label: Text(label),
        backgroundColor: backgroundColor ?? const Color(0xFF6750A4),
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );
    } else {
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? const Color(0xFF6750A4),
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon ?? Icons.add),
      );
    }
  }

  /// Navigation Rail moderno para tablets/desktop
  static Widget modernNavigationRail({
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    required List<NavigationRailDestination> destinations,
    Widget? leading,
    Widget? trailing,
    bool extended = false,
  }) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      leading: leading,
      trailing: trailing,
      extended: extended,
      backgroundColor: const Color(0xFFFEF7FF),
      selectedIconTheme: const IconThemeData(
        color: Color(0xFF6750A4),
      ),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFF6750A4),
        fontWeight: FontWeight.w500,
      ),
      unselectedIconTheme: const IconThemeData(
        color: Color(0xFF79747E),
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: Color(0xFF79747E),
      ),
    );
  }

  /// Bottom App Bar moderna
  static Widget modernBottomAppBar({
    required List<Widget> actions,
    Widget? floatingActionButton,
    Color? backgroundColor,
    double height = 80,
  }) {
    return BottomAppBar(
      height: height,
      color: backgroundColor ?? const Color(0xFFFEF7FF),
      surfaceTintColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions,
      ),
    );
  }

  /// Menu Anchor moderno (Android 15)
  static Widget modernMenuAnchor({
    required Widget child,
    required List<Widget> menuChildren,
    Offset? alignmentOffset,
  }) {
    return MenuAnchor(
      alignmentOffset: alignmentOffset ?? Offset.zero,
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: menuChildren,
      child: child,
    );
  }

  /// Search Bar moderna (Android 15)
  static Widget modernSearchBar({
    required String hintText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    Widget? leading,
    List<Widget>? trailing,
    TextEditingController? controller,
    bool enabled = true,
  }) {
    return SearchBar(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      leading: leading ?? const Icon(Icons.search),
      trailing: trailing,
      enabled: enabled,
      backgroundColor: WidgetStateProperty.all(const Color(0xFFF7F2FA)),
      elevation: WidgetStateProperty.all(0),
      side: WidgetStateProperty.all(
        const BorderSide(color: Color(0xFFCAC4D0)),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  /// Carousel moderno para imágenes/contenido
  static Widget modernCarousel({
    required List<Widget> items,
    double height = 200,
    bool autoPlay = false,
    Duration autoPlayInterval = const Duration(seconds: 3),
  }) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: items[index],
            ),
          );
        },
      ),
    );
  }

  /// Progress Indicator lineal moderno
  static Widget modernLinearProgress({
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double height = 4,
    String? semanticsLabel,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: backgroundColor ?? const Color(0xFFE8DEF8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(
            valueColor ?? const Color(0xFF6750A4),
          ),
          semanticsLabel: semanticsLabel,
        ),
      ),
    );
  }
}

/// 🎯 SISTEMA DE COLORES MATERIAL 3 ANDROID 15
class Material3Colors {
  // Purple Theme (Primary)
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE8DEF8);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Secondary Colors
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Tertiary Colors
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31101D);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Surface Colors
  static const Color surface = Color(0xFFFEF7FF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Background
  static const Color background = Color(0xFFFEF7FF);
  static const Color onBackground = Color(0xFF1C1B1F);

  // Outline
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  /// Generar ColorScheme completo de Material 3
  static ColorScheme lightColorScheme = const ColorScheme.light(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
  );

  static ColorScheme darkColorScheme = const ColorScheme.dark(
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFE8DEF8),
    secondary: Color(0xFFCBC2DB),
    onSecondary: Color(0xFF332D41),
    secondaryContainer: Color(0xFF4A4458),
    onSecondaryContainer: Color(0xFFE8DEF8),
    tertiary: Color(0xFFEFB8C8),
    onTertiary: Color(0xFF492532),
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD8E4),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF141218),
    onSurface: Color(0xFFE6E0E9),
    surfaceContainerHighest: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
  );
}