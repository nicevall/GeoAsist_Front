// lib/models/auth_response_model.dart
import 'usuario_model.dart';

class AuthResponse {
  final bool ok;
  final String mensaje;
  final String? token;
  final Usuario? usuario;

  AuthResponse({
    required this.ok,
    required this.mensaje,
    this.token,
    this.usuario,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      ok: json['ok'] ?? false,
      mensaje: json['mensaje'] ?? '',
      token: json['token'],
      usuario:
          json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
    );
  }
}
