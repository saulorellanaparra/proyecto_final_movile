import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/inventory_table.dart';

part 'product_dao.g.dart';

/// Data Access Object para gestión de productos
/// Proporciona métodos para CRUD y consultas relacionadas con productos
@DriftAccessor(tables: [Products, ProductVariants, Inventory])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(AppDatabase db) : super(db);

  // ==================== PRODUCTOS ====================

  /// Obtiene todos los productos activos
  Future<List<ProductData>> getAllActiveProducts() {
    return (select(products)..where((p) => p.isActive.equals(true))).get();
  }

  /// Obtiene todos los productos inactivos
  Future<List<ProductData>> getAllInactiveProducts() {
    return (select(products)..where((p) => p.isActive.equals(false))).get();
  }

  /// Obtiene todos los productos
  Future<List<ProductData>> getAllProducts() {
    return select(products).get();
  }

  /// Obtiene un producto por ID
  Future<ProductData?> getProductById(int id) {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Obtiene un producto por código
  Future<ProductData?> getProductByCode(String code) {
    return (select(products)..where((p) => p.code.equals(code)))
        .getSingleOrNull();
  }

  /// Obtiene productos por categoría
  Future<List<ProductData>> getProductsByCategory(String category) {
    return (select(products)
          ..where((p) =>
              p.category.equals(category) & p.isActive.equals(true)))
        .get();
  }

  /// Obtiene productos por marca
  Future<List<ProductData>> getProductsByBrand(String brand) {
    return (select(products)
          ..where((p) => p.brand.equals(brand) & p.isActive.equals(true)))
        .get();
  }

  /// Busca productos por nombre, código o descripción
  Future<List<ProductData>> searchProducts(String query) {
    final searchQuery = '%$query%';
    return (select(products)
          ..where((p) =>
              (p.name.like(searchQuery) |
                  p.code.like(searchQuery) |
                  p.description.like(searchQuery)) &
              p.isActive.equals(true)))
        .get();
  }

  /// Obtiene productos que tienen inventario en una ubicación específica
  Future<List<ProductData>> getProductsByLocation(
    String locationType,
    int locationId,
  ) async {
    // Hacer JOIN entre Products, ProductVariants e Inventory
    // para obtener solo productos que tienen inventario en la ubicación especificada
    final query = selectOnly(products, distinct: true)
      ..addColumns([products.id, products.code, products.name, products.description,
                    products.brand, products.category, products.basePrice, products.costPrice,
                    products.isActive, products.createdAt, products.updatedAt, products.lastSyncAt])
      ..join([
        innerJoin(
          productVariants,
          productVariants.productId.equalsExp(products.id),
        ),
        innerJoin(
          inventory,
          inventory.productVariantId.equalsExp(productVariants.id) &
          inventory.locationType.equals(locationType) &
          inventory.locationId.equals(locationId),
        ),
      ])
      ..where(products.isActive.equals(true));

    final rows = await query.get();

    return rows.map((row) {
      return ProductData(
        id: row.read(products.id)!,
        code: row.read(products.code)!,
        name: row.read(products.name)!,
        description: row.read(products.description),
        brand: row.read(products.brand),
        category: row.read(products.category)!,
        basePrice: row.read(products.basePrice)!,
        costPrice: row.read(products.costPrice)!,
        isActive: row.read(products.isActive)!,
        createdAt: row.read(products.createdAt)!,
        updatedAt: row.read(products.updatedAt)!,
        lastSyncAt: row.read(products.lastSyncAt),
      );
    }).toList();
  }

  /// Busca productos por nombre o código en una ubicación específica
  Future<List<ProductData>> searchProductsByLocation(
    String query,
    String locationType,
    int locationId,
  ) async {
    final searchQuery = '%$query%';

    final queryBuilder = selectOnly(products, distinct: true)
      ..addColumns([products.id, products.code, products.name, products.description,
                    products.brand, products.category, products.basePrice, products.costPrice,
                    products.isActive, products.createdAt, products.updatedAt, products.lastSyncAt])
      ..join([
        innerJoin(
          productVariants,
          productVariants.productId.equalsExp(products.id),
        ),
        innerJoin(
          inventory,
          inventory.productVariantId.equalsExp(productVariants.id) &
          inventory.locationType.equals(locationType) &
          inventory.locationId.equals(locationId),
        ),
      ])
      ..where(
        (products.name.like(searchQuery) |
         products.code.like(searchQuery) |
         products.description.like(searchQuery)) &
        products.isActive.equals(true)
      );

    final rows = await queryBuilder.get();

    return rows.map((row) {
      return ProductData(
        id: row.read(products.id)!,
        code: row.read(products.code)!,
        name: row.read(products.name)!,
        description: row.read(products.description),
        brand: row.read(products.brand),
        category: row.read(products.category)!,
        basePrice: row.read(products.basePrice)!,
        costPrice: row.read(products.costPrice)!,
        isActive: row.read(products.isActive)!,
        createdAt: row.read(products.createdAt)!,
        updatedAt: row.read(products.updatedAt)!,
        lastSyncAt: row.read(products.lastSyncAt),
      );
    }).toList();
  }

  /// Crea un nuevo producto
  Future<int> createProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  /// Actualiza un producto existente
  Future<bool> updateProduct(ProductData product) {
    return update(products).replace(product);
  }

  /// Elimina un producto (soft delete)
  Future<int> softDeleteProduct(int productId) {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina un producto permanentemente
  Future<int> deleteProduct(int productId) {
    return (delete(products)..where((p) => p.id.equals(productId))).go();
  }

  // ==================== VARIANTES DE PRODUCTOS ====================

  /// Obtiene todas las variantes de un producto
  Future<List<ProductVariantData>> getProductVariants(int productId) {
    return (select(productVariants)
          ..where((v) =>
              v.productId.equals(productId) & v.isActive.equals(true)))
        .get();
  }

  /// Obtiene todas las variantes activas
  Future<List<ProductVariantData>> getAllActiveVariants() {
    return (select(productVariants)..where((v) => v.isActive.equals(true)))
        .get();
  }

  /// Obtiene una variante por ID
  Future<ProductVariantData?> getVariantById(int id) {
    return (select(productVariants)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtiene una variante por SKU
  Future<ProductVariantData?> getVariantBySku(String sku) {
    return (select(productVariants)..where((v) => v.sku.equals(sku)))
        .getSingleOrNull();
  }

  /// Obtiene una variante por código de barras
  Future<ProductVariantData?> getVariantByBarcode(String barcode) {
    return (select(productVariants)..where((v) => v.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Busca variantes por SKU, código de barras o características
  Future<List<ProductVariantData>> searchVariants(String query) {
    final searchQuery = '%$query%';
    return (select(productVariants)
          ..where((v) =>
              (v.sku.like(searchQuery) |
                  v.barcode.like(searchQuery) |
                  v.size.like(searchQuery) |
                  v.color.like(searchQuery)) &
              v.isActive.equals(true)))
        .get();
  }

  /// Obtiene variantes por talla
  Future<List<ProductVariantData>> getVariantsBySize(
      int productId, String size) {
    return (select(productVariants)
          ..where((v) =>
              v.productId.equals(productId) &
              v.size.equals(size) &
              v.isActive.equals(true)))
        .get();
  }

  /// Obtiene variantes por color
  Future<List<ProductVariantData>> getVariantsByColor(
      int productId, String color) {
    return (select(productVariants)
          ..where((v) =>
              v.productId.equals(productId) &
              v.color.equals(color) &
              v.isActive.equals(true)))
        .get();
  }

  /// Crea una nueva variante
  Future<int> createVariant(ProductVariantsCompanion variant) {
    return into(productVariants).insert(variant);
  }

  /// Actualiza una variante existente
  Future<bool> updateVariant(ProductVariantData variant) {
    return update(productVariants).replace(variant);
  }

  /// Elimina una variante (soft delete)
  Future<int> softDeleteVariant(int variantId) {
    return (update(productVariants)..where((v) => v.id.equals(variantId)))
        .write(
      ProductVariantsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina una variante permanentemente
  Future<int> deleteVariant(int variantId) {
    return (delete(productVariants)..where((v) => v.id.equals(variantId)))
        .go();
  }

  /// Obtiene el precio total de una variante (precio base + precio adicional)
  Future<double> getVariantTotalPrice(int variantId) async {
    final variant = await getVariantById(variantId);
    if (variant == null) return 0.0;

    final product = await getProductById(variant.productId);
    if (product == null) return 0.0;

    return product.basePrice + variant.additionalPrice;
  }

  /// Obtiene información completa del producto con su variante
  Future<Map<String, dynamic>?> getProductWithVariant(int variantId) async {
    final variant = await getVariantById(variantId);
    if (variant == null) return null;

    final product = await getProductById(variant.productId);
    if (product == null) return null;

    return {
      'product': product,
      'variant': variant,
      'totalPrice': product.basePrice + variant.additionalPrice,
    };
  }

  /// Obtiene productos con sus variantes (con JOIN)
  Stream<List<Map<String, dynamic>>> watchProductsWithVariants() {
    final query = select(products).join([
      leftOuterJoin(
        productVariants,
        productVariants.productId.equalsExp(products.id),
      ),
    ])
      ..where(products.isActive.equals(true));

    return query.watch().map((rows) {
      final Map<int, Map<String, dynamic>> productMap = {};

      for (final row in rows) {
        final product = row.readTable(products);
        final variant = row.readTableOrNull(productVariants);

        if (!productMap.containsKey(product.id)) {
          productMap[product.id] = {
            'product': product,
            'variants': <ProductVariantData>[],
          };
        }

        if (variant != null && variant.isActive) {
          (productMap[product.id]!['variants'] as List<ProductVariantData>)
              .add(variant);
        }
      }

      return productMap.values.toList();
    });
  }

  /// Actualiza la fecha de última sincronización de un producto
  Future<int> updateProductLastSync(int productId) {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  /// Actualiza la fecha de última sincronización de una variante
  Future<int> updateVariantLastSync(int variantId) {
    return (update(productVariants)..where((v) => v.id.equals(variantId)))
        .write(
      ProductVariantsCompanion(
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }
}
