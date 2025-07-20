// lib/utils/date_utils.dart
class DateUtils {
  DateUtils._(); // Private constructor to prevent instantiation

  /// Formatea una fecha en formato legible en español
  static String formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  /// Formatea una fecha en formato corto (dd/mm/yyyy)
  static String formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatea solo la hora (HH:mm)
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea un rango de tiempo
  static String formatTimeRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  /// Formatea fecha y hora completa
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} a las ${formatTime(dateTime)}';
  }

  /// Obtiene el tiempo relativo (hace X minutos, horas, días)
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else {
      return formatDateShort(date);
    }
  }

  /// Verifica si dos fechas son del mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Verifica si una fecha es de esta semana
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Obtiene el nombre del día de la semana en español
  static String getDayName(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return days[date.weekday - 1];
  }

  /// Obtiene el nombre del mes en español
  static String getMonthName(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[date.month - 1];
  }

  /// Parsea una fecha ISO string a DateTime
  static DateTime? parseISOString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// Convierte DateTime a formato ISO string para el backend
  static String toISOString(DateTime date) {
    return date.toIso8601String();
  }
}
