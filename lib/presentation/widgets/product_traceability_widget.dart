import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/services/dependency_injection.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/inventory_dao.dart';

/// Widget para mostrar la trazabilidad completa de un producto
class ProductTraceabilityWidget extends StatefulWidget {
  final int productVariantId;
  final String? productName;

  const ProductTraceabilityWidget({
    super.key,
    required this.productVariantId,
    this.productName,
  });

  @override
  State<ProductTraceabilityWidget> createState() =>
      _ProductTraceabilityWidgetState();
}

class _ProductTraceabilityWidgetState
    extends State<ProductTraceabilityWidget> {
  final InventoryDao _inventoryDao = getIt<InventoryDao>();
  bool _isLoading = true;
  List<InventoryMovementData> _movements = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final movements =
          await _inventoryDao.getMovementsByVariant(widget.productVariantId);

      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el historial: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(child: _buildErrorState())
            else if (_movements.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(child: _buildMovementsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trazabilidad del Producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.productName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.productName!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];
        final isLast = index == _movements.length - 1;
        return _buildMovementItem(movement, isLast);
      },
    );
  }

  Widget _buildMovementItem(InventoryMovementData movement, bool isLast) {
    final movementType = MovementType.fromCode(movement.movementType);
    final isIncrease = movement.quantityChange > 0;
    final color = isIncrease ? AppColors.success : Colors.red;
    final icon = _getMovementIcon(movementType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getMovementTypeName(movementType),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${isIncrease ? '+' : ''}${movement.quantityChange}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movement.quantityBefore} → ${movement.quantityAfter} unidades',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(movement.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (movement.referenceType != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${movement.referenceType} #${movement.referenceId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  if (movement.notes != null && movement.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        movement.notes!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
          Icon(Icons.timeline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay movimientos registrados',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Error desconocido'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMovements,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.purchase:
        return Icons.shopping_cart;
      case MovementType.sale:
        return Icons.point_of_sale;
      case MovementType.transferIn:
        return Icons.arrow_downward;
      case MovementType.transferOut:
        return Icons.arrow_upward;
      case MovementType.adjustment:
        return Icons.edit;
    }
  }

  String _getMovementTypeName(MovementType type) {
    return type.displayName;
  }

  String _formatDateTime(DateTime dt) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dt);
  }
}
