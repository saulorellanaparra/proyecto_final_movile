import 'package:drift/drift.dart';

/// Tabla de productos base
/// Almacena información general de los productos
@DataClassName('ProductData')
class Products extends Table {
  /// ID único del producto
  IntColumn get id => integer().autoIncrement()();

  /// Código único del producto
  TextColumn get code => text().withLength(min: 1, max: 50).unique()();

  /// Nombre del producto
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Descripción del producto
  TextColumn get description => text().withLength(max: 1000).nullable()();

  /// Marca del producto
  TextColumn get brand => text().withLength(max: 100).nullable()();

  /// Categoría del producto (código de enum ProductCategory)
  TextColumn get category => text().withLength(max: 50)();

  /// Precio base del producto (sin variantes)
  RealColumn get basePrice => real().withDefault(const Constant(0.0))();

  /// Costo/precio de compra del producto
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();

  /// URL de la imagen del producto (opcional)
  TextColumn get imageUrl => text().withLength(max: 500).nullable()();

  /// Indica si el producto está activo
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

/// Tabla de variantes de productos
/// Almacena las diferentes variantes de un producto (talla, color, etc.)
@DataClassName('ProductVariantData')
class ProductVariants extends Table {
  /// ID único de la variante
  IntColumn get id => integer().autoIncrement()();

  /// ID del producto padre
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();

  /// SKU único de la variante (Stock Keeping Unit)
  TextColumn get sku => text().withLength(min: 1, max: 100).unique()();

  /// Talla de la variante (ej: S, M, L, XL)
  TextColumn get size => text().withLength(max: 20).nullable()();

  /// Color de la variante
  TextColumn get color => text().withLength(max: 50).nullable()();

  /// Código de barras de la variante
  TextColumn get barcode => text().withLength(max: 50).nullable().unique()();

  /// Precio adicional sobre el precio base (puede ser 0 o negativo)
  RealColumn get additionalPrice => real().withDefault(const Constant(0.0))();

  /// Notas adicionales de la variante
  TextColumn get notes => text().withLength(max: 500).nullable()();

  /// URL de la imagen específica de esta variante (opcional)
  TextColumn get imageUrl => text().withLength(max: 500).nullable()();

  /// Indica si la variante está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última actualización
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}
