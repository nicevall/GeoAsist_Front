import 'package:geo_asist_front/core/utils/app_logger.dart';
// lib/services/battery_optimization_service.dart
// 🔋 SERVICIO ESPECIALIZADO PARA EXENCIÓN DE OPTIMIZACIÓN DE BATERÍA
import 'package:flutter/services.dart'; // ✅ CORRECCIÓN: Removido foundation.dart
import 'package:flutter/material.dart';
import 'notifications/notification_manager.dart';

/// Servicio especializado para gestionar la exención de optimización de batería
/// CRÍTICO para que el tracking continúe funcionando en background
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  // 🎯 METHODCHANNEL PARA COMUNICACIÓN NATIVA
  static const MethodChannel _nativeChannel =
      MethodChannel('com.geoasist/foreground_service');

  // 🎯 SERVICIOS
  final NotificationManager _notificationManager = NotificationManager();

  // 🎯 ESTADO DEL SERVICIO
  bool _isInitialized = false;
  bool _isExemptionGranted = false;
  bool _hasCheckedStatus = false;

  /// Inicializar el servicio de battery optimization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.d('🔋 Inicializando BatteryOptimizationService');

      await _notificationManager.initialize();
      await _checkCurrentExemptionStatus();

      _isInitialized = true;
      logger.d('✅ BatteryOptimizationService inicializado');
    } catch (e) {
      logger.d('❌ Error inicializando BatteryOptimizationService: $e');
      rethrow;
    }
  }

  /// Verificar el estado actual de la exención
  Future<bool> _checkCurrentExemptionStatus() async {
    try {
      logger.d('🔍 Verificando estado actual de battery optimization');

      final isIgnored = await _nativeChannel
              .invokeMethod<bool>('isBatteryOptimizationIgnored') ??
          false;

      _isExemptionGranted = isIgnored;
      _hasCheckedStatus = true;

      logger.d(
          '📊 Estado battery optimization: ${isIgnored ? "EXENTA" : "NO EXENTA"}');

      return isIgnored;
    } catch (e) {
      logger.d('❌ Error verificando battery optimization: $e');
      return false;
    }
  }

  /// 🎯 MÉTODO PRINCIPAL: Validar y solicitar exención OBLIGATORIA
  Future<bool> ensureBatteryOptimizationExemption({
    required BuildContext context,
    bool showDialogIfNeeded = true,
  }) async {
    try {
      logger.d('🔋 Asegurando exención de battery optimization OBLIGATORIA');

      // 1. Verificar estado actual
      final isCurrentlyExempt = await _checkCurrentExemptionStatus();

      if (isCurrentlyExempt) {
        logger.d('✅ App ya está exenta de battery optimization');
        return true;
      }

      // 2. Si no está exenta, es OBLIGATORIO solicitarla
      logger.d('⚠️ App NO está exenta - Solicitando exención OBLIGATORIA');

      if (showDialogIfNeeded) {
        // ✅ CORRECCIÓN LÍNEA 87: Verificar context antes de usar
        if (!context.mounted) return false;
        final userAccepted = await _showBatteryOptimizationDialog(context);
        if (!userAccepted) {
          // ✅ CORRECCIÓN LÍNEA 90: Verificar context antes de usar
          if (!context.mounted) return false;
          await _showMandatoryExemptionDialog(context);
          return false;
        }
      }

      // 3. Solicitar exención
      await _requestBatteryOptimizationExemption();

      // 4. Verificar nuevamente después de la solicitud
      await Future.delayed(const Duration(milliseconds: 500));
      final isNowExempt = await _checkCurrentExemptionStatus();

      if (isNowExempt) {
        logger.d('✅ Exención de battery optimization otorgada exitosamente');
        await _notificationManager.showTestNotification();
        return true;
      } else {
        logger.d('❌ Exención no otorgada - Reintentando...');
        return false;
      }
    } catch (e) {
      logger.d('❌ Error en exención battery optimization: $e');
      return false;
    }
  }

  /// Solicitar exención usando el MethodChannel nativo
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      logger.d('📱 Solicitando exención de battery optimization');

      await _nativeChannel.invokeMethod('requestBatteryOptimizationExemption');

      logger.d('✅ Solicitud de exención enviada');
    } catch (e) {
      logger.d('❌ Error solicitando exención: $e');
      rethrow;
    }
  }

  /// Mostrar diálogo educativo sobre battery optimization
  Future<bool> _showBatteryOptimizationDialog(BuildContext context) async {
    // ✅ CORRECCIÓN: Verificar context montado
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // No se puede cerrar sin responder
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.battery_alert, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Configuración Requerida'),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para garantizar el funcionamiento correcto del tracking de asistencia, necesitamos deshabilitar la optimización de batería.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '¿Por qué es necesario?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text('• Mantener el tracking activo en background'),
                  Text('• Evitar que Android cierre la app automáticamente'),
                  Text('• Garantizar notificaciones en tiempo real'),
                  Text('• Conservar tu asistencia durante el evento'),
                  SizedBox(height: 16),
                  Text(
                    'Esto NO afectará significativamente tu batería.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // ✅ CORRECCIÓN: Verificar context antes de usar Navigator
                  if (context.mounted) {
                    Navigator.of(context).pop(false);
                  }
                },
                child: const Text('No Permitir'),
              ),
              ElevatedButton(
                onPressed: () {
                  // ✅ CORRECCIÓN: Verificar context antes de usar Navigator
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Configurar Ahora'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Diálogo obligatorio si el usuario rechaza la exención
  Future<void> _showMandatoryExemptionDialog(BuildContext context) async {
    // ✅ CORRECCIÓN: Verificar context montado
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Configuración Obligatoria'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'La exención de optimización de batería es OBLIGATORIA para usar el sistema de asistencia.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Sin esta configuración:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('❌ El tracking se detendrá automáticamente'),
            Text('❌ Perderás tu asistencia sin aviso'),
            Text('❌ Las notificaciones no funcionarán'),
            SizedBox(height: 16),
            Text(
              'Debes configurar esta opción para continuar.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // ✅ CORRECCIÓN: Verificar context antes de usar Navigator
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido - Configurar'),
          ),
        ],
      ),
    );
  }

  /// 🎯 VALIDACIÓN ANTES DE INICIAR TRACKING
  Future<bool> validateBatteryOptimizationForTracking({
    required BuildContext context,
  }) async {
    try {
      logger.d('🔋 Validando battery optimization antes de tracking');

      if (!_isInitialized) {
        await initialize();
      }

      // Verificar estado actual
      final isExempt = await _checkCurrentExemptionStatus();

      if (isExempt) {
        logger.d('✅ Validation passed - Battery optimization exenta');
        return true;
      }

      // Si no está exenta, solicitar OBLIGATORIAMENTE
      logger.d('⚠️ Validation failed - Solicitando exención obligatoria');

      // ✅ CORRECCIÓN: Verificar context antes de usar después de await
      if (!context.mounted) return false;

      final exemptionGranted = await ensureBatteryOptimizationExemption(
        context: context,
        showDialogIfNeeded: true,
      );

      if (!exemptionGranted) {
        // ✅ CORRECCIÓN: Verificar context antes de usar después de await
        if (!context.mounted) return false;

        // Mostrar mensaje de error crítico
        await _showTrackingBlockedDialog(context);
        return false;
      }

      return true;
    } catch (e) {
      logger.d('❌ Error en validación battery optimization: $e');
      return false;
    }
  }

  /// Diálogo cuando el tracking está bloqueado por battery optimization
  Future<void> _showTrackingBlockedDialog(BuildContext context) async {
    // ✅ CORRECCIÓN LÍNEA 287: Verificar context antes de showDialog
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Tracking Bloqueado'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No puedes unirte al evento sin configurar la exención de battery optimization.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Opciones:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Configurar la exención ahora'),
            Text('2. Contactar al administrador'),
            Text('3. Usar otro dispositivo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // ✅ CORRECCIÓN LÍNEA 293: Verificar context antes de Navigator
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () {
              // ✅ CORRECCIÓN: Verificar context antes de Navigator
              if (context.mounted) {
                Navigator.of(context).pop();
                // Volver a intentar la configuración
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// 🎯 MÉTODOS DE INFORMACIÓN Y ESTADO

  /// Verificar si la exención está otorgada
  bool get isExemptionGranted => _isExemptionGranted;

  /// Verificar si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Verificar si se ha verificado el estado
  bool get hasCheckedStatus => _hasCheckedStatus;

  /// Obtener estado completo del servicio
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _isInitialized,
      'exemption_granted': _isExemptionGranted,
      'has_checked_status': _hasCheckedStatus,
      'service_available': true,
    };
  }

  /// 🎯 MÉTODO PARA TESTING
  Future<void> testBatteryOptimizationStatus() async {
    try {
      logger.d('🧪 Testing battery optimization status');

      final status = await _checkCurrentExemptionStatus();

      logger.d('📊 Test results:');
      logger.d('  - Exemption granted: $status');
      logger.d('  - Service initialized: $_isInitialized');
      logger.d('  - Has checked status: $_hasCheckedStatus');

      // Mostrar notificación de test
      await _notificationManager.showTestNotification();
    } catch (e) {
      logger.d('❌ Error en test battery optimization: $e');
    }
  }

  /// Re-verificar estado (útil después de cambios manuales)
  Future<bool> refreshExemptionStatus() async {
    logger.d('🔄 Refrescando estado de battery optimization');
    return await _checkCurrentExemptionStatus();
  }
}
