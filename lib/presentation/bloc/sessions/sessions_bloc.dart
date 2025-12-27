import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/daos/user_sessions_dao.dart';
import 'sessions_event.dart';
import 'sessions_state.dart';

/// BLoC para gestionar la lógica de sesiones de usuario
class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final UserSessionsDao userSessionsDao;

  SessionsBloc({required this.userSessionsDao}) : super(const SessionsInitial()) {
    on<SessionsLoadUserSessionsRequested>(_onLoadUserSessionsRequested);
    on<SessionsGetActiveRequested>(_onGetActiveRequested);
    on<SessionsGetAllActiveRequested>(_onGetAllActiveRequested);
    on<SessionsLoadByDateRangeRequested>(_onLoadByDateRangeRequested);
  }

  /// Maneja la carga de sesiones de un usuario
  Future<void> _onLoadUserSessionsRequested(
    SessionsLoadUserSessionsRequested event,
    Emitter<SessionsState> emit,
  ) async {
    try {
      emit(const SessionsLoading());

      final sessions = await userSessionsDao.getUserSessions(
        event.userId,
        limit: event.limit,
        offset: event.offset,
      );

      emit(SessionsLoaded(sessions));
    } catch (e) {
      emit(SessionsError('Error al cargar sesiones del usuario: ${e.toString()}'));
    }
  }

  /// Maneja la obtención de la sesión activa
  Future<void> _onGetActiveRequested(
    SessionsGetActiveRequested event,
    Emitter<SessionsState> emit,
  ) async {
    try {
      emit(const SessionsLoading());

      final session = await userSessionsDao.getActiveSession(event.userId);

      emit(SessionsActiveLoaded(session));
    } catch (e) {
      emit(SessionsError('Error al obtener sesión activa: ${e.toString()}'));
    }
  }

  /// Maneja la obtención de todas las sesiones activas
  Future<void> _onGetAllActiveRequested(
    SessionsGetAllActiveRequested event,
    Emitter<SessionsState> emit,
  ) async {
    try {
      emit(const SessionsLoading());

      final sessions = await userSessionsDao.getAllActiveSessions();

      emit(SessionsLoaded(sessions));
    } catch (e) {
      emit(SessionsError('Error al obtener sesiones activas: ${e.toString()}'));
    }
  }

  /// Maneja la carga de sesiones por rango de fechas
  Future<void> _onLoadByDateRangeRequested(
    SessionsLoadByDateRangeRequested event,
    Emitter<SessionsState> emit,
  ) async {
    try {
      emit(const SessionsLoading());

      final sessions = await userSessionsDao.getSessionsByDateRange(
        event.startDate,
        event.endDate,
        userId: event.userId,
        limit: event.limit,
        offset: event.offset,
      );

      emit(SessionsLoaded(sessions));
    } catch (e) {
      emit(SessionsError('Error al cargar sesiones por fecha: ${e.toString()}'));
    }
  }
}
