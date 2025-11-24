import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/dependency_injection.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/purchases/purchases_bloc.dart';
import '../../bloc/purchases/purchases_event.dart';
import '../../bloc/purchases/purchases_state.dart';

/// Página de detalle de compra
class PurchaseDetailPage extends StatelessWidget {
  final int purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PurchasesBloc(
        purchasesDao: getIt(),
        inventoryDao: getIt(),
      )..add(PurchaseDetailsLoadRequested(purchaseId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Compra'),
        ),
        body: BlocBuilder<PurchasesBloc, PurchasesState>(
          builder: (context, state) {
            if (state is PurchasesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PurchaseDetailsLoaded) {
              return _buildDetails(state.purchase, state.details);
            }

            if (state is PurchasesError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDetails(
    PurchaseData purchase,
    List<PurchaseDetailData> details,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información de la compra
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        purchase.purchaseNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(purchase.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(purchase.status),
                          style: TextStyle(
                            color: _getStatusColor(purchase.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Proveedor', purchase.supplierName),
                  if (purchase.supplierRuc != null)
                    _buildInfoRow('RUC', purchase.supplierRuc!),
                  _buildInfoRow(
                    'Fecha',
                    dateFormat.format(purchase.purchaseDate),
                  ),
                  if (purchase.notes != null) ...[
                    const Divider(height: 24),
                    const Text('Notas:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(purchase.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de items
          const Text(
            'Items de Compra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Variante #${detail.productVariantId}'),
                  subtitle: Text(
                    'Cantidad: ${detail.quantity} x Bs. ${detail.unitCost.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    'Bs. ${detail.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),

          // Total
          const SizedBox(height: 16),
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bs. ${purchase.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
}
