import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/dependency_injection.dart';
import '../../bloc/transfers/transfers_bloc.dart';
import '../../bloc/transfers/transfers_event.dart';
import '../../bloc/transfers/transfers_state.dart';
import 'transfer_detail_page.dart';
import 'new_transfer_page.dart';

/// Pantalla de lista de transferencias (salientes/entrantes)
class TransfersListPage extends StatefulWidget {
  final LocationType locationType;
  final int locationId;

  const TransfersListPage({
    Key? key,
    required this.locationType,
    required this.locationId,
  }) : super(key: key);

  @override
  State<TransfersListPage> createState() => _TransfersListPageState();
}

class _TransfersListPageState extends State<TransfersListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTransfers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadTransfers();
    }
  }

  void _loadTransfers() {
    if (_tabController.index == 0) {
      // Salientes
      context.read<TransfersBloc>().add(
            TransfersLoadOutgoingRequested(
              locationType: widget.locationType,
              locationId: widget.locationId,
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
    } else {
      // Entrantes
      context.read<TransfersBloc>().add(
            TransfersLoadIncomingRequested(
              locationType: widget.locationType,
              locationId: widget.locationId,
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por fecha',
            onPressed: _showDateFilter,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Salientes', icon: Icon(Icons.arrow_upward)),
            Tab(text: 'Entrantes', icon: Icon(Icons.arrow_downward)),
          ],
        ),
      ),
      body: BlocConsumer<TransfersBloc, TransfersState>(
        listener: (context, state) {
          if (state is TransfersError) {
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
                    Icons.swap_horiz,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay transferencias',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is TransfersLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _loadTransfers(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.transfers.length,
                itemBuilder: (context, index) {
                  final transfer = state.transfers[index];
                  return _buildTransferCard(transfer);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNewTransfer(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Transferencia'),
      ),
    );
  }

  Widget _buildTransferCard(dynamic transfer) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(transfer.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _tabController.index == 0
                          ? 'Destino: ${transfer.toType == 'STORE' ? 'Tienda' : 'Almacén'} #${transfer.toId}'
                          : 'Origen: ${transfer.fromType == 'STORE' ? 'Tienda' : 'Almacén'} #${transfer.fromId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(transfer.transferDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (transfer.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  transfer.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filtrar por Fecha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fecha Inicio'),
              subtitle: Text(
                _startDate != null
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'No seleccionada',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: dialogContext,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('Fecha Fin'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'No seleccionada',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: dialogContext,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.of(dialogContext).pop();
              _loadTransfers();
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _loadTransfers();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _navigateToNewTransfer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => getIt<TransfersBloc>(),
          child: NewTransferPage(
            fromType: widget.locationType,
            fromId: widget.locationId,
          ),
        ),
      ),
    ).then((_) => _loadTransfers());
  }

  void _navigateToDetail(int transferId) {
    final bloc = context.read<TransfersBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: TransferDetailPage(transferId: transferId),
        ),
      ),
    ).then((_) => _loadTransfers());
  }
}
