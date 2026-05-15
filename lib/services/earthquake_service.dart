import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

class EarthquakeService {
  static const _base = 'https://earthquake.usgs.gov/fdsnws/event/1/query';

  Future<List<Earthquake>> fetchRecent({double minMagnitude = 2.5}) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(days: 7));

    final uri = Uri.parse(_base).replace(queryParameters: {
      'format': 'geojson',
      'starttime': _iso(start),
      'endtime': _iso(now),
      'minmagnitude': minMagnitude.toString(),
      'orderby': 'time',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('USGS ${response.statusCode}: ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;

    final results = <Earthquake>[];
    for (final f in features) {
      try {
        final eq = Earthquake.fromUsgsFeature(f as Map<String, dynamic>);
        if (eq.latitude == -200 || eq.longitude == -200) continue;
        results.add(eq);
      } catch (_) {}
    }

    return results; // already newest-first
  }

  static String _iso(DateTime dt) =>
      dt.toIso8601String().replaceFirst(RegExp(r'\.\d+'), '');
}
