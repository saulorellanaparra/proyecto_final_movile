import 'package:equatable/equatable.dart';

/// Fallos del sistema para manejo de errores con Either
/// Se utilizan en combinación con el patrón Either<Failure, Success>

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure: $message';
}

/// Fallo de servidor
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  @override
  String toString() => 'ServerFailure: $message';
}

/// Fallo de caché
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});

  @override
  String toString() => 'CacheFailure: $message';
}

/// Fallo de red
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});

  @override
  String toString() => 'NetworkFailure: $message';
}

/// Fallo de base de datos
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});

  @override
  String toString() => 'DatabaseFailure: $message';
}

/// Fallo de autenticación
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code});

  @override
  String toString() => 'AuthenticationFailure: $message';
}

/// Fallo de autorización
class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message, {super.code});

  @override
  String toString() => 'AuthorizationFailure: $message';
}

/// Fallo de validación
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors, super.code});

  @override
  List<Object?> get props => [message, code, fieldErrors];

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationFailure: $message (${fieldErrors.toString()})';
    }
    return 'ValidationFailure: $message';
  }
}

/// Fallo de recurso no encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});

  @override
  String toString() => 'NotFoundFailure: $message';
}

/// Fallo de conflicto
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code});

  @override
  String toString() => 'ConflictFailure: $message';
}

/// Fallo de sincronización
class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code});

  @override
  String toString() => 'SyncFailure: $message';
}

/// Fallo de timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.code});

  @override
  String toString() => 'TimeoutFailure: $message';
}

/// Fallo de inventario
class InventoryFailure extends Failure {
  const InventoryFailure(super.message, {super.code});

  @override
  String toString() => 'InventoryFailure: $message';
}

/// Fallo de regla de negocio
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure(super.message, {super.code});

  @override
  String toString() => 'BusinessRuleFailure: $message';
}

/// Fallo genérico/desconocido
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});

  @override
  String toString() => 'UnknownFailure: $message';
}

/// Clase auxiliar para mapear excepciones a failures
class FailureMapper {
  static Failure mapExceptionToFailure(Exception exception) {
    // Aquí puedes mapear excepciones específicas a failures específicos
    final message = exception.toString();

    if (message.contains('Network')) {
      return NetworkFailure(message);
    } else if (message.contains('Database')) {
      return DatabaseFailure(message);
    } else if (message.contains('Authentication')) {
      return AuthenticationFailure(message);
    } else if (message.contains('Authorization')) {
      return AuthorizationFailure(message);
    } else if (message.contains('Validation')) {
      return ValidationFailure(message);
    } else if (message.contains('NotFound')) {
      return NotFoundFailure(message);
    } else if (message.contains('Conflict')) {
      return ConflictFailure(message);
    } else if (message.contains('Sync')) {
      return SyncFailure(message);
    } else if (message.contains('Timeout')) {
      return TimeoutFailure(message);
    } else if (message.contains('Inventory')) {
      return InventoryFailure(message);
    } else if (message.contains('BusinessRule')) {
      return BusinessRuleFailure(message);
    }

    return UnknownFailure(message);
  }
}
