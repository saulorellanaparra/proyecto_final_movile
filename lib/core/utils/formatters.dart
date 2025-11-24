import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formateadores para presentación de datos
/// Utilidades para formatear números, monedas, fechas, etc.

class Formatters {
  /// Formatea un número como moneda
  /// Ejemplo: 1234.56 -> "Bs. 1,234.56"
  static String currency(double amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'es_PE',
      symbol: includeSymbol ? AppConstants.currencySymbol : '',
      decimalDigits: AppConstants.currencyDecimals,
    );
    return formatter.format(amount).trim();
  }

  /// Formatea un número entero
  /// Ejemplo: 1234 -> "1,234"
  static String integer(int number) {
    final formatter = NumberFormat('#,##0', 'es_PE');
    return formatter.format(number);
  }

  /// Formatea un número decimal
  /// Ejemplo: 1234.567 -> "1,234.57"
  static String decimal(double number, {int decimals = 2}) {
    final pattern = '#,##0.${'0' * decimals}';
    final formatter = NumberFormat(pattern, 'es_PE');
    return formatter.format(number);
  }

  /// Formatea porcentaje
  /// Ejemplo: 0.1567 -> "15.67%"
  static String percentage(double value, {int decimals = 2}) {
    final formatter = NumberFormat.percentPattern('es_PE');
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    return formatter.format(value);
  }

  /// Formatea un teléfono
  /// Ejemplo: "987654321" -> "987 654 321"
  static String phone(String phone) {
    if (phone.length != 9) return phone;
    return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
  }

  /// Formatea un SKU con guiones
  /// Ejemplo: "ABC123XYZ" -> "ABC-123-XYZ"
  static String sku(String sku) {
    // Implementación básica, puede personalizarse según necesidades
    if (sku.length <= 6) return sku;
    return sku.replaceAllMapped(
      RegExp(r'(.{3})'),
      (match) => '${match.group(1)}-',
    ).replaceAll(RegExp(r'-$'), '');
  }

  /// Capitaliza la primera letra de cada palabra
  /// Ejemplo: "juan pérez" -> "Juan Pérez"
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Convierte texto a mayúsculas
  static String uppercase(String text) => text.toUpperCase();

  /// Convierte texto a minúsculas
  static String lowercase(String text) => text.toLowerCase();

  /// Trunca un texto si excede una longitud
  /// Ejemplo: truncate("Hola mundo", 7) -> "Hola..."
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Formatea un código de barras con guiones para mejor legibilidad
  /// Ejemplo: "1234567890123" -> "123-4567-890-123"
  static String barcode(String code) {
    if (code.length == 13) {
      // EAN-13
      return '${code.substring(0, 3)}-${code.substring(3, 7)}-${code.substring(7, 10)}-${code.substring(10)}';
    } else if (code.length == 8) {
      // EAN-8
      return '${code.substring(0, 4)}-${code.substring(4)}';
    }
    return code;
  }

  /// Formatea bytes a tamaño legible
  /// Ejemplo: 1536 -> "1.5 KB"
  static String fileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Formatea duración en formato legible
  /// Ejemplo: Duration(hours: 2, minutes: 30) -> "2h 30m"
  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Pluraliza una palabra según la cantidad
  /// Ejemplo: pluralize(1, 'producto', 'productos') -> "1 producto"
  /// Ejemplo: pluralize(5, 'producto', 'productos') -> "5 productos"
  static String pluralize(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  /// Formatea coordenadas geográficas
  /// Ejemplo: (-12.046374, -77.042793) -> "12°2'47\"S, 77°2'34\"W"
  static String coordinates(double latitude, double longitude) {
    final lat = _formatCoordinate(latitude, 'N', 'S');
    final lng = _formatCoordinate(longitude, 'E', 'W');
    return '$lat, $lng';
  }

  static String _formatCoordinate(double value, String positive, String negative) {
    final isPositive = value >= 0;
    final absValue = value.abs();
    final degrees = absValue.floor();
    final minutesDecimal = (absValue - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = ((minutesDecimal - minutes) * 60).round();

    return '$degrees°$minutes\'$seconds"${isPositive ? positive : negative}';
  }

  /// Formatea un número de tarjeta de crédito (oculta dígitos centrales)
  /// Ejemplo: "1234567890123456" -> "1234 **** **** 3456"
  static String creditCard(String cardNumber) {
    if (cardNumber.length < 12) return cardNumber;
    return '${cardNumber.substring(0, 4)} **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  /// Remueve caracteres especiales de un string
  /// Ejemplo: "Hola, ¿cómo estás?" -> "Hola como estas"
  static String removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Sanitiza input para búsqueda (remueve acentos, convierte a minúsculas)
  static String sanitizeForSearch(String text) {
    const withDiacritics = 'àáâãäåòóôõöøèéêëðçìíîïùúûüñšžýÿ';
    const withoutDiacritics = 'aaaaaaooooooeeeeocdiiiiuuuunszyy';

    var sanitized = text.toLowerCase();
    for (var i = 0; i < withDiacritics.length; i++) {
      sanitized = sanitized.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return sanitized;
  }

  Formatters._(); // Constructor privado
}
