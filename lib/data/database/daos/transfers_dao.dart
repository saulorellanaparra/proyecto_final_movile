import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transfers_table.dart';

part 'transfers_dao.g.dart';

/// Data Access Object para gestión de transferencias
@DriftAccessor(tables: [Transfers, TransferDetails])
class TransfersDao extends DatabaseAccessor<AppDatabase>
    with _$TransfersDaoMixin {
  TransfersDao(AppDatabase db) : super(db);

  /// Crea una nueva transferencia con sus detalles
  Future<int> createTransfer(
    TransfersCompanion transfer,
    List<TransferDetailsCompanion> details,
  ) async {
    return await transaction(() async {
      final transferId = await into(transfers).insert(transfer);

      for (final detail in details) {
        await into(transferDetails).insert(
          detail.copyWith(transferId: Value(transferId)),
        );
      }

      return transferId;
    });
  }

  /// Obtiene todas las transferencias
  Future<List<TransferData>> getAllTransfers({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(transfers);

    if (startDate != null) {
      query.where((t) => t.transferDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.transferDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.transferDate)]);
    return query.get();
  }

  /// Obtiene transferencias por ubicación de origen
  Future<List<TransferData>> getTransfersFrom(
    String fromType,
    int fromId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(transfers)
      ..where((t) => t.fromType.equals(fromType) & t.fromId.equals(fromId));

    if (startDate != null) {
      query.where((t) => t.transferDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.transferDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.transferDate)]);
    return query.get();
  }

  /// Obtiene transferencias por ubicación de destino
  Future<List<TransferData>> getTransfersTo(
    String toType,
    int toId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(transfers)
      ..where((t) => t.toType.equals(toType) & t.toId.equals(toId));

    if (startDate != null) {
      query.where((t) => t.transferDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((t) => t.transferDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.transferDate)]);
    return query.get();
  }

  /// Obtiene transferencias pendientes de aprobación
  Future<List<TransferData>> getPendingTransfers() {
    return (select(transfers)
          ..where((t) => t.status.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Obtiene transferencias aprobadas (listas para recibir)
  Future<List<TransferData>> getApprovedTransfers() {
    return (select(transfers)
          ..where((t) => t.status.equals('APPROVED'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Obtiene una transferencia por ID
  Future<TransferData?> getTransferById(int transferId) {
    return (select(transfers)..where((t) => t.id.equals(transferId)))
        .getSingleOrNull();
  }

  /// Obtiene los detalles de una transferencia
  Future<List<TransferDetailData>> getTransferDetails(int transferId) {
    return (select(transferDetails)
          ..where((td) => td.transferId.equals(transferId)))
        .get();
  }

  /// Aprueba una transferencia
  Future<int> approveTransfer(int transferId, int userId) {
    return (update(transfers)..where((t) => t.id.equals(transferId))).write(
      TransfersCompanion(
        status: const Value('APPROVED'),
        approvedBy: Value(userId),
        approvedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marca transferencia como recibida
  Future<int> receiveTransfer(int transferId, int userId) {
    return (update(transfers)..where((t) => t.id.equals(transferId))).write(
      TransfersCompanion(
        status: const Value('RECEIVED'),
        receivedBy: Value(userId),
        receivedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Cancela una transferencia
  Future<int> cancelTransfer(int transferId) {
    return (update(transfers)..where((t) => t.id.equals(transferId))).write(
      TransfersCompanion(
        status: const Value('CANCELLED'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Stream de transferencias
  Stream<List<TransferData>> watchTransfers() {
    return (select(transfers)
          ..orderBy([(t) => OrderingTerm.desc(t.transferDate)]))
        .watch();
  }
}
