import 'package:drift/drift.dart';
import 'users_table.dart';

/// Tabla de sesiones de usuario
/// Almacena el historial de inicio y cierre de sesión de los usuarios
@DataClassName('UserSessionData')
class UserSessions extends Table {
  /// ID único de la sesión
  IntColumn get id => integer().autoIncrement()();

  /// ID del usuario que inició sesión
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Fecha y hora de inicio de sesión
  DateTimeColumn get loginAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de cierre de sesión (null si la sesión está activa)
  DateTimeColumn get logoutAt => dateTime().nullable()();

  /// Información del dispositivo (ej: 'Android 13', 'iOS 16', 'Windows 11')
  TextColumn get deviceInfo => text().withLength(max: 200).nullable()();

  /// Dirección IP desde donde se inició sesión
  TextColumn get ipAddress => text().withLength(max: 50).nullable()();

  /// Indica si la sesión está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Tipo de ubicación desde donde inició sesión (STORE o WAREHOUSE)
  TextColumn get locationType => text().withLength(max: 20).nullable()();

  /// ID de la ubicación desde donde inició sesión
  IntColumn get locationId => integer().nullable()();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
