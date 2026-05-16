import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyAlertRadiusKm = 'alert_radius_km';
  static const _keyMinMagnitude = 'min_magnitude';

  static const double defaultAlertRadiusKm = 50.0;
  static const double defaultMinMagnitude = 4.0;

  static const double minRadiusKm = 10.0;
  static const double maxRadiusKm = 500.0;
  static const List<double> magnitudeOptions = [2.0, 3.0, 4.0, 5.0, 6.0];

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<double> getAlertRadiusKm() async {
    final p = await _p;
    return p.getDouble(_keyAlertRadiusKm) ?? defaultAlertRadiusKm;
  }

  Future<void> setAlertRadiusKm(double km) async {
    final p = await _p;
    await p.setDouble(_keyAlertRadiusKm, km.clamp(minRadiusKm, maxRadiusKm));
  }

  Future<double> getMinMagnitude() async {
    final p = await _p;
    return p.getDouble(_keyMinMagnitude) ?? defaultMinMagnitude;
  }

  Future<void> setMinMagnitude(double mag) async {
    final p = await _p;
    await p.setDouble(_keyMinMagnitude, mag);
  }
}
