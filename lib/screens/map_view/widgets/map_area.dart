// lib/screens/map_view/widgets/map_area.dart - ARCHIVO CORREGIDO COMPLETO
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/evento_model.dart';

class MapArea extends StatelessWidget {
  final Evento? currentEvento;
  final bool isOnBreak;
  final bool isInsideGeofence;
  final Animation<double> pulseAnimation;

  const MapArea({
    super.key,
    required this.currentEvento,
    required this.isOnBreak,
    required this.isInsideGeofence,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ✅ CORREGIDO: withOpacity -> withValues (línea 29)
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
            _buildMapBackground(context),
            _buildMapOverlays(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground(BuildContext context) {
    return Container(
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
          ..._buildStreetPattern(),
          _buildGeofenceCircle(),
          _buildUserLocationIndicator(context),
          _buildCenterMarker(context),
        ],
      ),
    );
  }

  Widget _buildGeofenceCircle() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isOnBreak
                // ✅ CORREGIDO: withOpacity -> withValues (línea 78)
                ? AppColors.secondaryTeal.withValues(alpha: 0.5)
                // ✅ CORREGIDO: withOpacity -> withValues (línea 79)
                : AppColors.primaryOrange.withValues(alpha: 0.8),
            width: 3,
          ),
          color: isOnBreak
              // ✅ CORREGIDO: withOpacity -> withValues (línea 83)
              ? AppColors.secondaryTeal.withValues(alpha: 0.1)
              // ✅ CORREGIDO: withOpacity -> withValues (línea 84)
              : AppColors.primaryOrange.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildUserLocationIndicator(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.5 - 16,
      top: MediaQuery.of(context).size.height * 0.4,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: pulseAnimation.value,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isInsideGeofence ? Colors.blue : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isInsideGeofence ? Colors.blue : Colors.red)
                        // ✅ CORREGIDO: withOpacity -> withValues (línea 108)
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
    );
  }

  Widget _buildCenterMarker(BuildContext context) {
    return Positioned(
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
    );
  }

  List<Widget> _buildStreetPattern() {
    return [
      // Líneas horizontales
      Positioned(
        top: 50,
        left: 0,
        right: 0,
        child: Container(
            height: 2,
            // ✅ CORREGIDO: withOpacity -> withValues (línea 154)
            color: Colors.grey.withValues(alpha: 0.3)),
      ),
      Positioned(
        top: 150,
        left: 0,
        right: 0,
        child: Container(
            height: 2,
            // ✅ CORREGIDO: withOpacity -> withValues (línea 160)
            color: Colors.grey.withValues(alpha: 0.3)),
      ),
      Positioned(
        bottom: 50,
        left: 0,
        right: 0,
        child: Container(
            height: 2,
            // ✅ CORREGIDO: withOpacity -> withValues (línea 166)
            color: Colors.grey.withValues(alpha: 0.3)),
      ),
      // Líneas verticales
      Positioned(
        top: 0,
        bottom: 0,
        left: 80,
        child: Container(
            width: 2,
            // ✅ CORREGIDO: withOpacity -> withValues (línea 173)
            color: Colors.grey.withValues(alpha: 0.3)),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 80,
        child: Container(
            width: 2,
            // ✅ CORREGIDO: withOpacity -> withValues (línea 179)
            color: Colors.grey.withValues(alpha: 0.3)),
      ),
    ];
  }

  Widget _buildMapOverlays(BuildContext context) {
    return Stack(
      children: [
        _buildMapHeader(),
        if (currentEvento != null) _buildEventInfo(),
      ],
    );
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  // ✅ CORREGIDO: withOpacity -> withValues (línea 208)
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Text(
              currentEvento != null
                  ? '📍 ${currentEvento!.titulo}'
                  : '📍 UIDE Campus',
              style: const TextStyle(
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
                  // ✅ CORREGIDO: withOpacity -> withValues (línea 230)
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
          // ✅ CORREGIDO: withOpacity -> withValues (línea 254)
          color: AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // ✅ CORREGIDO: withOpacity -> withValues (línea 258)
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentEvento!.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (currentEvento!.descripcion != null)
              Text(
                currentEvento!.descripcion!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            Text(
              'Inicio: ${_formatDateTime(currentEvento!.horaInicio)}',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              'Fin: ${_formatDateTime(currentEvento!.horaFinal)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
