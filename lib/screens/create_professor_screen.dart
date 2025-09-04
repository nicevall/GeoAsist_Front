// lib/screens/create_professor_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/auth_service.dart';
import '../services/email_verification_service.dart'; // 🚨 NUEVO
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
                'Completa la información del profesor',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Campos de texto
              CustomTextField(
                hintText: 'Nombre completo del profesor',
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
                        'El profesor recibirá sus credenciales y podrá cambiar su contraseña en el primer inicio de sesión.',
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
        AppConstants.profesorRole, // Backend usa 'profesor'
      );

      if (response.ok) {
        AppRouter.showSnackBar(
          '✅ Docente registrado. Se enviará código de verificación.',
        );

        // 🚨 BUG CRÍTICO REPARADO: Agregar verificación de correo para profesores
        if (mounted) {
          // Mostrar diálogo de verificación específico para profesores
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _ProfessorVerificationDialog(
              email: correo,
              professorName: nombre,
            ),
          );
          
          // Después de la verificación exitosa, regresar
          if (mounted) {
            Navigator.of(context).pop();
          }
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

/// 🚨 NUEVO: Diálogo especializado para verificación de profesores
class _ProfessorVerificationDialog extends StatefulWidget {
  final String email;
  final String professorName;

  const _ProfessorVerificationDialog({
    required this.email,
    required this.professorName,
  });

  @override
  State<_ProfessorVerificationDialog> createState() => 
      _ProfessorVerificationDialogState();
}

class _ProfessorVerificationDialogState extends State<_ProfessorVerificationDialog> {
  final TextEditingController _codeController = TextEditingController();
  final EmailVerificationService _verificationService = EmailVerificationService();
  
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _codeSent = false;
  String? _errorMessage;
  int _resendCountdown = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_add_alt_1,
              size: 64,
              color: AppColors.secondaryTeal,
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificación de Docente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Profesor: ${widget.professorName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTeal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Correo: ${widget.email}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            if (!_codeSent) ...[
              // Fase 1: Enviar código
              const Text(
                'Haz clic en el botón para enviar el código de verificación al correo del profesor.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSendingCode ? null : _sendVerificationCode,
                  icon: _isSendingCode 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSendingCode ? 'Enviando...' : 'Enviar Código'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Fase 2: Verificar código
              const Text(
                'Código enviado. Ingresa el código de 6 dígitos:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '123456',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.secondaryTeal, width: 2),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                onChanged: (value) {
                  setState(() => _errorMessage = null);
                },
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _resendCountdown > 0 || _isSendingCode
                          ? null
                          : _sendVerificationCode,
                      child: Text(
                        _isSendingCode
                            ? 'Reenviando...'
                            : _resendCountdown > 0
                                ? 'Reenviar en ${_resendCountdown}s'
                                : 'Reenviar',
                        style: TextStyle(
                          color: _resendCountdown > 0 || _isSendingCode
                              ? AppColors.textGray
                              : AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Verificar'),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textGray),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enviar código de verificación al profesor
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
    });

    try {
      // Usar el endpoint específico para enviar código a profesors
      final response = await _verificationService.sendTeacherVerificationCode(widget.email);
      
      if (response.success) {
        setState(() {
          _codeSent = true;
          _isSendingCode = false;
        });
        _startResendCountdown();
        AppRouter.showSnackBar('✅ Código enviado al correo del profesor');
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Error al enviar código';
          _isSendingCode = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión';
        _isSendingCode = false;
      });
    }
  }

  /// Verificar código ingresado
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Ingresa los 6 dígitos del código');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _verificationService.verifyEmailCode(widget.email, code);
      
      if (response.success) {
        AppRouter.showSnackBar('✅ Docente verificado exitosamente');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _errorMessage = response.error ?? 'Código incorrecto');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error de conexión');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Iniciar countdown para reenvío
  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
