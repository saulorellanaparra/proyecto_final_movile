import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/dependency_injection.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/purchases/purchases_bloc.dart';
import '../../bloc/purchases/purchases_event.dart';
import '../../bloc/purchases/purchases_state.dart';
import 'purchase_detail_page.dart';
import 'purchases_page.dart';

/// Página de lista de compras
class PurchasesListPage extends StatelessWidget {
  final int warehouseId;

  const PurchasesListPage({
    super.key,
    required this.warehouseId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PurchasesBloc(
        purchasesDao: getIt(),
        inventoryDao: getIt(),
      )..add(PurchasesLoadByWarehouseRequested(warehouseId: warehouseId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compras'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: BlocConsumer<PurchasesBloc, PurchasesState>(
          listener: (context, state) {
            if (state is PurchaseMarkedAsReceived) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compra recibida, inventario actualizado'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PurchasesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PurchasesEmpty) {
              return _buildEmptyState(context);
            }

            if (state is PurchasesLoaded) {
              return _buildPurchasesList(context, state.purchases);
            }

            if (state is PurchasesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(state.message),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToNewPurchase(context),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Nueva Compra'),
        ),
      ),
    );
  }

  Widget _buildPurchasesList(
    BuildContext context,
    List<PurchaseData> purchases,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PurchasesBloc>().add(
              PurchasesLoadByWarehouseRequested(warehouseId: warehouseId),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final purchase = purchases[index];
          return _buildPurchaseCard(context, purchase);
        },
      ),
    );
  }

  Widget _buildPurchaseCard(BuildContext context, PurchaseData purchase) {
    final statusColor = _getStatusColor(purchase.status);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(context, purchase.id),
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
                      purchase.purchaseNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(purchase.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Proveedor: ${purchase.supplierName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: ${dateFormat.format(purchase.purchaseDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Bs. ${purchase.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (purchase.status == 'PENDING') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsReceived(context, purchase),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Marcar como Recibida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay compras registradas',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _navigateToNewPurchase(context),
            icon: const Icon(Icons.add),
            label: const Text('Registrar compra'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'RECEIVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'RECEIVED':
        return 'RECIBIDA';
      case 'PENDING':
        return 'PENDIENTE';
      case 'CANCELLED':
        return 'CANCELADA';
      default:
        return status;
    }
  }

  void _markAsReceived(BuildContext context, PurchaseData purchase) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Recepción'),
        content: Text(
          '¿Confirmar que se recibió la compra ${purchase.purchaseNumber}?\n\n'
          'Esto actualizará el inventario del almacén.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PurchasesBloc>().add(
                    PurchaseMarkAsReceivedRequested(
                      purchaseId: purchase.id,
                      warehouseId: warehouseId,
                      userId: AuthHelper.getCurrentUserId(context),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, int purchaseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseDetailPage(purchaseId: purchaseId),
      ),
    );
  }

  void _navigateToNewPurchase(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchasesPage(warehouseId: warehouseId),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((range) {
      if (range != null) {
        context.read<PurchasesBloc>().add(
              PurchasesLoadByWarehouseRequested(
                warehouseId: warehouseId,
                startDate: range.start,
                endDate: range.end,
              ),
            );
      }
    });
  }
}
