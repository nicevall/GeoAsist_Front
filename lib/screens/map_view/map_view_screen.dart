// lib/screens/map_view_screen.dart
import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../core/app_constants.dart';
import '../../services/evento_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import 'widgets/status_panel.dart';
import 'widgets/map_area.dart';
import 'widgets/control_panel.dart';

class MapViewScreen extends StatefulWidget {
  final bool isAdminMode;
  final String userName;

  const MapViewScreen({
    super.key,
    this.isAdminMode = false,
    this.userName = "Usuario",
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

  // Coordenadas simuladas
  final double _centerLat = -0.1807;
  final double _centerLng = -78.4678;
  final double _userLat = -0.1805;
  final double _userLng = -78.4680;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _graceController.dispose();
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

  Future<void> _registerAttendance() async {
    if (_currentEvento == null || _currentUser == null) return;

    try {
      final response = await _asistenciaService.registrarAsistencia(
        eventoId: _currentEvento!.id!,
        latitud: _userLat,
        longitud: _userLng,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navegar a configuraciones
            },
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
            ),
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
