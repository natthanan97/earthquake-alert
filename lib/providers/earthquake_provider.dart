import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earthquake.dart';
import '../services/earthquake_service.dart';

final earthquakeServiceProvider = Provider<EarthquakeService>(
  (_) => EarthquakeService(),
);

final earthquakesProvider = FutureProvider.autoDispose<List<Earthquake>>(
  (ref) => ref.watch(earthquakeServiceProvider).fetchRecent(),
);
