// lib/screens/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/colors.dart';
import '../services/permission_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double initialRange;
  final String initialLocationName;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude = -0.1805, // UIDE por defecto
    this.initialLongitude = -78.4680,
    this.initialRange = 100.0,
    this.initialLocationName = 'UIDE Campus Principal',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController; // ✅ CAMBIADO: nullable
  final PermissionService _permissionService = PermissionService();

  late double _selectedLatitude;
  late double _selectedLongitude;
  late double _selectedRange;
  late String _selectedLocationName;

  bool _isLoading = true;
  bool _hasPermissions = false;
  bool _mapReady = false;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 LocationPicker: initState iniciado');

    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _selectedRange = widget.initialRange;
    _selectedLocationName = widget.initialLocationName;

    debugPrint(
        '📍 LocationPicker: Coordenadas iniciales: $_selectedLatitude, $_selectedLongitude');
    debugPrint('📏 LocationPicker: Rango inicial: $_selectedRange');
    debugPrint('🏷️ LocationPicker: Nombre inicial: $_selectedLocationName');

    _updateMapElements();
    _initializeLocation();
  }

  /// ✅ NUEVO: Método de inicialización con debug completo
  Future<void> _initializeLocation() async {
    debugPrint('🔄 LocationPicker: Iniciando _initializeLocation');

    try {
      // 1. Verificar permisos
      debugPrint('🔐 LocationPicker: Verificando permisos...');
      final hasPermissions = await _permissionService.hasLocationPermissions();
      debugPrint('🔐 LocationPicker: Permisos resultado: $hasPermissions');

      setState(() {
        _hasPermissions = hasPermissions;
      });

      if (hasPermissions) {
        debugPrint('✅ LocationPicker: Permisos OK, obteniendo ubicación...');
        await _getCurrentLocationSafe();
      } else {
        debugPrint(
            '❌ LocationPicker: Sin permisos, usando ubicación por defecto');
      }

      // 2. Simular que el mapa está listo después de un delay
      debugPrint('⏳ LocationPicker: Esperando inicialización del mapa...');
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        debugPrint('✅ LocationPicker: Mapa listo, quitando loading');
        setState(() {
          _isLoading = false;
          _mapReady = true;
        });
      }
    } catch (e) {
      debugPrint('💥 LocationPicker: Error en inicialización: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _mapReady = true; // Permitir que se muestre aunque haya error
        });
      }
    }
  }

  /// ✅ NUEVO: Obtener ubicación de forma segura
  Future<void> _getCurrentLocationSafe() async {
    try {
      debugPrint('🌍 LocationPicker: Obteniendo ubicación actual...');

      final position = await _permissionService.getCurrentLocation();

      if (position != null && mounted) {
        debugPrint(
            '✅ LocationPicker: Ubicación obtenida: ${position.latitude}, ${position.longitude}');

        // Solo actualizar si estamos usando la ubicación por defecto
        if (_selectedLatitude == widget.initialLatitude &&
            _selectedLongitude == widget.initialLongitude) {
          debugPrint('🔄 LocationPicker: Actualizando a ubicación actual');
          setState(() {
            _selectedLatitude = position.latitude;
            _selectedLongitude = position.longitude;
            _selectedLocationName = 'Mi ubicación actual';
            _updateMapElements();
          });
        } else {
          debugPrint(
              '⏭️ LocationPicker: Manteniendo ubicación inicial personalizada');
        }
      } else {
        debugPrint(
            '❌ LocationPicker: No se pudo obtener ubicación o widget no montado');
      }
    } catch (e) {
      debugPrint('💥 LocationPicker: Error obteniendo ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🎨 LocationPicker: build() llamado - isLoading: $_isLoading, mapReady: $_mapReady');

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: _saveLocation,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildMapContent(),
    );
  }

  /// ✅ NUEVO: Estado de carga con debug
  Widget _buildLoadingState() {
    debugPrint('⏳ LocationPicker: Mostrando estado de carga');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 20),
          const Text(
            'Cargando mapa...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Permisos: ${_hasPermissions ? "✅" : "❌"}\n'
            'Mapa listo: ${_mapReady ? "✅" : "❌"}',
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

  /// ✅ NUEVO: Contenido del mapa separado
  Widget _buildMapContent() {
    debugPrint('🗺️ LocationPicker: Mostrando contenido del mapa');

    return Column(
      children: [
        // Mapa
        Expanded(
          flex: 3,
          child: _buildMapWidget(),
        ),

        // Panel de control inferior
        Expanded(
          flex: 1,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  /// ✅ NUEVO: Widget del mapa con debug
  Widget _buildMapWidget() {
    debugPrint('🗺️ LocationPicker: Construyendo GoogleMap widget');

    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(_selectedLatitude, _selectedLongitude),
          zoom: 17.0,
        ),
        markers: _markers,
        circles: _circles,
        onTap: _onMapTapped,
        mapType: MapType.hybrid,
        myLocationEnabled: _hasPermissions,
        myLocationButtonEnabled: _hasPermissions,
        zoomControlsEnabled: false,
        // ✅ AGREGADO: Callbacks de debug
        onCameraMove: (CameraPosition position) {
          // Solo debug ocasional para no saturar logs
          if (position.zoom.round() % 2 == 0) {
            debugPrint(
                '📷 LocationPicker: Cámara movida a: ${position.target}');
          }
        },
      );
    } catch (e) {
      debugPrint('💥 LocationPicker: Error creando GoogleMap: $e');
      return Container(
        color: AppColors.lightGray,
        child: const Center(
          child: Text(
            'Error cargando el mapa\nVerifica tu conexión a internet',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGray),
          ),
        ),
      );
    }
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ubicación seleccionada
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedLocationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      'Lat: ${_selectedLatitude.toStringAsFixed(6)}, Lng: ${_selectedLongitude.toStringAsFixed(6)}',
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

          const SizedBox(height: 16),

          // Slider de rango
          const Text(
            'Rango de asistencia',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          Row(
            children: [
              const Text('10m', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _selectedRange,
                  min: 10.0,
                  max: 500.0,
                  divisions: 49,
                  activeColor: AppColors.primaryOrange,
                  label: '${_selectedRange.toInt()}m',
                  onChanged: (value) {
                    debugPrint('📏 LocationPicker: Rango cambiado a: $value');
                    setState(() {
                      _selectedRange = value;
                      _updateMapElements();
                    });
                  },
                ),
              ),
              const Text('500m', style: TextStyle(fontSize: 12)),
            ],
          ),

          // Botones de ubicaciones predefinidas
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToUideLocation,
                  icon: const Icon(Icons.school, size: 16),
                  label: const Text('UIDE', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.primaryOrange),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Mi ubicación',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryTeal,
                    side: const BorderSide(color: AppColors.secondaryTeal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint('🗺️ LocationPicker: _onMapCreated llamado');
    try {
      _mapController = controller;
      debugPrint('✅ LocationPicker: Map controller asignado exitosamente');

      // Mover cámara a la ubicación inicial
      _moveMapToLocation(_selectedLatitude, _selectedLongitude);
    } catch (e) {
      debugPrint('💥 LocationPicker: Error en _onMapCreated: $e');
    }
  }

  void _onMapTapped(LatLng location) {
    debugPrint(
        '👆 LocationPicker: Mapa tocado en: ${location.latitude}, ${location.longitude}');
    setState(() {
      _selectedLatitude = location.latitude;
      _selectedLongitude = location.longitude;
      _selectedLocationName = 'Ubicación personalizada';
      _updateMapElements();
    });
  }

  void _updateMapElements() {
    debugPrint('🔄 LocationPicker: Actualizando elementos del mapa');
    final markerPosition = LatLng(_selectedLatitude, _selectedLongitude);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: markerPosition,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Ubicación del evento',
            snippet: 'Rango: ${_selectedRange.toInt()}m',
          ),
        ),
      };

      _circles = {
        Circle(
          circleId: const CircleId('range_circle'),
          center: markerPosition,
          radius: _selectedRange,
          fillColor: AppColors.primaryOrange.withOpacity(0.2),
          strokeColor: AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      };
    });
    debugPrint('✅ LocationPicker: Marcadores y círculos actualizados');
  }

  void _goToUideLocation() {
    debugPrint('🏫 LocationPicker: Navegando a UIDE');
    const uideLocation = LatLng(-0.1805, -78.4680);
    setState(() {
      _selectedLatitude = uideLocation.latitude;
      _selectedLongitude = uideLocation.longitude;
      _selectedLocationName = 'UIDE Campus Principal';
      _updateMapElements();
    });

    _moveMapToLocation(uideLocation.latitude, uideLocation.longitude);
  }

  void _goToCurrentLocation() async {
    debugPrint('📍 LocationPicker: Navegando a ubicación actual');
    try {
      final position = await _permissionService.getCurrentLocation();
      if (position != null && mounted) {
        debugPrint(
            '✅ LocationPicker: Ubicación actual obtenida: ${position.latitude}, ${position.longitude}');
        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _selectedLocationName = 'Mi ubicación actual';
          _updateMapElements();
        });

        _moveMapToLocation(position.latitude, position.longitude);
      } else {
        debugPrint('❌ LocationPicker: No se pudo obtener ubicación actual');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la ubicación actual'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('💥 LocationPicker: Error obteniendo ubicación actual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener ubicación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ NUEVO: Método seguro para mover la cámara
  void _moveMapToLocation(double lat, double lng) {
    debugPrint('📷 LocationPicker: Moviendo cámara a: $lat, $lng');
    try {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(lat, lng)),
        );
        debugPrint('✅ LocationPicker: Cámara movida exitosamente');
      } else {
        debugPrint('❌ LocationPicker: Map controller no está disponible');
      }
    } catch (e) {
      debugPrint('💥 LocationPicker: Error moviendo cámara: $e');
    }
  }

  void _saveLocation() {
    debugPrint('💾 LocationPicker: Guardando ubicación seleccionada');
    debugPrint(
        '📍 LocationPicker: Lat: $_selectedLatitude, Lng: $_selectedLongitude');
    debugPrint('📏 LocationPicker: Rango: $_selectedRange');
    debugPrint('🏷️ LocationPicker: Nombre: $_selectedLocationName');

    final result = {
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
      'range': _selectedRange,
      'locationName': _selectedLocationName,
    };

    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    debugPrint('🗑️ LocationPicker: dispose() llamado');
    super.dispose();
  }
}
