import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../core/services/dependency_injection.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/product_dao.dart';
import '../../data/database/daos/inventory_dao.dart';

/// Resultado de la selección de producto/variante
class ProductVariantSelection {
  final int variantId;
  final String productName;
  final String variantDescription;
  final double price;
  final int availableStock;

  ProductVariantSelection({
    required this.variantId,
    required this.productName,
    required this.variantDescription,
    required this.price,
    required this.availableStock,
  });
}

/// Diálogo para buscar y seleccionar variantes de productos
class ProductVariantSelectorDialog extends StatefulWidget {
  final LocationType locationType;
  final int locationId;

  const ProductVariantSelectorDialog({
    Key? key,
    required this.locationType,
    required this.locationId,
  }) : super(key: key);

  @override
  State<ProductVariantSelectorDialog> createState() =>
      _ProductVariantSelectorDialogState();
}

class _ProductVariantSelectorDialogState
    extends State<ProductVariantSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ProductDao _productDao = getIt<ProductDao>();
  final InventoryDao _inventoryDao = getIt<InventoryDao>();

  List<ProductData> _products = [];
  List<ProductData> _filteredProducts = [];
  Map<int, List<ProductVariantData>> _productVariants = {};
  Map<int, int> _variantStock = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // Limpiar datos anteriores
      final newProductVariants = <int, List<ProductVariantData>>{};
      final newVariantStock = <int, int>{};

      final products = await _productDao.getAllActiveProducts();

      // Cargar variantes para cada producto
      for (final product in products) {
        final variants = await _productDao.getProductVariants(product.id);
        if (variants.isNotEmpty) {
          newProductVariants[product.id] = variants;

          // Cargar stock para cada variante
          for (final variant in variants) {
            final stock = await _inventoryDao.getAvailableQuantity(
              variant.id,
              widget.locationType,
              widget.locationId,
            );
            newVariantStock[variant.id] = stock;
          }
        }
      }

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _productVariants = newProductVariants;
          _variantStock = newVariantStock;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = _products);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            product.code.toLowerCase().contains(lowerQuery) ||
            (product.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  String _getVariantDescription(ProductVariantData variant) {
    final parts = <String>[];
    if (variant.size != null) parts.add('Talla: ${variant.size}');
    if (variant.color != null) parts.add('Color: ${variant.color}');
    if (parts.isEmpty) parts.add('SKU: ${variant.sku}');
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seleccionar Producto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : () {
                    setState(() => _isLoading = true);
                    _loadProducts();
                  },
                  tooltip: 'Refrescar lista',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o descripción...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),

            // Lista de productos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron productos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final variants = _productVariants[product.id] ?? [];

                            if (variants.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    product.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Código: ${product.code} | Bs. ${product.basePrice.toStringAsFixed(2)}',
                                ),
                                children: variants.map((variant) {
                                  final stock = _variantStock[variant.id] ?? 0;
                                  final totalPrice =
                                      product.basePrice + variant.additionalPrice;

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 4,
                                    ),
                                    title: Text(_getVariantDescription(variant)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Bs. ${totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: stock > 0
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: stock > 0
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                          child: Text(
                                            'Stock: $stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: stock > 0
                                                  ? Colors.green.shade900
                                                  : Colors.red.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: stock > 0
                                          ? () {
                                              Navigator.pop(
                                                context,
                                                ProductVariantSelection(
                                                  variantId: variant.id,
                                                  productName: product.name,
                                                  variantDescription:
                                                      _getVariantDescription(
                                                          variant),
                                                  price: totalPrice,
                                                  availableStock: stock,
                                                ),
                                              );
                                            }
                                          : null,
                                      child: const Text('Seleccionar'),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
