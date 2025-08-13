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

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final eventos = await _eventoService.obtenerEventos();
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppRouter.showSnackBar('Error al cargar eventos', isError: true);
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

  // 🔒 MÉTODO PRINCIPAL - VALIDACIONES SECUENCIALES DE SEGURIDAD
  Future<void> _handleJoinEventWithValidations(Evento evento) async {
    debugPrint(
        '🔒 Iniciando validaciones de seguridad para evento: ${evento.titulo}');

    // Prevenir múltiples ejecuciones
    if (_isValidatingPermissions) {
      debugPrint('⚠️ Validaciones ya en progreso');
      return;
    }

    setState(() => _isValidatingPermissions = true);

    try {
      // 🔒 PASO 1: VALIDAR UBICACIÓN PRECISA OBLIGATORIA
      debugPrint('🔒 PASO 1: Validando ubicación precisa...');
      final hasLocationPrecise = await _validatePreciseLocationPermission();
      if (!hasLocationPrecise) {
        await _showLocationPermissionDialog();
        return;
      }

      // 🔒 PASO 2: VALIDAR PERMISOS DE BACKGROUND
      debugPrint('🔒 PASO 2: Validando permisos de background...');
      final hasBackgroundPermissions = await _validateBackgroundPermissions();
      if (!hasBackgroundPermissions) {
        await _showBackgroundPermissionDialog();
        return;
      }

      // 🔒 PASO 3: VALIDAR EXENCIÓN DE OPTIMIZACIÓN DE BATERÍA
      debugPrint('🔒 PASO 3: Validando optimización de batería...');
      final hasBatteryExemption = await _validateBatteryOptimization();
      if (!hasBatteryExemption) {
        await _showBatteryOptimizationDialog();
        return;
      }

      // 🔒 PASO 4: VALIDAR SERVICIOS DE UBICACIÓN ACTIVOS
      debugPrint('🔒 PASO 4: Validando servicios de ubicación...');
      final hasLocationServices = await _validateLocationServices();
      if (!hasLocationServices) {
        await _showLocationServicesDialog();
        return;
      }

      // ✅ PASO 5: TODAS LAS VALIDACIONES EXITOSAS - PERMITIR NAVEGACIÓN
      debugPrint('✅ Todas las validaciones exitosas - Navegando a evento');
      if (mounted) {
        await _notificationManager
            .showGeofenceEnteredNotification(evento.titulo);
        _navigateToEventSafely(evento);
      }
    } catch (e) {
      debugPrint('❌ Error durante validaciones: $e');
      if (mounted) {
        _showErrorDialog('Error validando permisos', 'Ocurrió un error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isValidatingPermissions = false);
      }
    }
  }

  // 🔒 VALIDACIONES ESPECÍFICAS

  Future<bool> _validatePreciseLocationPermission() async {
    try {
      final isPreciseGranted =
          await _permissionService.isPreciseLocationGranted();
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
    if (!mounted) return;

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
          'La ubicación aproximada no es suficiente para el sistema de asistencia.',
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
                await _requestPreciseLocationPermission();
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

  Future<void> _showBackgroundPermissionDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_backup_restore, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permisos de Background'),
          ],
        ),
        content: const Text(
          'Para el tracking continuo de asistencia es necesario que la app pueda ejecutarse en segundo plano.\n\n'
          'Esto garantiza que tu asistencia se mantenga registrada aunque uses otras apps.',
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
                await _requestBackgroundPermissions();
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

  // 🔒 NAVEGACIÓN SEGURA (SOLO DESPUÉS DE VALIDACIONES)
  void _navigateToEventSafely(Evento evento) {
    if (!mounted) return;

    debugPrint('🚀 Navegando de forma segura a evento: ${evento.titulo}');

    // Navegar con todos los permisos validados
    Navigator.pushNamed(
      context,
      '/map-view',
      arguments: {
        'isAdminMode': false,
        'userName': 'Estudiante',
        'eventoId': evento.id,
        'isStudentMode': true,
        // 🔒 NUEVOS ARGUMENTOS DE VALIDACIÓN
        'permissionsValidated': true,
        'preciseLocationGranted': true,
        'backgroundPermissionsGranted': true,
        'batteryOptimizationDisabled': true,
      },
    );
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
