/// Constantes globales de la aplicación
/// Centralización de valores constantes utilizados en toda la app

class AppConstants {
  // Información de la aplicación
  static const String appName = 'Inventory Pro';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Fashion Store';

  // Base de datos
  static const String databaseName = 'inventory_app.db';
  static const int databaseVersion = 1;

  // Sincronización
  static const int syncBatchSize = 50;
  static const int maxSyncAttempts = 3;
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);

  // Paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validaciones
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // Formato de fechas
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Formato de moneda
  static const String currencySymbol = 'Bs.'; // Bolivianos
  static const String currencyCode = 'BOB';
  static const int currencyDecimals = 2;

  // Inventario
  static const int minStockWarning = 10;
  static const int maxStockLimit = 10000;

  // Descuentos
  static const double maxDiscountPercentage = 50.0;
  static const double minDiscountPercentage = 0.0;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);

  // Caché
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 48.0;

  // Animaciones
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Mensajes
  static const String noInternetMessage =
      'No hay conexión a Internet. Los cambios se sincronizarán cuando se restablezca la conexión.';
  static const String syncingMessage = 'Sincronizando datos...';
  static const String syncSuccessMessage = 'Sincronización completada';
  static const String syncErrorMessage = 'Error al sincronizar datos';

  // Claves de almacenamiento local
  static const String keyUserId = 'user_id';
  static const String keyUserToken = 'user_token';
  static const String keySelectedStore = 'selected_store';
  static const String keySelectedWarehouse = 'selected_warehouse';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyLastSyncTime = 'last_sync_time';

  // Regex patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\d{7,8}$'; // 7-8 dígitos para Bolivia
  static const String barcodePattern = r'^\d{8,13}$'; // EAN-8 o EAN-13

  // Permisos por rol
  static const Map<String, List<String>> rolePermissions = {
    'SUPER_ADMIN': [
      'all',
    ],
    'GERENTE_GENERAL': [
      'view_all_reports',
      'manage_employees',
      'manage_stores',
      'manage_warehouses',
      'view_all_inventory',
      'approve_transfers',
    ],
    'ENCARGADO_TIENDA': [
      'manage_sales',
      'view_store_inventory',
      'manage_store_employees',
      'create_transfers',
      'view_store_reports',
    ],
    'ENCARGADO_ALMACEN': [
      'manage_purchases',
      'view_warehouse_inventory',
      'manage_warehouse_employees',
      'approve_transfers',
      'create_transfers',
    ],
    'VENDEDOR': [
      'create_sales',
      'view_products',
      'view_store_inventory',
    ],
    'ALMACENERO': [
      'receive_purchases',
      'create_transfers',
      'view_warehouse_inventory',
    ],
  };

  // Mensajes de error comunes
  static const String errorGeneric = 'Ocurrió un error inesperado';
  static const String errorNetwork = 'Error de conexión';
  static const String errorDatabase = 'Error en la base de datos';
  static const String errorAuthentication = 'Error de autenticación';
  static const String errorPermission = 'No tienes permisos para esta acción';
  static const String errorValidation = 'Error de validación de datos';
  static const String errorNotFound = 'Registro no encontrado';

  // Configuración de reportes
  static const List<String> reportTypes = [
    'daily_sales',
    'sales_by_store',
    'inventory_status',
    'purchases_report',
    'transfers_report',
    'low_stock_report',
  ];

  // Estados de conexión
  static const String connectionOnline = 'online';
  static const String connectionOffline = 'offline';

  AppConstants._(); // Constructor privado para evitar instanciación
}
