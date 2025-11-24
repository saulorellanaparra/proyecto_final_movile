import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar la conectividad de red
/// Detecta cambios en el estado de la conexión (online/offline)
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream que emite true cuando hay conexión, false cuando no
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    _init();
  }

  /// Inicializa el servicio y comienza a escuchar cambios de conectividad
  void _init() {
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });

    // Verificar estado inicial
    _checkInitialConnectivity();
  }

  /// Verifica el estado inicial de la conectividad
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error al verificar conectividad inicial: $e');
      _connectivityController.add(false);
    }
  }

  /// Actualiza el estado de conexión basado en el resultado
  void _updateConnectionStatus(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    debugPrint('📡 Estado de conectividad: ${isConnected ? "Online" : "Offline"}');
    _connectivityController.add(isConnected);
  }

  /// Verifica si actualmente hay conexión
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error al verificar conectividad: $e');
      return false;
    }
  }

  /// Obtiene el tipo de conexión actual
  Future<ConnectivityResult> getConnectionType() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Error al obtener tipo de conexión: $e');
      return ConnectivityResult.none;
    }
  }

  /// Libera recursos
  void dispose() {
    _connectivityController.close();
  }
}
