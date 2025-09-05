import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/screens/location_picker_screen.dart - VERSIÓN CORREGIDA
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
    this.initialLatitude = -0.1805,
    this.initialLongitude = -78.4680,
    this.initialRange = 100.0,
    this.initialLocationName = 'UIDE Campus Principal',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final PermissionService _permissionService = PermissionService();

  late double _selectedLatitude;
  late double _selectedLongitude;
  late double _selectedRange;
  late String _selectedLocationName;

  bool _isLoading = true;
  bool _hasPermissions = false;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();

    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _selectedRange = widget.initialRange;
    _selectedLocationName = widget.initialLocationName;

    _updateMapElements();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermissions = await _permissionService.hasLocationPermissions();

      if (mounted) {
        setState(() {
          _hasPermissions = hasPermissions;
          _isLoading = false; // ✅ CORREGIDO: Quitar loading inmediatamente
        });
      }

      if (hasPermissions) {
        await _getCurrentLocationSafe();
      }
    } catch (e) {
      logger.d('Error en inicialización: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocationSafe() async {
    try {
      final position = await _permissionService.getCurrentLocation();

      if (position != null && mounted) {
        // Solo actualizar si estamos usando la ubicación por defecto
        if (_selectedLatitude == widget.initialLatitude &&
            _selectedLongitude == widget.initialLongitude) {
          setState(() {
            _selectedLatitude = position.latitude;
            _selectedLongitude = position.longitude;
            _selectedLocationName = 'Mi ubicación actual';
          });
          _updateMapElements();
          _moveMapToLocation(position.latitude, position.longitude);
        }
      }
    } catch (e) {
      logger.d('Error obteniendo ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryOrange),
          SizedBox(height: 20),
          Text('Inicializando mapa...'),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: GoogleMap(
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
          ),
        ),
        SizedBox(
          height: 180, // Fixed height to prevent overflow
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  // ... resto de métodos igual que antes

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLatitude = location.latitude;
      _selectedLongitude = location.longitude;
      _selectedLocationName = 'Ubicación personalizada';
    });
    _updateMapElements();
  }

  void _updateMapElements() {
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
          fillColor:
              const Color.fromARGB(250, 250, 107, 53).withValues(alpha: 0.46),
          strokeColor: AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      };
    });
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
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ubicación seleccionada - RESPONSIVE
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
                          fontSize: 14, // Reducido de 16
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Lat: ${_selectedLatitude.toStringAsFixed(4)}, Lng: ${_selectedLongitude.toStringAsFixed(4)}', // Reducido precision
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGray), // Reducido de 12
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reducido de 16
            // Slider de rango - COMPACTO
            Row(
              children: [
                const Text('Rango:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _selectedRange,
                    min: 10.0,
                    max: 500.0,
                    divisions: 49,
                    activeColor: AppColors.primaryOrange,
                    label: '${_selectedRange.toInt()}m',
                    onChanged: (value) {
                      setState(() {
                        _selectedRange = value;
                      });
                      _updateMapElements();
                    },
                  ),
                ),
                Text('${_selectedRange.toInt()}m', 
                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8), // Reducido spacing
            // Botones - RESPONSIVO
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 300) {
                  // Layout horizontal para pantallas más grandes
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goToUideLocation,
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('UIDE', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goToCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Mi ubicación', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout vertical para pantallas pequeñas
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _goToUideLocation,
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('UIDE Campus', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _goToCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Mi ubicación', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToUideLocation() {
    setState(() {
      _selectedLatitude = -0.1805;
      _selectedLongitude = -78.4680;
      _selectedLocationName = 'UIDE Campus Principal';
    });
    _updateMapElements();
    _moveMapToLocation(-0.1805, -78.4680);
  }

  void _goToCurrentLocation() async {
    final position = await _permissionService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _selectedLocationName = 'Mi ubicación actual';
      });
      _updateMapElements();
      _moveMapToLocation(position.latitude, position.longitude);
    }
  }

  void _moveMapToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  void _saveLocation() {
    final result = {
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
      'range': _selectedRange,
      'locationName': _selectedLocationName,
    };
    
    // Debug: Log datos que se van a retornar
    logger.d('=== LOCATION PICKER SAVING ===');
    logger.d('Datos a retornar:');
    logger.d('  - latitude: ${result['latitude']}');
    logger.d('  - longitude: ${result['longitude']}');
    logger.d('  - range: ${result['range']}');
    logger.d('  - locationName: ${result['locationName']}');
    logger.d('Resultado completo: $result');
    logger.d('==============================');
    
    Navigator.of(context).pop(result);
  }
}
