import 'package:drift/drift.dart';
import 'users_table.dart';

/// Tabla de tiendas/sucursales
/// Almacena información de las tiendas de la empresa
@DataClassName('StoreData')
class Stores extends Table {
  /// ID único de la tienda
  IntColumn get id => integer().autoIncrement()();

  /// Código único de la tienda (ej: T001, T002)
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();

  /// Nombre de la tienda
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Dirección de la tienda
  TextColumn get address => text().withLength(max: 255)();

  /// Teléfono de la tienda
  TextColumn get phone => text().withLength(max: 20).nullable()();

  /// Email de la tienda (opcional)
  TextColumn get email => text().withLength(max: 100).nullable()();

  /// ID del encargado/gerente de la tienda
  IntColumn get managerId => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Latitud para geolocalización (opcional)
  RealColumn get latitude => real().nullable()();

  /// Longitud para geolocalización (opcional)
  RealColumn get longitude => real().nullable()();

  /// Indica si la tienda está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
