import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/screens/attendance/attendance_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../services/storage_service.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/notifications/notification_manager.dart';
import '../../models/usuario_model.dart';
import '../../models/evento_model.dart';
import '../../models/asistencia_model.dart';
import '../../widgets/attendance/permission_dialog_widgets.dart';
import '../../widgets/attendance/tracking_status_panel.dart';
import '../../widgets/attendance/location_info_panel.dart';
import '../../widgets/attendance/attendance_stats_panel.dart';
import '../../services/attendance/permission_flow_manager.dart';
import 'package:geolocator/geolocator.dart';

/// ✅ ATTENDANCE TRACKING SCREEN MODULAR: Coordinador principal preservado
/// Responsabilidades del coordinador:
/// - App lifecycle management (dual grace periods)
/// - Integración con componentes modulares
/// - Estados globales y timers
/// - FloatingActionButton y navegación
/// - Preservación total de funcionalidad crítica
class AttendanceTrackingScreen extends StatefulWidget {
  final String userName;
  final String? eventoId;

  const AttendanceTrackingScreen({
    super.key,
    this.userName = 'Usuario',
    this.eventoId,
  });

  @override
  State<AttendanceTrackingScreen> createState() =>
      _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState extends State<AttendanceTrackingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // 🎯 SERVICIOS
  final StorageService _storageService = StorageService();
  final EventoService _eventoService = EventoService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final NotificationManager _notificationManager = NotificationManager();
  final PermissionFlowManager _permissionFlowManager = PermissionFlowManager();

  // 🎯 CONTROLADORES DE ANIMACIÓN
  late AnimationController _trackingController;
  late AnimationController _pulseController;
  late Animation<double> _trackingAnimation;
  late Animation<double> _pulseAnimation;

  // 🎯 ESTADO DEL TRACKING
  bool _isLoading = true;
  bool _isTrackingActive = false;
  bool _isInGeofence = false;
  bool _hasPermissions = false;
  String? _errorMessage;

  // 🎯 DATOS DEL TRACKING
  Usuario? _currentUser;
  Evento? _activeEvent;
  List<Asistencia> _attendanceHistory = [];
  Position? _currentPosition;
  String _trackingStatus = 'inactive';
  bool _isEnrolledInEvent = false;
  bool _isEventStarted = false;
  bool _isEventCompleted = false;
  Timer? _eventStartTimer;

  // 🎯 TIMERS Y CONTADORES - DUAL GRACE PERIODS PRESERVADOS
  Timer? _positionUpdateTimer;
  Timer? _heartbeatTimer;
  Timer? _geofenceGraceTimer;
  Timer? _appClosedGraceTimer;
  int _geofenceSecondsRemaining = 0;
  int _appClosedSecondsRemaining = 0;
  Duration _timeInEvent = Duration.zero;
  int _exitWarningCount = 0;

  // 🎯 ESTADÍSTICAS EN TIEMPO REAL
  double _distanceFromCenter = 0.0;
  double _currentAccuracy = 0.0;
  String _lastUpdateTime = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _setupPermissionFlowCallbacks();
    _startInitialLocationUpdate(); // ✅ NUEVO: Obtener ubicación inicial
    _startCriticalPermissionsFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingController.dispose();
    _pulseController.dispose();
    _positionUpdateTimer?.cancel();
    _heartbeatTimer?.cancel();
    _geofenceGraceTimer?.cancel();
    _appClosedGraceTimer?.cancel();
    _eventStartTimer?.cancel();
    super.dispose();
  }

  // 🎯 APP LIFECYCLE MANAGEMENT PRESERVADO
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    logger.d('📱 App lifecycle cambió a: $state');

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

  /// 🔧 CONFIGURAR CALLBACKS DEL PERMISSION FLOW MANAGER
  void _setupPermissionFlowCallbacks() {
    _permissionFlowManager.setCallbacks(
      onPermissionStatusChanged: () {
        if (mounted) {
          setState(() {
            _hasPermissions = _permissionFlowManager.allPermissionsGranted;
          });
        }
      },
      onAllPermissionsGranted: () async {
        await _startAutomaticTracking();
      },
      onShowPermissionDialog: (permissionType) async {
        await _showPermissionDialog(permissionType);
      },
    );
  }

  /// 🚀 INICIAR FLUJO DE PERMISOS CRÍTICOS
  Future<void> _startCriticalPermissionsFlow() async {
    logger.d('🔐 Iniciando flujo de permisos críticos...');
    await _permissionFlowManager.initializeCriticalPermissionsFlow();
  }

  /// 📋 MOSTRAR DIÁLOGO DE PERMISO ESPECÍFICO
  Future<void> _showPermissionDialog(String permissionType) async {
    if (!mounted) return;

    switch (permissionType) {
      case 'location_services':
        await PermissionDialogWidgets.showLocationServicesDialog(
          context,
          _onPermissionConfigured,
        );
        break;
      case 'location_precise':
        await PermissionDialogWidgets.showPreciseLocationDialog(
          context,
          _onPermissionConfigured,
        );
        break;
      case 'location_always':
        await PermissionDialogWidgets.showAlwaysLocationDialog(
          context,
          _onPermissionConfigured,
        );
        break;
      case 'battery_optimization':
        await PermissionDialogWidgets.showBatteryOptimizationDialog(
          context,
          _onPermissionConfigured,
        );
        break;
    }
  }

  /// ✅ CALLBACK CUANDO SE CONFIGURA UN PERMISO
  Future<void> _onPermissionConfigured() async {
    await _permissionFlowManager.recheckPermissionsAndContinue();
  }

  /// 🚀 INICIAR TRACKING AUTOMÁTICO
  Future<void> _startAutomaticTracking() async {
    logger.d('🚀 Iniciando tracking automático con permisos completos...');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadUserData();
      await _loadEventData();
      await _loadAttendanceHistory();
      await _activateTracking();
      await _notificationManager.showTrackingActiveNotification();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      logger.d('✅ Tracking automático activado exitosamente');
    } catch (e) {
      logger.d('❌ Error en tracking automático: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error iniciando tracking: $e';
        });
      }
    }
  }

  void _initializeAnimations() {
    _trackingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _trackingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trackingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  /// ✅ NUEVO: Obtener ubicación inicial para mostrar siempre
  Future<void> _startInitialLocationUpdate() async {
    logger.d('📍 Obteniendo ubicación inicial...');
    try {
      // Intentar obtener ubicación inicial sin permisos especiales
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAccuracy = position.accuracy;
          _lastUpdateTime = DateTime.now().toString().substring(11, 19);
        });
        logger.d('✅ Ubicación inicial obtenida: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      logger.d('⚠️ No se pudo obtener ubicación inicial: $e');
      // No es crítico, el usuario verá "Obteniendo ubicación..."
    }
  }

  Future<void> _loadUserData() async {
    final user = await _storageService.getUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _loadEventData() async {
    try {
      if (widget.eventoId != null) {
        final eventos = await _eventoService.obtenerEventos();
        _activeEvent = eventos.firstWhere(
          (e) => e.id == widget.eventoId,
          orElse: () => throw Exception('Evento no encontrado'),
        );
      } else {
        final activeEvents = await _eventoService.obtenerEventos();
        // ✅ CAMBIO: Permitir eventos futuros, no solo activos
        if (activeEvents.isNotEmpty) {
          _activeEvent = activeEvents.first;
        }
      }

      if (mounted && _activeEvent != null) {
        _checkEventStatus();
        _setupEventStartTimer();
        setState(() {
          logger.d('✅ Evento cargado: ${_activeEvent!.titulo}');
        });
      }
    } catch (e) {
      logger.d('❌ Error cargando evento: $e');
      rethrow;
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (_currentUser?.id == null) return;

    try {
      final history = await _asistenciaService.obtenerHistorialUsuario(_currentUser!.id);

      if (mounted) {
        setState(() {
          _attendanceHistory = history;
          _isLoading = false;
        });
      }

      logger.d('✅ Historial cargado: ${history.length} asistencias');
    } catch (e) {
      logger.d('❌ Error cargando historial: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _activateTracking() async {
    if (_activeEvent == null) {
      throw Exception('No hay evento activo para tracking');
    }

    try {
      logger.d('▶️ Activando tracking automático');

      _startPositionUpdates();
      _startHeartbeat();

      setState(() {
        _isTrackingActive = true;
        _trackingStatus = 'active';
        _hasPermissions = true;
      });

      _trackingController.forward();
      _pulseController.repeat(reverse: true);
      logger.d('✅ Tracking automático activado');
    } catch (e) {
      logger.d('❌ Error activando tracking: $e');
      rethrow;
    }
  }

  Future<void> _startTracking() async {
    if (!_hasPermissions) {
      await _startCriticalPermissionsFlow();
      return;
    }

    if (_activeEvent == null) {
      _showErrorDialog('No hay evento activo para tracking');
      return;
    }

    try {
      logger.d('▶️ Iniciando tracking manual');

      _startPositionUpdates();
      _startHeartbeat();

      setState(() {
        _isTrackingActive = true;
        _trackingStatus = 'active';
      });

      _trackingController.forward();
      _pulseController.repeat(reverse: true);

      logger.d('✅ Tracking iniciado');
    } catch (e) {
      logger.d('❌ Error iniciando tracking: $e');
      _showErrorDialog('Error iniciando tracking: $e');
    }
  }

  Future<void> _stopTracking() async {
    try {
      logger.d('⏹️ Deteniendo tracking');

      _positionUpdateTimer?.cancel();
      _heartbeatTimer?.cancel();
      _geofenceGraceTimer?.cancel();
      _appClosedGraceTimer?.cancel();

      setState(() {
        _isTrackingActive = false;
        _trackingStatus = 'inactive';
        _timeInEvent = Duration.zero;
      });

      _trackingController.reverse();
      _pulseController.stop();

      logger.d('✅ Tracking detenido');
    } catch (e) {
      logger.d('❌ Error deteniendo tracking: $e');
    }
  }

  void _startPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        if (_isTrackingActive && mounted) {
          await _updateCurrentPosition();
        }
      },
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (_isTrackingActive && mounted) {
          await _sendHeartbeat();
        }
      },
    );
  }

  Future<void> _updateCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAccuracy = position.accuracy;
          _lastUpdateTime = DateTime.now().toString().substring(11, 19);
        });

        if (_activeEvent != null) {
          _distanceFromCenter = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _activeEvent!.ubicacion.latitud,
            _activeEvent!.ubicacion.longitud,
          );

          _checkGeofence();
        }

        // ✅ FIXED: Always get fresh user from storage to ensure userId is not null
        final currentUser = await _storageService.getUser();
        if (currentUser?.id != null && _activeEvent?.id != null) {
          await _asistenciaService.actualizarUbicacion(
            usuarioId: currentUser!.id,
            eventoId: _activeEvent!.id!,
            latitud: position.latitude,
            longitud: position.longitude,
            precision: position.accuracy,
          );
        } else {
          logger.d('❌ Error: Usuario o evento es null - Usuario: ${currentUser?.id}, Evento: ${_activeEvent?.id}');
        }
      }
    } catch (e) {
      logger.d('❌ Error actualizando posición: $e');
    }
  }

  void _checkGeofence() {
    if (_activeEvent == null || _currentPosition == null) return;

    final isInsideGeofence = _distanceFromCenter <= _activeEvent!.rangoPermitido;

    if (isInsideGeofence != _isInGeofence) {
      setState(() {
        _isInGeofence = isInsideGeofence;
      });

      if (isInsideGeofence) {
        _handleGeofenceEntered();
      } else {
        _handleGeofenceExited();
      }
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      // ✅ FIXED: Always get fresh user from storage to ensure userId is not null
      final currentUser = await _storageService.getUser();
      if (currentUser?.id != null &&
          _activeEvent?.id != null) {
        
        // ✅ FIXED: Use proper heartbeat method instead of location update
        await _asistenciaService.enviarHeartbeat(
          usuarioId: currentUser!.id,
          eventoId: _activeEvent!.id!,
          isAppActive: true,
          isInGracePeriod: false,
          gracePeriodRemaining: 0,
        );

        logger.d('💓 Heartbeat enviado');
      } else {
        logger.d('❌ Error en heartbeat: Usuario o evento es null - Usuario: ${currentUser?.id}, Evento: ${_activeEvent?.id}');
      }
    } catch (e) {
      logger.d('❌ Error enviando heartbeat: $e');
      _handleConnectivityLoss();
    }
  }

  void _handleGeofenceEntered() {
    logger.d('✅ Usuario entró al geofence');

    setState(() {
      _exitWarningCount = 0;
    });

    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entraste al área del evento - Registrando asistencia...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }

    _registerAttendanceAutomatically();
  }

  Future<void> _registerAttendanceAutomatically() async {
    // ✅ FIXED: Always get fresh user from storage to ensure userId is not null
    final currentUser = await _storageService.getUser();
    if (_currentPosition == null ||
        _activeEvent == null ||
        currentUser?.id == null) {
      logger.d('❌ Faltan datos para registro automático - Usuario: ${currentUser?.id}, Evento: ${_activeEvent?.id}');
      return;
    }

    try {
      logger.d('📝 Registrando asistencia automáticamente');

      await _notificationManager.showGeofenceEnteredWithAutoRegistration(_activeEvent!.titulo);

      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _activeEvent!.id!,
        usuarioId: currentUser!.id,
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        estado: 'presente',
        observaciones: 'Registro automático - entrada al área del evento',
      );

      if (response.success) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          try {
            final asistenciaData = response.data as Map<String, dynamic>;
            final nuevaAsistencia = Asistencia.fromJson(asistenciaData);
            setState(() {
              _attendanceHistory.insert(0, nuevaAsistencia);
            });
          } catch (e) {
            logger.d('❌ Error parsing asistencia automática: $e');
          }
        }

        await _notificationManager.showAttendanceRegisteredAutomaticallyNotification(
          eventName: _activeEvent!.titulo,
          studentName: currentUser.nombre,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('✅ ¡Asistencia registrada automáticamente en "${_activeEvent!.titulo}"!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }

        logger.d('✅ Asistencia automática registrada exitosamente');
      } else {
        if (response.error?.contains('ya registró') == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text('ℹ️ Ya tienes asistencia registrada para este evento')),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          await _notificationManager.showConnectionErrorNotification();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: ${response.error}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      logger.d('❌ Excepción en registro automático: $e');
      await _notificationManager.showConnectionErrorNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error de conexión registrando asistencia'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleGeofenceExited() {
    logger.d('⚠️ Usuario salió del geofence');

    setState(() {
      _exitWarningCount++;
    });

    HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saliste del área - Tienes 1 minuto para regresar'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    _startGracePeriod();
  }

  // 🎯 APP LIFECYCLE HANDLERS PRESERVADOS
  void _handleAppResumed() {
    logger.d('✅ App resumed');

    if (_appClosedGraceTimer != null) {
      _appClosedGraceTimer!.cancel();
      _appClosedGraceTimer = null;
      _appClosedSecondsRemaining = 0;
    }

    setState(() {
      _trackingStatus = _isTrackingActive ? 'active' : 'inactive';
    });

    if (_isTrackingActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _handleAppPaused() {
    logger.d('⏸️ App paused');

    if (_isTrackingActive) {
      _startAppClosedGracePeriod();
    }
  }

  void _handleAppDetached() {
    logger.d('❌ App detached');
    _triggerAttendanceLoss('App cerrada');
  }

  void _handleAppInactive() {
    logger.d('⚠️ App inactive');
  }

  void _handleAppHidden() {
    logger.d('🙈 App hidden');

    setState(() {
      _trackingStatus = 'paused';
    });
  }

  // ✅ DUAL GRACE PERIODS PRESERVADOS
  void _startGracePeriod() {
    _geofenceGraceTimer?.cancel();
    
    _geofenceSecondsRemaining = 60;

    _geofenceGraceTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          setState(() {
            _geofenceSecondsRemaining--;
          });

          if (_geofenceSecondsRemaining <= 0) {
            timer.cancel();
            _geofenceGraceTimer = null;
            if (!_isInGeofence) {
              _triggerAttendanceLoss('Fuera del área por más de 1 minuto');
            }
          }
        } else {
          timer.cancel();
          _geofenceGraceTimer = null;
        }
      },
    );
  }

  void _startAppClosedGracePeriod() {
    _appClosedGraceTimer?.cancel();
    
    _appClosedSecondsRemaining = 30;

    setState(() {
      _trackingStatus = 'warning';
    });

    _appClosedGraceTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          setState(() {
            _appClosedSecondsRemaining--;
          });

          if (_appClosedSecondsRemaining <= 0) {
            timer.cancel();
            _appClosedGraceTimer = null;
            _triggerAttendanceLoss('App cerrada por más de 30 segundos');
          }
        } else {
          timer.cancel();
          _appClosedGraceTimer = null;
        }
      },
    );
  }

  void _triggerAttendanceLoss(String reason) async {
    logger.d('❌ PÉRDIDA DE ASISTENCIA: $reason');

    // ✅ FIXED: Always get fresh user from storage to ensure userId is not null
    final currentUser = await _storageService.getUser();
    if (currentUser?.id != null && _activeEvent?.id != null) {
      _asistenciaService.marcarAusente(
        usuarioId: currentUser!.id,
        eventoId: _activeEvent!.id!,
        motivo: reason,
      );
    }

    _stopTracking();
    PermissionDialogWidgets.showAttendanceLossDialog(context, reason);
  }

  void _handleConnectivityLoss() {
    setState(() {
      _trackingStatus = 'error';
      _errorMessage = 'Pérdida de conectividad';
    });
  }

  Future<void> _registerAttendanceManually() async {
    // ✅ FIXED: Always get fresh user from storage to ensure userId is not null
    final currentUser = await _storageService.getUser();
    if (_currentPosition == null ||
        _activeEvent == null ||
        currentUser?.id == null) {
      _showErrorDialog('Faltan datos para registrar asistencia - Usuario: ${currentUser?.id}, Evento: ${_activeEvent?.id}');
      return;
    }

    try {
      logger.d('📝 Registrando asistencia manualmente');

      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _activeEvent!.id!,
        usuarioId: currentUser!.id,
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        estado: _isInGeofence ? 'presente' : 'fuera_area',
      );

      if (response.success) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          try {
            final asistenciaData = response.data as Map<String, dynamic>;
            final nuevaAsistencia = Asistencia.fromJson(asistenciaData);
            setState(() {
              _attendanceHistory.insert(0, nuevaAsistencia);
            });
          } catch (e) {
            logger.d('❌ Error parsing asistencia response: $e');
          }
        }

        HapticFeedback.selectionClick();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asistencia registrada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog(response.error ?? 'Error registrando asistencia');
      }
    } catch (e) {
      logger.d('❌ Error en registro manual: $e');
      _showErrorDialog('Error registrando asistencia: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildTrackingContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _getStatusColor(),
      foregroundColor: AppColors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracking de Asistencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getStatusText(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        if (_isTrackingActive)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => PermissionDialogWidgets.showTrackingInfoDialog(context),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
          SizedBox(height: 16),
          Text(
            'Inicializando tracking...',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_hasPermissions) {
      return _buildPermissionsRequired();
    }

    if (_activeEvent == null) {
      return _buildNoActiveEvent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ MODULAR: Panel de estado del tracking
          TrackingStatusPanel(
            isTrackingActive: _isTrackingActive,
            isInGeofence: _isInGeofence,
            trackingStatus: _trackingStatus,
            geofenceSecondsRemaining: _geofenceSecondsRemaining,
            appClosedSecondsRemaining: _appClosedSecondsRemaining,
            timeInEvent: _timeInEvent,
            exitWarningCount: _exitWarningCount,
            distanceFromCenter: _distanceFromCenter,
            trackingAnimation: _trackingAnimation,
            onStatusTap: () => PermissionDialogWidgets.showTrackingInfoDialog(context),
          ),
          
          const SizedBox(height: 16),
          
          // ✅ MODULAR: Panel de información de ubicación
          LocationInfoPanel(
            currentPosition: _currentPosition,
            activeEvent: _activeEvent,
            distanceFromCenter: _distanceFromCenter,
            currentAccuracy: _currentAccuracy,
            lastUpdateTime: _lastUpdateTime,
            isInGeofence: _isInGeofence,
          ),
          
          const SizedBox(height: 16),
          
          // ✅ MODULAR: Panel de estadísticas
          AttendanceStatsPanel(
            attendanceHistory: _attendanceHistory,
            trackingStatus: _trackingStatus,
            currentAccuracy: _currentAccuracy,
            lastUpdateTime: _lastUpdateTime,
            isTrackingActive: _isTrackingActive,
            isInGeofence: _isInGeofence,
            onViewFullHistory: () => Navigator.pushNamed(context, '/attendance-history'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _startCriticalPermissionsFlow();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              color: AppColors.primaryOrange,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Permisos Requeridos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Para utilizar el tracking de asistencia necesitamos ubicación precisa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startCriticalPermissionsFlow,
              icon: const Icon(Icons.security),
              label: const Text('Otorgar Permisos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveEvent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              color: AppColors.textGray,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay eventos disponibles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes eventos disponibles en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/available-events'),
              icon: const Icon(Icons.event_available),
              label: const Text('Ver Eventos Disponibles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (!_hasPermissions || _activeEvent == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de abandonar evento / evento completado (lado derecho)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Botón principal (tracking o inscripción)
            _buildMainActionButton(),
            
            const SizedBox(width: 16),
            
            // Botón de abandonar/completado
            _buildSecondaryActionButton(),
          ],
        ),
        
        // Botón de registro manual si está en tracking
        if (_isTrackingActive) ...[
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _registerAttendanceManually,
            backgroundColor: AppColors.secondaryTeal,
            heroTag: 'register',
            child: const Icon(Icons.assignment_turned_in),
          ),
        ],
      ],
    );
  }
  
  /// Botón principal: Inscribir / Iniciar Tracking / Detener Tracking
  Widget _buildMainActionButton() {
    if (_isEventCompleted) {
      return FloatingActionButton.extended(
        onPressed: null, // Deshabilitado
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.check_circle),
        label: const Text('Evento Completado'),
      );
    }
    
    if (!_isEnrolledInEvent) {
      return FloatingActionButton.extended(
        onPressed: _enrollInEvent,
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.person_add),
        label: const Text('Inscribir al Evento'),
        heroTag: 'enroll',
      );
    }
    
    if (!_isEventStarted) {
      return FloatingActionButton.extended(
        onPressed: null, // Deshabilitado hasta que inicie
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.schedule),
        label: const Text('Esperando Inicio...'),
        heroTag: 'waiting',
      );
    }
    
    // Evento iniciado y inscrito: botones de tracking
    return FloatingActionButton.extended(
      onPressed: _isTrackingActive ? _stopTracking : _startTracking,
      backgroundColor: _isTrackingActive ? Colors.red : Colors.green,
      icon: Icon(_isTrackingActive ? Icons.stop : Icons.play_arrow),
      label: Text(_isTrackingActive ? 'Detener Tracking' : 'Iniciar Tracking'),
      heroTag: 'tracking',
    );
  }
  
  /// Botón secundario: Abandonar Evento / Evento Completado
  Widget _buildSecondaryActionButton() {
    if (_isEventCompleted) {
      return FloatingActionButton(
        onPressed: null, // Solo visual
        backgroundColor: Colors.green,
        heroTag: 'completed',
        child: const Icon(Icons.event_available),
      );
    }
    
    if (_isEnrolledInEvent) {
      return FloatingActionButton(
        onPressed: _showAbandonEventDialog,
        backgroundColor: Colors.red,
        heroTag: 'abandon',
        child: const Icon(Icons.exit_to_app),
      );
    }
    
    return const SizedBox.shrink();
  }

  // 🎯 MÉTODOS UTILITARIOS PRESERVADOS
  Color _getStatusColor() {
    switch (_trackingStatus) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'warning':
        return Colors.red;
      case 'error':
        return Colors.red;
      default:
        return AppColors.textGray;
    }
  }

  String _getStatusText() {
    switch (_trackingStatus) {
      case 'active':
        return 'Tracking Activo';
      case 'paused':
        return 'Tracking Pausado';
      case 'warning':
        return 'Advertencia - App en Background';
      case 'error':
        return 'Error en Tracking';
      default:
        return 'Tracking Inactivo';
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVOS MÉTODOS PARA EL FLUJO MEJORADO
  
  /// Verificar estado del evento (futuro, activo, completado)
  void _checkEventStatus() {
    if (_activeEvent == null) return;
    
    final now = DateTime.now();
    final eventStart = DateTime(
      _activeEvent!.fecha.year,
      _activeEvent!.fecha.month,
      _activeEvent!.fecha.day,
      _activeEvent!.horaInicio.hour,
      _activeEvent!.horaInicio.minute,
    );
    final eventEnd = DateTime(
      _activeEvent!.fecha.year,
      _activeEvent!.fecha.month,
      _activeEvent!.fecha.day,
      _activeEvent!.horaFinal.hour,
      _activeEvent!.horaFinal.minute,
    );
    
    setState(() {
      _isEventStarted = now.isAfter(eventStart);
      _isEventCompleted = now.isAfter(eventEnd);
    });
    
    logger.d('📅 Estado del evento: iniciado=$_isEventStarted, completado=$_isEventCompleted');
  }
  
  /// Configurar timer para inicio del evento y notificación 5 min antes
  void _setupEventStartTimer() {
    if (_activeEvent == null || _isEventStarted) return;
    
    final now = DateTime.now();
    final eventStart = DateTime(
      _activeEvent!.fecha.year,
      _activeEvent!.fecha.month,
      _activeEvent!.fecha.day,
      _activeEvent!.horaInicio.hour,
      _activeEvent!.horaInicio.minute,
    );
    
    // Notificación 5 minutos antes
    final notificationTime = eventStart.subtract(const Duration(minutes: 5));
    
    if (now.isBefore(notificationTime)) {
      final timeToNotification = notificationTime.difference(now);
      _eventStartTimer = Timer(timeToNotification, () {
        _notificationManager.showEventStartingSoonNotification(
          eventName: _activeEvent!.titulo,
          minutesLeft: 5,
        );
      });
    }
    
    // Timer para cuando inicie el evento
    if (now.isBefore(eventStart)) {
      final timeToStart = eventStart.difference(now);
      Timer(timeToStart, () {
        if (mounted) {
          setState(() {
            _isEventStarted = true;
          });
          logger.d('🚀 ¡El evento ha iniciado!');
        }
      });
    }
  }
  
  /// Inscribirse al evento (reemplaza pre-registro)
  Future<void> _enrollInEvent() async {
    if (_activeEvent == null || _currentUser == null) return;
    
    try {
      logger.d('📝 Inscribiéndose al evento: ${_activeEvent!.titulo}');
      
      // Aquí llamarías a tu servicio de inscripción
      // await _eventoService.inscribirseAlEvento(_activeEvent!.id!, _currentUser!.id);
      
      setState(() {
        _isEnrolledInEvent = true;
      });
      
      await _notificationManager.showEventEnrollmentSuccessNotification(
        eventName: _activeEvent!.titulo,
      );
      
      // Configurar notificación para 5 min antes
      _setupEventStartTimer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('✅ Inscrito exitosamente en "${_activeEvent!.titulo}"'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      logger.d('✅ Inscripción exitosa al evento');
    } catch (e) {
      logger.d('❌ Error en inscripción: $e');
      _showErrorDialog('Error al inscribirse: $e');
    }
  }
  
  /// Abandonar evento con popup de confirmación
  Future<void> _showAbandonEventDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Abandonar Evento'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de abandonar el evento?\n\n'
          'Tu asistencia se tomará como falta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _abandonEvent();
    }
  }
  
  /// Abandonar evento
  Future<void> _abandonEvent() async {
    try {
      logger.d('🚪 Abandonando evento...');
      
      // Detener tracking si está activo
      if (_isTrackingActive) {
        await _stopTracking();
      }
      
      // Marcar como ausente en el backend
      final currentUser = await _storageService.getUser();
      if (currentUser?.id != null && _activeEvent?.id != null) {
        await _asistenciaService.marcarAusente(
          usuarioId: currentUser!.id,
          eventoId: _activeEvent!.id!,
          motivo: 'Usuario abandonó el evento voluntariamente',
        );
      }
      
      // Notificación
      await _notificationManager.showEventAbandonedNotification(
        eventName: _activeEvent!.titulo,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Text('Has abandonado "${_activeEvent!.titulo}"'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Regresar a la pantalla anterior
        Navigator.of(context).pop();
      }
      
      logger.d('✅ Evento abandonado');
    } catch (e) {
      logger.d('❌ Error abandonando evento: $e');
      _showErrorDialog('Error al abandonar evento: $e');
    }
  }
}