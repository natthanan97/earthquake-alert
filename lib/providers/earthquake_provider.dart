import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/earthquake.dart';
import '../services/database_service.dart';
import '../services/distance_service.dart';
import '../services/earthquake_service.dart';
import '../services/historical_earthquake_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/proximity_alert_service.dart';
import '../services/websocket_service.dart';
import 'settings_provider.dart';

/// Shared last-known user GPS position.
/// Written by MapScreen's location stream; read by ProximityAlertService.
final userPositionProvider = StateProvider<LatLng?>((ref) => null);

/// Written by any screen that wants the map to animate to a coordinate.
/// MapScreen consumes this in ref.listen and resets it to null after panning.
final mapFocusProvider = StateProvider<LatLng?>((ref) => null);

final earthquakeServiceProvider = Provider<EarthquakeService>(
  (_) => EarthquakeService(),
);

// Legacy USGS 7-day list used by the home screen history section.
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

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final svc = DatabaseService();
  ref.onDispose(svc.dispose);
  return svc;
});

final proximityAlertServiceProvider = Provider<ProximityAlertService>((ref) {
  return ProximityAlertService(
    locationService: LocationService(),
    distanceService: DistanceService(),
    notificationService: ref.watch(notificationServiceProvider),
    lastKnownPosition: () => ref.read(userPositionProvider),
    alertRadiusMetersSupplier: () {
      final settings = ref.read(settingsProvider).valueOrNull;
      return (settings?.alertRadiusKm ?? 50.0) * 1000;
    },
    minMagnitudeSupplier: () {
      final settings = ref.read(settingsProvider).valueOrNull;
      return settings?.minMagnitude ?? 4.0;
    },
  );
});

// ── Realtime WebSocket feed — newest first, capped at 50 ─────────────────────

final realtimeEarthquakesProvider =
    NotifierProvider<RealtimeEarthquakesNotifier, List<Earthquake>>(
  RealtimeEarthquakesNotifier.new,
);

class RealtimeEarthquakesNotifier extends Notifier<List<Earthquake>> {
  @override
  List<Earthquake> build() {
    final service = ref.watch(webSocketServiceProvider);
    final alertService = ref.watch(proximityAlertServiceProvider);
    final db = ref.watch(databaseServiceProvider);

    // Load cached earthquakes from SQLite on startup so the UI is not empty
    // while waiting for the first WebSocket events.
    _loadCache(db);

    final sub = service.earthquakeStream.listen((eq) {
      state = [eq, ...state].take(50).toList();
      alertService.evaluate(eq);
      db.insertEarthquakes([eq]);
    });
    ref.onDispose(sub.cancel);
    return [];
  }

  Future<void> _loadCache(DatabaseService db) async {
    try {
      final cached = await db.loadRecent(limit: 50);
      if (cached.isNotEmpty && state.isEmpty) {
        state = cached;
      }
    } catch (e) {
      log('Cache load error: $e', name: 'RealtimeEarthquakesNotifier');
    }
  }
}

// ── Historical USGS fetch — once on startup ───────────────────────────────────

final historicalEarthquakesProvider =
    FutureProvider<List<Earthquake>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final svc = HistoricalEarthquakeService();
  try {
    final results = await svc.fetchLast10Hours();
    if (results.isNotEmpty) {
      await db.insertEarthquakes(results);
    }
    return results;
  } catch (e) {
    log('Historical fetch failed — loading from cache: $e',
        name: 'earthquake_provider');
    return db.loadRecent(limit: 200);
  }
});

// ── Combined feed — merges realtime + historical, deduped, newest first ───────
//
// Dedup key: timestamp (second precision) + lat/lon (2 dp) + magnitude (1 dp).
// This tolerates minor float differences between p2pquake and USGS for the
// same physical event while still catching true duplicates.

final combinedFeedProvider = Provider<List<Earthquake>>((ref) {
  final realtime = ref.watch(realtimeEarthquakesProvider);
  final historicalAsync = ref.watch(historicalEarthquakesProvider);
  final historical = historicalAsync.valueOrNull ?? [];

  // Build a set of realtime keys first — they take priority.
  final seen = <String>{};
  final merged = <Earthquake>[];

  for (final eq in realtime) {
    final k = eq.dedupKey;
    if (seen.add(k)) merged.add(eq);
  }

  for (final eq in historical) {
    final k = eq.dedupKey;
    if (seen.add(k)) merged.add(eq);
  }

  // Realtime events are already at the front (they arrived after historical).
  // Sort just in case a late WebSocket event slipped behind a historical one.
  merged.sort((a, b) => b.time.compareTo(a.time));

  return merged;
});
