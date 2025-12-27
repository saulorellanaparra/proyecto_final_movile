import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados para el BLoC de auditoría
abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AuditInitial extends AuditState {
  const AuditInitial();
}

/// Estado de carga
class AuditLoading extends AuditState {
  const AuditLoading();
}

/// Estado cuando los registros de auditoría fueron cargados exitosamente
class AuditLogsLoaded extends AuditState {
  final List<AuditLogData> logs;

  const AuditLogsLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

/// Estado cuando una acción fue registrada exitosamente
class AuditActionLogged extends AuditState {
  final int auditLogId;

  const AuditActionLogged(this.auditLogId);

  @override
  List<Object?> get props => [auditLogId];
}

/// Estado cuando se obtuvieron los conteos de acciones
class AuditActionCountsLoaded extends AuditState {
  final Map<String, int> counts;

  const AuditActionCountsLoaded(this.counts);

  @override
  List<Object?> get props => [counts];
}

/// Estado de error
class AuditError extends AuditState {
  final String message;

  const AuditError(this.message);

  @override
  List<Object?> get props => [message];
}
