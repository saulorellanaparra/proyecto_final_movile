import 'package:flutter/material.dart';
import '../../../core/constants/enums.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/stock_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/product_dao.dart';

/// Página de alertas de stock bajo
class StockAlertsPage extends StatefulWidget {
  final int? locationId;
  final LocationType? locationType;

  const StockAlertsPage({
    super.key,
    this.locationId,
    this.locationType,
  });

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
  final StockAlertService _stockAlertService = StockAlertService(getIt());
  final ProductDao _productDao = getIt<ProductDao>();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  List<_StockAlertItem> _alerts = [];
  Map<String, dynamic>? _summary;
  int? _effectiveLocationId;
  LocationType? _effectiveLocationType;

  @override
  void initState() {
    super.initState();
    _loadLocationAndAlerts();
  }

  Future<void> _loadLocationAndAlerts() async {
    // Usar la ubicación proporcionada o la ubicación del usuario
    if (widget.locationId != null && widget.locationType != null) {
      _effectiveLocationId = widget.locationId;
      _effectiveLocationType = widget.locationType;
    } else {
      final location = await _locationService.getUserLocation();
      _effectiveLocationId = location?['id'];
      _effectiveLocationType = location?['type'];
    }

    await _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lowStock = await _stockAlertService.getLowStockItems(
        locationType: _effectiveLocationType,
        locationId: _effectiveLocationId,
      );

      final summary = await _stockAlertService.getStockAlertSummary(
        locationType: _effectiveLocationType,
        locationId: _effectiveLocationId,
      );

      // Obtener información de productos para cada item
      final alerts = <_StockAlertItem>[];
      for (final item in lowStock) {
        final variant = await _productDao.getVariantById(item.productVariantId);
        if (variant != null) {
          final product = await _productDao.getProductById(variant.productId);
          if (product != null) {
            alerts.add(_StockAlertItem(
              inventory: item,
              product: product,
              variant: variant,
            ));
          }
        }
      }

      setState(() {
        _alerts = alerts;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar alertas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: Column(
                children: [
                  if (_summary != null) _buildSummaryCard(),
                  Expanded(
                    child: _alerts.isEmpty
                        ? _buildEmptyState()
                        : _buildAlertsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Alertas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Stock Crítico',
                  _summary!['criticalStockCount'].toString(),
                  Icons.error,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Stock Bajo',
                  _summary!['lowStockCount'].toString(),
                  Icons.warning,
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Cerca del Mínimo',
                  _summary!['nearMinStockCount'].toString(),
                  Icons.info,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(_StockAlertItem alert) {
    final isCritical = alert.inventory.quantity == 0;
    final isNearMin = alert.inventory.quantity > alert.inventory.minStock;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCritical) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'CRÍTICO';
    } else if (isNearMin) {
      statusColor = Colors.blue;
      statusIcon = Icons.info;
      statusText = 'CERCA DEL MÍNIMO';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'BAJO';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          alert.product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (alert.variant.size != null || alert.variant.color != null)
              Text(
                '${alert.variant.size ?? ''} ${alert.variant.color ?? ''}'.trim(),
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              'Stock actual: ${alert.inventory.quantity} | Mínimo: ${alert.inventory.minStock}',
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: AppColors.success.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No hay alertas de stock bajo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos los productos tienen stock suficiente',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Clase auxiliar para agrupar información de alerta
class _StockAlertItem {
  final InventoryData inventory;
  final ProductData product;
  final ProductVariantData variant;

  _StockAlertItem({
    required this.inventory,
    required this.product,
    required this.variant,
  });
}
