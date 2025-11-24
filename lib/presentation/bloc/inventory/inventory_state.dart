import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/inventory_dao.dart';

/// Estados del InventoryBloc
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Cargando inventario
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// Inventario cargado exitosamente
class InventoryLoaded extends InventoryState {
  final List<InventoryData> items;

  const InventoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Inventario vacío
class InventoryEmpty extends InventoryState {
  const InventoryEmpty();
}

/// Stock bajo cargado
class InventoryLowStockLoaded extends InventoryState {
  final List<InventoryData> items;

  const InventoryLowStockLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Sin stock cargado
class InventoryOutOfStockLoaded extends InventoryState {
  final List<InventoryData> items;

  const InventoryOutOfStockLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Movimientos cargados
class InventoryMovementsLoaded extends InventoryState {
  final List<InventoryMovementData> movements;

  const InventoryMovementsLoaded(this.movements);

  @override
  List<Object?> get props => [movements];
}

/// Inventario ajustado exitosamente
class InventoryAdjusted extends InventoryState {
  final int variantId;
  final int newQuantity;

  const InventoryAdjusted({
    required this.variantId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [variantId, newQuantity];
}

/// Stock verificado
class InventoryStockChecked extends InventoryState {
  final bool hasStock;
  final int availableQuantity;

  const InventoryStockChecked({
    required this.hasStock,
    required this.availableQuantity,
  });

  @override
  List<Object?> get props => [hasStock, availableQuantity];
}

/// Error en inventario
class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== ESTADOS CON INFORMACIÓN ENRIQUECIDA ====================

/// Inventario cargado con información completa del producto
class InventoryLoadedWithProductInfo extends InventoryState {
  final List<InventoryWithProductInfo> items;

  const InventoryLoadedWithProductInfo(this.items);

  @override
  List<Object?> get props => [items];
}

/// Stock bajo cargado con información completa del producto
class InventoryLowStockLoadedWithProductInfo extends InventoryState {
  final List<InventoryWithProductInfo> items;

  const InventoryLowStockLoadedWithProductInfo(this.items);

  @override
  List<Object?> get props => [items];
}

/// Sin stock cargado con información completa del producto
class InventoryOutOfStockLoadedWithProductInfo extends InventoryState {
  final List<InventoryWithProductInfo> items;

  const InventoryOutOfStockLoadedWithProductInfo(this.items);

  @override
  List<Object?> get props => [items];
}
