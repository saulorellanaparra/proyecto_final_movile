import 'package:equatable/equatable.dart';

/// Eventos del BLoC de autenticación
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar si hay una sesión activa
class AuthCheckRequested extends AuthEvent {}

/// Evento para iniciar sesión
class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// Evento para cerrar sesión
class AuthLogoutRequested extends AuthEvent {}
