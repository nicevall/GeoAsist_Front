// lib/widgets/permission_handler_widget.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/permission_service.dart';

class PermissionHandlerWidget extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionHandlerWidget({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<PermissionHandlerWidget> createState() =>
      _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  final PermissionService _permissionService = PermissionService();
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.secondaryTeal,
              ),
            ),

            const SizedBox(height: 20),

            // Título
            const Text(
              'Necesitamos tu ubicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Explicación
            const Text(
              'Para registrar tu asistencia necesitamos conocer tu ubicación y verificar que estés dentro del área del evento.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Beneficios
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Asistencia automática y precisa',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.darkGray),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu ubicación es privada y segura',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.darkGray),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isRequesting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onPermissionDenied?.call();
                          },
                    child: const Text(
                      'Más tarde',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Permitir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);

    try {
      final result = await _permissionService.requestLocationPermissions();

      if (mounted) {
        Navigator.of(context).pop();

        switch (result) {
          case LocationPermissionResult.granted:
            widget.onPermissionGranted?.call();
            break;
          case LocationPermissionResult.denied:
            _showDeniedDialog();
            break;
          case LocationPermissionResult.deniedForever:
            _showPermanentDeniedDialog();
            break;
          case LocationPermissionResult.serviceDisabled:
            _showServiceDisabledDialog();
            break;
          case LocationPermissionResult.error:
            widget.onPermissionDenied?.call();
            break;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _showDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos Denegados'),
        content: const Text(
          'Sin permisos de ubicación no podremos registrar tu asistencia automáticamente. '
          'Podrás intentar nuevamente más tarde.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPermissionDenied?.call();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos Requeridos'),
        content: const Text(
          'Los permisos de ubicación han sido denegados permanentemente. '
          'Puedes habilitarlos desde la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPermissionDenied?.call();
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  void _showServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Deshabilitado'),
        content: const Text(
          'El servicio de ubicación está deshabilitado. '
          'Por favor actívalo desde la configuración de tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPermissionDenied?.call();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
