import 'package:drift/drift.dart';
import 'users_table.dart';

/// Tabla de almacenes
/// Almacena información de los almacenes de la empresa
@DataClassName('WarehouseData')
class Warehouses extends Table {
  /// ID único del almacén
  IntColumn get id => integer().autoIncrement()();

  /// Código único del almacén (ej: A001, A002)
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();

  /// Nombre del almacén
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Dirección del almacén
  TextColumn get address => text().withLength(max: 255)();

  /// Teléfono del almacén
  TextColumn get phone => text().withLength(max: 20).nullable()();

  /// Email del almacén (opcional)
  TextColumn get email => text().withLength(max: 100).nullable()();

  /// ID del encargado del almacén
  IntColumn get managerId => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Latitud para geolocalización (opcional)
  RealColumn get latitude => real().nullable()();

  /// Longitud para geolocalización (opcional)
  RealColumn get longitude => real().nullable()();

  /// Indica si el almacén está activo
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
