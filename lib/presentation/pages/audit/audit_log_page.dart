import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/dependency_injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/audit/audit_bloc.dart';
import '../../bloc/audit/audit_event.dart';
import '../../bloc/audit/audit_state.dart';

/// Página de registro de auditoría
class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuditBloc(auditLogDao: getIt())
        ..add(const AuditLoadAllRequested(limit: 100)),
      child: const _AuditLogPageContent(),
    );
  }
}

class _AuditLogPageContent extends StatefulWidget {
  const _AuditLogPageContent();

  @override
  State<_AuditLogPageContent> createState() => _AuditLogPageContentState();
}

class _AuditLogPageContentState extends State<_AuditLogPageContent> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría del Sistema'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _applyFilter(context, value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Todas las acciones'),
              ),
              const PopupMenuItem(
                value: 'LOGIN',
                child: Text('Inicios de sesión'),
              ),
              const PopupMenuItem(
                value: 'LOGOUT',
                child: Text('Cierres de sesión'),
              ),
              const PopupMenuItem(
                value: 'CREATE',
                child: Text('Creaciones'),
              ),
              const PopupMenuItem(
                value: 'UPDATE',
                child: Text('Actualizaciones'),
              ),
              const PopupMenuItem(
                value: 'DELETE',
                child: Text('Eliminaciones'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
        ],
      ),
      body: BlocBuilder<AuditBloc, AuditState>(
        builder: (context, state) {
          if (state is AuditLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuditLogsLoaded) {
            if (state.logs.isEmpty) {
              return _buildEmptyState();
            }
            return _buildLogsList(context, state.logs);
          }

          if (state is AuditError) {
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
                      context.read<AuditBloc>().add(
                            const AuditLoadAllRequested(limit: 100),
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

  Widget _buildLogsList(BuildContext context, List<AuditLogData> logs) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedFilter == null || _selectedFilter == 'all') {
          context.read<AuditBloc>().add(
                const AuditLoadAllRequested(limit: 100),
              );
        } else {
          context.read<AuditBloc>().add(
                AuditLoadByActionRequested(
                  action: _selectedFilter!,
                  limit: 100,
                ),
              );
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogCard(log);
        },
      ),
    );
  }

  Widget _buildLogCard(AuditLogData log) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withOpacity(0.2),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Text(
          log.action,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: actionColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              log.description,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(log.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', '#${log.id}'),
                _buildDetailRow('Usuario ID', '#${log.userId}'),
                if (log.entityType != null)
                  _buildDetailRow('Tipo de entidad', log.entityType!),
                if (log.entityId != null)
                  _buildDetailRow('ID de entidad', '#${log.entityId}'),
                if (log.ipAddress != null)
                  _buildDetailRow('Dirección IP', log.ipAddress!),
                if (log.deviceInfo != null)
                  _buildDetailRow('Dispositivo', log.deviceInfo!),
                if (log.oldValues != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Valores anteriores:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.oldValues!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (log.newValues != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Valores nuevos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.newValues!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
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
            'No hay registros de auditoría',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'LOGIN':
        return Colors.green;
      case 'LOGOUT':
        return Colors.orange;
      case 'CREATE':
        return Colors.blue;
      case 'UPDATE':
        return Colors.amber;
      case 'DELETE':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'CREATE':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dt) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    return formatter.format(dt);
  }

  void _applyFilter(BuildContext context, String filter) {
    if (filter == 'all') {
      context.read<AuditBloc>().add(
            const AuditLoadAllRequested(limit: 100),
          );
    } else {
      context.read<AuditBloc>().add(
            AuditLoadByActionRequested(action: filter, limit: 100),
          );
    }
  }

  void _showDateRangePicker(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (range != null && mounted) {
      context.read<AuditBloc>().add(
            AuditLoadByDateRangeRequested(
              startDate: range.start,
              endDate: range.end,
              limit: 100,
            ),
          );
    }
  }
}
