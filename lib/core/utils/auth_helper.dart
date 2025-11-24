import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/database/app_database.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_state.dart';

/// Helper de autenticación para obtener el usuario actual
/// Proporciona funciones de utilidad para acceder al estado de autenticación
class AuthHelper {
  /// Obtiene el ID del usuario autenticado actualmente
  ///
  /// Lanza una excepción si el usuario no está autenticado
  ///
  /// Ejemplo:
  /// ```dart
  /// final userId = AuthHelper.getCurrentUserId(context);
  /// ```
  static int getCurrentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      throw Exception('Usuario no autenticado. Por favor inicie sesión.');
    }

    return authState.user.id;
  }

  /// Obtiene el usuario completo autenticado actualmente
  ///
  /// Lanza una excepción si el usuario no está autenticado
  ///
  /// Ejemplo:
  /// ```dart
  /// final user = AuthHelper.getCurrentUser(context);
  /// print('Usuario: ${user.fullName}');
  /// ```
  static UserData getCurrentUser(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      throw Exception('Usuario no autenticado. Por favor inicie sesión.');
    }

    return authState.user;
  }

  /// Verifica si el usuario está autenticado
  ///
  /// Retorna true si hay un usuario autenticado, false en caso contrario
  ///
  /// Ejemplo:
  /// ```dart
  /// if (AuthHelper.isAuthenticated(context)) {
  ///   // Realizar acción
  /// }
  /// ```
  static bool isAuthenticated(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated;
  }

  /// Intenta obtener el ID del usuario actual, retornando null si no está autenticado
  ///
  /// Esta es una versión segura que no lanza excepciones
  ///
  /// Ejemplo:
  /// ```dart
  /// final userId = AuthHelper.tryGetCurrentUserId(context);
  /// if (userId != null) {
  ///   // Usuario autenticado
  /// }
  /// ```
  static int? tryGetCurrentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }

    return null;
  }

  /// Intenta obtener el usuario actual, retornando null si no está autenticado
  ///
  /// Esta es una versión segura que no lanza excepciones
  ///
  /// Ejemplo:
  /// ```dart
  /// final user = AuthHelper.tryGetCurrentUser(context);
  /// if (user != null) {
  ///   print('Bienvenido ${user.fullName}');
  /// }
  /// ```
  static UserData? tryGetCurrentUser(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      return authState.user;
    }

    return null;
  }

  /// Obtiene el nombre completo del usuario actual
  ///
  /// Retorna el nombre del usuario o 'Usuario' si no está autenticado
  ///
  /// Ejemplo:
  /// ```dart
  /// final name = AuthHelper.getCurrentUserName(context);
  /// print('Hola, $name');
  /// ```
  static String getCurrentUserName(BuildContext context) {
    final user = tryGetCurrentUser(context);
    return user?.fullName ?? 'Usuario';
  }

  /// Obtiene el username del usuario actual
  ///
  /// Retorna el username o null si no está autenticado
  ///
  /// Ejemplo:
  /// ```dart
  /// final username = AuthHelper.getCurrentUsername(context);
  /// ```
  static String? getCurrentUsername(BuildContext context) {
    final user = tryGetCurrentUser(context);
    return user?.username;
  }

  /// Verifica si el usuario actual está activo
  ///
  /// Retorna false si no está autenticado o si está inactivo
  ///
  /// Ejemplo:
  /// ```dart
  /// if (AuthHelper.isCurrentUserActive(context)) {
  ///   // Permitir acceso
  /// }
  /// ```
  static bool isCurrentUserActive(BuildContext context) {
    final user = tryGetCurrentUser(context);
    return user?.isActive ?? false;
  }
}
