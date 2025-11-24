import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../core/constants/enums.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

/// BLoC para gestión de inventario
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryDao inventoryDao;

  InventoryBloc({required this.inventoryDao})
      : super(const InventoryInitial()) {
    on<InventoryLoadByLocationRequested>(_onLoadByLocation);
    on<InventoryLoadLowStockRequested>(_onLoadLowStock);
    on<InventoryLoadOutOfStockRequested>(_onLoadOutOfStock);
    on<InventoryAdjustRequested>(_onAdjustInventory);
    on<InventoryMovementsLoadRequested>(_onLoadMovements);
    on<InventoryMovementsByVariantRequested>(_onLoadMovementsByVariant);
    on<InventoryCheckStockRequested>(_onCheckStock);
  }

  /// Cargar inventario por ubicación
  Future<void> _onLoadByLocation(
    InventoryLoadByLocationRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final items = await inventoryDao.getInventoryWithProductInfoByLocation(
        event.locationType,
        event.locationId,
      );

      if (items.isEmpty) {
        emit(const InventoryEmpty());
      } else {
        emit(InventoryLoadedWithProductInfo(items));
      }
    } catch (e) {
      emit(InventoryError('Error al cargar inventario: ${e.toString()}'));
    }
  }

  /// Cargar productos con stock bajo
  Future<void> _onLoadLowStock(
    InventoryLoadLowStockRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final items = await inventoryDao.getLowStockWithProductInfo(
        event.locationType,
        event.locationId,
      );

      emit(InventoryLowStockLoadedWithProductInfo(items));
    } catch (e) {
      emit(InventoryError('Error al cargar stock bajo: ${e.toString()}'));
    }
  }

  /// Cargar productos sin stock
  Future<void> _onLoadOutOfStock(
    InventoryLoadOutOfStockRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final items = await inventoryDao.getOutOfStockWithProductInfo(
        event.locationType,
        event.locationId,
      );

      emit(InventoryOutOfStockLoadedWithProductInfo(items));
    } catch (e) {
      emit(InventoryError('Error al cargar sin stock: ${e.toString()}'));
    }
  }

  /// Ajustar inventario manualmente
  Future<void> _onAdjustInventory(
    InventoryAdjustRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      // Obtener inventario actual
      final currentInventory = await inventoryDao.getInventoryForVariant(
        event.variantId,
        event.locationType,
        event.locationId,
      );

      final quantityBefore = currentInventory?.quantity ?? 0;
      final quantityChange = event.newQuantity - quantityBefore;

      if (currentInventory == null) {
        // Crear nuevo inventario
        await inventoryDao.upsertInventory(
          InventoryCompanion.insert(
            productVariantId: event.variantId,
            locationType: event.locationType.code,
            locationId: event.locationId,
            quantity: Value(event.newQuantity),
            updatedBy: Value(event.userId),
          ),
        );
      } else {
        // Actualizar inventario existente
        await inventoryDao.updateQuantity(
          currentInventory.id,
          event.newQuantity,
          event.userId,
        );
      }

      // Registrar movimiento
      await inventoryDao.recordMovement(
        variantId: event.variantId,
        locationType: event.locationType,
        locationId: event.locationId,
        movementType: MovementType.adjustment,
        quantityChange: quantityChange,
        quantityBefore: quantityBefore,
        userId: event.userId,
        notes: event.notes,
      );

      emit(InventoryAdjusted(
        variantId: event.variantId,
        newQuantity: event.newQuantity,
      ));

      // Recargar inventario
      add(InventoryLoadByLocationRequested(
        locationType: event.locationType,
        locationId: event.locationId,
      ));
    } catch (e) {
      emit(InventoryError('Error al ajustar inventario: ${e.toString()}'));
    }
  }

  /// Cargar movimientos de inventario
  Future<void> _onLoadMovements(
    InventoryMovementsLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final movements = await inventoryDao.getMovementsByLocation(
        event.locationType,
        event.locationId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(InventoryMovementsLoaded(movements));
    } catch (e) {
      emit(InventoryError('Error al cargar movimientos: ${e.toString()}'));
    }
  }

  /// Cargar movimientos por variante
  Future<void> _onLoadMovementsByVariant(
    InventoryMovementsByVariantRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final movements = await inventoryDao.getMovementsByVariant(
        event.variantId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(InventoryMovementsLoaded(movements));
    } catch (e) {
      emit(InventoryError(
          'Error al cargar movimientos de variante: ${e.toString()}'));
    }
  }

  /// Verificar stock disponible
  Future<void> _onCheckStock(
    InventoryCheckStockRequested event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      final hasStock = await inventoryDao.hasStock(
        event.variantId,
        event.locationType,
        event.locationId,
        event.requiredQuantity,
      );

      final availableQuantity = await inventoryDao.getAvailableQuantity(
        event.variantId,
        event.locationType,
        event.locationId,
      );

      emit(InventoryStockChecked(
        hasStock: hasStock,
        availableQuantity: availableQuantity,
      ));
    } catch (e) {
      emit(InventoryError('Error al verificar stock: ${e.toString()}'));
    }
  }
}
