// lib/services/permission_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Tipo de resultado para permisos de ubicación
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  restrictedBackground,
  notPrecise,
  serviceDisabled,
  error,
}

/// Servicio para gestionar permisos críticos con validación estricta
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // 🎯 VALIDACIÓN DE UBICACIÓN PRECISA OBLIGATORIA

  /// Validar si la ubicación precisa está otorgada
  Future<bool> isPreciseLocationGranted() async {
    try {
      debugPrint('🔍 Validando permisos de ubicación precisa');

      // 1. Verificar permisos básicos de ubicación
      final locationPermission = await Geolocator.checkPermission();

      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) {
        debugPrint('❌ Permisos de ubicación denegados');
        return false;
      }

      // 2. Verificar configuración de precisión
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Servicios de ubicación deshabilitados');
        return false;
      }

      // 3. Verificar precisión en Android
      if (Platform.isAndroid) {
        final hasAccuracyPermission = await _checkAndroidLocationAccuracy();
        if (!hasAccuracyPermission) {
          debugPrint('❌ Ubicación precisa no otorgada en Android');
          return false;
        }
      }

      // 4. Probar obtener ubicación con alta precisión
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        );

        final isAccurate = position.accuracy <= 20.0; // Máximo 20 metros

        debugPrint('📍 Ubicación obtenida - Precisión: ${position.accuracy}m');
        debugPrint(
            isAccurate ? '✅ Precisión aceptable' : '❌ Precisión insuficiente');

        return isAccurate;
      } catch (e) {
        debugPrint('❌ Error obteniendo ubicación precisa: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error validando ubicación precisa: $e');
      return false;
    }
  }

  /// Solicitar permisos de ubicación precisa
  Future<bool> requestPreciseLocationPermission() async {
    try {
      debugPrint('📲 Solicitando permisos de ubicación precisa');

      // 1. Solicitar permisos básicos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permisos denegados permanentemente');
        await _showLocationSettingsDialog();
        return false;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permisos de ubicación denegados');
        return false;
      }

      // 2. En Android, verificar ubicación precisa específicamente
      if (Platform.isAndroid) {
        final preciseGranted = await _requestAndroidPreciseLocation();
        if (!preciseGranted) {
          debugPrint('❌ Ubicación precisa no otorgada');
          return false;
        }
      }

      // 3. Validar que realmente funcione
      final isWorking = await isPreciseLocationGranted();

      debugPrint(isWorking
          ? '✅ Ubicación precisa configurada correctamente'
          : '❌ Configuración de ubicación incorrecta');
      return isWorking;
    } catch (e) {
      debugPrint('❌ Error solicitando ubicación precisa: $e');
      return false;
    }
  }

  // 🎯 PERMISOS DE BACKGROUND OBLIGATORIOS

  /// Solicitar permisos de background
  Future<bool> requestBackgroundPermission() async {
    try {
      debugPrint('🔄 Solicitando permisos de background');

      // 1. Verificar versión de Android
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        debugPrint('📱 Android version: ${androidInfo.version.sdkInt}');

        // Android 10+ requiere background location
        if (androidInfo.version.sdkInt >= 29) {
          final backgroundGranted = await _requestAndroidBackgroundLocation();
          if (!backgroundGranted) {
            debugPrint('❌ Background location no otorgado');
            return false;
          }
        }
      }

      // 2. Solicitar exención de optimización de batería
      final batteryOptimizationDisabled =
          await requestBatteryOptimizationExemption();

      // 3. Verificar permisos adicionales necesarios
      final additionalPermissions =
          await _requestAdditionalBackgroundPermissions();

      final allGranted = batteryOptimizationDisabled && additionalPermissions;

      debugPrint(allGranted
          ? '✅ Permisos de background configurados'
          : '❌ Faltan permisos de background');
      return allGranted;
    } catch (e) {
      debugPrint('❌ Error solicitando permisos de background: $e');
      return false;
    }
  }

  /// Solicitar exención de optimización de batería
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      debugPrint('🔋 Solicitando exención de optimización de batería');

      if (Platform.isAndroid) {
        // Verificar si ya está exenta
        final isIgnoring =
            await Permission.ignoreBatteryOptimizations.isGranted;

        if (isIgnoring) {
          debugPrint('✅ Ya exenta de optimización de batería');
          return true;
        }

        // Solicitar exención
        final status = await Permission.ignoreBatteryOptimizations.request();

        if (status.isGranted) {
          debugPrint('✅ Exención de batería otorgada');
          return true;
        } else {
          debugPrint('❌ Exención de batería denegada');
          await _showBatteryOptimizationDialog();
          return false;
        }
      }

      // En iOS no es necesario
      return true;
    } catch (e) {
      debugPrint('❌ Error configurando exención de batería: $e');
      return false;
    }
  }

  // 🎯 CONFIGURACIÓN DE FOREGROUND SERVICE

  /// Configurar servicio foreground
  Future<bool> setupForegroundService() async {
    try {
      debugPrint('⚙️ Configurando servicio foreground');

      if (Platform.isAndroid) {
        // Verificar permisos de notificaciones
        final notificationStatus = await Permission.notification.status;

        if (!notificationStatus.isGranted) {
          final granted = await Permission.notification.request();
          if (!granted.isGranted) {
            debugPrint('❌ Permisos de notificación denegados');
            return false;
          }
        }

        // En Android 14+, verificar permiso específico de foreground service
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 34) {
          final foregroundServiceStatus =
              await Permission.systemAlertWindow.status;
          if (!foregroundServiceStatus.isGranted) {
            await Permission.systemAlertWindow.request();
          }
        }
      }

      debugPrint('✅ Servicio foreground configurado');
      return true;
    } catch (e) {
      debugPrint('❌ Error configurando foreground service: $e');
      return false;
    }
  }

  // 🎯 MONITOREO CONTINUO DE PERMISOS

  /// Monitorear cambios en permisos
  Stream<PermissionStatus> monitorPermissionChanges() async* {
    while (true) {
      try {
        final hasLocation = await isPreciseLocationGranted();
        final hasBackground = await _checkBackgroundPermissions();

        if (hasLocation && hasBackground) {
          yield PermissionStatus.granted;
        } else {
          yield PermissionStatus.denied;
        }

        // Verificar cada 10 minutos
        await Future.delayed(const Duration(minutes: 10));
      } catch (e) {
        debugPrint('❌ Error monitoreando permisos: $e');
        yield PermissionStatus.permanentlyDenied;
        await Future.delayed(const Duration(minutes: 10));
      }
    }
  }

  // 🎯 MÉTODOS ESPECÍFICOS DE ANDROID

  Future<bool> _checkAndroidLocationAccuracy() async {
    try {
      // En Android 12+, verificar ACCESS_FINE_LOCATION específicamente
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 31) {
        // Android 12+ tiene control granular de precisión
        final fineLocation = await Permission.locationWhenInUse.isGranted;
        final preciseLocation = await Permission.location.isGranted;

        return fineLocation && preciseLocation;
      } else {
        // Versiones anteriores, verificar que funcione la ubicación precisa
        return await Permission.location.isGranted;
      }
    } catch (e) {
      debugPrint('❌ Error verificando precisión Android: $e');
      return false;
    }
  }

  Future<bool> _requestAndroidPreciseLocation() async {
    try {
      // Solicitar permisos específicos para ubicación precisa
      final permissions = <Permission>[];

      permissions.add(Permission.location);
      permissions.add(Permission.locationWhenInUse);

      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Android 12+ requiere permisos específicos de precisión
      if (androidInfo.version.sdkInt >= 31) {
        permissions.add(Permission.locationAlways);
      }

      final statuses = await permissions.request();

      final allGranted = statuses.values.every((status) => status.isGranted);

      debugPrint('📍 Permisos de ubicación Android: $allGranted');
      return allGranted;
    } catch (e) {
      debugPrint('❌ Error solicitando ubicación precisa Android: $e');
      return false;
    }
  }

  Future<bool> _requestAndroidBackgroundLocation() async {
    try {
      debugPrint('🔄 Solicitando background location en Android');

      // Verificar si ya está otorgado
      final currentStatus = await Permission.locationAlways.status;

      if (currentStatus.isGranted) {
        debugPrint('✅ Background location ya otorgado');
        return true;
      }

      // Solicitar permiso
      final status = await Permission.locationAlways.request();

      if (status.isGranted) {
        debugPrint('✅ Background location otorgado');
        return true;
      } else {
        debugPrint('❌ Background location denegado');
        await _showBackgroundLocationDialog();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error solicitando background location Android: $e');
      return false;
    }
  }

  Future<bool> _requestAdditionalBackgroundPermissions() async {
    try {
      final permissions = <Permission>[];

      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.notification,
          Permission.systemAlertWindow,
          Permission.accessNotificationPolicy,
        ]);
      }

      final statuses = await permissions.request();

      // No todos son obligatorios, pero mejoran la funcionalidad
      final criticalGranted =
          statuses[Permission.notification]?.isGranted ?? true;

      debugPrint('🔔 Permisos adicionales: críticos=$criticalGranted');
      return criticalGranted;
    } catch (e) {
      debugPrint('❌ Error solicitando permisos adicionales: $e');
      return true; // No bloquear por estos permisos
    }
  }

  Future<bool> _checkBackgroundPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Android 10+ requiere background location
        if (androidInfo.version.sdkInt >= 29) {
          final backgroundLocation = await Permission.locationAlways.isGranted;
          if (!backgroundLocation) return false;
        }

        // Verificar exención de optimización de batería
        final batteryOptimization =
            await Permission.ignoreBatteryOptimizations.isGranted;
        return batteryOptimization;
      }

      return true; // iOS no requiere estos permisos específicos
    } catch (e) {
      debugPrint('❌ Error verificando permisos background: $e');
      return false;
    }
  }

  // 🎯 DIÁLOGOS EDUCATIVOS

  Future<void> _showLocationSettingsDialog() async {
    debugPrint('📋 Mostrando diálogo de configuración de ubicación');

    // En una implementación real, aquí se abriría la configuración del sistema
    // Por ahora solo loggeamos para debugging
    debugPrint(
        '💡 Usuario debe ir a Configuración > Aplicaciones > GeoAsist > Permisos > Ubicación > Precisa');
  }

  Future<void> _showBatteryOptimizationDialog() async {
    debugPrint('📋 Mostrando diálogo de optimización de batería');

    debugPrint(
        '💡 Usuario debe ir a Configuración > Batería > Optimización de batería > Todas las apps > GeoAsist > No optimizar');
  }

  Future<void> _showBackgroundLocationDialog() async {
    debugPrint('📋 Mostrando diálogo de ubicación en background');

    debugPrint(
        '💡 Usuario debe permitir ubicación "Siempre" para tracking continuo');
  }

  Future<void> showLocationSettingsDialog() async {
    await _showLocationSettingsDialog();
  }

  // 🎯 MÉTODOS UTILITARIOS PÚBLICOS

  /// Validar permisos completos para tracking
  Future<bool> validateAllPermissionsForTracking() async {
    try {
      debugPrint('🔒 Validando todos los permisos para tracking');

      final checks = await Future.wait([
        isPreciseLocationGranted(),
        _checkBackgroundPermissions(),
        _checkNotificationPermissions(),
      ]);

      final locationOk = checks[0];
      final backgroundOk = checks[1];
      final notificationOk = checks[2];

      debugPrint(
          '📊 Permisos - Ubicación: $locationOk, Background: $backgroundOk, Notificaciones: $notificationOk');

      final allOk = locationOk && backgroundOk && notificationOk;

      debugPrint(allOk
          ? '✅ Todos los permisos validados'
          : '❌ Faltan permisos críticos');
      return allOk;
    } catch (e) {
      debugPrint('❌ Error validando permisos: $e');
      return false;
    }
  }

  Future<bool> _checkNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.notification.isGranted;
      }
      return true; // iOS maneja notificaciones diferente
    } catch (e) {
      debugPrint('❌ Error verificando notificaciones: $e');
      return false;
    }
  }

  /// Obtener estado detallado de permisos
  Future<Map<String, dynamic>> getDetailedPermissionStatus() async {
    try {
      final status = <String, dynamic>{};

      // Ubicación
      final locationPermission = await Geolocator.checkPermission();
      status['location_permission'] = locationPermission.toString();
      status['location_service_enabled'] =
          await Geolocator.isLocationServiceEnabled();
      status['location_precise'] = await isPreciseLocationGranted();

      // Background
      if (Platform.isAndroid) {
        status['background_location'] =
            await Permission.locationAlways.isGranted;
        status['battery_optimization_ignored'] =
            await Permission.ignoreBatteryOptimizations.isGranted;
      }

      // Notificaciones
      status['notifications'] = await Permission.notification.isGranted;

      // Sistema
      status['platform'] = Platform.operatingSystem;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        status['android_version'] = androidInfo.version.sdkInt;
      }

      debugPrint('📋 Estado detallado de permisos: $status');
      return status;
    } catch (e) {
      debugPrint('❌ Error obteniendo estado de permisos: $e');
      return {'error': e.toString()};
    }
  }

  /// Abrir configuración de la aplicación
  Future<bool> openAppSettings() async {
    try {
      debugPrint('⚙️ Abriendo configuración de la aplicación');
      return await Permission.manageExternalStorage.request().isGranted;
    } catch (e) {
      debugPrint('❌ Error abriendo configuración: $e');
      return false;
    }
  }

  /// Verificar si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('❌ Error verificando servicios de ubicación: $e');
      return false;
    }
  }

  /// Obtener precisión actual de ubicación
  Future<double?> getCurrentLocationAccuracy() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      );
      return position.accuracy;
    } catch (e) {
      debugPrint('❌ Error obteniendo precisión: $e');
      return null;
    }
  }

  /// Verificar si la app puede ejecutarse en background
  Future<bool> canRunInBackground() async {
    try {
      if (Platform.isAndroid) {
        final batteryOptimized =
            await Permission.ignoreBatteryOptimizations.isGranted;
        final backgroundLocation = await Permission.locationAlways.isGranted;
        return batteryOptimized && backgroundLocation;
      }
      return true; // iOS maneja esto automáticamente
    } catch (e) {
      debugPrint('❌ Error verificando background: $e');
      return false;
    }
  }

  // 🎯 CONFIGURACIÓN AUTOMÁTICA

  /// Configurar todos los permisos automáticamente
  Future<Map<String, bool>> requestAllPermissions() async {
    debugPrint('🚀 Iniciando configuración automática de permisos');

    final results = <String, bool>{};

    try {
      // 1. Ubicación precisa
      results['location'] = await requestPreciseLocationPermission();

      // 2. Background
      results['background'] = await requestBackgroundPermission();

      // 3. Foreground service
      results['foreground_service'] = await setupForegroundService();

      // 4. Validación final
      results['all_valid'] = await validateAllPermissionsForTracking();

      debugPrint('📊 Resultados configuración: $results');

      final success = results.values.every((granted) => granted);
      debugPrint(success
          ? '✅ Configuración completa exitosa'
          : '❌ Configuración incompleta');

      return results;
    } catch (e) {
      debugPrint('❌ Error en configuración automática: $e');
      results['error'] = false;
      return results;
    }
  }

  /// Verificar configuración cada cierto tiempo
  Future<bool> performPeriodicCheck() async {
    try {
      debugPrint('🔍 Verificación periódica de permisos');

      final isValid = await validateAllPermissionsForTracking();

      if (!isValid) {
        debugPrint('⚠️ Permisos han cambiado - requiere nueva configuración');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Error en verificación periódica: $e');
      return false;
    }
  }

  // 🎯 LIMPIEZA Y RESET

  /// Limpiar caché de permisos
  void clearPermissionCache() {
    debugPrint('🧹 Limpiando caché de permisos');
    // En el futuro se puede implementar caché local si es necesario
  }

  /// Verificar si es necesario volver a solicitar permisos
  Future<bool> shouldRequestPermissionsAgain() async {
    try {
      final lastCheck = await _getLastPermissionCheck();
      final now = DateTime.now();

      // Verificar cada 24 horas
      if (lastCheck == null || now.difference(lastCheck).inHours >= 24) {
        await _saveLastPermissionCheck(now);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error verificando necesidad de permisos: $e');
      return true; // Si hay error, mejor verificar
    }
  }

  Future<DateTime?> _getLastPermissionCheck() async {
    // En una implementación real, esto se guardaría en SharedPreferences
    // Por ahora retornamos null para siempre verificar
    return null;
  }

  Future<void> _saveLastPermissionCheck(DateTime date) async {
    // En una implementación real, esto se guardaría en SharedPreferences
    debugPrint('💾 Guardando última verificación: $date');
  }

  // 🎯 INFORMACIÓN PARA DEBUGGING

  /// Obtener información completa del sistema para debugging
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final info = <String, dynamic>{};

      // Información del dispositivo
      info['platform'] = Platform.operatingSystem;
      info['is_physical_device'] = !kIsWeb;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        info['android_version'] = androidInfo.version.sdkInt;
        info['android_release'] = androidInfo.version.release;
        info['device_model'] = androidInfo.model;
        info['manufacturer'] = androidInfo.manufacturer;
      }

      // Estado de servicios
      info['location_service_enabled'] =
          await Geolocator.isLocationServiceEnabled();

      // Permisos detallados
      info['permissions'] = await getDetailedPermissionStatus();

      // Capacidades de ubicación
      final accuracy = await getCurrentLocationAccuracy();
      info['current_accuracy'] = accuracy;
      info['can_run_background'] = await canRunInBackground();

      debugPrint('🔧 Sistema info: $info');
      return info;
    } catch (e) {
      debugPrint('❌ Error obteniendo info del sistema: $e');
      return {'error': e.toString()};
    }
  }

  // AGREGAR al final de la clase PermissionService, antes del cierre }

  /// Verificar si tiene permisos de ubicación básicos
  Future<bool> hasLocationPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever &&
          serviceEnabled;
    } catch (e) {
      debugPrint('❌ Error verificando permisos de ubicación: $e');
      return false;
    }
  }

  /// Obtener ubicación actual del dispositivo
  Future<Position?> getCurrentLocation() async {
    try {
      // Verificar permisos primero
      if (!await hasLocationPermissions()) {
        debugPrint('❌ Sin permisos de ubicación para obtener posición');
        return null;
      }

      // Obtener ubicación con configuración moderna
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      );

      debugPrint(
          '📍 Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Solicitar permisos de ubicación con resultado detallado
  Future<LocationPermissionResult> requestLocationPermissions() async {
    try {
      debugPrint('📲 Solicitando permisos de ubicación');

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionResult.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionResult.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionResult.granted;
        default:
          return LocationPermissionResult.denied;
      }
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
      return LocationPermissionResult.denied;
    }
  }
}
