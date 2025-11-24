import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../core/constants/enums.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';
import '../../widgets/product_variant_selector_dialog.dart';

/// Página de registro de venta (POS simplificado)
class SalesPage extends StatefulWidget {
  final int storeId;
  final int userId;

  const SalesPage({
    super.key,
    required this.storeId,
    required this.userId,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<SaleItem> _items = [];
  String _paymentMethod = 'EFECTIVO';

  // Datos del cliente
  String? _customerName;
  String? _customerDocument;
  String? _customerPhone;

  // BLoC y suscripción
  late final SalesBloc _salesBloc;
  StreamSubscription<SalesState>? _subscription;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _salesBloc = getIt<SalesBloc>();

    // Escuchar cambios de estado para navegación
    _subscription = _salesBloc.stream.listen(_handleStateChange);
  }

  void _handleStateChange(SalesState state) {
    if (!mounted || _isNavigating) return;

    if (state is SaleCreated) {
      _isNavigating = true;
      // Esperar a que el frame actual termine antes de navegar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _handleSaleCreated(state.total);
        }
      });
    } else if (state is SalesError) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _showErrorSnackBar(state.message);
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // No cerrar el BLoC aquí ya que puede causar problemas
    super.dispose();
  }

  void _handleSaleCreated(double total) {
    if (!mounted) return;

    // Primero navegar, luego mostrar el snackbar
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    // Mostrar snackbar después de navegar
    Future.delayed(const Duration(milliseconds: 50), () {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Venta registrada: Bs. ${total.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _salesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Venta'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                // Navegar a historial
              },
            ),
          ],
        ),
        body: BlocBuilder<SalesBloc, SalesState>(
          builder: (context, state) {
            final isLoading = state is SalesLoading;

            return SafeArea(
              child: Column(
                children: [
                  // Lista de items
                  Expanded(
                    child: _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('Agrega productos a la venta',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
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
                                      Text(
                                        'Bs. ${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                                      ),
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
                                        onPressed: () {
                                          setState(() {
                                            _items.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Panel inferior
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bs. ${_calculateTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Método de pago
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Método de pago',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA']
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _paymentMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Botones
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        await _showProductSelector();
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Agregar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isLoading || _items.isEmpty
                                    ? null
                                    : () => _showCustomerDataDialog(),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check, size: 20),
                                label: const Text('Completar Venta'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateTotal() {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  Future<void> _showProductSelector() async {
    final selection = await showDialog<ProductVariantSelection>(
      context: context,
      builder: (ctx) => ProductVariantSelectorDialog(
        locationType: LocationType.store,
        locationId: widget.storeId,
      ),
    );

    if (selection != null && mounted) {
      await _showQuantityDialog(selection);
    }
  }

  Future<void> _showQuantityDialog(ProductVariantSelection selection) async {
    final quantityController = TextEditingController(text: '1');

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cantidad'),
        content: Column(
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
            const SizedBox(height: 8),
            Text('Precio: Bs. ${selection.price.toStringAsFixed(2)}'),
            Text(
              'Stock disponible: ${selection.availableStock}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                if (quantity > selection.availableStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Stock insuficiente. Disponible: ${selection.availableStock}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, quantity);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _items.add(SaleItem(
          variantId: selection.variantId,
          quantity: result,
          unitPrice: selection.price,
          productName: selection.productName,
          variantDescription: selection.variantDescription,
        ));
      });
    }
  }

  Future<void> _showCustomerDataDialog() async {
    final nameController = TextEditingController();
    final documentController = TextEditingController();
    final phoneController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Datos del Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Resumen de la venta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a pagar:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bs. ${_calculateTotal().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Campos del cliente
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente *',
                  hintText: 'Ej: Juan Pérez',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: documentController,
                decoration: const InputDecoration(
                  labelText: 'NIT / CI',
                  hintText: 'Ej: 12345678',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej: 70012345',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Validar que al menos el nombre esté presente
              if (nameController.text.trim().isEmpty) {
                // Retornar null para indicar validación fallida
                Navigator.pop(dialogContext, null);
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirmar Venta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );

    // Limpiar controladores
    final name = nameController.text.trim();
    final document = documentController.text.trim();
    final phone = phoneController.text.trim();
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();

    // Validación fallida - mostrar mensaje y volver a intentar
    if (confirmed == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese el nombre del cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      // Volver a mostrar el diálogo
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showCustomerDataDialog();
        }
      });
      return;
    }

    if (confirmed == true && mounted) {
      // Guardar datos del cliente
      _customerName = name;
      _customerDocument = document.isEmpty ? null : document;
      _customerPhone = phone.isEmpty ? null : phone;

      // Proceder con la venta
      _salesBloc.add(
        SalesCreateRequested(
          storeId: widget.storeId,
          userId: widget.userId,
          items: _items,
          customerName: _customerName,
          customerDocument: _customerDocument,
          customerPhone: _customerPhone,
          paymentMethod: _paymentMethod,
        ),
      );
    }
  }
}
