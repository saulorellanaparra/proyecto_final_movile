import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/database/daos/sales_dao.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../data/database/daos/product_dao.dart';
import '../../../data/database/daos/purchases_dao.dart';
import '../../../data/database/daos/transfers_dao.dart';
import '../../../data/database/daos/stores_dao.dart';
import 'reports_event.dart';
import 'reports_state.dart';

/// BLoC para gestión de reportes y estadísticas
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final SalesDao salesDao;
  final InventoryDao inventoryDao;
  final ProductDao productDao;
  final PurchasesDao purchasesDao;
  final TransfersDao transfersDao;
  final StoresDao? storesDao;

  ReportsBloc({
    required this.salesDao,
    required this.inventoryDao,
    required this.productDao,
    required this.purchasesDao,
    required this.transfersDao,
    this.storesDao,
  }) : super(const ReportsInitial()) {
    on<ReportsLoadDashboardRequested>(_onLoadDashboard);
    on<ReportsLoadSalesRequested>(_onLoadSales);
    on<ReportsLoadTopProductsRequested>(_onLoadTopProducts);
    on<ReportsLoadInventoryRequested>(_onLoadInventory);
    on<ReportsLoadPurchasesRequested>(_onLoadPurchases);
    on<ReportsLoadTransfersRequested>(_onLoadTransfers);
    on<ReportsLoadSalesByStoreRequested>(_onLoadSalesByStore);
  }

  Future<void> _onLoadDashboard(
    ReportsLoadDashboardRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      // Calcular ventas totales
      final sales = await salesDao.getAllSales();
      final filteredSales = _filterByDate(sales, event.startDate, event.endDate);

      final totalSales = filteredSales.fold<double>(
        0,
        (sum, sale) => sum + sale.total,
      );
      final totalOrders = filteredSales.length;
      final averageOrderValue = totalOrders > 0 ? (totalSales / totalOrders).toDouble() : 0.0;

      // Obtener estadísticas de inventario
      final allInventory = await inventoryDao.getAllInventory();
      final lowStockItems = allInventory.where((inv) {
        return inv.quantity > 0 && inv.quantity <= 10;
      }).length;
      final outOfStockItems = allInventory.where((inv) => inv.quantity == 0).length;

      // Productos totales
      final products = await productDao.getAllProducts();
      final totalProducts = products.length;

      // Valor total de inventario (simplificado)
      final totalInventoryValue = allInventory.fold<double>(
        0,
        (sum, inv) => sum + (inv.quantity * 100.0), // Estimado
      );

      emit(ReportsDashboardLoaded(
        DashboardData(
          totalSales: totalSales,
          totalOrders: totalOrders,
          averageOrderValue: averageOrderValue,
          lowStockItems: lowStockItems,
          outOfStockItems: outOfStockItems,
          totalProducts: totalProducts,
          totalInventoryValue: totalInventoryValue,
        ),
      ));
    } catch (e) {
      emit(ReportsError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSales(
    ReportsLoadSalesRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final sales = await salesDao.getAllSales();
      var filteredSales = _filterByDate(sales, event.startDate, event.endDate);

      if (event.storeId != null) {
        filteredSales = filteredSales.where((s) => s.storeId == event.storeId).toList();
      }

      final totalSales = filteredSales.fold<double>(0, (sum, sale) => sum + sale.total);
      final totalOrders = filteredSales.length;
      final averageOrderValue = totalOrders > 0 ? (totalSales / totalOrders).toDouble() : 0.0;

      // Ventas por método de pago
      final salesByPaymentMethod = <String, double>{};
      for (final sale in filteredSales) {
        salesByPaymentMethod[sale.paymentMethod] =
            (salesByPaymentMethod[sale.paymentMethod] ?? 0) + sale.total;
      }

      // Ventas diarias
      final dailySalesMap = <String, DailySalesData>{};
      for (final sale in filteredSales) {
        final dateKey = '${sale.saleDate.year}-${sale.saleDate.month}-${sale.saleDate.day}';
        if (dailySalesMap.containsKey(dateKey)) {
          final existing = dailySalesMap[dateKey]!;
          dailySalesMap[dateKey] = DailySalesData(
            date: existing.date,
            amount: existing.amount + sale.total,
            orders: existing.orders + 1,
          );
        } else {
          dailySalesMap[dateKey] = DailySalesData(
            date: DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day),
            amount: sale.total,
            orders: 1,
          );
        }
      }

      final dailySales = dailySalesMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      emit(ReportsSalesLoaded(
        SalesReportData(
          totalSales: totalSales,
          totalOrders: totalOrders,
          averageOrderValue: averageOrderValue,
          salesByPaymentMethod: salesByPaymentMethod,
          dailySales: dailySales,
        ),
      ));
    } catch (e) {
      emit(ReportsError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTopProducts(
    ReportsLoadTopProductsRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final sales = await salesDao.getAllSales();
      final filteredSales = _filterByDate(sales, event.startDate, event.endDate);

      // Obtener detalles de ventas para cada venta
      final productSales = <int, TopProductData>{};

      for (final sale in filteredSales) {
        final details = await salesDao.getSaleDetails(sale.id);

        for (final detail in details) {
          if (productSales.containsKey(detail.productVariantId)) {
            final existing = productSales[detail.productVariantId]!;
            productSales[detail.productVariantId] = TopProductData(
              productName: existing.productName,
              variantName: existing.variantName,
              quantitySold: existing.quantitySold + detail.quantity,
              totalRevenue: existing.totalRevenue + detail.subtotal,
            );
          } else {
            // Obtener info del producto (simplificado)
            productSales[detail.productVariantId] = TopProductData(
              productName: 'Producto #${detail.productVariantId}',
              variantName: null,
              quantitySold: detail.quantity,
              totalRevenue: detail.subtotal,
            );
          }
        }
      }

      // Ordenar por cantidad vendida
      final topProducts = productSales.values.toList()
        ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

      emit(ReportsTopProductsLoaded(
        topProducts.take(event.limit).toList(),
      ));
    } catch (e) {
      emit(ReportsError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadInventory(
    ReportsLoadInventoryRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      var inventory = await inventoryDao.getAllInventory();

      if (event.locationId != null && event.locationType != null) {
        inventory = inventory.where((inv) {
          return inv.locationId == event.locationId &&
              inv.locationType == event.locationType;
        }).toList();
      }

      final totalItems = inventory.length;
      final lowStockItems = inventory.where((inv) {
        return inv.quantity > 0 && inv.quantity <= 10;
      }).length;
      final outOfStockItems = inventory.where((inv) => inv.quantity == 0).length;

      final totalValue = inventory.fold<double>(
        0,
        (sum, inv) => sum + (inv.quantity * 100.0), // Estimado
      );

      // Items por categoría (simplificado)
      final itemsByCategory = <String, int>{
        'En Stock': inventory.where((inv) => inv.quantity > 10).length,
        'Stock Bajo': lowStockItems,
        'Sin Stock': outOfStockItems,
      };

      emit(ReportsInventoryLoaded(
        InventoryReportData(
          totalItems: totalItems,
          lowStockItems: lowStockItems,
          outOfStockItems: outOfStockItems,
          totalValue: totalValue,
          itemsByCategory: itemsByCategory,
        ),
      ));
    } catch (e) {
      emit(ReportsError('Error: ${e.toString()}'));
    }
  }

  /// Cargar reporte de compras
  Future<void> _onLoadPurchases(
    ReportsLoadPurchasesRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      // Obtener compras del almacén (o todas si no se especifica)
      final purchases = event.warehouseId != null
          ? await purchasesDao.getPurchasesByWarehouse(
              event.warehouseId!,
              startDate: event.startDate,
              endDate: event.endDate,
            )
          : await purchasesDao.getAllPurchases(
              startDate: event.startDate,
              endDate: event.endDate,
            );

      // Calcular totales
      final totalAmount = purchases.fold<double>(0, (sum, p) => sum + p.totalAmount);
      final totalPurchases = purchases.length;
      final averagePurchaseValue = totalPurchases > 0 ? totalAmount / totalPurchases : 0.0;

      // Contar por estado
      final pendingPurchases = purchases.where((p) => p.status == 'PENDING').length;
      final receivedPurchases = purchases.where((p) => p.status == 'RECEIVED').length;

      // Compras por proveedor
      final purchasesBySupplier = <String, double>{};
      for (final purchase in purchases) {
        purchasesBySupplier[purchase.supplierName] =
            (purchasesBySupplier[purchase.supplierName] ?? 0) + purchase.totalAmount;
      }

      // Compras diarias
      final dailyPurchasesMap = <String, DailyPurchasesData>{};
      for (final purchase in purchases) {
        final dateKey =
            '${purchase.purchaseDate.year}-${purchase.purchaseDate.month}-${purchase.purchaseDate.day}';
        if (dailyPurchasesMap.containsKey(dateKey)) {
          final existing = dailyPurchasesMap[dateKey]!;
          dailyPurchasesMap[dateKey] = DailyPurchasesData(
            date: existing.date,
            amount: existing.amount + purchase.totalAmount,
            purchases: existing.purchases + 1,
          );
        } else {
          dailyPurchasesMap[dateKey] = DailyPurchasesData(
            date: DateTime(
              purchase.purchaseDate.year,
              purchase.purchaseDate.month,
              purchase.purchaseDate.day,
            ),
            amount: purchase.totalAmount,
            purchases: 1,
          );
        }
      }

      final dailyPurchases = dailyPurchasesMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      emit(ReportsPurchasesLoaded(
        PurchasesReportData(
          totalAmount: totalAmount,
          totalPurchases: totalPurchases,
          averagePurchaseValue: averagePurchaseValue,
          pendingPurchases: pendingPurchases,
          receivedPurchases: receivedPurchases,
          purchasesBySupplier: purchasesBySupplier,
          dailyPurchases: dailyPurchases,
        ),
      ));
    } catch (e) {
      emit(ReportsError('Error al cargar reporte de compras: ${e.toString()}'));
    }
  }

  /// Cargar reporte de transferencias
  Future<void> _onLoadTransfers(
    ReportsLoadTransfersRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      List<dynamic> transfers = [];

      // Obtener transferencias según filtros
      if (event.locationId != null && event.locationType != null) {
        if (event.direction == 'outgoing') {
          transfers = await transfersDao.getTransfersFrom(
            event.locationType!,
            event.locationId!,
            startDate: event.startDate,
            endDate: event.endDate,
          );
        } else if (event.direction == 'incoming') {
          transfers = await transfersDao.getTransfersTo(
            event.locationType!,
            event.locationId!,
            startDate: event.startDate,
            endDate: event.endDate,
          );
        } else {
          // Ambas direcciones
          final outgoing = await transfersDao.getTransfersFrom(
            event.locationType!,
            event.locationId!,
            startDate: event.startDate,
            endDate: event.endDate,
          );
          final incoming = await transfersDao.getTransfersTo(
            event.locationType!,
            event.locationId!,
            startDate: event.startDate,
            endDate: event.endDate,
          );
          transfers = [...outgoing, ...incoming];
        }
      } else {
        // Todas las transferencias
        transfers = await transfersDao.getAllTransfers(
          startDate: event.startDate,
          endDate: event.endDate,
        );
      }

      // Calcular estadísticas
      final totalTransfers = transfers.length;
      final pendingTransfers = transfers.where((t) => t.status == 'PENDING').length;
      final approvedTransfers = transfers.where((t) => t.status == 'APPROVED').length;
      final receivedTransfers = transfers.where((t) => t.status == 'RECEIVED').length;
      final cancelledTransfers = transfers.where((t) => t.status == 'CANCELLED').length;

      // Contar salientes y entrantes
      int outgoingTransfers = 0;
      int incomingTransfers = 0;
      if (event.locationId != null && event.locationType != null) {
        outgoingTransfers = transfers.where((t) {
          return t.fromType == event.locationType && t.fromId == event.locationId;
        }).length;
        incomingTransfers = transfers.where((t) {
          return t.toType == event.locationType && t.toId == event.locationId;
        }).length;
      }

      // Transferencias por estado
      final transfersByStatus = <String, int>{
        'PENDING': pendingTransfers,
        'APPROVED': approvedTransfers,
        'RECEIVED': receivedTransfers,
        'CANCELLED': cancelledTransfers,
      };

      // Transferencias diarias por estado
      final dailyTransfersMap = <String, Map<String, int>>{};
      for (final transfer in transfers) {
        final dateKey =
            '${transfer.transferDate.year}-${transfer.transferDate.month}-${transfer.transferDate.day}';
        if (!dailyTransfersMap.containsKey(dateKey)) {
          dailyTransfersMap[dateKey] = {};
        }
        final statusCount = dailyTransfersMap[dateKey]!;
        statusCount[transfer.status] = (statusCount[transfer.status] ?? 0) + 1;
      }

      // Convertir a lista de DailyTransfersData
      final dailyTransfers = <DailyTransfersData>[];
      dailyTransfersMap.forEach((dateKey, statusMap) {
        final parts = dateKey.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        statusMap.forEach((status, count) {
          dailyTransfers.add(DailyTransfersData(
            date: date,
            transfers: count,
            status: status,
          ));
        });
      });

      dailyTransfers.sort((a, b) => a.date.compareTo(b.date));

      emit(ReportsTransfersLoaded(
        TransfersReportData(
          totalTransfers: totalTransfers,
          pendingTransfers: pendingTransfers,
          approvedTransfers: approvedTransfers,
          receivedTransfers: receivedTransfers,
          cancelledTransfers: cancelledTransfers,
          outgoingTransfers: outgoingTransfers,
          incomingTransfers: incomingTransfers,
          transfersByStatus: transfersByStatus,
          dailyTransfers: dailyTransfers,
        ),
      ));
    } catch (e) {
      emit(ReportsError('Error al cargar reporte de transferencias: ${e.toString()}'));
    }
  }

  /// Cargar ventas agrupadas por tienda
  Future<void> _onLoadSalesByStore(
    ReportsLoadSalesByStoreRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      if (storesDao == null) {
        emit(const ReportsError('No se puede acceder a las tiendas'));
        return;
      }

      // Obtener todas las tiendas
      final stores = await storesDao!.getAllStores();

      // Obtener todas las ventas
      final allSales = await salesDao.getAllSales();
      final filteredSales = _filterByDate(allSales, event.startDate, event.endDate);

      // Agrupar ventas por tienda
      final Map<int, StoreSalesData> salesByStore = {};
      double totalAllStores = 0;
      int totalOrdersAllStores = 0;

      for (final store in stores) {
        final storeSales = filteredSales.where((s) => s.storeId == store.id).toList();

        if (storeSales.isEmpty) continue;

        final totalSales = storeSales.fold<double>(0, (sum, sale) => sum + sale.total);
        final totalOrders = storeSales.length;
        final averageOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;

        // Ventas por método de pago
        final salesByPaymentMethod = <String, double>{};
        for (final sale in storeSales) {
          salesByPaymentMethod[sale.paymentMethod] =
              (salesByPaymentMethod[sale.paymentMethod] ?? 0) + sale.total;
        }

        // Convertir ventas a SaleItemData
        final saleItems = storeSales.map((sale) => SaleItemData(
          id: sale.id,
          saleNumber: sale.saleNumber,
          saleDate: sale.saleDate,
          total: sale.total,
          paymentMethod: sale.paymentMethod,
          customerName: sale.customerName,
          status: sale.status,
        )).toList();

        // Ordenar por fecha descendente
        saleItems.sort((a, b) => b.saleDate.compareTo(a.saleDate));

        salesByStore[store.id] = StoreSalesData(
          storeId: store.id,
          storeName: store.name,
          totalSales: totalSales,
          totalOrders: totalOrders,
          averageOrderValue: averageOrderValue,
          salesByPaymentMethod: salesByPaymentMethod,
          sales: saleItems,
        );

        totalAllStores += totalSales;
        totalOrdersAllStores += totalOrders;
      }

      if (salesByStore.isEmpty) {
        emit(const ReportsError('No hay ventas en el período seleccionado'));
        return;
      }

      emit(ReportsSalesByStoreLoaded(
        salesByStore: salesByStore,
        totalAllStores: totalAllStores,
        totalOrdersAllStores: totalOrdersAllStores,
      ));
    } catch (e) {
      emit(ReportsError('Error al cargar ventas por tienda: ${e.toString()}'));
    }
  }

  List<T> _filterByDate<T>(
    List<T> items,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return items;

    return items.where((item) {
      DateTime? itemDate;

      // Determinar la fecha del item basado en su tipo
      if (item is dynamic) {
        try {
          itemDate = item.saleDate as DateTime?;
        } catch (_) {
          try {
            itemDate = item.createdAt as DateTime?;
          } catch (_) {
            return true; // Si no tiene fecha, incluirlo
          }
        }
      }

      if (itemDate == null) return true;

      if (startDate != null && itemDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && itemDate.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }
}
