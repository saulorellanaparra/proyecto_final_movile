import 'package:equatable/equatable.dart';

/// Eventos del PurchasesBloc
abstract class PurchasesEvent extends Equatable {
  const PurchasesEvent();

  @override
  List<Object?> get props => [];
}

/// Item de compra para crear una compra
class PurchaseItem extends Equatable {
  final int variantId;
  final int quantity;
  final double unitCost;
  final String? productName;
  final String? variantDescription;

  const PurchaseItem({
    required this.variantId,
    required this.quantity,
    required this.unitCost,
    this.productName,
    this.variantDescription,
  });

  double get total => quantity * unitCost;

  @override
  List<Object?> get props => [variantId, quantity, unitCost, productName, variantDescription];
}

/// Cargar compras por almacén
class PurchasesLoadByWarehouseRequested extends PurchasesEvent {
  final int warehouseId;
  final DateTime? startDate;
  final DateTime? endDate;

  const PurchasesLoadByWarehouseRequested({
    required this.warehouseId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [warehouseId, startDate, endDate];
}

/// Cargar detalles de una compra
class PurchaseDetailsLoadRequested extends PurchasesEvent {
  final int purchaseId;

  const PurchaseDetailsLoadRequested(this.purchaseId);

  @override
  List<Object?> get props => [purchaseId];
}

/// Crear nueva compra
class PurchaseCreateRequested extends PurchasesEvent {
  final int warehouseId;
  final String supplierName;
  final String? supplierRuc;
  final String? supplierPhone;
  final String? supplierEmail;
  final int userId;
  final List<PurchaseItem> items;
  final String? notes;

  const PurchaseCreateRequested({
    required this.warehouseId,
    required this.supplierName,
    this.supplierRuc,
    this.supplierPhone,
    this.supplierEmail,
    required this.userId,
    required this.items,
    this.notes,
  });

  @override
  List<Object?> get props => [
        warehouseId,
        supplierName,
        supplierRuc,
        supplierPhone,
        supplierEmail,
        userId,
        items,
        notes,
      ];
}

/// Marcar compra como recibida
class PurchaseMarkAsReceivedRequested extends PurchasesEvent {
  final int purchaseId;
  final int warehouseId;
  final int userId;

  const PurchaseMarkAsReceivedRequested({
    required this.purchaseId,
    required this.warehouseId,
    required this.userId,
  });

  @override
  List<Object?> get props => [purchaseId, warehouseId, userId];
}
