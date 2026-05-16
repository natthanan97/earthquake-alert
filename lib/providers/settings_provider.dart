import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class AppSettings {
  const AppSettings({
    required this.alertRadiusKm,
    required this.minMagnitude,
    required this.themeMode,
  });

  final double alertRadiusKm;
  final double minMagnitude;
  final ThemeMode themeMode;

  AppSettings copyWith({
    double? alertRadiusKm,
    double? minMagnitude,
    ThemeMode? themeMode,
  }) =>
      AppSettings(
        alertRadiusKm: alertRadiusKm ?? this.alertRadiusKm,
        minMagnitude: minMagnitude ?? this.minMagnitude,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late final SettingsService _svc;

  @override
  Future<AppSettings> build() async {
    _svc = SettingsService();
    final radius = await _svc.getAlertRadiusKm();
    final mag = await _svc.getMinMagnitude();
    final theme = await _svc.getThemeMode();
    return AppSettings(alertRadiusKm: radius, minMagnitude: mag, themeMode: theme);
  }

  Future<void> setAlertRadius(double km) async {
    await _svc.setAlertRadiusKm(km);
    state = AsyncData(state.requireValue.copyWith(alertRadiusKm: km));
  }

  Future<void> setMinMagnitude(double mag) async {
    await _svc.setMinMagnitude(mag);
    state = AsyncData(state.requireValue.copyWith(minMagnitude: mag));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _svc.setThemeMode(mode);
    state = AsyncData(state.requireValue.copyWith(themeMode: mode));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
