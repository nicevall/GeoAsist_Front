// lib/services/attendance/permission_flow_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../permission_service.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';

/// ✅ PERMISSION FLOW MANAGER: Gestión del flujo de permisos críticos preservado
/// Responsabilidades:
/// - Flujo secuencial obligatorio: Servicios → Preciso → Siempre → Batería
/// - Validaciones automáticas sin escape
/// - Estado de permisos en tiempo real
/// - Recheck automático después de configurar
/// - Callbacks para coordinación con UI
class PermissionFlowManager {
  final PermissionService _permissionService = PermissionService();
  
  // Estado de permisos críticos
  Map<String, bool> _permissionStatus = {};
  bool _allPermissionsGranted = false;
  bool _showingPermissionDialog = false;
  
  // Callbacks para coordinación
  VoidCallback? _onPermissionStatusChanged;
  VoidCallback? _onAllPermissionsGranted;
  Function(String)? _onShowPermissionDialog;
  
  /// Estado actual de permisos
  Map<String, bool> get permissionStatus => Map.from(_permissionStatus);
  
  /// ¿Todos los permisos están otorgados?
  bool get allPermissionsGranted => _allPermissionsGranted;
  
  /// ¿Se está mostrando un diálogo de permisos?
  bool get showingPermissionDialog => _showingPermissionDialog;

  /// Configurar callbacks para coordinación con UI
  void setCallbacks({
    VoidCallback? onPermissionStatusChanged,
    VoidCallback? onAllPermissionsGranted,
    Function(String)? onShowPermissionDialog,
  }) {
    _onPermissionStatusChanged = onPermissionStatusChanged;
    _onAllPermissionsGranted = onAllPermissionsGranted;
    _onShowPermissionDialog = onShowPermissionDialog;
  }

  /// ✅ INICIALIZAR VERIFICACIÓN DE PERMISOS CRÍTICOS
  /// Este es el punto de entrada principal del flujo
  Future<void> initializeCriticalPermissionsFlow() async {
    logger.d('🔐 Iniciando flujo de permisos críticos...');
    
    // Verificar todos los permisos críticos
    await _checkAllPermissions();
    
    // Si no todos los permisos están otorgados, iniciar flujo secuencial
    if (!_areAllPermissionsGranted()) {
      await _startPermissionFlow();
    } else {
      // Todos los permisos están OK
      _allPermissionsGranted = true;
      _onAllPermissionsGranted?.call();
      logger.d('✅ Todos los permisos críticos están otorgados');
    }
  }

  /// 🔍 VERIFICAR TODOS LOS PERMISOS
  Future<void> _checkAllPermissions() async {
    _permissionStatus = await _permissionService.checkCriticalPermissions();
    _updatePermissionState();
    logger.d('📋 Estado de permisos actualizado: $_permissionStatus');
  }

  /// ✅ VERIFICAR SI TODOS LOS PERMISOS ESTÁN OTORGADOS
  bool _areAllPermissionsGranted() {
    return _permissionStatus['location_precise'] == true &&
           _permissionStatus['location_always'] == true &&
           _permissionStatus['battery_optimization'] == true &&
           _permissionStatus['location_services'] == true;
  }

  /// 🔄 ACTUALIZAR ESTADO DE PERMISOS
  void _updatePermissionState() {
    _allPermissionsGranted = _areAllPermissionsGranted();
    _onPermissionStatusChanged?.call();
  }

  /// 🚦 INICIAR FLUJO SECUENCIAL DE PERMISOS
  /// Orden obligatorio: Servicios → Preciso → Siempre → Batería
  Future<void> _startPermissionFlow() async {
    if (_showingPermissionDialog) return; // Evitar diálogos múltiples
    
    logger.d('🚦 Iniciando flujo secuencial de permisos...');
    _showingPermissionDialog = true;
    
    // Verificar en orden estricto
    if (_permissionStatus['location_services'] != true) {
      _onShowPermissionDialog?.call('location_services');
    } else if (_permissionStatus['location_precise'] != true) {
      _onShowPermissionDialog?.call('location_precise');
    } else if (_permissionStatus['location_always'] != true) {
      _onShowPermissionDialog?.call('location_always');
    } else if (_permissionStatus['battery_optimization'] != true) {
      _onShowPermissionDialog?.call('battery_optimization');
    }
  }

  /// ✅ RECHECK DESPUÉS DE CONFIGURAR PERMISO
  /// Se llama cuando el usuario termina de configurar un permiso
  Future<void> recheckPermissionsAndContinue() async {
    _showingPermissionDialog = false;
    
    logger.d('🔍 Reverificando permisos después de configuración...');
    
    // Verificar nuevamente todos los permisos
    await _checkAllPermissions();
    
    if (_areAllPermissionsGranted()) {
      // ¡Todos los permisos están OK!
      _allPermissionsGranted = true;
      _onAllPermissionsGranted?.call();
      logger.d('✅ ¡Todos los permisos críticos ahora están otorgados!');
    } else {
      // Todavía faltan permisos, continuar con el siguiente en secuencia
      logger.d('⚠️ Todavía faltan permisos, continuando flujo...');
      Timer(Duration(milliseconds: 800), () async {
        await _startPermissionFlow();
      });
    }
  }

  /// 🔧 SOLICITAR PERMISO ESPECÍFICO
  Future<bool> requestSpecificPermission(String permissionType) async {
    bool granted = false;
    
    try {
      switch (permissionType) {
        case 'location_services':
          // Este se maneja a través de configuraciones del sistema
          await _permissionService.openLocationSettings();
          // El recheck se maneja por timer en el diálogo
          break;
          
        case 'location_precise':
          granted = await _permissionService.requestPreciseLocationPermissionEnhanced();
          break;
          
        case 'location_always':
          granted = await _permissionService.requestAlwaysLocationPermission();
          break;
          
        case 'battery_optimization':
          granted = await _permissionService.requestBatteryOptimizationPermission();
          break;
          
        default:
          logger.d('❌ Tipo de permiso desconocido: $permissionType');
          return false;
      }
      
      logger.d('📋 Permiso $permissionType: ${granted ? "otorgado" : "denegado"}');
      return granted;
    } catch (e) {
      logger.d('❌ Error solicitando permiso $permissionType: $e');
      return false;
    }
  }

  /// 🔍 OBTENER ESTADO DE PERMISO ESPECÍFICO
  bool isPermissionGranted(String permissionType) {
    return _permissionStatus[permissionType] == true;
  }

  /// 📊 OBTENER PROGRESO DE PERMISOS (0.0 - 1.0)
  double getPermissionProgress() {
    if (_permissionStatus.isEmpty) return 0.0;
    
    final grantedCount = _permissionStatus.values.where((granted) => granted == true).length;
    final totalCount = _permissionStatus.length;
    
    return grantedCount / totalCount;
  }

  /// 📋 OBTENER PERMISOS FALTANTES
  List<String> getMissingPermissions() {
    return _permissionStatus.entries
        .where((entry) => entry.value != true)
        .map((entry) => entry.key)
        .toList();
  }

  /// 📝 OBTENER NOMBRE AMIGABLE DE PERMISO
  String getPermissionFriendlyName(String permissionType) {
    const friendlyNames = {
      'location_services': 'Servicios de Ubicación',
      'location_precise': 'Ubicación Precisa',
      'location_always': 'Ubicación Siempre',
      'battery_optimization': 'Optimización de Batería',
    };
    
    return friendlyNames[permissionType] ?? permissionType;
  }

  /// 📊 OBTENER DESCRIPCIÓN DE PERMISO
  String getPermissionDescription(String permissionType) {
    const descriptions = {
      'location_services': 'Activar servicios de ubicación del dispositivo',
      'location_precise': 'Ubicación precisa para geofencing exacto',
      'location_always': 'Ubicación continua durante eventos',
      'battery_optimization': 'Desactivar optimización para tracking estable',
    };
    
    return descriptions[permissionType] ?? 'Permiso requerido para funcionamiento';
  }

  /// 🎯 OBTENER ICONO DE PERMISO
  String getPermissionIcon(String permissionType) {
    const icons = {
      'location_services': '📍',
      'location_precise': '🎯',
      'location_always': '⏰',
      'battery_optimization': '🔋',
    };
    
    return icons[permissionType] ?? '⚙️';
  }

  /// ⚠️ VERIFICAR SI PERMISO ES CRÍTICO
  bool isPermissionCritical(String permissionType) {
    // Todos los permisos en este manager son críticos
    return [
      'location_services',
      'location_precise', 
      'location_always',
      'battery_optimization'
    ].contains(permissionType);
  }

  /// 🔄 FORZAR RECHECK MANUAL
  Future<void> forcePermissionRecheck() async {
    logger.d('🔄 Forzando recheck manual de permisos...');
    await _checkAllPermissions();
    
    if (!_areAllPermissionsGranted() && !_showingPermissionDialog) {
      await _startPermissionFlow();
    }
  }

  /// 🧹 RESET DEL ESTADO (para testing)
  void resetState() {
    _permissionStatus.clear();
    _allPermissionsGranted = false;
    _showingPermissionDialog = false;
    logger.d('🧹 Estado de permisos reseteado');
  }

  /// 📊 OBTENER RESUMEN DE ESTADO
  Map<String, dynamic> getPermissionSummary() {
    return {
      'permissionStatus': Map.from(_permissionStatus),
      'allGranted': _allPermissionsGranted,
      'showingDialog': _showingPermissionDialog,
      'progress': getPermissionProgress(),
      'missingPermissions': getMissingPermissions(),
      'criticalPermissionsCount': 4,
      'grantedPermissionsCount': _permissionStatus.values.where((granted) => granted == true).length,
    };
  }

  /// 🔒 VALIDAR ESTADO ANTES DE TRACKING
  bool canStartTracking() {
    return _allPermissionsGranted && 
           !_showingPermissionDialog &&
           _permissionStatus.isNotEmpty;
  }

  /// ⚠️ OBTENER MENSAJE DE ERROR SI NO SE PUEDE INICIAR TRACKING
  String? getTrackingBlockerMessage() {
    if (_showingPermissionDialog) {
      return 'Configurando permisos, por favor espera...';
    }
    
    if (!_allPermissionsGranted) {
      final missing = getMissingPermissions();
      if (missing.isNotEmpty) {
        final missingNames = missing.map((p) => getPermissionFriendlyName(p)).join(', ');
        return 'Faltan permisos: $missingNames';
      }
    }
    
    if (_permissionStatus.isEmpty) {
      return 'Estado de permisos no inicializado';
    }
    
    return null; // Todo OK
  }

  /// 🧪 SIMULAR PERMISO OTORGADO (para testing)
  void simulatePermissionGranted(String permissionType) {
    if (kDebugMode) {
      _permissionStatus[permissionType] = true;
      _updatePermissionState();
      logger.d('🧪 Simulado permiso otorgado: $permissionType');
    }
  }

  /// 🧪 SIMULAR PERMISO DENEGADO (para testing)
  void simulatePermissionDenied(String permissionType) {
    if (kDebugMode) {
      _permissionStatus[permissionType] = false;
      _updatePermissionState();
      logger.d('🧪 Simulado permiso denegado: $permissionType');
    }
  }
}