import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/transfers_dao.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../data/database/daos/stores_dao.dart';
import '../../../data/database/daos/warehouses_dao.dart';
import '../../../data/database/daos/user_dao.dart';
import '../../../core/constants/enums.dart';
import 'transfers_event.dart';
import 'transfers_state.dart';

/// BLoC para gestión de transferencias
class TransfersBloc extends Bloc<TransfersEvent, TransfersState> {
  final TransfersDao transfersDao;
  final InventoryDao inventoryDao;
  final StoresDao? storesDao;
  final WarehousesDao? warehousesDao;
  final UserDao? userDao;

  TransfersBloc({
    required this.transfersDao,
    required this.inventoryDao,
    this.storesDao,
    this.warehousesDao,
    this.userDao,
  }) : super(const TransfersInitial()) {
    on<TransfersLoadOutgoingRequested>(_onLoadOutgoing);
    on<TransfersLoadIncomingRequested>(_onLoadIncoming);
    on<TransfersLoadPendingRequested>(_onLoadPending);
    on<TransferDetailsLoadRequested>(_onLoadDetails);
    on<TransferCreateRequested>(_onCreateTransfer);
    on<TransferApproveRequested>(_onApproveTransfer);
    on<TransferReceiveRequested>(_onReceiveTransfer);
    on<TransferCancelRequested>(_onCancelTransfer);
  }

  Future<void> _onLoadOutgoing(TransfersLoadOutgoingRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      final transfers = await transfersDao.getTransfersFrom(
        event.locationType.code,
        event.locationId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(transfers.isEmpty ? const TransfersEmpty() : TransfersLoaded(transfers));
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadIncoming(TransfersLoadIncomingRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      final transfers = await transfersDao.getTransfersTo(
        event.locationType.code,
        event.locationId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(transfers.isEmpty ? const TransfersEmpty() : TransfersLoaded(transfers));
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPending(TransfersLoadPendingRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      final transfers = await transfersDao.getPendingTransfers();
      emit(transfers.isEmpty ? const TransfersEmpty() : TransfersLoaded(transfers));
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDetails(TransferDetailsLoadRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      // Buscar la transferencia por ID directamente
      final transfer = await transfersDao.getTransferById(event.transferId);
      if (transfer == null) {
        emit(const TransfersError('Transferencia no encontrada'));
        return;
      }
      final details = await transfersDao.getTransferDetails(event.transferId);

      // Obtener nombres de ubicaciones
      String? fromLocationName;
      String? toLocationName;

      // Obtener nombre de ubicación origen
      if (transfer.fromType == 'STORE' && storesDao != null) {
        final store = await storesDao!.getStoreById(transfer.fromId);
        fromLocationName = store?.name;
      } else if (transfer.fromType == 'WAREHOUSE' && warehousesDao != null) {
        final warehouse = await warehousesDao!.getWarehouseById(transfer.fromId);
        fromLocationName = warehouse?.name;
      }

      // Obtener nombre de ubicación destino
      if (transfer.toType == 'STORE' && storesDao != null) {
        final store = await storesDao!.getStoreById(transfer.toId);
        toLocationName = store?.name;
      } else if (transfer.toType == 'WAREHOUSE' && warehousesDao != null) {
        final warehouse = await warehousesDao!.getWarehouseById(transfer.toId);
        toLocationName = warehouse?.name;
      }

      // Obtener nombres de usuarios involucrados
      String? createdByName;
      String? approvedByName;
      String? receivedByName;

      if (userDao != null) {
        // Usuario que creó la transferencia
        if (transfer.createdBy != null) {
          final user = await userDao!.getUserById(transfer.createdBy!);
          createdByName = user?.fullName;
        }

        // Usuario que aprobó la transferencia
        if (transfer.approvedBy != null) {
          final user = await userDao!.getUserById(transfer.approvedBy!);
          approvedByName = user?.fullName;
        }

        // Usuario que recibió la transferencia
        if (transfer.receivedBy != null) {
          final user = await userDao!.getUserById(transfer.receivedBy!);
          receivedByName = user?.fullName;
        }
      }

      emit(TransferDetailsLoaded(
        transfer: transfer,
        details: details,
        fromLocationName: fromLocationName,
        toLocationName: toLocationName,
        createdByName: createdByName,
        approvedByName: approvedByName,
        receivedByName: receivedByName,
      ));
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTransfer(TransferCreateRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      final transferNumber = 'TRF-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final transferCompanion = TransfersCompanion.insert(
        transferNumber: transferNumber,
        fromType: event.fromType.code,
        fromId: event.fromId,
        toType: event.toType.code,
        toId: event.toId,
        transferDate: DateTime.now(),
        notes: Value(event.notes),
        status: const Value('PENDING'),
        createdBy: Value(event.userId),
      );

      final details = event.items.map((item) => TransferDetailsCompanion.insert(
        transferId: 0,
        productVariantId: item.variantId,
        quantity: item.quantity,
      )).toList();

      final transferId = await transfersDao.createTransfer(transferCompanion, details);
      emit(TransferCreated(transferId));
      add(const TransfersLoadPendingRequested());
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onApproveTransfer(TransferApproveRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      await transfersDao.approveTransfer(event.transferId, event.userId);
      emit(TransferApproved(event.transferId));
      add(const TransfersLoadPendingRequested());
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onReceiveTransfer(TransferReceiveRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      final details = await transfersDao.getTransferDetails(event.transferId);

      // Actualizar inventario destino
      for (final detail in details) {
        // Obtener inventario actual antes de incrementar
        final inventoryBefore = await inventoryDao.getInventoryForVariant(
          detail.productVariantId,
          event.toType,
          event.toId,
        );

        await inventoryDao.incrementInventory(
          variantId: detail.productVariantId,
          locationType: event.toType,
          locationId: event.toId,
          quantity: detail.quantity,
          userId: event.userId,
        );

        await inventoryDao.recordMovement(
          variantId: detail.productVariantId,
          locationType: event.toType,
          locationId: event.toId,
          movementType: MovementType.transferIn,
          quantityChange: detail.quantity,
          quantityBefore: inventoryBefore?.quantity ?? 0,
          userId: event.userId,
          referenceType: 'TRANSFER',
          referenceId: event.transferId,
        );
      }

      await transfersDao.receiveTransfer(event.transferId, event.userId);
      emit(TransferReceived(event.transferId));
      add(const TransfersLoadPendingRequested());
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onCancelTransfer(TransferCancelRequested event, Emitter<TransfersState> emit) async {
    emit(const TransfersLoading());
    try {
      await transfersDao.cancelTransfer(event.transferId);
      emit(TransferCancelled(event.transferId));
      add(const TransfersLoadPendingRequested());
    } catch (e) {
      emit(TransfersError('Error: ${e.toString()}'));
    }
  }
}
