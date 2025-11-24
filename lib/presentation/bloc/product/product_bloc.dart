import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/product_dao.dart';
import '../../../data/database/daos/stores_dao.dart';
import '../../../data/database/daos/warehouses_dao.dart';
import '../../../data/database/daos/inventory_dao.dart';
import 'product_event.dart';
import 'product_state.dart';

/// BLoC para gestión de productos
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductDao productDao;
  final StoresDao storesDao;
  final WarehousesDao warehousesDao;
  final InventoryDao inventoryDao;

  ProductBloc({
    required this.productDao,
    required this.storesDao,
    required this.warehousesDao,
    required this.inventoryDao,
  }) : super(const ProductInitial()) {
    on<ProductLoadAllRequested>(_onLoadAllRequested);
    on<ProductLoadActiveRequested>(_onLoadActiveRequested);
    on<ProductLoadInactiveRequested>(_onLoadInactiveRequested);
    on<ProductSearchRequested>(_onSearchRequested);
    on<ProductLoadByLocationRequested>(_onLoadByLocationRequested);
    on<ProductSearchByLocationRequested>(_onSearchByLocationRequested);
    on<ProductLoadByIdRequested>(_onLoadByIdRequested);
    on<ProductCreateRequested>(_onCreateRequested);
    on<ProductUpdateRequested>(_onUpdateRequested);
    on<ProductDeleteRequested>(_onDeleteRequested);
    on<ProductVariantsLoadRequested>(_onVariantsLoadRequested);
    on<ProductVariantCreateRequested>(_onVariantCreateRequested);
    on<ProductVariantDeleteRequested>(_onVariantDeleteRequested);
    on<ProductDeactivateRequested>(_onDeactivateRequested);
  }

  /// Cargar todos los productos
  Future<void> _onLoadAllRequested(
    ProductLoadAllRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final products = await productDao.getAllProducts();

      if (products.isEmpty) {
        emit(const ProductEmpty());
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductError('Error al cargar productos: ${e.toString()}'));
    }
  }

  /// Cargar solo productos activos
  Future<void> _onLoadActiveRequested(
    ProductLoadActiveRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final products = await productDao.getAllActiveProducts();

      if (products.isEmpty) {
        emit(const ProductEmpty());
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductError('Error al cargar productos activos: ${e.toString()}'));
    }
  }

  /// Cargar solo productos inactivos
  Future<void> _onLoadInactiveRequested(
    ProductLoadInactiveRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final products = await productDao.getAllInactiveProducts();

      if (products.isEmpty) {
        emit(const ProductEmpty());
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductError('Error al cargar productos inactivos: ${e.toString()}'));
    }
  }

  /// Buscar productos
  Future<void> _onSearchRequested(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      if (event.searchTerm.isEmpty) {
        final products = await productDao.getAllProducts();
        emit(products.isEmpty ? const ProductEmpty() : ProductsLoaded(products));
        return;
      }

      final products = await productDao.searchProducts(event.searchTerm);

      if (products.isEmpty) {
        emit(const ProductEmpty());
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductError('Error al buscar productos: ${e.toString()}'));
    }
  }

  /// Cargar productos de una ubicación específica
  Future<void> _onLoadByLocationRequested(
    ProductLoadByLocationRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final products = await productDao.getProductsByLocation(
        event.locationType,
        event.locationId,
      );

      if (products.isEmpty) {
        emit(const ProductEmpty());
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductError('Error al cargar productos de la ubicación: ${e.toString()}'));
    }
  }

  /// Buscar productos en una ubicación específica
  Future<void> _onSearchByLocationRequested(
    ProductSearchByLocationRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      if (event.searchTerm.isEmpty) {
        final products = await productDao.getProductsByLocation(
          event.locationType,
          event.locationId,
        );
        emit(products.isEmpty ? const ProductEmpty() : ProductsLoaded(products));
        return;
      }

      final products = await productDao.searchProductsByLocation(
        event.searchTerm,
        event.locationType,
        event.locationId,
      );

      if (products.isEmpty) {
        emit(const ProductEmpty());
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductError('Error al buscar productos en la ubicación: ${e.toString()}'));
    }
  }

  /// Cargar producto por ID
  Future<void> _onLoadByIdRequested(
    ProductLoadByIdRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final product = await productDao.getProductById(event.productId);

      if (product == null) {
        emit(const ProductError('Producto no encontrado'));
      } else {
        emit(ProductLoaded(product));
      }
    } catch (e) {
      emit(ProductError('Error al cargar producto: ${e.toString()}'));
    }
  }

  /// Crear nuevo producto
  Future<void> _onCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      // Validar que el código no exista
      final existingProduct = await productDao.getProductByCode(event.sku);
      if (existingProduct != null) {
        emit(const ProductError('Ya existe un producto con ese código'));
        return;
      }

      final productCompanion = ProductsCompanion.insert(
        code: event.sku,
        name: event.name,
        description: Value(event.description),
        brand: Value(event.brand),
        category: event.category ?? 'General',
        basePrice: Value(event.price),
        costPrice: Value(event.cost),
        isActive: Value(event.isActive),
      );

      final productId = await productDao.createProduct(productCompanion);

      // Crear variante estándar automáticamente
      final defaultVariantCompanion = ProductVariantsCompanion.insert(
        productId: productId,
        sku: '${event.sku}-STD',
        size: const Value(null),
        color: const Value(null),
        additionalPrice: const Value(0.0),
        isActive: const Value(true),
      );

      final variantId = await productDao.createVariant(defaultVariantCompanion);

      // Crear registros de inventario según el usuario
      // Si el usuario tiene una tienda asignada, solo crear inventario en esa tienda
      if (event.userStoreId != null) {
        await inventoryDao.upsertInventory(
          InventoryCompanion.insert(
            productVariantId: variantId,
            locationType: 'STORE',
            locationId: event.userStoreId!,
            quantity: const Value(0),
          ),
        );
      }
      // Si el usuario tiene un almacén asignado, solo crear inventario en ese almacén
      else if (event.userWarehouseId != null) {
        await inventoryDao.upsertInventory(
          InventoryCompanion.insert(
            productVariantId: variantId,
            locationType: 'WAREHOUSE',
            locationId: event.userWarehouseId!,
            quantity: const Value(0),
          ),
        );
      }
      // Si no tiene ubicación asignada (admin/gerente), crear en todas las ubicaciones
      else {
        // Crear registros de inventario con cantidad 0 en todas las tiendas
        final stores = await storesDao.getAllStores();
        for (final store in stores) {
          await inventoryDao.upsertInventory(
            InventoryCompanion.insert(
              productVariantId: variantId,
              locationType: 'STORE',
              locationId: store.id,
              quantity: const Value(0),
            ),
          );
        }

        // Crear registros de inventario con cantidad 0 en todos los almacenes
        final warehouses = await warehousesDao.getAllWarehouses();
        for (final warehouse in warehouses) {
          await inventoryDao.upsertInventory(
            InventoryCompanion.insert(
              productVariantId: variantId,
              locationType: 'WAREHOUSE',
              locationId: warehouse.id,
              quantity: const Value(0),
            ),
          );
        }
      }

      final product = await productDao.getProductById(productId);

      if (product != null) {
        emit(ProductCreated(product));
        // Recargar lista de productos
        add(const ProductLoadAllRequested());
      } else {
        emit(const ProductError('Error al crear producto'));
      }
    } catch (e) {
      emit(ProductError('Error al crear producto: ${e.toString()}'));
    }
  }

  /// Actualizar producto
  Future<void> _onUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      // Validar que el código no esté duplicado (excepto el producto actual)
      final existingProduct = await productDao.getProductByCode(event.sku);
      if (existingProduct != null && existingProduct.id != event.productId) {
        emit(const ProductError('Ya existe otro producto con ese código'));
        return;
      }

      final product = await productDao.getProductById(event.productId);
      if (product == null) {
        emit(const ProductError('Producto no encontrado'));
        return;
      }

      final updatedProduct = product.copyWith(
        code: event.sku,
        name: event.name,
        description: Value(event.description),
        brand: Value(event.brand),
        category: event.category ?? 'General',
        basePrice: event.price,
        costPrice: event.cost,
        isActive: event.isActive,
        updatedAt: DateTime.now(),
      );

      await productDao.updateProduct(updatedProduct);

      emit(ProductUpdated(updatedProduct));
      // Recargar lista de productos
      add(const ProductLoadAllRequested());
    } catch (e) {
      emit(ProductError('Error al actualizar producto: ${e.toString()}'));
    }
  }

  /// Eliminar producto
  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      await productDao.deleteProduct(event.productId);
      emit(ProductDeleted(event.productId));
      // Recargar lista de productos
      add(const ProductLoadAllRequested());
    } catch (e) {
      emit(ProductError('Error al eliminar producto: ${e.toString()}'));
    }
  }

  /// Cargar variantes de un producto
  Future<void> _onVariantsLoadRequested(
    ProductVariantsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final variants = await productDao.getProductVariants(event.productId);
      emit(ProductVariantsLoaded(
        productId: event.productId,
        variants: variants,
      ));
    } catch (e) {
      emit(ProductError('Error al cargar variantes: ${e.toString()}'));
    }
  }

  /// Crear variante
  Future<void> _onVariantCreateRequested(
    ProductVariantCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final variantCompanion = ProductVariantsCompanion.insert(
        productId: event.productId,
        sku: event.additionalSku ?? '${event.productId}-${event.size}-${event.color}',
        size: Value(event.size),
        color: Value(event.color),
      );

      final variantId = await productDao.createVariant(variantCompanion);

      // Recargar variantes
      final variants = await productDao.getProductVariants(event.productId);
      final createdVariant = variants.firstWhere((v) => v.id == variantId);

      emit(ProductVariantCreated(createdVariant));
      // Recargar lista de variantes
      add(ProductVariantsLoadRequested(event.productId));
    } catch (e) {
      emit(ProductError('Error al crear variante: ${e.toString()}'));
    }
  }

  /// Eliminar variante
  Future<void> _onVariantDeleteRequested(
    ProductVariantDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      await productDao.deleteVariant(event.variantId);
      emit(ProductVariantDeleted(event.variantId));
    } catch (e) {
      emit(ProductError('Error al eliminar variante: ${e.toString()}'));
    }
  }

  /// Desactivar producto (soft delete)
  Future<void> _onDeactivateRequested(
    ProductDeactivateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      await productDao.softDeleteProduct(event.productId);
      final product = await productDao.getProductById(event.productId);

      if (product != null) {
        emit(ProductUpdated(product));
      } else {
        emit(const ProductError('Producto no encontrado'));
      }
    } catch (e) {
      emit(ProductError('Error al desactivar producto: ${e.toString()}'));
    }
  }
}
