class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;

  const Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final geo = json['geometry'] as Map<String, dynamic>;
    final coords = geo['coordinates'] as List<dynamic>;

    return Earthquake(
      id: json['id'] as String,
      magnitude: (props['mag'] as num).toDouble(),
      place: props['place'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(props['time'] as int),
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
      depth: (coords[2] as num).toDouble(),
    );
  }
}
