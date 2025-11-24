import 'package:equatable/equatable.dart';

/// Eventos del ReportsBloc
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object?> get props => [];
}

/// Cargar dashboard con KPIs generales
class ReportsLoadDashboardRequested extends ReportsEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportsLoadDashboardRequested({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Cargar reporte de ventas
class ReportsLoadSalesRequested extends ReportsEvent {
  final int? storeId;
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportsLoadSalesRequested({
    this.storeId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [storeId, startDate, endDate];
}

/// Cargar reporte de productos más vendidos
class ReportsLoadTopProductsRequested extends ReportsEvent {
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportsLoadTopProductsRequested({
    this.limit = 10,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [limit, startDate, endDate];
}

/// Cargar reporte de inventario
class ReportsLoadInventoryRequested extends ReportsEvent {
  final int? locationId;
  final String? locationType;

  const ReportsLoadInventoryRequested({
    this.locationId,
    this.locationType,
  });

  @override
  List<Object?> get props => [locationId, locationType];
}

/// Cargar reporte de compras
class ReportsLoadPurchasesRequested extends ReportsEvent {
  final int? warehouseId;
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportsLoadPurchasesRequested({
    this.warehouseId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [warehouseId, startDate, endDate];
}

/// Cargar reporte de transferencias
class ReportsLoadTransfersRequested extends ReportsEvent {
  final int? locationId;
  final String? locationType;
  final String? direction; // 'outgoing', 'incoming', or null for both
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportsLoadTransfersRequested({
    this.locationId,
    this.locationType,
    this.direction,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [locationId, locationType, direction, startDate, endDate];
}

/// Cargar ventas agrupadas por tienda (para encargados de almacén y gerentes)
class ReportsLoadSalesByStoreRequested extends ReportsEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const ReportsLoadSalesByStoreRequested({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}
