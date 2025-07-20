// lib/models/evento_model.dart
import 'package:flutter/foundation.dart';
import 'ubicacion_model.dart';

class Evento {
  final String? id;
  final String titulo;
  final String? descripcion;
  final Ubicacion ubicacion;
  final DateTime fecha; // Backend usa campo separado 'fecha'
  final DateTime horaInicio; // Backend usa 'horaInicio'
  final DateTime horaFinal; // Backend usa 'horaFinal'
  final double rangoPermitido;
  final String? creadoPor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Evento({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.ubicacion,
    required this.fecha,
    required this.horaInicio,
    required this.horaFinal,
    this.rangoPermitido = 100.0,
    this.creadoPor,
    this.createdAt,
    this.updatedAt,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ VALIDACIÓN: Campos requeridos con valores por defecto seguros
      final String titulo = json['titulo']?.toString() ?? 'Evento sin título';

      // ✅ PARSING SEGURO: Fechas con manejo de errores
      DateTime fecha;
      DateTime horaInicio;
      DateTime horaFinal;

      try {
        fecha = DateTime.parse(json['fecha'].toString());
      } catch (e) {
        debugPrint(
            'Error parsing fecha: ${json['fecha']}, usando fecha actual');
        fecha = DateTime.now();
      }

      try {
        horaInicio = DateTime.parse(json['horaInicio'].toString());
      } catch (e) {
        debugPrint(
            'Error parsing horaInicio: ${json['horaInicio']}, usando hora actual');
        horaInicio = DateTime.now();
      }

      try {
        horaFinal = DateTime.parse(json['horaFinal'].toString());
      } catch (e) {
        debugPrint(
            'Error parsing horaFinal: ${json['horaFinal']}, usando hora actual + 1h');
        horaFinal = DateTime.now().add(const Duration(hours: 1));
      }

      // ✅ UBICACIÓN SEGURA: Con valores por defecto
      Ubicacion ubicacion;
      if (json['ubicacion'] != null &&
          json['ubicacion'] is Map<String, dynamic>) {
        try {
          ubicacion = Ubicacion.fromJson(json['ubicacion']);
        } catch (e) {
          debugPrint(
              'Error parsing ubicacion: ${json['ubicacion']}, usando ubicación por defecto');
          ubicacion = Ubicacion(
              latitud: -0.1805, longitud: -78.4680); // UIDE por defecto
        }
      } else {
        ubicacion =
            Ubicacion(latitud: -0.1805, longitud: -78.4680); // UIDE por defecto
      }

      return Evento(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        titulo: titulo,
        descripcion: json['descripcion']?.toString(),
        ubicacion: ubicacion,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFinal: horaFinal,
        rangoPermitido: _parseDouble(json['rangoPermitido'], 100.0),
        creadoPor: json['creadoPor']?.toString(),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      debugPrint('Error general en Evento.fromJson: $e');
      debugPrint('JSON problemático: $json');
      rethrow; // Re-lanzar para que el servicio pueda manejarlo
    }
  }

  /// ✅ HELPER: Parsing seguro de double
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('Error parsing double: $value, usando $defaultValue');
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// ✅ HELPER: Parsing seguro de DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('Error parsing DateTime: $value');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion': ubicacion.toJson(),
      'fecha': fecha.toIso8601String(),
      'horaInicio': horaInicio.toIso8601String(),
      'horaFinal': horaFinal.toIso8601String(),
      'rangoPermitido': rangoPermitido,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(horaInicio) && now.isBefore(horaFinal);
  }

  bool get hasStarted => DateTime.now().isAfter(horaInicio);
  bool get hasEnded => DateTime.now().isAfter(horaFinal);
}
