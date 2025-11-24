import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utilidades para manejo de fechas
/// Funciones helper para formateo y manipulación de fechas

class AppDateUtils {
  /// Formatea una fecha según el formato estándar de la app
  /// Ejemplo: DateTime(2024, 12, 25) -> "25/12/2024"
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Formatea una fecha y hora
  /// Ejemplo: DateTime(2024, 12, 25, 15, 30) -> "25/12/2024 15:30"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  /// Formatea solo la hora
  /// Ejemplo: DateTime(2024, 12, 25, 15, 30) -> "15:30"
  static String formatTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  /// Formatea una fecha en formato largo
  /// Ejemplo: DateTime(2024, 12, 25) -> "25 de diciembre de 2024"
  static String formatLongDate(DateTime date) {
    return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_PE').format(date);
  }

  /// Formatea una fecha con día de la semana
  /// Ejemplo: DateTime(2024, 12, 25) -> "Miércoles, 25 de diciembre"
  static String formatWithWeekday(DateTime date) {
    return DateFormat('EEEE, d \'de\' MMMM', 'es_PE').format(date);
  }

  /// Obtiene la fecha actual sin hora
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Obtiene la fecha y hora actual
  static DateTime get now => DateTime.now();

  /// Obtiene el primer día del mes actual
  static DateTime get firstDayOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Obtiene el último día del mes actual
  static DateTime get lastDayOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// Obtiene el primer día del año actual
  static DateTime get firstDayOfYear {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  /// Obtiene el último día del año actual
  static DateTime get lastDayOfYear {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31);
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Verifica si una fecha es ayer
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  /// Verifica si una fecha está en el futuro
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Verifica si una fecha está en el pasado
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Calcula la diferencia de días entre dos fechas
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  /// Obtiene una fecha relativa (hace X días, ayer, hoy, etc.)
  /// Ejemplo: DateTime.now() -> "Hoy"
  /// Ejemplo: DateTime.now().subtract(Duration(days: 1)) -> "Ayer"
  /// Ejemplo: DateTime.now().subtract(Duration(days: 5)) -> "Hace 5 días"
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference == -1) {
      return 'Mañana';
    } else if (difference > 1 && difference < 7) {
      return 'Hace $difference días';
    } else if (difference < -1 && difference > -7) {
      return 'En ${-difference} días';
    } else if (difference >= 7 && difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? 'Hace 1 semana' : 'Hace $weeks semanas';
    } else if (difference <= -7 && difference > -30) {
      final weeks = (-difference / 7).floor();
      return weeks == 1 ? 'En 1 semana' : 'En $weeks semanas';
    } else if (difference >= 30 && difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? 'Hace 1 mes' : 'Hace $months meses';
    } else if (difference <= -30 && difference > -365) {
      final months = (-difference / 30).floor();
      return months == 1 ? 'En 1 mes' : 'En $months meses';
    } else if (difference >= 365) {
      final years = (difference / 365).floor();
      return years == 1 ? 'Hace 1 año' : 'Hace $years años';
    } else {
      final years = (-difference / 365).floor();
      return years == 1 ? 'En 1 año' : 'En $years años';
    }
  }

  /// Obtiene el tiempo relativo con hora
  /// Ejemplo: hace 2 horas, hace 30 minutos, etc.
  static String relativeDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? 'Hace 1 minuto' : 'Hace $minutes minutos';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? 'Hace 1 hora' : 'Hace $hours horas';
    } else {
      return relativeDate(dateTime);
    }
  }

  /// Parsea una fecha desde string
  /// Ejemplo: "25/12/2024" -> DateTime(2024, 12, 25)
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parsea una fecha y hora desde string
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return DateFormat(AppConstants.dateTimeFormat).parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Añade días a una fecha
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Resta días a una fecha
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Añade meses a una fecha
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  /// Resta meses a una fecha
  static DateTime subtractMonths(DateTime date, int months) {
    return DateTime(date.year, date.month - months, date.day);
  }

  /// Obtiene el inicio del día (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Obtiene el fin del día (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Verifica si dos fechas son del mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Verifica si dos fechas son del mismo mes
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Verifica si dos fechas son del mismo año
  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  /// Obtiene el nombre del mes
  static String monthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  /// Obtiene el nombre del día de la semana
  static String weekdayName(int weekday) {
    const weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    return weekdays[weekday - 1];
  }

  /// Verifica si una fecha está dentro de un rango
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return (date.isAfter(start) || isSameDay(date, start)) &&
           (date.isBefore(end) || isSameDay(date, end));
  }

  /// Obtiene un rango de fechas (lista de días entre dos fechas)
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = startOfDay(start);
    final endDay = startOfDay(end);

    while (current.isBefore(endDay) || isSameDay(current, endDay)) {
      days.add(current);
      current = addDays(current, 1);
    }

    return days;
  }

  AppDateUtils._(); // Constructor privado
}
