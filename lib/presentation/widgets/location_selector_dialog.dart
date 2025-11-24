import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../core/services/dependency_injection.dart';
import '../../core/services/location_service.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/stores_dao.dart';
import '../../data/database/daos/warehouses_dao.dart';

/// Diálogo para seleccionar la ubicación de trabajo del usuario
class LocationSelectorDialog extends StatefulWidget {
  final UserData? currentUser;

  const LocationSelectorDialog({Key? key, this.currentUser}) : super(key: key);

  @override
  State<LocationSelectorDialog> createState() => _LocationSelectorDialogState();
}

class _LocationSelectorDialogState extends State<LocationSelectorDialog> {
  LocationType _selectedType = LocationType.store;
  int? _selectedLocationId;
  String? _selectedLocationName;
  bool _isLoading = true;

  List<StoreData> _stores = [];
  List<WarehouseData> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final storesDao = getIt<StoresDao>();
      final warehousesDao = getIt<WarehousesDao>();

      List<StoreData> stores = [];
      List<WarehouseData> warehouses = [];

      // Si el usuario tiene una tienda asignada, solo cargar esa tienda
      if (widget.currentUser?.storeId != null) {
        final store = await storesDao.getStoreById(widget.currentUser!.storeId!);
        if (store != null) {
          stores = [store];
          _selectedType = LocationType.store;
        }
      }
      // Si el usuario tiene un almacén asignado, solo cargar ese almacén
      else if (widget.currentUser?.warehouseId != null) {
        final warehouse = await warehousesDao.getWarehouseById(widget.currentUser!.warehouseId!);
        if (warehouse != null) {
          warehouses = [warehouse];
          _selectedType = LocationType.warehouse;
        }
      }
      // Si no tiene ubicación asignada (admin/gerente), cargar todas
      else {
        stores = await storesDao.getActiveStores();
        warehouses = await warehousesDao.getActiveWarehouses();
      }

      setState(() {
        _stores = stores;
        _warehouses = warehouses;
        _isLoading = false;

        // Seleccionar la primera (y única para usuarios con ubicación asignada) ubicación por defecto
        if (_selectedType == LocationType.store && stores.isNotEmpty) {
          _selectedLocationId = stores.first.id;
          _selectedLocationName = stores.first.name;
        } else if (_selectedType == LocationType.warehouse && warehouses.isNotEmpty) {
          _selectedLocationId = warehouses.first.id;
          _selectedLocationName = warehouses.first.name;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ubicaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Ubicación de Trabajo'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Solo mostrar selector de tipo si el usuario NO tiene ubicación asignada
                  if (widget.currentUser?.storeId == null && widget.currentUser?.warehouseId == null) ...[
                    const Text(
                      'Tipo de Ubicación:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<LocationType>(
                            title: const Text('Tienda'),
                            value: LocationType.store,
                            groupValue: _selectedType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedType = value;
                                  if (_stores.isNotEmpty) {
                                    _selectedLocationId = _stores.first.id;
                                    _selectedLocationName = _stores.first.name;
                                  } else {
                                    _selectedLocationId = null;
                                    _selectedLocationName = null;
                                  }
                                });
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<LocationType>(
                            title: const Text('Almacén'),
                            value: LocationType.warehouse,
                            groupValue: _selectedType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedType = value;
                                  if (_warehouses.isNotEmpty) {
                                    _selectedLocationId = _warehouses.first.id;
                                    _selectedLocationName = _warehouses.first.name;
                                  } else {
                                    _selectedLocationId = null;
                                    _selectedLocationName = null;
                                  }
                                });
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Seleccione Ubicación:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedType == LocationType.store)
                    ..._stores.map((store) => RadioListTile<int>(
                          title: Text(store.name),
                          subtitle: Text(store.address ?? 'Sin dirección'),
                          value: store.id,
                          groupValue: _selectedLocationId,
                          onChanged: (value) {
                            setState(() {
                              _selectedLocationId = value;
                              _selectedLocationName = store.name;
                            });
                          },
                        ))
                  else
                    ..._warehouses.map((warehouse) => RadioListTile<int>(
                          title: Text(warehouse.name),
                          subtitle: Text(warehouse.address ?? 'Sin dirección'),
                          value: warehouse.id,
                          groupValue: _selectedLocationId,
                          onChanged: (value) {
                            setState(() {
                              _selectedLocationId = value;
                              _selectedLocationName = warehouse.name;
                            });
                          },
                        )),
                  if ((_selectedType == LocationType.store && _stores.isEmpty) ||
                      (_selectedType == LocationType.warehouse && _warehouses.isEmpty))
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No hay ${_selectedType == LocationType.store ? 'tiendas' : 'almacenes'} disponibles',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedLocationId == null
              ? null
              : () async {
                  if (_selectedLocationId != null && _selectedLocationName != null) {
                    final locationService = LocationService();
                    await locationService.saveUserLocation(
                      locationType: _selectedType,
                      locationId: _selectedLocationId!,
                      locationName: _selectedLocationName!,
                    );

                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
