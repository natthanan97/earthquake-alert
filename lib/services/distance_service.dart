import 'package:geolocator/geolocator.dart';

class DistanceService {
  static const double defaultAlertRadiusMeters = 2000;

  double calculateDistanceMeters({
    required double userLatitude,
    required double userLongitude,
    required double earthquakeLatitude,
    required double earthquakeLongitude,
  }) {
    return Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      earthquakeLatitude,
      earthquakeLongitude,
    );
  }

  bool isWithinAlertRadius({
    required double userLatitude,
    required double userLongitude,
    required double earthquakeLatitude,
    required double earthquakeLongitude,
    double radiusMeters = defaultAlertRadiusMeters,
  }) {
    final distance = calculateDistanceMeters(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      earthquakeLatitude: earthquakeLatitude,
      earthquakeLongitude: earthquakeLongitude,
    );
    return distance <= radiusMeters;
  }
}
