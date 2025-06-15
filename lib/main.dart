import 'package:flutter/material.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'utils/app_router.dart';

void main() {
  runApp(const GeoAssistApp());
}

class GeoAssistApp extends StatelessWidget {
  const GeoAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Material Design 3 Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Navigation Configuration (Simple routing for now)
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.loginRoute,

      // App-wide configurations
      builder: (context, child) {
        return MediaQuery(
          // Prevent font scaling from system settings to maintain UI consistency
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
