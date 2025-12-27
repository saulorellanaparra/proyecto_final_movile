/// Definición de rutas de navegación de la aplicación
/// Centralización de todas las rutas nombradas

class AppRoutes {
  // Autenticación
  static const String login = '/login';
  static const String splash = '/';

  // Principal
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // Productos
  static const String products = '/products';
  static const String productDetail = '/products/detail';
  static const String productCreate = '/products/create';
  static const String productEdit = '/products/edit';
  static const String productVariants = '/products/variants';

  // Inventario
  static const String inventory = '/inventory';
  static const String inventoryDetail = '/inventory/detail';
  static const String inventoryAdjustment = '/inventory/adjustment';

  // Ventas
  static const String sales = '/sales';
  static const String saleDetail = '/sales/detail';
  static const String newSale = '/sales/new';
  static const String saleHistory = '/sales/history';

  // Compras
  static const String purchases = '/purchases';
  static const String purchaseDetail = '/purchases/detail';
  static const String newPurchase = '/purchases/new';
  static const String purchaseHistory = '/purchases/history';

  // Transferencias
  static const String transfers = '/transfers';
  static const String transferDetail = '/transfers/detail';
  static const String newTransfer = '/transfers/new';
  static const String transferApproval = '/transfers/approval';
  static const String transferReceive = '/transfers/receive';

  // Reportes
  static const String reports = '/reports';
  static const String dailySalesReport = '/reports/daily-sales';
  static const String salesByStoreReport = '/reports/sales-by-store';
  static const String inventoryReport = '/reports/inventory';
  static const String purchasesReport = '/reports/purchases';
  static const String transfersReport = '/reports/transfers';
  static const String lowStockReport = '/reports/low-stock';

  // Administración
  static const String admin = '/admin';
  static const String users = '/admin/users';
  static const String userDetail = '/admin/users/detail';
  static const String userCreate = '/admin/users/create';
  static const String userEdit = '/admin/users/edit';

  static const String stores = '/admin/stores';
  static const String storeDetail = '/admin/stores/detail';
  static const String storeCreate = '/admin/stores/create';
  static const String storeEdit = '/admin/stores/edit';

  static const String warehouses = '/admin/warehouses';
  static const String warehouseDetail = '/admin/warehouses/detail';
  static const String warehouseCreate = '/admin/warehouses/create';
  static const String warehouseEdit = '/admin/warehouses/edit';

  // Configuración
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
  static const String changePassword = '/settings/change-password';
  static const String sync = '/settings/sync';

  // Auditoría y Sesiones
  static const String auditLog = '/audit';
  static const String sessionHistory = '/sessions/history';

  // Alertas
  static const String stockAlerts = '/alerts/stock';

  AppRoutes._(); // Constructor privado para evitar instanciación
}
