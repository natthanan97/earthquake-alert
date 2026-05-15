import 'dart:developer';

import 'package:geolocator/geolocator.dart';

class LocationService {
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // metres — suppress updates smaller than 10 m
  );

  Future<Position> getCurrentPosition() async {
    await _resolvePermission();

    log('Getting current position', name: 'LocationService');

    final position = await Geolocator.getCurrentPosition(
      locationSettings: _settings,
    );

    log(
      'Current coordinates: ${position.latitude}, ${position.longitude}',
      name: 'LocationService',
    );

    return position;
  }

  /// Returns a stream of position updates after resolving permission.
  /// Throws [LocationPermissionDeniedException] if permission is denied.
  Future<Stream<Position>> getPositionStream() async {
    await _resolvePermission();
    log('Starting position stream', name: 'LocationService');
    return Geolocator.getPositionStream(locationSettings: _settings);
  }

  Future<LocationPermission> _resolvePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      log('Location permission denied', name: 'LocationService');
      throw const LocationPermissionDeniedException();
    }

    log('Location permission granted', name: 'LocationService');
    return permission;
  }
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();

  @override
  String toString() => 'LocationPermissionDeniedException: '
      'Location permission was denied. Cannot get current position.';
}

