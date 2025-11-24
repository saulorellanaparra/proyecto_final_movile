import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';
import '../tables/roles_table.dart';
import '../tables/stores_table.dart';
import '../tables/warehouses_table.dart';

part 'user_dao.g.dart';

/// Data Access Object para gestión de usuarios
/// Proporciona métodos para CRUD y consultas relacionadas con usuarios
@DriftAccessor(tables: [Users, Roles, UserRoles, Stores, Warehouses])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  /// Obtiene todos los usuarios activos
  Future<List<UserData>> getAllActiveUsers() {
    return (select(users)..where((u) => u.isActive.equals(true))).get();
  }

  /// Obtiene todos los usuarios (activos e inactivos)
  Future<List<UserData>> getAllUsers() {
    return select(users).get();
  }

  /// Obtiene un usuario por ID
  Future<UserData?> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Obtiene un usuario por nombre de usuario
  Future<UserData?> getUserByUsername(String username) {
    return (select(users)..where((u) => u.username.equals(username)))
        .getSingleOrNull();
  }

  /// Obtiene un usuario por email
  Future<UserData?> getUserByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  /// Crea un nuevo usuario
  Future<int> createUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  /// Actualiza un usuario existente
  Future<bool> updateUser(UserData user) {
    return update(users).replace(user);
  }

  /// Elimina un usuario (soft delete - marca como inactivo)
  Future<int> softDeleteUser(int userId) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      const UsersCompanion(
        isActive: Value(false),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Elimina un usuario permanentemente
  Future<int> deleteUser(int userId) {
    return (delete(users)..where((u) => u.id.equals(userId))).go();
  }

  /// Verifica las credenciales de un usuario
  Future<UserData?> verifyCredentials(String username, String passwordHash) {
    return (select(users)
          ..where((u) =>
              u.username.equals(username) &
              u.passwordHash.equals(passwordHash) &
              u.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Actualiza la contraseña de un usuario
  Future<int> updatePassword(int userId, String newPasswordHash) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(newPasswordHash),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene los roles de un usuario
  Future<List<RoleData>> getUserRoles(int userId) async {
    final query = select(userRoles).join([
      innerJoin(roles, roles.id.equalsExp(userRoles.roleId)),
    ])
      ..where(userRoles.userId.equals(userId));

    final result = await query.get();

    return result.map((row) => row.readTable(roles)).toList();
  }

  /// Obtiene el rol principal de un usuario
  Future<RoleData?> getUserPrimaryRole(int userId) async {
    final query = select(userRoles).join([
      innerJoin(roles, roles.id.equalsExp(userRoles.roleId)),
    ])
      ..where(
        userRoles.userId.equals(userId) & userRoles.isPrimary.equals(true),
      );

    final result = await query.getSingleOrNull();

    if (result == null) return null;

    return result.readTable(roles);
  }

  /// Asigna un rol a un usuario
  Future<int> assignRoleToUser({
    required int userId,
    required int roleId,
    int? storeId,
    int? warehouseId,
    bool isPrimary = false,
  }) {
    return into(userRoles).insert(
      UserRolesCompanion.insert(
        userId: userId,
        roleId: roleId,
        storeId: Value(storeId),
        warehouseId: Value(warehouseId),
        isPrimary: Value(isPrimary),
      ),
    );
  }

  /// Remueve un rol de un usuario
  Future<int> removeRoleFromUser(int userId, int roleId) {
    return (delete(userRoles)
          ..where((ur) =>
              ur.userId.equals(userId) & ur.roleId.equals(roleId)))
        .go();
  }

  /// Obtiene usuarios por rol
  Future<List<UserData>> getUsersByRole(String roleCode) async {
    final query = select(users).join([
      innerJoin(userRoles, userRoles.userId.equalsExp(users.id)),
      innerJoin(roles, roles.id.equalsExp(userRoles.roleId)),
    ])
      ..where(roles.code.equals(roleCode) & users.isActive.equals(true));

    final result = await query.get();

    return result.map((row) => row.readTable(users)).toList();
  }

  /// Obtiene usuarios asignados a una tienda
  Future<List<UserData>> getUsersByStore(int storeId) async {
    final query = select(users).join([
      innerJoin(userRoles, userRoles.userId.equalsExp(users.id)),
    ])
      ..where(
        userRoles.storeId.equals(storeId) & users.isActive.equals(true),
      );

    final result = await query.get();

    return result.map((row) => row.readTable(users)).toList();
  }

  /// Obtiene usuarios asignados a un almacén
  Future<List<UserData>> getUsersByWarehouse(int warehouseId) async {
    final query = select(users).join([
      innerJoin(userRoles, userRoles.userId.equalsExp(users.id)),
    ])
      ..where(
        userRoles.warehouseId.equals(warehouseId) &
            users.isActive.equals(true),
      );

    final result = await query.get();

    return result.map((row) => row.readTable(users)).toList();
  }

  /// Busca usuarios por nombre o username
  Future<List<UserData>> searchUsers(String query) {
    final searchQuery = '%$query%';
    return (select(users)
          ..where((u) =>
              u.username.like(searchQuery) |
              u.fullName.like(searchQuery) |
              u.email.like(searchQuery)))
        .get();
  }

  /// Actualiza la fecha de última sincronización
  Future<int> updateLastSync(int userId) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }
}
