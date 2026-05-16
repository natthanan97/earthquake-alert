import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import '../services/websocket_service.dart';
import '../services/distance_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/earthquake_history_list.dart';
import '../widgets/hero_quake_card.dart';
import '../widgets/nearby_quake_card.dart';
import '../widgets/statistics_card.dart';
import '../widgets/websocket_status_card.dart';

// ── Computed stat providers (select prevents whole-list rebuilds) ─────────────

final _todayEarthquakesProvider = Provider<List<Earthquake>>((ref) {
  final list = ref.watch(realtimeEarthquakesProvider);
  final todayStart = DateTime.now().copyWith(
    hour: 0, minute: 0, second: 0, millisecond: 0,
  );
  return list.where((e) => e.time.isAfter(todayStart)).toList();
});

final _todayCountProvider = Provider<int>((ref) {
  return ref.watch(_todayEarthquakesProvider).length;
});

final _todayMaxMagProvider = Provider<double?>((ref) {
  final today = ref.watch(_todayEarthquakesProvider);
  if (today.isEmpty) return null;
  return today.map((e) => e.magnitude).reduce((a, b) => a > b ? a : b);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Alerts'),
        centerTitle: false,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        actions: [
          const _AppBarStatus(),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Hero card ─────────────────────────────────────────────────
          const _HeroSection(),

          // ── Stats row ─────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _sectionLabel(context, 'TODAY\'S OVERVIEW'),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const _StatsRow(),

          // ── WebSocket status ──────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _sectionLabel(context, 'CONNECTION STATUS'),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: WebsocketStatusCard()),

          // ── Nearest earthquake ────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _sectionLabel(context, 'NEARBY ACTIVITY'),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: NearbyQuakeCard()),

          // ── Realtime history ──────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.history, size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'REALTIME HISTORY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _TodayCountChip(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const EarthquakeHistoryList(),

          // ── Bottom padding ────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  static SliverToBoxAdapter _sectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── App bar connection dot (isolated rebuild) ─────────────────────────────────

class _AppBarStatus extends ConsumerWidget {
  const _AppBarStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider);
    final status = statusAsync.valueOrNull;

    final color = switch (status) {
      null => Colors.orange,
      ConnectionStatus.connected => Colors.green,
      ConnectionStatus.disconnected => Colors.red,
      ConnectionStatus.reconnecting => Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(Icons.circle, size: 10, color: color),
    );
  }
}

// ── Hero section — rebuilds only when latest event or user position changes ───

class _HeroSection extends ConsumerWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(
      realtimeEarthquakesProvider.select((l) => l.firstOrNull),
    );
    final userLatLng = ref.watch(userPositionProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (latest == null) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.sensors, size: 24, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for realtime events…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Connected to p2pquake WebSocket',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Distance from user to this quake — null when GPS not available.
    double? distanceMeters;
    if (userLatLng != null &&
        latest.latitude != -200 &&
        latest.longitude != -200) {
      distanceMeters = DistanceService().calculateDistanceMeters(
        userLatitude: userLatLng.latitude,
        userLongitude: userLatLng.longitude,
        earthquakeLatitude: latest.latitude,
        earthquakeLongitude: latest.longitude,
      );
    }

    return SliverToBoxAdapter(
      child: HeroQuakeCard(
        key: ValueKey(latest.time.millisecondsSinceEpoch),
        earthquake: latest,
        distanceMeters: distanceMeters,
        onTap: () => _openOnMap(context, ref, latest.latitude, latest.longitude),
      ),
    );
  }

  void _openOnMap(BuildContext context, WidgetRef ref, double lat, double lon) {
    // Signal MapScreen to pan, then switch to the Map tab via shell callback.
    ref.read(mapFocusProvider.notifier).state = LatLng(lat, lon);
    HomeNavigation.of(context)?.goToMap();
  }
}

// ── Stats row — four metric tiles ────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_todayCountProvider);
    final maxMag = ref.watch(_todayMaxMagProvider);
    final userLatLng = ref.watch(userPositionProvider);
    final earthquakes = ref.watch(realtimeEarthquakesProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    double? nearestKm;
    if (userLatLng != null && earthquakes.isNotEmpty) {
      double min = double.infinity;
      for (final eq in earthquakes) {
        if (eq.latitude == -200 || eq.longitude == -200) continue;
        final d = DistanceService().calculateDistanceMeters(
          userLatitude: userLatLng.latitude,
          userLongitude: userLatLng.longitude,
          earthquakeLatitude: eq.latitude,
          earthquakeLongitude: eq.longitude,
        );
        if (d < min) min = d;
      }
      if (min != double.infinity) nearestKm = min / 1000;
    }

    final magColor = maxMag == null
        ? null
        : maxMag >= 6.0
            ? Colors.red
            : maxMag >= 4.0
                ? Colors.orange
                : Colors.green;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 112,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            StatisticsCard(
              icon: Icons.format_list_numbered,
              label: 'Events today',
              value: '$count',
            ),
            const SizedBox(width: 10),
            StatisticsCard(
              icon: Icons.speed,
              label: 'Strongest today',
              value: maxMag != null ? 'M${maxMag.toStringAsFixed(1)}' : '—',
              valueColor: magColor,
            ),
            const SizedBox(width: 10),
            StatisticsCard(
              icon: Icons.social_distance,
              label: 'Nearest quake',
              value: nearestKm != null
                  ? nearestKm >= 10
                      ? '${nearestKm.toStringAsFixed(0)} km'
                      : '${nearestKm.toStringAsFixed(1)} km'
                  : '—',
              valueColor: nearestKm != null && nearestKm <= 2 ? Colors.red : null,
              subtitle: nearestKm != null && nearestKm <= 2 ? 'IN ALERT ZONE' : null,
            ),
            const SizedBox(width: 10),
            StatisticsCard(
              icon: Icons.radar,
              label: 'Alert radius',
              value: settings != null
                  ? '${settings.alertRadiusKm.toStringAsFixed(0)} km'
                  : '${(DistanceService.defaultAlertRadiusMeters / 1000).toStringAsFixed(0)} km',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today count chip (inside history header) ──────────────────────────────────

class _TodayCountChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_todayCountProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count today',
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Navigation callback injected by _RootShell ────────────────────────────────

class HomeNavigation extends InheritedWidget {
  const HomeNavigation({
    super.key,
    required this.goToMap,
    required super.child,
  });

  final VoidCallback goToMap;

  static HomeNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeNavigation>();

  @override
  bool updateShouldNotify(HomeNavigation old) => false;
}
