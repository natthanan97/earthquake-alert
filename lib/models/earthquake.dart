import '../utils/country_flag_helper.dart';

enum EarthquakeSource { jma, usgs }

class Earthquake {
  final double latitude;
  final double longitude;
  final double magnitude;
  final double depth;
  final String location;
  final DateTime time;
  final int maxScale;
  final bool tsunami;
  final EarthquakeSource source;
  /// ISO 3166-1 alpha-2 country code, detected from coordinates.
  final String countryCode;
  /// Unicode flag emoji for the country.
  final String countryFlag;
  /// Human-readable country name.
  final String countryName;

  const Earthquake({
    required this.latitude,
    required this.longitude,
    required this.magnitude,
    required this.depth,
    required this.location,
    required this.time,
    required this.maxScale,
    this.tsunami = false,
    this.source = EarthquakeSource.jma,
    this.countryCode = 'XX',
    this.countryFlag = '🌐',
    this.countryName = 'International',
  });

  /// Parses a p2pquake WebSocket event (code 551).
  factory Earthquake.fromP2pquakeJson(Map<String, dynamic> json) {
    final hypocenter =
        (json['earthquake'] as Map<String, dynamic>?)?['hypocenter']
            as Map<String, dynamic>? ??
        {};

    final eqBlock = json['earthquake'] as Map<String, dynamic>?;

    final lat = (hypocenter['latitude'] as num? ?? -200).toDouble();
    final lon = (hypocenter['longitude'] as num? ?? -200).toDouble();
    final country = _detectCountry(lat, lon);

    return Earthquake(
      latitude: lat,
      longitude: lon,
      magnitude: (hypocenter['magnitude'] as num? ?? -1).toDouble(),
      depth: (hypocenter['depth'] as num? ?? -1).toDouble(),
      location: hypocenter['name'] as String? ?? 'Unknown',
      time: _parseP2pTime(json['time'] as String? ?? ''),
      maxScale: eqBlock?['maxScale'] as int? ?? -1,
      tsunami: false,
      source: EarthquakeSource.jma,
      countryCode: country.code,
      countryFlag: country.flag,
      countryName: country.name,
    );
  }

  /// Parses a single GeoJSON feature from the USGS fdsnws API.
  factory Earthquake.fromUsgsFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final coords =
        (feature['geometry']?['coordinates'] as List<dynamic>?) ?? [];

    final lon = coords.isNotEmpty ? (coords[0] as num).toDouble() : -200.0;
    final lat = coords.length > 1 ? (coords[1] as num).toDouble() : -200.0;
    final depth = coords.length > 2 ? (coords[2] as num).toDouble() : -1.0;

    final ms = props['time'] as int? ?? 0;
    final time = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final country = _detectCountry(lat, lon);

    return Earthquake(
      latitude: lat,
      longitude: lon,
      magnitude: (props['mag'] as num? ?? -1).toDouble(),
      depth: depth,
      location: props['place'] as String? ?? 'Unknown',
      time: time,
      maxScale: -1,
      tsunami: (props['tsunami'] as int? ?? 0) == 1,
      source: EarthquakeSource.usgs,
      countryCode: country.code,
      countryFlag: country.flag,
      countryName: country.name,
    );
  }

  /// Legacy alias kept so existing p2pquake call-sites compile unchanged.
  factory Earthquake.fromJson(Map<String, dynamic> json) =>
      Earthquake.fromP2pquakeJson(json);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'magnitude': magnitude,
        'depth': depth,
        'location': location,
        'time': time.toIso8601String(),
        'maxScale': maxScale,
        'tsunami': tsunami,
        'source': source.name,
        'countryCode': countryCode,
      };

  static ({String flag, String code, String name}) _detectCountry(
      double lat, double lon) {
    if (lat == -200 || lon == -200) {
      return (flag: '🌐', code: 'XX', name: 'International');
    }
    return CountryFlagHelper.detect(lat, lon);
  }

  /// Deduplication key: rounded time + rounded coordinates + rounded magnitude.
  /// Tolerates small float differences between sources for the same event.
  String get dedupKey {
    final tSec = (time.millisecondsSinceEpoch ~/ 1000).toString();
    final latR = lat2dp(latitude);
    final lonR = lat2dp(longitude);
    final magR = magnitude.toStringAsFixed(1);
    return '${tSec}_${latR}_${lonR}_$magR';
  }

  static String lat2dp(double v) => v.toStringAsFixed(2);

  // p2pquake time format: "2006/01/02 15:04:05.999"
  static DateTime _parseP2pTime(String raw) {
    if (raw.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(raw.replaceFirst('/', '-').replaceFirst('/', '-'));
    } catch (_) {
      return DateTime.now();
    }
  }
}
