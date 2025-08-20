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
  final String estado; // ✅ AGREGADO campo estado
  final bool isActive; // ✅ AGREGADO campo isActive
  final double? latitud; // ✅ AGREGADO getter latitud
  final double? longitud; // ✅ AGREGADO getter longitud
  final int duracionMinutos; // ✅ AGREGADO duración en minutos

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
    this.estado = 'programado', // ✅ VALOR DEFAULT
    this.isActive = false, // ✅ VALOR DEFAULT
    int? duracionMinutos,
  }) : latitud = ubicacion.latitud, // ✅ GETTER CALCULADO
       longitud = ubicacion.longitud, // ✅ GETTER CALCULADO
       duracionMinutos = duracionMinutos ?? _calculateDuration(horaInicio, horaFinal); // ✅ CALCULAR DURACIÓN

  // ✅ MÉTODO PARA CALCULAR DURACIÓN
  static int _calculateDuration(DateTime inicio, DateTime fin) {
    return fin.difference(inicio).inMinutes;
  }

  factory Evento.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ MANEJAR AMBOS NOMBRES: titulo (frontend) y nombre (backend)
      final String titulo =
          json['titulo']?.toString() ??
          json['nombre']?.toString() ??
          'Evento sin título';

      // ✅ NUEVOS CAMPOS DEL BACKEND
      final String? tipo = json['tipo']?.toString();
      final String? lugar = json['lugar']?.toString();
      final String? descripcion = json['descripcion']?.toString();
      final String? creadoPor =
          json['creadoPor']?.toString() ??
          json['docente']?.toString() ??
          json['creadorId']?.toString();

      // ✅ ESTADO E ISACTIVE DEL BACKEND
      final String estado = json['estado']?.toString() ?? 'programado';
      final bool isActive =
          json['isActive'] == true ||
          json['activo'] == true ||
          estado == 'activo';

      // ✅ COORDENADAS DEL BACKEND
      Map<String, dynamic>? coordenadas;
      double lat = 0.0, lng = 0.0, radio = 100.0;

      if (json['coordenadas'] != null) {
        coordenadas = json['coordenadas'] as Map<String, dynamic>;
        lat = (coordenadas['latitud'] as num?)?.toDouble() ?? 0.0;
        lng = (coordenadas['longitud'] as num?)?.toDouble() ?? 0.0;
        radio = (coordenadas['radio'] as num?)?.toDouble() ?? 100.0;
      } else {
        // ✅ FALLBACK SI VIENEN DIRECTAMENTE EN EL JSON
        lat = (json['latitud'] as num?)?.toDouble() ?? 0.0;
        lng = (json['longitud'] as num?)?.toDouble() ?? 0.0;
        radio =
            (json['radio'] as num?)?.toDouble() ??
            (json['rangoPermitido'] as num?)?.toDouble() ??
            100.0;
      }

      // ✅ FECHAS Y HORAS DEL BACKEND
      DateTime fecha = DateTime.now();
      if (json['fechaInicio'] != null) {
        fecha = DateTime.parse(json['fechaInicio'].toString());
      } else if (json['fecha'] != null) {
        fecha = DateTime.parse(json['fecha'].toString());
      }

      DateTime horaInicio = DateTime.now();
      DateTime horaFinal = DateTime.now().add(const Duration(hours: 2));

      if (json['horaInicio'] != null) {
        final timeStr = json['horaInicio'].toString();
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          horaInicio = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      }

      if (json['horaFin'] != null || json['horaFinal'] != null) {
        final timeStr = (json['horaFin'] ?? json['horaFinal']).toString();
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          horaFinal = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      }

      return Evento(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        titulo: titulo,
        tipo: tipo,
        lugar: lugar,
        descripcion: descripcion,
        ubicacion: Ubicacion(latitud: lat, longitud: lng),
        fecha: fecha,
        horaInicio: horaInicio,
        horaFinal: horaFinal,
        rangoPermitido: radio,
        creadoPor: creadoPor,
        createdAt: json['creadoEn'] != null
            ? DateTime.parse(json['creadoEn'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'].toString())
            : null,
        estado: estado,
        isActive: isActive,
        duracionMinutos: json['duracionMinutos'] as int?,
      );
    } catch (e) {
      debugPrint('❌ Error parsing Evento from JSON: $e');
      debugPrint('❌ JSON data: $json');
      throw Exception('Error parsing Evento: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'nombre': titulo, // ✅ ENVIAR AMBOS NOMBRES
      'tipo': tipo,
      'lugar': lugar,
      'descripcion': descripcion,
      'coordenadas': {
        'latitud': ubicacion.latitud,
        'longitud': ubicacion.longitud,
        'radio': rangoPermitido,
      },
      'fecha': fecha.toIso8601String().split('T')[0],
      'fechaInicio': fecha.toIso8601String().split('T')[0],
      'horaInicio':
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
      'horaFin':
          '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}',
      'horaFinal':
          '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}',
      'creadoPor': creadoPor,
      'docente': creadoPor,
      'estado': estado,
      'isActive': isActive,
      'activo': isActive,
      'duracionMinutos': duracionMinutos,
    };
  }

  // ✅ MÉTODO PARA ACTUALIZAR isActive
  Evento copyWith({
    String? id,
    String? titulo,
    String? tipo,
    String? lugar,
    String? descripcion,
    Ubicacion? ubicacion,
    DateTime? fecha,
    DateTime? horaInicio,
    DateTime? horaFinal,
    double? rangoPermitido,
    String? creadoPor,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? estado,
    bool? isActive,
    int? duracionMinutos,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      lugar: lugar ?? this.lugar,
      descripcion: descripcion ?? this.descripcion,
      ubicacion: ubicacion ?? this.ubicacion,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFinal: horaFinal ?? this.horaFinal,
      rangoPermitido: rangoPermitido ?? this.rangoPermitido,
      creadoPor: creadoPor ?? this.creadoPor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estado: estado ?? this.estado,
      isActive: isActive ?? this.isActive,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    );
  }

  // ✅ GETTERS PARA FECHAS FORMATEADAS
  String get fechaInicioFormatted {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get horaInicioFormatted {
    return '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
  }

  String get horaFinalFormatted {
    return '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}';
  }

  // ✅ GETTER PARA COMPATIBILIDAD
  DateTime get fechaInicio => fecha;

  @override
  String toString() {
    return 'Evento(id: $id, titulo: $titulo, tipo: $tipo, estado: $estado, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evento && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
