// lib/models/justificacion_model.dart
import 'package:flutter/material.dart';

/// 📄 MODELO COMPLETO DE JUSTIFICACIONES
/// Sistema que permite a estudiantes enviar justificaciones con documentos externos
class Justificacion {
  final String? id;
  final String usuarioId;
  final String eventoId;
  final String? eventTitle;
  final String motivo;
  final String linkDocumento;
  final JustificacionTipo tipo;
  final JustificacionEstado estado;
  final DateTime fechaCreacion;
  final DateTime? fechaRevision;
  final String? comentarioDocente;
  final String? documentoNombre;
  final String? usuarioNombre;
  final Map<String, dynamic>? metadatos;

  const Justificacion({
    this.id,
    required this.usuarioId,
    required this.eventoId,
    this.eventTitle,
    required this.motivo,
    required this.linkDocumento,
    required this.tipo,
    required this.estado,
    required this.fechaCreacion,
    this.fechaRevision,
    this.comentarioDocente,
    this.documentoNombre,
    this.usuarioNombre,
    this.metadatos,
  });

  /// Factory desde JSON (backend response)
  factory Justificacion.fromJson(Map<String, dynamic> json) {
    // El backend almacena justificaciones en el campo 'observaciones' de asistencia
    Map<String, dynamic> observacionesData = {};
    if (json['observaciones'] != null) {
      try {
        observacionesData = json['observaciones'] is String 
            ? Map<String, dynamic>.from(
                Map.from(json['observaciones'] as Map))
            : json['observaciones'] as Map<String, dynamic>;
      } catch (e) {
        observacionesData = {};
      }
    }

    return Justificacion(
      id: json['id']?.toString(),
      usuarioId: json['usuarioId']?.toString() ?? '',
      eventoId: json['eventoId']?.toString() ?? '',
      eventTitle: json['eventTitle']?.toString(),
      motivo: observacionesData['motivo']?.toString() ?? 'Sin motivo especificado',
      linkDocumento: observacionesData['linkDocumento']?.toString() ?? '',
      tipo: JustificacionTipo.fromString(observacionesData['tipoJustificacion']?.toString()),
      estado: JustificacionEstado.fromString(json['estado']?.toString()),
      fechaCreacion: DateTime.tryParse(observacionesData['fechaEnvio']?.toString() ?? '') ?? DateTime.now(),
      fechaRevision: json['fechaRevision'] != null 
          ? DateTime.tryParse(json['fechaRevision'].toString())
          : null,
      comentarioDocente: json['comentarioDocente']?.toString(),
      documentoNombre: observacionesData['documentoNombre']?.toString(),
      usuarioNombre: json['usuarioNombre']?.toString(),
      metadatos: observacionesData['metadatos'] as Map<String, dynamic>?,
    );
  }

  /// Convertir a JSON para envío al backend
  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'eventoId': eventoId,
      'estado': 'justificado',
      'observaciones': {
        'tipo': 'justificacion',
        'tipoJustificacion': tipo.value,
        'linkDocumento': linkDocumento,
        'motivo': motivo,
        'documentoNombre': documentoNombre,
        'fechaEnvio': fechaCreacion.toIso8601String(),
        'metadatos': metadatos,
      },
      'fecha': DateTime.now().toIso8601String().split('T')[0],
      'hora': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
      'latitud': 0.0, // No relevante para justificaciones
      'longitud': 0.0,
    };
  }

  /// Factory para crear nueva justificación
  factory Justificacion.create({
    required String usuarioId,
    required String eventoId,
    required String motivo,
    required String linkDocumento,
    required JustificacionTipo tipo,
    String? documentoNombre,
    Map<String, dynamic>? metadatos,
  }) {
    return Justificacion(
      usuarioId: usuarioId,
      eventoId: eventoId,
      motivo: motivo,
      linkDocumento: linkDocumento,
      tipo: tipo,
      estado: JustificacionEstado.pendiente,
      fechaCreacion: DateTime.now(),
      documentoNombre: documentoNombre,
      metadatos: metadatos,
    );
  }

  /// Copiar con modificaciones
  Justificacion copyWith({
    String? id,
    String? usuarioId,
    String? eventoId,
    String? eventTitle,
    String? motivo,
    String? linkDocumento,
    JustificacionTipo? tipo,
    JustificacionEstado? estado,
    DateTime? fechaCreacion,
    DateTime? fechaRevision,
    String? comentarioDocente,
    String? documentoNombre,
    String? usuarioNombre,
    Map<String, dynamic>? metadatos,
  }) {
    return Justificacion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      eventoId: eventoId ?? this.eventoId,
      eventTitle: eventTitle ?? this.eventTitle,
      motivo: motivo ?? this.motivo,
      linkDocumento: linkDocumento ?? this.linkDocumento,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaRevision: fechaRevision ?? this.fechaRevision,
      comentarioDocente: comentarioDocente ?? this.comentarioDocente,
      documentoNombre: documentoNombre ?? this.documentoNombre,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      metadatos: metadatos ?? this.metadatos,
    );
  }

  /// Validar que la justificación esté completa
  bool get isValid {
    return usuarioId.isNotEmpty &&
           eventoId.isNotEmpty &&
           motivo.trim().isNotEmpty &&
           linkDocumento.trim().isNotEmpty &&
           _isValidUrl(linkDocumento);
  }

  /// Validar que la URL sea válida
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Obtener errores de validación
  List<String> get validationErrors {
    List<String> errors = [];

    if (usuarioId.isEmpty) errors.add('ID de usuario requerido');
    if (eventoId.isEmpty) errors.add('ID de evento requerido');
    if (motivo.trim().isEmpty) errors.add('Motivo es requerido');
    if (linkDocumento.trim().isEmpty) errors.add('Link del documento es requerido');
    if (!_isValidUrl(linkDocumento)) errors.add('URL del documento no es válida');
    if (motivo.length < 10) errors.add('El motivo debe tener al menos 10 caracteres');

    return errors;
  }

  /// Tiempo transcurrido desde la creación
  String get tiempoTranscurrido {
    final diferencia = DateTime.now().difference(fechaCreacion);
    
    if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos momentos';
    }
  }

  @override
  String toString() {
    return 'Justificacion(id: $id, evento: $eventoId, tipo: ${tipo.displayName}, estado: ${estado.displayName})';
  }
}

/// 📋 TIPOS DE JUSTIFICACIONES
enum JustificacionTipo {
  medica('medica', 'Médica', Icons.medical_services, Color(0xFF2196F3)),
  familiar('familiar', 'Familiar', Icons.family_restroom, Color(0xFF4CAF50)),
  laboral('laboral', 'Laboral', Icons.work, Color(0xFFFF9800)),
  academica('academica', 'Académica', Icons.school, Color(0xFF9C27B0)),
  personal('personal', 'Personal', Icons.person, Color(0xFF607D8B)),
  emergencia('emergencia', 'Emergencia', Icons.emergency, Color(0xFFF44336)),
  transporte('transporte', 'Transporte', Icons.directions_bus, Color(0xFF795548)),
  otra('otra', 'Otra', Icons.description, Color(0xFF757575));

  const JustificacionTipo(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  static JustificacionTipo fromString(String? value) {
    return values.firstWhere(
      (tipo) => tipo.value == value,
      orElse: () => JustificacionTipo.otra,
    );
  }

  /// Obtener sugerencias de documentos por tipo
  List<String> get documentosSugeridos {
    switch (this) {
      case JustificacionTipo.medica:
        return [
          'Certificado médico',
          'Incapacidad médica',
          'Orden de reposo',
          'Resultado de exámenes médicos',
        ];
      case JustificacionTipo.familiar:
        return [
          'Certificado de defunción',
          'Acta de nacimiento',
          'Constancia de matrimonio',
          'Certificado de emergencia familiar',
        ];
      case JustificacionTipo.laboral:
        return [
          'Carta del empleador',
          'Horario de trabajo',
          'Permiso laboral',
          'Constancia de trabajo',
        ];
      case JustificacionTipo.academica:
        return [
          'Certificado de participación',
          'Convocatoria académica',
          'Permiso institucional',
          'Constancia de evento académico',
        ];
      case JustificacionTipo.transporte:
        return [
          'Constancia de paro de transporte',
          'Incidencia de tráfico',
          'Problema vehicular',
          'Certificado de transporte público',
        ];
      case JustificacionTipo.emergencia:
        return [
          'Reporte policial',
          'Certificado de emergencia',
          'Constancia de autoridad',
          'Documento de fuerza mayor',
        ];
      default:
        return [
          'Documento de soporte',
          'Carta explicativa',
          'Certificado correspondiente',
        ];
    }
  }
}

/// 📊 ESTADOS DE JUSTIFICACIONES
enum JustificacionEstado {
  pendiente('pendiente', 'Pendiente', Icons.schedule, Color(0xFFFF9800)),
  aprobada('aprobada', 'Aprobada', Icons.check_circle, Color(0xFF4CAF50)),
  rechazada('rechazada', 'Rechazada', Icons.cancel, Color(0xFFF44336)),
  revision('revision', 'En Revisión', Icons.rate_review, Color(0xFF2196F3));

  const JustificacionEstado(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  static JustificacionEstado fromString(String? value) {
    // El backend usa 'justificado' para pendientes
    if (value == 'justificado') return JustificacionEstado.pendiente;
    
    return values.firstWhere(
      (estado) => estado.value == value,
      orElse: () => JustificacionEstado.pendiente,
    );
  }

  /// Indica si la justificación requiere acción
  bool get requiereAccion {
    return this == JustificacionEstado.pendiente || this == JustificacionEstado.revision;
  }

  /// Indica si la justificación está finalizada
  bool get esFinal {
    return this == JustificacionEstado.aprobada || this == JustificacionEstado.rechazada;
  }
}

/// 📈 ESTADÍSTICAS DE JUSTIFICACIONES
class JustificacionStats {
  final int total;
  final int pendientes;
  final int aprobadas;
  final int rechazadas;
  final int enRevision;

  const JustificacionStats({
    required this.total,
    required this.pendientes,
    required this.aprobadas,
    required this.rechazadas,
    required this.enRevision,
  });

  factory JustificacionStats.fromList(List<Justificacion> justificaciones) {
    return JustificacionStats(
      total: justificaciones.length,
      pendientes: justificaciones.where((j) => j.estado == JustificacionEstado.pendiente).length,
      aprobadas: justificaciones.where((j) => j.estado == JustificacionEstado.aprobada).length,
      rechazadas: justificaciones.where((j) => j.estado == JustificacionEstado.rechazada).length,
      enRevision: justificaciones.where((j) => j.estado == JustificacionEstado.revision).length,
    );
  }

  double get porcentajeAprobacion {
    if (total == 0) return 0.0;
    return (aprobadas / total) * 100;
  }

  double get porcentajePendientes {
    if (total == 0) return 0.0;
    return (pendientes / total) * 100;
  }

  Map<String, int> get resumenEstados {
    return {
      'Pendientes': pendientes,
      'Aprobadas': aprobadas,
      'Rechazadas': rechazadas,
      'En Revisión': enRevision,
    };
  }
}