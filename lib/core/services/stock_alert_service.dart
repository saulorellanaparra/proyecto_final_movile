import '../../data/database/daos/inventory_dao.dart';
import '../../data/database/app_database.dart';
import '../constants/enums.dart';

/// Servicio para gestionar alertas de stock bajo
class StockAlertService {
  final InventoryDao _inventoryDao;

  StockAlertService(this._inventoryDao);

  /// Obtiene todos los productos con stock bajo (cantidad <= minStock)
  Future<List<InventoryData>> getLowStockItems({
    LocationType? locationType,
    int? locationId,
  }) async {
    try {
      // Si no se especifica ubicación, obtener todo el inventario
      List<InventoryData> allInventory;

      if (locationType != null && locationId != null) {
        allInventory = await _inventoryDao.getInventoryByLocation(
          locationType,
          locationId,
        );
      } else {
        // Obtener inventario de todas las ubicaciones
        allInventory = [];
        // Podríamos implementar un método getAllInventory en el DAO
        // Por ahora retornamos lista vacía si no hay ubicación
      }

      // Filtrar items con stock bajo
      final lowStockItems = allInventory.where((item) {
        return item.quantity <= item.minStock;
      }).toList();

      return lowStockItems;
    } catch (e) {
      throw Exception('Error al obtener items con stock bajo: $e');
    }
  }

  /// Obtiene el conteo de items con stock bajo por ubicación
  Future<int> getLowStockCount({
    LocationType? locationType,
    int? locationId,
  }) async {
    final lowStockItems = await getLowStockItems(
      locationType: locationType,
      locationId: locationId,
    );
    return lowStockItems.length;
  }

  /// Obtiene items con stock crítico (cantidad == 0)
  Future<List<InventoryData>> getCriticalStockItems({
    LocationType? locationType,
    int? locationId,
  }) async {
    try {
      List<InventoryData> allInventory;

      if (locationType != null && locationId != null) {
        allInventory = await _inventoryDao.getInventoryByLocation(
          locationType,
          locationId,
        );
      } else {
        allInventory = [];
      }

      // Filtrar items con stock crítico (0 unidades)
      final criticalItems = allInventory.where((item) {
        return item.quantity == 0;
      }).toList();

      return criticalItems;
    } catch (e) {
      throw Exception('Error al obtener items con stock crítico: $e');
    }
  }

  /// Obtiene items que están cerca del stock mínimo (por ejemplo, 20% por encima del mínimo)
  Future<List<InventoryData>> getNearMinStockItems({
    LocationType? locationType,
    int? locationId,
    double threshold = 0.2, // 20% por encima del mínimo
  }) async {
    try {
      List<InventoryData> allInventory;

      if (locationType != null && locationId != null) {
        allInventory = await _inventoryDao.getInventoryByLocation(
          locationType,
          locationId,
        );
      } else {
        allInventory = [];
      }

      // Filtrar items cerca del stock mínimo
      final nearMinItems = allInventory.where((item) {
        final warningLevel = item.minStock + (item.minStock * threshold);
        return item.quantity > item.minStock && item.quantity <= warningLevel;
      }).toList();

      return nearMinItems;
    } catch (e) {
      throw Exception('Error al obtener items cerca del stock mínimo: $e');
    }
  }

  /// Verifica si hay alertas de stock para una ubicación específica
  Future<bool> hasLowStockAlerts({
    LocationType? locationType,
    int? locationId,
  }) async {
    final count = await getLowStockCount(
      locationType: locationType,
      locationId: locationId,
    );
    return count > 0;
  }

  /// Obtiene un resumen de alertas de stock
  Future<Map<String, dynamic>> getStockAlertSummary({
    LocationType? locationType,
    int? locationId,
  }) async {
    final lowStock = await getLowStockItems(
      locationType: locationType,
      locationId: locationId,
    );
    final criticalStock = await getCriticalStockItems(
      locationType: locationType,
      locationId: locationId,
    );
    final nearMinStock = await getNearMinStockItems(
      locationType: locationType,
      locationId: locationId,
    );

    return {
      'lowStockCount': lowStock.length,
      'criticalStockCount': criticalStock.length,
      'nearMinStockCount': nearMinStock.length,
      'totalAlertsCount': lowStock.length + nearMinStock.length,
    };
  }

  /// Stream para monitorear cambios en items con stock bajo
  Stream<List<InventoryData>> watchLowStockItems({
    LocationType? locationType,
    int? locationId,
  }) {
    // Aquí necesitarías implementar un stream que escuche cambios en la base de datos
    // Por ahora, retornamos un stream vacío
    // En una implementación real, usarías el método watch del DAO
    return Stream.value([]);
  }
}
