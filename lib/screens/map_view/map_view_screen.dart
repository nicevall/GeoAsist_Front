import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/screens/map_view/map_view_screen.dart - FASE C COMPLETA
// 🎯 INTEGRACIÓN TOTAL CON STUDENTATTENDANCEMANAGER + RESTRICCIONES DE SEGURIDAD
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/permission_service.dart';
import '../../services/student_attendance_manager.dart';
import '../../services/notifications/notification_manager.dart';
import '../../services/background_service.dart';
import '../../utils/colors.dart';
import '../../services/evento_service.dart';
import '../../models/evento_model.dart';
import '../../models/attendance_state_model.dart';
import '../../models/location_response_model.dart';
import 'widgets/map_area.dart';
import 'widgets/control_panel.dart';
import 'widgets/attendance_status_widget.dart';
import 'widgets/grace_period_widget.dart';
import 'widgets/notification_overlay_widget.dart';

class MapViewScreen extends StatefulWidget {
  final bool isAdminMode;
  final String userName;
  final String? eventoId;
  final bool isStudentMode;
  final bool? permissionsValidated;
  final bool? preciseLocationGranted;
  final bool? backgroundPermissionsGranted;
  final bool? batteryOptimizationDisabled;

  const MapViewScreen({
    super.key,
    this.isAdminMode = false,
    this.userName = "Usuario",
    this.eventoId,
    this.isStudentMode = false,
    this.permissionsValidated,
    this.preciseLocationGranted,
    this.backgroundPermissionsGranted,
    this.batteryOptimizationDisabled,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  // 🎯 SERVICIOS PRINCIPALES - FASE C
  final StudentAttendanceManager _attendanceManager =
      StudentAttendanceManager();
  final EventoService _eventoService = EventoService();
  final PermissionService _permissionService = PermissionService();
  final NotificationManager _notificationManager = NotificationManager();
  final BackgroundService _backgroundService = BackgroundService();

  // 🎯 CONTROLADORES DE ANIMACIÓN
  late AnimationController _pulseController;
  late AnimationController _graceController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _graceColorAnimation;

  // 🎯 ESTADO REACTIVO REAL - NO MÁS HARDCODED
  AttendanceState _currentAttendanceState = AttendanceState.initial();
  LocationResponseModel? _currentLocationResponse;

  // 🎯 VARIABLES DE UI Y VALIDACIONES
  bool _isLoading = true;
  bool _hasLocationPermissions = false;
  bool _isRegisteringAttendance = false;
  bool _isTrackingActive = false;

  // 🎯 DATOS BÁSICOS
  Evento? _currentEvento;

  // 🎯 STREAMS SUBSCRIPTIONS CRÍTICOS
  StreamSubscription<AttendanceState>? _stateSubscription;
  StreamSubscription<LocationResponseModel>? _locationSubscription;

  // 🎯 TIMERS PARA VALIDACIONES CONTINUAS
  Timer? _permissionValidationTimer;
  Timer? _heartbeatValidationTimer;

  @override
  void initState() {
    super.initState();
    logger.d(
        '🎯 MapViewScreen iniciando con restricciones de seguridad FASE C');

    // 1. Inicializar animaciones
    _initializeAnimations();

    // 2. Validar argumentos de navegación
    _validateNavigationArguments();

    // 3. Inicializar con restricciones de seguridad
    _initializeWithSecurityValidations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _graceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _graceColorAnimation = ColorTween(
      begin: Colors.orange,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _graceController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat();
  }

  void _validateNavigationArguments() {
    logger.d('🔍 Validando argumentos de navegación:');
    logger.d('   - isStudentMode: ${widget.isStudentMode}');
    logger.d('   - eventoId: ${widget.eventoId}');
    logger.d('   - permissionsValidated: ${widget.permissionsValidated}');
    logger.d('   - preciseLocationGranted: ${widget.preciseLocationGranted}');
    logger.d(
        '   - backgroundPermissionsGranted: ${widget.backgroundPermissionsGranted}');
    logger.d(
        '   - batteryOptimizationDisabled: ${widget.batteryOptimizationDisabled}');

    // ✅ FASE C: Si no vienen validaciones, es acceso directo (no permitido para estudiantes)
    if (widget.isStudentMode && widget.permissionsValidated != true) {
      logger.d(
          '🚨 ACCESO DIRECTO NO PERMITIDO - Redirigiendo a validaciones');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/available-events');
      });
      return;
    }
  }

  Future<void> _initializeWithSecurityValidations() async {
    try {
      setState(() => _isLoading = true);

      // 🔒 PASO 1: RE-VALIDAR PERMISOS CRÍTICOS (incluso si vinieron validados)
      logger.d('🔒 PASO 1: Re-validando permisos críticos...');
      final permissionsValid = await _revalidateAllPermissions();
      if (!permissionsValid) {
        _showCriticalPermissionError();
        return;
      }

      // 🔒 PASO 2: INICIALIZAR SERVICIOS BACKGROUND OBLIGATORIOS
      logger.d('🔒 PASO 2: Inicializando servicios background...');
      await _initializeBackgroundServices();

      // 🔒 PASO 3: CONFIGURAR STUDENTATTENDANCEMANAGER CON RESTRICCIONES
      logger.d('🔒 PASO 3: Configurando StudentAttendanceManager...');
      await _initializeAttendanceManagerWithRestrictions();

      // 🔒 PASO 4: CARGAR EVENTO Y VALIDAR DISPONIBILIDAD
      logger.d('🔒 PASO 4: Cargando evento...');
      await _loadEventWithValidation();

      // 🔒 PASO 5: INICIAR TRACKING CON TODAS LAS RESTRICCIONES
      logger.d('🔒 PASO 5: Iniciando tracking seguro...');
      await _startSecureTracking();

      // 🔒 PASO 6: INICIAR VALIDACIONES CONTINUAS
      logger.d('🔒 PASO 6: Iniciando validaciones continuas...');
      _startContinuousValidations();

      setState(() => _isLoading = false);
      logger.d('✅ MapViewScreen inicializado con todas las restricciones');
    } catch (e) {
      logger.d('❌ Error crítico en inicialización: $e');
      _showCriticalInitializationError(e.toString());
    }
  }

  Future<bool> _revalidateAllPermissions() async {
    try {
      // 1. Ubicación precisa obligatoria
      final hasLocation = await _permissionService.hasLocationPermissions();
      if (!hasLocation) {
        logger.d('❌ Ubicación precisa no otorgada');
        return false;
      }

      // 2. Background permissions obligatorios
      final hasBackground = await _permissionService.canRunInBackground();
      if (!hasBackground) {
        logger.d('❌ Permisos background no otorgados');
        return false;
      }

      // 3. Servicios de ubicación activos
      final servicesEnabled =
          await _permissionService.isLocationServiceEnabled();
      if (!servicesEnabled) {
        logger.d('❌ Servicios de ubicación desactivados');
        return false;
      }

      setState(() => _hasLocationPermissions = true);
      logger.d('✅ Todos los permisos re-validados correctamente');
      return true;
    } catch (e) {
      logger.d('❌ Error re-validando permisos: $e');
      return false;
    }
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      // 1. Inicializar BackgroundService primero
      await _backgroundService.initialize();

      logger.d(
          '✅ Servicios background inicializados (sin ForegroundService aún)');

      // Nota: startForegroundService se llama después en _startSecureTracking()
      // cuando ya tenemos userId y eventId disponibles
    } catch (e) {
      logger.d('❌ Error inicializando servicios background: $e');
      throw Exception('No se pudieron inicializar servicios críticos');
    }
  }

  Future<void> _initializeAttendanceManagerWithRestrictions() async {
    try {
      // 1. Inicializar el manager
      await _attendanceManager.initialize();

      // 2. Configurar listeners reactivos
      _setupReactiveListeners();

      logger.d('✅ StudentAttendanceManager configurado con restricciones');
    } catch (e) {
      logger.d('❌ Error inicializando AttendanceManager: $e');
      throw Exception('Error en sistema de asistencia');
    }
  }

  void _setupReactiveListeners() {
    // 🎯 LISTENER PRINCIPAL DE ESTADO
    _stateSubscription = _attendanceManager.stateStream.listen(
      (AttendanceState newState) {
        if (mounted) {
          setState(() {
            _currentAttendanceState = newState;
            _isTrackingActive =
                newState.trackingStatus == TrackingStatus.active;

            // Actualizar animaciones basadas en estado real
            if (newState.isInGracePeriod) {
              _graceController.repeat();
            } else {
              _graceController.stop();
            }
          });

          // Log crítico para debugging
          logger.d('🎯 Estado actualizado: ${newState.statusText}');
          logger.d('   - Tracking: ${newState.trackingStatus}');
          logger.d('   - Dentro de geofence: ${newState.isInsideGeofence}');
          logger.d('   - Grace period: ${newState.isInGracePeriod}');
          logger.d('   - Puede registrar: ${newState.canRegisterAttendance}');
        }
      },
      onError: (error) {
        logger.d('❌ Error en stream de estado: $error');
        if (mounted) {
          _showErrorSnackBar('Error en tiempo real: $error');
        }
      },
    );

    // 🎯 LISTENER DE UBICACIÓN
    _locationSubscription = _attendanceManager.locationStream.listen(
      (LocationResponseModel locationResponse) {
        if (mounted) {
          setState(() {
            _currentLocationResponse = locationResponse;
          });

          logger.d('📍 Ubicación actualizada:');
          logger.d('   - Distancia: ${locationResponse.formattedDistance}');
          logger.d(
              '   - Dentro geofence: ${locationResponse.insideGeofence}');
          logger.d('   - Evento activo: ${locationResponse.eventActive}');
        }
      },
      onError: (error) {
        logger.d('❌ Error en stream de ubicación: $error');
      },
    );
  }

  Future<void> _loadEventWithValidation() async {
    try {
      if (widget.eventoId == null || widget.eventoId!.isEmpty) {
        throw Exception('ID de evento no proporcionado');
      }

      // 1. Cargar todos los eventos disponibles
      final eventos = await _eventoService.obtenerEventos();

      // 2. Buscar el evento específico
      final evento = eventos.firstWhere(
        (e) => e.id == widget.eventoId,
        orElse: () => throw Exception('Evento no encontrado'),
      );

      // 3. Validar que el evento esté activo
      if (!evento.isActive) {
        throw Exception('Evento no está activo');
      }

      setState(() {
        _currentEvento = evento;
      });

      logger.d('✅ Evento cargado: ${evento.titulo}');
    } catch (e) {
      logger.d('❌ Error cargando evento: $e');
      throw Exception('Error cargando evento: $e');
    }
  }

  Future<void> _startSecureTracking() async {
    try {
      if (_currentEvento == null) {
        throw Exception('No hay evento para iniciar tracking');
      }

      // 1. Validar horarios del evento para tracking
      final now = DateTime.now();
      if (now.isBefore(_currentEvento!.horaInicio)) {
        throw Exception('El evento aún no ha iniciado, no se puede iniciar tracking');
      }
      if (now.isAfter(_currentEvento!.horaFinal)) {
        logger.d('⚠️ Evento terminado, mostrar solo vista de información');
        // No permitir tracking para eventos terminados, pero no lanzar error
        return;
      }

      // 2. Obtener userId del AttendanceManager
      final userId = _attendanceManager.currentState.currentUser?.id;
      if (userId == null) {
        throw Exception('No hay usuario para iniciar tracking');
      }

      // 3. Iniciar ForegroundService con parámetros requeridos
      await _backgroundService.startForegroundService(
        userId: userId,
        eventId: _currentEvento!.id!,
      );

      // 4. Iniciar tracking con evento real
      await _attendanceManager.startEventTracking(_currentEvento!);

      // 5. Mostrar notificación de tracking iniciado
      await _notificationManager.showTrackingActiveNotification();

      setState(() => _isTrackingActive = true);
      logger.d('✅ Tracking seguro iniciado para: ${_currentEvento!.titulo}');
    } catch (e) {
      logger.d('❌ Error iniciando tracking: $e');
      throw Exception('Error iniciando tracking: $e');
    }
  }

  void _startContinuousValidations() {
    // 🔒 VALIDACIÓN DE PERMISOS CADA 10 MINUTOS
    _permissionValidationTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _performPeriodicPermissionValidation(),
    );

    // 🔒 VALIDACIÓN DE HEARTBEAT CADA 30 SEGUNDOS
    _heartbeatValidationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performHeartbeatValidation(),
    );

    logger.d('🔒 Validaciones continuas iniciadas');
  }

  Future<void> _performPeriodicPermissionValidation() async {
    logger.d('🔒 Validación periódica de permisos...');

    final permissionsValid = await _revalidateAllPermissions();
    if (!permissionsValid) {
      logger.d('🚨 Permisos perdidos durante tracking');
      await _handlePermissionLoss();
    }
  }

  Future<void> _performHeartbeatValidation() async {
    if (!_isTrackingActive) return;

    try {
      await _attendanceManager.sendHeartbeatToBackend();
      logger.d('💓 Heartbeat enviado exitosamente');
    } catch (e) {
      logger.d('❌ Falla en heartbeat: $e');
      await _handleHeartbeatFailure();
    }
  }

  Future<void> _handlePermissionLoss() async {
    await _notificationManager.showCriticalAppLifecycleWarning();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Permisos Perdidos'),
            ],
          ),
          content: const Text(
            'Se han perdido permisos críticos durante el tracking. '
            'La asistencia se marcará como perdida.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Salir de MapView
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    await _attendanceManager.stopTracking();
  }

  Future<void> _handleHeartbeatFailure() async {
    await _notificationManager.showAppClosedWarningNotification(30);

    // Intentar reconectarse 3 veces
    int attempts = 0;
    while (attempts < 3 && _isTrackingActive) {
      await Future.delayed(Duration(seconds: 10 * (attempts + 1)));
      try {
        await _attendanceManager.sendHeartbeatToBackend();
        logger.d('✅ Heartbeat recuperado en intento ${attempts + 1}');
        return;
      } catch (e) {
        attempts++;
        logger.d('❌ Falla en reconexión $attempts: $e');
      }
    }

    // Si no se pudo reconectar, marcar como perdida
    logger.d(
        '🚨 No se pudo reconectar heartbeat - marcando asistencia perdida');
    await _attendanceManager.stopTracking();
  }

  // 🎯 MÉTODOS DE ACCIÓN PRINCIPALES

  Future<void> _registerAttendance() async {
    if (_isRegisteringAttendance) return;

    setState(() => _isRegisteringAttendance = true);

    try {
      logger.d('📝 Registrando asistencia con backend real...');

      final success = await _attendanceManager.registerAttendanceWithBackend();

      if (success) {
        await _notificationManager.showAttendanceRegisteredNotification();
        _showSuccessSnackBar('✅ Asistencia registrada exitosamente');
      } else {
        _showErrorSnackBar('❌ Error registrando asistencia');
      }
    } catch (e) {
      logger.d('❌ Error registrando asistencia: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isRegisteringAttendance = false);
    }
  }

  Future<void> _startBreak() async {
    try {
      await _attendanceManager.pauseTracking();
      await _notificationManager.showBreakStartedNotification();
      _showSuccessSnackBar('⏸️ Receso iniciado');
    } catch (e) {
      logger.d('❌ Error iniciando receso: $e');
      _showErrorSnackBar('Error iniciando receso: $e');
    }
  }

  Future<void> _endBreak() async {
    try {
      await _attendanceManager.resumeTracking();
      await _notificationManager.showBreakEndedNotification();
      _showSuccessSnackBar('▶️ Receso terminado');
    } catch (e) {
      logger.d('❌ Error terminando receso: $e');
      _showErrorSnackBar('Error terminando receso: $e');
    }
  }

  Future<void> _refreshData() async {
    try {
      // Forzar actualización del AttendanceManager
      if (_isTrackingActive) {
        // El manager se actualiza automáticamente, solo forzamos un refresh de UI
        setState(() {});
      }
    } catch (e) {
      logger.d('❌ Error refrescando datos: $e');
    }
  }

  // 🎯 UTILIDADES UI

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showCriticalPermissionError() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Permisos Críticos'),
          ],
        ),
        content: const Text(
          'No tienes los permisos necesarios para el tracking de asistencia. '
          'Por favor regresa a la lista de eventos y configura los permisos.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/available-events');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Volver a Eventos'),
          ),
        ],
      ),
    );
  }

  void _showCriticalInitializationError(String error) {
    if (!mounted) return;

    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error Crítico'),
          ],
        ),
        content: Text('Error inicializando tracking:\n\n$error'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Salir de MapView
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    logger.d('🧹 Limpiando MapViewScreen...');

    // Cancelar subscriptions
    _stateSubscription?.cancel();
    _locationSubscription?.cancel();

    // Cancelar timers
    _permissionValidationTimer?.cancel();
    _heartbeatValidationTimer?.cancel();

    // Limpiar animaciones
    _pulseController.dispose();
    _graceController.dispose();

    // Si es estudiante y tracking activo, detener servicios
    if (widget.isStudentMode && _isTrackingActive) {
      _attendanceManager.stopTracking();
      _backgroundService.stopForegroundService();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inicializando tracking seguro...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: const Text(
                'Validando permisos, inicializando servicios background '
                'y configurando restricciones de seguridad.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _currentEvento?.titulo ?? 'Tracking de Asistencia',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0.5,
      actions: [
        // Estado del tracking
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isTrackingActive ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isTrackingActive ? Icons.my_location : Icons.location_off,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                _isTrackingActive ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // 🎯 MAPA PRINCIPAL - DATOS REALES
        MapArea(
          currentEvento: _currentEvento,
          userLat: _currentAttendanceState.userLatitude,
          userLng: _currentAttendanceState.userLongitude,
          isInsideGeofence: _currentAttendanceState.isInsideGeofence,
          isOnBreak:
              _currentAttendanceState.trackingStatus == TrackingStatus.paused,
          pulseAnimation: _pulseAnimation,
        ),

        // 🎯 WIDGET DE ESTADO DE ASISTENCIA
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: AttendanceStatusWidget(
            attendanceState: _currentAttendanceState,
            locationResponse: _currentLocationResponse,
            userName: widget.userName,
            currentEvento: _currentEvento,
          ),
        ),

        // 🎯 WIDGET DE GRACE PERIOD (si está activo)
        if (_currentAttendanceState.isInGracePeriod)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: GracePeriodWidget(
              gracePeriodSeconds: _currentAttendanceState.gracePeriodRemaining,
              graceColorAnimation: _graceColorAnimation,
            ),
          ),

        // 🎯 CONTROLES INFERIORES
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),

        // 🎯 OVERLAY DE NOTIFICACIONES - NUEVO
        NotificationOverlayWidget(
          attendanceState: _currentAttendanceState,
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Indicador de estado superior
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Estado de conexión y GPS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hasLocationPermissions ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasLocationPermissions ? Icons.gps_fixed : Icons.gps_off,
                  size: 10,
                  color: _hasLocationPermissions ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _hasLocationPermissions ? 'GPS Activo' : 'GPS Desactivado',
                    style: TextStyle(
                      fontSize: 9,
                      color: _hasLocationPermissions ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_currentLocationResponse != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '• ${_currentLocationResponse!.formattedDistance}',
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🎯 INFORMACIÓN DE ESTADO PARA ESTUDIANTES (SIN BOTÓN MANUAL)
          if (widget.isStudentMode && _currentEvento != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentAttendanceState.isInsideGeofence 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentAttendanceState.isInsideGeofence 
                        ? Colors.green 
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentAttendanceState.isInsideGeofence 
                          ? Icons.check_circle 
                          : Icons.location_on,
                      color: _currentAttendanceState.isInsideGeofence 
                          ? Colors.green 
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentAttendanceState.isInsideGeofence 
                                ? 'Dentro del área del evento'
                                : 'Fuera del área del evento',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentAttendanceState.isInsideGeofence 
                                ? 'Tu asistencia se registra automáticamente'
                                : 'Acércate al área para registrar asistencia',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 🎯 PANEL DE CONTROL - SOLO PARA ADMINISTRADORES
          if (widget.isAdminMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ControlPanel(
              isAdminMode: widget.isAdminMode,
              isOnBreak: _currentAttendanceState.trackingStatus ==
                  TrackingStatus.paused,
              isAttendanceActive: _currentAttendanceState.trackingStatus ==
                  TrackingStatus.active,
              isInsideGeofence: _currentAttendanceState.isInsideGeofence,
              currentEvento: _currentEvento,
              onStartBreak: _startBreak,
              onEndBreak: _endBreak,
              onRegisterAttendance: _registerAttendance,
              onRefreshData: _refreshData,
            ),
          ),

          const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
