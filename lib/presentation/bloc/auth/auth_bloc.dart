import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/database/daos/user_dao.dart';
import '../../../data/database/daos/stores_dao.dart';
import '../../../data/database/daos/warehouses_dao.dart';
import '../../../data/database/daos/audit_log_dao.dart';
import '../../../data/database/daos/user_sessions_dao.dart';
import '../../../data/database/app_database.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/enums.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC para gestión de autenticación
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserDao userDao;
  final StoresDao storesDao;
  final WarehousesDao warehousesDao;
  final AuditLogDao auditLogDao;
  final UserSessionsDao userSessionsDao;
  final LocationService locationService;
  UserData? _currentUser;
  RoleData? _currentRole;
  int? _currentSessionId; // ID de la sesión actual

  AuthBloc({
    required this.userDao,
    required this.storesDao,
    required this.warehousesDao,
    required this.auditLogDao,
    required this.userSessionsDao,
    required this.locationService,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  /// Getter para el usuario actual
  UserData? get currentUser => _currentUser;

  /// Getter para el rol actual
  RoleData? get currentRole => _currentRole;

  /// Verifica si hay una sesión activa
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Por ahora, no hay sesión persistente
      // En producción, aquí verificarías un token guardado
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Intenta iniciar sesión
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Verificar credenciales
      // En producción: usar bcrypt para hash de contraseñas
      final user = await userDao.getUserByUsername(event.username);

      if (user == null) {
        emit(const AuthError('Usuario no encontrado'));
        return;
      }

      // Verificar contraseña (comparación simplificada para demo)
      // En producción: verificar con bcrypt
      if (!_verifyPassword(event.password, user.username)) {
        emit(const AuthError('Contraseña incorrecta'));
        return;
      }

      if (!user.isActive) {
        emit(const AuthError('Usuario inactivo'));
        return;
      }

      // Obtener rol principal del usuario
      final role = await userDao.getUserPrimaryRole(user.id);

      if (role == null) {
        emit(const AuthError('Usuario sin rol asignado'));
        return;
      }

      // Guardar usuario y rol actuales
      _currentUser = user;
      _currentRole = role;

      // Configurar ubicación automáticamente si el usuario tiene una asignada
      await _setupUserLocation(user);

      // Registrar sesión de usuario
      try {
        _currentSessionId = await userSessionsDao.createSession(
          userId: user.id,
          deviceInfo: 'Flutter App', // Podría obtener info real del dispositivo
          ipAddress: null, // En app móvil/desktop no aplica
        );
      } catch (e) {
        // No fallar el login si falla el registro de sesión
        print('Error al registrar sesión: $e');
      }

      // Registrar evento de LOGIN en auditoría
      try {
        await auditLogDao.logAction(
          userId: user.id,
          action: 'LOGIN',
          description: 'Usuario ${user.username} inició sesión exitosamente',
          entityType: 'USER',
          entityId: user.id,
        );
      } catch (e) {
        // No fallar el login si falla el registro de auditoría
        print('Error al registrar login en auditoría: $e');
      }

      // Emitir estado de autenticado
      emit(AuthAuthenticated(user: user, role: role));
    } catch (e) {
      emit(AuthError('Error al iniciar sesión: ${e.toString()}'));
    }
  }

  /// Configura la ubicación del usuario automáticamente si tiene una asignada
  Future<void> _setupUserLocation(UserData user) async {
    try {
      // Si el usuario tiene una tienda asignada
      if (user.storeId != null) {
        final store = await storesDao.getStoreById(user.storeId!);
        if (store != null) {
          await locationService.saveUserLocation(
            locationType: LocationType.store,
            locationId: store.id,
            locationName: store.name,
          );
        }
      }
      // Si el usuario tiene un almacén asignado
      else if (user.warehouseId != null) {
        final warehouse = await warehousesDao.getWarehouseById(user.warehouseId!);
        if (warehouse != null) {
          await locationService.saveUserLocation(
            locationType: LocationType.warehouse,
            locationId: warehouse.id,
            locationName: warehouse.name,
          );
        }
      }
    } catch (e) {
      // Silenciosamente ignorar errores de configuración de ubicación
      // El usuario podrá configurarla manualmente si falla
      print('Error al configurar ubicación del usuario: $e');
    }
  }

  /// Cierra la sesión
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Cerrar sesión activa
      if (_currentSessionId != null) {
        try {
          await userSessionsDao.closeSession(_currentSessionId!);
        } catch (e) {
          print('Error al cerrar sesión: $e');
        }
      }

      // Registrar evento de LOGOUT en auditoría antes de limpiar el usuario
      if (_currentUser != null) {
        try {
          await auditLogDao.logAction(
            userId: _currentUser!.id,
            action: 'LOGOUT',
            description: 'Usuario ${_currentUser!.username} cerró sesión',
            entityType: 'USER',
            entityId: _currentUser!.id,
          );
        } catch (e) {
          // No fallar el logout si falla el registro de auditoría
          print('Error al registrar logout en auditoría: $e');
        }
      }

      _currentUser = null;
      _currentRole = null;
      _currentSessionId = null;

      // Limpiar sesión persistente si existe

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Error al cerrar sesión: ${e.toString()}'));
    }
  }

  /// Verifica contraseña (SIMPLIFICADO PARA DEMO)
  /// En producción, usar bcrypt para hash y verificación de contraseñas
  /// Usuarios por defecto:
  /// - admin / admin123 (Super Administrador)
  /// - gerente / gerente123 (Gerente General)
  /// - tienda1 / tienda1123 (Encargada Tienda Centro)
  /// - tienda2 / tienda2123 (Encargada Tienda Queru Queru)
  /// - tienda3 / tienda3123 (Encargada Tienda Alalay)
  /// - almacen1 / almacen1123 (Encargado Almacén Central)
  /// - almacen2 / almacen2123 (Encargado Almacén Sacaba)
  bool _verifyPassword(String password, String username) {
    final validCredentials = {
      'admin': 'admin123',
      'gerente': 'gerente123',
      'tienda1': 'tienda1123',
      'tienda2': 'tienda2123',
      'tienda3': 'tienda3123',
      'almacen1': 'almacen1123',
      'almacen2': 'almacen2123',
    };

    return validCredentials[username] == password;
  }
}
