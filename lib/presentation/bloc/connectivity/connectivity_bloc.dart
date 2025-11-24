import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/connectivity_service.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

/// BLoC para gestión de conectividad de red
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityBloc({required this.connectivityService})
      : super(ConnectivityInitial()) {
    on<ConnectivityStarted>(_onConnectivityStarted);
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  /// Inicia el monitoreo de conectividad
  Future<void> _onConnectivityStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    // Suscribirse a cambios de conectividad
    _connectivitySubscription =
        connectivityService.connectivityStream.listen((isConnected) {
      add(ConnectivityChanged(isConnected));
    });
  }

  /// Maneja cambios en el estado de conectividad
  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    if (event.isConnected) {
      emit(ConnectivityOnline());
    } else {
      emit(ConnectivityOffline());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
