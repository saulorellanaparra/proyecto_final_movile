import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/purchases_table.dart';

part 'purchases_dao.g.dart';

/// Data Access Object para gestión de compras
@DriftAccessor(tables: [Purchases, PurchaseDetails])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(AppDatabase db) : super(db);

  /// Crea una nueva compra con sus detalles
  Future<int> createPurchase(
    PurchasesCompanion purchase,
    List<PurchaseDetailsCompanion> details,
  ) async {
    return await transaction(() async {
      final purchaseId = await into(purchases).insert(purchase);

      for (final detail in details) {
        await into(purchaseDetails).insert(
          detail.copyWith(purchaseId: Value(purchaseId)),
        );
      }

      return purchaseId;
    });
  }

  /// Obtiene todas las compras
  Future<List<PurchaseData>> getAllPurchases({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(purchases);

    if (startDate != null) {
      query.where((p) => p.purchaseDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((p) => p.purchaseDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]);
    return query.get();
  }

  /// Obtiene compras por almacén
  Future<List<PurchaseData>> getPurchasesByWarehouse(
    int warehouseId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(purchases)
      ..where((p) => p.warehouseId.equals(warehouseId));

    if (startDate != null) {
      query.where((p) => p.purchaseDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((p) => p.purchaseDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]);
    return query.get();
  }

  /// Obtiene los detalles de una compra
  Future<List<PurchaseDetailData>> getPurchaseDetails(int purchaseId) {
    return (select(purchaseDetails)
          ..where((pd) => pd.purchaseId.equals(purchaseId)))
        .get();
  }

  /// Marca una compra como recibida
  Future<int> markAsReceived(int purchaseId) {
    return (update(purchases)..where((p) => p.id.equals(purchaseId))).write(
      PurchasesCompanion(
        status: const Value('RECEIVED'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Stream de compras
  Stream<List<PurchaseData>> watchPurchasesByWarehouse(int warehouseId) {
    return (select(purchases)
          ..where((p) => p.warehouseId.equals(warehouseId))
          ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
        .watch();
  }
}
