import 'package:drift/drift.dart';
import 'warehouses_table.dart';
import 'users_table.dart';
import 'products_table.dart';

/// Tabla de compras
/// Almacena las órdenes de compra a proveedores
@DataClassName('PurchaseData')
class Purchases extends Table {
  /// ID único de la compra
  IntColumn get id => integer().autoIncrement()();

  /// Número de compra (generado automáticamente, ej: COM-2024-0001)
  TextColumn get purchaseNumber => text().withLength(min: 1, max: 50).unique()();

  /// Nombre del proveedor
  TextColumn get supplierName => text().withLength(min: 1, max: 200)();

  /// RUC o identificación del proveedor
  TextColumn get supplierRuc => text().withLength(max: 20).nullable()();

  /// Teléfono del proveedor
  TextColumn get supplierPhone => text().withLength(max: 20).nullable()();

  /// Email del proveedor
  TextColumn get supplierEmail => text().withLength(max: 100).nullable()();

  /// ID del almacén donde se recibe la compra
  IntColumn get warehouseId => integer().references(Warehouses, #id, onDelete: KeyAction.restrict)();

  /// Fecha de la compra
  DateTimeColumn get purchaseDate => dateTime()();

  /// Monto total de la compra
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();

  /// Notas adicionales
  TextColumn get notes => text().withLength(max: 1000).nullable()();

  /// Estado de la compra (PENDING, RECEIVED, CANCELLED)
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('PENDING'))();

  /// ID del usuario que creó la compra
  IntColumn get createdBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Tabla de detalles de compra
/// Almacena los ítems de cada compra
@DataClassName('PurchaseDetailData')
class PurchaseDetails extends Table {
  /// ID único del detalle
  IntColumn get id => integer().autoIncrement()();

  /// ID de la compra
  IntColumn get purchaseId => integer().references(Purchases, #id, onDelete: KeyAction.cascade)();

  /// ID de la variante del producto
  IntColumn get productVariantId => integer().references(ProductVariants, #id, onDelete: KeyAction.restrict)();

  /// Cantidad comprada
  IntColumn get quantity => integer()();

  /// Costo unitario
  RealColumn get unitCost => real()();

  /// Subtotal (quantity * unitCost)
  RealColumn get subtotal => real()();

  /// Fecha de creación del detalle
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
