import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/database/app_database.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';

/// Página de formulario de producto (crear/editar)
class ProductFormPage extends StatefulWidget {
  final ProductData? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();

  bool _isActive = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _skuController.text = widget.product!.code;
      _costController.text = widget.product!.costPrice.toStringAsFixed(2);
      _priceController.text = widget.product!.basePrice.toStringAsFixed(2);
      _categoryController.text = widget.product!.category;
      _brandController.text = widget.product!.brand ?? '';
      _isActive = widget.product!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductCreated || state is ProductUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing
                            ? 'Guardando cambios...'
                            : 'Creando producto...',
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(milliseconds: 1500),
                ),
              );
              // Pequeño delay para que se vea el mensaje
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              });
            } else if (state is ProductError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ProductLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre del producto
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del producto *',
                        hintText: 'Ej: Camisa Polo',
                        prefixIcon: const Icon(Icons.inventory_2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
                        }
                        if (value.length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Descripción detallada del producto',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),

                    // SKU
                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: 'SKU *',
                        hintText: 'Ej: CAM-POLO-001',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El SKU es requerido';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),

                    // Categoría y Marca
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              labelText: 'Categoría',
                              hintText: 'Ej: Camisas',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            enabled: !isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: InputDecoration(
                              labelText: 'Marca',
                              hintText: 'Ej: Nike',
                              prefixIcon: const Icon(Icons.branding_watermark),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            enabled: !isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Costo y Precio
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: InputDecoration(
                              labelText: 'Costo *',
                              hintText: '0.00',
                              prefixIcon: const Icon(Icons.attach_money),
                              prefixText: 'Bs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.orange[50],
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El costo es requerido';
                              }
                              final cost = double.tryParse(value);
                              if (cost == null || cost <= 0) {
                                return 'Ingresa un costo válido';
                              }
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Precio *',
                              hintText: '0.00',
                              prefixIcon: const Icon(Icons.sell),
                              prefixText: 'Bs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.green[50],
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El precio es requerido';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Ingresa un precio válido';
                              }
                              final cost = double.tryParse(_costController.text);
                              if (cost != null && price < cost) {
                                return 'El precio debe ser mayor al costo';
                              }
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Margen de ganancia calculado
                    if (_costController.text.isNotEmpty &&
                        _priceController.text.isNotEmpty)
                      _buildMarginInfo(),
                    const SizedBox(height: 16),

                    // Estado activo/inactivo
                    Card(
                      color: Colors.blue[50],
                      child: SwitchListTile(
                        title: const Text('Producto activo'),
                        subtitle: Text(
                          _isActive
                              ? 'El producto está disponible para venta'
                              : 'El producto está desactivado',
                        ),
                        value: _isActive,
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                        activeThumbColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(_isEditing ? 'Actualizar' : 'Crear Producto'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }

  Widget _buildMarginInfo() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (cost > 0 && price > 0) {
      final margin = ((price - cost) / cost * 100);
      final profit = price - cost;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'Margen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.blue[200],
            ),
            Column(
              children: [
                Text(
                  'Ganancia',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bs. ${profit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final cost = double.parse(_costController.text);
      final price = double.parse(_priceController.text);

      if (_isEditing) {
        context.read<ProductBloc>().add(
              ProductUpdateRequested(
                productId: widget.product!.id,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                sku: _skuController.text.trim().toUpperCase(),
                cost: cost,
                price: price,
                category: _categoryController.text.trim().isEmpty
                    ? null
                    : _categoryController.text.trim(),
                brand: _brandController.text.trim().isEmpty
                    ? null
                    : _brandController.text.trim(),
                isActive: _isActive,
              ),
            );
      } else {
        // Obtener el usuario actual para determinar su ubicación asignada
        final authState = context.read<AuthBloc>().state;
        int? userStoreId;
        int? userWarehouseId;

        if (authState is AuthAuthenticated) {
          userStoreId = authState.user.storeId;
          userWarehouseId = authState.user.warehouseId;
        }

        context.read<ProductBloc>().add(
              ProductCreateRequested(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                sku: _skuController.text.trim().toUpperCase(),
                cost: cost,
                price: price,
                category: _categoryController.text.trim().isEmpty
                    ? null
                    : _categoryController.text.trim(),
                brand: _brandController.text.trim().isEmpty
                    ? null
                    : _brandController.text.trim(),
                isActive: _isActive,
                userStoreId: userStoreId,
                userWarehouseId: userWarehouseId,
              ),
            );
      }
    }
  }
}
