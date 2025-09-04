import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/authentication_controller.dart';
import '../widgets/login_form_widget.dart';
import '../widgets/authentication_loading_widget.dart' as auth_loading;

/// **LoginPage**: Main authentication screen for user login
/// 
/// **Purpose**: Provides user interface for email/password authentication
/// **AI Context**: Stateful page managing login form and authentication state
/// **Dependencies**: AuthenticationController via Provider
/// **Used by**: App routing system when user needs authentication
/// **Performance**: Lightweight page with reactive state management
class LoginPage extends StatefulWidget {
  /// **Property**: Route name for navigation system
  /// **AI Context**: Used by router for type-safe navigation
  static const String routeName = '/authentication/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// **Property**: Global key for form validation
  /// **AI Context**: Enables form validation and state management
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  /// **Property**: Email input controller for form management
  /// **AI Context**: Manages email text field state and validation
  final TextEditingController _emailTextController = TextEditingController();

  /// **Property**: Password input controller for form management
  /// **AI Context**: Manages password text field state and validation
  final TextEditingController _passwordTextController = TextEditingController();

  /// **Property**: Focus node for email input field
  /// **AI Context**: Controls keyboard focus and field traversal
  final FocusNode _emailFocusNode = FocusNode();

  /// **Property**: Focus node for password input field
  /// **AI Context**: Controls keyboard focus and field traversal
  final FocusNode _passwordFocusNode = FocusNode();

  /// **Property**: Controls password field visibility
  /// **AI Context**: Toggle between hidden and visible password text
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // AI Context: Set up authentication state listener for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthenticationStateListener();
    });
  }

  @override
  void dispose() {
    // AI Context: Clean up controllers and focus nodes to prevent memory leaks
    _emailTextController.dispose();
    _passwordTextController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AI Context: Remove app bar for full-screen login experience
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Consumer<AuthenticationController>(
          builder: (context, authController, child) {
            // AI Context: Show loading overlay during authentication
            if (authController.isAuthenticationInProgress) {
              return const auth_loading.AuthenticationLoadingWidget();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI Context: Top spacing for visual balance
                  const SizedBox(height: 60),

                  // AI Context: App branding and welcome section
                  _buildWelcomeSection(context),

                  const SizedBox(height: 40),

                  // AI Context: Login form with validation
                  _buildLoginForm(context, authController),

                  const SizedBox(height: 24),

                  // AI Context: Error message display
                  if (authController.currentState.hasError)
                    _buildErrorMessageWidget(context, authController),

                  const SizedBox(height: 32),

                  // AI Context: Login action button
                  _buildLoginButton(context, authController),

                  const SizedBox(height: 16),

                  // AI Context: Forgot password link
                  _buildForgotPasswordButton(context),

                  const SizedBox(height: 32),

                  // AI Context: Register account navigation
                  _buildRegisterNavigationButton(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// **Method**: Build welcome section with app branding
  /// **AI Context**: Creates visual hierarchy with logo and welcome text
  /// **Returns**: Widget containing branding elements
  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // AI Context: App logo or icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
        ),

        const SizedBox(height: 24),

        // AI Context: App name and tagline
        Text(
          'GeoAsist',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Control de Asistencia Geolocalizada',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// **Method**: Build login form with email and password fields
  /// **AI Context**: Creates validated form with user input handling
  /// **Returns**: Widget containing form fields
  Widget _buildLoginForm(BuildContext context, AuthenticationController authController) {
    return Form(
      key: _loginFormKey,
      child: LoginFormWidget(
        emailController: _emailTextController,
        passwordController: _passwordTextController,
        emailFocusNode: _emailFocusNode,
        passwordFocusNode: _passwordFocusNode,
        isPasswordVisible: _isPasswordVisible,
        onPasswordVisibilityToggle: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
        onFormSubmit: () => _handleLoginFormSubmission(authController),
        isFormEnabled: authController.currentState.allowsUserInteraction,
      ),
    );
  }

  /// **Method**: Build error message display widget
  /// **AI Context**: Shows user-friendly error messages with retry option
  /// **Returns**: Widget displaying current error state
  Widget _buildErrorMessageWidget(BuildContext context, AuthenticationController authController) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authController.currentErrorMessage ?? 'Error desconocido',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onErrorContainer,
            ),
            onPressed: () => authController.clearCurrentError(),
            tooltip: 'Cerrar mensaje de error',
          ),
        ],
      ),
    );
  }

  /// **Method**: Build login action button
  /// **AI Context**: Primary action button for form submission
  /// **Returns**: Widget with login button and loading state
  Widget _buildLoginButton(BuildContext context, AuthenticationController authController) {
    final theme = Theme.of(context);
    
    return ElevatedButton(
      onPressed: authController.currentState.allowsUserInteraction
          ? () => _handleLoginFormSubmission(authController)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Iniciar Sesión',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// **Method**: Build forgot password navigation button
  /// **AI Context**: Secondary action for password recovery flow
  /// **Returns**: Widget with text button for password reset
  Widget _buildForgotPasswordButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextButton(
      onPressed: () {
        // AI Context: Navigate to password reset page
        _navigateToPasswordReset(context);
      },
      child: Text(
        '¿Olvidaste tu contraseña?',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  /// **Method**: Build register account navigation button
  /// **AI Context**: Navigation to registration flow for new users
  /// **Returns**: Widget with registration navigation
  Widget _buildRegisterNavigationButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            // AI Context: Navigate to registration page
            _navigateToRegistration(context);
          },
          child: Text(
            'Regístrate aquí',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// **Method**: Handle login form submission with validation
  /// **AI Context**: Validates form and triggers authentication process
  /// **Side Effects**: Calls authentication controller with user input
  Future<void> _handleLoginFormSubmission(AuthenticationController authController) async {
    // AI Context: Clear previous errors before validation
    authController.clearCurrentError();

    // AI Context: Validate form inputs
    if (_loginFormKey.currentState?.validate() ?? false) {
      // AI Context: Dismiss keyboard before authentication
      FocusScope.of(context).unfocus();

      // AI Context: Trigger authentication with form data
      await authController.authenticateUserWithEmailAndPassword(
        emailAddress: _emailTextController.text.trim(),
        password: _passwordTextController.text,
      );
    }
  }

  /// **Method**: Set up listener for authentication state changes
  /// **AI Context**: Listens for authentication success to navigate away
  /// **Side Effects**: Navigates to dashboard on successful authentication
  void _setupAuthenticationStateListener() {
    final authController = context.read<AuthenticationController>();
    
    authController.addListener(() {
      if (authController.isUserAuthenticated) {
        // AI Context: Navigate to appropriate dashboard based on user role
        _navigateToDashboardBasedOnUserRole(authController.authenticatedUser!);
      }
    });
  }

  /// **Method**: Navigate to dashboard based on authenticated user role
  /// **AI Context**: Role-based navigation after successful authentication
  /// **Side Effects**: Replaces current route with appropriate dashboard
  void _navigateToDashboardBasedOnUserRole(dynamic user) {
    // AI Context: Determine navigation route based on user role
    String dashboardRoute = '/dashboard/student'; // Default route
    
    if (user.hasAdministratorPrivileges) {
      dashboardRoute = '/dashboard/admin';
    } else if (user.isProfessorRole) {
      dashboardRoute = '/dashboard/professor';
    }

    // AI Context: Replace current route to prevent back navigation to login
    Navigator.of(context).pushReplacementNamed(dashboardRoute);
  }

  /// **Method**: Navigate to password reset page
  /// **AI Context**: Navigation to password recovery flow
  /// **Side Effects**: Pushes password reset page to navigation stack
  void _navigateToPasswordReset(BuildContext context) {
    Navigator.of(context).pushNamed('/authentication/password-reset');
  }

  /// **Method**: Navigate to registration page
  /// **AI Context**: Navigation to account creation flow
  /// **Side Effects**: Pushes registration page to navigation stack
  void _navigateToRegistration(BuildContext context) {
    Navigator.of(context).pushNamed('/authentication/register');
  }
}