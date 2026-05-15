import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import '../services/distance_service.dart';

// ── Filter state ──────────────────────────────────────────────────────────────

enum MagFilter { all, m2plus, m4plus, m6plus }

class FeedFilters {
  const FeedFilters({
    this.magFilter = MagFilter.all,
    this.nearbyOnly = false,
    this.todayOnly = false,
  });

  final MagFilter magFilter;
  final bool nearbyOnly;
  final bool todayOnly;

  FeedFilters copyWith({
    MagFilter? magFilter,
    bool? nearbyOnly,
    bool? todayOnly,
  }) =>
      FeedFilters(
        magFilter: magFilter ?? this.magFilter,
        nearbyOnly: nearbyOnly ?? this.nearbyOnly,
        todayOnly: todayOnly ?? this.todayOnly,
      );

  bool get isActive =>
      magFilter != MagFilter.all || nearbyOnly || todayOnly;
}

// ── Filter notifier ───────────────────────────────────────────────────────────

class FeedFiltersNotifier extends Notifier<FeedFilters> {
  @override
  FeedFilters build() => const FeedFilters();

  void setMagFilter(MagFilter v) => state = state.copyWith(magFilter: v);
  void toggleNearby() => state = state.copyWith(nearbyOnly: !state.nearbyOnly);
  void toggleToday() => state = state.copyWith(todayOnly: !state.todayOnly);
  void reset() => state = const FeedFilters();
}

final feedFiltersProvider =
    NotifierProvider<FeedFiltersNotifier, FeedFilters>(FeedFiltersNotifier.new);

// ── Feed notifier — tracks realtime-only additions for "isNew" highlight ──────
//
// The actual list shown to the user comes from combinedFeedProvider (historical
// + realtime merged). This notifier just stores keys of events that arrived
// via WebSocket during this session, so the UI can flash them as new.

class EarthquakeFeedNotifier extends Notifier<List<Earthquake>> {
  static const _maxItems = 200;

  @override
  List<Earthquake> build() {
    final ws = ref.watch(webSocketServiceProvider);
    final sub = ws.earthquakeStream.listen((eq) {
      state = [eq, ...state].take(_maxItems).toList();
    });
    ref.onDispose(sub.cancel);
    return [];
  }

  void clear() => state = [];
}

final earthquakeFeedProvider =
    NotifierProvider<EarthquakeFeedNotifier, List<Earthquake>>(
  EarthquakeFeedNotifier.new,
);

// ── Filtered + annotated feed item ───────────────────────────────────────────

class FeedItem {
  const FeedItem({
    required this.earthquake,
    this.distanceMeters,
    this.isHistorical = false,
  });
  final Earthquake earthquake;
  final double? distanceMeters; // null when user location unknown
  final bool isHistorical;
}

/// Derived provider: applies filters and attaches distance annotation.
/// Source is combinedFeedProvider (realtime + historical merged + deduped).
/// Rebuilds when combined feed, filters, or user position change.
final filteredFeedProvider = Provider<List<FeedItem>>((ref) {
  final realtimeKeys = ref
      .watch(earthquakeFeedProvider)
      .map((e) => e.dedupKey)
      .toSet();

  final all = ref.watch(combinedFeedProvider);
  final filters = ref.watch(feedFiltersProvider);
  final userLatLng = ref.watch(userPositionProvider);

  final todayStart = DateTime.now().copyWith(
    hour: 0, minute: 0, second: 0, millisecond: 0,
  );

  final ds = DistanceService();

  final items = <FeedItem>[];
  for (final eq in all) {
    // Magnitude threshold
    final minMag = switch (filters.magFilter) {
      MagFilter.all => 0.0,
      MagFilter.m2plus => 2.0,
      MagFilter.m4plus => 4.0,
      MagFilter.m6plus => 6.0,
    };
    if (eq.magnitude < minMag) continue;

    // Today filter
    if (filters.todayOnly && eq.time.isBefore(todayStart)) continue;

    // Distance
    double? dist;
    if (userLatLng != null &&
        eq.latitude != -200 &&
        eq.longitude != -200) {
      dist = ds.calculateDistanceMeters(
        userLatitude: userLatLng.latitude,
        userLongitude: userLatLng.longitude,
        earthquakeLatitude: eq.latitude,
        earthquakeLongitude: eq.longitude,
      );
    }

    // Nearby filter — only keep if within 100 km when active
    if (filters.nearbyOnly) {
      if (dist == null || dist > 100000) continue;
    }

    items.add(FeedItem(
      earthquake: eq,
      distanceMeters: dist,
      isHistorical: !realtimeKeys.contains(eq.dedupKey),
    ));
  }

  return items;
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color magnitudeColor(double m) {
  if (m >= 6.0) return const Color(0xFFEF5350); // red
  if (m >= 4.0) return const Color(0xFFFF9800); // orange
  return const Color(0xFF66BB6A); // green
}

String maxScaleLabel(int scale) {
  const labels = {
    10: '1', 20: '2', 30: '3', 40: '4', 45: '4強',
    50: '5弱', 55: '5強', 60: '6弱', 65: '6強', 70: '7',
  };
  return scale == -1 ? '—' : (labels[scale] ?? '$scale');
}

String formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}
