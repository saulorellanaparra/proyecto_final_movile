/// Excepciones personalizadas del sistema
/// Definición de excepciones específicas para manejo de errores

/// Excepción base para todas las excepciones de la aplicación
abstract class AppException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Excepción de base de datos
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'DatabaseException: $message';
}

/// Excepción de red
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Excepción de autenticación
class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Excepción de autorización (permisos)
class AuthorizationException extends AppException {
  const AuthorizationException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthorizationException: $message';
}

/// Excepción de validación
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final errors = fieldErrors!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return 'ValidationException: $message ($errors)';
    }
    return 'ValidationException: $message';
  }
}

/// Excepción de recurso no encontrado
class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'NotFoundException: $message';
}

/// Excepción de conflicto (por ejemplo, duplicado)
class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'ConflictException: $message';
}

/// Excepción de sincronización
class SyncException extends AppException {
  const SyncException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'SyncException: $message';
}

/// Excepción de cache
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción de servidor
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ServerException [$statusCode]: $message';
    }
    return 'ServerException: $message';
  }
}

/// Excepción de timeout
class TimeoutException extends AppException {
  const TimeoutException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'TimeoutException: $message';
}

/// Excepción de formato
class FormatException extends AppException {
  const FormatException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'FormatException: $message';
}

/// Excepción de inventario (stock insuficiente, etc.)
class InventoryException extends AppException {
  const InventoryException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'InventoryException: $message';
}

/// Excepción de negocio (reglas de negocio violadas)
class BusinessRuleException extends AppException {
  const BusinessRuleException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'BusinessRuleException: $message';
}
