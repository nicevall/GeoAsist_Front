// lib/models/usuario_model.dart
class Usuario {
  final String id;
  final String nombre;
  final String correo; // Backend usa 'correo', no 'email'
  final String rol;
  final DateTime? creadoEn;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.creadoEn,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'estudiante',
      creadoEn:
          json['creadoEn'] != null ? DateTime.parse(json['creadoEn']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }

  bool get isAdmin => rol == 'admin';
  bool get isDocente => rol == 'docente';
  bool get isEstudiante => rol == 'estudiante';
}
