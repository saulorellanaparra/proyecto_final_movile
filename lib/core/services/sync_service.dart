import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import '../constants/enums.dart';

/// Servicio de sincronización offline-first
/// Maneja la cola de sincronización y sincroniza datos con el servidor
class SyncService {
  final AppDatabase database;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({required this.database});

  /// Inicia la sincronización automática periódica
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncPendingChanges());
    debugPrint('🔄 Sincronización automática iniciada');
  }

  /// Detiene la sincronización automática
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('⏸️ Sincronización automática detenida');
  }

  /// Sincroniza todos los cambios pendientes
  Future<void> syncPendingChanges() async {
    if (_isSyncing) {
      debugPrint('⏭️ Sincronización ya en progreso, omitiendo...');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 Iniciando sincronización...');

    try {
      // Obtener todos los elementos pendientes de sincronización
      final pendingItems = await _getPendingItems();

      if (pendingItems.isEmpty) {
        debugPrint('✅ No hay elementos pendientes de sincronización');
        return;
      }

      debugPrint('📊 ${pendingItems.length} elementos pendientes de sincronización');

      // Procesar cada elemento
      for (final item in pendingItems) {
        await _syncItem(item);
      }

      debugPrint('✅ Sincronización completada');
    } catch (e) {
      debugPrint('❌ Error en sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Obtiene elementos pendientes de la cola de sincronización
  Future<List<SyncQueueData>> _getPendingItems() async {
    return await (database.select(database.syncQueue)
          ..where((s) => s.synced.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  /// Sincroniza un elemento individual
  Future<void> _syncItem(SyncQueueData item) async {
    try {
      debugPrint('🔄 Sincronizando: ${item.entityType} #${item.entityId}');

      // NOTA: Aquí se implementaría la llamada real al servidor/API
      // Por ahora, simularemos la sincronización exitosa

      // Ejemplo de implementación real:
      // final response = await apiClient.sync(
      //   entityType: item.entityType,
      //   entityId: item.entityId,
      //   operation: item.operation,
      //   data: jsonDecode(item.dataJson),
      // );

      // Simular sincronización exitosa
      await Future.delayed(const Duration(milliseconds: 100));

      // Marcar como sincronizado
      await _markAsSynced(item.id);

      debugPrint('✅ ${item.entityType} #${item.entityId} sincronizado');
    } catch (e) {
      debugPrint('❌ Error al sincronizar ${item.entityType} #${item.entityId}: $e');

      // Incrementar contador de intentos
      await _incrementSyncAttempts(item.id, e.toString());

      // Si se exceden los intentos máximos, marcar como fallido permanentemente
      if (item.syncAttempts + 1 >= 3) {
        debugPrint('⚠️ Máximo de intentos alcanzado para ${item.entityType} #${item.entityId}');
      }
    }
  }

  /// Marca un elemento como sincronizado
  Future<void> _markAsSynced(int syncQueueId) async {
    await (database.update(database.syncQueue)
          ..where((s) => s.id.equals(syncQueueId)))
        .write(
      SyncQueueCompanion(
        synced: const Value(true),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Incrementa el contador de intentos de sincronización
  Future<void> _incrementSyncAttempts(int syncQueueId, String error) async {
    final item = await (database.select(database.syncQueue)
          ..where((s) => s.id.equals(syncQueueId)))
        .getSingle();

    await (database.update(database.syncQueue)
          ..where((s) => s.id.equals(syncQueueId)))
        .write(
      SyncQueueCompanion(
        syncAttempts: Value(item.syncAttempts + 1),
        lastError: Value(error),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  /// Agrega un elemento a la cola de sincronización
  Future<void> addToSyncQueue({
    required EntityType entityType,
    required int entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    await database.into(database.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: entityType.code,
            entityId: entityId,
            operation: operation.code,
            dataJson: jsonEncode(data),
          ),
        );

    debugPrint('➕ Agregado a cola de sync: ${entityType.code} #$entityId');
  }

  /// Limpia elementos sincronizados antiguos (más de 30 días)
  Future<void> cleanOldSyncedItems() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final deleted = await (database.delete(database.syncQueue)
          ..where((s) =>
              s.synced.equals(true) &
              s.syncedAt.isSmallerOrEqualValue(thirtyDaysAgo)))
        .go();

    if (deleted > 0) {
      debugPrint('🧹 Limpiados $deleted elementos antiguos de la cola');
    }
  }

  /// Obtiene el conteo de elementos pendientes
  Future<int> getPendingCount() async {
    final result = await (database.selectOnly(database.syncQueue)
          ..addColumns([database.syncQueue.id.count()])
          ..where(database.syncQueue.synced.equals(false)))
        .getSingle();

    return result.read(database.syncQueue.id.count()) ?? 0;
  }

  /// Libera recursos
  void dispose() {
    stopAutoSync();
  }
}
