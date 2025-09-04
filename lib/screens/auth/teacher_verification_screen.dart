// lib/screens/auth/teacher_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';
import '../../services/email_verification_service.dart';

class TeacherVerificationScreen extends StatefulWidget {
  final String teacherEmail;

  const TeacherVerificationScreen({
    super.key,
    required this.teacherEmail,
  });

  @override
  State<TeacherVerificationScreen> createState() => _TeacherVerificationScreenState();
}

class _TeacherVerificationScreenState extends State<TeacherVerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final EmailVerificationService _verificationService = EmailVerificationService();

  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _codeSent = false;
  int _resendCountdown = 0;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Automatically send initial code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationCode();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    if (!mounted) return;
    setState(() => _resendCountdown = 60);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      }
    });
  }

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
        title: const Text(
          'Verificación Docente',
          style: TextStyle(color: AppColors.darkGray, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeaderSection(),
                  const SizedBox(height: 40),
                  if (_codeSent) _buildCodeInputSection(),
                  if (!_codeSent) _buildInitialSection(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  _buildFooterInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryOrange, AppColors.primaryOrange.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.school,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verificación de Cuenta Docente',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
          ),
          child: Text(
            widget.teacherEmail,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mail_outline,
            size: 48,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Enviando código de verificación...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Estamos enviando un código de 6 dígitos a tu correo institucional para verificar que eres un profesor autorizado.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isSendingCode) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.primaryOrange),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user,
            size: 48,
            color: AppColors.successGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'Código de Verificación Enviado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingresa el código de 6 dígitos que enviamos a tu correo institucional:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildCodeInput(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return TextField(
      controller: _codeController,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: '123456',
        hintStyle: TextStyle(color: AppColors.textGray.withValues(alpha: 0.5)),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textGray.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
        color: AppColors.darkGray,
      ),
      onChanged: (value) {
        setState(() {
          _errorMessage = null;
          _successMessage = null;
        });
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_codeSent) ...[
          CustomButton(
            text: _isLoading ? 'Verificando...' : 'Verificar Código',
            onPressed: _isLoading ? null : _verifyCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resendCountdown > 0 || _isSendingCode ? null : _sendVerificationCode,
            child: Text(
              _isSendingCode
                  ? 'Reenviando...'
                  : _resendCountdown > 0
                      ? 'Reenviar en ${_resendCountdown}s'
                      : 'Reenviar código',
              style: TextStyle(
                color: _resendCountdown > 0 || _isSendingCode
                    ? AppColors.textGray
                    : AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          CustomButton(
            text: _isSendingCode ? 'Enviando...' : 'Enviar Código',
            onPressed: _isSendingCode ? null : _sendVerificationCode,
            isLoading: _isSendingCode,
          ),
        ],
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 20),
          SizedBox(height: 8),
          Text(
            'Solo profesors con correo institucional autorizado pueden completar este proceso.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    if (!mounted) return;
    
    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _verificationService.sendTeacherVerificationCode(widget.teacherEmail);

      if (mounted) {
        if (response.success) {
          setState(() {
            _codeSent = true;
            _successMessage = 'Código enviado exitosamente. Revisa tu correo.';
          });
          _startResendCountdown();
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Error al enviar el código';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Ingresa los 6 dígitos del código');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Use the existing email verification method (works for both regular and teacher verification)
      final response = await _verificationService.verifyEmailCode(widget.teacherEmail, code);

      if (mounted) {
        if (response.success) {
          setState(() {
            _successMessage = '¡Cuenta profesor verificada exitosamente!';
          });
          
          // Wait a moment to show success message
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            // Navigate back to login or registration completion
            AppRouter.showSnackBar('Verificación completada. Ya puedes iniciar sesión como profesor.');
            Navigator.of(context).popUntil((route) => route.isFirst);
            AppRouter.goToLogin();
          }
        } else {
          setState(() => _errorMessage = response.error ?? 'Código incorrecto o expirado');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error de conexión. Intenta nuevamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}