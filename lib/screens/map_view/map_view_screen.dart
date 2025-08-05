// lib/screens/map_view/map_view_screen.dart - ARCHIVO CORREGIDO COMPLETO
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../services/permission_service.dart';
import '../../widgets/permission_handler_widget.dart';
import '../../utils/colors.dart';
import '../../core/app_constants.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import '../../utils/app_router.dart';
import 'widgets/status_panel.dart';
import 'widgets/map_area.dart';
import 'widgets/control_panel.dart';
import '../../models/attendance_state_model.dart';
import '../../widgets/attendance_button_widget.dart';

class MapViewScreen extends StatefulWidget {
  final bool isAdminMode;
  final String userName;
  final String? eventoId;
  final bool isStudentMode;

  const MapViewScreen({
    super.key,
    this.isAdminMode = false,
    this.userName = "Usuario",
    this.eventoId,
    this.isStudentMode = false,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  // Servicios
  final EventoService _eventoService = EventoService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  // Controladores de animación
  late AnimationController _pulseController;
  late AnimationController _graceController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _graceColorAnimation;

  // Variables de estado
  bool _isInsideGeofence = true;
  bool _isOnBreak = false;
  bool _isAttendanceActive = true;
  int _gracePeriodSeconds = 60;
  int _breakTimeRemaining = 0;
  bool _isLoading = true;

  // Datos
  Usuario? _currentUser;
  List<Evento> _eventos = [];
  Evento? _currentEvento;

  // Coordenadas del usuario (GPS real)
  double _userLat = 0.0; // Se actualiza con GPS real
  double _userLng = 0.0; // Se actualiza con GPS real

  // Coordenadas del evento (del backend)
  double _eventLat = 0.0; // Coordenadas donde el docente creó el evento
  double _eventLng = 0.0; // Se cargan desde currentEvento.ubicacion
  double _eventRange = 100.0; // Rango del evento

  /// Calcula distancia entre estudiante y evento (para debugging)
  double _calculateDistance() {
    if (_eventLat == 0.0 ||
        _eventLng == 0.0 ||
        _userLat == 0.0 ||
        _userLng == 0.0) {
      return 0.0;
    }

    return Geolocator.distanceBetween(_userLat, _userLng, _eventLat, _eventLng);
  }

  bool _hasLocationPermissions = false;
  final PermissionService _permissionService = PermissionService();

  // Variables para modo estudiante
  StudentAttendanceStatus? _attendanceStatus;
  bool _isRegisteringAttendance = false;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _initializeStudentMode();
    _checkLocationPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _graceController.dispose();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _graceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _graceColorAnimation = ColorTween(
      begin: AppColors.primaryOrange,
      end: Colors.red,
    ).animate(_graceController);
  }

  Future<void> _initializeData() async {
    try {
      _currentUser = await _storageService.getUser();
      _eventos = await _eventoService.obtenerEventos();
      _findActiveEvent();
      _startLocationUpdates();
    } catch (e) {
      debugPrint('Error al inicializar datos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _findActiveEvent() {
    final now = DateTime.now();
    for (final evento in _eventos) {
      if (evento.isActive ||
          (now.isAfter(
                  evento.horaInicio.subtract(const Duration(minutes: 10))) &&
              now.isBefore(evento.horaFinal))) {
        _currentEvento = evento;
        break;
      }
    }
  }

  void _startLocationUpdates() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _currentEvento != null) {
        _checkGeofenceStatus();
      }
    });
  }

  Future<void> _checkGeofenceStatus() async {
    if (_currentUser == null || _currentEvento == null) return;

    try {
      final response = await _locationService.updateUserLocation(
        userId: _currentUser!.id,
        latitude: _userLat,
        longitude: _userLng,
        previousState: _isInsideGeofence,
        eventoId: _currentEvento!.id,
      );

      if (response.success && response.data != null) {
        final newGeofenceStatus =
            response.data!['insideGeofence'] as bool? ?? true;

        if (newGeofenceStatus != _isInsideGeofence) {
          setState(() => _isInsideGeofence = newGeofenceStatus);

          if (!_isInsideGeofence) {
            _startGracePeriod();
          } else {
            _resetGracePeriod();
          }
        }
      }
    } catch (e) {
      debugPrint('Error al verificar geofence: $e');
    }
  }

  void _startGracePeriod() {
    _graceController.forward();
    _startGracePeriodCountdown();
  }

  void _resetGracePeriod() {
    _graceController.reset();
    setState(() {
      _gracePeriodSeconds = 60;
      _isAttendanceActive = true;
    });
  }

  void _startGracePeriodCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted &&
          _gracePeriodSeconds > 0 &&
          !_isInsideGeofence &&
          !_isOnBreak) {
        setState(() => _gracePeriodSeconds--);
        _startGracePeriodCountdown();
      } else if (mounted &&
          _gracePeriodSeconds == 0 &&
          !_isInsideGeofence &&
          !_isOnBreak) {
        _markAsAbsent();
      }
    });
  }

  void _markAsAbsent() {
    setState(() => _isAttendanceActive = false);
    _showAbsentDialog();
  }

  void _startBreak(int minutes) {
    setState(() {
      _isOnBreak = true;
      _breakTimeRemaining = minutes * 60;
    });
    _startBreakCountdown();
  }

  void _startBreakCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _breakTimeRemaining > 0) {
        setState(() => _breakTimeRemaining--);
        _startBreakCountdown();
      } else if (mounted && _breakTimeRemaining == 0) {
        setState(() => _isOnBreak = false);
        _showBreakEndDialog();
      }
    });
  }

  // ✅ CORREGIDO: Agregada verificación mounted
  Future<void> _registerAttendance() async {
    if (_currentEvento == null || _currentUser == null) return;

    try {
      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _currentEvento!.id!,
        latitud: _userLat,
        longitud: _userLng,
      );

      // ✅ Verificar que el widget esté montado antes de usar context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al registrar asistencia: $e');
    }
  }

  void _simulateReturnToArea() {
    setState(() {
      _isInsideGeofence = true;
      _isAttendanceActive = true;
      _gracePeriodSeconds = 60;
    });
    _graceController.reset();

    if (_currentEvento != null && _currentUser != null) {
      _registerAttendance();
    }
  }

  void _showAbsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Asistencia Perdida'),
        content: const Text(
          'Has salido del área permitida y se ha agotado el período de gracia. '
          'Tu asistencia ha sido marcada como ausente.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateReturnToArea();
            },
            child: const Text('Reingresar al Área'),
          ),
        ],
      ),
    );
  }

  void _showBreakEndDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Fin del Descanso'),
        content: const Text(
          'Tu período de descanso ha terminado. La asistencia se reanudará automáticamente.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showBreakOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Duración del Descanso'),
        content: const Text('Selecciona la duración del período de descanso:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ...AppConstants.defaultBreakDurations.map(
            (minutes) => TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startBreak(minutes);
              },
              child: Text('$minutes min'),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORREGIDO: Implementado diálogo de configuraciones
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚙️ Configuraciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Precisión GPS'),
              // ignore: prefer_const_constructors
              subtitle: Text('${AppConstants.defaultLocationAccuracy}m'),
              onTap: () {
                // Configuración de precisión GPS
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Período de gracia'),
              subtitle:
                  Text('${AppConstants.gracePeriodDuration.inMinutes} min'),
              onTap: () {
                // Configuración de período de gracia
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.of(context).pop();
                await AppRouter.logout();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ===== MÉTODOS MODO ESTUDIANTE =====

  void _initializeStudentMode() {
    if (widget.isStudentMode && widget.eventoId != null) {
      _findEventById(widget.eventoId!);
      _initializeAttendanceStatus();
      _startLocationTracking();
    }
  }

  /// Verifica y solicita permisos de ubicación
  Future<void> _checkLocationPermissions() async {
    final hasPermissions = await _permissionService.hasLocationPermissions();

    setState(() => _hasLocationPermissions = hasPermissions);

    if (hasPermissions) {
      _startRealLocationTracking();
    } else {
      // AMBOS roles necesitan GPS - solicitar permisos
      _showPermissionDialog();
    }
  }

  /// Muestra dialog de permisos
  void _showPermissionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionHandlerWidget(
            onPermissionGranted: () {
              setState(() => _hasLocationPermissions = true);
              _startRealLocationTracking();
            },
            onPermissionDenied: () {
              // Continuar con coordenadas simuladas
              debugPrint('Permisos denegados - usando coordenadas simuladas');
            },
          ),
        );
      }
    });
  }

  /// Inicia tracking con GPS real
  void _startRealLocationTracking() async {
    try {
      final position = await _permissionService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
        });
        debugPrint('📱 Ubicación estudiante: $_userLat, $_userLng');
        debugPrint('📍 Ubicación evento: $_eventLat, $_eventLng');
        debugPrint('📏 Distancia calculada: ${_calculateDistance()}m');
      }

      // Iniciar stream de ubicación para actualizaciones continuas
      _permissionService.getLocationStream().listen((position) {
        if (mounted) {
          setState(() {
            _userLat = position.latitude;
            _userLng = position.longitude;
          });
        }
      });
    } catch (e) {
      debugPrint('Error obteniendo ubicación real: $e');
    }
  }

  void _findEventById(String eventoId) {
    try {
      _currentEvento = _eventos.firstWhere((evento) => evento.id == eventoId);

      // ✅ CARGAR COORDENADAS DEL EVENTO ESPECÍFICO
      if (_currentEvento != null) {
        setState(() {
          _eventLat = _currentEvento!.ubicacion.latitud;
          _eventLng = _currentEvento!.ubicacion.longitud;
          _eventRange = _currentEvento!.rangoPermitido;
        });

        debugPrint('📍 Evento: ${_currentEvento!.titulo}');
        debugPrint('📍 Ubicación evento: $_eventLat, $_eventLng');
        debugPrint('📍 Rango evento: ${_eventRange}m');
      }
    } catch (e) {
      debugPrint('Evento no encontrado: $eventoId');
    }
  }

  void _initializeAttendanceStatus() {
    if (widget.eventoId != null) {
      setState(() {
        _attendanceStatus = StudentAttendanceStatus.initial(widget.eventoId!);
      });
    }
  }

  void _startLocationTracking() {
    if (!widget.isStudentMode) return;

    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5), // Cada 5 segundos
      (timer) => _updateStudentLocation(),
    );

    // Primera actualización inmediata
    _updateStudentLocation();
  }

  Future<void> _updateStudentLocation() async {
    if (_currentUser == null || widget.eventoId == null) return;

    try {
      final response = await _locationService.updateUserLocation(
        userId: _currentUser!.id,
        latitude: _userLat, // GPS real del estudiante
        longitude: _userLng, // GPS real del estudiante
        eventoId: widget.eventoId,
      );

      if (response.success && response.data != null && mounted) {
        final newStatus = StudentAttendanceStatus.fromLocationResponse(
          eventoId: widget.eventoId!,
          locationData: response.data!,
          hasRegistered: _attendanceStatus?.hasRegistered ?? false,
          registeredAt: _attendanceStatus?.registeredAt,
        );

        setState(() {
          _attendanceStatus = newStatus;
          _isInsideGeofence = newStatus.isInsideGeofence;
        });

        // Manejar período de gracia
        if (newStatus.state == AttendanceState.gracePeriod) {
          _startStudentGracePeriod();
        }

        debugPrint('Estado asistencia actualizado: $newStatus');
      }
    } catch (e) {
      debugPrint('Error actualizando ubicación estudiante: $e');
      if (mounted) {
        setState(() {
          _attendanceStatus = _attendanceStatus?.copyWith(
            state: AttendanceState.error,
            errorMessage: 'Error de conexión',
          );
        });
      }
    }
  }

  void _startStudentGracePeriod() {
    if (_attendanceStatus?.state != AttendanceState.gracePeriod) return;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _attendanceStatus?.state != AttendanceState.gracePeriod) {
        timer.cancel();
        return;
      }

      final currentSeconds = _attendanceStatus!.gracePeriodSeconds;
      if (currentSeconds <= 0) {
        timer.cancel();
        setState(() {
          _attendanceStatus = _attendanceStatus!.copyWith(
            state: AttendanceState.outsideRange,
            gracePeriodSeconds: 0,
          );
        });
      } else {
        setState(() {
          _attendanceStatus = _attendanceStatus!.copyWith(
            gracePeriodSeconds: currentSeconds - 1,
          );
        });
      }
    });
  }

  Future<void> _registerStudentAttendance() async {
    if (_attendanceStatus?.canRegisterAttendance != true) return;

    setState(() => _isRegisteringAttendance = true);

    try {
      final response = await _asistenciaService.registrarAsistencia(
        eventoId: widget.eventoId!,
        latitud: _userLat, // GPS real del estudiante
        longitud: _userLng, // GPS real del estudiante
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _attendanceStatus = _attendanceStatus!.copyWith(
              state: AttendanceState.registered,
              hasRegistered: true,
              registeredAt: DateTime.now(),
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Asistencia registrada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${response.error ?? "Error al registrar"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegisteringAttendance = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightGray,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(
          widget.isAdminMode ? 'Panel de Administrador' : 'Mi Asistencia',
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
          ),
          // ✅ CORREGIDO: Implementada navegación a configuraciones
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          StatusPanel(
            userName: widget.userName,
            isAttendanceActive: _isAttendanceActive,
            isInsideGeofence: _isInsideGeofence,
            isOnBreak: _isOnBreak,
            gracePeriodSeconds: _gracePeriodSeconds,
            breakTimeRemaining: _breakTimeRemaining,
            currentEvento: _currentEvento,
            graceColorAnimation: _graceColorAnimation,
          ),
          Expanded(
            child: MapArea(
              currentEvento: _currentEvento,
              isOnBreak: _isOnBreak,
              isInsideGeofence: _isInsideGeofence,
              pulseAnimation: _pulseAnimation,
              userLat: _userLat,
              userLng: _userLng,
            ),
          ),

          // Indicador GPS para TODOS los usuarios
          // Indicador GPS para TODOS los usuarios
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (_hasLocationPermissions ? Colors.green : Colors.red)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                  size: 12,
                  color: _hasLocationPermissions ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _hasLocationPermissions ? 'GPS Activo' : 'GPS Desactivado',
                  style: TextStyle(
                    fontSize: 10,
                    color: _hasLocationPermissions ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 🆕 AGREGAR AQUÍ - Botón de asistencia para estudiantes
          if (widget.isStudentMode && _attendanceStatus != null)
            AttendanceButtonWidget(
              attendanceStatus: _attendanceStatus!,
              isLoading: _isRegisteringAttendance,
              onPressed: _registerStudentAttendance,
            ),

          ControlPanel(
            isAdminMode: widget.isAdminMode,
            isOnBreak: _isOnBreak,
            isAttendanceActive: _isAttendanceActive,
            isInsideGeofence: _isInsideGeofence,
            currentEvento: _currentEvento,
            onStartBreak: _showBreakOptions,
            onEndBreak: () {
              setState(() {
                _isOnBreak = false;
                _breakTimeRemaining = 0;
              });
            },
            onRegisterAttendance: _registerAttendance,
            onRefreshData: _initializeData,
          ),
        ],
      ),
    );
  }
}
