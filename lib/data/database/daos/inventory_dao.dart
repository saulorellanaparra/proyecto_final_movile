import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/inventory_table.dart';
import '../tables/products_table.dart';
import '../../../core/constants/enums.dart';

part 'inventory_dao.g.dart';

/// Data Access Object para gestión de inventario
/// Proporciona métodos para CRUD y consultas relacionadas con inventario
@DriftAccessor(tables: [Inventory, InventoryMovements, ProductVariants, Products])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(AppDatabase db) : super(db);

  // ==================== INVENTARIO ====================

  /// Obtiene todo el inventario
  Future<List<InventoryData>> getAllInventory() {
    return select(inventory).get();
  }

  /// Obtiene el inventario de una ubicación específica
  Future<List<InventoryData>> getInventoryByLocation(
    LocationType locationType,
    int locationId,
  ) {
    return (select(inventory)
          ..where((i) =>
              i.locationType.equals(locationType.code) &
              i.locationId.equals(locationId)))
        .get();
  }

  /// Obtiene el inventario de una variante específica en una ubicación
  Future<InventoryData?> getInventoryForVariant(
    int variantId,
    LocationType locationType,
    int locationId,
  ) {
    return (select(inventory)
          ..where((i) =>
              i.productVariantId.equals(variantId) &
              i.locationType.equals(locationType.code) &
              i.locationId.equals(locationId)))
        .getSingleOrNull();
  }

  /// Obtiene la cantidad disponible de una variante en una ubicación
  Future<int> getAvailableQuantity(
    int variantId,
    LocationType locationType,
    int locationId,
  ) async {
    final inv = await getInventoryForVariant(
      variantId,
      locationType,
      locationId,
    );
    return inv?.quantity ?? 0;
  }

  /// Verifica si hay stock disponible
  Future<bool> hasStock(
    int variantId,
    LocationType locationType,
    int locationId,
    int requiredQuantity,
  ) async {
    final available = await getAvailableQuantity(
      variantId,
      locationType,
      locationId,
    );
    return available >= requiredQuantity;
  }

  /// Obtiene productos con stock bajo (menor al mínimo)
  Future<List<InventoryData>> getLowStockItems(
    LocationType locationType,
    int locationId,
  ) {
    return (select(inventory)
          ..where((i) =>
              i.locationType.equals(locationType.code) &
              i.locationId.equals(locationId) &
              i.quantity.isSmallerThan(i.minStock)))
        .get();
  }

  /// Obtiene productos sin stock
  Future<List<InventoryData>> getOutOfStockItems(
    LocationType locationType,
    int locationId,
  ) {
    return (select(inventory)
          ..where((i) =>
              i.locationType.equals(locationType.code) &
              i.locationId.equals(locationId) &
              i.quantity.equals(0)))
        .get();
  }

  /// Crea o actualiza inventario
  Future<void> upsertInventory(InventoryCompanion inventoryItem) async {
    await into(inventory).insertOnConflictUpdate(inventoryItem);
  }

  /// Actualiza la cantidad de inventario
  Future<int> updateQuantity(
    int inventoryId,
    int newQuantity,
    int userId,
  ) {
    return (update(inventory)..where((i) => i.id.equals(inventoryId))).write(
      InventoryCompanion(
        quantity: Value(newQuantity),
        lastUpdated: Value(DateTime.now()),
        updatedBy: Value(userId),
      ),
    );
  }

  /// Incrementa la cantidad de inventario
  Future<void> incrementInventory({
    required int variantId,
    required LocationType locationType,
    required int locationId,
    required int quantity,
    required int userId,
  }) async {
    final currentInventory = await getInventoryForVariant(
      variantId,
      locationType,
      locationId,
    );

    if (currentInventory == null) {
      // Crear nuevo inventario
      await into(inventory).insert(
        InventoryCompanion.insert(
          productVariantId: variantId,
          locationType: locationType.code,
          locationId: locationId,
          quantity: Value(quantity),
          updatedBy: Value(userId),
        ),
      );
    } else {
      // Actualizar inventario existente
      final newQuantity = currentInventory.quantity + quantity;
      await (update(inventory)..where((i) => i.id.equals(currentInventory.id)))
          .write(
        InventoryCompanion(
          quantity: Value(newQuantity),
          lastUpdated: Value(DateTime.now()),
          updatedBy: Value(userId),
        ),
      );
    }
  }

  /// Decrementa la cantidad de inventario
  Future<void> decrementInventory({
    required int variantId,
    required LocationType locationType,
    required int locationId,
    required int quantity,
    required int userId,
  }) async {
    final currentInventory = await getInventoryForVariant(
      variantId,
      locationType,
      locationId,
    );

    if (currentInventory == null) {
      throw Exception('Inventario no encontrado');
    }

    if (currentInventory.quantity < quantity) {
      throw Exception('Stock insuficiente');
    }

    await (update(inventory)..where((i) => i.id.equals(currentInventory.id)))
        .write(
      InventoryCompanion(
        quantity: Value(currentInventory.quantity - quantity),
        lastUpdated: Value(DateTime.now()),
        updatedBy: Value(userId),
      ),
    );
  }

  // ==================== MOVIMIENTOS DE INVENTARIO ====================

  /// Registra un movimiento de inventario
  Future<int> recordMovement({
    required int variantId,
    required LocationType locationType,
    required int locationId,
    required MovementType movementType,
    required int quantityChange,
    required int quantityBefore,
    required int userId,
    String? referenceType,
    int? referenceId,
    String? notes,
  }) {
    return into(inventoryMovements).insert(
      InventoryMovementsCompanion.insert(
        productVariantId: variantId,
        locationType: locationType.code,
        locationId: locationId,
        movementType: movementType.code,
        quantityChange: quantityChange,
        quantityBefore: quantityBefore,
        quantityAfter: quantityBefore + quantityChange,
        referenceType: Value(referenceType),
        referenceId: Value(referenceId),
        notes: Value(notes),
        createdBy: Value(userId),
      ),
    );
  }

  /// Obtiene movimientos por ubicación
  Future<List<InventoryMovementData>> getMovementsByLocation(
    LocationType locationType,
    int locationId,
    {DateTime? startDate,
    DateTime? endDate,
    int? limit,}
  ) {
    final query = select(inventoryMovements)
      ..where((m) =>
          m.locationType.equals(locationType.code) &
          m.locationId.equals(locationId));

    if (startDate != null) {
      query.where((m) => m.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((m) => m.createdAt.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Stream de movimientos por ubicación (para actualizaciones en tiempo real)
  Stream<List<InventoryMovementData>> watchMovementsByLocation(
    LocationType locationType,
    int locationId,
    {int? limit,}
  ) {
    final query = select(inventoryMovements)
      ..where((m) =>
          m.locationType.equals(locationType.code) &
          m.locationId.equals(locationId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch();
  }

  /// Obtiene movimientos por variante
  Future<List<InventoryMovementData>> getMovementsByVariant(
    int variantId,
    {DateTime? startDate,
    DateTime? endDate,}
  ) {
    final query = select(inventoryMovements)
      ..where((m) => m.productVariantId.equals(variantId));

    if (startDate != null) {
      query.where((m) => m.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((m) => m.createdAt.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    return query.get();
  }

  /// Obtiene movimientos por tipo
  Future<List<InventoryMovementData>> getMovementsByType(
    MovementType movementType,
    {DateTime? startDate,
    DateTime? endDate,}
  ) {
    final query = select(inventoryMovements)
      ..where((m) => m.movementType.equals(movementType.code));

    if (startDate != null) {
      query.where((m) => m.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((m) => m.createdAt.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(m) => OrderingTerm.desc(m.createdAt)]);

    return query.get();
  }

  /// Obtiene el inventario total de una variante (todas las ubicaciones)
  Future<int> getTotalInventoryForVariant(int variantId) async {
    final result = await (selectOnly(inventory)
          ..addColumns([inventory.quantity.sum()])
          ..where(inventory.productVariantId.equals(variantId)))
        .getSingle();

    return result.read(inventory.quantity.sum()) ?? 0;
  }

  /// Stream para observar cambios en el inventario de una ubicación
  Stream<List<InventoryData>> watchInventoryByLocation(
    LocationType locationType,
    int locationId,
  ) {
    return (select(inventory)
          ..where((i) =>
              i.locationType.equals(locationType.code) &
              i.locationId.equals(locationId)))
        .watch();
  }

  // ==================== CONSULTAS ENRIQUECIDAS CON JOIN ====================

  /// Obtiene inventario enriquecido con información del producto por ubicación
  Future<List<InventoryWithProductInfo>> getInventoryWithProductInfoByLocation(
    LocationType locationType,
    int locationId,
  ) async {
    final query = select(inventory).join([
      innerJoin(
        productVariants,
        productVariants.id.equalsExp(inventory.productVariantId),
      ),
      innerJoin(
        products,
        products.id.equalsExp(productVariants.productId),
      ),
    ])
      ..where(
        inventory.locationType.equals(locationType.code) &
            inventory.locationId.equals(locationId),
      )
      ..orderBy([OrderingTerm.asc(products.name)]);

    final results = await query.get();

    return results.map((row) {
      final inv = row.readTable(inventory);
      final variant = row.readTable(productVariants);
      final product = row.readTable(products);

      return InventoryWithProductInfo(
        inventory: inv,
        variant: variant,
        product: product,
      );
    }).toList();
  }

  /// Obtiene inventario con stock bajo enriquecido
  /// Stock bajo: cantidad menor a 5 unidades
  Future<List<InventoryWithProductInfo>> getLowStockWithProductInfo(
    LocationType locationType,
    int locationId,
  ) async {
    // Primero cargar todo el inventario de la ubicación
    final allItems = await getInventoryWithProductInfoByLocation(
      locationType,
      locationId,
    );

    // Filtrar en memoria los items con stock bajo (menos de 5 unidades)
    return allItems.where((item) {
      return item.inventory.quantity > 0 && item.inventory.quantity < 5;
    }).toList();
  }

  /// Obtiene inventario sin stock enriquecido
  Future<List<InventoryWithProductInfo>> getOutOfStockWithProductInfo(
    LocationType locationType,
    int locationId,
  ) async {
    // Primero cargar todo el inventario de la ubicación
    final allItems = await getInventoryWithProductInfoByLocation(
      locationType,
      locationId,
    );

    // Filtrar en memoria los items sin stock
    return allItems.where((item) {
      return item.inventory.quantity == 0;
    }).toList();
  }
}

/// Clase para representar inventario con información completa del producto
class InventoryWithProductInfo {
  final InventoryData inventory;
  final ProductVariantData variant;
  final ProductData product;

  InventoryWithProductInfo({
    required this.inventory,
    required this.variant,
    required this.product,
  });

  /// Genera una descripción legible del producto con variante
  String get displayName {
    final parts = <String>[product.name];

    if (variant.size != null && variant.size!.isNotEmpty) {
      parts.add('Talla ${variant.size}');
    }

    if (variant.color != null && variant.color!.isNotEmpty) {
      parts.add(variant.color!);
    }

    return parts.join(' - ');
  }

  /// Obtiene el SKU/código para mostrar
  String get displaySku {
    return variant.sku;
  }

  /// Obtiene la marca si existe
  String? get brand => product.brand;

  /// Obtiene la categoría
  String get category => product.category;
}
