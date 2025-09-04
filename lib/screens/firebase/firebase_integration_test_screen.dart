// lib/screens/firebase/firebase_integration_test_screen.dart
// Pantalla para probar la integración completa Firebase + Backend híbrido

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase/hybrid_backend_service.dart';
import '../../services/firebase/hybrid_location_service.dart';
// Unused import removed
import 'package:geolocator/geolocator.dart';

class FirebaseIntegrationTestScreen extends StatefulWidget {
  const FirebaseIntegrationTestScreen({super.key});

  @override
  State<FirebaseIntegrationTestScreen> createState() => _FirebaseIntegrationTestScreenState();
}

class _FirebaseIntegrationTestScreenState extends State<FirebaseIntegrationTestScreen> {
  final HybridBackendService _backendService = HybridBackendService();
  final HybridLocationService _locationService = HybridLocationService();
  
  bool _isInitializing = false;
  bool _isServicesInitialized = false;
  String _statusMessage = 'Servicios no inicializados';
  
  Map<String, dynamic> _serviceStatus = {};
  Map<String, dynamic> _testResults = {};
  Position? _currentPosition;
  
  // Datos de prueba
  final String _testUserId = 'test_user_flutter';
  final String _testUserRole = 'estudiante';

  @override
  void initState() {
    super.initState();
    _setupLocationCallbacks();
  }

  void _setupLocationCallbacks() {
    _locationService.onLocationUpdate = (position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    };

    _locationService.onGeofenceResult = (result) {
      if (mounted) {
        setState(() {
          _testResults['last_geofence_result'] = result;
        });
        
        if (result['success'] == true) {
          _showSuccessSnackBar('Geofencing procesado exitosamente');
        }
      }
    };

    _locationService.onAttendanceRegistered = (attendance) {
      if (mounted) {
        _showSuccessSnackBar(
          'Asistencia registrada: ${attendance['eventoNombre']}'
        );
      }
    };

    _locationService.onError = (error) {
      if (mounted) {
        _showErrorSnackBar('Error en ubicación: $error');
      }
    };
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Inicializando servicios...';
    });

    try {
      // 1. Inicializar backend service
      _statusMessage = 'Conectando con backend...';
      setState(() {});
      
      await _backendService.initialize(_testUserId, _testUserRole);
      
      // 2. Inicializar location service
      _statusMessage = 'Configurando servicios de ubicación...';
      setState(() {});
      
      await _locationService.initialize();
      
      // 3. Obtener estados
      final backendStatus = await _backendService.getServiceStatus();
      final locationStatus = _locationService.getServiceStatus();
      
      setState(() {
        _serviceStatus = {
          'backend': backendStatus,
          'location': locationStatus,
        };
        _isServicesInitialized = true;
        _statusMessage = 'Servicios inicializados correctamente ✅';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error inicializando servicios: $e';
      });
      _showErrorSnackBar(_statusMessage);
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _runComprehensiveTests() async {
    if (!_isServicesInitialized) {
      _showErrorSnackBar('Inicializa los servicios primero');
      return;
    }

    setState(() {
      _statusMessage = 'Ejecutando pruebas completas...';
    });

    try {
      // Pruebas del backend
      final backendTests = await _backendService.runComprehensiveTest();
      
      // Pruebas de ubicación
      final locationTests = await _locationService.runLocationTest();
      
      setState(() {
        _testResults = {
          'backend_tests': backendTests,
          'location_tests': locationTests,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _statusMessage = 'Pruebas completadas ✅';
      });
      
      final allPassed = (backendTests['overall_status'] == true) && 
                       (locationTests['overall_status'] == true);
      
      if (allPassed) {
        _showSuccessSnackBar('Todas las pruebas pasaron exitosamente 🎉');
      } else {
        _showErrorSnackBar('Algunas pruebas fallaron. Revisa los detalles.');
      }
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error en pruebas: $e';
      });
      _showErrorSnackBar(_statusMessage);
    }
  }

  Future<void> _sendTestNotification() async {
    if (!_isServicesInitialized) {
      _showErrorSnackBar('Inicializa los servicios primero');
      return;
    }

    try {
      final success = await _backendService.sendTestNotification(
        '🧪 Prueba desde Flutter',
        'Esta notificación fue enviada desde la app Flutter a través del backend híbrido'
      );
      
      if (success) {
        _showSuccessSnackBar('Notificación de prueba enviada ✅');
      } else {
        _showErrorSnackBar('Error enviando notificación de prueba');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _testGeofencingManually() async {
    if (!_isServicesInitialized) {
      _showErrorSnackBar('Inicializa los servicios primero');
      return;
    }

    setState(() {
      _statusMessage = 'Probando geofencing manual...';
    });

    try {
      final result = await _locationService.checkGeofenceManually();
      
      setState(() {
        _testResults['manual_geofence'] = result;
        _statusMessage = result?['success'] == true 
            ? 'Geofencing manual exitoso ✅' 
            : 'Geofencing completado (sin eventos activos)';
      });
      
      if (result?['success'] == true) {
        _showSuccessSnackBar('Geofencing procesado exitosamente');
      } else {
        _showInfoSnackBar('Geofencing procesado - ${result?['mensaje'] ?? 'Sin eventos activos'}');
      }
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error en geofencing: $e';
      });
      _showErrorSnackBar(_statusMessage);
    }
  }

  Future<void> _startLocationTracking() async {
    if (!_isServicesInitialized) {
      _showErrorSnackBar('Inicializa los servicios primero');
      return;
    }

    try {
      await _locationService.startLocationTracking(
        enableGeofencing: true,
        enableBackgroundTracking: false,
      );
      
      setState(() {
        _statusMessage = 'Seguimiento de ubicación iniciado 🎯';
      });
      
      _showSuccessSnackBar('Seguimiento iniciado - El geofencing automático está activo');
    } catch (e) {
      _showErrorSnackBar('Error iniciando seguimiento: $e');
    }
  }

  Future<void> _stopLocationTracking() async {
    await _locationService.stopLocationTracking();
    
    setState(() {
      _statusMessage = 'Seguimiento de ubicación detenido ⏹️';
      _currentPosition = null;
    });
    
    _showInfoSnackBar('Seguimiento detenido');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showInfoSnackBar('Copiado al portapapeles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Pruebas Firebase Híbrido'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado actual
            _buildStatusCard(),
            
            const SizedBox(height: 16),
            
            // Controles principales
            _buildMainControls(),
            
            const SizedBox(height: 16),
            
            // Controles de ubicación
            if (_isServicesInitialized) _buildLocationControls(),
            
            const SizedBox(height: 16),
            
            // Estado de servicios
            if (_serviceStatus.isNotEmpty) _buildServiceStatusCard(),
            
            const SizedBox(height: 16),
            
            // Ubicación actual
            if (_currentPosition != null) _buildLocationCard(),
            
            const SizedBox(height: 16),
            
            // Resultados de pruebas
            if (_testResults.isNotEmpty) _buildTestResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estado Actual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _isServicesInitialized ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usuario: $_testUserId | Rol: $_testUserRole',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Backend: ${HybridBackendService().baseUrl}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🎮 Controles Principales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isInitializing ? null : _initializeServices,
              icon: _isInitializing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.power_settings_new),
              label: Text(_isInitializing ? 'Inicializando...' : 'Inicializar Servicios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isServicesInitialized ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isServicesInitialized ? _runComprehensiveTests : null,
              icon: const Icon(Icons.science),
              label: const Text('Ejecutar Pruebas Completas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isServicesInitialized ? _sendTestNotification : null,
              icon: const Icon(Icons.notifications),
              label: const Text('Probar Notificación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationControls() {
    final isTracking = _locationService.isTracking;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🎯 Control de Ubicación y Geofencing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTracking ? _stopLocationTracking : _startLocationTracking,
                    icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(isTracking ? 'Detener Seguimiento' : 'Iniciar Seguimiento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTracking ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _testGeofencingManually,
              icon: const Icon(Icons.my_location),
              label: const Text('Probar Geofencing Manual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            
            if (isTracking) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.track_changes, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seguimiento activo - El geofencing automático está funcionando',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔧 Estado de Servicios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(_serviceStatus.toString()),
                  tooltip: 'Copiar al portapapeles',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _formatJsonForDisplay(_serviceStatus),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final pos = _currentPosition!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📍 Ubicación Actual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationRow('Latitud', pos.latitude.toStringAsFixed(6)),
            _buildLocationRow('Longitud', pos.longitude.toStringAsFixed(6)),
            _buildLocationRow('Precisión', '${pos.accuracy.toStringAsFixed(1)} m'),
            _buildLocationRow('Velocidad', '${pos.speed.toStringAsFixed(1)} m/s'),
            _buildLocationRow('Timestamp', pos.timestamp.toLocal().toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildTestResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🧪 Resultados de Pruebas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(_testResults.toString()),
                  tooltip: 'Copiar resultados',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _formatJsonForDisplay(_testResults),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJsonForDisplay(Map<String, dynamic> json) {
    // Formateo simple del JSON para mejor legibilidad
    final buffer = StringBuffer();
    _formatJsonRecursive(json, buffer, 0);
    return buffer.toString();
  }

  void _formatJsonRecursive(dynamic obj, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;
    
    if (obj is Map<String, dynamic>) {
      buffer.writeln('{');
      final entries = obj.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$indentStr  "${entry.key}": ');
        _formatJsonRecursive(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$indentStr}');
    } else if (obj is List) {
      buffer.write('[');
      for (int i = 0; i < obj.length; i++) {
        _formatJsonRecursive(obj[i], buffer, indent);
        if (i < obj.length - 1) buffer.write(', ');
      }
      buffer.write(']');
    } else if (obj is String) {
      buffer.write('"$obj"');
    } else {
      buffer.write(obj.toString());
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}