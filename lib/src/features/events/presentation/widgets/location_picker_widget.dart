// lib/src/features/events/presentation/widgets/location_picker_widget.dart
// Location picker widget for event creation

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(double lat, double lng)? onLocationSelected;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerWidget({
    super.key,
    this.onLocationSelected,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  double? _selectedLat;
  double? _selectedLng;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                const Text(
                  'Ubicación del evento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedLat != null && _selectedLng != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación seleccionada:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text('Lat: ${_selectedLat!.toStringAsFixed(6)}'),
                    Text('Lng: ${_selectedLng!.toStringAsFixed(6)}'),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No se ha seleccionado ubicación',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Usar ubicación actual'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map),
                    label: const Text('Seleccionar en mapa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están permanentemente denegados');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
      });

      widget.onLocationSelected?.call(_selectedLat!, _selectedLng!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obteniendo ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openMapPicker() {
    // TODO: Implement map picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selector de mapa no implementado aún'),
      ),
    );
  }
}