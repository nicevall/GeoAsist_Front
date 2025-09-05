// lib/core/strings/app_strings.dart
/// Simplified string constants for Android-only GeoAsist app
/// Using hardcoded Spanish strings for better performance
class AppStrings {
  // App basic
  static const String appTitle = 'GeoAsist';
  static const String welcome = 'Bienvenido';
  
  // Authentication
  static const String login = 'Iniciar Sesión';
  static const String logout = 'Cerrar Sesión';
  static const String email = 'Email';
  static const String password = 'Contraseña';
  static const String enterEmail = 'Ingresa tu email';
  static const String enterPassword = 'Ingresa tu contraseña';
  
  // Validation messages
  static const String requiredField = 'Este campo es requerido';
  static const String invalidEmail = 'Por favor ingresa un email válido';
  static const String passwordTooShort = 'La contraseña debe tener al menos 6 caracteres';
  
  // Navigation
  static const String dashboard = 'Panel Principal';
  static const String events = 'Eventos';
  static const String attendance = 'Asistencia';
  static const String settings = 'Configuración';
  static const String profile = 'Perfil';
  
  // Attendance
  static const String markAttendance = 'Marcar Asistencia';
  static const String attendanceMarked = 'Asistencia marcada exitosamente';
  static const String locationPermissionRequired = 'Se requiere permiso de ubicación para marcar asistencia';
  static const String outsideGeofence = 'Estás fuera del área del evento';
  
  // Status
  static const String present = 'Presente';
  static const String absent = 'Ausente';
  static const String late = 'Tarde';
  static const String loading = 'Cargando...';
  
  // Actions
  static const String retry = 'Reintentar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String search = 'Buscar';
  
  // Messages
  static const String error = 'Error';
  static const String noResults = 'No se encontraron resultados';
  static const String networkError = 'Error de conexión de red. Por favor verifica tu conexión a internet.';
  static const String unknownError = 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
  static const String permissionDenied = 'Permiso denegado';
  
  // Theme
  static const String lightTheme = 'Claro';
  static const String darkTheme = 'Oscuro';
  static const String systemTheme = 'Sistema';
  
  // Accessibility
  static const String accessibilityButton = 'botón';
  static const String accessibilityTextField = 'campo de texto';
  static const String accessibilityDisabled = 'deshabilitado';
  static const String accessibilityRequired = 'campo requerido';
  
  // App info
  static const String about = 'Acerca de';
  static const String version = 'Versión';
  static const String notifications = 'Notificaciones';
  
  // Helper methods for dynamic strings
  static String welcomeUser(String userName) => 'Bienvenido, $userName';
  static String eventStartsAt(String time) => 'El evento comienza a las $time';
  static String attendanceCount(int count) => 'Asistencias: $count';
  static String distanceFromEvent(double distance) => 'Distancia: ${distance.toStringAsFixed(1)}m';
}