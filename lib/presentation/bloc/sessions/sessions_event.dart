import 'package:equatable/equatable.dart';

/// Eventos para el BLoC de sesiones
abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar las sesiones de un usuario
class SessionsLoadUserSessionsRequested extends SessionsEvent {
  final int userId;
  final int? limit;
  final int? offset;

  const SessionsLoadUserSessionsRequested({
    required this.userId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}

/// Evento para obtener la sesión activa de un usuario
class SessionsGetActiveRequested extends SessionsEvent {
  final int userId;

  const SessionsGetActiveRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Evento para obtener todas las sesiones activas del sistema
class SessionsGetAllActiveRequested extends SessionsEvent {
  const SessionsGetAllActiveRequested();
}

/// Evento para obtener sesiones en un rango de fechas
class SessionsLoadByDateRangeRequested extends SessionsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final int? userId;
  final int? limit;
  final int? offset;

  const SessionsLoadByDateRangeRequested({
    required this.startDate,
    required this.endDate,
    this.userId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [startDate, endDate, userId, limit, offset];
}
