import 'package:equatable/equatable.dart';

/// Eventos del ProductBloc
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar todos los productos
class ProductLoadAllRequested extends ProductEvent {
  const ProductLoadAllRequested();
}

/// Cargar solo productos activos
class ProductLoadActiveRequested extends ProductEvent {
  const ProductLoadActiveRequested();
}

/// Cargar solo productos inactivos
class ProductLoadInactiveRequested extends ProductEvent {
  const ProductLoadInactiveRequested();
}

/// Buscar productos por término
class ProductSearchRequested extends ProductEvent {
  final String searchTerm;

  const ProductSearchRequested(this.searchTerm);

  @override
  List<Object?> get props => [searchTerm];
}

/// Cargar productos de una ubicación específica
class ProductLoadByLocationRequested extends ProductEvent {
  final String locationType;
  final int locationId;

  const ProductLoadByLocationRequested({
    required this.locationType,
    required this.locationId,
  });

  @override
  List<Object?> get props => [locationType, locationId];
}

/// Buscar productos en una ubicación específica
class ProductSearchByLocationRequested extends ProductEvent {
  final String searchTerm;
  final String locationType;
  final int locationId;

  const ProductSearchByLocationRequested({
    required this.searchTerm,
    required this.locationType,
    required this.locationId,
  });

  @override
  List<Object?> get props => [searchTerm, locationType, locationId];
}

/// Cargar un producto por ID
class ProductLoadByIdRequested extends ProductEvent {
  final int productId;

  const ProductLoadByIdRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Crear nuevo producto
class ProductCreateRequested extends ProductEvent {
  final String name;
  final String? description;
  final String sku;
  final double cost;
  final double price;
  final String? category;
  final String? brand;
  final bool isActive;
  final int? userStoreId;       // ID de la tienda del usuario (si es encargado de tienda)
  final int? userWarehouseId;   // ID del almacén del usuario (si es encargado de almacén)

  const ProductCreateRequested({
    required this.name,
    this.description,
    required this.sku,
    required this.cost,
    required this.price,
    this.category,
    this.brand,
    this.isActive = true,
    this.userStoreId,
    this.userWarehouseId,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        sku,
        cost,
        price,
        category,
        brand,
        isActive,
        userStoreId,
        userWarehouseId,
      ];
}

/// Actualizar producto existente
class ProductUpdateRequested extends ProductEvent {
  final int productId;
  final String name;
  final String? description;
  final String sku;
  final double cost;
  final double price;
  final String? category;
  final String? brand;
  final bool isActive;

  const ProductUpdateRequested({
    required this.productId,
    required this.name,
    this.description,
    required this.sku,
    required this.cost,
    required this.price,
    this.category,
    this.brand,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        productId,
        name,
        description,
        sku,
        cost,
        price,
        category,
        brand,
        isActive,
      ];
}

/// Eliminar producto
class ProductDeleteRequested extends ProductEvent {
  final int productId;

  const ProductDeleteRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Cargar variantes de un producto
class ProductVariantsLoadRequested extends ProductEvent {
  final int productId;

  const ProductVariantsLoadRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Crear nueva variante
class ProductVariantCreateRequested extends ProductEvent {
  final int productId;
  final String size;
  final String color;
  final String? additionalSku;

  const ProductVariantCreateRequested({
    required this.productId,
    required this.size,
    required this.color,
    this.additionalSku,
  });

  @override
  List<Object?> get props => [productId, size, color, additionalSku];
}

/// Eliminar variante
class ProductVariantDeleteRequested extends ProductEvent {
  final int variantId;

  const ProductVariantDeleteRequested(this.variantId);

  @override
  List<Object?> get props => [variantId];
}

/// Desactivar producto (soft delete)
class ProductDeactivateRequested extends ProductEvent {
  final int productId;

  const ProductDeactivateRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}
