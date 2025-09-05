// lib/screens/map_view/widgets/map_area.dart - CON GOOGLE MAPS REAL
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../utils/colors.dart';
import '../../../models/evento_model.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';

class MapArea extends StatefulWidget {
  final Evento? currentEvento;
  final bool isOnBreak;
  final bool isInsideGeofence;
  final Animation<double> pulseAnimation;
  final double userLat; // ✅ NUEVO: Coordenadas reales del usuario
  final double userLng; // ✅ NUEVO: Coordenadas reales del usuario

  const MapArea({
    super.key,
    required this.currentEvento,
    required this.isOnBreak,
    required this.isInsideGeofence,
    required this.pulseAnimation,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<MapArea> createState() => _MapAreaState();
}

class _MapAreaState extends State<MapArea> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _updateMapElements();
  }

  @override
  void didUpdateWidget(MapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    logger.d('🗺️ MapArea recibió coordenadas: Lat: ${widget.userLat}, Lng: ${widget.userLng}');
    if (oldWidget.currentEvento != widget.currentEvento ||
        oldWidget.userLat != widget.userLat ||
        oldWidget.userLng != widget.userLng ||
        oldWidget.isInsideGeofence != widget.isInsideGeofence) {
      _updateMapElements();
    }
  }

  void _updateMapElements() {
    _updateMarkers();
    _updateCircles();
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};

    // ✅ Marcador del usuario (estudiante/profesor)
    if (widget.userLat != 0.0 && widget.userLng != 0.0) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(widget.userLat, widget.userLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.isInsideGeofence
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title:
                widget.isInsideGeofence ? 'Mi ubicación ✅' : 'Mi ubicación ❌',
            snippet: widget.isInsideGeofence
                ? 'Dentro del área del evento'
                : 'Fuera del área del evento',
          ),
        ),
      );
    }

    // ✅ Marcador del evento (centro del geofence)
    if (widget.currentEvento != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('event_location'),
          position: LatLng(
            widget.currentEvento!.ubicacion.latitud,
            widget.currentEvento!.ubicacion.longitud,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.isOnBreak
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: widget.currentEvento!.titulo,
            snippet:
                widget.currentEvento!.descripcion ?? 'Evento de asistencia',
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _updateCircles() {
    Set<Circle> newCircles = {};

    // ✅ Círculo del geofence del evento
    if (widget.currentEvento != null) {
      newCircles.add(
        Circle(
          circleId: const CircleId('event_geofence'),
          center: LatLng(
            widget.currentEvento!.ubicacion.latitud,
            widget.currentEvento!.ubicacion.longitud,
          ),
          radius: widget.currentEvento!.rangoPermitido,
          fillColor: widget.isOnBreak
              ? AppColors.secondaryTeal.withValues(alpha: 0.2)
              : AppColors.primaryOrange.withValues(alpha: 0.2),
          strokeColor: widget.isOnBreak
              ? AppColors.secondaryTeal
              : AppColors.primaryOrange,
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _circles = newCircles;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // ✅ GOOGLE MAPS REAL
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _centerMapOnEvent();
              },
              initialCameraPosition: CameraPosition(
                target: widget.currentEvento != null
                    ? LatLng(
                        widget.currentEvento!.ubicacion.latitud,
                        widget.currentEvento!.ubicacion.longitud,
                      )
                    : const LatLng(-0.1805, -78.4680), // UIDE por defecto
                zoom: 17.0,
              ),
              markers: _markers,
              circles: _circles,
              myLocationEnabled: true,
              myLocationButtonEnabled:
                  false, // Usaremos nuestro botón personalizado
              mapType: MapType.normal,
              compassEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
            ),

            // ✅ Header con información del evento
            _buildMapHeader(),

            // ✅ Botón de centrar mapa
            Positioned(
              top: 16,
              right: 16,
              child: _buildCenterButton(),
            ),

            // ✅ Información del evento en la parte inferior
            if (widget.currentEvento != null) _buildEventInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.isInsideGeofence ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.currentEvento != null
                  ? widget.currentEvento!.titulo
                  : 'UIDE Campus',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
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
      child: IconButton(
        onPressed: _centerMapOnEvent,
        icon: const Icon(
          Icons.my_location,
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.currentEvento!.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  'Rango: ${widget.currentEvento!.rangoPermitido.toInt()}m',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
            if (widget.currentEvento!.descripcion?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                widget.currentEvento!.descripcion!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _centerMapOnEvent() {
    if (_mapController == null) return;

    LatLng targetLocation;

    if (widget.currentEvento != null) {
      targetLocation = LatLng(
        widget.currentEvento!.ubicacion.latitud,
        widget.currentEvento!.ubicacion.longitud,
      );
    } else if (widget.userLat != 0.0 && widget.userLng != 0.0) {
      targetLocation = LatLng(widget.userLat, widget.userLng);
    } else {
      targetLocation = const LatLng(-0.1805, -78.4680); // UIDE por defecto
    }

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: targetLocation,
          zoom: 17.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
