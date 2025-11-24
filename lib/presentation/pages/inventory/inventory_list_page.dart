import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import '../../bloc/inventory/inventory_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import 'inventory_movements_page.dart';

/// Página de lista de inventario por ubicación
class InventoryListPage extends StatefulWidget {
  final int locationId;
  final LocationType locationType;

  const InventoryListPage({
    super.key,
    required this.locationId,
    required this.locationType,
  });

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> with WidgetsBindingObserver {
  String _filterType = 'all'; // all, in_stock, low_stock, out_of_stock
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Referencia al BLoC para poder refrescar
  InventoryBloc? _inventoryBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refrescar cuando la app vuelve al primer plano
    if (state == AppLifecycleState.resumed) {
      _refreshInventory();
    }
  }

  void _refreshInventory() {
    if (_inventoryBloc != null) {
      _inventoryBloc!.add(
        InventoryLoadByLocationRequested(
          locationType: widget.locationType,
          locationId: widget.locationId,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final bloc = InventoryBloc(inventoryDao: getIt())
              ..add(InventoryLoadByLocationRequested(
                locationType: widget.locationType,
                locationId: widget.locationId,
              ));
            _inventoryBloc = bloc;
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) => ProductBloc(
            productDao: getIt(),
            storesDao: getIt(),
            warehousesDao: getIt(),
            inventoryDao: getIt(),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Inventario - ${widget.locationType == LocationType.store ? 'Tienda' : 'Almacén'}',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshInventory,
              tooltip: 'Actualizar inventario',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _navigateToMovements(context),
              tooltip: 'Ver movimientos',
            ),
          ],
        ),
        body: Builder(
          builder: (builderContext) => Column(
            children: [
              _buildSearchBar(builderContext),
              _buildFilterChips(builderContext),
              Expanded(
                child: BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    if (state is InventoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is InventoryEmpty) {
                      return _buildEmptyState();
                    }

                    if (state is InventoryLoadedWithProductInfo) {
                      return _buildInventoryListWithProductInfo(context, state.items);
                    }

                    if (state is InventoryLowStockLoadedWithProductInfo) {
                      return _buildInventoryListWithProductInfo(context, state.items,
                          title: 'Stock Bajo');
                    }

                    if (state is InventoryOutOfStockLoadedWithProductInfo) {
                      return _buildInventoryListWithProductInfo(context, state.items,
                          title: 'Sin Stock');
                    }

                    if (state is InventoryError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 60, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(state.message),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de búsqueda
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, SKU o marca...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Todos'),
              selected: _filterType == 'all',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterType = 'all');
                  context.read<InventoryBloc>().add(
                        InventoryLoadByLocationRequested(
                          locationType: widget.locationType,
                          locationId: widget.locationId,
                        ),
                      );
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Con Stock'),
              selected: _filterType == 'in_stock',
              avatar: Icon(
                Icons.check_circle,
                size: 18,
                color: _filterType == 'in_stock' ? Colors.white : Colors.green,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterType = 'in_stock');
                  // Cargar todos y filtrar localmente
                  context.read<InventoryBloc>().add(
                        InventoryLoadByLocationRequested(
                          locationType: widget.locationType,
                          locationId: widget.locationId,
                        ),
                      );
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Stock Bajo'),
              selected: _filterType == 'low_stock',
              avatar: Icon(
                Icons.warning,
                size: 18,
                color: _filterType == 'low_stock' ? Colors.white : Colors.orange,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterType = 'low_stock');
                  context.read<InventoryBloc>().add(
                        InventoryLoadLowStockRequested(
                          locationType: widget.locationType,
                          locationId: widget.locationId,
                        ),
                      );
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Sin Stock'),
              selected: _filterType == 'out_of_stock',
              avatar: Icon(
                Icons.remove_circle,
                size: 18,
                color: _filterType == 'out_of_stock' ? Colors.white : Colors.red,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterType = 'out_of_stock');
                  context.read<InventoryBloc>().add(
                        InventoryLoadOutOfStockRequested(
                          locationType: widget.locationType,
                          locationId: widget.locationId,
                        ),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    List<InventoryData> items, {
    String? title,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InventoryBloc>().add(
              InventoryLoadByLocationRequested(
                locationType: widget.locationType,
                locationId: widget.locationId,
              ),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (title != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (title != null && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final item = items[title != null ? index - 1 : index];
          return _buildInventoryCard(context, item);
        },
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, InventoryData item) {
    final stockLevel = _getStockLevel(item);
    final stockColor = _getStockColor(stockLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor.withOpacity(0.2),
          child: Icon(
            _getStockIcon(stockLevel),
            color: stockColor,
          ),
        ),
        title: Text('Variante #${item.productVariantId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Stock: ${item.quantity} unidades'),
            if (item.minStock != null)
              Text(
                'Mínimo: ${item.minStock}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: stockColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStockLevelText(stockLevel),
            style: TextStyle(
              color: stockColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showInventoryDetail(context, item),
      ),
    );
  }

  // ==================== NUEVOS MÉTODOS CON INFORMACIÓN ENRIQUECIDA ====================

  /// Aplica filtros locales a la lista de inventario
  List<InventoryWithProductInfo> _applyLocalFilters(List<InventoryWithProductInfo> items) {
    var filteredItems = items;

    // Filtro por tipo (Con Stock)
    if (_filterType == 'in_stock') {
      filteredItems = filteredItems.where((item) => item.inventory.quantity > 0).toList();
    }

    // Filtro por búsqueda de texto
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final productName = item.product.name.toLowerCase();
        final sku = item.displaySku.toLowerCase();
        final brand = (item.brand ?? '').toLowerCase();
        final category = item.category.toLowerCase();
        final size = (item.variant.size ?? '').toLowerCase();
        final color = (item.variant.color ?? '').toLowerCase();

        return productName.contains(_searchQuery) ||
            sku.contains(_searchQuery) ||
            brand.contains(_searchQuery) ||
            category.contains(_searchQuery) ||
            size.contains(_searchQuery) ||
            color.contains(_searchQuery);
      }).toList();
    }

    return filteredItems;
  }

  Widget _buildInventoryListWithProductInfo(
    BuildContext context,
    List<InventoryWithProductInfo> items, {
    String? title,
  }) {
    // Aplicar filtros locales
    final filteredItems = _applyLocalFilters(items);

    // Si la lista filtrada está vacía, mostrar mensaje apropiado
    if (filteredItems.isEmpty) {
      // Determinar el mensaje según el filtro activo
      String emptyMessage;
      IconData emptyIcon;

      if (_searchQuery.isNotEmpty) {
        emptyMessage = 'No se encontraron productos\nque coincidan con "$_searchQuery"';
        emptyIcon = Icons.search_off;
      } else if (_filterType == 'in_stock') {
        emptyMessage = 'No hay productos con stock disponible';
        emptyIcon = Icons.check_circle_outline;
      } else if (title == 'Stock Bajo') {
        emptyMessage = 'No hay productos con stock bajo\n(menos de 5 unidades)';
        emptyIcon = Icons.warning_amber;
      } else if (title == 'Sin Stock') {
        emptyMessage = 'No hay productos sin stock';
        emptyIcon = Icons.remove_circle_outline;
      } else {
        emptyMessage = 'No hay productos en inventario';
        emptyIcon = Icons.inventory_2_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _filterType = 'all';
                  _searchController.clear();
                  _searchQuery = '';
                });
                context.read<InventoryBloc>().add(
                      InventoryLoadByLocationRequested(
                        locationType: widget.locationType,
                        locationId: widget.locationId,
                      ),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<InventoryBloc>().add(
              InventoryLoadByLocationRequested(
                locationType: widget.locationType,
                locationId: widget.locationId,
              ),
            );
      },
      child: Column(
        children: [
          // Mostrar contador de resultados si hay búsqueda activa
          if (_searchQuery.isNotEmpty || _filterType == 'in_stock')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${filteredItems.length} producto${filteredItems.length != 1 ? 's' : ''} encontrado${filteredItems.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length + (title != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (title != null && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final item = filteredItems[title != null ? index - 1 : index];
                return _buildInventoryCardWithProductInfo(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCardWithProductInfo(
      BuildContext context, InventoryWithProductInfo item) {
    final stockLevel = _getStockLevel(item.inventory);
    final stockColor = _getStockColor(stockLevel);
    final isOutOfStock = item.inventory.quantity == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: stockColor.withOpacity(0.2),
              child: Icon(
                _getStockIcon(stockLevel),
                color: stockColor,
              ),
            ),
            title: Text(
              item.displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'SKU: ${item.displaySku}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text('Stock: ${item.inventory.quantity} unidades'),
                if (item.brand != null && item.brand!.isNotEmpty)
                  Text(
                    'Marca: ${item.brand}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                if (item.inventory.minStock != null)
                  Text(
                    'Mínimo: ${item.inventory.minStock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: stockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStockLevelText(stockLevel),
                style: TextStyle(
                  color: stockColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => _showInventoryDetailWithProductInfo(context, item),
          ),
          // Mostrar botón de desactivar cuando el stock es 0
          if (isOutOfStock && item.product.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sin stock - Producto activo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _deactivateProduct(context, item),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Desactivar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Desactivar producto
  void _deactivateProduct(BuildContext context, InventoryWithProductInfo item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desactivar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas desactivar el producto "${item.product.name}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El producto quedará inactivo y no aparecerá en la lista de productos activos.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
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
              context.read<ProductBloc>().add(
                    ProductDeactivateRequested(item.product.id),
                  );
              Navigator.pop(dialogContext);

              // Recargar inventario después de un breve delay
              Future.delayed(const Duration(milliseconds: 500), () {
                context.read<InventoryBloc>().add(
                      InventoryLoadByLocationRequested(
                        locationType: widget.locationType,
                        locationId: widget.locationId,
                      ),
                    );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _showInventoryDetailWithProductInfo(
      BuildContext context, InventoryWithProductInfo item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('SKU', item.displaySku),
            if (item.variant.size != null && item.variant.size!.isNotEmpty)
              _buildDetailRow('Talla', item.variant.size!),
            if (item.variant.color != null && item.variant.color!.isNotEmpty)
              _buildDetailRow('Color', item.variant.color!),
            if (item.brand != null && item.brand!.isNotEmpty)
              _buildDetailRow('Marca', item.brand!),
            _buildDetailRow('Categoría', item.category),
            const Divider(),
            _buildDetailRow('Cantidad actual', '${item.inventory.quantity}'),
            if (item.inventory.minStock != null)
              _buildDetailRow('Stock mínimo', '${item.inventory.minStock}'),
            if (item.inventory.maxStock != null)
              _buildDetailRow('Stock máximo', '${item.inventory.maxStock}'),
            const Divider(),
            Text(
              'Última actualización: ${_formatDateTime(item.inventory.lastUpdated)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showAdjustDialogWithProductInfo(context, item);
            },
            child: const Text('Ajustar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay productos en inventario',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showAdjustDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar producto'),
          ),
        ],
      ),
    );
  }

  String _getStockLevel(InventoryData item) {
    if (item.quantity == 0) return 'out';
    if (item.minStock != null && item.quantity < item.minStock!) return 'low';
    return 'ok';
  }

  Color _getStockColor(String level) {
    switch (level) {
      case 'out':
        return Colors.red;
      case 'low':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getStockIcon(String level) {
    switch (level) {
      case 'out':
        return Icons.remove_circle;
      case 'low':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }

  String _getStockLevelText(String level) {
    switch (level) {
      case 'out':
        return 'SIN STOCK';
      case 'low':
        return 'BAJO';
      default:
        return 'OK';
    }
  }

  void _showInventoryDetail(BuildContext context, InventoryData item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalle de Inventario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Variante', '#${item.productVariantId}'),
            _buildDetailRow('Cantidad actual', '${item.quantity}'),
            if (item.minStock != null)
              _buildDetailRow('Stock mínimo', '${item.minStock}'),
            if (item.maxStock != null)
              _buildDetailRow('Stock máximo', '${item.maxStock}'),
            const Divider(),
            Text(
              'Última actualización: ${_formatDateTime(item.lastUpdated)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showAdjustDialog(context, item);
            },
            child: const Text('Ajustar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, [InventoryData? item]) {
    final quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '0',
    );
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajustar Inventario'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Variante #${item.productVariantId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Nueva cantidad *',
                  hintText: '0',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Motivo del ajuste',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
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
              if (formKey.currentState!.validate() && item != null) {
                context.read<InventoryBloc>().add(
                      InventoryAdjustRequested(
                        variantId: item.productVariantId,
                        locationType: widget.locationType,
                        locationId: widget.locationId,
                        newQuantity: int.parse(quantityController.text),
                        userId: AuthHelper.getCurrentUserId(context),
                        notes: notesController.text.isEmpty
                            ? null
                            : notesController.text,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Ajustar'),
          ),
        ],
      ),
    );
  }

  /// Diálogo de ajuste con opción de desactivar automáticamente
  void _showAdjustDialogWithProductInfo(
      BuildContext context, InventoryWithProductInfo item) {
    final quantityController = TextEditingController(
      text: item.inventory.quantity.toString(),
    );
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool deactivateIfZero = false;

    // Capturar el contexto del widget antes de abrir el diálogo
    final widgetContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) {
          final newQuantity = int.tryParse(quantityController.text) ?? 0;
          final willBeZero = newQuantity == 0;

          return AlertDialog(
            title: Text('Ajustar: ${item.product.name}'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'SKU: ${item.displaySku}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva cantidad *',
                      hintText: '0',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty < 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      hintText: 'Motivo del ajuste',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  // Mostrar checkbox si la cantidad será 0 y el producto está activo
                  if (willBeZero && item.product.isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: CheckboxListTile(
                        value: deactivateIfZero,
                        onChanged: (value) {
                          setState(() {
                            deactivateIfZero = value ?? false;
                          });
                        },
                        title: const Text(
                          'Desactivar producto automáticamente',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Al quedar sin stock, el producto será desactivado',
                          style: TextStyle(fontSize: 11),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
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
                    final newQty = int.parse(quantityController.text);

                    // Ajustar inventario
                    widgetContext.read<InventoryBloc>().add(
                          InventoryAdjustRequested(
                            variantId: item.inventory.productVariantId,
                            locationType: widget.locationType,
                            locationId: widget.locationId,
                            newQuantity: newQty,
                            userId: AuthHelper.getCurrentUserId(widgetContext),
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          ),
                        );

                    // Si está marcado y la cantidad es 0, desactivar producto
                    if (deactivateIfZero && newQty == 0) {
                      widgetContext.read<ProductBloc>().add(
                            ProductDeactivateRequested(item.product.id),
                          );
                    }

                    Navigator.pop(dialogContext);

                    // Recargar inventario
                    Future.delayed(const Duration(milliseconds: 500), () {
                      widgetContext.read<InventoryBloc>().add(
                            InventoryLoadByLocationRequested(
                              locationType: widget.locationType,
                              locationId: widget.locationId,
                            ),
                          );
                    });
                  }
                },
                child: const Text('Ajustar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToMovements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryMovementsPage(
          locationId: widget.locationId,
          locationType: widget.locationType,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
