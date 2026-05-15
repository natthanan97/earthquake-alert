import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/earthquake_card.dart';
import '../widgets/earthquake_history_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(earthquakesProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Alerts'),
        actions: [
          const ConnectionStatusBadge(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(earthquakesProvider),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Dashboard: latest realtime card ──────────────────────────
          const _LatestEventSection(),

          // ── History list header ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'HISTORY  (last 50)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Realtime history list (isolated widget, no HomeScreen rebuild) ──
          const EarthquakeHistoryList(),

          // ── USGS static history ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.public, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'RECENT  (USGS)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          historyAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, st) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text('Failed to load history',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(earthquakesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (earthquakes) {
              if (earthquakes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No recent earthquakes')),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => EarthquakeCard(
                    key: ValueKey('usgs_$i'),
                    earthquake: earthquakes[i],
                  ),
                  childCount: earthquakes.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// Isolated widget — watches only the first item, rebuilds only when latest changes.
class _LatestEventSection extends ConsumerWidget {
  const _LatestEventSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(
      realtimeEarthquakesProvider.select((list) => list.firstOrNull),
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (latest == null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LATEST EVENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cs.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.sensors, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        'Waiting for realtime events…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'LATEST EVENT',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            EarthquakeCard(
              key: ValueKey(latest.time),
              earthquake: latest,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}
