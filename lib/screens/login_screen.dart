import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/auth_service.dart';
import '../core/app_constants.dart';
// import 'auth/teacher_verification_screen.dart'; // TEMPORALMENTE DESHABILITADO

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48, // Compensar padding
                ),
                child: Column(
                  children: [
              const SizedBox(height: 60),

              // Logo y título
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 30,
                      right: 25,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      left: 25,
                      child: Container(
                        width: 45,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryTeal,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
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
                      text: 'WELCO\nME\n',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'GEO ASISTENCIA',
                      style: TextStyle(
                        color: AppColors.darkGray,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Campos de texto
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

              const SizedBox(height: 30),

              // Botones
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    )
                  : CustomButton(
                      text: 'Iniciar Sesión',
                      onPressed: _handleLogin,
                    ),

              CustomButton(
                text: 'Registrarse',
                onPressed: () {
                  // Navegar a la pantalla de registro
                  AppRouter.goToRegister();
                },
                isPrimary: false,
              ),

              // ⚠️ TEACHER VERIFICATION TEMPORALMENTE DESHABILITADO
              // TODO: Rehabilitar cuando tengamos más tiempo para testing completo
              /*
              const SizedBox(height: 16),
              
              // ✅ PHASE 3: Teacher Verification Access
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.school, color: AppColors.primaryOrange, size: 20),
                    const SizedBox(height: 8),
                    const Text(
                      '¿Eres profesor?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showTeacherEmailDialog(),
                      child: const Text(
                        'Verifica tu cuenta profesor aquí',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              */

              const SizedBox(height: 20),

              // Indicador de estado del servidor
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
                    Flexible(
                      child: Text(
                        'Conectado al servidor: ${AppConstants.baseUrl}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones básicas
    if (correo.isEmpty || password.isEmpty) {
      AppRouter.showSnackBar(
        'Por favor completa todos los campos',
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Llamada real al backend
      final response = await _authService.login(correo, password);

      if (response.ok && response.usuario != null) {
        AppRouter.showSnackBar(
          response.mensaje.isNotEmpty
              ? response.mensaje
              : AppConstants.loginSuccessMessage,
        );

        // Determinar la ruta según el rol del usuario
        final usuario = response.usuario!;
        _navigateByRole(usuario.rol, usuario.nombre);
      } else {
        AppRouter.showSnackBar(
          response.mensaje.isNotEmpty
              ? response.mensaje
              : AppConstants.invalidCredentialsMessage,
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateByRole(String rol, String userName) {
    AppRouter.goToDashboard(userName: userName);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // ⚠️ TEMPORALMENTE DESHABILITADO - Teacher Email Input Dialog
  /*
  void _showTeacherEmailDialog() {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.school, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Verificación Docente',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa tu correo institucional para verificar tu cuenta profesor:',
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo institucional',
                  hintText: 'profesor@universidad.edu',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solo correos institucionales autorizados pueden completar este proceso.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  AppRouter.showSnackBar('Ingresa tu correo institucional', isError: true);
                  return;
                }
                if (!_isValidEmail(email)) {
                  AppRouter.showSnackBar('Ingresa un correo válido', isError: true);
                  return;
                }
                
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeacherVerificationScreen(teacherEmail: email),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }
  */

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
