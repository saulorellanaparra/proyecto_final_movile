import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/daos/audit_log_dao.dart';
import 'audit_event.dart';
import 'audit_state.dart';

/// BLoC para gestionar la lógica de auditoría
class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final AuditLogDao auditLogDao;

  AuditBloc({required this.auditLogDao}) : super(const AuditInitial()) {
    on<AuditLoadAllRequested>(_onLoadAllRequested);
    on<AuditLoadByUserRequested>(_onLoadByUserRequested);
    on<AuditLoadByActionRequested>(_onLoadByActionRequested);
    on<AuditLoadByEntityTypeRequested>(_onLoadByEntityTypeRequested);
    on<AuditLoadByDateRangeRequested>(_onLoadByDateRangeRequested);
    on<AuditLoadForEntityRequested>(_onLoadForEntityRequested);
    on<AuditLogActionRequested>(_onLogActionRequested);
    on<AuditGetActionsCountsRequested>(_onGetActionsCountsRequested);
  }

  /// Maneja la carga de todos los registros de auditoría
  Future<void> _onLoadAllRequested(
    AuditLoadAllRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final logs = await auditLogDao.getAllAuditLogs(
        limit: event.limit,
        offset: event.offset,
      );

      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError('Error al cargar registros de auditoría: ${e.toString()}'));
    }
  }

  /// Maneja la carga de registros por usuario
  Future<void> _onLoadByUserRequested(
    AuditLoadByUserRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final logs = await auditLogDao.getAuditLogsByUser(
        event.userId,
        limit: event.limit,
        offset: event.offset,
      );

      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError('Error al cargar registros del usuario: ${e.toString()}'));
    }
  }

  /// Maneja la carga de registros por acción
  Future<void> _onLoadByActionRequested(
    AuditLoadByActionRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final logs = await auditLogDao.getAuditLogsByAction(
        event.action,
        limit: event.limit,
        offset: event.offset,
      );

      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError('Error al cargar registros por acción: ${e.toString()}'));
    }
  }

  /// Maneja la carga de registros por tipo de entidad
  Future<void> _onLoadByEntityTypeRequested(
    AuditLoadByEntityTypeRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final logs = await auditLogDao.getAuditLogsByEntityType(
        event.entityType,
        limit: event.limit,
        offset: event.offset,
      );

      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError('Error al cargar registros por tipo de entidad: ${e.toString()}'));
    }
  }

  /// Maneja la carga de registros por rango de fechas
  Future<void> _onLoadByDateRangeRequested(
    AuditLoadByDateRangeRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final logs = await auditLogDao.getAuditLogsByDateRange(
        event.startDate,
        event.endDate,
        limit: event.limit,
        offset: event.offset,
      );

      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError('Error al cargar registros por fecha: ${e.toString()}'));
    }
  }

  /// Maneja la carga de registros para una entidad específica
  Future<void> _onLoadForEntityRequested(
    AuditLoadForEntityRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final logs = await auditLogDao.getAuditLogsForEntity(
        event.entityType,
        event.entityId,
      );

      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError('Error al cargar registros de la entidad: ${e.toString()}'));
    }
  }

  /// Maneja el registro de una nueva acción de auditoría
  Future<void> _onLogActionRequested(
    AuditLogActionRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      final auditLogId = await auditLogDao.logAction(
        userId: event.userId,
        action: event.action,
        description: event.description,
        entityType: event.entityType,
        entityId: event.entityId,
        oldValues: event.oldValues,
        newValues: event.newValues,
        ipAddress: event.ipAddress,
        deviceInfo: event.deviceInfo,
      );

      emit(AuditActionLogged(auditLogId));
    } catch (e) {
      emit(AuditError('Error al registrar acción de auditoría: ${e.toString()}'));
    }
  }

  /// Maneja la obtención de conteos de acciones
  Future<void> _onGetActionsCountsRequested(
    AuditGetActionsCountsRequested event,
    Emitter<AuditState> emit,
  ) async {
    try {
      emit(const AuditLoading());

      final counts = await auditLogDao.getActionsCounts();

      emit(AuditActionCountsLoaded(counts));
    } catch (e) {
      emit(AuditError('Error al obtener conteos de acciones: ${e.toString()}'));
    }
  }
}
