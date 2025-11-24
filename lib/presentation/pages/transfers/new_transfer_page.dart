import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/stores_dao.dart';
import '../../../data/database/daos/warehouses_dao.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../bloc/transfers/transfers_bloc.dart';
import '../../bloc/transfers/transfers_event.dart';
import '../../bloc/transfers/transfers_state.dart';

/// Pantalla para crear nueva transferencia
class NewTransferPage extends StatefulWidget {
  final LocationType fromType;
  final int fromId;

  const NewTransferPage({
    Key? key,
    required this.fromType,
    required this.fromId,
  }) : super(key: key);

  @override
  State<NewTransferPage> createState() => _NewTransferPageState();
}

class _NewTransferPageState extends State<NewTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  LocationType _toType = LocationType.store;
  int? _toId;
  final List<TransferItem> _items = [];

  // DAOs
  late StoresDao _storesDao;
  late WarehousesDao _warehousesDao;
  late InventoryDao _inventoryDao;

  // Listas de ubicaciones
  List<StoreData> _stores = [];
  List<WarehouseData> _warehouses = [];
  List<InventoryWithProductInfo> _availableProducts = [];
  bool _isLoadingLocations = true;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _storesDao = getIt<StoresDao>();
    _warehousesDao = getIt<WarehousesDao>();
    _inventoryDao = getIt<InventoryDao>();
    _loadLocations();
    _loadAvailableProducts();
  }

  /// Carga tiendas y almacenes disponibles
  Future<void> _loadLocations() async {
    try {
      final stores = await _storesDao.getActiveStores();
      final warehouses = await _warehousesDao.getActiveWarehouses();

      setState(() {
        _stores = stores;
        _warehouses = warehouses;
        _isLoadingLocations = false;

        // Establecer destino inicial diferente al origen
        if (widget.fromType == LocationType.warehouse) {
          // Si origen es almacén, destino inicial es tienda
          _toType = LocationType.store;
          if (_stores.isNotEmpty) {
            _toId = _stores.first.id;
          }
        } else {
          // Si origen es tienda, destino inicial es almacén
          _toType = LocationType.warehouse;
          if (_warehouses.isNotEmpty) {
            _toId = _warehouses.first.id;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ubicaciones: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Carga productos disponibles en el origen
  Future<void> _loadAvailableProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _inventoryDao.getInventoryWithProductInfoByLocation(
        widget.fromType,
        widget.fromId,
      );
      setState(() {
        _availableProducts = products.where((p) => p.inventory.quantity > 0).toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Transferencia'),
      ),
      body: BlocConsumer<TransfersBloc, TransfersState>(
        listener: (context, state) {
          if (state is TransferCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transferencia creada exitosamente'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is TransfersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is TransfersLoading;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origen
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Origen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${widget.fromType.displayName} #${widget.fromId}',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Destino
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destino',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingLocations)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            DropdownButtonFormField<LocationType>(
                              value: _toType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Ubicación',
                                border: OutlineInputBorder(),
                              ),
                              items: LocationType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _toType = value;
                                    // Establecer primera ubicación disponible
                                    if (value == LocationType.store && _stores.isNotEmpty) {
                                      _toId = _stores.first.id;
                                    } else if (value == LocationType.warehouse && _warehouses.isNotEmpty) {
                                      _toId = _warehouses.first.id;
                                    } else {
                                      _toId = null;
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Dropdown de ubicaciones específicas
                            if (_toType == LocationType.store)
                              _buildStoreDropdown()
                            else
                              _buildWarehouseDropdown(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Productos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: isLoading ? null : _addItem,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Agregar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_items.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No hay productos agregados',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withAlpha(25),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item.productName ?? 'Variante #${item.variantId}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.sku != null)
                                        Text(
                                          'SKU: ${item.sku}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        'Cantidad: ${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: AppColors.error),
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _items.removeAt(index);
                                            });
                                          },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                          hintText:
                              'Ingrese notas o comentarios sobre la transferencia',
                        ),
                        maxLines: 3,
                        enabled: !isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      // Botón fijo en la parte inferior
      bottomNavigationBar: BlocBuilder<TransfersBloc, TransfersState>(
        builder: (context, state) {
          final isLoading = state is TransfersLoading;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _saveTransfer,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    isLoading ? 'Creando...' : 'Crear Transferencia',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye el dropdown de tiendas
  Widget _buildStoreDropdown() {
    if (_stores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No hay tiendas activas disponibles',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _toId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Seleccionar Tienda',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.store),
      ),
      items: _stores.map((store) {
        return DropdownMenuItem(
          value: store.id,
          child: Text(
            '${store.name} (${store.code})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _toId = value);
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Debe seleccionar una tienda';
        }
        return null;
      },
    );
  }

  /// Construye el dropdown de almacenes
  Widget _buildWarehouseDropdown() {
    if (_warehouses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No hay almacenes activos disponibles',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _toId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Seleccionar Almacén',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse),
      ),
      items: _warehouses.map((warehouse) {
        return DropdownMenuItem(
          value: warehouse.id,
          child: Text(
            '${warehouse.name} (${warehouse.code})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _toId = value);
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Debe seleccionar un almacén';
        }
        return null;
      },
    );
  }

  void _addItem() {
    // Si no hay productos disponibles, mostrar mensaje
    if (_availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos con stock disponible en esta ubicación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    InventoryWithProductInfo? selectedProduct;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown de productos disponibles
                DropdownButtonFormField<InventoryWithProductInfo>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: _availableProducts.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.displayName,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Stock: ${product.inventory.quantity} | SKU: ${product.displaySku}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProduct = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: const OutlineInputBorder(),
                    helperText: selectedProduct != null
                        ? 'Disponible: ${selectedProduct!.inventory.quantity}'
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar un producto'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final quantity = int.tryParse(quantityController.text);

                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cantidad inválida'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (quantity > selectedProduct!.inventory.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cantidad excede el stock disponible (${selectedProduct!.inventory.quantity})',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Verificar si el producto ya está en la lista
                final existingIndex = _items.indexWhere(
                  (item) => item.variantId == selectedProduct!.inventory.productVariantId,
                );

                if (existingIndex >= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este producto ya está en la lista'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }

                setState(() {
                  _items.add(TransferItem(
                    variantId: selectedProduct!.inventory.productVariantId,
                    quantity: quantity,
                    productName: selectedProduct!.displayName,
                    sku: selectedProduct!.displaySku,
                  ));
                });

                Navigator.of(dialogContext).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransfer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar una ubicación de destino'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos un producto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validar que destino sea diferente al origen
    if (_toType == widget.fromType && _toId == widget.fromId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El destino debe ser diferente al origen'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    context.read<TransfersBloc>().add(
          TransferCreateRequested(
            fromType: widget.fromType,
            fromId: widget.fromId,
            toType: _toType,
            toId: _toId!,
            userId: AuthHelper.getCurrentUserId(context),
            items: _items,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          ),
        );
  }
}
