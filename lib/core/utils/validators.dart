import '../constants/app_constants.dart';

/// Validadores para formularios y datos de entrada
/// Utilidades para validación de datos en toda la aplicación

class Validators {
  /// Valida que un campo no esté vacío
  static String? required(String? value, [String fieldName = 'Campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida nombre de usuario
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de usuario es requerido';
    }

    if (value.length < AppConstants.minUsernameLength) {
      return 'El nombre de usuario debe tener al menos ${AppConstants.minUsernameLength} caracteres';
    }

    if (value.length > AppConstants.maxUsernameLength) {
      return 'El nombre de usuario no puede exceder ${AppConstants.maxUsernameLength} caracteres';
    }

    // Solo letras, números y guión bajo
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números y guión bajo';
    }

    return null;
  }

  /// Valida contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'La contraseña no puede exceder ${AppConstants.maxPasswordLength} caracteres';
    }

    return null;
  }

  /// Valida que dos contraseñas coincidan
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirme su contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    if (!RegExp(AppConstants.emailPattern).hasMatch(value)) {
      return 'Ingrese un email válido';
    }

    return null;
  }

  /// Valida número de teléfono
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }

    if (!RegExp(AppConstants.phonePattern).hasMatch(value)) {
      return 'Ingrese un teléfono válido (9 dígitos)';
    }

    return null;
  }

  /// Valida número entero positivo
  static String? positiveInteger(String? value, [String fieldName = 'Valor']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Ingrese un número válido';
    }

    if (number <= 0) {
      return '$fieldName debe ser mayor que 0';
    }

    return null;
  }

  /// Valida número decimal positivo
  static String? positiveDouble(String? value, [String fieldName = 'Valor']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Ingrese un número válido';
    }

    if (number <= 0) {
      return '$fieldName debe ser mayor que 0';
    }

    return null;
  }

  /// Valida cantidad de inventario
  static String? quantity(String? value) {
    final error = positiveInteger(value, 'Cantidad');
    if (error != null) return error;

    final qty = int.parse(value!);
    if (qty > AppConstants.maxStockLimit) {
      return 'La cantidad no puede exceder ${AppConstants.maxStockLimit}';
    }

    return null;
  }

  /// Valida precio
  static String? price(String? value) {
    final error = positiveDouble(value, 'Precio');
    if (error != null) return error;

    final price = double.parse(value!);
    if (price > 999999.99) {
      return 'El precio es demasiado alto';
    }

    return null;
  }

  /// Valida porcentaje de descuento
  static String? discountPercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // El descuento es opcional
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Ingrese un porcentaje válido';
    }

    if (number < AppConstants.minDiscountPercentage) {
      return 'El descuento no puede ser negativo';
    }

    if (number > AppConstants.maxDiscountPercentage) {
      return 'El descuento no puede exceder ${AppConstants.maxDiscountPercentage}%';
    }

    return null;
  }

  /// Valida código de barras
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de barras es requerido';
    }

    if (!RegExp(AppConstants.barcodePattern).hasMatch(value)) {
      return 'Código de barras inválido (debe tener 8-13 dígitos)';
    }

    return null;
  }

  /// Valida SKU (código de producto)
  static String? sku(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El SKU es requerido';
    }

    if (value.length < 3) {
      return 'El SKU debe tener al menos 3 caracteres';
    }

    if (value.length > 50) {
      return 'El SKU no puede exceder 50 caracteres';
    }

    // Letras, números, guión y guión bajo
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'SKU inválido (solo letras, números, - y _)';
    }

    return null;
  }

  /// Valida longitud mínima
  static String? minLength(String? value, int minLength, [String fieldName = 'Campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    return null;
  }

  /// Valida longitud máxima
  static String? maxLength(String? value, int maxLength, [String fieldName = 'Campo']) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }

    return null;
  }

  /// Valida rango numérico
  static String? numberRange(String? value, double min, double max, [String fieldName = 'Valor']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Ingrese un número válido';
    }

    if (number < min || number > max) {
      return '$fieldName debe estar entre $min y $max';
    }

    return null;
  }

  /// Combina múltiples validadores
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  Validators._(); // Constructor privado
}
