// lib/theme/material3_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/material3_components.dart';

/// 🎨 TEMA MATERIAL 3 ANDROID 15 COMPLETO
/// Implementa el sistema de diseño más reciente de Google
class Material3Theme {
  static const String _fontFamily = 'Roboto';

  /// Tema claro Material 3
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: Material3Colors.lightColorScheme,
    fontFamily: _fontFamily,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Material3Colors.surface,
      foregroundColor: Material3Colors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 3,
      surfaceTintColor: Material3Colors.surfaceVariant,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: Material3Colors.surface,
      surfaceTintColor: Material3Colors.surfaceVariant,
      elevation: 1,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Material3Colors.primary,
        foregroundColor: Material3Colors.onPrimary,
        elevation: 1,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Material3Colors.primary,
        side: const BorderSide(color: Material3Colors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Material3Colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // FloatingActionButton Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Material3Colors.primaryContainer,
      foregroundColor: Material3Colors.onPrimaryContainer,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Material3Colors.surfaceVariant.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Material3Colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Material3Colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Material3Colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Material3Colors.error),
      ),
      labelStyle: const TextStyle(
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
      hintStyle: const TextStyle(
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Material3Colors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Material3Colors.onPrimary),
      side: const BorderSide(color: Material3Colors.outline, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Material3Colors.primary;
        }
        return Material3Colors.outline;
      }),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Material3Colors.onPrimary;
        }
        return Material3Colors.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Material3Colors.primary;
        }
        return Material3Colors.surfaceVariant;
      }),
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
      iconColor: Material3Colors.onSurfaceVariant,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Material3Colors.surface,
      selectedItemColor: Material3Colors.onSecondaryContainer,
      unselectedItemColor: Material3Colors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 3,
    ),

    // Navigation Rail Theme
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Material3Colors.surface,
      selectedIconTheme: IconThemeData(
        color: Material3Colors.onSecondaryContainer,
      ),
      unselectedIconTheme: IconThemeData(
        color: Material3Colors.onSurfaceVariant,
      ),
      selectedLabelTextStyle: TextStyle(
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Material3Colors.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: Material3Colors.surface,
      surfaceTintColor: Material3Colors.surfaceVariant,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C1B1F), // inverseSurface
      contentTextStyle: const TextStyle(
        color: Color(0xFFF4EFF4), // inverseOnSurface
        fontFamily: _fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Material3Colors.primary,
      linearTrackColor: Material3Colors.surfaceVariant,
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Material3Colors.onSurface,
        fontFamily: _fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Material3Colors.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: Material3Colors.background,
    canvasColor: Material3Colors.surface,
    disabledColor: Material3Colors.onSurface.withValues(alpha: 0.38),
  );

  /// Tema oscuro Material 3
  static ThemeData darkTheme = lightTheme.copyWith(
    colorScheme: Material3Colors.darkColorScheme,
    scaffoldBackgroundColor: Material3Colors.darkColorScheme.surface,
    canvasColor: Material3Colors.darkColorScheme.surface,
    
    appBarTheme: lightTheme.appBarTheme.copyWith(
      backgroundColor: Material3Colors.darkColorScheme.surface,
      foregroundColor: Material3Colors.darkColorScheme.onSurface,
      titleTextStyle: lightTheme.appBarTheme.titleTextStyle?.copyWith(
        color: Material3Colors.darkColorScheme.onSurface,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    cardTheme: lightTheme.cardTheme.copyWith(
      color: Material3Colors.darkColorScheme.surface,
      surfaceTintColor: Material3Colors.darkColorScheme.surfaceContainerHighest,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: lightTheme.elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.all(Material3Colors.darkColorScheme.primary),
        foregroundColor: WidgetStateProperty.all(Material3Colors.darkColorScheme.onPrimary),
      ),
    ),

    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
      fillColor: Material3Colors.darkColorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      labelStyle: TextStyle(
        color: Material3Colors.darkColorScheme.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
      hintStyle: TextStyle(
        color: Material3Colors.darkColorScheme.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
    ),

    textTheme: lightTheme.textTheme.apply(
      bodyColor: Material3Colors.darkColorScheme.onSurface,
      displayColor: Material3Colors.darkColorScheme.onSurface,
    ),
  );

  /// Tema adaptativo basado en el sistema
  static ThemeData adaptiveTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}

/// Extensión para colores adicionales de Material 3
extension Material3ColorsExtension on ColorScheme {
  Color get inverseSurface => brightness == Brightness.light 
    ? const Color(0xFF1C1B1F)
    : const Color(0xFFE6E0E9);
    
  Color get inverseOnSurface => brightness == Brightness.light
    ? const Color(0xFFF4EFF4)
    : const Color(0xFF313033);
}