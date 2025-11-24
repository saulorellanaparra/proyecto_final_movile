import 'package:equatable/equatable.dart';

/// Estados del ReportsBloc
abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

/// Estado con datos del dashboard
class ReportsDashboardLoaded extends ReportsState {
  final DashboardData data;

  const ReportsDashboardLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Estado con reporte de ventas
class ReportsSalesLoaded extends ReportsState {
  final SalesReportData data;

  const ReportsSalesLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Estado con productos más vendidos
class ReportsTopProductsLoaded extends ReportsState {
  final List<TopProductData> products;

  const ReportsTopProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

/// Estado con reporte de inventario
class ReportsInventoryLoaded extends ReportsState {
  final InventoryReportData data;

  const ReportsInventoryLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Estado con reporte de compras
class ReportsPurchasesLoaded extends ReportsState {
  final PurchasesReportData data;

  const ReportsPurchasesLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Estado con reporte de transferencias
class ReportsTransfersLoaded extends ReportsState {
  final TransfersReportData data;

  const ReportsTransfersLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Estado con ventas agrupadas por tienda
class ReportsSalesByStoreLoaded extends ReportsState {
  final Map<int, StoreSalesData> salesByStore;
  final double totalAllStores;
  final int totalOrdersAllStores;

  const ReportsSalesByStoreLoaded({
    required this.salesByStore,
    required this.totalAllStores,
    required this.totalOrdersAllStores,
  });

  @override
  List<Object?> get props => [salesByStore, totalAllStores, totalOrdersAllStores];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== MODELOS DE DATOS ====================

/// Datos del dashboard
class DashboardData extends Equatable {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final int lowStockItems;
  final int outOfStockItems;
  final int totalProducts;
  final double totalInventoryValue;

  const DashboardData({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.totalProducts,
    required this.totalInventoryValue,
  });

  @override
  List<Object?> get props => [
        totalSales,
        totalOrders,
        averageOrderValue,
        lowStockItems,
        outOfStockItems,
        totalProducts,
        totalInventoryValue,
      ];
}

/// Datos de reporte de ventas
class SalesReportData extends Equatable {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final Map<String, double> salesByPaymentMethod;
  final List<DailySalesData> dailySales;

  const SalesReportData({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.salesByPaymentMethod,
    required this.dailySales,
  });

  @override
  List<Object?> get props => [
        totalSales,
        totalOrders,
        averageOrderValue,
        salesByPaymentMethod,
        dailySales,
      ];
}

/// Ventas diarias
class DailySalesData extends Equatable {
  final DateTime date;
  final double amount;
  final int orders;

  const DailySalesData({
    required this.date,
    required this.amount,
    required this.orders,
  });

  @override
  List<Object?> get props => [date, amount, orders];
}

/// Producto más vendido
class TopProductData extends Equatable {
  final String productName;
  final String? variantName;
  final int quantitySold;
  final double totalRevenue;

  const TopProductData({
    required this.productName,
    this.variantName,
    required this.quantitySold,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [productName, variantName, quantitySold, totalRevenue];
}

/// Datos de reporte de inventario
class InventoryReportData extends Equatable {
  final int totalItems;
  final int lowStockItems;
  final int outOfStockItems;
  final double totalValue;
  final Map<String, int> itemsByCategory;

  const InventoryReportData({
    required this.totalItems,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.totalValue,
    required this.itemsByCategory,
  });

  @override
  List<Object?> get props => [
        totalItems,
        lowStockItems,
        outOfStockItems,
        totalValue,
        itemsByCategory,
      ];
}

/// Datos de reporte de compras
class PurchasesReportData extends Equatable {
  final double totalAmount;
  final int totalPurchases;
  final double averagePurchaseValue;
  final int pendingPurchases;
  final int receivedPurchases;
  final Map<String, double> purchasesBySupplier;
  final List<DailyPurchasesData> dailyPurchases;

  const PurchasesReportData({
    required this.totalAmount,
    required this.totalPurchases,
    required this.averagePurchaseValue,
    required this.pendingPurchases,
    required this.receivedPurchases,
    required this.purchasesBySupplier,
    required this.dailyPurchases,
  });

  @override
  List<Object?> get props => [
        totalAmount,
        totalPurchases,
        averagePurchaseValue,
        pendingPurchases,
        receivedPurchases,
        purchasesBySupplier,
        dailyPurchases,
      ];
}

/// Compras diarias
class DailyPurchasesData extends Equatable {
  final DateTime date;
  final double amount;
  final int purchases;

  const DailyPurchasesData({
    required this.date,
    required this.amount,
    required this.purchases,
  });

  @override
  List<Object?> get props => [date, amount, purchases];
}

/// Datos de reporte de transferencias
class TransfersReportData extends Equatable {
  final int totalTransfers;
  final int pendingTransfers;
  final int approvedTransfers;
  final int receivedTransfers;
  final int cancelledTransfers;
  final int outgoingTransfers;
  final int incomingTransfers;
  final Map<String, int> transfersByStatus;
  final List<DailyTransfersData> dailyTransfers;

  const TransfersReportData({
    required this.totalTransfers,
    required this.pendingTransfers,
    required this.approvedTransfers,
    required this.receivedTransfers,
    required this.cancelledTransfers,
    required this.outgoingTransfers,
    required this.incomingTransfers,
    required this.transfersByStatus,
    required this.dailyTransfers,
  });

  @override
  List<Object?> get props => [
        totalTransfers,
        pendingTransfers,
        approvedTransfers,
        receivedTransfers,
        cancelledTransfers,
        outgoingTransfers,
        incomingTransfers,
        transfersByStatus,
        dailyTransfers,
      ];
}

/// Transferencias diarias
class DailyTransfersData extends Equatable {
  final DateTime date;
  final int transfers;
  final String status;

  const DailyTransfersData({
    required this.date,
    required this.transfers,
    required this.status,
  });

  @override
  List<Object?> get props => [date, transfers, status];
}

/// Datos de ventas por tienda
class StoreSalesData extends Equatable {
  final int storeId;
  final String storeName;
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final Map<String, double> salesByPaymentMethod;
  final List<SaleItemData> sales; // Lista de ventas individuales

  const StoreSalesData({
    required this.storeId,
    required this.storeName,
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.salesByPaymentMethod,
    required this.sales,
  });

  @override
  List<Object?> get props => [
        storeId,
        storeName,
        totalSales,
        totalOrders,
        averageOrderValue,
        salesByPaymentMethod,
        sales,
      ];
}

/// Datos de una venta individual para mostrar en reportes
class SaleItemData extends Equatable {
  final int id;
  final String saleNumber;
  final DateTime saleDate;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final String status;

  const SaleItemData({
    required this.id,
    required this.saleNumber,
    required this.saleDate,
    required this.total,
    required this.paymentMethod,
    this.customerName,
    required this.status,
  });

  @override
  List<Object?> get props => [id, saleNumber, saleDate, total, paymentMethod, customerName, status];
}
