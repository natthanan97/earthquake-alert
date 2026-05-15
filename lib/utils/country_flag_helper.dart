/// Detects country from coordinates using bounding boxes and renders the
/// corresponding flag emoji. No external packages required.
class CountryFlagHelper {
  CountryFlagHelper._();

  /// Returns a flag emoji + country code string, e.g. "🇯🇵 JP".
  static ({String flag, String code, String name}) detect(
      double lat, double lon) {
    for (final entry in _boxes) {
      if (lat >= entry.minLat &&
          lat <= entry.maxLat &&
          lon >= entry.minLon &&
          lon <= entry.maxLon) {
        return (flag: _emoji(entry.code), code: entry.code, name: entry.name);
      }
    }
    return (flag: '🌐', code: 'XX', name: 'International');
  }

  /// Converts an ISO 3166-1 alpha-2 code to a flag emoji.
  static String _emoji(String code) {
    const base = 0x1F1E6 - 0x41; // regional indicator A offset
    final points = code.toUpperCase().codeUnits.map((c) => base + c);
    return String.fromCharCodes(points.expand((p) => [p]));
  }

  // ── Bounding boxes — ordered most-specific first ──────────────────────────
  // Covers the seismically active regions most relevant to this app.
  static const _boxes = <_Box>[
    // Japan (split to avoid overlap with Korea/China)
    _Box('JP', 'Japan', 24.0, 146.0, 45.5, 154.0),
    // Philippines
    _Box('PH', 'Philippines', 4.5, 116.0, 21.0, 127.0),
    // Indonesia (approximate)
    _Box('ID', 'Indonesia', -11.0, 95.0, 6.0, 141.0),
    // Papua New Guinea
    _Box('PG', 'Papua New Guinea', -12.0, 140.5, 0.0, 156.0),
    // New Zealand
    _Box('NZ', 'New Zealand', -47.5, 166.0, -34.0, 178.5),
    // Solomon Islands
    _Box('SB', 'Solomon Islands', -13.0, 155.0, -5.0, 167.5),
    // Vanuatu
    _Box('VU', 'Vanuatu', -20.5, 166.5, -13.0, 170.5),
    // Fiji
    _Box('FJ', 'Fiji', -20.0, 176.0, -15.5, 180.0),
    // Tonga
    _Box('TO', 'Tonga', -23.5, -176.5, -15.0, -173.5),
    // Chile
    _Box('CL', 'Chile', -56.0, -76.0, -17.0, -65.5),
    // Peru
    _Box('PE', 'Peru', -18.5, -81.5, -0.5, -68.5),
    // Ecuador
    _Box('EC', 'Ecuador', -5.0, -81.5, 1.5, -75.0),
    // Colombia
    _Box('CO', 'Colombia', -4.5, -79.0, 12.5, -66.5),
    // Venezuela
    _Box('VE', 'Venezuela', 0.5, -73.5, 12.5, -59.5),
    // Mexico
    _Box('MX', 'Mexico', 14.5, -117.5, 32.5, -86.5),
    // Guatemala
    _Box('GT', 'Guatemala', 13.5, -92.5, 18.0, -88.0),
    // United States (lower 48)
    _Box('US', 'United States', 24.0, -125.0, 49.5, -66.0),
    // Alaska
    _Box('US', 'United States', 51.0, -180.0, 71.5, -130.0),
    // Canada
    _Box('CA', 'Canada', 41.5, -141.0, 84.0, -52.5),
    // Iceland
    _Box('IS', 'Iceland', 63.0, -25.0, 67.0, -13.0),
    // Italy
    _Box('IT', 'Italy', 36.5, 6.5, 47.0, 18.5),
    // Greece
    _Box('GR', 'Greece', 34.5, 19.5, 42.0, 28.0),
    // Turkey
    _Box('TR', 'Turkey', 35.5, 26.0, 42.5, 44.5),
    // Iran
    _Box('IR', 'Iran', 25.0, 44.0, 39.5, 63.5),
    // Afghanistan
    _Box('AF', 'Afghanistan', 29.0, 60.5, 38.5, 74.5),
    // Pakistan
    _Box('PK', 'Pakistan', 23.5, 60.5, 37.0, 77.5),
    // India
    _Box('IN', 'India', 7.5, 68.0, 35.5, 97.5),
    // Nepal
    _Box('NP', 'Nepal', 26.5, 80.0, 30.5, 88.5),
    // China
    _Box('CN', 'China', 18.0, 73.5, 53.5, 135.5),
    // Taiwan
    _Box('TW', 'Taiwan', 21.5, 119.5, 25.5, 122.5),
    // South Korea
    _Box('KR', 'South Korea', 33.0, 125.5, 38.5, 130.0),
    // North Korea
    _Box('KP', 'North Korea', 37.5, 124.0, 43.0, 130.5),
    // Russia (east, seismically active)
    _Box('RU', 'Russia', 43.0, 130.0, 72.0, 180.0),
    // Kazakhstan
    _Box('KZ', 'Kazakhstan', 40.5, 50.5, 55.5, 87.5),
    // Argentina
    _Box('AR', 'Argentina', -55.0, -73.5, -21.5, -53.5),
    // Bolivia
    _Box('BO', 'Bolivia', -22.5, -69.5, -9.5, -57.5),
    // Morocco
    _Box('MA', 'Morocco', 27.5, -13.5, 36.0, -0.5),
    // Algeria
    _Box('DZ', 'Algeria', 18.5, -8.5, 37.5, 12.0),
    // Ethiopia
    _Box('ET', 'Ethiopia', 3.5, 33.0, 15.0, 48.0),
    // Kenya
    _Box('KE', 'Kenya', -4.5, 33.5, 5.0, 42.0),
  ];
}

class _Box {
  const _Box(this.code, this.name, this.minLat, this.minLon, this.maxLat,
      this.maxLon);
  final String code;
  final String name;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
}
