// lib/models/evento_model.dart
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
    return Evento(
      id: json['_id'] ?? json['id'],
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      ubicacion: Ubicacion.fromJson(json['ubicacion'] ?? {}),
      fecha: DateTime.parse(json['fecha']),
      horaInicio: DateTime.parse(json['horaInicio']),
      horaFinal: DateTime.parse(json['horaFinal']),
      rangoPermitido: (json['rangoPermitido'] ?? 100.0).toDouble(),
      creadoPor: json['creadoPor'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
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
