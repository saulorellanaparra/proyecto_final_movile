import 'package:drift/drift.dart';
import 'products_table.dart';
import 'users_table.dart';

/// Tabla de inventario por ubicación
/// Almacena las cantidades de cada variante de producto en cada ubicación
@DataClassName('InventoryData')
class Inventory extends Table {
  /// ID único del registro de inventario
  IntColumn get id => integer().autoIncrement()();

  /// ID de la variante del producto
  IntColumn get productVariantId => integer().references(ProductVariants, #id, onDelete: KeyAction.cascade)();

  /// Tipo de ubicación (STORE o WAREHOUSE)
  TextColumn get locationType => text().withLength(max: 20)();

  /// ID de la ubicación (store_id o warehouse_id según locationType)
  IntColumn get locationId => integer()();

  /// Cantidad actual en stock
  IntColumn get quantity => integer().withDefault(const Constant(0))();

  /// Stock mínimo (para alertas de inventario bajo)
  IntColumn get minStock => integer().withDefault(const Constant(0))();

  /// Stock máximo (para control de inventario)
  IntColumn get maxStock => integer().withDefault(const Constant(1000))();

  /// Fecha y hora de última actualización del inventario
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();

  /// ID del usuario que realizó la última actualización
  IntColumn get updatedBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {productVariantId, locationType, locationId},
  ];
}

/// Tabla de movimientos de inventario
/// Registra todos los movimientos históricos de inventario para auditoría
@DataClassName('InventoryMovementData')
class InventoryMovements extends Table {
  /// ID único del movimiento
  IntColumn get id => integer().autoIncrement()();

  /// ID de la variante del producto
  IntColumn get productVariantId => integer().references(ProductVariants, #id, onDelete: KeyAction.cascade)();

  /// Tipo de ubicación (STORE o WAREHOUSE)
  TextColumn get locationType => text().withLength(max: 20)();

  /// ID de la ubicación
  IntColumn get locationId => integer()();

  /// Tipo de movimiento (PURCHASE, SALE, TRANSFER_IN, TRANSFER_OUT, ADJUSTMENT)
  TextColumn get movementType => text().withLength(max: 30)();

  /// Tipo de referencia (purchase_id, sale_id, transfer_id, etc.)
  TextColumn get referenceType => text().withLength(max: 30).nullable()();

  /// ID de la referencia
  IntColumn get referenceId => integer().nullable()();

  /// Cambio en la cantidad (+/-)
  IntColumn get quantityChange => integer()();

  /// Cantidad antes del movimiento
  IntColumn get quantityBefore => integer()();

  /// Cantidad después del movimiento
  IntColumn get quantityAfter => integer()();

  /// Notas del movimiento (opcional)
  TextColumn get notes => text().withLength(max: 500).nullable()();

  /// ID del usuario que creó el movimiento
  IntColumn get createdBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de creación del movimiento
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
