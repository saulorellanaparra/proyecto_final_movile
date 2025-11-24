import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';

/// Eventos del InventoryBloc
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar inventario por ubicación (tienda o almacén)
class InventoryLoadByLocationRequested extends InventoryEvent {
  final LocationType locationType;
  final int locationId;

  const InventoryLoadByLocationRequested({
    required this.locationType,
    required this.locationId,
  });

  @override
  List<Object?> get props => [locationType, locationId];
}

/// Cargar productos con stock bajo
class InventoryLoadLowStockRequested extends InventoryEvent {
  final LocationType locationType;
  final int locationId;

  const InventoryLoadLowStockRequested({
    required this.locationType,
    required this.locationId,
  });

  @override
  List<Object?> get props => [locationType, locationId];
}

/// Cargar productos sin stock
class InventoryLoadOutOfStockRequested extends InventoryEvent {
  final LocationType locationType;
  final int locationId;

  const InventoryLoadOutOfStockRequested({
    required this.locationType,
    required this.locationId,
  });

  @override
  List<Object?> get props => [locationType, locationId];
}

/// Ajustar cantidad de inventario manualmente
class InventoryAdjustRequested extends InventoryEvent {
  final int variantId;
  final LocationType locationType;
  final int locationId;
  final int newQuantity;
  final int userId;
  final String? notes;

  const InventoryAdjustRequested({
    required this.variantId,
    required this.locationType,
    required this.locationId,
    required this.newQuantity,
    required this.userId,
    this.notes,
  });

  @override
  List<Object?> get props => [
        variantId,
        locationType,
        locationId,
        newQuantity,
        userId,
        notes,
      ];
}

/// Cargar movimientos de inventario
class InventoryMovementsLoadRequested extends InventoryEvent {
  final LocationType locationType;
  final int locationId;
  final DateTime? startDate;
  final DateTime? endDate;

  const InventoryMovementsLoadRequested({
    required this.locationType,
    required this.locationId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [locationType, locationId, startDate, endDate];
}

/// Cargar movimientos por variante
class InventoryMovementsByVariantRequested extends InventoryEvent {
  final int variantId;
  final DateTime? startDate;
  final DateTime? endDate;

  const InventoryMovementsByVariantRequested({
    required this.variantId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [variantId, startDate, endDate];
}

/// Verificar stock disponible
class InventoryCheckStockRequested extends InventoryEvent {
  final int variantId;
  final LocationType locationType;
  final int locationId;
  final int requiredQuantity;

  const InventoryCheckStockRequested({
    required this.variantId,
    required this.locationType,
    required this.locationId,
    required this.requiredQuantity,
  });

  @override
  List<Object?> get props => [
        variantId,
        locationType,
        locationId,
        requiredQuantity,
      ];
}
