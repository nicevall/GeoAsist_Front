// lib/core/theme/android_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Android-specific theme optimizations with Material 3 design
/// Optimized for Google Play Store and Android UI guidelines
class AndroidAppTheme {
  /// Material 3 light theme optimized for Android
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    
    // Color scheme from Material 3 guidelines
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryTeal,
      brightness: Brightness.light,
    ),
    
    // Android-specific visual density
    visualDensity: VisualDensity.adaptivePlatformDensity,
    
    // Material 2021 typography for better Android integration
    typography: Typography.material2021(
      platform: TargetPlatform.android,
    ),
    
    // AppBar theme optimized for Android
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false, // Android standard
      titleTextStyle: AppTextStyles.headlineMedium,
      systemOverlayStyle: null, // Let system handle
    ),
    
    // Card theme for consistent Material 3 elevation
    cardTheme: const CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    
    // Button themes optimized for Android touch targets
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(88, 48), // Android minimum touch target
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(88, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(88, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    
    // Input decoration optimized for Android
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Bottom navigation optimized for Android
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedItemColor: AppColors.primaryTeal,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    
    // Dialog theme for consistent Android experience
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      titleTextStyle: AppTextStyles.headlineSmall,
      contentTextStyle: AppTextStyles.bodyMedium,
    ),
    
    // Snackbar theme for Android Material guidelines
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      actionTextColor: AppColors.primaryTeal,
    ),
    
    // FloatingActionButton optimized for Android
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 6,
      highlightElevation: 8,
      shape: CircleBorder(),
    ),
    
    // Drawer theme for Android navigation
    drawerTheme: const DrawerThemeData(
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    ),
    
    // Switch and checkbox themes for Material 3
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryTeal;
          }
          return null;
        },
      ),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryTeal;
          }
          return null;
        },
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryTeal,
      linearTrackColor: Colors.grey,
      circularTrackColor: Colors.grey,
    ),
  );

  /// Material 3 dark theme optimized for Android
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    
    // Dark color scheme from Material 3
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryTeal,
      brightness: Brightness.dark,
    ),
    
    visualDensity: VisualDensity.adaptivePlatformDensity,
    
    typography: Typography.material2021(
      platform: TargetPlatform.android,
    ),
    
    // Dark theme specific configurations
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
    ),
    
    cardTheme: const CardThemeData(
      elevation: 2,
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Dark theme input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade400),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
  );

  /// Get theme based on system brightness
  static ThemeData getThemeForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Android-specific Material 3 color extensions
  static ColorScheme get androidColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primaryTeal,
    brightness: Brightness.light,
  );

  /// Android dark color scheme
  static ColorScheme get androidDarkColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primaryTeal,
    brightness: Brightness.dark,
  );
}