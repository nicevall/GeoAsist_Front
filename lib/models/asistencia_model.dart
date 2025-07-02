// lib/models/asistencia_model.dart

import 'ubicacion_model.dart';

class Asistencia {
  final String? id;
  final String estudiante;
  final String evento;
  final DateTime? hora;
  final Ubicacion coordenadas;
  final bool dentroDelRango;
  final String estado; // Backend usa 'estado' en minúscula
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Asistencia({
    this.id,
    required this.estudiante,
    required this.evento,
    this.hora,
    required this.coordenadas,
    required this.dentroDelRango,
    required this.estado,
    this.createdAt,
    this.updatedAt,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['_id'] ?? json['id'],
      estudiante: json['estudiante'] ?? '',
      evento: json['evento'] ?? '',
      hora: json['hora'] != null ? DateTime.parse(json['hora']) : null,
      coordenadas: Ubicacion.fromJson(json['coordenadas'] ?? {}),
      dentroDelRango: json['dentroDelRango'] ?? false,
      estado: json['estado'] ?? 'Ausente',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estudiante': estudiante,
      'evento': evento,
      'coordenadas': coordenadas.toJson(),
      'dentroDelRango': dentroDelRango,
      'estado': estado,
    };
  }

  bool get isPresente => estado.toLowerCase() == 'presente';
  bool get isAusente => estado.toLowerCase() == 'ausente';
  bool get isPendiente => estado.toLowerCase() == 'pendiente';
}
