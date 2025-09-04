// lib/screens/attendance/attendance_tracking_screen_modular.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/colors.dart';
import 'widgets/attendance_tracking_animations.dart';
import 'widgets/attendance_tracking_stats.dart';
import 'managers/attendance_tracking_manager.dart';

class AttendanceTrackingScreenModular extends StatefulWidget {
  final String userName;
  final String? eventoId;

  const AttendanceTrackingScreenModular({
    super.key,
    this.userName = 'Usuario',
    this.eventoId,
  });

  @override
  State<AttendanceTrackingScreenModular> createState() =>
      _AttendanceTrackingScreenModularState();
}

class _AttendanceTrackingScreenModularState extends State<AttendanceTrackingScreenModular>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  // Manager y animaciones
  late AttendanceTrackingManager _manager;
  late AttendanceTrackingAnimations _animations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Inicializar manager
    _manager = AttendanceTrackingManager();
    _manager.onStateChanged = () => setState(() {});
    _manager.onError = _showError;
    
    // Inicializar animaciones
    _animations = AttendanceTrackingAnimations();
    _animations.initializeAnimations(this);
    
    // Inicializar datos
    _manager.initialize(eventoId: widget.eventoId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animations.dispose();
    _manager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _manager.handleAppLifecycleChange(state);
  }

  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Asistencia'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manager.refreshData,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (!_manager.hasPermissions) {
      return _buildPermissionsRequired();
    }

    if (_manager.activeEvent == null) {
      return _buildNoActiveEvent();
    }

    return RefreshIndicator(
      onRefresh: _manager.refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildTrackingHeader(),
            _buildStatusIndicator(),
            AttendanceTrackingStats(
              activeEvent: _manager.activeEvent,
              attendanceHistory: _manager.attendanceHistory,
              distanceFromCenter: _manager.distanceFromCenter,
              currentAccuracy: _manager.currentAccuracy,
              lastUpdateTime: _manager.lastUpdateTime,
              timeInEvent: _manager.timeInEvent,
              exitWarningCount: _manager.exitWarningCount,
            ),
            _buildGracePeriodInfo(),
            AttendanceHistoryWidget(
              attendanceHistory: _manager.attendanceHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Permisos Requeridos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta aplicación necesita permisos de ubicación para funcionar correctamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _manager.initialize(eventoId: widget.eventoId),
              icon: const Icon(Icons.settings),
              label: const Text('Configurar Permisos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No hay eventos activos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay eventos disponibles para seguimiento en este momento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _manager.refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Hola, ${widget.userName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _manager.activeEvent?.titulo ?? 'Sin evento',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TrackingStatusIndicator(
            trackingAnimation: _animations.trackingAnimation,
            pulseAnimation: _animations.pulseAnimation,
            isTrackingActive: _manager.isTrackingActive,
            isInGeofence: _manager.isInGeofence,
            trackingStatus: _manager.trackingStatus,
          ),
          const SizedBox(height: 16),
          Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGracePeriodInfo() {
    if (_manager.geofenceSecondsRemaining > 0 || _manager.appClosedSecondsRemaining > 0) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_manager.geofenceSecondsRemaining > 0)
                _buildGraceTimer(
                  'Tiempo para regresar al área',
                  _manager.geofenceSecondsRemaining,
                  Icons.location_off,
                  Colors.orange,
                ),
              if (_manager.appClosedSecondsRemaining > 0)
                _buildGraceTimer(
                  'Tiempo para abrir la app',
                  _manager.appClosedSecondsRemaining,
                  Icons.phone_android,
                  Colors.red,
                ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGraceTimer(String label, int seconds, IconData icon, Color color) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (!_manager.hasPermissions || _manager.activeEvent == null) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: _toggleTracking,
      backgroundColor: _manager.isTrackingActive ? Colors.red : AppColors.primaryColor,
      foregroundColor: Colors.white,
      icon: Icon(
        _manager.isTrackingActive ? Icons.stop : Icons.play_arrow,
      ),
      label: Text(
        _manager.isTrackingActive ? 'Detener' : 'Iniciar',
      ),
    );
  }

  Future<void> _toggleTracking() async {
    HapticFeedback.mediumImpact();
    
    if (_manager.isTrackingActive) {
      await _manager.stopTracking();
      _animations.stopTrackingAnimation();
      _animations.stopPulseAnimation();
    } else {
      await _manager.startTracking();
      _animations.startTrackingAnimation();
      _animations.startPulseAnimation();
    }
  }

  String _getStatusText() {
    if (!_manager.isTrackingActive) {
      return 'Seguimiento inactivo';
    } else if (_manager.isInGeofence) {
      return 'Dentro del área del evento';
    } else {
      return 'Fuera del área del evento';
    }
  }

  Color _getStatusColor() {
    if (!_manager.isTrackingActive) {
      return Colors.grey;
    } else if (_manager.isInGeofence) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}