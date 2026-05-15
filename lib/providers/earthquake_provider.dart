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

// Accumulates realtime events; newest first, capped at 50.
final realtimeEarthquakesProvider =
    NotifierProvider<RealtimeEarthquakesNotifier, List<Earthquake>>(
  RealtimeEarthquakesNotifier.new,
);

class RealtimeEarthquakesNotifier extends Notifier<List<Earthquake>> {
  @override
  List<Earthquake> build() {
    final service = ref.watch(webSocketServiceProvider);
    final sub = service.earthquakeStream.listen((eq) {
      state = [eq, ...state].take(50).toList();
    });
    ref.onDispose(sub.cancel);
    return [];
  }
}
