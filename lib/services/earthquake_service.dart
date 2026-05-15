import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

class EarthquakeService {
  static const _baseUrl =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary';

  Future<List<Earthquake>> fetchRecent({double minMagnitude = 2.5}) async {
    final uri = Uri.parse('$_baseUrl/significant_week.geojson');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch earthquakes: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;

    return features
        .map((f) => Earthquake.fromJson(f as Map<String, dynamic>))
        .where((e) => e.magnitude >= minMagnitude)
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }
}
