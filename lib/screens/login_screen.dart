import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                hintText: 'Username',
                controller: _usernameController,
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.text,
              ),

              CustomTextField(
                hintText: 'Password',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                keyboardType: TextInputType.visiblePassword,
              ),

              const SizedBox(height: 30),

              // Botones
              CustomButton(
                text: 'Login',
                onPressed: () {
                  // Simular autenticación - En producción conectar con tu backend
                  final username = _usernameController.text.trim();

                  if (username.isEmpty) {
                    AppRouter.showSnackBar(
                      'Por favor ingresa tu usuario',
                      isError: true,
                    );
                    return;
                  }

                  // Determinar si es admin o asistente basado en el username
                  final isAdmin = username.toLowerCase().contains('admin');

                  // Navegar a la pantalla del mapa
                  AppRouter.goToMapView(
                    isAdminMode: isAdmin,
                    userName: username,
                  );
                },
              ),

              CustomButton(
                text: 'Register',
                onPressed: () {
                  // TODO: Navigate to registration screen
                  AppRouter.showSnackBar(
                    'Función de registro próximamente disponible',
                  );
                },
                isPrimary: false,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
