import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/stores_table.dart';

part 'stores_dao.g.dart';

/// DAO para gestión de tiendas
@DriftAccessor(tables: [Stores])
class StoresDao extends DatabaseAccessor<AppDatabase> with _$StoresDaoMixin {
  StoresDao(AppDatabase db) : super(db);

  /// Obtiene todas las tiendas activas
  Future<List<StoreData>> getActiveStores() {
    return (select(stores)..where((s) => s.isActive.equals(true))).get();
  }

  /// Obtiene todas las tiendas
  Future<List<StoreData>> getAllStores() {
    return select(stores).get();
  }

  /// Obtiene una tienda por ID
  Future<StoreData?> getStoreById(int id) {
    return (select(stores)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Crea una nueva tienda
  Future<int> createStore(StoresCompanion store) {
    return into(stores).insert(store);
  }

  /// Actualiza una tienda
  Future<int> updateStore(int id, StoresCompanion store) {
    return (update(stores)..where((s) => s.id.equals(id))).write(store);
  }

  /// Desactiva una tienda
  Future<int> deactivateStore(int id) {
    return (update(stores)..where((s) => s.id.equals(id)))
        .write(const StoresCompanion(isActive: Value(false)));
  }

  /// Activa una tienda
  Future<int> activateStore(int id) {
    return (update(stores)..where((s) => s.id.equals(id)))
        .write(const StoresCompanion(isActive: Value(true)));
  }

  /// Busca tiendas por nombre
  Future<List<StoreData>> searchStoresByName(String query) {
    return (select(stores)..where((s) => s.name.like('%$query%'))).get();
  }
}
