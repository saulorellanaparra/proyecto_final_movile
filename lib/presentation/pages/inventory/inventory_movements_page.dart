import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/database/app_database.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import '../../bloc/inventory/inventory_state.dart';

/// Página de movimientos de inventario
class InventoryMovementsPage extends StatelessWidget {
  final int locationId;
  final LocationType locationType;

  const InventoryMovementsPage({
    super.key,
    required this.locationId,
    required this.locationType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryBloc(inventoryDao: getIt())
        ..add(InventoryMovementsLoadRequested(
          locationType: locationType,
          locationId: locationId,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Movimientos de Inventario'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, state) {
            if (state is InventoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InventoryMovementsLoaded) {
              if (state.movements.isEmpty) {
                return _buildEmptyState();
              }
              return _buildMovementsList(context, state.movements);
            }

            if (state is InventoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
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
    );
  }

  Widget _buildMovementsList(
    BuildContext context,
    List<InventoryMovementData> movements,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InventoryBloc>().add(
              InventoryMovementsLoadRequested(
                locationType: locationType,
                locationId: locationId,
              ),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movements.length,
        itemBuilder: (context, index) {
          final movement = movements[index];
          return _buildMovementCard(movement);
        },
      ),
    );
  }

  Widget _buildMovementCard(InventoryMovementData movement) {
    final isIncrease = movement.quantityChange > 0;
    final movementType = MovementType.fromCode(movement.movementType);
    final icon = _getMovementIcon(movementType);
    final color = isIncrease ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          _getMovementTypeName(movementType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Variante #${movement.productVariantId}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDateTime(movement.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncrease ? '+' : ''}${movement.quantityChange}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${movement.quantityBefore} → ${movement.quantityAfter}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Cantidad antes', '${movement.quantityBefore}'),
                _buildDetailRow('Cambio', '${movement.quantityChange}'),
                _buildDetailRow('Cantidad después', '${movement.quantityAfter}'),
                if (movement.referenceType != null)
                  _buildDetailRow(
                    'Referencia',
                    '${movement.referenceType} #${movement.referenceId}',
                  ),
                if (movement.notes != null) ...[
                  const Divider(height: 24),
                  const Text(
                    'Notas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(movement.notes!),
                ],
              ],
            ),
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
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
          Icon(Icons.swap_vert, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay movimientos registrados',
            style: TextStyle(color: Colors.grey[600]),
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

  void _showFilterDialog(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((range) {
      if (range != null) {
        context.read<InventoryBloc>().add(
              InventoryMovementsLoadRequested(
                locationType: locationType,
                locationId: locationId,
                startDate: range.start,
                endDate: range.end,
              ),
            );
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dt);
  }
}
