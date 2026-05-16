import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class AppSettings {
  const AppSettings({
    required this.alertRadiusKm,
    required this.minMagnitude,
  });

  final double alertRadiusKm;
  final double minMagnitude;

  AppSettings copyWith({double? alertRadiusKm, double? minMagnitude}) =>
      AppSettings(
        alertRadiusKm: alertRadiusKm ?? this.alertRadiusKm,
        minMagnitude: minMagnitude ?? this.minMagnitude,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late final SettingsService _svc;

  @override
  Future<AppSettings> build() async {
    _svc = SettingsService();
    final radius = await _svc.getAlertRadiusKm();
    final mag = await _svc.getMinMagnitude();
    return AppSettings(alertRadiusKm: radius, minMagnitude: mag);
  }

  Future<void> setAlertRadius(double km) async {
    await _svc.setAlertRadiusKm(km);
    state = AsyncData(state.requireValue.copyWith(alertRadiusKm: km));
  }

  Future<void> setMinMagnitude(double mag) async {
    await _svc.setMinMagnitude(mag);
    state = AsyncData(state.requireValue.copyWith(minMagnitude: mag));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
