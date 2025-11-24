import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sales_table.dart';

part 'sales_dao.g.dart';

/// Data Access Object para gestión de ventas
@DriftAccessor(tables: [Sales, SaleDetails])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(AppDatabase db) : super(db);

  /// Crea una nueva venta con sus detalles
  Future<int> createSale(
    SalesCompanion sale,
    List<SaleDetailsCompanion> details,
  ) async {
    return await transaction(() async {
      final saleId = await into(sales).insert(sale);

      for (final detail in details) {
        await into(saleDetails).insert(
          detail.copyWith(saleId: Value(saleId)),
        );
      }

      return saleId;
    });
  }

  /// Obtiene todas las ventas
  Future<List<SaleData>> getAllSales() {
    return (select(sales)..orderBy([(s) => OrderingTerm.desc(s.saleDate)])).get();
  }

  /// Obtiene ventas por tienda y rango de fechas
  Future<List<SaleData>> getSalesByStore(
    int storeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(sales)..where((s) => s.storeId.equals(storeId));

    if (startDate != null) {
      query.where((s) => s.saleDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((s) => s.saleDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(s) => OrderingTerm.desc(s.saleDate)]);
    return query.get();
  }

  /// Obtiene los detalles de una venta
  Future<List<SaleDetailData>> getSaleDetails(int saleId) {
    return (select(saleDetails)..where((sd) => sd.saleId.equals(saleId)))
        .get();
  }

  /// Obtiene el total de ventas del día
  Future<double> getDailySalesTotal(int storeId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await (selectOnly(sales)
          ..addColumns([sales.total.sum()])
          ..where(
            sales.storeId.equals(storeId) &
                sales.saleDate.isBiggerOrEqualValue(startOfDay) &
                sales.saleDate.isSmallerThanValue(endOfDay) &
                sales.status.equals('COMPLETED'),
          ))
        .getSingle();

    return result.read(sales.total.sum()) ?? 0.0;
  }

  /// Cancela una venta
  Future<int> cancelSale(int saleId) {
    return (update(sales)..where((s) => s.id.equals(saleId))).write(
      SalesCompanion(
        status: const Value('CANCELLED'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Stream de ventas
  Stream<List<SaleData>> watchSalesByStore(int storeId) {
    return (select(sales)
          ..where((s) => s.storeId.equals(storeId))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .watch();
  }
}
