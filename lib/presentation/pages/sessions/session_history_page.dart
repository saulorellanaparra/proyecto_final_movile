import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/dependency_injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/user_sessions_dao.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/sessions/sessions_bloc.dart';
import '../../bloc/sessions/sessions_event.dart';
import '../../bloc/sessions/sessions_state.dart';

/// Página de historial de sesiones del usuario
class SessionHistoryPage extends StatelessWidget {
  final int? userId;

  const SessionHistoryPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    // Obtener el userId del usuario autenticado si no se proporciona
    final authState = context.read<AuthBloc>().state;
    final effectiveUserId = userId ??
        (authState is AuthAuthenticated ? authState.user.id : null);

    if (effectiveUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de Sesiones')),
        body: const Center(
          child: Text('Usuario no autenticado'),
        ),
      );
    }

    return BlocProvider(
      create: (context) => SessionsBloc(userSessionsDao: getIt())
        ..add(SessionsLoadUserSessionsRequested(
          userId: effectiveUserId,
          limit: 50,
        )),
      child: _SessionHistoryPageContent(userId: effectiveUserId),
    );
  }
}

class _SessionHistoryPageContent extends StatelessWidget {
  final int userId;

  const _SessionHistoryPageContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Sesiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
        ],
      ),
      body: BlocBuilder<SessionsBloc, SessionsState>(
        builder: (context, state) {
          if (state is SessionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SessionsLoaded) {
            if (state.sessions.isEmpty) {
              return _buildEmptyState();
            }
            return _buildSessionsList(context, state.sessions);
          }

          if (state is SessionsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SessionsBloc>().add(
                            SessionsLoadUserSessionsRequested(
                              userId: userId,
                              limit: 50,
                            ),
                          );
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSessionsList(
    BuildContext context,
    List<UserSessionData> sessions,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SessionsBloc>().add(
              SessionsLoadUserSessionsRequested(
                userId: userId,
                limit: 50,
              ),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(UserSessionData session) {
    final isActive = session.isActive;
    final duration = _getSessionDuration(session);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppColors.success.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            isActive ? Icons.circle : Icons.check_circle,
            color: isActive ? AppColors.success : Colors.grey,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              _formatDateTime(session.loginAt),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (session.deviceInfo != null)
              Text(
                session.deviceInfo!,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 2),
            Text(
              duration,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (session.ipAddress != null) ...[
              const SizedBox(height: 2),
              Text(
                'IP: ${session.ipAddress}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: session.logoutAt != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.logout, size: 16, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(session.logoutAt!),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay sesiones registradas',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dt);
  }

  String _getSessionDuration(UserSessionData session) {
    final userSessionsDao = getIt<UserSessionsDao>();

    if (session.logoutAt != null) {
      final duration = userSessionsDao.getSessionDuration(session);
      if (duration != null) {
        return _formatDuration(duration);
      }
    } else {
      final duration = userSessionsDao.getCurrentSessionDuration(session);
      return '${_formatDuration(duration)} (en curso)';
    }

    return 'Duración desconocida';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }

  void _showDateRangePicker(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (range != null && context.mounted) {
      context.read<SessionsBloc>().add(
            SessionsLoadByDateRangeRequested(
              startDate: range.start,
              endDate: range.end,
              userId: userId,
              limit: 50,
            ),
          );
    }
  }
}
