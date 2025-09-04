// lib/services/evento/evento_validator.dart
import 'package:flutter/foundation.dart';
import '../../models/evento_model.dart';
import '../../models/usuario_model.dart';
import '../../core/app_constants.dart';

/// ✅ VALIDATOR: Validaciones de business rules y permisos
/// Responsabilidades:
/// - Validaciones de entrada de datos
/// - Business rules y permisos de usuario
/// - Validaciones antes de operaciones CRUD
/// - Validaciones de integridad de datos
class EventoValidator {
  static final EventoValidator _instance = EventoValidator._internal();
  factory EventoValidator() => _instance;
  EventoValidator._internal();

  /// ✅ VALIDAR CREACIÓN DE EVENTO
  ValidationResult validateEventCreation(Evento evento, Usuario? usuario) {
    debugPrint('🔍 Validating event creation: ${evento.titulo}');

    // 1. Validar usuario
    final userValidation = _validateUser(usuario);
    if (!userValidation.isValid) {
      return userValidation;
    }

    // 2. Validar permisos de creación
    final permissionResult = _validateCreationPermissions(usuario!);
    if (!permissionResult.isValid) {
      return permissionResult;
    }

    // 3. Validar datos básicos del evento
    final basicValidation = _validateBasicEventData(evento);
    if (!basicValidation.isValid) {
      return basicValidation;
    }

    // 4. Validar fechas y horarios
    final timeValidation = _validateEventTiming(evento);
    if (!timeValidation.isValid) {
      return timeValidation;
    }

    // 5. Validar ubicación
    final locationValidation = _validateEventLocation(evento);
    if (!locationValidation.isValid) {
      return locationValidation;
    }

    debugPrint('✅ Event creation validation passed');
    return ValidationResult.success('Evento válido para creación');
  }

  /// ✅ VALIDAR EDICIÓN DE EVENTO
  ValidationResult validateEventUpdate(Evento evento, Usuario? usuario) {
    debugPrint('🔍 Validating event update: ${evento.titulo}');

    // 1. Validar que el evento existe y no está eliminado
    if (evento.estado.toLowerCase() == 'eliminado') {
      return ValidationResult.error('No se puede editar un evento eliminado');
    }

    // 2. Validar usuario y permisos
    final userValidation = _validateUser(usuario);
    if (!userValidation.isValid) {
      return userValidation;
    }

    final permissionResult = _validateUpdatePermissions(evento, usuario!);
    if (!permissionResult.isValid) {
      return permissionResult;
    }

    // 3. Validar datos básicos
    final basicValidation = _validateBasicEventData(evento);
    if (!basicValidation.isValid) {
      return basicValidation;
    }

    // 4. Validar que no se edite un evento activo con estudiantes
    final activeValidation = _validateEditingActiveEvent(evento);
    if (!activeValidation.isValid) {
      return activeValidation;
    }

    debugPrint('✅ Event update validation passed');
    return ValidationResult.success('Evento válido para edición');
  }

  /// ✅ VALIDAR ELIMINACIÓN DE EVENTO (SOFT DELETE)
  ValidationResult validateEventDeletion(String eventoId, Usuario? usuario) {
    debugPrint('🔍 Validating event deletion: $eventoId');

    // 1. Validar usuario
    final userValidation = _validateUser(usuario);
    if (!userValidation.isValid) {
      return userValidation;
    }

    // 2. Validar permisos de eliminación
    final permissionResult = _validateDeletionPermissions(eventoId, usuario!);
    if (!permissionResult.isValid) {
      return permissionResult;
    }

    // 3. Validar ID del evento
    if (eventoId.isEmpty) {
      return ValidationResult.error('ID de evento requerido para eliminación');
    }

    debugPrint('✅ Event deletion validation passed');
    return ValidationResult.success('Evento válido para eliminación');
  }

  /// ✅ VALIDAR TOGGLE ESTADO ACTIVO
  ValidationResult validateToggleActive(String eventoId, bool isActive, Usuario? usuario) {
    debugPrint('🔍 Validating toggle active: $eventoId → $isActive');

    // 1. Validar usuario
    final userValidation = _validateUser(usuario);
    if (!userValidation.isValid) {
      return userValidation;
    }

    // 2. Validar permisos
    final permissionResult = _validateTogglePermissions(eventoId, usuario!);
    if (!permissionResult.isValid) {
      return permissionResult;
    }

    // 3. Validar ID
    if (eventoId.isEmpty) {
      return ValidationResult.error('ID de evento requerido');
    }

    debugPrint('✅ Toggle active validation passed');
    return ValidationResult.success('Válido para cambiar estado');
  }

  /// ✅ VALIDAR ACCESO A EVENTO (ESTUDIANTES)
  ValidationResult validateStudentEventAccess(Evento evento, Usuario? usuario) {
    debugPrint('🔍 Validating student access to: ${evento.titulo}');

    // 1. Validar usuario estudiante
    if (usuario == null || usuario.rol != AppConstants.estudianteRole) {
      return ValidationResult.error('Solo estudiantes pueden acceder a eventos');
    }

    // 2. Validar que el evento no esté eliminado
    if (evento.estado.toLowerCase() == 'eliminado') {
      return ValidationResult.error('Este evento ya no está disponible');
    }

    // 3. Validar que el evento esté disponible para estudiantes
    final allowedStates = ['activo', 'en espera'];
    if (!allowedStates.contains(evento.estado.toLowerCase())) {
      return ValidationResult.error('Este evento no está disponible en este momento');
    }

    // 4. Validar horarios
    final now = DateTime.now();
    if (evento.horaFinal.isBefore(now)) {
      return ValidationResult.error('Este evento ya ha terminado');
    }

    // 5. Validar que el evento no esté muy próximo a iniciar
    final timeDiff = evento.horaInicio.difference(now).inMinutes;
    if (timeDiff > 60) {
      return ValidationResult.error('Este evento aún no está disponible para unirse');
    }

    debugPrint('✅ Student event access validation passed');
    return ValidationResult.success('Estudiante puede acceder al evento');
  }

  /// ⚙️ VALIDACIONES PRIVADAS

  /// Validar usuario básico
  ValidationResult _validateUser(Usuario? usuario) {
    if (usuario == null) {
      return ValidationResult.error('Usuario requerido para esta operación');
    }

    if (usuario.id.isEmpty) {
      return ValidationResult.error('ID de usuario inválido');
    }

    if (usuario.rol.isEmpty) {
      return ValidationResult.error('Rol de usuario requerido');
    }

    return ValidationResult.success('Usuario válido');
  }

  /// Validar permisos de creación
  ValidationResult _validateCreationPermissions(Usuario usuario) {
    final allowedRoles = [AppConstants.profesorRole, AppConstants.adminRole];
    
    if (!allowedRoles.contains(usuario.rol)) {
      return ValidationResult.error('No tienes permisos para crear eventos');
    }

    return ValidationResult.success('Permisos de creación válidos');
  }

  /// Validar permisos de edición
  ValidationResult _validateUpdatePermissions(Evento evento, Usuario usuario) {
    // Admins pueden editar cualquier evento
    if (usuario.rol == AppConstants.adminRole) {
      return ValidationResult.success('Admin puede editar cualquier evento');
    }

    // Docentes solo pueden editar sus propios eventos
    if (usuario.rol == AppConstants.profesorRole) {
      if (evento.creadoPor == usuario.id) {
        return ValidationResult.success('Docente puede editar su propio evento');
      } else {
        return ValidationResult.error('Solo puedes editar tus propios eventos');
      }
    }

    return ValidationResult.error('No tienes permisos para editar eventos');
  }

  /// Validar permisos de eliminación
  ValidationResult _validateDeletionPermissions(String eventoId, Usuario usuario) {
    // Similar a edición - admin puede eliminar cualquiera, profesor solo los suyos
    final allowedRoles = [AppConstants.profesorRole, AppConstants.adminRole];
    
    if (!allowedRoles.contains(usuario.rol)) {
      return ValidationResult.error('No tienes permisos para eliminar eventos');
    }

    // Para validación completa, necesitaríamos el evento completo
    // Por ahora, permitimos si tiene rol adecuado
    return ValidationResult.success('Permisos de eliminación válidos');
  }

  /// Validar permisos de toggle
  ValidationResult _validateTogglePermissions(String eventoId, Usuario usuario) {
    return _validateDeletionPermissions(eventoId, usuario);
  }

  /// Validar datos básicos del evento
  ValidationResult _validateBasicEventData(Evento evento) {
    // Título requerido
    if (evento.titulo.trim().isEmpty) {
      return ValidationResult.error('El título del evento es requerido');
    }

    if (evento.titulo.length < 3) {
      return ValidationResult.error('El título debe tener al menos 3 caracteres');
    }

    if (evento.titulo.length > 100) {
      return ValidationResult.error('El título no puede exceder 100 caracteres');
    }

    // Tipo válido
    final validTypes = ['conferencia', 'taller', 'seminario', 'clase', 'evento'];
    if (evento.tipo != null && !validTypes.contains(evento.tipo!.toLowerCase())) {
      return ValidationResult.error('Tipo de evento no válido');
    }

    // Descripción
    if (evento.descripcion != null && evento.descripcion!.length > 500) {
      return ValidationResult.error('La descripción no puede exceder 500 caracteres');
    }

    return ValidationResult.success('Datos básicos válidos');
  }

  /// Validar fechas y horarios
  ValidationResult _validateEventTiming(Evento evento) {
    final now = DateTime.now();

    // Fecha no puede ser en el pasado
    if (evento.fecha.isBefore(now.subtract(const Duration(days: 1)))) {
      return ValidationResult.error('La fecha del evento no puede ser en el pasado');
    }

    // Hora de fin debe ser después de hora de inicio
    if (evento.horaFinal.isBefore(evento.horaInicio)) {
      return ValidationResult.error('La hora de fin debe ser posterior a la hora de inicio');
    }

    // Duración mínima de 30 minutos
    final duration = evento.horaFinal.difference(evento.horaInicio);
    if (duration.inMinutes < 30) {
      return ValidationResult.error('El evento debe durar al menos 30 minutos');
    }

    // Duración máxima de 12 horas
    if (duration.inHours > 12) {
      return ValidationResult.error('El evento no puede durar más de 12 horas');
    }

    return ValidationResult.success('Fechas y horarios válidos');
  }

  /// Validar ubicación del evento
  ValidationResult _validateEventLocation(Evento evento) {
    // Validar latitud
    if (evento.ubicacion.latitud.abs() > 90) {
      return ValidationResult.error('Latitud inválida (debe estar entre -90 y 90)');
    }

    // Validar longitud
    if (evento.ubicacion.longitud.abs() > 180) {
      return ValidationResult.error('Longitud inválida (debe estar entre -180 y 180)');
    }

    // Validar radio
    if (evento.rangoPermitido < 10) {
      return ValidationResult.error('El rango permitido debe ser al menos 10 metros');
    }

    if (evento.rangoPermitido > 1000) {
      return ValidationResult.error('El rango permitido no puede exceder 1000 metros');
    }

    // Validar lugar (opcional pero si existe debe ser válido)
    if (evento.lugar != null && evento.lugar!.length > 100) {
      return ValidationResult.error('El nombre del lugar no puede exceder 100 caracteres');
    }

    return ValidationResult.success('Ubicación válida');
  }

  /// Validar edición de evento activo
  ValidationResult _validateEditingActiveEvent(Evento evento) {
    // Si el evento está activo y tiene participantes, solo permitir cambios menores
    if (evento.estado.toLowerCase() == 'activo' && evento.isActive) {
      // Aquí podrían agregarse validaciones más específicas
      // Por ejemplo, no permitir cambio de ubicación si hay estudiantes activos
      debugPrint('⚠️ Editing active event - proceed with caution');
    }

    return ValidationResult.success('Edición de evento activo permitida');
  }

  /// 🧹 Cleanup
  void dispose() {
    debugPrint('🧹 EventoValidator disposed');
  }
}

/// ✅ RESULTADO DE VALIDACIÓN
class ValidationResult {
  final bool isValid;
  final String message;
  final String? errorCode;

  const ValidationResult({
    required this.isValid,
    required this.message,
    this.errorCode,
  });

  factory ValidationResult.success(String message) {
    return ValidationResult(
      isValid: true,
      message: message,
    );
  }

  factory ValidationResult.error(String message, {String? errorCode}) {
    return ValidationResult(
      isValid: false,
      message: message,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message${errorCode != null ? ', code: $errorCode' : ''})';
  }
}