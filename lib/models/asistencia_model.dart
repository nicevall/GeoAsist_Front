// lib/models/asistencia_model.dart
import 'package:flutter/foundation.dart';

class Asistencia {
  final String? id;
  final String usuarioId; // ✅ AGREGADO campo usuarioId
  final String eventoId; // ✅ AGREGADO campo eventoId
  final String usuario;
  final String evento;
  final String estado;
  final double latitud;
  final double longitud;
  final DateTime hora;
  final DateTime fecha; // ✅ AGREGADO campo fecha
  final bool dentroDelRango;
  final String? observaciones; // ✅ AGREGADO campo observaciones
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final DateTime? fechaRegistro; // ✅ AGREGADO fechaRegistro
  final String? nombreUsuario; // ✅ AGREGADO nombreUsuario

  Asistencia({
    this.id,
    required this.usuarioId, // ✅ REQUERIDO
    required this.eventoId, // ✅ REQUERIDO
    required this.usuario,
    required this.evento,
    required this.estado,
    required this.latitud,
    required this.longitud,
    required this.hora,
    required this.fecha, // ✅ REQUERIDO
    this.dentroDelRango = true,
    this.observaciones, // ✅ OPCIONAL
    this.creadoEn,
    this.actualizadoEn,
    this.fechaRegistro, // ✅ OPCIONAL
    this.nombreUsuario, // ✅ OPCIONAL
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ MANEJAR CAMPOS DEL BACKEND
      final String usuarioId =
          json['usuarioId']?.toString() ??
          json['estudiante']?.toString() ??
          json['userId']?.toString() ??
          '';

      final String eventoId =
          json['eventoId']?.toString() ??
          json['evento']?.toString() ??
          json['eventId']?.toString() ??
          '';

      final String usuario =
          json['usuario']?.toString() ??
          json['estudiante']?.toString() ??
          usuarioId;

      final String evento =
          json['evento']?.toString() ??
          json['eventoTitulo']?.toString() ??
          eventoId;

      final String estado = json['estado']?.toString() ?? 'presente';

      // ✅ COORDENADAS DEL BACKEND
      double latitud = 0.0, longitud = 0.0;
      if (json['coordenadas'] != null) {
        final coordenadas = json['coordenadas'] as Map<String, dynamic>;
        latitud = (coordenadas['latitud'] as num?)?.toDouble() ?? 0.0;
        longitud = (coordenadas['longitud'] as num?)?.toDouble() ?? 0.0;
      } else {
        latitud = (json['latitud'] as num?)?.toDouble() ?? 0.0;
        longitud = (json['longitud'] as num?)?.toDouble() ?? 0.0;
      }

      // ✅ FECHAS Y HORAS DEL BACKEND
      DateTime hora = DateTime.now();
      if (json['hora'] != null) {
        hora = DateTime.parse(json['hora'].toString());
      } else if (json['creadoEn'] != null) {
        hora = DateTime.parse(json['creadoEn'].toString());
      }

      DateTime fecha = DateTime.now();
      if (json['fecha'] != null) {
        if (json['fecha'] is String) {
          fecha = DateTime.parse(json['fecha'].toString());
        } else if (json['fecha'] is DateTime) {
          fecha = json['fecha'] as DateTime;
        }
      } else {
        // ✅ EXTRAER FECHA DE LA HORA
        fecha = DateTime(hora.year, hora.month, hora.day);
      }

      final bool dentroDelRango =
          json['dentroDelRango'] == true ||
          json['enRango'] == true ||
          json['withinRange'] == true;

      final String? observaciones = json['observaciones']?.toString();
      final String? nombreUsuario = json['nombreUsuario']?.toString() ?? 
                                     json['usuarioNombre']?.toString() ??
                                     json['studentName']?.toString();
      final DateTime? fechaRegistro = json['fechaRegistro'] != null
          ? DateTime.parse(json['fechaRegistro'].toString())
          : (json['creadoEn'] != null ? DateTime.parse(json['creadoEn'].toString()) : null);

      return Asistencia(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        usuarioId: usuarioId,
        eventoId: eventoId,
        usuario: usuario,
        evento: evento,
        estado: estado,
        latitud: latitud,
        longitud: longitud,
        hora: hora,
        fecha: fecha,
        dentroDelRango: dentroDelRango,
        observaciones: observaciones,
        creadoEn: json['creadoEn'] != null
            ? DateTime.parse(json['creadoEn'].toString())
            : null,
        actualizadoEn: json['actualizadoEn'] != null
            ? DateTime.parse(json['actualizadoEn'].toString())
            : null,
        fechaRegistro: fechaRegistro,
        nombreUsuario: nombreUsuario,
      );
    } catch (e) {
      debugPrint('❌ Error parsing Asistencia from JSON: $e');
      debugPrint('❌ JSON data: $json');
      throw Exception('Error parsing Asistencia: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'eventoId': eventoId,
      'usuario': usuario,
      'evento': evento,
      'estudiante': usuarioId, // ✅ PARA BACKEND
      'estado': estado,
      'coordenadas': {'latitud': latitud, 'longitud': longitud},
      'latitud': latitud, // ✅ COMPATIBILIDAD
      'longitud': longitud, // ✅ COMPATIBILIDAD
      'hora': hora.toIso8601String(),
      'fecha': fecha.toIso8601String().split('T')[0],
      'dentroDelRango': dentroDelRango,
      'enRango': dentroDelRango, // ✅ PARA BACKEND
      'observaciones': observaciones,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'nombreUsuario': nombreUsuario,
    };
  }

  Asistencia copyWith({
    String? id,
    String? usuarioId,
    String? eventoId,
    String? usuario,
    String? evento,
    String? estado,
    double? latitud,
    double? longitud,
    DateTime? hora,
    DateTime? fecha,
    bool? dentroDelRango,
    String? observaciones,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    DateTime? fechaRegistro,
    String? nombreUsuario,
  }) {
    return Asistencia(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      eventoId: eventoId ?? this.eventoId,
      usuario: usuario ?? this.usuario,
      evento: evento ?? this.evento,
      estado: estado ?? this.estado,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      hora: hora ?? this.hora,
      fecha: fecha ?? this.fecha,
      dentroDelRango: dentroDelRango ?? this.dentroDelRango,
      observaciones: observaciones ?? this.observaciones,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    );
  }

  @override
  String toString() {
    return 'Asistencia(id: $id, usuario: $usuario, evento: $evento, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Asistencia && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
