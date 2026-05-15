class Earthquake {
  final double latitude;
  final double longitude;
  final double magnitude;
  final double depth;
  final String location;
  final DateTime time;
  final int maxScale;

  const Earthquake({
    required this.latitude,
    required this.longitude,
    required this.magnitude,
    required this.depth,
    required this.location,
    required this.time,
    required this.maxScale,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final hypocenter =
        (json['earthquake'] as Map<String, dynamic>?)?['hypocenter']
            as Map<String, dynamic>? ??
        {};

    return Earthquake(
      latitude: (hypocenter['latitude'] as num? ?? -200).toDouble(),
      longitude: (hypocenter['longitude'] as num? ?? -200).toDouble(),
      magnitude: (hypocenter['magnitude'] as num? ?? -1).toDouble(),
      depth: (hypocenter['depth'] as num? ?? -1).toDouble(),
      location: hypocenter['name'] as String? ?? 'Unknown',
      time: _parseTime(json['time'] as String? ?? ''),
      maxScale: (json['earthquake'] as Map<String, dynamic>?)?['maxScale']
              as int? ??
          -1,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'magnitude': magnitude,
        'depth': depth,
        'location': location,
        'time': time.toIso8601String(),
        'maxScale': maxScale,
      };

  // p2pquake time format: "2006/01/02 15:04:05.999"
  static DateTime _parseTime(String raw) {
    if (raw.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(raw.replaceFirst('/', '-').replaceFirst('/', '-'));
    } catch (_) {
      return DateTime.now();
    }
  }
}
