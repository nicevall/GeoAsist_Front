// lib/screens/map_view_screen.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../core/app_constants.dart';
import '../widgets/custom_button.dart';

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
  // Variables de estado para el control de asistencia
  bool _isInsideGeofence = true;
  bool _isOnBreak = false;
  bool _isAttendanceActive = true;
  int _gracePeriodSeconds = 60; // Período de gracia de 1 minuto
  int _breakTimeRemaining = 0; // Tiempo de descanso restante en segundos

  // Variables para animaciones
  late AnimationController _pulseController;
  late AnimationController _graceController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _graceColorAnimation;

  // Coordenadas del ejemplo (Universidad Internacional del Ecuador - Quito)
  final double _centerLat = -0.1807;
  final double _centerLng = -78.4678;
  final double _userLat = -0.1805;
  final double _userLng = -78.4680;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLocationUpdates();
  }

  void _initializeAnimations() {
    // Animación de pulso para el indicador de ubicación
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación para el período de gracia
    _graceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _graceColorAnimation = ColorTween(
      begin: AppColors.primaryOrange,
      end: Colors.red,
    ).animate(_graceController);
  }

  void _startLocationUpdates() {
    // Simulación de actualizaciones de ubicación
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isInsideGeofence = false;
          _gracePeriodSeconds = 60;
        });
        _startGracePeriod();
      }
    });
  }

  void _startGracePeriod() {
    _graceController.forward();
    _startGracePeriodCountdown();
  }

  void _startGracePeriodCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _gracePeriodSeconds > 0 && !_isInsideGeofence) {
        setState(() {
          _gracePeriodSeconds--;
        });
        _startGracePeriodCountdown();
      } else if (mounted && _gracePeriodSeconds == 0 && !_isInsideGeofence) {
        // Marcar como ausente
        _markAsAbsent();
      }
    });
  }

  void _markAsAbsent() {
    setState(() {
      _isAttendanceActive = false;
    });
    _showAbsentDialog();
  }

  void _showAbsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('⚠️ Asistencia Perdida'),
            content: const Text(
              'Has salido del área permitida y se ha agotado el período de gracia. '
              'Tu asistencia ha sido marcada como ausente.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Simular regreso al área
                  setState(() {
                    _isInsideGeofence = true;
                    _isAttendanceActive = true;
                    _gracePeriodSeconds = 60;
                  });
                  _graceController.reset();
                },
                child: const Text('Reingresar al Área'),
              ),
            ],
          ),
    );
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
        setState(() {
          _breakTimeRemaining--;
        });
        _startBreakCountdown();
      } else if (mounted && _breakTimeRemaining == 0) {
        setState(() {
          _isOnBreak = false;
        });
        _showBreakEndDialog();
      }
    });
  }

  void _showBreakEndDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navegar a configuraciones
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de estado superior
          _buildStatusPanel(),

          // Área del mapa
          Expanded(child: _buildMapArea()),

          // Panel de controles inferior
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Saludo y estado general
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      _isAttendanceActive
                          ? AppColors.secondaryTeal
                          : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAttendanceActive ? Icons.check : Icons.close,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${widget.userName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Información adicional basada en el estado
          if (!_isInsideGeofence && _isAttendanceActive) ...[
            const SizedBox(height: 15),
            _buildGracePeriodWarning(),
          ],

          if (_isOnBreak) ...[const SizedBox(height: 15), _buildBreakTimer()],
        ],
      ),
    );
  }

  Widget _buildGracePeriodWarning() {
    return AnimatedBuilder(
      animation: _graceColorAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _graceColorAnimation.value!.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _graceColorAnimation.value!, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _graceColorAnimation.value,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ Período de Gracia Activo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _graceColorAnimation.value,
                      ),
                    ),
                    Text(
                      'Regresa al área en: ${_formatTime(_gracePeriodSeconds)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakTimer() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryTeal, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.coffee, color: AppColors.secondaryTeal, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '☕ Descanso Activo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryTeal,
                  ),
                ),
                Text(
                  'Tiempo restante: ${_formatTime(_breakTimeRemaining)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Simulación del mapa (reemplazar con GoogleMap cuando se integre)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5E8), Color(0xFFD4F1D4)],
                ),
              ),
              child: Stack(
                children: [
                  // Patrón de calles simulado
                  ..._buildStreetPattern(),

                  // Geofence circular
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _isOnBreak
                                  ? AppColors.secondaryTeal.withValues(
                                    alpha: 0.5,
                                  )
                                  : AppColors.primaryOrange.withValues(
                                    alpha: 0.8,
                                  ),
                          width: 3,
                        ),
                        color:
                            _isOnBreak
                                ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                                : AppColors.primaryOrange.withValues(
                                  alpha: 0.1,
                                ),
                      ),
                    ),
                  ),

                  // Indicador de ubicación del usuario
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.5 - 16,
                    top: MediaQuery.of(context).size.height * 0.4,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color:
                                  _isInsideGeofence ? Colors.blue : Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isInsideGeofence
                                          ? Colors.blue
                                          : Colors.red)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Centro del geofence
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.5 - 10,
                    top: MediaQuery.of(context).size.height * 0.35,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información del mapa en la parte superior
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      '📍 UIDE Campus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStreetPattern() {
    return [
      // Líneas horizontales simulando calles
      Positioned(
        top: 50,
        left: 0,
        right: 0,
        child: Container(height: 2, color: Colors.grey.withValues(alpha: 0.3)),
      ),
      Positioned(
        top: 150,
        left: 0,
        right: 0,
        child: Container(height: 2, color: Colors.grey.withValues(alpha: 0.3)),
      ),
      Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Container(height: 2, color: Colors.grey.withValues(alpha: 0.3)),
      ),
      // Líneas verticales simulando calles
      Positioned(
        top: 0,
        bottom: 0,
        left: 80,
        child: Container(width: 2, color: Colors.grey.withValues(alpha: 0.3)),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 80,
        child: Container(width: 2, color: Colors.grey.withValues(alpha: 0.3)),
      ),
    ];
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.isAdminMode) ...[
            _buildAdminControls(),
          ] else ...[
            _buildAttendeeControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminControls() {
    return Column(
      children: [
        const Text(
          '🔧 Controles de Administrador',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: _isOnBreak ? 'Terminar Descanso' : 'Iniciar Descanso',
                onPressed: () {
                  if (_isOnBreak) {
                    setState(() {
                      _isOnBreak = false;
                      _breakTimeRemaining = 0;
                    });
                  } else {
                    _showBreakOptions();
                  }
                },
                isPrimary: !_isOnBreak,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: 'Ver Asistentes',
                onPressed: () {
                  // TODO: Mostrar lista de asistentes
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendeeControls() {
    return Column(
      children: [
        const Text(
          '📱 Estado de Asistencia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color:
                      _isAttendanceActive
                          ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        _isAttendanceActive
                            ? AppColors.secondaryTeal
                            : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isAttendanceActive ? Icons.check_circle : Icons.cancel,
                      color:
                          _isAttendanceActive
                              ? AppColors.secondaryTeal
                              : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAttendanceActive ? 'Presente' : 'Ausente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _isAttendanceActive
                                ? AppColors.secondaryTeal
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color:
                      _isInsideGeofence
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isInsideGeofence ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isInsideGeofence
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _isInsideGeofence ? Colors.green : Colors.orange,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isInsideGeofence ? 'En Área' : 'Fuera de Área',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isInsideGeofence ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBreakOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('⏰ Duración del Descanso'),
            content: const Text(
              'Selecciona la duración del período de descanso:',
            ),
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

  String _getStatusMessage() {
    if (_isOnBreak) {
      return '☕ En período de descanso';
    } else if (!_isAttendanceActive) {
      return '❌ Asistencia perdida';
    } else if (!_isInsideGeofence) {
      return '⚠️ Fuera del área permitida';
    } else {
      return '✅ Asistencia activa';
    }
  }

  Color _getStatusColor() {
    if (_isOnBreak) {
      return AppColors.secondaryTeal;
    } else if (!_isAttendanceActive) {
      return Colors.red;
    } else if (!_isInsideGeofence) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _graceController.dispose();
    super.dispose();
  }
}
