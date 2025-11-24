import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/theme/app_colors.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/database/daos/stores_dao.dart';
import '../../../data/database/daos/warehouses_dao.dart';
import '../../../data/database/app_database.dart';

/// Página de gestión de Tiendas y Almacenes
class LocationsPage extends StatefulWidget {
  const LocationsPage({Key? key}) : super(key: key);

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StoresDao _storesDao;
  late WarehousesDao _warehousesDao;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _storesDao = getIt<StoresDao>();
    _warehousesDao = getIt<WarehousesDao>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicaciones'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tiendas', icon: Icon(Icons.store)),
            Tab(text: 'Almacenes', icon: Icon(Icons.warehouse)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoresList(),
          _buildWarehousesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: Text(
          'Nueva ${_tabController.index == 0 ? "Tienda" : "Almacén"}',
        ),
      ),
    );
  }

  Widget _buildStoresList() {
    return FutureBuilder<List<StoreData>>(
      future: _storesDao.getAllStores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final stores = snapshot.data ?? [];

        if (stores.isEmpty) {
          return _buildEmptyState('tienda');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return _buildStoreCard(store);
          },
        );
      },
    );
  }

  Widget _buildWarehousesList() {
    return FutureBuilder<List<WarehouseData>>(
      future: _warehousesDao.getAllWarehouses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final warehouses = snapshot.data ?? [];

        if (warehouses.isEmpty) {
          return _buildEmptyState('almacén');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: warehouses.length,
          itemBuilder: (context, index) {
            final warehouse = warehouses[index];
            return _buildWarehouseCard(warehouse);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'tienda' ? Icons.store : Icons.warehouse,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ${type}s registradas',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(StoreData store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: store.isActive
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.textSecondary.withOpacity(0.1),
          child: Icon(
            Icons.store,
            color: store.isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          store.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    store.address,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (store.phone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    store.phone!,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    store.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(store.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditStoreDialog(store);
            } else if (value == 'toggle') {
              _toggleStoreStatus(store);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWarehouseCard(WarehouseData warehouse) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: warehouse.isActive
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.textSecondary.withOpacity(0.1),
          child: Icon(
            Icons.warehouse,
            color: warehouse.isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          warehouse.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    warehouse.address,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (warehouse.phone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    warehouse.phone!,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    warehouse.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(warehouse.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditWarehouseDialog(warehouse);
            } else if (value == 'toggle') {
              _toggleWarehouseStatus(warehouse);
            }
          },
        ),
      ),
    );
  }

  void _showAddDialog() {
    final type = _tabController.index == 0 ? 'tienda' : 'almacén';
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Nueva ${type[0].toUpperCase()}${type.substring(1)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Código (ej: ${_tabController.index == 0 ? 'T001' : 'A001'})',
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
            onPressed: () async {
              if (codeController.text.isEmpty ||
                  nameController.text.isEmpty ||
                  addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código, nombre y dirección son requeridos'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                if (_tabController.index == 0) {
                  // Tienda
                  await _storesDao.createStore(
                    StoresCompanion.insert(
                      code: codeController.text.trim().toUpperCase(),
                      name: nameController.text,
                      address: addressController.text,
                      phone: phoneController.text.isEmpty
                          ? const drift.Value.absent()
                          : drift.Value(phoneController.text),
                    ),
                  );
                } else {
                  // Almacén
                  await _warehousesDao.createWarehouse(
                    WarehousesCompanion.insert(
                      code: codeController.text.trim().toUpperCase(),
                      name: nameController.text,
                      address: addressController.text,
                      phone: phoneController.text.isEmpty
                          ? const drift.Value.absent()
                          : drift.Value(phoneController.text),
                    ),
                  );
                }

                Navigator.of(dialogContext).pop();
                setState(() {}); // Refresh the list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$type agregada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditStoreDialog(StoreData store) {
    final nameController = TextEditingController(text: store.name);
    final addressController = TextEditingController(text: store.address);
    final phoneController = TextEditingController(text: store.phone ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Tienda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
            onPressed: () async {
              try {
                await _storesDao.updateStore(
                  store.id,
                  StoresCompanion(
                    name: drift.Value(nameController.text),
                    address: drift.Value(addressController.text),
                    phone: phoneController.text.isEmpty
                        ? const drift.Value.absent()
                        : drift.Value(phoneController.text),
                  ),
                );

                Navigator.of(dialogContext).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tienda actualizada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditWarehouseDialog(WarehouseData warehouse) {
    final nameController = TextEditingController(text: warehouse.name);
    final addressController = TextEditingController(text: warehouse.address);
    final phoneController = TextEditingController(text: warehouse.phone ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Almacén'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
            onPressed: () async {
              try {
                await _warehousesDao.updateWarehouse(
                  warehouse.id,
                  WarehousesCompanion(
                    name: drift.Value(nameController.text),
                    address: drift.Value(addressController.text),
                    phone: phoneController.text.isEmpty
                        ? const drift.Value.absent()
                        : drift.Value(phoneController.text),
                  ),
                );

                Navigator.of(dialogContext).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Almacén actualizado exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleStoreStatus(StoreData store) async {
    try {
      if (store.isActive) {
        await _storesDao.deactivateStore(store.id);
      } else {
        await _storesDao.activateStore(store.id);
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tienda ${store.isActive ? "desactivada" : "activada"} exitosamente',
          ),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _toggleWarehouseStatus(WarehouseData warehouse) async {
    try {
      if (warehouse.isActive) {
        await _warehousesDao.deactivateWarehouse(warehouse.id);
      } else {
        await _warehousesDao.activateWarehouse(warehouse.id);
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Almacén ${warehouse.isActive ? "desactivado" : "activado"} exitosamente',
          ),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
