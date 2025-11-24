import 'package:equatable/equatable.dart';

/// Eventos del BLoC de conectividad
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para iniciar el monitoreo de conectividad
class ConnectivityStarted extends ConnectivityEvent {}

/// Evento cuando cambia el estado de conectividad
class ConnectivityChanged extends ConnectivityEvent {
  final bool isConnected;

  const ConnectivityChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}
