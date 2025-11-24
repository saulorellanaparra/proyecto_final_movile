import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/sales/sales_bloc.dart';
import '../../bloc/sales/sales_event.dart';
import '../../bloc/sales/sales_state.dart';
import 'sales_detail_page.dart';

class SalesListPage extends StatefulWidget {
  final int? storeId; // Opcional para encargados de almacén

  const SalesListPage({super.key, this.storeId});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedStoreId; // Para filtrar por tienda
  bool _isWarehouseManager = false;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.storeId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar rol del usuario
    final authState = context.read<AuthBloc>().state;
    String? roleCode;
    if (authState is AuthAuthenticated) {
      roleCode = authState.role.code;
    }
    _isWarehouseManager = roleCode == UserRole.encargadoAlmacen.code ||
        roleCode == UserRole.superAdmin.code ||
        roleCode == UserRole.gerenteGeneral.code;

    return BlocProvider(
      create: (context) {
        final bloc = SalesBloc(
          salesDao: getIt(),
          inventoryDao: getIt(),
          productDao: getIt(),
          storesDao: getIt(),
        );

        // Cargar según el rol
        if (_isWarehouseManager && widget.storeId == null) {
          bloc.add(const SalesLoadAllStoresRequested());
        } else if (widget.storeId != null) {
          bloc.add(SalesLoadTodayByStoreRequested(widget.storeId!));
        }

        return bloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isWarehouseManager ? 'Ventas - Todas las Tiendas' : 'Historial de Ventas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Campo de búsqueda por nombre de cliente
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre de cliente...',
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
            ),

            // Lista de ventas
            Expanded(
              child: BlocBuilder<SalesBloc, SalesState>(
                builder: (context, state) {
                  if (state is SalesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SalesEmpty) {
                    return _buildEmptyState();
                  }

                  // Ventas de todas las tiendas (para encargados de almacén)
                  if (state is SalesAllStoresLoaded) {
                    return _buildAllStoresSalesView(context, state);
                  }

                  // Ventas de una tienda específica
                  if (state is SalesLoaded) {
                    return _buildSingleStoreSalesView(context, state);
                  }

                  if (state is SalesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(state.message, textAlign: TextAlign.center),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No hay ventas', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// Vista para ventas de todas las tiendas (encargados de almacén)
  Widget _buildAllStoresSalesView(BuildContext context, SalesAllStoresLoaded state) {
    // Filtro por tienda seleccionada
    final storeIds = state.salesByStore.keys.toList();

    return Column(
      children: [
        // Resumen total
        _buildTotalSummaryCard(state.totalAmount, state.totalSalesCount),

        // Selector de tienda
        if (storeIds.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int?>(
              value: _selectedStoreId,
              decoration: InputDecoration(
                labelText: 'Filtrar por tienda',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas las tiendas'),
                ),
                ...storeIds.map((storeId) => DropdownMenuItem<int?>(
                      value: storeId,
                      child: Text(state.storeNames[storeId] ?? 'Tienda $storeId'),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStoreId = value;
                });
              },
            ),
          ),

        const SizedBox(height: 8),

        // Lista de ventas agrupadas por tienda
        Expanded(
          child: _selectedStoreId == null
              ? _buildGroupedByStoreList(state)
              : _buildFilteredStoreList(state, _selectedStoreId!),
        ),
      ],
    );
  }

  Widget _buildTotalSummaryCard(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Total del Día',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Bs. ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$count ventas',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Lista de ventas agrupadas por tienda con secciones
  Widget _buildGroupedByStoreList(SalesAllStoresLoaded state) {
    final storeIds = state.salesByStore.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: storeIds.length,
      itemBuilder: (context, index) {
        final storeId = storeIds[index];
        final storeName = state.storeNames[storeId] ?? 'Tienda $storeId';
        final sales = state.salesByStore[storeId] ?? [];

        // Filtrar por búsqueda
        final filteredSales = _filterSalesBySearch(sales);

        if (filteredSales.isEmpty && _searchQuery.isNotEmpty) {
          return const SizedBox.shrink();
        }

        // Calcular total de la tienda
        final storeTotal = filteredSales.fold<double>(0, (sum, sale) => sum + sale.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de tienda
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        storeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bs. ${storeTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        '${filteredSales.length} ventas',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ventas de la tienda
            ...filteredSales.map((sale) => _buildSaleCard(context, sale, storeName)),
          ],
        );
      },
    );
  }

  /// Lista filtrada por una tienda específica
  Widget _buildFilteredStoreList(SalesAllStoresLoaded state, int storeId) {
    final sales = state.salesByStore[storeId] ?? [];
    final filteredSales = _filterSalesBySearch(sales);
    final storeName = state.storeNames[storeId] ?? 'Tienda $storeId';

    if (filteredSales.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SalesBloc>().add(const SalesLoadAllStoresRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSales.length,
        itemBuilder: (context, index) {
          return _buildSaleCard(context, filteredSales[index], storeName);
        },
      ),
    );
  }

  /// Vista para ventas de una sola tienda
  Widget _buildSingleStoreSalesView(BuildContext context, SalesLoaded state) {
    final filteredSales = _filterSalesBySearch(state.sales);

    if (filteredSales.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.storeId != null) {
          context.read<SalesBloc>().add(SalesLoadTodayByStoreRequested(widget.storeId!));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSales.length,
        itemBuilder: (context, index) {
          return _buildSaleCard(context, filteredSales[index], null);
        },
      ),
    );
  }

  List<SaleData> _filterSalesBySearch(List<SaleData> sales) {
    if (_searchQuery.isEmpty) return sales;

    return sales.where((sale) {
      final customerName = sale.customerName?.toLowerCase() ?? '';
      return customerName.contains(_searchQuery);
    }).toList();
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron ventas para "$_searchQuery"',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, SaleData sale, String? storeName) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalesDetailPage(saleId: sale.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.saleNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sale.customerName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  sale.customerName!,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(sale.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(sale.status),
                      style: TextStyle(
                        color: _getStatusColor(sale.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(sale.saleDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPaymentIcon(sale.paymentMethod),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sale.paymentMethod,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    'Bs. ${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'COMPLETO':
        return Colors.green;
      case 'CANCELLED':
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'COMPLETADO';
      case 'CANCELLED':
        return 'CANCELADO';
      default:
        return status;
    }
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod.toUpperCase()) {
      case 'EFECTIVO':
        return Icons.money;
      case 'TARJETA':
        return Icons.credit_card;
      case 'TRANSFERENCIA':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  void _showFilterDialog(BuildContext context) {
    // Capturar bloc antes del async gap
    final bloc = context.read<SalesBloc>();

    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    ).then((range) {
      if (range != null && mounted) {
        if (_isWarehouseManager && widget.storeId == null) {
          bloc.add(
                SalesLoadAllStoresRequested(
                  startDate: range.start,
                  endDate: range.end.add(const Duration(days: 1)),
                ),
              );
        } else if (widget.storeId != null) {
          bloc.add(
                SalesLoadByDateRangeRequested(
                  storeId: widget.storeId!,
                  startDate: range.start,
                  endDate: range.end.add(const Duration(days: 1)),
                ),
              );
        }
      }
    });
  }
}
