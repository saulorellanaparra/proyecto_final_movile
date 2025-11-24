import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados del SalesBloc
abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState {
  const SalesInitial();
}

class SalesLoading extends SalesState {
  const SalesLoading();
}

class SalesLoaded extends SalesState {
  final List<SaleData> sales;

  const SalesLoaded(this.sales);

  @override
  List<Object?> get props => [sales];
}

class SaleDetailLoaded extends SalesState {
  final SaleData sale;
  final List<SaleDetailData> details;
  final Map<int, String> productNames; // variantId -> "Producto - Talla/Color"

  const SaleDetailLoaded({
    required this.sale,
    required this.details,
    this.productNames = const {},
  });

  @override
  List<Object?> get props => [sale, details, productNames];
}

class SaleCreated extends SalesState {
  final int saleId;
  final double total;

  const SaleCreated({
    required this.saleId,
    required this.total,
  });

  @override
  List<Object?> get props => [saleId, total];
}

class SaleCancelled extends SalesState {
  final int saleId;

  const SaleCancelled(this.saleId);

  @override
  List<Object?> get props => [saleId];
}

class SalesTotalLoaded extends SalesState {
  final double total;
  final int salesCount;

  const SalesTotalLoaded({
    required this.total,
    required this.salesCount,
  });

  @override
  List<Object?> get props => [total, salesCount];
}

class SalesEmpty extends SalesState {
  const SalesEmpty();
}

/// Estado para ventas de todas las tiendas (agrupadas por tienda)
class SalesAllStoresLoaded extends SalesState {
  final Map<int, List<SaleData>> salesByStore; // storeId -> lista de ventas
  final Map<int, String> storeNames; // storeId -> nombre de tienda

  const SalesAllStoresLoaded({
    required this.salesByStore,
    required this.storeNames,
  });

  /// Obtiene todas las ventas en una lista plana
  List<SaleData> get allSales {
    final all = <SaleData>[];
    for (final sales in salesByStore.values) {
      all.addAll(sales);
    }
    all.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return all;
  }

  /// Obtiene el total de ventas de todas las tiendas
  double get totalAmount {
    double total = 0;
    for (final sales in salesByStore.values) {
      for (final sale in sales) {
        total += sale.total;
      }
    }
    return total;
  }

  /// Obtiene el conteo total de ventas
  int get totalSalesCount {
    int count = 0;
    for (final sales in salesByStore.values) {
      count += sales.length;
    }
    return count;
  }

  @override
  List<Object?> get props => [salesByStore, storeNames];
}

class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object?> get props => [message];
}
