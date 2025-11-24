import 'package:equatable/equatable.dart';

/// Estados del BLoC de conectividad
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ConnectivityInitial extends ConnectivityState {}

/// Estado cuando hay conexión
class ConnectivityOnline extends ConnectivityState {}

/// Estado cuando no hay conexión
class ConnectivityOffline extends ConnectivityState {}
