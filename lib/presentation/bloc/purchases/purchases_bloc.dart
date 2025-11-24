import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/purchases_dao.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../core/constants/enums.dart';
import 'purchases_event.dart';
import 'purchases_state.dart';

/// BLoC para gestión de compras
class PurchasesBloc extends Bloc<PurchasesEvent, PurchasesState> {
  final PurchasesDao purchasesDao;
  final InventoryDao inventoryDao;

  PurchasesBloc({
    required this.purchasesDao,
    required this.inventoryDao,
  }) : super(const PurchasesInitial()) {
    on<PurchasesLoadByWarehouseRequested>(_onLoadByWarehouse);
    on<PurchaseDetailsLoadRequested>(_onLoadDetails);
    on<PurchaseCreateRequested>(_onCreatePurchase);
    on<PurchaseMarkAsReceivedRequested>(_onMarkAsReceived);
  }

  /// Cargar compras por almacén
  Future<void> _onLoadByWarehouse(
    PurchasesLoadByWarehouseRequested event,
    Emitter<PurchasesState> emit,
  ) async {
    emit(const PurchasesLoading());
    try {
      final purchases = await purchasesDao.getPurchasesByWarehouse(
        event.warehouseId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      if (purchases.isEmpty) {
        emit(const PurchasesEmpty());
      } else {
        emit(PurchasesLoaded(purchases));
      }
    } catch (e) {
      emit(PurchasesError('Error al cargar compras: ${e.toString()}'));
    }
  }

  /// Cargar detalles de una compra
  Future<void> _onLoadDetails(
    PurchaseDetailsLoadRequested event,
    Emitter<PurchasesState> emit,
  ) async {
    emit(const PurchasesLoading());
    try {
      // Buscar la compra
      final purchases = await purchasesDao.getPurchasesByWarehouse(1);
      final purchase = purchases.where((p) => p.id == event.purchaseId).firstOrNull;

      if (purchase == null) {
        emit(const PurchasesError('Compra no encontrada'));
        return;
      }

      // Obtener detalles
      final details = await purchasesDao.getPurchaseDetails(event.purchaseId);

      emit(PurchaseDetailsLoaded(
        purchase: purchase,
        details: details,
      ));
    } catch (e) {
      emit(PurchasesError('Error al cargar detalles: ${e.toString()}'));
    }
  }

  /// Crear nueva compra
  Future<void> _onCreatePurchase(
    PurchaseCreateRequested event,
    Emitter<PurchasesState> emit,
  ) async {
    emit(const PurchasesLoading());
    try {
      final total = event.items.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );

      // Generar número de compra
      final purchaseNumber =
          'COM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final purchaseCompanion = PurchasesCompanion.insert(
        purchaseNumber: purchaseNumber,
        supplierName: event.supplierName,
        supplierRuc: Value(event.supplierRuc),
        supplierPhone: Value(event.supplierPhone),
        supplierEmail: Value(event.supplierEmail),
        warehouseId: event.warehouseId,
        purchaseDate: DateTime.now(),
        totalAmount: Value(total),
        notes: Value(event.notes),
        status: const Value('PENDING'),
        createdBy: Value(event.userId),
      );

      final detailsCompanions = event.items
          .map((item) => PurchaseDetailsCompanion.insert(
                purchaseId: 0, // Se actualizará en el DAO
                productVariantId: item.variantId,
                quantity: item.quantity,
                unitCost: item.unitCost,
                subtotal: item.total,
              ))
          .toList();

      final purchaseId = await purchasesDao.createPurchase(
        purchaseCompanion,
        detailsCompanions,
      );

      emit(PurchaseCreated(purchaseId: purchaseId, total: total));

      // Recargar lista de compras
      add(PurchasesLoadByWarehouseRequested(warehouseId: event.warehouseId));
    } catch (e) {
      emit(PurchasesError('Error al crear compra: ${e.toString()}'));
    }
  }

  /// Marcar compra como recibida y actualizar inventario
  Future<void> _onMarkAsReceived(
    PurchaseMarkAsReceivedRequested event,
    Emitter<PurchasesState> emit,
  ) async {
    emit(const PurchasesLoading());
    try {
      // Obtener detalles de la compra
      final details = await purchasesDao.getPurchaseDetails(event.purchaseId);

      // Actualizar inventario por cada item
      for (final detail in details) {
        await inventoryDao.incrementInventory(
          variantId: detail.productVariantId,
          locationType: LocationType.warehouse,
          locationId: event.warehouseId,
          quantity: detail.quantity,
          userId: event.userId,
        );

        // Registrar movimiento
        await inventoryDao.recordMovement(
          variantId: detail.productVariantId,
          locationType: LocationType.warehouse,
          locationId: event.warehouseId,
          movementType: MovementType.purchase,
          quantityChange: detail.quantity,
          quantityBefore: 0, // TODO: Get actual quantity before
          userId: event.userId,
          referenceType: 'PURCHASE',
          referenceId: event.purchaseId,
          notes: 'Compra recibida',
        );
      }

      // Marcar compra como recibida
      await purchasesDao.markAsReceived(event.purchaseId);

      emit(PurchaseMarkedAsReceived(event.purchaseId));

      // Recargar lista
      add(PurchasesLoadByWarehouseRequested(warehouseId: event.warehouseId));
    } catch (e) {
      emit(PurchasesError('Error al recibir compra: ${e.toString()}'));
    }
  }
}
