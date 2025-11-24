import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/location_service.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../products/product_list_page.dart';
import '../sales/sales_page.dart';
import '../sales/sales_list_page.dart';
import '../inventory/inventory_list_page.dart';
import '../purchases/purchases_list_page.dart';
import '../transfers/transfers_list_page.dart';
import '../transfers/pending_transfers_page.dart';
import '../reports/reports_dashboard_page.dart';
import '../settings/locations_page.dart';
import '../settings/employees_page.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/dependency_injection.dart';
import '../../bloc/transfers/transfers_bloc.dart';
import '../../bloc/reports/reports_bloc.dart';
import '../../widgets/location_selector_dialog.dart';

/// Pantalla principal del dashboard
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();
  Map<String, dynamic>? _userLocation;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _checkUserLocation();
  }

  Future<void> _checkUserLocation() async {
    final hasLocation = await _locationService.hasUserLocation();

    // Solo mostrar selector si no tiene ubicación Y el usuario no tiene ubicación asignada
    if (!hasLocation && mounted) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;

        // Si el usuario NO tiene ubicación asignada, mostrar selector
        if (user.storeId == null && user.warehouseId == null) {
          await _showLocationSelector();
        }
        // Si tiene ubicación asignada, esperar a que AuthBloc la configure
        else {
          // Esperar un momento para que AuthBloc configure la ubicación
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    await _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final location = await _locationService.getUserLocation();
    setState(() {
      _userLocation = location;
      _isLoadingLocation = false;
    });
  }

  Future<void> _showLocationSelector() async {
    final authState = context.read<AuthBloc>().state;
    UserData? currentUser;

    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationSelectorDialog(currentUser: currentUser),
    );

    if (result == true) {
      await _loadUserLocation();
    }
  }

  int get _locationId => _userLocation?['id'] ?? 1;
  LocationType get _locationType => _userLocation?['type'] ?? LocationType.store;
  String get _locationName => _userLocation?['name'] ?? 'Sin ubicación';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inventory Pro', style: TextStyle(fontSize: 18)),
            if (!_isLoadingLocation)
              Text(
                _locationName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          // Solo mostrar botón de cambiar ubicación si el usuario NO tiene ubicación asignada
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final bool canChangeLocation = state is AuthAuthenticated &&
                  state.user.storeId == null &&
                  state.user.warehouseId == null;

              return !_isLoadingLocation && canChangeLocation
                  ? IconButton(
                      icon: const Icon(Icons.location_on),
                      tooltip: 'Cambiar Ubicación',
                      onPressed: () async {
                        await _showLocationSelector();
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return _buildDashboard(context, state);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }

  Widget _buildDashboard(BuildContext context, AuthAuthenticated state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del usuario
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      state.user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido,',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          state.user.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            state.role.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Mostrar nombre de ubicación si está asignada
                        if (!_isLoadingLocation && _userLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _locationType == LocationType.store
                                      ? Icons.store
                                      : Icons.warehouse,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _locationName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Menú del dashboard
          const Text(
            'Menú Principal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid de opciones
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildDashboardCard(
                icon: Icons.inventory,
                title: 'Productos',
                subtitle: 'Gestión de productos',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListPage(),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.shopping_cart,
                title: 'Ventas',
                subtitle: 'Registrar ventas',
                color: AppColors.success,
                onTap: () {
                  if (state is AuthAuthenticated) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: false,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shopping_cart, color: AppColors.success, size: 28),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Ventas',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Items
                              ListTile(
                              leading: const Icon(Icons.add_shopping_cart, color: AppColors.success),
                              title: const Text('Nueva Venta'),
                              subtitle: const Text('Registrar una nueva venta'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                if (_locationType != LocationType.store) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Las ventas solo se pueden realizar desde una tienda'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalesPage(
                                      storeId: _locationId,
                                      userId: state.user.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.history, color: AppColors.success),
                              title: const Text('Historial'),
                              subtitle: const Text('Ver ventas anteriores'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                if (_locationType != LocationType.store) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('El historial de ventas solo está disponible para tiendas'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SalesListPage(storeId: _locationId),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    );
                  }
                },
              ),
              _buildDashboardCard(
                icon: Icons.inventory_2,
                title: 'Inventario',
                subtitle: 'Control de stock',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryListPage(
                        locationId: _locationId,
                        locationType: _locationType,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.receipt,
                title: 'Compras',
                subtitle: 'Registrar compras',
                color: AppColors.warning,
                onTap: () {
                  if (_locationType != LocationType.warehouse) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Las compras solo se pueden realizar desde un almacén'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchasesListPage(
                        warehouseId: _locationId,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.swap_horiz,
                title: 'Transferencias',
                subtitle: 'Entre almacenes',
                color: AppColors.info,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: false,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  const Icon(Icons.swap_horiz, color: AppColors.info, size: 28),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Transferencias',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Items
                            ListTile(
                            leading: const Icon(Icons.list, color: AppColors.info),
                            title: const Text('Mis Transferencias'),
                            subtitle: const Text('Ver transferencias de mi ubicación'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                    create: (context) => getIt<TransfersBloc>(),
                                    child: TransfersListPage(
                                      locationType: _locationType,
                                      locationId: _locationId,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.pending_actions, color: AppColors.info),
                            title: const Text('Pendientes de Aprobación'),
                            subtitle: const Text('Ver y aprobar transferencias'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                    create: (context) => getIt<TransfersBloc>(),
                                    child: const PendingTransfersPage(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.assessment,
                title: 'Reportes',
                subtitle: 'Ver estadísticas',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => getIt<ReportsBloc>(),
                        child: const ReportsDashboardPage(),
                      ),
                    ),
                  );
                },
              ),
              // Solo mostrar Configuración para roles administrativos
              if (state.role.code != 'VENDEDOR' &&
                  state.role.code != 'ALMACENERO' &&
                  state.role.code != 'ENCARGADO_TIENDA' &&
                  state.role.code != 'ENCARGADO_ALMACEN')
                _buildDashboardCard(
                  icon: Icons.settings,
                  title: 'Configuración',
                  subtitle: 'Ajustes del sistema',
                  color: AppColors.textSecondary,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: false,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    const Icon(Icons.settings, color: AppColors.primary, size: 28),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Configuración',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Items
                              ListTile(
                                leading: const Icon(Icons.location_on, color: AppColors.primary),
                                title: const Text('Ubicaciones'),
                                subtitle: const Text('Gestionar tiendas y almacenes'),
                                trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LocationsPage(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.people, color: AppColors.primary),
                            title: const Text('Empleados'),
                            subtitle: const Text('Gestionar personal'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmployeesPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
