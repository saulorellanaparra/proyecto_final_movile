import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/services/dependency_injection.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/inventory_dao.dart';

/// Widget para mostrar los últimos movimientos de inventario
class RecentMovementsWidget extends StatelessWidget {
  final int? locationId;
  final LocationType? locationType;
  final int limit;

  const RecentMovementsWidget({
    super.key,
    this.locationId,
    this.locationType,
    this.limit = 10,
  });

  @override
  Widget build(BuildContext context) {
    final inventoryDao = getIt<InventoryDao>();

    // Si no hay ubicación, mostrar mensaje
    if (locationId == null || locationType == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'Selecciona una ubicación',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<InventoryMovementData>>(
      stream: inventoryDao.watchMovementsByLocation(
        locationType!,
        locationId!,
        limit: limit,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 8),
                  Text(
                    'Error al cargar movimientos: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        final movements = snapshot.data ?? [];

        if (movements.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'No hay movimientos recientes',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Últimos Movimientos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${movements.length} ${movements.length == 1 ? 'movimiento' : 'movimientos'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final movement = movements[index];
                return _buildMovementItem(context, movement);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMovementItem(BuildContext context, InventoryMovementData movement) {
    final movementType = MovementType.fromCode(movement.movementType);
    final isIncrease = movement.quantityChange > 0;
    final color = isIncrease ? AppColors.success : Colors.red;
    final icon = _getMovementIcon(movementType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          radius: 18,
          child: Icon(icon, color: color, size: 16),
        ),
        title: Text(
          _getMovementTypeName(movementType),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          _formatDateTime(movement.createdAt),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncrease ? '+' : ''}${movement.quantityChange}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${movement.quantityBefore} → ${movement.quantityAfter}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
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
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(dt);
    }
  }
}
