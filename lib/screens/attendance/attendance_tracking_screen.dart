// lib/screens/attendance/attendance_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../services/storage_service.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/permission_service.dart'; // ✅ NUEVO IMPORT
import '../../services/notifications/notification_manager.dart'; // ✅ NUEVO IMPORT
import '../../models/usuario_model.dart';
import '../../models/evento_model.dart';
import '../../models/asistencia_model.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceTrackingScreen extends StatefulWidget {
  final String userName;
  final String? eventoId; // Si viene desde "Unirse a Evento"

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
  final PermissionService _permissionService = PermissionService(); // ✅ NUEVO SERVICIO
  final NotificationManager _notificationManager = NotificationManager(); // ✅ NUEVO SERVICIO

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

  // 🎯 TIMERS Y CONTADORES - FIXED: Separate timers to avoid conflicts
  Timer? _positionUpdateTimer;
  Timer? _heartbeatTimer;
  Timer? _geofenceGraceTimer; // ✅ SEPARADO: Para violations de geofence
  Timer? _appClosedGraceTimer; // ✅ SEPARADO: Para app lifecycle
  int _geofenceSecondsRemaining = 0; // ✅ SEPARADO: Contador geofence
  int _appClosedSecondsRemaining = 0; // ✅ SEPARADO: Contador app closed
  Duration _timeInEvent = Duration.zero;
  int _exitWarningCount = 0;

  // 🎯 ESTADÍSTICAS EN TIEMPO REAL
  double _distanceFromCenter = 0.0;
  double _currentAccuracy = 0.0;
  String _lastUpdateTime = '';

  // ✅ NUEVAS VARIABLES PARA PERMISOS CRÍTICOS
  bool _showingPermissionDialog = false;
  bool _allPermissionsGranted = false;
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _checkCriticalPermissionsBeforeTracking(); // ✅ MODIFICAR ESTA LÍNEA
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingController.dispose();
    _pulseController.dispose();
    // ✅ FIXED: Cleanup all timers properly
    _positionUpdateTimer?.cancel();
    _heartbeatTimer?.cancel();
    _geofenceGraceTimer?.cancel();
    _appClosedGraceTimer?.cancel();
    super.dispose();
  }

  // 🎯 APP LIFECYCLE MANAGEMENT
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('📱 App lifecycle cambió a: $state');

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

  Future<void> _initializeTracking() async {
    debugPrint('🎯 Inicializando AttendanceTracking');

    try {
      // 1. Validar permisos críticos
      await _validateCriticalPermissions();

      // 2. Cargar datos del usuario
      await _loadUserData();

      // 3. Cargar evento específico
      await _loadEventData();

      // 4. Cargar historial
      await _loadAttendanceHistory();
    } catch (e) {
      debugPrint('❌ Error inicializando tracking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error inicializando tracking: $e';
        });
      }
      rethrow;
    }
  }

  // ✅ REEMPLAZADO: Sistema de validación de permisos críticos obsoleto
  // Ahora se maneja en _checkCriticalPermissionsBeforeTracking()
  Future<void> _validateCriticalPermissions() async {
    debugPrint('🔒 Método legacy - usar _checkCriticalPermissionsBeforeTracking');
    // Método legacy - no se usa más
    setState(() {
      _hasPermissions = _allPermissionsGranted;
    });
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
        // Cargar evento específico
        final eventos = await _eventoService.obtenerEventos();
        _activeEvent = eventos.firstWhere(
          (e) => e.id == widget.eventoId,
          orElse: () => throw Exception('Evento no encontrado'),
        );
      } else {
        // Buscar evento activo
        final activeEvents = await _eventoService.obtenerEventos();
        final userActiveEvents = activeEvents.where((e) => e.isActive).toList();

        if (userActiveEvents.isNotEmpty) {
          _activeEvent = userActiveEvents.first;
        }
      }

      if (mounted && _activeEvent != null) {
        setState(() {
          debugPrint('✅ Evento cargado: ${_activeEvent!.titulo}');
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando evento: $e');
      rethrow;
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (_currentUser?.id == null) return;

    try {
      final history =
          await _asistenciaService.obtenerHistorialUsuario(_currentUser!.id);

      if (mounted) {
        setState(() {
          _attendanceHistory = history;
          _isLoading = false;
        });
      }

      debugPrint('✅ Historial cargado: ${history.length} asistencias');
    } catch (e) {
      debugPrint('❌ Error cargando historial: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================
  // ✅ NUEVOS MÉTODOS - SISTEMA DE PERMISOS CRÍTICOS
  // ===========================================

  /// ✅ NUEVO: Verificar permisos críticos antes del tracking
  Future<void> _checkCriticalPermissionsBeforeTracking() async {
    debugPrint('🔐 Verificando permisos críticos antes del tracking...');
    
    // Verificar todos los permisos críticos
    _permissionStatus = await _permissionService.checkCriticalPermissions();
    
    debugPrint('📋 Estado de permisos: $_permissionStatus');
    
    // Si no todos los permisos están otorgados, mostrar diálogos
    if (!_areAllPermissionsGranted()) {
      await _showCriticalPermissionsDialog();
    } else {
      // Solo si todos los permisos están OK, iniciar tracking
      _allPermissionsGranted = true;
      await _startAutomaticTracking();
    }
  }

  /// ✅ NUEVO: Verificar si todos los permisos están otorgados
  bool _areAllPermissionsGranted() {
    return _permissionStatus['location_precise'] == true &&
           _permissionStatus['location_always'] == true &&
           _permissionStatus['battery_optimization'] == true &&
           _permissionStatus['location_services'] == true;
  }

  /// ✅ NUEVO: Mostrar diálogos de permisos críticos
  Future<void> _showCriticalPermissionsDialog() async {
    if (_showingPermissionDialog) return; // Evitar diálogos múltiples
    
    _showingPermissionDialog = true;
    
    // Verificar en orden: servicios → preciso → siempre → batería
    if (_permissionStatus['location_services'] != true) {
      await _showLocationServicesDialog();
    } else if (_permissionStatus['location_precise'] != true) {
      await _showPreciseLocationDialog();
    } else if (_permissionStatus['location_always'] != true) {
      await _showAlwaysLocationDialog();
    } else if (_permissionStatus['battery_optimization'] != true) {
      await _showBatteryOptimizationDialog();
    }
  }

  /// ✅ NUEVO: Diálogo de servicios de ubicación
  Future<void> _showLocationServicesDialog() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // No permite cerrar con back
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.location_off, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('📍 Ubicación Desactivada')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ REQUERIDO PARA ASISTENCIA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Para registrar tu asistencia necesitas:'),
                SizedBox(height: 8),
                _buildRequirementItem('📍', 'Activar servicios de ubicación del dispositivo'),
                SizedBox(height: 16),
                Text(
                  'Este popup seguirá apareciendo hasta que actives la ubicación.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _permissionService.openLocationSettings();
                  // Recheck después de 2 segundos
                  Timer(Duration(seconds: 2), () async {
                    await _recheckPermissionsAndContinue();
                  });
                },
                icon: Icon(Icons.settings),
                label: Text('Abrir Configuración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ NUEVO: Diálogo de ubicación precisa
  Future<void> _showPreciseLocationDialog() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.gps_not_fixed, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('🎯 Ubicación Precisa')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.precision_manufacturing, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PRECISIÓN REQUERIDA',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Para detectar cuando entres al área del evento:'),
                SizedBox(height: 8),
                _buildRequirementItem('🎯', 'Ubicación PRECISA (no aproximada)'),
                _buildRequirementItem('📐', 'Para geofencing exacto'),
                SizedBox(height: 16),
                Text(
                  'Nota: Sin ubicación precisa no se puede registrar asistencia automáticamente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _recheckPermissionsAndContinue();
                },
                child: Text('❌ Rechazar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final granted = await _permissionService.requestPreciseLocationPermissionEnhanced();
                  if (granted) {
                    await _recheckPermissionsAndContinue();
                  } else {
                    // Volver a mostrar el diálogo
                    Timer(Duration(milliseconds: 500), () async {
                      await _recheckPermissionsAndContinue();
                    });
                  }
                },
                icon: Icon(Icons.check),
                label: Text('✅ Permitir Precisa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ NUEVO: Diálogo de ubicación siempre
  Future<void> _showAlwaysLocationDialog() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('⏰ Ubicación Todo el Tiempo')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TRACKING CONTINUO',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Para asistencia automática necesitas:'),
                SizedBox(height: 8),
                _buildRequirementItem('📱', 'Ubicación activa aunque cambies de app'),
                _buildRequirementItem('🔄', 'Tracking continuo durante el evento'),
                _buildRequirementItem('⚡', 'Detección inmediata de entrada/salida'),
                SizedBox(height: 16),
                Text(
                  '💡 Tranquilo: Solo se usa durante eventos activos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _recheckPermissionsAndContinue();
                },
                child: Text('❌ Solo cuando use la app'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final granted = await _permissionService.requestAlwaysLocationPermission();
                  if (granted) {
                    await _recheckPermissionsAndContinue();
                  } else {
                    Timer(Duration(milliseconds: 500), () async {
                      await _recheckPermissionsAndContinue();
                    });
                  }
                },
                icon: Icon(Icons.check),
                label: Text('✅ Permitir Siempre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ NUEVO: Diálogo de optimización de batería
  Future<void> _showBatteryOptimizationDialog() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.battery_alert, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('🔋 Optimización de Batería')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ CRÍTICO PARA ASISTENCIA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Android está optimizando la batería de GeoAsist.'),
                SizedBox(height: 12),
                Text('Esto causará:'),
                SizedBox(height: 8),
                _buildRequirementItem('❌', 'App se cierre automáticamente'),
                _buildRequirementItem('💔', 'Pérdida de asistencia registrada'),
                _buildRequirementItem('📍', 'Tracking interrumpido'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✅ Desactivar optimización = Asistencia garantizada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _recheckPermissionsAndContinue();
                },
                child: Text('❌ Mantener Optimización'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final granted = await _permissionService.requestBatteryOptimizationPermission();
                  if (granted) {
                    await _recheckPermissionsAndContinue();
                  } else {
                    Timer(Duration(milliseconds: 500), () async {
                      await _recheckPermissionsAndContinue();
                    });
                  }
                },
                icon: Icon(Icons.check),
                label: Text('🔋 Desactivar Optimización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ NUEVO: Widget helper para elementos de requisito
  Widget _buildRequirementItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Revericar permisos y continuar
  Future<void> _recheckPermissionsAndContinue() async {
    _showingPermissionDialog = false;
    
    // Verificar nuevamente todos los permisos
    _permissionStatus = await _permissionService.checkCriticalPermissions();
    
    if (_areAllPermissionsGranted()) {
      // ¡Todos los permisos están OK! Iniciar tracking
      _allPermissionsGranted = true;
      await _startAutomaticTracking();
    } else {
      // Todavía faltan permisos, mostrar el siguiente diálogo
      Timer(Duration(milliseconds: 800), () async {
        await _showCriticalPermissionsDialog();
      });
    }
  }

  /// ✅ MÉTODO MODIFICADO: Iniciar tracking automático (solo cuando permisos OK)
  Future<void> _startAutomaticTracking() async {
    if (!_allPermissionsGranted) {
      debugPrint('❌ No se puede iniciar tracking - faltan permisos críticos');
      return;
    }
    
    debugPrint('🚀 Iniciando tracking automático con permisos completos...');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar datos del usuario y evento primero
      await _loadUserData();
      await _loadEventData();
      await _loadAttendanceHistory();
      
      // Activar tracking automáticamente
      await _activateTracking();
      
      // Mostrar notificación de tracking iniciado
      await _notificationManager.showTrackingActiveNotification();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      debugPrint('✅ Tracking automático activado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en tracking automático: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error iniciando tracking: $e';
        });
      }
    }
  }

  /// ✅ NUEVO: Método de activación de tracking (equivalente a _startTracking)
  Future<void> _activateTracking() async {
    if (_activeEvent == null) {
      throw Exception('No hay evento activo para tracking');
    }

    try {
      debugPrint('▶️ Activando tracking automático');

      // Iniciar timers
      _startPositionUpdates();
      _startHeartbeat();

      // Actualizar UI
      setState(() {
        _isTrackingActive = true;
        _trackingStatus = 'active';
        _hasPermissions = true;
      });

      _trackingController.forward();
      debugPrint('✅ Tracking automático activado');
    } catch (e) {
      debugPrint('❌ Error activando tracking: $e');
      rethrow;
    }
  }

  // 🎯 CONTROL DE TRACKING

  Future<void> _startTracking() async {
    if (!_hasPermissions) {
      await _validateCriticalPermissions();
      if (!_hasPermissions) return;
    }

    if (_activeEvent == null) {
      _showErrorDialog('No hay evento activo para tracking');
      return;
    }

    try {
      debugPrint('▶️ Iniciando tracking');

      // Iniciar timers
      _startPositionUpdates();
      _startHeartbeat();

      // Actualizar UI
      setState(() {
        _isTrackingActive = true;
        _trackingStatus = 'active';
      });

      _trackingController.forward();
      _pulseController.repeat(reverse: true);

      debugPrint('✅ Tracking iniciado');
    } catch (e) {
      debugPrint('❌ Error iniciando tracking: $e');
      _showErrorDialog('Error iniciando tracking: $e');
    }
  }

  Future<void> _stopTracking() async {
    try {
      debugPrint('⏹️ Deteniendo tracking');

      // Detener timers
      // ✅ FIXED: Cancel all timers properly
      _positionUpdateTimer?.cancel();
      _heartbeatTimer?.cancel();
      _geofenceGraceTimer?.cancel();
      _appClosedGraceTimer?.cancel();

      // Actualizar UI
      setState(() {
        _isTrackingActive = false;
        _trackingStatus = 'inactive';
        _timeInEvent = Duration.zero;
      });

      _trackingController.reverse();
      _pulseController.stop();

      debugPrint('✅ Tracking detenido');
    } catch (e) {
      debugPrint('❌ Error deteniendo tracking: $e');
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

        // Calcular distancia al centro del evento
        if (_activeEvent != null) {
          _distanceFromCenter = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _activeEvent!.ubicacion.latitud,
            _activeEvent!.ubicacion.longitud,
          );

          // Verificar geofence
          _checkGeofence();
        }

        // Actualizar ubicación en backend
        await _asistenciaService.actualizarUbicacion(
          usuarioId: _currentUser!.id,
          eventoId: _activeEvent!.id!,
          latitud: position.latitude,
          longitud: position.longitude,
          precision: position.accuracy,
        );
      }
    } catch (e) {
      debugPrint('❌ Error actualizando posición: $e');
    }
  }

  void _checkGeofence() {
    if (_activeEvent == null || _currentPosition == null) return;

    final isInsideGeofence =
        _distanceFromCenter <= _activeEvent!.rangoPermitido;

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
      if (_currentUser?.id != null &&
          _activeEvent?.id != null &&
          _currentPosition != null) {
        await _asistenciaService.actualizarUbicacion(
          usuarioId: _currentUser!.id,
          eventoId: _activeEvent!.id!,
          latitud: _currentPosition!.latitude,
          longitud: _currentPosition!.longitude,
        );

        debugPrint('💓 Heartbeat enviado');
      }
    } catch (e) {
      debugPrint('❌ Error enviando heartbeat: $e');
      _handleConnectivityLoss();
    }
  }

  // 🎯 MANEJADORES DE EVENTOS

  void _handleGeofenceEntered() {
    debugPrint('✅ Usuario entró al geofence');

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

    // 🎯 REGISTRAR ASISTENCIA AUTOMÁTICAMENTE
    _registerAttendanceAutomatically();
  }

  /// 🎯 NUEVO: Registra asistencia automáticamente cuando entra al geofence
  /// ✅ MEJORADO: Registro automático con notificaciones contextuales
  Future<void> _registerAttendanceAutomatically() async {
    if (_currentPosition == null ||
        _activeEvent == null ||
        _currentUser?.id == null) {
      debugPrint('❌ Faltan datos para registro automático');
      return;
    }

    try {
      debugPrint('📝 Registrando asistencia automáticamente');

      // ✅ MOSTRAR NOTIFICACIÓN DE PROCESO
      await _notificationManager.showGeofenceEnteredWithAutoRegistration(_activeEvent!.titulo);

      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _activeEvent!.id!,
        usuarioId: _currentUser!.id,
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        estado: 'presente',
        observaciones: 'Registro automático - entrada al área del evento',
      );

      if (response.success) {
        // Procesar respuesta exitosa
        if (response.data != null && response.data is Map<String, dynamic>) {
          try {
            final asistenciaData = response.data as Map<String, dynamic>;
            final nuevaAsistencia = Asistencia.fromJson(asistenciaData);
            setState(() {
              _attendanceHistory.insert(0, nuevaAsistencia);
            });
          } catch (e) {
            debugPrint('❌ Error parsing asistencia automática: $e');
          }
        }

        // ✅ MOSTRAR NOTIFICACIÓN DE ÉXITO MEJORADA
        await _notificationManager.showAttendanceRegisteredAutomaticallyNotification(
          eventName: _activeEvent!.titulo,
          studentName: _currentUser!.nombre,
        );

        // ✅ SNACKBAR EN LA APP TAMBIÉN
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

        debugPrint('✅ Asistencia automática registrada exitosamente');
      } else {
        // Manejar errores específicos
        if (response.error?.contains('ya registró') == true) {
          // Ya registrado - no es error crítico
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
          // Error real - mostrar en notificación
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
      debugPrint('❌ Excepción en registro automático: $e');
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
    debugPrint('⚠️ Usuario salió del geofence');

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

  // 🎯 APP LIFECYCLE HANDLERS

  // ✅ FIXED: Handle app resumed with separate timers
  void _handleAppResumed() {
    debugPrint('✅ App resumed');

    // Stop app closed grace timer if running
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
    debugPrint('⏸️ App paused');

    if (_isTrackingActive) {
      _startAppClosedGracePeriod();
    }
  }

  void _handleAppDetached() {
    debugPrint('❌ App detached');
    _triggerAttendanceLoss('App cerrada');
  }

  void _handleAppInactive() {
    debugPrint('⚠️ App inactive');
  }

  void _handleAppHidden() {
    debugPrint('🙈 App hidden');

    setState(() {
      _trackingStatus = 'paused';
    });
  }

  // ✅ FIXED: Use dedicated geofence grace timer
  void _startGracePeriod() {
    // Cancel any existing geofence grace timer
    _geofenceGraceTimer?.cancel();
    
    _geofenceSecondsRemaining = 60; // 1 minuto de gracia

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

  // ✅ FIXED: Use dedicated app closed grace timer
  void _startAppClosedGracePeriod() {
    // Cancel any existing app closed grace timer
    _appClosedGraceTimer?.cancel();
    
    _appClosedSecondsRemaining = 30; // 30 segundos para reabrir

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

  void _triggerAttendanceLoss(String reason) {
    debugPrint('❌ PÉRDIDA DE ASISTENCIA: $reason');

    if (_currentUser?.id != null && _activeEvent?.id != null) {
      _asistenciaService.marcarAusente(
        usuarioId: _currentUser!.id,
        eventoId: _activeEvent!.id!,
        motivo: reason,
      );
    }

    _stopTracking();
    _showAttendanceLossDialog(reason);
  }

  void _handleConnectivityLoss() {
    setState(() {
      _trackingStatus = 'error';
      _errorMessage = 'Pérdida de conectividad';
    });
  }

  // 🎯 REGISTRO MANUAL DE ASISTENCIA

  Future<void> _registerAttendanceManually() async {
    if (_currentPosition == null ||
        _activeEvent == null ||
        _currentUser?.id == null) {
      _showErrorDialog('Faltan datos para registrar asistencia');
      return;
    }

    try {
      debugPrint('📝 Registrando asistencia manualmente');

      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _activeEvent!.id!,
        usuarioId: _currentUser!.id,
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        estado: _isInGeofence ? 'presente' : 'fuera_area',
      );

      if (response.success) {
        // El backend ahora devuelve los datos en response.data
        if (response.data != null && response.data is Map<String, dynamic>) {
          try {
            final asistenciaData = response.data as Map<String, dynamic>;
            final nuevaAsistencia = Asistencia.fromJson(asistenciaData);
            setState(() {
              _attendanceHistory.insert(0, nuevaAsistencia);
            });
          } catch (e) {
            debugPrint('❌ Error parsing asistencia response: $e');
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
      debugPrint('❌ Error en registro manual: $e');
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
          onPressed: _showTrackingInfo,
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
          // 🎯 NUEVO: Panel de instrucciones para el usuario
          _buildInstructionsPanel(),
          const SizedBox(height: 16),
          _buildEventPanel(),
          const SizedBox(height: 16),
          _buildTrackingStatusPanel(),
          const SizedBox(height: 16),
          _buildLocationPanel(),
          const SizedBox(height: 16),
          _buildRealTimeStats(),
          const SizedBox(height: 16),
          _buildRecentHistory(),
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
              _initializeTracking();
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
              onPressed: _validateCriticalPermissions,
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
              'No hay eventos activos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes eventos activos en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/available-events'),
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

  Widget _buildEventPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeEvent!.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        _activeEvent!.lugar ?? 'Ubicación',
                        style: const TextStyle(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _activeEvent!.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _activeEvent!.isActive ? 'ACTIVO' : 'INACTIVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Inicio',
                    '${_activeEvent!.horaInicio.hour.toString().padLeft(2, '0')}:${_activeEvent!.horaInicio.minute.toString().padLeft(2, '0')}',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Radio',
                    '${_activeEvent!.rangoPermitido.toInt()}m',
                    Icons.location_on,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Estado',
                    _isInGeofence ? 'Dentro' : 'Fuera',
                    _isInGeofence ? Icons.check_circle : Icons.location_off,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStatusPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _trackingAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ✅ FIXED: Display both grace periods appropriately
            if (_geofenceSecondsRemaining > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Geofence Grace Period: ${_geofenceSecondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_appClosedSecondsRemaining > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'App Closed Grace Period: ${_appClosedSecondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isTrackingActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Tiempo en Evento',
                      _formatDuration(_timeInEvent),
                      Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Salidas del Área',
                      '$_exitWarningCount',
                      Icons.exit_to_app,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.my_location, color: AppColors.secondaryTeal),
                SizedBox(width: 8),
                Text(
                  'Ubicación Actual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentPosition != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Latitud',
                      _currentPosition!.latitude.toStringAsFixed(6),
                      Icons.place,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Longitud',
                      _currentPosition!.longitude.toStringAsFixed(6),
                      Icons.place,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Precisión',
                      '${_currentAccuracy.toStringAsFixed(1)}m',
                      Icons.gps_fixed,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Distancia Centro',
                      '${_distanceFromCenter.toStringAsFixed(1)}m',
                      Icons.straighten,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: AppColors.textGray),
                    const SizedBox(width: 8),
                    Text(
                      'Última actualización: $_lastUpdateTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.secondaryTeal),
                    SizedBox(height: 8),
                    Text(
                      'Obteniendo ubicación...',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Estadísticas en Tiempo Real',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Estado Actual',
                    _getDetailedStatus(),
                    _getStatusIcon(),
                    _getStatusColor(),
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Asistencias Total',
                    '${_attendanceHistory.length}',
                    Icons.assignment_turned_in,
                    AppColors.secondaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Precisión GPS',
                    _currentAccuracy > 0
                        ? '${_currentAccuracy.toStringAsFixed(1)}m'
                        : 'N/A',
                    Icons.gps_fixed,
                    _currentAccuracy <= 10 ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Conectividad',
                    _lastUpdateTime.isNotEmpty ? 'Activa' : 'Sin datos',
                    Icons.signal_cellular_alt,
                    _lastUpdateTime.isNotEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.textGray),
                SizedBox(width: 8),
                Text(
                  'Historial Reciente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_attendanceHistory.isNotEmpty) ...[
              ...(_attendanceHistory
                  .take(5)
                  .map((asistencia) => _buildHistoryItem(asistencia))),
              if (_attendanceHistory.length > 5) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/attendance-history'),
                  child: const Text('Ver historial completo'),
                ),
              ],
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 48,
                      color: AppColors.textGray,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No hay historial de asistencias',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Asistencia asistencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getEstadoColor(asistencia.estado),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getEstadoIcon(asistencia.estado),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEstado(asistencia.estado),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${asistencia.hora.day}/${asistencia.hora.month} - ${asistencia.hora.hour.toString().padLeft(2, '0')}:${asistencia.hora.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        if (_isTrackingActive) ...[
          FloatingActionButton(
            onPressed: _registerAttendanceManually,
            backgroundColor: AppColors.secondaryTeal,
            heroTag: 'register',
            child: const Icon(Icons.assignment_turned_in),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton.extended(
          onPressed: _isTrackingActive ? _stopTracking : _startTracking,
          backgroundColor:
              _isTrackingActive ? Colors.red : AppColors.primaryOrange,
          icon: Icon(_isTrackingActive ? Icons.stop : Icons.play_arrow),
          label: Text(_isTrackingActive ? 'Detener' : 'Iniciar'),
        ),
      ],
    );
  }

  // 🎯 NUEVO: Panel de instrucciones para el usuario
  Widget _buildInstructionsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isTrackingActive ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            _isTrackingActive ? Colors.green.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isTrackingActive ? Colors.green.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isTrackingActive ? Icons.check_circle : Icons.info_outline,
                color: _isTrackingActive ? Colors.green : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _isTrackingActive ? '¡Tracking Activo!' : 'Cómo funciona',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isTrackingActive ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isTrackingActive) ...[
            _buildInstructionStep(
              '1.',
              'Presiona "Iniciar" para activar el tracking GPS',
              Icons.play_arrow,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '2.',
              'Dirígete hacia el área del evento',
              Icons.directions_walk,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '3.',
              'Tu asistencia se registrará automáticamente al entrar',
              Icons.check_circle,
              Colors.green,
            ),
          ] else ...[
            Text(
              '• GPS monitoreando tu ubicación cada 5 segundos\n'
              '• Distancia al evento: ${_distanceFromCenter.toStringAsFixed(0)}m\n'
              '• Tu asistencia se registrará automáticamente al entrar al área',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // 🎯 MÉTODOS UTILITARIOS

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

  IconData _getStatusIcon() {
    switch (_trackingStatus) {
      case 'active':
        return Icons.track_changes;
      case 'paused':
        return Icons.pause;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.location_off;
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

  String _getDetailedStatus() {
    if (_isTrackingActive) {
      if (_isInGeofence) {
        return 'Presente';
      } else {
        return 'Fuera del Área';
      }
    }
    return 'Inactivo';
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Colors.green;
      case 'tarde':
        return Colors.orange;
      case 'ausente':
        return Colors.red;
      case 'justificado':
        return Colors.blue;
      default:
        return AppColors.textGray;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Icons.check_circle;
      case 'tarde':
        return Icons.schedule;
      case 'ausente':
        return Icons.cancel;
      case 'justificado':
        return Icons.description;
      default:
        return Icons.help;
    }
  }

  String _formatEstado(String estado) {
    return estado[0].toUpperCase() + estado.substring(1);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  // 🎯 DIÁLOGOS Y ALERTAS

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

  void _showAttendanceLossDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Asistencia Perdida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Has perdido la asistencia para este evento.\n\nMotivo: $reason',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver al dashboard
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showTrackingInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Tracking'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Características del Tracking:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• GPS preciso cada 5 segundos'),
              Text('• Heartbeat al servidor cada 30 segundos'),
              Text('• Detección automática de geofence'),
              Text('• Grace period de 60s por salida del área'),
              Text('• Grace period de 30s por cerrar app'),
              Text('• Registro automático de asistencia'),
              SizedBox(height: 16),
              Text(
                'Restricciones de Seguridad:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Ubicación precisa obligatoria'),
              Text('• Background tracking requerido'),
              Text('• Cerrar app = pérdida de asistencia'),
              Text('• Tracking continuo durante evento'),
              SizedBox(height: 16),
              Text(
                'Mantén la aplicación abierta durante todo el evento para conservar tu asistencia.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
