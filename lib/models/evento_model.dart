// lib/models/evento_model.dart
import 'package:flutter/foundation.dart';
import 'ubicacion_model.dart';

class Evento {
  final String? id;
  final String titulo;
  final String? tipo;
  final String? lugar;
  final String? descripcion;
  final Ubicacion ubicacion;
  final DateTime fecha; // Backend usa campo separado 'fecha'
  final DateTime horaInicio; // Backend usa 'horaInicio'
  final DateTime horaFinal; // Backend usa 'horaFinal'
  final double rangoPermitido; // 'radio' en el backend
  final String? creadoPor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Evento({
    this.id,
    required this.titulo,
    this.tipo,
    this.lugar,
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
      // ✅ MANEJAR AMBOS NOMBRES: titulo (frontend) y nombre (backend)
      final String titulo = json['titulo']?.toString() ??
          json['nombre']?.toString() ??
          'Evento sin título';

      // ✅ NUEVOS CAMPOS DEL BACKEND
      final String? tipo = json['tipo']?.toString();
      final String? lugar = json['lugar']?.toString();

      // ✅ PARSING SEGURO: Fechas con manejo de errores
      DateTime fecha;
      DateTime horaInicio;
      DateTime horaFinal;

      // Parsing de fecha base
      try {
        if (json['fecha'] != null) {
          fecha = DateTime.parse(json['fecha'].toString());
        } else if (json['fechaInicio'] != null) {
          // Backend usa fechaInicio como fecha base
          fecha = DateTime.parse(json['fechaInicio'].toString());
        } else {
          debugPrint('No se encontró fecha válida, usando fecha actual');
          fecha = DateTime.now();
        }
      } catch (e) {
        debugPrint(
            'Error parsing fecha: ${json['fecha']}, usando fecha actual');
        fecha = DateTime.now();
      }

      // Parsing de horaInicio
      try {
        if (json['horaInicio'] != null) {
          // Si viene como datetime completo
          if (json['horaInicio'].toString().contains('T') ||
              json['horaInicio'].toString().contains(' ')) {
            horaInicio = DateTime.parse(json['horaInicio'].toString());
          } else {
            // Si viene como HH:mm, combinar con fecha
            final timeStr = json['horaInicio'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              horaInicio =
                  DateTime(fecha.year, fecha.month, fecha.day, hour, minute);
            } else {
              throw FormatException('Formato de hora inválido');
            }
          }
        } else {
          debugPrint('horaInicio no encontrado, usando hora actual');
          horaInicio = DateTime.now();
        }
      } catch (e) {
        debugPrint(
            'Error parsing horaInicio: ${json['horaInicio']}, usando hora actual');
        horaInicio = DateTime.now();
      }

      // Parsing de horaFinal
      try {
        if (json['horaFinal'] != null || json['horaFin'] != null) {
          final horaFinalJson = json['horaFinal'] ?? json['horaFin'];

          // Si viene como datetime completo
          if (horaFinalJson.toString().contains('T') ||
              horaFinalJson.toString().contains(' ')) {
            horaFinal = DateTime.parse(horaFinalJson.toString());
          } else {
            // Si viene como HH:mm, combinar con fecha
            final timeStr = horaFinalJson.toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              horaFinal =
                  DateTime(fecha.year, fecha.month, fecha.day, hour, minute);
            } else {
              throw FormatException('Formato de hora inválido');
            }
          }
        } else {
          debugPrint('horaFinal no encontrado, usando hora actual + 1h');
          horaFinal = horaInicio.add(const Duration(hours: 1));
        }
      } catch (e) {
        debugPrint(
            'Error parsing horaFinal: ${json['horaFinal'] ?? json['horaFin']}, usando hora actual + 1h');
        horaFinal = horaInicio.add(const Duration(hours: 1));
      }

      // ✅ UBICACIÓN SEGURA: Manejar ubicacion (frontend) y coordenadas (backend)
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
      } else if (json['coordenadas'] != null &&
          json['coordenadas'] is Map<String, dynamic>) {
        // Backend usa 'coordenadas'
        try {
          ubicacion = Ubicacion.fromJson({
            'latitud': json['coordenadas']['latitud'],
            'longitud': json['coordenadas']['longitud'],
          });
        } catch (e) {
          debugPrint(
              'Error parsing coordenadas: ${json['coordenadas']}, usando ubicación por defecto');
          ubicacion = Ubicacion(latitud: -0.1805, longitud: -78.4680);
        }
      } else {
        ubicacion =
            Ubicacion(latitud: -0.1805, longitud: -78.4680); // UIDE por defecto
      }

      // ✅ RANGO PERMITIDO: Manejar rangoPermitido (frontend) y radio (backend)
      double rangoPermitido = _parseDouble(json['rangoPermitido'], 100.0);
      if (rangoPermitido == 100.0 && json['coordenadas']?['radio'] != null) {
        rangoPermitido = _parseDouble(json['coordenadas']['radio'], 100.0);
      }

      return Evento(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        titulo: titulo,
        tipo: tipo, // ✅ NUEVO CAMPO
        lugar: lugar, // ✅ NUEVO CAMPO
        descripcion: json['descripcion']?.toString(),
        ubicacion: ubicacion,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFinal: horaFinal,
        rangoPermitido: rangoPermitido,
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
