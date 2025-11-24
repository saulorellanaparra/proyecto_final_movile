import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';

/// Eventos del TransfersBloc
abstract class TransfersEvent extends Equatable {
  const TransfersEvent();
  @override
  List<Object?> get props => [];
}

/// Item de transferencia
class TransferItem extends Equatable {
  final int variantId;
  final int quantity;
  final String? productName; // Nombre del producto (para mostrar en UI)
  final String? sku; // SKU del producto (para mostrar en UI)

  const TransferItem({
    required this.variantId,
    required this.quantity,
    this.productName,
    this.sku,
  });

  @override
  List<Object?> get props => [variantId, quantity, productName, sku];
}

/// Cargar transferencias salientes
class TransfersLoadOutgoingRequested extends TransfersEvent {
  final LocationType locationType;
  final int locationId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransfersLoadOutgoingRequested({
    required this.locationType,
    required this.locationId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [locationType, locationId, startDate, endDate];
}

/// Cargar transferencias entrantes
class TransfersLoadIncomingRequested extends TransfersEvent {
  final LocationType locationType;
  final int locationId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransfersLoadIncomingRequested({
    required this.locationType,
    required this.locationId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [locationType, locationId, startDate, endDate];
}

/// Cargar transferencias pendientes
class TransfersLoadPendingRequested extends TransfersEvent {
  const TransfersLoadPendingRequested();
}

/// Cargar detalles de transferencia
class TransferDetailsLoadRequested extends TransfersEvent {
  final int transferId;

  const TransferDetailsLoadRequested(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

/// Crear nueva transferencia
class TransferCreateRequested extends TransfersEvent {
  final LocationType fromType;
  final int fromId;
  final LocationType toType;
  final int toId;
  final int userId;
  final List<TransferItem> items;
  final String? notes;

  const TransferCreateRequested({
    required this.fromType,
    required this.fromId,
    required this.toType,
    required this.toId,
    required this.userId,
    required this.items,
    this.notes,
  });

  @override
  List<Object?> get props => [fromType, fromId, toType, toId, userId, items, notes];
}

/// Aprobar transferencia
class TransferApproveRequested extends TransfersEvent {
  final int transferId;
  final int userId;

  const TransferApproveRequested(this.transferId, this.userId);

  @override
  List<Object?> get props => [transferId, userId];
}

/// Recibir transferencia
class TransferReceiveRequested extends TransfersEvent {
  final int transferId;
  final int userId;
  final LocationType toType;
  final int toId;

  const TransferReceiveRequested({
    required this.transferId,
    required this.userId,
    required this.toType,
    required this.toId,
  });

  @override
  List<Object?> get props => [transferId, userId, toType, toId];
}

/// Cancelar transferencia
class TransferCancelRequested extends TransfersEvent {
  final int transferId;

  const TransferCancelRequested(this.transferId);

  @override
  List<Object?> get props => [transferId];
}
