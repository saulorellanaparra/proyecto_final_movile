import 'package:drift/drift.dart';

/// Tabla de cola de sincronización
/// Almacena los cambios pendientes de sincronizar con el servidor
@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  /// ID único del registro en la cola
  IntColumn get id => integer().autoIncrement()();

  /// Tipo de entidad (USER, PRODUCT, SALE, PURCHASE, etc.)
  TextColumn get entityType => text().withLength(max: 50)();

  /// ID de la entidad afectada
  IntColumn get entityId => integer()();

  /// Operación realizada (INSERT, UPDATE, DELETE)
  TextColumn get operation => text().withLength(max: 20)();

  /// Datos de la entidad en formato JSON
  TextColumn get dataJson => text()();

  /// Indica si ya fue sincronizado
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  /// Número de intentos de sincronización
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();

  /// Último error de sincronización (si hubo)
  TextColumn get lastError => text().withLength(max: 1000).nullable()();

  /// Fecha y hora de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Fecha y hora de última sincronización exitosa
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Fecha y hora del último intento de sincronización
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
