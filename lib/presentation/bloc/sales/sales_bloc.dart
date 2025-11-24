import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';

import '../../../core/constants/enums.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/sales_dao.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../data/database/daos/product_dao.dart';
import '../../../data/database/daos/stores_dao.dart';
import 'sales_event.dart';
import 'sales_state.dart';

/// BLoC para gestión de ventas
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesDao salesDao;
  final InventoryDao inventoryDao;
  final ProductDao? productDao;
  final StoresDao? storesDao;

  SalesBloc({
    required this.salesDao,
    required this.inventoryDao,
    this.productDao,
    this.storesDao,
  }) : super(const SalesInitial()) {
    on<SalesLoadTodayByStoreRequested>(_onLoadTodayByStore);
    on<SalesLoadByDateRangeRequested>(_onLoadByDateRange);
    on<SalesLoadByIdRequested>(_onLoadById);
    on<SalesCreateRequested>(_onCreateSale);
    on<SalesCancelRequested>(_onCancelSale);
    on<SalesGetDailyTotalRequested>(_onGetDailyTotal);
    on<SalesLoadAllStoresRequested>(_onLoadAllStores);
  }

  Future<void> _onLoadTodayByStore(
    SalesLoadTodayByStoreRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sales = await salesDao.getSalesByStore(
        event.storeId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      emit(sales.isEmpty ? const SalesEmpty() : SalesLoaded(sales));
    } catch (e) {
      emit(SalesError('Error al cargar ventas: ${e.toString()}'));
    }
  }

  Future<void> _onLoadByDateRange(
    SalesLoadByDateRangeRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      final sales = await salesDao.getSalesByStore(
        event.storeId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(sales.isEmpty ? const SalesEmpty() : SalesLoaded(sales));
    } catch (e) {
      emit(SalesError('Error al cargar ventas: ${e.toString()}'));
    }
  }

  Future<void> _onLoadById(
    SalesLoadByIdRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      // Obtener todas las ventas y buscar por ID
      final sales = await salesDao.getSalesByStore(1); // TODO: mejorar esto
      final sale = sales.where((s) => s.id == event.saleId).firstOrNull;

      if (sale == null) {
        emit(const SalesError('Venta no encontrada'));
        return;
      }
      final details = await salesDao.getSaleDetails(event.saleId);

      // Obtener nombres de productos para cada variante
      final Map<int, String> productNames = {};
      if (productDao != null) {
        for (final detail in details) {
          try {
            final productInfo = await productDao!
                .getProductWithVariant(detail.productVariantId);
            if (productInfo != null) {
              final product = productInfo['product'] as ProductData;
              final variant = productInfo['variant'] as ProductVariantData;
              final variantDesc = [
                if (variant.size != null) variant.size,
                if (variant.color != null) variant.color,
              ].join(' - ');
              productNames[detail.productVariantId] = variantDesc.isNotEmpty
                  ? '${product.name} ($variantDesc)'
                  : product.name;
            }
          } catch (_) {
            // Si falla, se usará el ID como fallback
          }
        }
      }

      emit(SaleDetailLoaded(
          sale: sale, details: details, productNames: productNames));
    } catch (e) {
      emit(SalesError('Error al cargar venta: ${e.toString()}'));
    }
  }

  Future<void> _onCreateSale(
    SalesCreateRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      final total =
          event.items.fold<double>(0, (sum, item) => sum + item.total);

      // Generar número de venta
      final saleNumber =
          'VEN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final saleCompanion = SalesCompanion.insert(
        saleNumber: saleNumber,
        storeId: event.storeId,
        saleDate: DateTime.now(),
        total: Value(total),
        subtotal: Value(total),
        paymentMethod: event.paymentMethod,
        customerName: Value(event.customerName),
        customerDocument: Value(event.customerDocument),
        customerPhone: Value(event.customerPhone),
        status: const Value('COMPLETED'),
        createdBy: Value(event.userId),
      );

      final detailsCompanions = event.items
          .map((item) => SaleDetailsCompanion.insert(
                saleId: 0, // Se actualizará en el DAO
                productVariantId: item.variantId,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal: item.total,
              ))
          .toList();

      final saleId =
          await salesDao.createSale(saleCompanion, detailsCompanions);

      // ✅ DESCONTAR INVENTARIO Y REGISTRAR MOVIMIENTOS
      for (final item in event.items) {
        try {
          // Obtener cantidad antes del movimiento
          final quantityBefore = await inventoryDao.getAvailableQuantity(
            item.variantId,
            LocationType.store,
            event.storeId,
          );

          // Decrementar inventario (usando cantidad negativa)
          await inventoryDao.incrementInventory(
            variantId: item.variantId,
            locationType: LocationType.store,
            locationId: event.storeId,
            quantity: -item.quantity, // Cantidad negativa para descontar
            userId: event.userId,
          );

          // Registrar movimiento
          await inventoryDao.recordMovement(
            variantId: item.variantId,
            locationType: LocationType.store,
            locationId: event.storeId,
            movementType: MovementType.sale,
            quantityChange: -item.quantity,
            quantityBefore: quantityBefore,
            userId: event.userId,
            referenceType: 'SALE',
            referenceId: saleId,
            notes: 'Venta $saleNumber - ${item.quantity} unidades',
          );
        } catch (inventoryError) {
          // Log error pero no cancelar la venta
          print('Error al actualizar inventario: $inventoryError');
        }
      }

      emit(SaleCreated(saleId: saleId, total: total));
      add(SalesLoadTodayByStoreRequested(event.storeId));
    } catch (e) {
      emit(SalesError('Error al crear venta: ${e.toString()}'));
    }
  }

  Future<void> _onCancelSale(
    SalesCancelRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      await salesDao.cancelSale(event.saleId);
      emit(SaleCancelled(event.saleId));
    } catch (e) {
      emit(SalesError('Error al anular venta: ${e.toString()}'));
    }
  }

  Future<void> _onGetDailyTotal(
    SalesGetDailyTotalRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      final total =
          await salesDao.getDailySalesTotal(event.storeId, DateTime.now());

      // Obtener ventas del día para contar
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final sales = await salesDao.getSalesByStore(
        event.storeId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      emit(SalesTotalLoaded(total: total, salesCount: sales.length));
    } catch (e) {
      emit(SalesError('Error al obtener total: ${e.toString()}'));
    }
  }

  /// Carga ventas de todas las tiendas (para encargados de almacén)
  Future<void> _onLoadAllStores(
    SalesLoadAllStoresRequested event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      if (storesDao == null) {
        emit(const SalesError('No se puede acceder a las tiendas'));
        return;
      }

      // Obtener todas las tiendas
      final stores = await storesDao!.getAllStores();

      // Crear mapa de nombres de tiendas
      final Map<int, String> storeNames = {};
      for (final store in stores) {
        storeNames[store.id] = store.name;
      }

      // Obtener ventas de hoy para cada tienda
      final now = DateTime.now();
      final startDate = event.startDate ?? DateTime(now.year, now.month, now.day);
      final endDate = event.endDate ?? startDate.add(const Duration(days: 1));

      final Map<int, List<SaleData>> salesByStore = {};

      for (final store in stores) {
        final sales = await salesDao.getSalesByStore(
          store.id,
          startDate: startDate,
          endDate: endDate,
        );
        if (sales.isNotEmpty) {
          salesByStore[store.id] = sales;
        }
      }

      if (salesByStore.isEmpty) {
        emit(const SalesEmpty());
      } else {
        emit(SalesAllStoresLoaded(
          salesByStore: salesByStore,
          storeNames: storeNames,
        ));
      }
    } catch (e) {
      emit(SalesError('Error al cargar ventas: ${e.toString()}'));
    }
  }
}
