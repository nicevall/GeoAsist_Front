// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Centralized color system for GeoAsist app
/// Provides consistent color palette across all UI components
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary brand colors
  static const Color primary = Color(0xFF4ECDC4); // Teal
  static const Color primaryTeal = Color(0xFF4ECDC4); // Teal (alias)
  static const Color primaryDark = Color(0xFF26A69A); // Dark Teal
  static const Color primaryLight = Color(0xFF80CBC4); // Light Teal

  // Secondary colors
  static const Color secondary = Color(0xFFFF6B35); // Orange
  static const Color secondaryDark = Color(0xFFE65100); // Dark Orange
  static const Color secondaryLight = Color(0xFFFFAB91); // Light Orange

  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Amber
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Surface and background colors
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color background = Color(0xFFF5F5F5); // Light Gray
  static const Color surfaceVariant = Color(0xFFF0F0F0); // Variant Gray

  // Text colors
  static const Color onPrimary = Color(0xFFFFFFFF); // White on primary
  static const Color onSecondary = Color(0xFFFFFFFF); // White on secondary
  static const Color onSurface = Color(0xFF212121); // Dark Gray on surface
  static const Color onSurfaceVariant = Color(0xFF757575); // Medium Gray
  
  // Outline colors
  static const Color outline = Color(0xFFE0E0E0); // Light Gray outline
  
  // Alpha variants for Material 3
  static const Color black05 = Color(0x0D000000); // Black 5% alpha
  static const Color primary12 = Color(0x1F4ECDC4); // Primary 12% alpha
  static const Color success12 = Color(0x1F4CAF50); // Success 12% alpha

  // Attendance status colors
  static const Color attendancePresent = success;
  static const Color attendanceAbsent = error;
  static const Color attendanceLate = warning;
  static const Color attendancePending = info;

  // Event status colors
  static const Color eventActive = success;
  static const Color eventScheduled = info;
  static const Color eventCompleted = Color(0xFF9E9E9E); // Gray
  static const Color eventCancelled = error;

  // Utility methods
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'activo':
        return eventActive;
      case 'scheduled':
      case 'programado':
        return eventScheduled;
      case 'completed':
      case 'finalizado':
        return eventCompleted;
      case 'cancelled':
      case 'cancelado':
        return eventCancelled;
      default:
        return onSurfaceVariant;
    }
  }

  static Color getAttendanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'presente':
        return attendancePresent;
      case 'absent':
      case 'ausente':
        return attendanceAbsent;
      case 'late':
      case 'tarde':
        return attendanceLate;
      case 'pending':
      case 'pendiente':
        return attendancePending;
      default:
        return onSurfaceVariant;
    }
  }
}