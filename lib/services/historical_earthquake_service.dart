import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/earthquake.dart';

class HistoricalEarthquakeService {
  static const _base = 'https://earthquake.usgs.gov/fdsnws/event/1/query';
  static const _lookbackHours = 10;

  /// Fetches the last [_lookbackHours] hours of global earthquakes from USGS.
  /// Returns events sorted newest-first.
  Future<List<Earthquake>> fetchLast10Hours() async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(hours: _lookbackHours));

    final uri = Uri.parse(_base).replace(queryParameters: {
      'format': 'geojson',
      'starttime': _iso(start),
      'endtime': _iso(now),
      'orderby': 'time',
    });

    log('Fetching historical: $uri', name: 'HistoricalEarthquakeService');

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
          'USGS returned ${response.statusCode}: ${response.reasonPhrase}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>;

    final results = <Earthquake>[];
    for (final f in features) {
      try {
        final eq = Earthquake.fromUsgsFeature(f as Map<String, dynamic>);
        // Skip entries with invalid coordinates.
        if (eq.latitude == -200 || eq.longitude == -200) continue;
        results.add(eq);
      } catch (e) {
        log('Parse error for feature: $e', name: 'HistoricalEarthquakeService');
      }
    }

    log('Loaded ${results.length} historical events', name: 'HistoricalEarthquakeService');
    return results; // already newest-first from orderby=time
  }

  static String _iso(DateTime dt) =>
      dt.toIso8601String().replaceFirst(RegExp(r'\.\d+'), '');
}
