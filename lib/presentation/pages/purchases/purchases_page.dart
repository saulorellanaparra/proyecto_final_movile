import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/dependency_injection.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../core/constants/enums.dart';
import '../../bloc/purchases/purchases_bloc.dart';
import '../../bloc/purchases/purchases_event.dart';
import '../../bloc/purchases/purchases_state.dart';
import '../../widgets/product_variant_selector_dialog.dart';

/// Página para registrar nueva compra
class PurchasesPage extends StatefulWidget {
  final int warehouseId;

  const PurchasesPage({super.key, required this.warehouseId});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final _formKey = GlobalKey<FormState>();
  final _supplierNameController = TextEditingController();
  final _supplierRucController = TextEditingController();
  final _notesController = TextEditingController();
  final List<PurchaseItem> _items = [];

  @override
  void dispose() {
    _supplierNameController.dispose();
    _supplierRucController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PurchasesBloc(purchasesDao: getIt(), inventoryDao: getIt()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Compra'),
        ),
        body: BlocListener<PurchasesBloc, PurchasesState>(
          listener: (context, state) {
            if (state is PurchaseCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Compra registrada: Bs. ${state.total.toStringAsFixed(2)}'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            } else if (state is PurchasesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSupplierSection(),
                const SizedBox(height: 24),
                _buildItemsSection(),
                const SizedBox(height: 24),
                _buildNotesSection(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Datos del Proveedor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Proveedor *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supplierRucController,
              decoration: const InputDecoration(
                labelText: 'RUC',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Items de Compra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No hay items agregados'),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  color: Colors.grey[50],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.productName ?? 'Producto #${item.variantId}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.variantDescription != null)
                          Text(
                            item.variantDescription!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        Text('${item.quantity} x Bs. ${item.unitCost.toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bs. ${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            if (_items.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'Bs. ${_calculateTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notas',
        hintText: 'Observaciones adicionales',
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<PurchasesBloc, PurchasesState>(
      builder: (context, state) {
        final isLoading = state is PurchasesLoading;
        return ElevatedButton(
          onPressed: isLoading || _items.isEmpty ? null : _submitPurchase,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar Compra', style: TextStyle(fontSize: 16)),
        );
      },
    );
  }

  Future<void> _addItem() async {
    // Mostrar selector de productos
    final selection = await showDialog<ProductVariantSelection>(
      context: context,
      builder: (context) => ProductVariantSelectorDialog(
        locationType: LocationType.warehouse,
        locationId: widget.warehouseId,
      ),
    );

    if (selection != null && mounted) {
      // Mostrar diálogo de cantidad y costo
      await _showQuantityAndCostDialog(selection);
    }
  }

  Future<void> _showQuantityAndCostDialog(ProductVariantSelection selection) async {
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cantidad y Costo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selection.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                selection.variantDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (int.tryParse(v) == null || int.parse(v) <= 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Costo Unitario *',
                  prefixText: 'Bs. ',
                  border: OutlineInputBorder(),
                  helperText: 'Precio de compra por unidad',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Costo inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, {
                  'quantity': int.parse(quantityController.text),
                  'unitCost': double.parse(costController.text),
                });
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _items.add(PurchaseItem(
          variantId: selection.variantId,
          quantity: result['quantity'] as int,
          unitCost: result['unitCost'] as double,
          productName: selection.productName,
          variantDescription: selection.variantDescription,
        ));
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  void _submitPurchase() {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      context.read<PurchasesBloc>().add(
            PurchaseCreateRequested(
              warehouseId: widget.warehouseId,
              supplierName: _supplierNameController.text.trim(),
              supplierRuc: _supplierRucController.text.trim().isEmpty
                  ? null
                  : _supplierRucController.text.trim(),
              userId: AuthHelper.getCurrentUserId(context),
              items: _items,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
    }
  }
}
