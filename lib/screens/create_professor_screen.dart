// lib/screens/create_professor_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/auth_service.dart';
import '../core/app_constants.dart';

class CreateProfessorScreen extends StatefulWidget {
  const CreateProfessorScreen({super.key});

  @override
  State<CreateProfessorScreen> createState() => _CreateProfessorScreenState();
}

class _CreateProfessorScreenState extends State<CreateProfessorScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Registrar Docente'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icono y título
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
                child: const Icon(
                  Icons.person_add,
                  color: AppColors.white,
                  size: 50,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'NUEVO DOCENTE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryTeal,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Completa la información del docente',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Campos de texto
              CustomTextField(
                hintText: 'Nombre completo del docente',
                controller: _nombreController,
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              CustomTextField(
                hintText: 'Correo electrónico institucional',
                controller: _correoController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              CustomTextField(
                hintText: 'Contraseña temporal',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                keyboardType: TextInputType.visiblePassword,
              ),

              const SizedBox(height: 20),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryTeal, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.secondaryTeal),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El docente recibirá sus credenciales y podrá cambiar su contraseña en el primer inicio de sesión.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botón de registro
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    )
                  : CustomButton(
                      text: 'Registrar Docente',
                      onPressed: _handleCreateProfessor,
                      isPrimary: false, // Usar color teal
                    ),

              const SizedBox(height: 16),

              // Botón cancelar
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateProfessor() async {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones
    if (nombre.isEmpty || correo.isEmpty || password.isEmpty) {
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

    setState(() => _isLoading = true);

    try {
      final response = await _authService.register(
        nombre,
        correo,
        password,
        AppConstants.docenteRole, // Backend usa 'docente'
      );

      if (response.ok) {
        AppRouter.showSnackBar(
          AppConstants
              .professorCreatedSuccessMessage, // "¡Docente creado exitosamente!"
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppRouter.showSnackBar(
          response.mensaje.isNotEmpty
              ? response.mensaje
              : AppConstants.professorCreationErrorMessage,
          isError: true,
        );
      }
    } catch (e) {
      AppRouter.showSnackBar(
        AppConstants.networkErrorMessage,
        isError: true,
      );
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
    super.dispose();
  }
}
