import 'package:drift/drift.dart';
import 'users_table.dart';
import 'products_table.dart';

/// Tabla de transferencias
/// Almacena las transferencias de productos entre almacenes y tiendas
@DataClassName('TransferData')
class Transfers extends Table {
  /// ID único de la transferencia
  IntColumn get id => integer().autoIncrement()();

  /// Número de transferencia (generado automáticamente, ej: TRF-2024-0001)
  TextColumn get transferNumber => text().withLength(min: 1, max: 50).unique()();

  /// Tipo de ubicación de origen (STORE o WAREHOUSE)
  TextColumn get fromType => text().withLength(max: 20)();

  /// ID de la ubicación de origen
  IntColumn get fromId => integer()();

  /// Tipo de ubicación de destino (STORE o WAREHOUSE)
  TextColumn get toType => text().withLength(max: 20)();

  /// ID de la ubicación de destino
  IntColumn get toId => integer()();

  /// Fecha de la transferencia
  DateTimeColumn get transferDate => dateTime()();

  /// Estado de la transferencia (PENDING, APPROVED, IN_TRANSIT, RECEIVED, CANCELLED)
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('PENDING'))();

  /// Notas adicionales
  TextColumn get notes => text().withLength(max: 1000).nullable()();

  /// ID del usuario que creó la transferencia
  IntColumn get createdBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de creación
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// ID del usuario que aprobó la transferencia
  IntColumn get approvedBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de aprobación
  DateTimeColumn get approvedAt => dateTime().nullable()();

  /// ID del usuario que recibió la transferencia
  IntColumn get receivedBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de recepción
  DateTimeColumn get receivedAt => dateTime().nullable()();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Tabla de detalles de transferencia
/// Almacena los ítems de cada transferencia
@DataClassName('TransferDetailData')
class TransferDetails extends Table {
  /// ID único del detalle
  IntColumn get id => integer().autoIncrement()();

  /// ID de la transferencia
  IntColumn get transferId => integer().references(Transfers, #id, onDelete: KeyAction.cascade)();

  /// ID de la variante del producto
  IntColumn get productVariantId => integer().references(ProductVariants, #id, onDelete: KeyAction.restrict)();

  /// Cantidad a transferir
  IntColumn get quantity => integer()();

  /// Cantidad recibida (puede ser diferente de la enviada)
  IntColumn get receivedQuantity => integer().nullable()();

  /// Notas del detalle (ej: diferencias en la recepción)
  TextColumn get notes => text().withLength(max: 500).nullable()();

  /// Fecha de creación del detalle
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
