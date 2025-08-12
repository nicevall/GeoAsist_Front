// lib/screens/map_view/map_view_screen.dart - FASE A1.2 REFACTORIZADO
// 🎯 ELIMINACIÓN DE VARIABLES HARDCODEADAS - USA StudentAttendanceManager
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/permission_service.dart';
import '../../services/student_attendance_manager.dart';
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
  // 🎯 SERVICIOS - StudentAttendanceManager como fuente principal
  final StudentAttendanceManager _attendanceManager =
      StudentAttendanceManager();
  final EventoService _eventoService = EventoService();
  final PermissionService _permissionService = PermissionService();

  // 🎯 CONTROLADORES DE ANIMACIÓN (mantenidos para compatibilidad)
  late AnimationController _pulseController;
  late AnimationController _graceController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _graceColorAnimation;

  // 🎯 ESTADO REACTIVO - REEMPLAZA VARIABLES HARDCODEADAS
  AttendanceState _currentAttendanceState = AttendanceState.initial();
  LocationResponseModel? _currentLocationResponse;

  // 🎯 VARIABLES DE UI (mantenidas para widgets existentes)
  bool _isLoading = true;
  bool _hasLocationPermissions = false;
  bool _isRegisteringAttendance = false;

  // 🎯 DATOS BÁSICOS
  List<Evento> _eventos = [];
  Evento? _currentEvento;

  // 🎯 STREAMS SUBSCRIPTIONS
  StreamSubscription<AttendanceState>? _stateSubscription;
  StreamSubscription<LocationResponseModel>? _locationSubscription;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animación
    _initializeAnimations();

    // Inicializar manager y cargar datos
    _initializeAttendanceManager();
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

  Future<void> _initializeAttendanceManager() async {
    debugPrint('🎯 Inicializando MapViewScreen con StudentAttendanceManager');

    try {
      // 1. Verificar permisos de ubicación
      await _checkLocationPermissions();

      // 2. Inicializar el AttendanceManager
      await _attendanceManager.initialize();

      // 3. Configurar listeners reactivos
      _setupAttendanceListeners();

      // 4. Cargar datos básicos
      await _loadInitialData();

      // 5. Si hay eventoId específico, iniciar tracking
      if (widget.eventoId != null && widget.eventoId!.isNotEmpty) {
        await _startTrackingForEvent(widget.eventoId!);
      }
    } catch (e) {
      debugPrint('❌ Error inicializando MapViewScreen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error inicializando la pantalla: $e');
      }
    }
  }

  void _setupAttendanceListeners() {
    // 🎯 LISTENER PRINCIPAL DE ESTADO - REEMPLAZA VARIABLES HARDCODEADAS
    _stateSubscription = _attendanceManager.stateStream.listen(
      (AttendanceState newState) {
        if (mounted) {
          setState(() {
            _currentAttendanceState = newState;

            // Actualizar animaciones basadas en el estado real
            if (newState.isInGracePeriod) {
              _graceController.repeat();
            } else {
              _graceController.stop();
            }
          });

          // Log para debugging
          debugPrint('🎯 Estado actualizado: ${newState.statusText}');
        }
      },
      onError: (error) {
        debugPrint('❌ Error en stream de estado: $error');
        if (mounted) {
          _showErrorSnackBar('Error en tiempo real: $error');
        }
      },
    );

    // 🎯 LISTENER DE UBICACIÓN - DATOS REALES DEL BACKEND
    _locationSubscription = _attendanceManager.locationStream.listen(
      (LocationResponseModel locationResponse) {
        if (mounted) {
          setState(() {
            _currentLocationResponse = locationResponse;
          });

          debugPrint(
              '📍 Ubicación actualizada: ${locationResponse.formattedDistance}');
        }
      },
      onError: (error) {
        debugPrint('❌ Error en stream de ubicación: $error');
      },
    );
  }

  Future<void> _loadInitialData() async {
    try {
      // ✅ SIMPLIFICADO: No necesitamos cargar usuario aquí ya que StudentAttendanceManager lo maneja

      // ✅ CORREGIDO: EventoService.obtenerEventos() devuelve List<Evento> directamente
      final eventos = await _eventoService.obtenerEventos();

      setState(() {
        _eventos = eventos;
      });

      // Si hay eventoId específico, buscar el evento
      if (widget.eventoId != null && widget.eventoId!.isNotEmpty) {
        final evento = _findEventById(widget.eventoId!);
        if (evento != null) {
          setState(() {
            _currentEvento = evento;
          });
        }
      }

      // Marcar como cargado
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos iniciales: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startTrackingForEvent(String eventoId) async {
    final evento = _findEventById(eventoId);
    if (evento != null) {
      try {
        await _attendanceManager.startEventTracking(evento);
        debugPrint('✅ Tracking iniciado para evento: ${evento.titulo}');
      } catch (e) {
        debugPrint('❌ Error iniciando tracking: $e');
        _showErrorSnackBar('Error iniciando tracking: $e');
      }
    } else {
      debugPrint('⚠️ Evento no encontrado: $eventoId');
    }
  }

  Evento? _findEventById(String eventoId) {
    try {
      return _eventos.firstWhere((evento) => evento.id == eventoId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkLocationPermissions() async {
    // ✅ CORREGIDO: Usar método correcto del PermissionService
    final hasPermissions = await _permissionService.hasLocationPermissions();
    if (mounted) {
      setState(() {
        _hasLocationPermissions = hasPermissions;
      });
    }
  }

  // 🎯 MÉTODOS DE CONTROL - USANDO ATTENDANCEMANAGER

  Future<void> _startBreak() async {
    try {
      await _attendanceManager.pauseTracking();
      _showSuccessSnackBar('Período de descanso iniciado');
    } catch (e) {
      _showErrorSnackBar('Error iniciando descanso: $e');
    }
  }

  Future<void> _endBreak() async {
    try {
      await _attendanceManager.resumeTracking();
      _showSuccessSnackBar('Período de descanso terminado');
    } catch (e) {
      _showErrorSnackBar('Error terminando descanso: $e');
    }
  }

  Future<void> _registerAttendance() async {
    if (!_currentAttendanceState.canRegisterAttendance) {
      _showErrorSnackBar('No se puede registrar asistencia en este momento');
      return;
    }

    setState(() => _isRegisteringAttendance = true);

    try {
      final success = await _attendanceManager.registerAttendance();

      if (success) {
        _showSuccessSnackBar('Asistencia registrada exitosamente');
      } else {
        _showErrorSnackBar('Error registrando asistencia');
      }
    } catch (e) {
      _showErrorSnackBar('Error registrando asistencia: $e');
    } finally {
      if (mounted) {
        setState(() => _isRegisteringAttendance = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadInitialData();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuraciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Permisos de ubicación'),
              trailing: Icon(
                _hasLocationPermissions ? Icons.check : Icons.close,
                color: _hasLocationPermissions ? Colors.green : Colors.red,
              ),
              onTap: _checkLocationPermissions,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Estado del tracking'),
              subtitle: Text(_currentAttendanceState.statusText),
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

  // 🎯 MÉTODOS AUXILIARES

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Limpiar controladores de animación
    _pulseController.dispose();
    _graceController.dispose();

    // Cancelar subscriptions
    _stateSubscription?.cancel();
    _locationSubscription?.cancel();

    // Limpiar AttendanceManager si es necesario
    // No llamamos dispose() aquí porque puede ser usado por otras pantallas

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightGray,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryOrange),
              SizedBox(height: 20),
              Text('Inicializando sistema de asistencia...'),
            ],
          ),
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
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🎯 NUEVO WIDGET DE ESTADO DE ASISTENCIA - DATOS REALES
          AttendanceStatusWidget(
            attendanceState: _currentAttendanceState,
            locationResponse: _currentLocationResponse,
            userName: widget.userName,
            currentEvento: _currentEvento,
          ),

          // 🎯 WIDGET DE PERÍODO DE GRACIA - SOLO SI APLICA
          if (_currentAttendanceState.isInGracePeriod)
            GracePeriodWidget(
              gracePeriodSeconds: _currentAttendanceState.gracePeriodRemaining,
              graceColorAnimation: _graceColorAnimation,
            ),

          // 🎯 MAPA - USANDO COORDENADAS REALES DEL MANAGER
          Expanded(
            child: MapArea(
              // Datos reales del evento
              currentEvento: _currentEvento,
              // Estados reales del manager
              isOnBreak: _currentAttendanceState.trackingStatus ==
                  TrackingStatus.paused,
              isInsideGeofence: _currentAttendanceState.isInsideGeofence,
              pulseAnimation: _pulseAnimation,
              // Coordenadas reales del usuario
              userLat: _currentAttendanceState.userLatitude,
              userLng: _currentAttendanceState.userLongitude,
            ),
          ),

          // 🎯 INDICADOR GPS - ESTADO REAL
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
                if (_currentLocationResponse != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${_currentLocationResponse!.formattedDistance}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),

          // 🎯 BOTÓN DE ASISTENCIA PARA ESTUDIANTES - ESTADO REAL
          if (widget.isStudentMode &&
              _currentAttendanceState.currentEvent != null)
            AttendanceButtonWidget(
              attendanceState: _currentAttendanceState,
              locationResponse: _currentLocationResponse,
              isLoading: _isRegisteringAttendance,
              onPressed: _registerAttendance,
            ),

          // 🎯 PANEL DE CONTROL - USANDO ESTADOS REALES
          ControlPanel(
            isAdminMode: widget.isAdminMode,
            isOnBreak:
                _currentAttendanceState.trackingStatus == TrackingStatus.paused,
            isAttendanceActive:
                _currentAttendanceState.trackingStatus == TrackingStatus.active,
            isInsideGeofence: _currentAttendanceState.isInsideGeofence,
            currentEvento: _currentEvento,
            onStartBreak: _startBreak,
            onEndBreak: _endBreak,
            onRegisterAttendance: _registerAttendance,
            onRefreshData: _refreshData,
          ),

          // 🎯 OVERLAY DE NOTIFICACIONES - NUEVO WIDGET
          NotificationOverlayWidget(
            attendanceState: _currentAttendanceState,
          ),
        ],
      ),
    );
  }
}
