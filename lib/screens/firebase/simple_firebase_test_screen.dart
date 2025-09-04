// lib/screens/firebase/simple_firebase_test_screen.dart
import 'package:flutter/material.dart';
import 'package:geo_asist_front/services/firebase/hybrid_backend_service.dart';
import 'package:geolocator/geolocator.dart';

class SimpleFirebaseTestScreen extends StatefulWidget {
  const SimpleFirebaseTestScreen({super.key});

  @override
  State<SimpleFirebaseTestScreen> createState() => _SimpleFirebaseTestScreenState();
}

class _SimpleFirebaseTestScreenState extends State<SimpleFirebaseTestScreen> {
  final HybridBackendService _hybridService = HybridBackendService();
  String _status = 'Listo para probar';
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Test Firebase Híbrido'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado Actual:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(_status),
                    if (_lastResult != null) ...[
                      SizedBox(height: 16),
                      Text('Último Resultado:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _lastResult.toString(),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildTestButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testInitializeService,
          icon: Icon(Icons.rocket_launch),
          label: Text('Inicializar Servicio'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testBackendHealth,
          icon: Icon(Icons.health_and_safety),
          label: Text('Probar Backend Health'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testGeofencing,
          icon: Icon(Icons.location_on),
          label: Text('Probar Geofencing'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testNotification,
          icon: Icon(Icons.notifications),
          label: Text('Probar Notificación'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runAllTests,
          icon: Icon(Icons.science),
          label: Text('🧪 Ejecutar Todas las Pruebas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _testInitializeService() async {
    setState(() {
      _isLoading = true;
      _status = 'Inicializando servicio híbrido...';
    });

    try {
      await _hybridService.initialize('test_user_flutter', 'estudiante');
      setState(() {
        _status = '✅ Servicio híbrido inicializado correctamente';
        _lastResult = {'initialized': true, 'timestamp': DateTime.now().toString()};
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error inicializando servicio: \$e';
        _lastResult = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBackendHealth() async {
    setState(() {
      _isLoading = true;
      _status = 'Probando salud del backend...';
    });

    try {
      final result = await _hybridService.getServiceStatus();
      setState(() {
        _status = result['backendHealthy'] == true 
          ? '✅ Backend saludable y funcionando'
          : '⚠️ Backend no está respondiendo correctamente';
        _lastResult = result;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error conectando con backend: \$e';
        _lastResult = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGeofencing() async {
    setState(() {
      _isLoading = true;
      _status = 'Probando geofencing con ubicación de prueba...';
    });

    try {
      // Crear Position de prueba usando geolocator
      final mockPosition = Position(
        latitude: -12.046374,
        longitude: -77.042793,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final result = await _hybridService.sendLocationForGeofencing(mockPosition);
      setState(() {
        if (result['success'] == true) {
          _status = '✅ Geofencing funcionando - Asistencia detectada';
        } else {
          _status = '⚠️ Geofencing ejecutado pero sin eventos detectados';
        }
        _lastResult = result;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error en geofencing: \$e';
        _lastResult = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Enviando notificación de prueba...';
    });

    try {
      final success = await _hybridService.sendTestNotification(
        '🧪 Prueba Exitosa',
        'El sistema híbrido Firebase + Node.js está funcionando correctamente',
      );

      setState(() {
        _status = success 
          ? '✅ Notificación enviada correctamente'
          : '⚠️ Notificación procesada pero puede no haberse entregado';
        _lastResult = {'notificationSent': success, 'timestamp': DateTime.now().toString()};
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error enviando notificación: \$e';
        _lastResult = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _status = '🧪 Ejecutando suite completa de pruebas...';
    });

    try {
      final result = await _hybridService.runComprehensiveTest();
      setState(() {
        final overallSuccess = result['overall_status'] == true;
        _status = overallSuccess 
          ? '🎉 ¡Todas las pruebas exitosas! Sistema completamente funcional'
          : '⚠️ Algunas pruebas fallaron, revisar detalles';
        _lastResult = result;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error ejecutando pruebas: \$e';
        _lastResult = {'error': e.toString()};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Ya no necesitamos MockPosition, usamos Position de geolocator