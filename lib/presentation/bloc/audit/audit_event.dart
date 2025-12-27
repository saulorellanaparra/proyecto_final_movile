import 'package:equatable/equatable.dart';

/// Eventos para el BLoC de auditoría
abstract class AuditEvent extends Equatable {
  const AuditEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar todos los registros de auditoría
class AuditLoadAllRequested extends AuditEvent {
  final int? limit;
  final int? offset;

  const AuditLoadAllRequested({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

/// Evento para cargar registros de auditoría por usuario
class AuditLoadByUserRequested extends AuditEvent {
  final int userId;
  final int? limit;
  final int? offset;

  const AuditLoadByUserRequested({
    required this.userId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}

/// Evento para cargar registros de auditoría por acción
class AuditLoadByActionRequested extends AuditEvent {
  final String action;
  final int? limit;
  final int? offset;

  const AuditLoadByActionRequested({
    required this.action,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [action, limit, offset];
}

/// Evento para cargar registros de auditoría por tipo de entidad
class AuditLoadByEntityTypeRequested extends AuditEvent {
  final String entityType;
  final int? limit;
  final int? offset;

  const AuditLoadByEntityTypeRequested({
    required this.entityType,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [entityType, limit, offset];
}

/// Evento para cargar registros de auditoría por rango de fechas
class AuditLoadByDateRangeRequested extends AuditEvent {
  final DateTime startDate;
  final DateTime endDate;
  final int? limit;
  final int? offset;

  const AuditLoadByDateRangeRequested({
    required this.startDate,
    required this.endDate,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [startDate, endDate, limit, offset];
}

/// Evento para cargar registros de auditoría para una entidad específica
class AuditLoadForEntityRequested extends AuditEvent {
  final String entityType;
  final int entityId;

  const AuditLoadForEntityRequested({
    required this.entityType,
    required this.entityId,
  });

  @override
  List<Object?> get props => [entityType, entityId];
}

/// Evento para registrar una nueva acción de auditoría
class AuditLogActionRequested extends AuditEvent {
  final int userId;
  final String action;
  final String description;
  final String? entityType;
  final int? entityId;
  final String? oldValues;
  final String? newValues;
  final String? ipAddress;
  final String? deviceInfo;

  const AuditLogActionRequested({
    required this.userId,
    required this.action,
    required this.description,
    this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [
        userId,
        action,
        description,
        entityType,
        entityId,
        oldValues,
        newValues,
        ipAddress,
        deviceInfo,
      ];
}

/// Evento para obtener conteos de acciones
class AuditGetActionsCountsRequested extends AuditEvent {
  const AuditGetActionsCountsRequested();
}
