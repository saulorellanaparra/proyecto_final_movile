import 'package:drift/drift.dart';

/// Tabla de usuarios del sistema
/// Almacena información de autenticación y datos básicos de usuarios
@DataClassName('UserData')
class Users extends Table {
  /// ID único del usuario
  IntColumn get id => integer().autoIncrement()();

  /// Nombre de usuario único para login
  TextColumn get username => text().withLength(min: 3, max: 30).unique()();

  /// Hash de la contraseña (nunca almacenar contraseña en texto plano)
  TextColumn get passwordHash => text().withLength(min: 60, max: 255)();

  /// Nombre completo del usuario
  TextColumn get fullName => text().withLength(min: 1, max: 100)();

  /// Email del usuario (opcional pero único si se proporciona)
  TextColumn get email => text().withLength(max: 100).nullable().unique()();

  /// Teléfono del usuario (opcional)
  TextColumn get phone => text().withLength(max: 20).nullable()();

  /// Indica si el usuario está activo
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización con el servidor
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  /// ID de la tienda asignada (para encargados de tienda)
  IntColumn get storeId => integer().nullable()();

  /// ID del almacén asignado (para encargados de almacén)
  IntColumn get warehouseId => integer().nullable()();
}
