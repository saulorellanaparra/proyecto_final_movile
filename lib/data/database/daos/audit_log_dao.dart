import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/audit_log_table.dart';

part 'audit_log_dao.g.dart';

/// DAO para operaciones con la tabla de auditoría
@DriftAccessor(tables: [AuditLog])
class AuditLogDao extends DatabaseAccessor<AppDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(AppDatabase db) : super(db);

  /// Registra una nueva acción de auditoría
  Future<int> logAction({
    required int userId,
    required String action,
    required String description,
    String? entityType,
    int? entityId,
    String? oldValues,
    String? newValues,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    return into(auditLog).insert(
      AuditLogCompanion.insert(
        userId: userId,
        action: action,
        description: description,
        entityType: Value(entityType),
        entityId: Value(entityId),
        oldValues: Value(oldValues),
        newValues: Value(newValues),
        ipAddress: Value(ipAddress),
        deviceInfo: Value(deviceInfo),
      ),
    );
  }

  /// Obtiene todos los registros de auditoría ordenados por fecha descendente
  Future<List<AuditLogData>> getAllAuditLogs({
    int? limit,
    int? offset,
  }) async {
    final query = select(auditLog)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene registros de auditoría por usuario
  Future<List<AuditLogData>> getAuditLogsByUser(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    final query = select(auditLog)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene registros de auditoría por tipo de acción
  Future<List<AuditLogData>> getAuditLogsByAction(
    String action, {
    int? limit,
    int? offset,
  }) async {
    final query = select(auditLog)
      ..where((t) => t.action.equals(action))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene registros de auditoría por tipo de entidad
  Future<List<AuditLogData>> getAuditLogsByEntityType(
    String entityType, {
    int? limit,
    int? offset,
  }) async {
    final query = select(auditLog)
      ..where((t) => t.entityType.equals(entityType))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene registros de auditoría para una entidad específica
  Future<List<AuditLogData>> getAuditLogsForEntity(
    String entityType,
    int entityId,
  ) async {
    return (select(auditLog)
          ..where((t) =>
              t.entityType.equals(entityType) & t.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Obtiene registros de auditoría en un rango de fechas
  Future<List<AuditLogData>> getAuditLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
  }) async {
    final query = select(auditLog)
      ..where((t) =>
          t.createdAt.isBiggerOrEqualValue(startDate) &
          t.createdAt.isSmallerOrEqualValue(endDate))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene el conteo de acciones por tipo
  Future<Map<String, int>> getActionsCounts() async {
    final query = selectOnly(auditLog)
      ..addColumns([auditLog.action])
      ..addColumns([auditLog.id.count()]);

    final result = await query.get();

    final Map<String, int> counts = {};
    for (final row in result) {
      final action = row.read(auditLog.action);
      final count = row.read(auditLog.id.count());
      if (action != null && count != null) {
        counts[action] = count;
      }
    }

    return counts;
  }

  /// Elimina registros de auditoría antiguos (más de X días)
  Future<int> deleteOldAuditLogs(int daysToKeep) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return (delete(auditLog)
          ..where((t) => t.createdAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// Stream de todos los registros de auditoría
  Stream<List<AuditLogData>> watchAllAuditLogs({int? limit}) {
    final query = select(auditLog)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch();
  }

  /// Stream de registros de auditoría por usuario
  Stream<List<AuditLogData>> watchAuditLogsByUser(int userId, {int? limit}) {
    final query = select(auditLog)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch();
  }
}
