// lib/widgets/attendance/permission_dialog_widgets.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/permission_service.dart';

/// ✅ PERMISSION DIALOG WIDGETS: Diálogos de permisos críticos preservados
/// Responsabilidades:
/// - Diálogos no cancelables (PopScope canPop: false)
/// - Flujo secuencial: Servicios → Preciso → Siempre → Batería
/// - Estilos exactos y colores preservados
/// - Validación obligatoria sin escape
/// - Recheck automático después de configurar
class PermissionDialogWidgets {
  static final PermissionService _permissionService = PermissionService();

  /// ✅ DIÁLOGO DE SERVICIOS DE UBICACIÓN
  static Future<void> showLocationServicesDialog(
    BuildContext context,
    VoidCallback onPermissionConfigured,
  ) async {
    if (!context.mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // No permite cerrar con back
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.location_off, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('📍 Ubicación Desactivada')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ REQUERIDO PARA ASISTENCIA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Para registrar tu asistencia necesitas:'),
                SizedBox(height: 8),
                _buildRequirementItem('📍', 'Activar servicios de ubicación del dispositivo'),
                SizedBox(height: 16),
                Text(
                  'Este popup seguirá apareciendo hasta que actives la ubicación.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _permissionService.openLocationSettings();
                  // Recheck después de 2 segundos
                  Timer(Duration(seconds: 2), () {
                    onPermissionConfigured();
                  });
                },
                icon: Icon(Icons.settings),
                label: Text('Abrir Configuración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ DIÁLOGO DE UBICACIÓN PRECISA
  static Future<void> showPreciseLocationDialog(
    BuildContext context,
    VoidCallback onPermissionConfigured,
  ) async {
    if (!context.mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.gps_not_fixed, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('🎯 Ubicación Precisa')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.precision_manufacturing, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PRECISIÓN REQUERIDA',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Para detectar cuando entres al área del evento:'),
                SizedBox(height: 8),
                _buildRequirementItem('🎯', 'Ubicación PRECISA (no aproximada)'),
                _buildRequirementItem('📐', 'Para geofencing exacto'),
                SizedBox(height: 16),
                Text(
                  'Nota: Sin ubicación precisa no se puede registrar asistencia automáticamente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  onPermissionConfigured();
                },
                child: Text('❌ Rechazar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final granted = await _permissionService.requestPreciseLocationPermissionEnhanced();
                  if (granted) {
                    onPermissionConfigured();
                  } else {
                    // Volver a mostrar el diálogo
                    Timer(Duration(milliseconds: 500), () {
                      onPermissionConfigured();
                    });
                  }
                },
                icon: Icon(Icons.check),
                label: Text('✅ Permitir Precisa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ DIÁLOGO DE UBICACIÓN SIEMPRE
  static Future<void> showAlwaysLocationDialog(
    BuildContext context,
    VoidCallback onPermissionConfigured,
  ) async {
    if (!context.mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('⏰ Ubicación Todo el Tiempo')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TRACKING CONTINUO',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Para asistencia automática necesitas:'),
                SizedBox(height: 8),
                _buildRequirementItem('📱', 'Ubicación activa aunque cambies de app'),
                _buildRequirementItem('🔄', 'Tracking continuo durante el evento'),
                _buildRequirementItem('⚡', 'Detección inmediata de entrada/salida'),
                SizedBox(height: 16),
                Text(
                  '💡 Tranquilo: Solo se usa durante eventos activos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  onPermissionConfigured();
                },
                child: Text('❌ Solo cuando use la app'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final granted = await _permissionService.requestAlwaysLocationPermission();
                  if (granted) {
                    onPermissionConfigured();
                  } else {
                    Timer(Duration(milliseconds: 500), () {
                      onPermissionConfigured();
                    });
                  }
                },
                icon: Icon(Icons.check),
                label: Text('✅ Permitir Siempre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ DIÁLOGO DE OPTIMIZACIÓN DE BATERÍA
  static Future<void> showBatteryOptimizationDialog(
    BuildContext context,
    VoidCallback onPermissionConfigured,
  ) async {
    if (!context.mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.battery_alert, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('🔋 Optimización de Batería')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ CRÍTICO PARA ASISTENCIA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Android está optimizando la batería de GeoAsist.'),
                SizedBox(height: 12),
                Text('Esto causará:'),
                SizedBox(height: 8),
                _buildRequirementItem('❌', 'App se cierre automáticamente'),
                _buildRequirementItem('💔', 'Pérdida de asistencia registrada'),
                _buildRequirementItem('📍', 'Tracking interrumpido'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✅ Desactivar optimización = Asistencia garantizada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  onPermissionConfigured();
                },
                child: Text('❌ Mantener Optimización'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final granted = await _permissionService.requestBatteryOptimizationPermission();
                  if (granted) {
                    onPermissionConfigured();
                  } else {
                    Timer(Duration(milliseconds: 500), () {
                      onPermissionConfigured();
                    });
                  }
                },
                icon: Icon(Icons.check),
                label: Text('🔋 Desactivar Optimización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ DIÁLOGO DE ASISTENCIA PERDIDA
  static void showAttendanceLossDialog(
    BuildContext context,
    String reason,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Asistencia Perdida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Has perdido la asistencia para este evento.\n\nMotivo: $reason',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver al dashboard
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// ✅ DIÁLOGO DE INFORMACIÓN DEL TRACKING
  static void showTrackingInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del Tracking'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Características del Tracking:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• GPS preciso cada 5 segundos'),
              Text('• Heartbeat al servidor cada 30 segundos'),
              Text('• Detección automática de geofence'),
              Text('• Grace period de 60s por salida del área'),
              Text('• Grace period de 30s por cerrar app'),
              Text('• Registro automático de asistencia'),
              SizedBox(height: 16),
              Text(
                'Restricciones de Seguridad:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Ubicación precisa obligatoria'),
              Text('• Background tracking requerido'),
              Text('• Cerrar app = pérdida de asistencia'),
              Text('• Tracking continuo durante evento'),
              SizedBox(height: 16),
              Text(
                'Mantén la aplicación abierta durante todo el evento para conservar tu asistencia.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// ✅ WIDGET HELPER PARA ELEMENTOS DE REQUISITO
  static Widget _buildRequirementItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}