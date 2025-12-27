import 'package:get_it/get_it.dart';

import '../../data/database/app_database.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'location_service.dart';

// BLoCs
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/connectivity/connectivity_bloc.dart';
import '../../presentation/bloc/transfers/transfers_bloc.dart';
import '../../presentation/bloc/reports/reports_bloc.dart';
import '../../presentation/bloc/product/product_bloc.dart';
import '../../presentation/bloc/sales/sales_bloc.dart';
import '../../presentation/bloc/audit/audit_bloc.dart';
import '../../presentation/bloc/sessions/sessions_bloc.dart';

/// Instancia global de GetIt para inyección de dependencias
final getIt = GetIt.instance;

/// Configura todas las dependencias de la aplicación
Future<void> setupDependencyInjection(AppDatabase database) async {
  // ==================== DATABASE ====================
  getIt.registerSingleton<AppDatabase>(database);

  // ==================== DAOs ====================
  getIt.registerLazySingleton(() => database.userDao);
  getIt.registerLazySingleton(() => database.productDao);
  getIt.registerLazySingleton(() => database.inventoryDao);
  getIt.registerLazySingleton(() => database.salesDao);
  getIt.registerLazySingleton(() => database.purchasesDao);
  getIt.registerLazySingleton(() => database.transfersDao);
  getIt.registerLazySingleton(() => database.storesDao);
  getIt.registerLazySingleton(() => database.warehousesDao);
  getIt.registerLazySingleton(() => database.auditLogDao);
  getIt.registerLazySingleton(() => database.userSessionsDao);

  // ==================== SERVICES ====================
  getIt.registerLazySingleton<LocationService>(
    () => LocationService(),
  );

  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(database: getIt()),
  );

  // ==================== BLOC ====================
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      userDao: getIt(),
      storesDao: getIt(),
      warehousesDao: getIt(),
      auditLogDao: getIt(),
      userSessionsDao: getIt(),
      locationService: getIt(),
    ),
  );

  getIt.registerFactory<ConnectivityBloc>(
    () => ConnectivityBloc(
      connectivityService: getIt(),
    ),
  );

  getIt.registerFactory<TransfersBloc>(
    () => TransfersBloc(
      transfersDao: getIt(),
      inventoryDao: getIt(),
      storesDao: getIt(),
      warehousesDao: getIt(),
      userDao: getIt(),
    ),
  );

  getIt.registerFactory<ReportsBloc>(
    () => ReportsBloc(
      salesDao: getIt(),
      inventoryDao: getIt(),
      productDao: getIt(),
      purchasesDao: getIt(),
      transfersDao: getIt(),
      storesDao: getIt(),
    ),
  );

  getIt.registerFactory<ProductBloc>(
    () => ProductBloc(
      productDao: getIt(),
      storesDao: getIt(),
      warehousesDao: getIt(),
      inventoryDao: getIt(),
    ),
  );

  getIt.registerFactory<SalesBloc>(
    () => SalesBloc(
      salesDao: getIt(),
      inventoryDao: getIt(),
      productDao: getIt(),
      storesDao: getIt(),
    ),
  );

  getIt.registerFactory<AuditBloc>(
    () => AuditBloc(
      auditLogDao: getIt(),
    ),
  );

  getIt.registerFactory<SessionsBloc>(
    () => SessionsBloc(
      userSessionsDao: getIt(),
    ),
  );

  // ignore: avoid_print
  print('✅ Dependency Injection configurado');
}
