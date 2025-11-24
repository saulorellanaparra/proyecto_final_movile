import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Importar todas las tablas
import 'tables/users_table.dart';
import 'tables/roles_table.dart';
import 'tables/stores_table.dart';
import 'tables/warehouses_table.dart';
import 'tables/products_table.dart';
import 'tables/inventory_table.dart';
import 'tables/purchases_table.dart';
import 'tables/sales_table.dart';
import 'tables/transfers_table.dart';
import 'tables/sync_queue_table.dart';

// Importar DAOs
import 'daos/user_dao.dart';
import 'daos/product_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/purchases_dao.dart';
import 'daos/transfers_dao.dart';
import 'daos/stores_dao.dart';
import 'daos/warehouses_dao.dart';

part 'app_database.g.dart';

/// Base de datos principal de la aplicación
/// Configuración de Drift con todas las tablas y DAOs
@DriftDatabase(
  tables: [
    Users,
    Roles,
    UserRoles,
    Stores,
    Warehouses,
    Products,
    ProductVariants,
    Inventory,
    InventoryMovements,
    Purchases,
    PurchaseDetails,
    Sales,
    SaleDetails,
    Transfers,
    TransferDetails,
    SyncQueue,
  ],
  daos: [
    UserDao,
    ProductDao,
    InventoryDao,
    SalesDao,
    PurchasesDao,
    TransfersDao,
    StoresDao,
    WarehousesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Insertar datos iniciales
        await _insertInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migración de versión 1 a 2: Agregar columnas de ubicación a usuarios
        if (from < 2) {
          await m.addColumn(users, users.storeId);
          await m.addColumn(users, users.warehouseId);
        }
      },
      beforeOpen: (details) async {
        // Habilitar claves foráneas
        await customStatement('PRAGMA foreign_keys = ON');

        if (details.wasCreated) {
          print('Base de datos creada por primera vez');
        }
      },
    );
  }

  /// Inserta datos iniciales en la base de datos
  Future<void> _insertInitialData() async {
    // Insertar roles predefinidos
    await _insertRoles();

    // Insertar usuarios de prueba
    await _insertDefaultUsers();

    // Insertar tiendas y almacenes de ejemplo
    await _insertDefaultLocations();

    // Insertar productos y variantes de ejemplo
    await _insertDefaultProducts();
  }

  /// Inserta los roles predefinidos del sistema
  Future<void> _insertRoles() async {
    final rolesData = [
      RolesCompanion.insert(
        code: 'SUPER_ADMIN',
        name: 'Super Administrador',
        description: const Value('Acceso completo al sistema'),
        permissionsJson: const Value('["all"]'),
      ),
      RolesCompanion.insert(
        code: 'GERENTE_GENERAL',
        name: 'Gerente General',
        description: const Value('Acceso a todos los reportes y gestión'),
        permissionsJson: const Value(
          '["view_all_reports","manage_employees","manage_stores","manage_warehouses","view_all_inventory","approve_transfers"]',
        ),
      ),
      RolesCompanion.insert(
        code: 'ENCARGADO_TIENDA',
        name: 'Encargado de Tienda',
        description: const Value('Gestión de ventas e inventario de tienda'),
        permissionsJson: const Value(
          '["manage_sales","view_store_inventory","manage_store_employees","create_transfers","view_store_reports"]',
        ),
      ),
      RolesCompanion.insert(
        code: 'ENCARGADO_ALMACEN',
        name: 'Encargado de Almacén',
        description: const Value('Gestión de compras y stock de almacén'),
        permissionsJson: const Value(
          '["manage_purchases","view_warehouse_inventory","manage_warehouse_employees","approve_transfers","create_transfers"]',
        ),
      ),
      RolesCompanion.insert(
        code: 'VENDEDOR',
        name: 'Vendedor',
        description: const Value('Registro de ventas en tienda'),
        permissionsJson: const Value(
          '["create_sales","view_products","view_store_inventory"]',
        ),
      ),
      RolesCompanion.insert(
        code: 'ALMACENERO',
        name: 'Almacenero',
        description: const Value('Recepciones y transferencias de almacén'),
        permissionsJson: const Value(
          '["receive_purchases","create_transfers","view_warehouse_inventory"]',
        ),
      ),
    ];

    for (final role in rolesData) {
      await into(roles).insert(role);
    }
  }

  /// Inserta usuarios de prueba por defecto
  /// Usuarios disponibles:
  /// - admin / admin123 (Super Administrador)
  /// - gerente / gerente123 (Gerente General)
  /// - tienda1 / tienda1123 (Encargada Tienda Centro)
  /// - tienda2 / tienda2123 (Encargada Tienda Queru Queru)
  /// - tienda3 / tienda3123 (Encargada Tienda Alalay)
  /// - almacen1 / almacen1123 (Encargado Almacén Central)
  /// - almacen2 / almacen2123 (Encargado Almacén Sacaba)
  Future<void> _insertDefaultUsers() async {
    // En producción, esto debería usar bcrypt o similar
    // Por ahora usamos un hash simple para demostración
    const passwordHash = '\$2a\$10\$X0h4Y9z.VqFKJyXw3K3K3.qvKQwXQwXQwXQwXQwXQwXQwXQwXQwXQ';

    // Lista de usuarios a crear
    final usersToCreate = [
      {
        'username': 'admin',
        'fullName': 'Administrador del Sistema',
        'email': 'admin@inventory.com',
        'phone': '999999999',
        'roleCode': 'SUPER_ADMIN',
      },
      {
        'username': 'gerente',
        'fullName': 'Juan Pérez - Gerente General',
        'email': 'gerente@inventory.com',
        'phone': '987654321',
        'roleCode': 'GERENTE_GENERAL',
      },
      // Encargados de Tienda (uno por cada tienda)
      {
        'username': 'tienda1',
        'fullName': 'María González - Encargada Tienda Centro',
        'email': 'centro@tienda.com',
        'phone': '77712345',
        'roleCode': 'ENCARGADO_TIENDA',
        'storeId': 1, // T001 - Centro
      },
      {
        'username': 'tienda2',
        'fullName': 'Ana Martínez - Encargada Tienda Queru Queru',
        'email': 'queruqueru@tienda.com',
        'phone': '77723456',
        'roleCode': 'ENCARGADO_TIENDA',
        'storeId': 2, // T002 - Queru Queru
      },
      {
        'username': 'tienda3',
        'fullName': 'Laura Rojas - Encargada Tienda Alalay',
        'email': 'alalay@tienda.com',
        'phone': '77734567',
        'roleCode': 'ENCARGADO_TIENDA',
        'storeId': 3, // T003 - Alalay
      },
      // Encargados de Almacén (uno por cada almacén)
      {
        'username': 'almacen1',
        'fullName': 'Carlos Ramírez - Encargado Almacén Central',
        'email': 'almacen@empresa.com',
        'phone': '77745678',
        'roleCode': 'ENCARGADO_ALMACEN',
        'warehouseId': 1, // ALM001 - Parque Industrial
      },
      {
        'username': 'almacen2',
        'fullName': 'Roberto Silva - Encargado Almacén Sacaba',
        'email': 'almacensacaba@empresa.com',
        'phone': '77756789',
        'roleCode': 'ENCARGADO_ALMACEN',
        'warehouseId': 2, // ALM002 - Sacaba
      },
    ];

    // Crear cada usuario y asignar su rol
    for (final userData in usersToCreate) {
      final userId = await into(users).insert(
        UsersCompanion.insert(
          username: userData['username'] as String,
          passwordHash: passwordHash,
          fullName: userData['fullName'] as String,
          email: Value(userData['email'] as String),
          phone: Value(userData['phone'] as String),
          isActive: const Value(true),
          storeId: userData.containsKey('storeId')
              ? Value(userData['storeId'] as int)
              : const Value(null),
          warehouseId: userData.containsKey('warehouseId')
              ? Value(userData['warehouseId'] as int)
              : const Value(null),
        ),
      );

      // Obtener el rol correspondiente
      final role = await (select(roles)
            ..where((r) => r.code.equals(userData['roleCode'] as String)))
          .getSingle();

      // Asignar el rol al usuario
      await into(userRoles).insert(
        UserRolesCompanion.insert(
          userId: userId,
          roleId: role.id,
          isPrimary: const Value(true),
        ),
      );
    }
  }

  /// Inserta tiendas y almacenes de ejemplo
  Future<void> _insertDefaultLocations() async {
    // Insertar tiendas de ejemplo
    final storesData = [
      StoresCompanion.insert(
        code: 'T001',
        name: 'Tienda Principal - Centro',
        address: 'Av. Heroínas N° 0234, Plaza 14 de Septiembre, Cochabamba',
        phone: const Value('4-4258901'),
        email: const Value('centro@tienda.com'),
        isActive: const Value(true),
      ),
      StoresCompanion.insert(
        code: 'T002',
        name: 'Tienda Sur - Queru Queru',
        address: 'Av. Blanco Galindo Km 4.5, Queru Queru, Cochabamba',
        phone: const Value('4-4367812'),
        email: const Value('queruqueru@tienda.com'),
        isActive: const Value(true),
      ),
      StoresCompanion.insert(
        code: 'T003',
        name: 'Tienda Norte - Alalay',
        address: 'Av. Atahuallpa entre Costanera y Melchor Pérez, Alalay, Cochabamba',
        phone: const Value('4-4489523'),
        email: const Value('alalay@tienda.com'),
        isActive: const Value(true),
      ),
    ];

    for (final store in storesData) {
      await into(stores).insert(store);
    }

    // Insertar almacenes de ejemplo
    final warehousesData = [
      WarehousesCompanion.insert(
        code: 'ALM001',
        name: 'Almacén Central - Parque Industrial',
        address: 'Parque Industrial Santiváñez, Calle 3 N° 150, Cochabamba',
        phone: const Value('4-4512634'),
        email: const Value('almacen@empresa.com'),
        isActive: const Value(true),
      ),
      WarehousesCompanion.insert(
        code: 'ALM002',
        name: 'Almacén Sacaba',
        address: 'Av. Villarroel Km 12, Zona Industrial Sacaba, Cochabamba',
        phone: const Value('4-4367945'),
        email: const Value('almacensacaba@empresa.com'),
        isActive: const Value(true),
      ),
    ];

    for (final warehouse in warehousesData) {
      await into(warehouses).insert(warehouse);
    }
  }

  /// Inserta productos y variantes de ejemplo
  Future<void> _insertDefaultProducts() async {
    // Productos de ropa de marca
    final productsData = [
      {
        'code': 'POLO-NK-001',
        'name': 'Polo Nike Deportivo',
        'description': 'Polo deportivo Nike Dri-FIT',
        'brand': 'Nike',
        'category': 'Polos',
        'basePrice': 89.90,
        'costPrice': 50.00,
      },
      {
        'code': 'JEAN-LV-001',
        'name': 'Jean Levis 501',
        'description': 'Jean clásico Levis 501 Original',
        'brand': 'Levis',
        'category': 'Jeans',
        'basePrice': 199.90,
        'costPrice': 120.00,
      },
      {
        'code': 'ZAPAT-AD-001',
        'name': 'Zapatillas Adidas Superstar',
        'description': 'Zapatillas Adidas Superstar clásicas',
        'brand': 'Adidas',
        'category': 'Zapatillas',
        'basePrice': 299.90,
        'costPrice': 180.00,
      },
    ];

    for (final productData in productsData) {
      final productId = await into(products).insert(
        ProductsCompanion.insert(
          code: productData['code'] as String,
          name: productData['name'] as String,
          description: Value(productData['description'] as String),
          brand: Value(productData['brand'] as String),
          category: productData['category'] as String,
          basePrice: Value(productData['basePrice'] as double),
          costPrice: Value(productData['costPrice'] as double),
          isActive: const Value(true),
        ),
      );

      // Crear variantes para cada producto
      if (productData['category'] == 'Polos') {
        // Variantes de polos: diferentes tallas y colores
        final sizes = ['S', 'M', 'L', 'XL'];
        final colors = ['Negro', 'Blanco', 'Azul'];

        for (final size in sizes) {
          for (final color in colors) {
            await into(productVariants).insert(
              ProductVariantsCompanion.insert(
                productId: productId,
                sku: '${productData['code']}-$size-$color',
                size: Value(size),
                color: Value(color),
                isActive: const Value(true),
              ),
            );
          }
        }
      } else if (productData['category'] == 'Jeans') {
        // Variantes de jeans: diferentes tallas
        final sizes = ['28', '30', '32', '34', '36'];

        for (final size in sizes) {
          await into(productVariants).insert(
            ProductVariantsCompanion.insert(
              productId: productId,
              sku: '${productData['code']}-$size',
              size: Value(size),
              isActive: const Value(true),
            ),
          );
        }
      } else if (productData['category'] == 'Zapatillas') {
        // Variantes de zapatillas: diferentes tallas
        final sizes = ['38', '39', '40', '41', '42', '43'];

        for (final size in sizes) {
          await into(productVariants).insert(
            ProductVariantsCompanion.insert(
              productId: productId,
              sku: '${productData['code']}-$size',
              size: Value(size),
              isActive: const Value(true),
            ),
          );
        }
      }
    }

    // Agregar inventario inicial
    final variantsToStock = await select(productVariants).get();
    final storesList = await select(stores).get();
    final warehousesList = await select(warehouses).get();

    // Stock inicial en ALMACENES (30 unidades por variante)
    for (final variant in variantsToStock) {
      for (final warehouse in warehousesList) {
        await into(inventory).insert(
          InventoryCompanion.insert(
            productVariantId: variant.id,
            locationType: 'WAREHOUSE',
            locationId: warehouse.id,
            quantity: const Value(30), // Stock inicial en almacén
          ),
        );
      }
    }

    // Inventario VACÍO en tiendas (cantidad 0)
    // Esto permite que los productos aparezcan en las listas pero sin stock
    for (final variant in variantsToStock) {
      for (final store in storesList) {
        await into(inventory).insert(
          InventoryCompanion.insert(
            productVariantId: variant.id,
            locationType: 'STORE',
            locationId: store.id,
            quantity: const Value(0), // Tiendas empiezan vacías
          ),
        );
      }
    }
  }
}

/// Abre la conexión a la base de datos
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inventory_app.db'));

    return NativeDatabase.createInBackground(file);
  });
}
