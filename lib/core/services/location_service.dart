import 'package:shared_preferences/shared_preferences.dart';
import '../constants/enums.dart';

/// Servicio para gestionar la ubicación del usuario
/// Almacena y recupera la ubicación seleccionada (tienda o almacén)
class LocationService {
  static const String _keyLocationType = 'user_location_type';
  static const String _keyLocationId = 'user_location_id';
  static const String _keyLocationName = 'user_location_name';

  /// Guarda la ubicación seleccionada por el usuario
  Future<void> saveUserLocation({
    required LocationType locationType,
    required int locationId,
    required String locationName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocationType, locationType.name);
    await prefs.setInt(_keyLocationId, locationId);
    await prefs.setString(_keyLocationName, locationName);
  }

  /// Obtiene el tipo de ubicación guardado
  Future<LocationType?> getUserLocationType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeString = prefs.getString(_keyLocationType);
    if (typeString == null) return null;

    return LocationType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => LocationType.store,
    );
  }

  /// Obtiene el ID de ubicación guardado
  Future<int?> getUserLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLocationId);
  }

  /// Obtiene el nombre de ubicación guardado
  Future<String?> getUserLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocationName);
  }

  /// Verifica si el usuario tiene una ubicación configurada
  Future<bool> hasUserLocation() async {
    final locationId = await getUserLocationId();
    return locationId != null;
  }

  /// Limpia la ubicación guardada
  Future<void> clearUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLocationType);
    await prefs.remove(_keyLocationId);
    await prefs.remove(_keyLocationName);
  }

  /// Obtiene toda la información de ubicación en un mapa
  Future<Map<String, dynamic>?> getUserLocation() async {
    final hasLocation = await hasUserLocation();
    if (!hasLocation) return null;

    final locationType = await getUserLocationType();
    final locationId = await getUserLocationId();
    final locationName = await getUserLocationName();

    return {
      'type': locationType,
      'id': locationId,
      'name': locationName,
    };
  }
}
