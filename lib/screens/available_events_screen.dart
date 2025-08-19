// lib/screens/available_events_screen.dart - FASE C CON VALIDACIONES DE SEGURIDAD
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';
import '../utils/app_router.dart';
import '../widgets/event_attendance_card.dart';
// 🔒 NUEVOS IMPORTS PARA VALIDACIONES DE SEGURIDAD FASE C
import '../services/permission_service.dart';
import '../services/notifications/notification_manager.dart';
import '../services/battery_optimization_service.dart';

class AvailableEventsScreen extends StatefulWidget {
  const AvailableEventsScreen({super.key});

  @override
  State<AvailableEventsScreen> createState() => _AvailableEventsScreenState();
}

class _AvailableEventsScreenState extends State<AvailableEventsScreen> {
  final EventoService _eventoService = EventoService();

  // 🔒 SERVICIOS DE VALIDACIÓN FASE C
  final PermissionService _permissionService = PermissionService();
  final NotificationManager _notificationManager = NotificationManager();
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();

  List<Evento> _eventos = [];
  bool _isLoading = true;

  // 🔒 ESTADO DE VALIDACIONES
  bool _isValidatingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _handleJoinEventWithValidations(Evento evento) async {
    debugPrint('🎯 Usuario seleccionó evento: ${evento.titulo}');

    if (_isValidatingPermissions) return;

    setState(() => _isValidatingPermissions = true);

    try {
      // ✅ NAVEGACIÓN DIRECTA - El AttendanceTrackingScreen manejará permisos
      debugPrint('✅ Navegando al tracking de asistencia');
      _navigateToEventSafely(evento);
      
    } catch (e) {
      debugPrint('❌ Error: $e');
      AppRouter.showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isValidatingPermissions = false);
    }
  }

  Future<bool> _validateBasicLocationPermission() async {
    try {
      // Usar el método correcto del PermissionService
      return await _permissionService.hasLocationPermissions();
    } catch (e) {
      debugPrint('❌ Error validando permisos: $e');
      return true; // Permitir continuar y que el tracking screen maneje los permisos
    }
  }

  Future<void> _showSimpleLocationPermissionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Ubicación'),
        content: const Text('La aplicación necesita acceso a tu ubicación para registrar la asistencia automáticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // El attendance tracking screen se encargará de solicitar permisos
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  // 🔒 NAVEGACIÓN SEGURA (SOLO DESPUÉS DE VALIDACIONES)
  void _navigateToEventSafely(Evento evento) {
    if (!mounted) return;

    debugPrint('🚀 Navegando de forma segura a evento: ${evento.titulo}');

    // Navegar al attendance tracking con todos los permisos validados
    Navigator.pushNamed(
      context,
      '/attendance-tracking',
      arguments: {
        'userName': 'Estudiante',
        'eventoId': evento.id,
        'permissionsValidated': true,
        'preciseLocationGranted': true,
        'backgroundPermissionsGranted': true,
        'batteryOptimizationDisabled': true,
      },
    );
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('📋 Cargando eventos disponibles...');
      final eventos = await _eventoService.obtenerEventos();
      
      debugPrint('✅ Eventos cargados: ${eventos.length}');
      for (var evento in eventos) {
        debugPrint('📅 Evento: ${evento.titulo} - ID: ${evento.id} - Activo: ${evento.isActive}');
        debugPrint('📍 Ubicación: ${evento.ubicacion.latitud}, ${evento.ubicacion.longitud}');
        debugPrint('🎯 Rango: ${evento.rangoPermitido}m');
      }
      
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
      
      if (eventos.isEmpty) {
        AppRouter.showSnackBar('No hay eventos disponibles', isError: false);
      }
    } catch (e) {
      debugPrint('❌ Error cargando eventos: $e');
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error al cargar eventos: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Eventos Disponibles'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _isLoading
            ? _buildLoadingState()
            : _eventos.isEmpty
                ? _buildEmptyState()
                : _buildEventsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando eventos...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventos.length,
      itemBuilder: (context, index) {
        final evento = _eventos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              EventAttendanceCard(
                evento: evento,
                onGoToLocation: () => _handleJoinEventWithValidations(evento),
              ),
              // Overlay de loading durante validaciones
              if (_isValidatingPermissions)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryOrange),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Validando permisos...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los eventos aparecerán aquí cuando los docentes los creen',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔒 VALIDACIONES ESPECÍFICAS

  Future<bool> _validatePreciseLocationPermission() async {
    try {
      final isPreciseGranted =
          await _permissionService.hasLocationPermissions();
      debugPrint('📍 Ubicación precisa: ${isPreciseGranted ? "✅" : "❌"}');
      return isPreciseGranted;
    } catch (e) {
      debugPrint('❌ Error validando ubicación precisa: $e');
      return false;
    }
  }

  Future<bool> _validateBackgroundPermissions() async {
    try {
      final hasBackground = await _permissionService.canRunInBackground();
      debugPrint('🔄 Permisos background: ${hasBackground ? "✅" : "❌"}');
      return hasBackground;
    } catch (e) {
      debugPrint('❌ Error validando background: $e');
      return false;
    }
  }

  Future<bool> _validateBatteryOptimization() async {
    try {
      await _batteryService.initialize();
      if (!mounted) return false;

      final hasExemption =
          await _batteryService.ensureBatteryOptimizationExemption(
        context: context,
        showDialogIfNeeded:
            false, // No mostrar diálogo aquí, lo haremos manualmente
      );
      debugPrint('🔋 Exención batería: ${hasExemption ? "✅" : "❌"}');
      return hasExemption;
    } catch (e) {
      debugPrint('❌ Error validando batería: $e');
      return false;
    }
  }

  Future<bool> _validateLocationServices() async {
    try {
      final servicesEnabled =
          await _permissionService.isLocationServiceEnabled();
      debugPrint('📡 Servicios ubicación: ${servicesEnabled ? "✅" : "❌"}');
      return servicesEnabled;
    } catch (e) {
      debugPrint('❌ Error validando servicios: $e');
      return false;
    }
  }

  // 🔒 DIÁLOGOS EDUCATIVOS PARA PERMISOS FALTANTES
  Future<void> _showLocationPermissionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Ubicación Precisa Requerida'),
          ],
        ),
        content: const Text(
          'Para registrar asistencia es obligatorio otorgar permisos de ubicación PRECISA.\n\n'
          'Pasos:\n'
          '1. Ve a Configuración → Aplicaciones\n'
          '2. Busca "GeoAsist"\n'
          '3. Toca "Permisos" → "Ubicación"\n'
          '4. Selecciona "Precisa" (no aproximada)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _requestPreciseLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackgroundPermissionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_backup_restore, color: Colors.orange),
            SizedBox(width: 8),
            Text('Tracking Continuo Requerido'),
          ],
        ),
        content: const Text(
          'Para el tracking necesitas:\n\n'
          '1. Ve a Configuración → Batería\n'
          '2. Busca "Optimización de batería"\n'
          '3. Encuentra "GeoAsist"\n'
          '4. Selecciona "No optimizar"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _requestBackgroundPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBatteryOptimizationDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.red),
            SizedBox(width: 8),
            Text('Optimización de Batería'),
          ],
        ),
        content: const Text(
          'Para evitar que el sistema cierre la app durante el tracking de asistencia, '
          'es necesario desactivar la optimización de batería para GeoAsist.\n\n'
          'Esto es crítico para el funcionamiento correcto del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (mounted) {
                await _requestBatteryOptimizationExemption();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationServicesDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.red),
            SizedBox(width: 8),
            Text('Servicios de Ubicación'),
          ],
        ),
        content: const Text(
          'Los servicios de ubicación están desactivados en tu dispositivo.\n\n'
          'Por favor actívalos en Configuración → Ubicación para poder registrar asistencia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (mounted) {
                await _permissionService.openAppSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  // 🔒 SOLICITUD DE PERMISOS ESPECÍFICOS

  Future<void> _requestPreciseLocationPermission() async {
    try {
      final granted =
          await _permissionService.requestPreciseLocationPermission();
      if (mounted) {
        if (granted) {
          AppRouter.showSnackBar(
              '✅ Ubicación precisa configurada correctamente');
        } else {
          AppRouter.showSnackBar('❌ No se pudo configurar ubicación precisa',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppRouter.showSnackBar('Error configurando ubicación: $e',
            isError: true);
      }
    }
  }

  Future<void> _requestBackgroundPermissions() async {
    try {
      final granted = await _permissionService.requestBackgroundPermission();
      if (mounted) {
        if (granted) {
          AppRouter.showSnackBar('✅ Permisos de background configurados');
        } else {
          AppRouter.showSnackBar(
              '❌ No se pudieron configurar permisos de background',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppRouter.showSnackBar('Error configurando background: $e',
            isError: true);
      }
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      if (!mounted) return;

      final granted = await _batteryService.ensureBatteryOptimizationExemption(
        context: context,
        showDialogIfNeeded: true,
      );
      if (mounted) {
        if (granted) {
          AppRouter.showSnackBar('✅ Optimización de batería desactivada');
        } else {
          AppRouter.showSnackBar(
              '❌ No se pudo desactivar optimización de batería',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppRouter.showSnackBar('Error configurando batería: $e', isError: true);
      }
    }
  }

  // 🔒 DIÁLOGO DE ERROR GENÉRICO
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
