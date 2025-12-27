import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados para el BLoC de sesiones
abstract class SessionsState extends Equatable {
  const SessionsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class SessionsInitial extends SessionsState {
  const SessionsInitial();
}

/// Estado de carga
class SessionsLoading extends SessionsState {
  const SessionsLoading();
}

/// Estado cuando las sesiones fueron cargadas exitosamente
class SessionsLoaded extends SessionsState {
  final List<UserSessionData> sessions;

  const SessionsLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// Estado cuando se obtuvo la sesión activa
class SessionsActiveLoaded extends SessionsState {
  final UserSessionData? session;

  const SessionsActiveLoaded(this.session);

  @override
  List<Object?> get props => [session];
}

/// Estado de error
class SessionsError extends SessionsState {
  final String message;

  const SessionsError(this.message);

  @override
  List<Object?> get props => [message];
}
