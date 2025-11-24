import 'package:equatable/equatable.dart';

/// Eventos del SalesBloc
abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar ventas del día por tienda
class SalesLoadTodayByStoreRequested extends SalesEvent {
  final int storeId;

  const SalesLoadTodayByStoreRequested(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

/// Cargar ventas por rango de fechas
class SalesLoadByDateRangeRequested extends SalesEvent {
  final int storeId;
  final DateTime startDate;
  final DateTime endDate;

  const SalesLoadByDateRangeRequested({
    required this.storeId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [storeId, startDate, endDate];
}

/// Cargar venta por ID
class SalesLoadByIdRequested extends SalesEvent {
  final int saleId;

  const SalesLoadByIdRequested(this.saleId);

  @override
  List<Object?> get props => [saleId];
}

/// Crear nueva venta
class SalesCreateRequested extends SalesEvent {
  final int storeId;
  final int userId;
  final List<SaleItem> items;
  final String? customerName;
  final String? customerDocument;
  final String? customerPhone;
  final String paymentMethod;

  const SalesCreateRequested({
    required this.storeId,
    required this.userId,
    required this.items,
    this.customerName,
    this.customerDocument,
    this.customerPhone,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [
        storeId,
        userId,
        items,
        customerName,
        customerDocument,
        customerPhone,
        paymentMethod,
      ];
}

/// Anular venta
class SalesCancelRequested extends SalesEvent {
  final int saleId;
  final String reason;

  const SalesCancelRequested({
    required this.saleId,
    required this.reason,
  });

  @override
  List<Object?> get props => [saleId, reason];
}

/// Obtener total del día
class SalesGetDailyTotalRequested extends SalesEvent {
  final int storeId;

  const SalesGetDailyTotalRequested(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

/// Cargar todas las ventas de todas las tiendas (para encargados de almacén)
class SalesLoadAllStoresRequested extends SalesEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const SalesLoadAllStoresRequested({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Clase auxiliar para items de venta
class SaleItem extends Equatable {
  final int variantId;
  final int quantity;
  final double unitPrice;
  final String? productName;
  final String? variantDescription;

  const SaleItem({
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    this.productName,
    this.variantDescription,
  });

  double get total => quantity * unitPrice;

  @override
  List<Object?> get props => [variantId, quantity, unitPrice, productName, variantDescription];
}
