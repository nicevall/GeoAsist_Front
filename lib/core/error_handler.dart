import 'utils/app_logger.dart';
// lib/core/error_handler.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ✅ ERROR HANDLER: Manejo centralizado de errores preservado
/// Responsabilidades:
/// - Clasificación automática de tipos de error
/// - Logging estructurado para debug y producción
/// - Retry automático con backoff exponencial
/// - Transformación de errores técnicos a mensajes user-friendly
/// - Reporte de errores críticos y métricas
/// - Manejo de errores específicos según DETALLES BACK.md
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Configuración de reintentos
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);

  // Contadores para métricas
  int _totalErrors = 0;
  int _networkErrors = 0;
  int _authErrors = 0;
  int _validationErrors = 0;
  int _unknownErrors = 0;

  /// 🔍 MANEJAR ERROR GENERAL
  AppError handleError(dynamic error, {String? context, StackTrace? stackTrace}) {
    _totalErrors++;
    
    final appError = _classifyError(error, context);
    _logError(appError, stackTrace);
    _updateMetrics(appError);
    
    return appError;
  }

  /// 🌐 MANEJAR ERROR DE HTTP
  AppError handleHttpError(http.Response response, {String? context}) {
    final appError = _classifyHttpError(response, context);
    _logError(appError, null);
    _updateMetrics(appError);
    
    return appError;
  }

  /// 🔄 EJECUTAR CON RETRY AUTOMÁTICO
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String? context,
    int? maxRetries,
    Duration? baseDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final retries = maxRetries ?? _maxRetries;
    final delay = baseDelay ?? _baseDelay;
    
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        if (attempt == retries) {
          // Último intento fallido
          throw handleError(error, context: context);
        }
        
        // Verificar si debemos reintentar
        if (shouldRetry != null && !shouldRetry(error)) {
          throw handleError(error, context: context);
        }
        
        // Verificar si el error es retriable
        if (!_isRetriableError(error)) {
          throw handleError(error, context: context);
        }
        
        // Calcular delay con backoff exponencial
        final currentDelay = Duration(
          milliseconds: (delay.inMilliseconds * (1 << attempt)).clamp(
            delay.inMilliseconds,
            _maxDelay.inMilliseconds,
          ),
        );
        
        logger.d('🔄 Reintentando operación (${attempt + 1}/$retries) en ${currentDelay.inSeconds}s');
        await Future.delayed(currentDelay);
      }
    }
    
    throw handleError(Exception('Max retries exceeded'), context: context);
  }

  /// 🏷️ CLASIFICAR ERROR
  AppError _classifyError(dynamic error, String? context) {
    if (error is AppError) {
      return error; // Ya clasificado
    }
    
    if (error is SocketException) {
      return AppError(
        type: ErrorType.network,
        code: 'NETWORK_ERROR',
        message: 'Sin conexión a internet',
        details: 'Verifica tu conexión de red e intenta nuevamente',
        technicalMessage: error.toString(),
        context: context,
        isRetriable: true,
      );
    }
    
    if (error is TimeoutException) {
      return AppError(
        type: ErrorType.network,
        code: 'TIMEOUT_ERROR',
        message: 'La operación tardó demasiado',
        details: 'El servidor no respondió a tiempo',
        technicalMessage: error.toString(),
        context: context,
        isRetriable: true,
      );
    }
    
    if (error is FormatException) {
      return AppError(
        type: ErrorType.parsing,
        code: 'PARSING_ERROR',
        message: 'Error procesando datos',
        details: 'Los datos recibidos no tienen el formato esperado',
        technicalMessage: error.toString(),
        context: context,
        isRetriable: false,
      );
    }
    
    if (error is ArgumentError) {
      return AppError(
        type: ErrorType.validation,
        code: 'VALIDATION_ERROR',
        message: 'Datos inválidos',
        details: 'Verifica que todos los campos estén completados correctamente',
        technicalMessage: error.toString(),
        context: context,
        isRetriable: false,
      );
    }
    
    // Error desconocido
    return AppError(
      type: ErrorType.unknown,
      code: 'UNKNOWN_ERROR',
      message: 'Error inesperado',
      details: 'Ocurrió un error inesperado, intenta nuevamente',
      technicalMessage: error.toString(),
      context: context,
      isRetriable: false,
    );
  }

  /// 🌐 CLASIFICAR ERROR HTTP
  AppError _classifyHttpError(http.Response response, String? context) {
    final statusCode = response.statusCode;
    String? errorMessage;
    String? errorCode;
    
    try {
      final body = response.body;
      if (body.isNotEmpty) {
        // Intentar extraer mensaje de error del body JSON
        final jsonBody = body.contains('{') ? body : '{"message": "$body"}';
        final Map<String, dynamic>? errorData = 
            jsonBody.isNotEmpty ? Map<String, dynamic>.from({}) : null;
        
        errorMessage = errorData?['message'] as String?;
        errorCode = errorData?['code'] as String?;
      }
    } catch (e) {
      // Ignorar errores de parsing del body
    }
    
    switch (statusCode) {
      case 400:
        return AppError(
          type: ErrorType.validation,
          code: errorCode ?? 'BAD_REQUEST',
          message: errorMessage ?? 'Solicitud inválida',
          details: 'Verifica los datos enviados',
          technicalMessage: 'HTTP 400: ${response.body}',
          context: context,
          isRetriable: false,
        );
        
      case 401:
        return AppError(
          type: ErrorType.authentication,
          code: errorCode ?? 'UNAUTHORIZED',
          message: errorMessage ?? 'Credenciales inválidas',
          details: 'Verifica tu usuario y contraseña',
          technicalMessage: 'HTTP 401: ${response.body}',
          context: context,
          isRetriable: false,
        );
        
      case 403:
        return AppError(
          type: ErrorType.authorization,
          code: errorCode ?? 'FORBIDDEN',
          message: errorMessage ?? 'Sin permisos',
          details: 'No tienes permisos para realizar esta acción',
          technicalMessage: 'HTTP 403: ${response.body}',
          context: context,
          isRetriable: false,
        );
        
      case 404:
        return AppError(
          type: ErrorType.notFound,
          code: errorCode ?? 'NOT_FOUND',
          message: errorMessage ?? 'Recurso no encontrado',
          details: 'El elemento solicitado no existe',
          technicalMessage: 'HTTP 404: ${response.body}',
          context: context,
          isRetriable: false,
        );
        
      case 409:
        return AppError(
          type: ErrorType.conflict,
          code: errorCode ?? 'CONFLICT',
          message: errorMessage ?? 'Conflicto de datos',
          details: 'Los datos ya existen o están en conflicto',
          technicalMessage: 'HTTP 409: ${response.body}',
          context: context,
          isRetriable: false,
        );
        
      case 422:
        return AppError(
          type: ErrorType.validation,
          code: errorCode ?? 'UNPROCESSABLE_ENTITY',
          message: errorMessage ?? 'Datos de entrada inválidos',
          details: 'Verifica que todos los campos estén correctos',
          technicalMessage: 'HTTP 422: ${response.body}',
          context: context,
          isRetriable: false,
        );
        
      case 500:
        return AppError(
          type: ErrorType.server,
          code: errorCode ?? 'INTERNAL_SERVER_ERROR',
          message: errorMessage ?? 'Error del servidor',
          details: 'Problema temporal del servidor, intenta más tarde',
          technicalMessage: 'HTTP 500: ${response.body}',
          context: context,
          isRetriable: true,
        );
        
      case 502:
      case 503:
      case 504:
        return AppError(
          type: ErrorType.server,
          code: errorCode ?? 'SERVICE_UNAVAILABLE',
          message: errorMessage ?? 'Servicio no disponible',
          details: 'El servidor está temporalmente no disponible',
          technicalMessage: 'HTTP $statusCode: ${response.body}',
          context: context,
          isRetriable: true,
        );
        
      default:
        return AppError(
          type: statusCode >= 500 ? ErrorType.server : ErrorType.client,
          code: errorCode ?? 'HTTP_ERROR_$statusCode',
          message: errorMessage ?? 'Error HTTP $statusCode',
          details: 'Error en la comunicación con el servidor',
          technicalMessage: 'HTTP $statusCode: ${response.body}',
          context: context,
          isRetriable: statusCode >= 500,
        );
    }
  }

  /// 🔄 VERIFICAR SI EL ERROR ES RETRIABLE
  bool _isRetriableError(dynamic error) {
    if (error is AppError) {
      return error.isRetriable;
    }
    
    if (error is SocketException || 
        error is TimeoutException ||
        error is HttpException) {
      return true;
    }
    
    return false;
  }

  /// 📝 REGISTRAR ERROR
  void _logError(AppError error, StackTrace? stackTrace) {
    if (kDebugMode) {
      logger.d('❌ [${error.type.name.toUpperCase()}] ${error.code}: ${error.message}');
      logger.d('   Details: ${error.details}');
      logger.d('   Context: ${error.context ?? "None"}');
      logger.d('   Technical: ${error.technicalMessage}');
      logger.d('   Retriable: ${error.isRetriable}');
      
      if (stackTrace != null) {
        logger.d('   Stack trace:');
        logger.d(stackTrace.toString());
      }
    } else {
      // En producción, enviar a servicio de logging
      _reportErrorToService(error, stackTrace);
    }
  }

  /// 📊 ACTUALIZAR MÉTRICAS
  void _updateMetrics(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        _networkErrors++;
        break;
      case ErrorType.authentication:
      case ErrorType.authorization:
        _authErrors++;
        break;
      case ErrorType.validation:
        _validationErrors++;
        break;
      default:
        _unknownErrors++;
        break;
    }
  }

  /// 📤 REPORTAR ERROR A SERVICIO EXTERNO
  void _reportErrorToService(AppError error, StackTrace? stackTrace) {
    // Implementar envío a servicio de análisis de errores
    // Como Crashlytics, Sentry, etc.
    logger.d('📤 Reportando error crítico: ${error.code}');
  }

  /// 📊 OBTENER MÉTRICAS DE ERRORES
  ErrorMetrics getMetrics() {
    return ErrorMetrics(
      total: _totalErrors,
      network: _networkErrors,
      auth: _authErrors,
      validation: _validationErrors,
      unknown: _unknownErrors,
    );
  }

  /// 🧹 LIMPIAR MÉTRICAS
  void clearMetrics() {
    _totalErrors = 0;
    _networkErrors = 0;
    _authErrors = 0;
    _validationErrors = 0;
    _unknownErrors = 0;
  }

  /// 🎯 CREAR ERROR PERSONALIZADO
  static AppError createCustomError({
    required ErrorType type,
    required String code,
    required String message,
    String? details,
    String? context,
    bool isRetriable = false,
  }) {
    return AppError(
      type: type,
      code: code,
      message: message,
      details: details,
      technicalMessage: message,
      context: context,
      isRetriable: isRetriable,
    );
  }

  /// 🔐 ERRORES ESPECÍFICOS DE AUTENTICACIÓN
  static AppError tokenExpiredError() {
    return AppError(
      type: ErrorType.authentication,
      code: 'TOKEN_EXPIRED',
      message: 'Sesión expirada',
      details: 'Tu sesión ha expirado, inicia sesión nuevamente',
      technicalMessage: 'JWT token expired',
      isRetriable: false,
    );
  }

  static AppError invalidCredentialsError() {
    return AppError(
      type: ErrorType.authentication,
      code: 'INVALID_CREDENTIALS',
      message: 'Credenciales incorrectas',
      details: 'Email o contraseña incorrectos',
      technicalMessage: 'Invalid email or password',
      isRetriable: false,
    );
  }

  /// 📍 ERRORES ESPECÍFICOS DE GEOLOCALIZACIÓN
  static AppError locationPermissionError() {
    return AppError(
      type: ErrorType.permission,
      code: 'LOCATION_PERMISSION_DENIED',
      message: 'Permiso de ubicación denegado',
      details: 'Se requiere acceso a la ubicación para registrar asistencia',
      technicalMessage: 'Location permission denied',
      isRetriable: false,
    );
  }

  static AppError geofenceError() {
    return AppError(
      type: ErrorType.validation,
      code: 'OUTSIDE_GEOFENCE',
      message: 'Fuera del área permitida',
      details: 'Debes estar dentro del área del evento para registrar asistencia',
      technicalMessage: 'User outside event geofence',
      isRetriable: false,
    );
  }

  /// 📅 ERRORES ESPECÍFICOS DE EVENTOS
  static AppError eventNotFoundError() {
    return AppError(
      type: ErrorType.notFound,
      code: 'EVENT_NOT_FOUND',
      message: 'Evento no encontrado',
      details: 'El evento solicitado no existe o fue eliminado',
      technicalMessage: 'Event not found in database',
      isRetriable: false,
    );
  }

  static AppError eventInactiveError() {
    return AppError(
      type: ErrorType.validation,
      code: 'EVENT_INACTIVE',
      message: 'Evento inactivo',
      details: 'El evento no está activo en este momento',
      technicalMessage: 'Event is not active',
      isRetriable: false,
    );
  }
}

/// 🏷️ TIPOS DE ERROR
enum ErrorType {
  network,
  authentication,
  authorization,
  validation,
  parsing,
  server,
  client,
  permission,
  notFound,
  conflict,
  unknown,
}

/// ❌ CLASE DE ERROR DE APLICACIÓN
class AppError implements Exception {
  final ErrorType type;
  final String code;
  final String message;
  final String? details;
  final String? technicalMessage;
  final String? context;
  final bool isRetriable;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.code,
    required this.message,
    this.details,
    this.technicalMessage,
    this.context,
    this.isRetriable = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 👤 MENSAJE AMIGABLE PARA EL USUARIO
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'Problema de conexión. Verifica tu internet e intenta nuevamente.';
      case ErrorType.authentication:
        return 'Error de autenticación. Verifica tus credenciales.';
      case ErrorType.authorization:
        return 'No tienes permisos para realizar esta acción.';
      case ErrorType.validation:
        return details ?? 'Datos inválidos. Verifica la información ingresada.';
      case ErrorType.server:
        return 'Error del servidor. Intenta más tarde.';
      case ErrorType.permission:
        return 'Se requieren permisos adicionales para continuar.';
      case ErrorType.notFound:
        return 'El elemento solicitado no fue encontrado.';
      default:
        return message;
    }
  }

  @override
  String toString() {
    return 'AppError(type: $type, code: $code, message: $message, isRetriable: $isRetriable)';
  }
}

/// 📊 MÉTRICAS DE ERRORES
class ErrorMetrics {
  final int total;
  final int network;
  final int auth;
  final int validation;
  final int unknown;

  const ErrorMetrics({
    required this.total,
    required this.network,
    required this.auth,
    required this.validation,
    required this.unknown,
  });

  @override
  String toString() {
    return 'ErrorMetrics(total: $total, network: $network, auth: $auth, validation: $validation, unknown: $unknown)';
  }
}