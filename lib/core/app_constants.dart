import 'package:flutter/material.dart';

// Core application constants
class AppConstants {
  // App Information
  static const String appName = 'GeoAsist';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Geo-location based attendance system';

  // API Configuration
  static const String baseUrl =
      'YOUR_NODE_JS_BACKEND_URL'; // Replace with actual backend URL
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Location & Geofencing
  static const double defaultLocationAccuracy = 5.0; // meters
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const Duration graceGeriodDuration = Duration(minutes: 1);
  static const double geofenceRadius = 100.0; // meters
  static const Duration breakTimerInterval = Duration(seconds: 1);

  // Authentication
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userDataKey = 'user_data';

  // User Roles
  static const String adminRole = 'admin';
  static const String attendeeRole = 'attendee';

  // Navigation Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String attendeeDashboardRoute = '/attendee-dashboard';
  static const String mapViewRoute = '/map-view';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';

  // Error Messages
  static const String networkErrorMessage =
      'Network connection error. Please check your internet.';
  static const String locationPermissionDeniedMessage =
      'Location permission is required for attendance tracking.';
  static const String locationServiceDisabledMessage =
      'Please enable location services to continue.';
  static const String invalidCredentialsMessage =
      'Invalid username or password.';
  static const String genericErrorMessage =
      'An unexpected error occurred. Please try again.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Registration successful!';
  static const String attendanceMarkedMessage =
      'Attendance marked successfully.';
  static const String breakStartedMessage = 'Break period started.';
  static const String breakEndedMessage = 'Break period ended.';

  // UI Configuration
  static const double borderRadius = 25.0;
  static const double cardElevation = 5.0;
  static const double buttonHeight = 55.0;
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const EdgeInsets widgetMargin = EdgeInsets.symmetric(vertical: 8.0);

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Map Configuration
  static const double defaultMapZoom = 17.0;
  static const double maxMapZoom = 20.0;
  static const double minMapZoom = 10.0;

  // Break System
  static const List<int> defaultBreakDurations = [5, 10, 15, 30]; // minutes
  static const int maxBreakDuration = 60; // minutes
}
