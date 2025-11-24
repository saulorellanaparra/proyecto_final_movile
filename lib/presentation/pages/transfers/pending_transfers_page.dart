import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auth_helper.dart';
import '../../bloc/transfers/transfers_bloc.dart';
import '../../bloc/transfers/transfers_event.dart';
import '../../bloc/transfers/transfers_state.dart';
import 'transfer_detail_page.dart';

/// Pantalla de transferencias pendientes (para aprobar/rechazar)
class PendingTransfersPage extends StatefulWidget {
  const PendingTransfersPage({Key? key}) : super(key: key);

  @override
  State<PendingTransfersPage> createState() => _PendingTransfersPageState();
}

class _PendingTransfersPageState extends State<PendingTransfersPage> {
  @override
  void initState() {
    super.initState();
    _loadPendingTransfers();
  }

  void _loadPendingTransfers() {
    context.read<TransfersBloc>().add(const TransfersLoadPendingRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencias Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadPendingTransfers,
          ),
        ],
      ),
      body: BlocConsumer<TransfersBloc, TransfersState>(
        listener: (context, state) {
          if (state is TransferApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transferencia aprobada'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is TransferCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transferencia cancelada'),
                backgroundColor: AppColors.info,
              ),
            );
          } else if (state is TransfersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TransfersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransfersEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay transferencias pendientes',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todas las transferencias han sido procesadas',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is TransfersLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _loadPendingTransfers(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.transfers.length,
                itemBuilder: (context, index) {
                  final transfer = state.transfers[index];
                  return _buildPendingTransferCard(transfer);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPendingTransferCard(dynamic transfer) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transfer.transferNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(transfer.status),
              ],
            ),
            const SizedBox(height: 12),

            // Origen y Destino
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Origen',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transfer.fromType == 'STORE' ? 'Tienda' : 'Almacén'} #${transfer.fromId}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Destino',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transfer.toType == 'STORE' ? 'Tienda' : 'Almacén'} #${transfer.toId}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fecha
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dateFormat.format(transfer.transferDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (transfer.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                transfer.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Botones de acción
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _viewDetails(transfer.id),
                    child: const Text('Ver', style: TextStyle(fontSize: 13)),
                  ),
                  if (transfer.status == 'PENDING') ...[
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => _cancelTransfer(transfer.id),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => _approveTransfer(transfer.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Aprobar', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'PENDING':
        color = AppColors.warning;
        text = 'Pendiente';
        break;
      case 'APPROVED':
        color = AppColors.info;
        text = 'Aprobada';
        break;
      case 'RECEIVED':
        color = AppColors.success;
        text = 'Recibida';
        break;
      case 'CANCELLED':
        color = AppColors.error;
        text = 'Cancelada';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _viewDetails(int transferId) {
    final bloc = context.read<TransfersBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: TransferDetailPage(transferId: transferId),
        ),
      ),
    ).then((_) => _loadPendingTransfers());
  }

  void _approveTransfer(int transferId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprobar Transferencia'),
        content: const Text(
          '¿Está seguro de que desea aprobar esta transferencia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final userId = AuthHelper.getCurrentUserId(context);
              context.read<TransfersBloc>().add(
                    TransferApproveRequested(
                      transferId,
                      userId,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _cancelTransfer(int transferId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Transferencia'),
        content: const Text(
          '¿Está seguro de que desea cancelar esta transferencia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TransfersBloc>().add(
                    TransferCancelRequested(transferId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }
}
