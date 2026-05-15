import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import 'earthquake_history_tile.dart';

class EarthquakeHistoryList extends ConsumerStatefulWidget {
  const EarthquakeHistoryList({super.key});

  @override
  ConsumerState<EarthquakeHistoryList> createState() =>
      _EarthquakeHistoryListState();
}

class _EarthquakeHistoryListState
    extends ConsumerState<EarthquakeHistoryList> {
  final _scrollController = ScrollController();
  int _previousCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final earthquakes = ref.watch(realtimeEarthquakesProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Auto-scroll to top when a new item arrives
    if (earthquakes.length > _previousCount && _previousCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
    }
    _previousCount = earthquakes.length;

    if (earthquakes.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.sensors, size: 40, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Waiting for realtime events…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _AnimatedTile(
          key: ValueKey(earthquakes[i].time.microsecondsSinceEpoch),
          earthquake: earthquakes[i],
        ),
        childCount: earthquakes.length,
      ),
    );
  }
}

// Wraps the tile with an enter animation; only runs once on insert.
class _AnimatedTile extends StatefulWidget {
  const _AnimatedTile({super.key, required this.earthquake});

  final Earthquake earthquake;

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: EarthquakeHistoryTile(earthquake: widget.earthquake),
      ),
    );
  }
}
