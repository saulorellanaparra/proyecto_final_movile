import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/dependency_injection.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import 'product_form_page.dart';

/// Página de detalles del producto
class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductData? _currentProduct;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(
        productDao: getIt(),
        storesDao: getIt(),
        warehousesDao: getIt(),
        inventoryDao: getIt(),
      )
        ..add(ProductLoadByIdRequested(widget.productId))
        ..add(ProductVariantsLoadRequested(widget.productId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalles del Producto'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEdit(context),
            ),
          ],
        ),
        body: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductLoaded) {
              setState(() {
                _currentProduct = state.product;
              });
            } else if (state is ProductError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ProductVariantCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Variante creada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is ProductVariantDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Variante eliminada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProductLoading && _currentProduct == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_currentProduct == null) {
              return const Center(child: Text('Producto no encontrado'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ProductBloc>()
                    .add(ProductLoadByIdRequested(widget.productId));
                context
                    .read<ProductBloc>()
                    .add(ProductVariantsLoadRequested(widget.productId));
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProductInfo(_currentProduct!),
                    const SizedBox(height: 24),
                    _buildVariantsSection(context, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductInfo(ProductData product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: product.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Código: ${product.code}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (product.description != null) ...[
              const SizedBox(height: 12),
              Text(
                product.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                if (product.category != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.category,
                      'Categoría',
                      product.category!,
                      Colors.blue,
                    ),
                  ),
                if (product.brand != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.branding_watermark,
                      'Marca',
                      product.brand!,
                      Colors.purple,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceCard(
                    'Costo',
                    product.costPrice,
                    Colors.orange,
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPriceCard(
                    'Precio',
                    product.basePrice,
                    Colors.green,
                    Icons.sell,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMarginCard(product.costPrice, product.basePrice),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
      String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bs. ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarginCard(double costPrice, double basePrice) {
    final margin = ((basePrice - costPrice) / costPrice * 100);
    final profit = basePrice - costPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Margen de Ganancia',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${margin.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white30,
          ),
          Column(
            children: [
              const Text(
                'Ganancia Unitaria',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bs. ${profit.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection(BuildContext context, ProductState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Variantes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddVariantDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state is ProductVariantsLoaded)
              _buildVariantsList(context, state.variants)
            else if (state is ProductLoading)
              const Center(child: CircularProgressIndicator())
            else
              const Center(child: Text('Sin variantes')),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsList(
      BuildContext context, List<ProductVariantData> variants) {
    if (variants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.style_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No hay variantes registradas',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: variants.map((variant) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.grey[50],
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorFromString(variant.color ?? 'gris'),
              child: Text(
                variant.size != null && variant.size!.isNotEmpty
                    ? variant.size!.substring(0, 1)
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('${variant.size ?? 'N/A'} - ${variant.color ?? 'N/A'}'),
            subtitle: Text('SKU: ${variant.sku}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteVariant(context, variant),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorFromString(String colorName) {
    final colors = {
      'rojo': Colors.red,
      'azul': Colors.blue,
      'verde': Colors.green,
      'amarillo': Colors.yellow,
      'negro': Colors.black,
      'blanco': Colors.grey,
      'gris': Colors.grey,
      'morado': Colors.purple,
      'naranja': Colors.orange,
      'rosa': Colors.pink,
    };

    return colors[colorName.toLowerCase()] ?? Colors.blue;
  }

  void _showAddVariantDialog(BuildContext context) {
    final sizeController = TextEditingController();
    final colorController = TextEditingController();
    final skuController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Variante'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Talla *',
                  hintText: 'Ej: M, L, XL',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color *',
                  hintText: 'Ej: Rojo, Azul',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU Adicional',
                  hintText: 'Opcional',
                ),
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
                context.read<ProductBloc>().add(
                      ProductVariantCreateRequested(
                        productId: widget.productId,
                        size: sizeController.text.trim(),
                        color: colorController.text.trim(),
                        additionalSku: skuController.text.trim().isEmpty
                            ? null
                            : skuController.text.trim(),
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVariant(BuildContext context, ProductVariantData variant) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar variante ${variant.size} - ${variant.color}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ProductBloc>()
                  .add(ProductVariantDeleteRequested(variant.id));
              Navigator.pop(dialogContext);
              // Recargar variantes después de un breve delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  context
                      .read<ProductBloc>()
                      .add(ProductVariantsLoadRequested(widget.productId));
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    if (_currentProduct != null) {
      // Capturar la referencia al BLoC ANTES del builder
      final productBloc = context.read<ProductBloc>();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: productBloc,
            child: ProductFormPage(product: _currentProduct),
          ),
        ),
      );

      if (result == true && mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Producto actualizado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
