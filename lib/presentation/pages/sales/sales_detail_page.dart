import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../core/services/receipt_service.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';

class SalesDetailPage extends StatelessWidget {
  final int saleId;

  const SalesDetailPage({super.key, required this.saleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SalesBloc(salesDao: getIt(), inventoryDao: getIt(), productDao: getIt())..add(SalesLoadByIdRequested(saleId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Venta'),
          actions: [
            BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                if (state is SaleDetailLoaded) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'Ver recibo',
                        onPressed: () => _previewReceipt(context, state),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Descargar recibo',
                        onPressed: () => _downloadReceipt(context, state),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            if (state is SalesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SaleDetailLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSaleInfo(state.sale),
                    const SizedBox(height: 16),
                    _buildReceiptActions(context, state),
                    const SizedBox(height: 24),
                    _buildItemsList(state.details, state.productNames),
                    const SizedBox(height: 24),
                    _buildTotalSection(state.sale),
                  ],
                ),
              );
            }

            if (state is SalesError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildReceiptActions(BuildContext context, SaleDetailLoaded state) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Recibo Digital',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _previewReceipt(context, state),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadReceipt(context, state),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _previewReceipt(BuildContext context, SaleDetailLoaded state) async {
    try {
      await ReceiptService.previewReceipt(
        sale: state.sale,
        details: state.details,
        productNames: state.productNames,
        storeName: 'Tienda de Ropa', // TODO: Obtener de configuración
        storeAddress: 'Dirección de la tienda',
        storePhone: '70012345',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al mostrar recibo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadReceipt(BuildContext context, SaleDetailLoaded state) async {
    try {
      final filePath = await ReceiptService.downloadReceipt(
        sale: state.sale,
        details: state.details,
        productNames: state.productNames,
        storeName: 'Tienda de Ropa', // TODO: Obtener de configuración
        storeAddress: 'Dirección de la tienda',
        storePhone: '70012345',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recibo guardado en: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSaleInfo(SaleData sale) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Venta #${sale.id}',
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
                    color: sale.status == 'COMPLETED'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sale.status,
                    style: TextStyle(
                      color: sale.status == 'COMPLETED'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Fecha:', dateFormat.format(sale.saleDate)),
            if (sale.customerName != null)
              _buildInfoRow('Cliente:', sale.customerName!),
            if (sale.customerDocument != null)
              _buildInfoRow('Documento:', sale.customerDocument!),
            _buildInfoRow('Método de Pago:', sale.paymentMethod),
          ],
        ),
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<SaleDetailData> details, Map<int, String> productNames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...details.map((detail) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productNames[detail.productVariantId] ?? 'Producto #${detail.productVariantId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bs. ${detail.unitPrice.toStringAsFixed(2)} x ${detail.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Bs. ${detail.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTotalSection(SaleData sale) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bs. ${sale.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
