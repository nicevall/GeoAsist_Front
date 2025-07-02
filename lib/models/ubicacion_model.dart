// lib/models/ubicacion_model.dart
class Ubicacion {
  final double latitud;
  final double longitud;

  Ubicacion({
    required this.latitud,
    required this.longitud,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}
