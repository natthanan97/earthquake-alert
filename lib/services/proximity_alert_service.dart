import 'dart:developer';

import 'package:latlong2/latlong.dart';

import '../models/earthquake.dart';
import 'distance_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class ProximityAlertService {
  ProximityAlertService({
    required this.locationService,
    required this.distanceService,
    required this.notificationService,
    /// Optional: supplier of the last known position (e.g. from map stream).
    /// Used to avoid an extra GPS round-trip on each event.
    this.lastKnownPosition,
    /// Supplier for current alert radius in meters (reads from settings).
    this.alertRadiusMetersSupplier,
    /// Supplier for minimum magnitude threshold (reads from settings).
    this.minMagnitudeSupplier,
    double alertRadiusMeters = DistanceService.defaultAlertRadiusMeters,
  }) : _defaultRadiusMeters = alertRadiusMeters;

  final LocationService locationService;
  final DistanceService distanceService;
  final NotificationService notificationService;
  final LatLng? Function()? lastKnownPosition;
  final double Function()? alertRadiusMetersSupplier;
  final double Function()? minMagnitudeSupplier;
  final double _defaultRadiusMeters;

  double get _alertRadiusMeters =>
      alertRadiusMetersSupplier?.call() ?? _defaultRadiusMeters;

  double get _minMagnitude => minMagnitudeSupplier?.call() ?? 4.0;

  // Deduplication: stores event keys that already triggered a notification.
  final _alerted = <String>{};

  Future<void> evaluate(Earthquake earthquake) async {
    final key = _eventKey(earthquake);

    if (_alerted.contains(key)) {
      log('Duplicate skipped: $key', name: 'ProximityAlertService');
      return;
    }

    if (earthquake.magnitude < _minMagnitude) {
      log(
        'Below min magnitude (${earthquake.magnitude} < $_minMagnitude) — skipped',
        name: 'ProximityAlertService',
      );
      return;
    }

    try {
      final userPos = await _resolvePosition();
      if (userPos == null) {
        log('No position available — skipping', name: 'ProximityAlertService');
        return;
      }

      final distance = distanceService.calculateDistanceMeters(
        userLatitude: userPos.latitude,
        userLongitude: userPos.longitude,
        earthquakeLatitude: earthquake.latitude,
        earthquakeLongitude: earthquake.longitude,
      );

      log(
        'Distance to ${earthquake.location}: ${distance.toStringAsFixed(0)} m',
        name: 'ProximityAlertService',
      );

      if (distance <= _alertRadiusMeters) {
        _alerted.add(key);

        await notificationService.showEarthquakeAlert(
          id: key.hashCode.abs(),
          magnitude: earthquake.magnitude,
          location: earthquake.location,
          distanceMeters: distance,
        );
      }
    } catch (e) {
      log('evaluate error: $e', name: 'ProximityAlertService');
    }
  }

  /// Uses the cached map position first; falls back to a fresh GPS fix.
  Future<_LatLon?> _resolvePosition() async {
    final cached = lastKnownPosition?.call();
    if (cached != null) {
      return _LatLon(cached.latitude, cached.longitude);
    }

    // No cached position — attempt fresh fix (permission may still be needed).
    try {
      final pos = await locationService.getCurrentPosition();
      return _LatLon(pos.latitude, pos.longitude);
    } on LocationPermissionDeniedException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String _eventKey(Earthquake eq) {
    final ts = (eq.time.millisecondsSinceEpoch ~/ 1000).toString();
    return '${eq.location}_$ts';
  }
}

class _LatLon {
  const _LatLon(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}
