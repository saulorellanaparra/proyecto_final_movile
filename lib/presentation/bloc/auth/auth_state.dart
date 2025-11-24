import 'package:equatable/equatable.dart';
import '../../../data/database/app_database.dart';

/// Estados del BLoC de autenticación
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AuthInitial extends AuthState {}

/// Estado de carga
class AuthLoading extends AuthState {}

/// Estado de autenticación exitosa
class AuthAuthenticated extends AuthState {
  final UserData user;
  final RoleData role;

  const AuthAuthenticated({
    required this.user,
    required this.role,
  });

  @override
  List<Object?> get props => [user, role];
}

/// Estado de no autenticado
class AuthUnauthenticated extends AuthState {}

/// Estado de error
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
