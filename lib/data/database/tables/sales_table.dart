import 'package:drift/drift.dart';
import 'stores_table.dart';
import 'users_table.dart';
import 'products_table.dart';

/// Tabla de ventas
/// Almacena las transacciones de venta realizadas en las tiendas
@DataClassName('SaleData')
class Sales extends Table {
  /// ID único de la venta
  IntColumn get id => integer().autoIncrement()();

  /// Número de venta (generado automáticamente, ej: VEN-2024-0001)
  TextColumn get saleNumber => text().withLength(min: 1, max: 50).unique()();

  /// ID de la tienda donde se realizó la venta
  IntColumn get storeId => integer().references(Stores, #id, onDelete: KeyAction.restrict)();

  /// Nombre del cliente (opcional)
  TextColumn get customerName => text().withLength(max: 200).nullable()();

  /// DNI/Documento del cliente (opcional)
  TextColumn get customerDocument => text().withLength(max: 20).nullable()();

  /// Teléfono del cliente (opcional)
  TextColumn get customerPhone => text().withLength(max: 20).nullable()();

  /// Email del cliente (opcional)
  TextColumn get customerEmail => text().withLength(max: 100).nullable()();

  /// Fecha y hora de la venta
  DateTimeColumn get saleDate => dateTime()();

  /// Subtotal (antes de descuentos e impuestos)
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();

  /// Descuento aplicado
  RealColumn get discount => real().withDefault(const Constant(0.0))();

  /// Impuesto (IGV en Perú: 18%)
  RealColumn get tax => real().withDefault(const Constant(0.0))();

  /// Total de la venta
  RealColumn get total => real().withDefault(const Constant(0.0))();

  /// Método de pago (CASH, CARD, TRANSFER, MIXED)
  TextColumn get paymentMethod => text().withLength(max: 20)();

  /// Monto pagado en efectivo (si aplica)
  RealColumn get cashAmount => real().nullable()();

  /// Monto pagado con tarjeta (si aplica)
  RealColumn get cardAmount => real().nullable()();

  /// Notas adicionales
  TextColumn get notes => text().withLength(max: 1000).nullable()();

  /// Estado de la venta (COMPLETED, CANCELLED)
  TextColumn get status => text().withLength(max: 20).withDefault(const Constant('COMPLETED'))();

  /// ID del usuario que realizó la venta
  IntColumn get createdBy => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Tabla de detalles de venta
/// Almacena los ítems de cada venta
@DataClassName('SaleDetailData')
class SaleDetails extends Table {
  /// ID único del detalle
  IntColumn get id => integer().autoIncrement()();

  /// ID de la venta
  IntColumn get saleId => integer().references(Sales, #id, onDelete: KeyAction.cascade)();

  /// ID de la variante del producto
  IntColumn get productVariantId => integer().references(ProductVariants, #id, onDelete: KeyAction.restrict)();

  /// Cantidad vendida
  IntColumn get quantity => integer()();

  /// Precio unitario al momento de la venta
  RealColumn get unitPrice => real()();

  /// Descuento aplicado a este ítem
  RealColumn get discount => real().withDefault(const Constant(0.0))();

  /// Subtotal (quantity * unitPrice - discount)
  RealColumn get subtotal => real()();

  /// Fecha de creación del detalle
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
