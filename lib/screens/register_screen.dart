// lib/screens/register_screen.dart - SOLO ESTUDIANTES
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/auth_service.dart';
import '../core/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  // ✅ ROL FIJO - Solo estudiantes pueden registrarse por la app
  final String _fixedRole = AppConstants.estudianteRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo y título
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 25,
                      right: 20,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        width: 40,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Título
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'REGISTRO\nESTUDIANTES\n',
                      style: TextStyle(
                        color: AppColors.secondaryTeal,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'ÚNETE A GEOASISTENCIA',
                      style: TextStyle(
                        color: AppColors.darkGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Campos de texto
              CustomTextField(
                hintText: 'Nombre completo',
                controller: _nombreController,
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              CustomTextField(
                hintText: 'Correo electrónico',
                controller: _correoController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              CustomTextField(
                hintText: 'Contraseña',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                keyboardType: TextInputType.visiblePassword,
              ),

              CustomTextField(
                hintText: 'Confirmar contraseña',
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                keyboardType: TextInputType.visiblePassword,
              ),

              // ✅ INFORMACIÓN DE ROL FIJO (sin selector)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.secondaryTeal, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.school,
                        color: AppColors.secondaryTeal, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎓 Registro de Estudiante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTeal,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Te registrarás como estudiante para seguimiento de asistencia.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ INFORMACIÓN PARA DOCENTES
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryOrange, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primaryOrange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '👨‍🏫 ¿Eres docente? Los docentes son registrados por el administrador del sistema.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de registro
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    )
                  : CustomButton(
                      text: 'Crear Cuenta de Estudiante',
                      onPressed: _handleRegister,
                      isPrimary: false, // Usar color teal para registro
                    ),

              const SizedBox(height: 15),

              // Enlace para volver al login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Información del servidor
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryTeal, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Servidor activo - Registro de estudiantes habilitado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FUNCIÓN DE REGISTRO - SOLO ESTUDIANTES
  Future<void> _handleRegister() async {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones básicas
    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      AppRouter.showSnackBar(
        'Por favor completa todos los campos',
        isError: true,
      );
      return;
    }

    if (nombre.length < 2) {
      AppRouter.showSnackBar(
        'El nombre debe tener al menos 2 caracteres',
        isError: true,
      );
      return;
    }

    if (!_isValidEmail(correo)) {
      AppRouter.showSnackBar(
        'Por favor ingresa un correo válido',
        isError: true,
      );
      return;
    }

    if (password.length < 6) {
      AppRouter.showSnackBar(
        'La contraseña debe tener al menos 6 caracteres',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      AppRouter.showSnackBar(
        'Las contraseñas no coinciden',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ REGISTRO SOLO COMO ESTUDIANTE
      final response = await _authService.register(
        nombre,
        correo,
        password,
        _fixedRole, // Siempre 'estudiante'
      );

      if (response.ok) {
        AppRouter.showSnackBar(
          response.mensaje.isNotEmpty
              ? response.mensaje
              : 'Registro exitoso. Ya puedes iniciar sesión como estudiante.',
        );

        // Regresar al login después del registro exitoso
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppRouter.showSnackBar(
          response.mensaje.isNotEmpty
              ? response.mensaje
              : 'Error al crear la cuenta de estudiante',
          isError: true,
        );
      }
    } catch (e) {
      AppRouter.showSnackBar(
        'Error de conexión. Verifica tu internet.',
        isError: true,
      );

      // Debug en desarrollo
      debugPrint('Error de registro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
