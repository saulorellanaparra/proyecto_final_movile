import 'package:drift/drift.dart';
import 'users_table.dart';

/// Tabla de registro de auditoría
/// Almacena todas las acciones realizadas por los usuarios para trazabilidad
@DataClassName('AuditLogData')
class AuditLog extends Table {
  /// ID único del registro de auditoría
  IntColumn get id => integer().autoIncrement()();

  /// ID del usuario que realizó la acción
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.setNull)();

  /// Tipo de acción (LOGIN, LOGOUT, CREATE, UPDATE, DELETE)
  TextColumn get action => text().withLength(max: 30)();

  /// Tipo de entidad afectada (PRODUCT, SALE, PURCHASE, TRANSFER, USER, etc.)
  TextColumn get entityType => text().withLength(max: 50).nullable()();

  /// ID de la entidad afectada
  IntColumn get entityId => integer().nullable()();

  /// Descripción de la acción realizada
  TextColumn get description => text().withLength(max: 500)();

  /// Valores anteriores (JSON) antes del cambio
  TextColumn get oldValues => text().nullable()();

  /// Nuevos valores (JSON) después del cambio
  TextColumn get newValues => text().nullable()();

  /// Dirección IP desde donde se realizó la acción
  TextColumn get ipAddress => text().withLength(max: 50).nullable()();

  /// Información del dispositivo
  TextColumn get deviceInfo => text().withLength(max: 200).nullable()();

  /// Fecha y hora de la acción
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
