import 'package:drift/drift.dart';
import 'users_table.dart';
import 'stores_table.dart';
import 'warehouses_table.dart';

/// Tabla de roles del sistema
/// Define los diferentes roles que pueden tener los usuarios
@DataClassName('RoleData')
class Roles extends Table {
  /// ID único del rol
  IntColumn get id => integer().autoIncrement()();

  /// Código único del rol (ej: SUPER_ADMIN, VENDEDOR)
  TextColumn get code => text().withLength(min: 1, max: 50).unique()();

  /// Nombre descriptivo del rol
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Descripción del rol
  TextColumn get description => text().withLength(max: 500).nullable()();

  /// Permisos del rol en formato JSON
  /// Ejemplo: ["view_inventory", "create_sale", "edit_product"]
  TextColumn get permissionsJson => text().withDefault(const Constant('[]'))();

  /// Fecha de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de relación usuario-rol con ubicación asignada
/// Un usuario puede tener diferentes roles en diferentes ubicaciones
@DataClassName('UserRoleData')
class UserRoles extends Table {
  /// ID único de la relación
  IntColumn get id => integer().autoIncrement()();

  /// ID del usuario
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// ID del rol
  IntColumn get roleId => integer().references(Roles, #id, onDelete: KeyAction.cascade)();

  /// ID de la tienda asociada (null si no es específico de tienda)
  IntColumn get storeId => integer().nullable().references(Stores, #id, onDelete: KeyAction.setNull)();

  /// ID del almacén asociado (null si no es específico de almacén)
  IntColumn get warehouseId => integer().nullable().references(Warehouses, #id, onDelete: KeyAction.setNull)();

  /// Indica si es el rol principal del usuario
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// Fecha de asignación del rol
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, roleId, storeId, warehouseId},
  ];
}
