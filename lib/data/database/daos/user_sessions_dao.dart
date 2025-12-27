import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_sessions_table.dart';

part 'user_sessions_dao.g.dart';

/// DAO para operaciones con la tabla de sesiones de usuario
@DriftAccessor(tables: [UserSessions])
class UserSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSessionsDaoMixin {
  UserSessionsDao(AppDatabase db) : super(db);

  /// Crea una nueva sesión de usuario al hacer login
  Future<int> createSession({
    required int userId,
    String? deviceInfo,
    String? ipAddress,
    String? locationType,
    int? locationId,
  }) async {
    return into(userSessions).insert(
      UserSessionsCompanion.insert(
        userId: userId,
        deviceInfo: Value(deviceInfo),
        ipAddress: Value(ipAddress),
        locationType: Value(locationType),
        locationId: Value(locationId),
        isActive: const Value(true),
      ),
    );
  }

  /// Cierra una sesión específica al hacer logout
  Future<bool> closeSession(int sessionId) async {
    return (update(userSessions)..where((t) => t.id.equals(sessionId))).write(
      UserSessionsCompanion(
        logoutAt: Value(DateTime.now()),
        isActive: const Value(false),
      ),
    ).then((rows) => rows > 0);
  }

  /// Cierra todas las sesiones activas de un usuario
  Future<int> closeAllUserSessions(int userId) async {
    return (update(userSessions)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true)))
        .write(
      UserSessionsCompanion(
        logoutAt: Value(DateTime.now()),
        isActive: const Value(false),
      ),
    );
  }

  /// Obtiene la sesión activa actual de un usuario
  Future<UserSessionData?> getActiveSession(int userId) async {
    return (select(userSessions)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.loginAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Obtiene todas las sesiones de un usuario (historial completo)
  Future<List<UserSessionData>> getUserSessions(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    final query = select(userSessions)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.loginAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene todas las sesiones activas en el sistema
  Future<List<UserSessionData>> getAllActiveSessions() async {
    return (select(userSessions)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.loginAt)]))
        .get();
  }

  /// Obtiene el conteo de sesiones activas por usuario
  Future<int> getActiveSessionsCount(int userId) async {
    final query = selectOnly(userSessions)
      ..addColumns([userSessions.id.count()])
      ..where(userSessions.userId.equals(userId) &
          userSessions.isActive.equals(true));

    final result = await query.getSingle();
    return result.read(userSessions.id.count()) ?? 0;
  }

  /// Obtiene sesiones en un rango de fechas
  Future<List<UserSessionData>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? userId,
    int? limit,
    int? offset,
  }) async {
    final query = select(userSessions)
      ..where((t) =>
          t.loginAt.isBiggerOrEqualValue(startDate) &
          t.loginAt.isSmallerOrEqualValue(endDate));

    if (userId != null) {
      query.where((t) => t.userId.equals(userId));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.loginAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.get();
  }

  /// Obtiene la última sesión de un usuario
  Future<UserSessionData?> getLastSession(int userId) async {
    return (select(userSessions)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.loginAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Calcula la duración de una sesión (si está cerrada)
  Duration? getSessionDuration(UserSessionData session) {
    if (session.logoutAt != null) {
      return session.logoutAt!.difference(session.loginAt);
    }
    return null; // Sesión aún activa
  }

  /// Calcula la duración de la sesión actual (si está abierta)
  Duration getCurrentSessionDuration(UserSessionData session) {
    final endTime = session.logoutAt ?? DateTime.now();
    return endTime.difference(session.loginAt);
  }

  /// Elimina sesiones antiguas (más de X días)
  Future<int> deleteOldSessions(int daysToKeep) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return (delete(userSessions)
          ..where((t) => t.loginAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// Stream de sesiones activas del usuario
  Stream<List<UserSessionData>> watchUserActiveSessions(int userId) {
    return (select(userSessions)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.loginAt)]))
        .watch();
  }

  /// Stream de todas las sesiones del usuario
  Stream<List<UserSessionData>> watchUserSessions(int userId, {int? limit}) {
    final query = select(userSessions)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.loginAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch();
  }

  /// Stream de todas las sesiones activas del sistema
  Stream<List<UserSessionData>> watchAllActiveSessions() {
    return (select(userSessions)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.loginAt)]))
        .watch();
  }
}
