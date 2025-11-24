import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados del ProductBloc
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Cargando productos
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// Productos cargados exitosamente
class ProductsLoaded extends ProductState {
  final List<ProductData> products;

  const ProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

/// Producto individual cargado
class ProductLoaded extends ProductState {
  final ProductData product;

  const ProductLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

/// Variantes cargadas
class ProductVariantsLoaded extends ProductState {
  final int productId;
  final List<ProductVariantData> variants;

  const ProductVariantsLoaded({
    required this.productId,
    required this.variants,
  });

  @override
  List<Object?> get props => [productId, variants];
}

/// Producto creado exitosamente
class ProductCreated extends ProductState {
  final ProductData product;

  const ProductCreated(this.product);

  @override
  List<Object?> get props => [product];
}

/// Producto actualizado exitosamente
class ProductUpdated extends ProductState {
  final ProductData product;

  const ProductUpdated(this.product);

  @override
  List<Object?> get props => [product];
}

/// Producto eliminado exitosamente
class ProductDeleted extends ProductState {
  final int productId;

  const ProductDeleted(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Variante creada
class ProductVariantCreated extends ProductState {
  final ProductVariantData variant;

  const ProductVariantCreated(this.variant);

  @override
  List<Object?> get props => [variant];
}

/// Variante eliminada
class ProductVariantDeleted extends ProductState {
  final int variantId;

  const ProductVariantDeleted(this.variantId);

  @override
  List<Object?> get props => [variantId];
}

/// Error
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado vacío (sin productos)
class ProductEmpty extends ProductState {
  const ProductEmpty();
}
