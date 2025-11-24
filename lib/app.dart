import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/routes.dart';
import 'core/services/dependency_injection.dart';
import 'data/database/app_database.dart';

// BLoCs
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/connectivity/connectivity_bloc.dart';
import 'presentation/bloc/connectivity/connectivity_event.dart';
import 'presentation/bloc/connectivity/connectivity_state.dart';

// Páginas
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/auth/splash_page.dart';

/// Widget principal de la aplicación
class InventoryApp extends StatelessWidget {
  final AppDatabase database;

  const InventoryApp({
    Key? key,
    required this.database,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BLoC de autenticación
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),

        // BLoC de conectividad
        BlocProvider<ConnectivityBloc>(
          create: (context) => getIt<ConnectivityBloc>()..add(ConnectivityStarted()),
        ),
      ],
      child: MaterialApp(
        // Configuración general
        title: 'Inventory Pro',
        debugShowCheckedModeBanner: false,

        // Tema
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        // Rutas
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashPage(),
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.home: (context) => const HomePage(),
        },

        // Generador de rutas
        onGenerateRoute: (settings) {
          // Aquí puedes manejar rutas dinámicas con parámetros
          switch (settings.name) {
            case AppRoutes.home:
              return MaterialPageRoute(
                builder: (context) => const HomePage(),
              );
            default:
              return null;
          }
        },

        // Ruta no encontrada
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Text('Ruta no encontrada: ${settings.name}'),
              ),
            ),
          );
        },

        // Builder para agregar widgets globales
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),

              // Indicador de conectividad
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
                  builder: (context, state) {
                    if (state is ConnectivityOffline) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        color: Colors.orange,
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.cloud_off,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sin conexión - Modo offline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
