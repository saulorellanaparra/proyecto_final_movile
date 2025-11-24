/// Enumeraciones del sistema de inventario
/// Definición de todos los tipos enumerados utilizados en la aplicación

/// Roles disponibles en el sistema
enum UserRole {
  superAdmin('SUPER_ADMIN', 'Super Administrador'),
  gerenteGeneral('GERENTE_GENERAL', 'Gerente General'),
  encargadoTienda('ENCARGADO_TIENDA', 'Encargado de Tienda'),
  encargadoAlmacen('ENCARGADO_ALMACEN', 'Encargado de Almacén'),
  vendedor('VENDEDOR', 'Vendedor'),
  almacenero('ALMACENERO', 'Almacenero');

  final String code;
  final String displayName;

  const UserRole(this.code, this.displayName);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.vendedor,
    );
  }
}

/// Tipo de ubicación para el inventario
enum LocationType {
  store('STORE', 'Tienda'),
  warehouse('WAREHOUSE', 'Almacén');

  final String code;
  final String displayName;

  const LocationType(this.code, this.displayName);

  static LocationType fromCode(String code) {
    return LocationType.values.firstWhere(
      (location) => location.code == code,
      orElse: () => LocationType.store,
    );
  }
}

/// Tipos de movimientos de inventario
enum MovementType {
  purchase('PURCHASE', 'Compra'),
  sale('SALE', 'Venta'),
  transferIn('TRANSFER_IN', 'Transferencia Entrada'),
  transferOut('TRANSFER_OUT', 'Transferencia Salida'),
  adjustment('ADJUSTMENT', 'Ajuste de Inventario');

  final String code;
  final String displayName;

  const MovementType(this.code, this.displayName);

  static MovementType fromCode(String code) {
    return MovementType.values.firstWhere(
      (movement) => movement.code == code,
      orElse: () => MovementType.adjustment,
    );
  }
}

/// Estados de transferencia
enum TransferStatus {
  pending('PENDING', 'Pendiente'),
  approved('APPROVED', 'Aprobado'),
  inTransit('IN_TRANSIT', 'En Tránsito'),
  received('RECEIVED', 'Recibido'),
  cancelled('CANCELLED', 'Cancelado');

  final String code;
  final String displayName;

  const TransferStatus(this.code, this.displayName);

  static TransferStatus fromCode(String code) {
    return TransferStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => TransferStatus.pending,
    );
  }
}

/// Métodos de pago
enum PaymentMethod {
  cash('CASH', 'Efectivo'),
  card('CARD', 'Tarjeta'),
  transfer('TRANSFER', 'Transferencia'),
  mixed('MIXED', 'Mixto');

  final String code;
  final String displayName;

  const PaymentMethod(this.code, this.displayName);

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (method) => method.code == code,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Operaciones de sincronización
enum SyncOperation {
  insert('INSERT', 'Insertar'),
  update('UPDATE', 'Actualizar'),
  delete('DELETE', 'Eliminar');

  final String code;
  final String displayName;

  const SyncOperation(this.code, this.displayName);

  static SyncOperation fromCode(String code) {
    return SyncOperation.values.firstWhere(
      (operation) => operation.code == code,
      orElse: () => SyncOperation.insert,
    );
  }
}

/// Tipos de entidad para sincronización
enum EntityType {
  user('USER'),
  product('PRODUCT'),
  productVariant('PRODUCT_VARIANT'),
  inventory('INVENTORY'),
  sale('SALE'),
  purchase('PURCHASE'),
  transfer('TRANSFER');

  final String code;

  const EntityType(this.code);

  static EntityType fromCode(String code) {
    return EntityType.values.firstWhere(
      (entity) => entity.code == code,
      orElse: () => EntityType.product,
    );
  }
}

/// Categorías de productos (expandible según necesidades)
enum ProductCategory {
  camisas('CAMISAS', 'Camisas'),
  pantalones('PANTALONES', 'Pantalones'),
  vestidos('VESTIDOS', 'Vestidos'),
  zapatos('ZAPATOS', 'Zapatos'),
  accesorios('ACCESORIOS', 'Accesorios'),
  otros('OTROS', 'Otros');

  final String code;
  final String displayName;

  const ProductCategory(this.code, this.displayName);

  static ProductCategory fromCode(String code) {
    return ProductCategory.values.firstWhere(
      (category) => category.code == code,
      orElse: () => ProductCategory.otros,
    );
  }
}

/// Tallas de ropa (expandible)
enum ClothingSize {
  xs('XS'),
  s('S'),
  m('M'),
  l('L'),
  xl('XL'),
  xxl('XXL'),
  xxxl('XXXL');

  final String code;

  const ClothingSize(this.code);

  static ClothingSize? fromCode(String? code) {
    if (code == null) return null;
    try {
      return ClothingSize.values.firstWhere(
        (size) => size.code == code,
      );
    } catch (e) {
      return null;
    }
  }
}
