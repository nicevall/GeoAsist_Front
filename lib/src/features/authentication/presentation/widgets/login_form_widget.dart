import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// **LoginFormWidget**: Reusable form component for user authentication input
/// 
/// **Purpose**: Provides email and password input fields with validation
/// **AI Context**: Stateless widget focusing on input collection and validation
/// **Dependencies**: Material Design components only
/// **Used by**: LoginPage, potentially other authentication screens
/// **Performance**: Lightweight form widget with optimized input handling
class LoginFormWidget extends StatelessWidget {
  /// **Property**: Controller for email text input field
  /// **AI Context**: Manages email field state and provides access to input value
  final TextEditingController emailController;
  
  /// **Property**: Controller for password text input field
  /// **AI Context**: Manages password field state and provides access to input value
  final TextEditingController passwordController;
  
  /// **Property**: Focus node for email input field
  /// **AI Context**: Controls keyboard focus and enables field traversal
  final FocusNode emailFocusNode;
  
  /// **Property**: Focus node for password input field
  /// **AI Context**: Controls keyboard focus and enables field traversal
  final FocusNode passwordFocusNode;
  
  /// **Property**: Controls password field visibility state
  /// **AI Context**: Toggles between hidden and visible password text
  final bool isPasswordVisible;
  
  /// **Property**: Callback for password visibility toggle
  /// **AI Context**: Triggered when user taps password visibility icon
  final VoidCallback onPasswordVisibilityToggle;
  
  /// **Property**: Callback for form submission
  /// **AI Context**: Triggered when form is submitted via button or keyboard
  final VoidCallback onFormSubmit;
  
  /// **Property**: Controls whether form inputs are enabled
  /// **AI Context**: Disables form during authentication process
  final bool isFormEnabled;

  const LoginFormWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isPasswordVisible,
    required this.onPasswordVisibilityToggle,
    required this.onFormSubmit,
    this.isFormEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI Context: Email input field with validation
        _buildEmailInputField(context),
        
        const SizedBox(height: 16),
        
        // AI Context: Password input field with visibility toggle
        _buildPasswordInputField(context),
      ],
    );
  }

  /// **Method**: Build email input field with validation
  /// **AI Context**: Creates email text field with comprehensive validation rules
  /// **Returns**: Widget containing styled email input with validation
  Widget _buildEmailInputField(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: emailController,
      focusNode: emailFocusNode,
      enabled: isFormEnabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: true,
      
      // AI Context: Email field decoration with clear visual hierarchy
      decoration: InputDecoration(
        labelText: 'Correo Electrónico',
        hintText: 'ejemplo@universidad.edu',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        
        // AI Context: Modern outlined border design
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        
        // AI Context: Consistent padding and background
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      
      // AI Context: Email format validation with user-friendly messages
      validator: (emailInput) => _validateEmailInput(emailInput),
      
      // AI Context: Auto-advance to password field on completion
      onFieldSubmitted: (_) {
        passwordFocusNode.requestFocus();
      },
      
      // AI Context: Input formatters for email normalization
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces in email
        LengthLimitingTextInputFormatter(100), // Reasonable email length limit
      ],
    );
  }

  /// **Method**: Build password input field with visibility toggle
  /// **AI Context**: Creates password field with show/hide functionality
  /// **Returns**: Widget containing styled password input with visibility control
  Widget _buildPasswordInputField(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: passwordController,
      focusNode: passwordFocusNode,
      enabled: isFormEnabled,
      obscureText: !isPasswordVisible,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      
      // AI Context: Password field decoration with visibility toggle
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        prefixIcon: Icon(
          Icons.lock_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        
        // AI Context: Password visibility toggle button
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: onPasswordVisibilityToggle,
          tooltip: isPasswordVisible ? 'Ocultar contraseña' : 'Mostrar contraseña',
        ),
        
        // AI Context: Consistent border styling with email field
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        
        // AI Context: Consistent styling with email field
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      
      // AI Context: Password validation with security requirements
      validator: (passwordInput) => _validatePasswordInput(passwordInput),
      
      // AI Context: Submit form when user presses done on keyboard
      onFieldSubmitted: (_) => onFormSubmit(),
      
      // AI Context: Input formatters for password security
      inputFormatters: [
        LengthLimitingTextInputFormatter(128), // Maximum password length
      ],
    );
  }

  /// **Method**: Validate email input with comprehensive rules
  /// **AI Context**: Email validation with user-friendly error messages in Spanish
  /// **Input**: emailInput (String?) - email text to validate
  /// **Returns**: String? - null if valid, error message if invalid
  String? _validateEmailInput(String? emailInput) {
    // AI Context: Check for empty input
    if (emailInput == null || emailInput.trim().isEmpty) {
      return 'El correo electrónico es obligatorio';
    }

    final trimmedEmail = emailInput.trim();

    // AI Context: Check minimum length for reasonable email
    if (trimmedEmail.length < 5) {
      return 'El correo debe tener al menos 5 caracteres';
    }

    // AI Context: Check maximum length for practical use
    if (trimmedEmail.length > 100) {
      return 'El correo es demasiado largo (máximo 100 caracteres)';
    }

    // AI Context: Comprehensive email regex validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      return 'Ingresa un correo electrónico válido';
    }

    // AI Context: Additional validation for educational email domains
    if (!trimmedEmail.contains('@')) {
      return 'El correo debe contener el símbolo @';
    }

    final emailParts = trimmedEmail.split('@');
    if (emailParts.length != 2) {
      return 'Formato de correo inválido';
    }

    final domain = emailParts[1];
    if (domain.isEmpty || !domain.contains('.')) {
      return 'Dominio de correo inválido';
    }

    return null; // AI Context: Email is valid
  }

  /// **Method**: Validate password input with security requirements
  /// **AI Context**: Password validation balancing security and usability
  /// **Input**: passwordInput (String?) - password text to validate
  /// **Returns**: String? - null if valid, error message if invalid
  String? _validatePasswordInput(String? passwordInput) {
    // AI Context: Check for empty input
    if (passwordInput == null || passwordInput.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    // AI Context: Minimum password length for security
    if (passwordInput.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    // AI Context: Maximum password length for practical use
    if (passwordInput.length > 128) {
      return 'La contraseña es demasiado larga (máximo 128 caracteres)';
    }

    // AI Context: Check for whitespace-only passwords
    if (passwordInput.trim().isEmpty) {
      return 'La contraseña no puede estar vacía';
    }

    return null; // AI Context: Password meets basic requirements
  }
}

/// **AuthenticationLoadingWidget**: Loading indicator for authentication processes
/// **AI Context**: Dedicated loading widget with authentication-specific messaging
class AuthenticationLoadingWidget extends StatelessWidget {
  const AuthenticationLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Context: Loading indicator with app colors
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 24),
            
            // AI Context: Loading message for user feedback
            Text(
              'Iniciando sesión...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // AI Context: Secondary loading message
            Text(
              'Por favor espera un momento',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}