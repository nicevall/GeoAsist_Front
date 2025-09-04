// lib/widgets/attendance/location_info_panel.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/colors.dart';
import '../../models/evento_model.dart';

/// ✅ LOCATION INFO PANEL: Panel de información GPS preservado
/// Responsabilidades:
/// - Mostrar coordenadas GPS actuales
/// - Precisión de ubicación en tiempo real
/// - Distancia al centro del evento
/// - Última actualización de GPS
/// - Indicadores visuales de calidad de señal
class LocationInfoPanel extends StatelessWidget {
  final Position? currentPosition;
  final Evento? activeEvent;
  final double distanceFromCenter;
  final double currentAccuracy;
  final String lastUpdateTime;
  final bool isInGeofence;

  const LocationInfoPanel({
    super.key,
    required this.currentPosition,
    required this.activeEvent,
    required this.distanceFromCenter,
    required this.currentAccuracy,
    required this.lastUpdateTime,
    required this.isInGeofence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Panel de información del evento
        if (activeEvent != null) _buildEventInfoPanel(),
        
        const SizedBox(height: 16),
        
        // Panel de ubicación GPS
        _buildLocationPanel(),
      ],
    );
  }

  /// 📍 PANEL DE INFORMACIÓN DEL EVENTO (UI PRESERVADA)
  Widget _buildEventInfoPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeEvent!.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                      Text(
                        activeEvent!.lugar ?? 'Ubicación',
                        style: const TextStyle(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeEvent!.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activeEvent!.isActive ? 'ACTIVO' : 'INACTIVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Inicio',
                    '${activeEvent!.horaInicio.hour.toString().padLeft(2, '0')}:${activeEvent!.horaInicio.minute.toString().padLeft(2, '0')}',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Radio',
                    '${activeEvent!.rangoPermitido.toInt()}m',
                    Icons.location_on,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Estado',
                    isInGeofence ? 'Dentro' : 'Fuera',
                    isInGeofence ? Icons.check_circle : Icons.location_off,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🌍 PANEL DE UBICACIÓN GPS (UI PRESERVADA)
  Widget _buildLocationPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location, 
                  color: _getLocationQualityColor(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ubicación Actual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLocationQualityColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getLocationQualityColor().withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getLocationQualityText(),
                    style: TextStyle(
                      color: _getLocationQualityColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (currentPosition != null) ...[
              // Coordenadas con manejo mejorado de errores
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Latitud',
                      _getFormattedCoordinate(currentPosition?.latitude),
                      Icons.place,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Longitud',
                      _getFormattedCoordinate(currentPosition?.longitude),
                      Icons.place,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Precisión y distancia con manejo mejorado
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Precisión',
                      _getFormattedDistance(currentAccuracy),
                      Icons.gps_fixed,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Distancia Centro',
                      _getFormattedDistance(distanceFromCenter),
                      Icons.straighten,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Información adicional del GPS
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      'Altitud',
                      '${currentPosition!.altitude.toStringAsFixed(1)}m',
                      Icons.height,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailCard(
                      'Velocidad',
                      '${(currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                      Icons.speed,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Última actualización
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Última actualización: $lastUpdateTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: lastUpdateTime.isNotEmpty ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicador de geofence
              if (activeEvent != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isInGeofence 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isInGeofence 
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isInGeofence ? Icons.check_circle : Icons.location_off,
                        color: isInGeofence ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isInGeofence ? 'Dentro del Área del Evento' : 'Fuera del Área del Evento',
                              style: TextStyle(
                                color: isInGeofence ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Radio permitido: ${activeEvent!.rangoPermitido.toInt()}m',
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
                ),
              ],
            ] else ...[
              // Estado de carga
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.secondaryTeal),
                    SizedBox(height: 8),
                    Text(
                      'Obteniendo ubicación...',
                      style: TextStyle(color: AppColors.textGray),
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

  /// 📊 ITEM DE ESTADÍSTICA (UI PRESERVADA)
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 🎨 TARJETA DE DETALLE
  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 OBTENER COLOR DE CALIDAD DE UBICACIÓN
  Color _getLocationQualityColor() {
    if (currentPosition == null) return AppColors.textGray;
    
    if (currentAccuracy <= 5) return Colors.green;     // Excelente
    if (currentAccuracy <= 10) return Colors.blue;    // Buena
    if (currentAccuracy <= 20) return Colors.orange;  // Regular
    return Colors.red;                                 // Mala
  }

  /// 📝 OBTENER TEXTO DE CALIDAD DE UBICACIÓN
  String _getLocationQualityText() {
    if (currentPosition == null) return 'Sin ubicación';
    
    if (currentAccuracy <= 5) return 'Excelente';
    if (currentAccuracy <= 10) return 'Buena';
    if (currentAccuracy <= 20) return 'Regular';
    return 'Mala';
  }

  /// ✅ NUEVO: Formatear coordenadas con manejo de errores
  String _getFormattedCoordinate(double? coordinate) {
    if (coordinate == null) return '---';
    if (coordinate.isNaN || coordinate.isInfinite) return 'Error';
    return coordinate.toStringAsFixed(6);
  }

  /// ✅ NUEVO: Formatear distancias con manejo de errores
  String _getFormattedDistance(double? distance) {
    if (distance == null) return '---';
    if (distance.isNaN || distance.isInfinite) return 'Error';
    return '${distance.toStringAsFixed(1)}m';
  }
}