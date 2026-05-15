import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earthquake.dart';
import '../services/earthquake_service.dart';
import '../services/websocket_service.dart';

final earthquakeServiceProvider = Provider<EarthquakeService>(
  (_) => EarthquakeService(),
);

final earthquakesProvider = FutureProvider.autoDispose<List<Earthquake>>(
  (ref) => ref.watch(earthquakeServiceProvider).fetchRecent(),
);

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(webSocketServiceProvider).statusStream;
});
