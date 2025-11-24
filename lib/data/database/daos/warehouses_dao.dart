import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/warehouses_table.dart';

part 'warehouses_dao.g.dart';

/// DAO para gestión de almacenes
@DriftAccessor(tables: [Warehouses])
class WarehousesDao extends DatabaseAccessor<AppDatabase>
    with _$WarehousesDaoMixin {
  WarehousesDao(AppDatabase db) : super(db);

  /// Obtiene todos los almacenes activos
  Future<List<WarehouseData>> getActiveWarehouses() {
    return (select(warehouses)..where((w) => w.isActive.equals(true))).get();
  }

  /// Obtiene todos los almacenes
  Future<List<WarehouseData>> getAllWarehouses() {
    return select(warehouses).get();
  }

  /// Obtiene un almacén por ID
  Future<WarehouseData?> getWarehouseById(int id) {
    return (select(warehouses)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }

  /// Crea un nuevo almacén
  Future<int> createWarehouse(WarehousesCompanion warehouse) {
    return into(warehouses).insert(warehouse);
  }

  /// Actualiza un almacén
  Future<int> updateWarehouse(int id, WarehousesCompanion warehouse) {
    return (update(warehouses)..where((w) => w.id.equals(id))).write(warehouse);
  }

  /// Desactiva un almacén
  Future<int> deactivateWarehouse(int id) {
    return (update(warehouses)..where((w) => w.id.equals(id)))
        .write(const WarehousesCompanion(isActive: Value(false)));
  }

  /// Activa un almacén
  Future<int> activateWarehouse(int id) {
    return (update(warehouses)..where((w) => w.id.equals(id)))
        .write(const WarehousesCompanion(isActive: Value(true)));
  }

  /// Busca almacenes por nombre
  Future<List<WarehouseData>> searchWarehousesByName(String query) {
    return (select(warehouses)..where((w) => w.name.like('%$query%'))).get();
  }
}
