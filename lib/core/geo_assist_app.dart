// lib/core/geo_assist_app.dart
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones del proyecto
import '../utils/app_router.dart';
import '../utils/colors.dart';
import 'app_constants.dart';
import '../services/student_attendance_manager.dart';

/// 🎯 Widget principal de la aplicación con configuración de routing
class GeoAssistApp extends StatefulWidget {
  const GeoAssistApp({super.key});

  @override
  State<GeoAssistApp> createState() => _GeoAssistAppState();
}

/// 🎯 State de la aplicación con Lifecycle Observer
class _GeoAssistAppState extends State<GeoAssistApp> with WidgetsBindingObserver {
  // ✅ REFERENCIA AL STUDENTATTENDANCEMANAGER
  StudentAttendanceManager? _attendanceManager;

  @override
  void initState() {
    super.initState();

    // ✅ CONFIGURAR LIFECYCLE OBSERVER
    WidgetsBinding.instance.addObserver(this);
    logger.d('🔄 Lifecycle observer activado en GeoAssistApp');

    // ✅ INICIALIZAR REFERENCIA AL STUDENTATTENDANCEMANAGER
    _initializeAttendanceManagerReference();
  }

  // ✅ Obtener referencia al StudentAttendanceManager
  void _initializeAttendanceManagerReference() {
    try {
      // Intentar obtener desde Provider context si está disponible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _attendanceManager = Provider.of<StudentAttendanceManager>(context, listen: false);
          logger.d('✅ Referencia a StudentAttendanceManager inicializada desde Provider');
        } catch (e) {
          // Fallback a singleton si Provider no está disponible
          _attendanceManager = StudentAttendanceManager();
          logger.d('✅ Referencia a StudentAttendanceManager inicializada como singleton');
        }
      });
    } catch (e) {
      logger.d('⚠️ Error inicializando referencia AttendanceManager: $e');
    }
  }

  @override
  void dispose() {
    // ✅ LIMPIAR LIFECYCLE OBSERVER
    WidgetsBinding.instance.removeObserver(this);
    logger.d('🔄 Lifecycle observer desactivado');
    super.dispose();
  }

  /// 🎯 DETECTOR DE CAMBIOS DE LIFECYCLE (CRÍTICO PARA FASE C)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    logger.d('🔄 [LIFECYCLE] Cambio detectado: $state');

    // ✅ CONECTAR CON STUDENTATTENDANCEMANAGER
    if (_attendanceManager != null) {
      _attendanceManager!.handleAppLifecycleChange(state);
      logger.d('📱 Lifecycle enviado a StudentAttendanceManager');
    } else {
      logger.d('⚠️ StudentAttendanceManager no disponible para lifecycle');
    }

    // ✅ MANTENER: Métodos existentes para logging y debugging
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// 🔄 APP RESUMED (REABIERTA) - LOGGING ADICIONAL
  void _handleAppResumed() {
    logger.d('✅ [LIFECYCLE] App reabierta - Reactivando tracking');

    try {
      // ✅ Confirmar que AttendanceManager recibió el evento
      if (_attendanceManager != null) {
        final attendanceState = _attendanceManager!.currentState;
        logger.d('📱 Estado AttendanceManager: ${attendanceState.trackingStatus}');
        logger.d('⏰ Grace period activo: ${attendanceState.isInGracePeriod}');
      }
    } catch (e) {
      logger.d('⚠️ Error verificando servicio: $e');
    }
  }

  /// 🔄 APP PAUSED (EN BACKGROUND) - LOGGING ADICIONAL
  void _handleAppPaused() {
    logger.d('⚠️ [LIFECYCLE] App en background - Continuando tracking');

    try {
      // ✅ Logging del estado de AttendanceManager
      if (_attendanceManager != null) {
        final isTracking = _attendanceManager!.currentState.trackingStatus;
        logger.d('📱 AttendanceManager tracking: $isTracking');
      }
    } catch (e) {
      logger.d('⚠️ Error verificando background service: $e');
    }
  }

  /// 🔄 APP DETACHED (CERRADA) - CRÍTICO PARA FASE 3
  void _handleAppDetached() {
    logger.d('🚨 [LIFECYCLE] App CERRADA - Grace period iniciado automáticamente');

    // ✅ Confirmar que AttendanceManager recibió el evento crítico
    if (_attendanceManager != null) {
      final attendanceState = _attendanceManager!.currentState;
      logger.d('📱 Estado post-detached: ${attendanceState.trackingStatus}');
      logger.d('⏰ Grace period iniciado: ${attendanceState.isInGracePeriod}');
      logger.d('⏱️ Segundos restantes: ${attendanceState.gracePeriodRemaining}');
    } else {
      logger.d('❌ CRÍTICO: AttendanceManager no disponible durante detached');
    }
  }

  /// 🔄 APP INACTIVE (TRANSITORIA)
  void _handleAppInactive() {
    logger.d('⏸️ [LIFECYCLE] App inactiva temporalmente');

    // ✅ Estado transitorio - solo logging
    if (_attendanceManager != null) {
      final isTracking = _attendanceManager!.currentState.trackingStatus;
      logger.d('📱 Tracking durante inactive: $isTracking');
    }
  }

  /// 🔄 APP HIDDEN (MINIMIZADA)
  void _handleAppHidden() {
    logger.d('👁️ [LIFECYCLE] App oculta - Tracking en background activo');

    // ✅ Confirmar estado durante hidden
    if (_attendanceManager != null) {
      final isTracking = _attendanceManager!.currentState.trackingStatus;
      logger.d('📱 Tracking durante hidden: $isTracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // 🎯 CONFIGURACIÓN CRÍTICA PARA ROUTING Y TESTS
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.loginRoute,

      // 🎨 THEME CONFIGURATION MEJORADO
      theme: ThemeData(
        primarySwatch: _createMaterialColor(AppColors.primaryOrange),
        primaryColor: AppColors.primaryOrange,
        scaffoldBackgroundColor: AppColors.lightGray,
        fontFamily: 'Roboto',
        useMaterial3: true,
        
        // ✅ APP BAR THEME
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        // ✅ ELEVATED BUTTON THEME
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
        
        // ✅ INPUT DECORATION THEME
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        
        // ✅ CARD THEME
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // ✅ BUILDER PARA CONFIGURACIONES GLOBALES
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Evitar que el usuario cambie el tamaño del texto
          ),
          child: child!,
        );
      },

      // ✅ CONFIGURACIÓN DE LOCALIZACIÓN (SI ES NECESARIA)
      // locale: const Locale('es', 'ES'),
      // localizationsDelegates: const [...],
      // supportedLocales: const [...],
    );
  }

  // ✅ Helper para crear Material Color
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255.0).round() & 0xff;
    final int g = (color.g * 255.0).round() & 0xff;
    final int b = (color.b * 255.0).round() & 0xff;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor((r << 16) | (g << 8) | b | 0xFF000000, swatch);
  }
}