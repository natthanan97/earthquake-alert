import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earthquake_feed_provider.dart';
import '../providers/earthquake_provider.dart';
import '../services/websocket_service.dart';
import '../widgets/earthquake_detail_sheet.dart';
import '../widgets/earthquake_feed_item.dart';

class EarthquakeFeedScreen extends ConsumerStatefulWidget {
  const EarthquakeFeedScreen({super.key});

  @override
  ConsumerState<EarthquakeFeedScreen> createState() =>
      _EarthquakeFeedScreenState();
}

class _EarthquakeFeedScreenState extends ConsumerState<EarthquakeFeedScreen> {
  final _scrollCtrl = ScrollController();
  bool _autoScroll = true;
  // Tracks the key of the item shown at index 0 — used to flash new items.
  Object? _topKey;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filters = ref.watch(feedFiltersProvider);
    final items = ref.watch(filteredFeedProvider);
    final statusAsync = ref.watch(connectionStatusProvider);
    final status = statusAsync.valueOrNull ?? ConnectionStatus.reconnecting;

    // Detect new top item and auto-scroll.
    final newTopKey = items.isNotEmpty
        ? items.first.earthquake.time.millisecondsSinceEpoch
        : null;
    if (newTopKey != _topKey && newTopKey != null) {
      _topKey = newTopKey;
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Live Feed'),
            const SizedBox(width: 10),
            _StatusPill(status: status),
          ],
        ),
        centerTitle: false,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bottom: items.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${items.length} events',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              Icons.vertical_align_top,
              color: _autoScroll ? cs.primary : cs.onSurfaceVariant,
            ),
            tooltip: _autoScroll ? 'Auto-scroll on' : 'Auto-scroll off',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Filter button with badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filters',
                onPressed: () => _showFilterSheet(context),
              ),
              if (filters.isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Active filter chips ────────────────────────────────────────
          if (filters.isActive) _FilterChips(filters: filters),

          // ── Feed list ──────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Pull-to-refresh clears local feed and re-connects.
                ref.read(earthquakeFeedProvider.notifier).clear();
              },
              child: items.isEmpty
                  ? _EmptyState(status: status)
                  : _FeedList(
                      items: items,
                      scrollCtrl: _scrollCtrl,
                      onTapItem: (item) => _showDetail(context, item),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, FeedItem item) {
    showEarthquakeDetailSheet(
      context,
      item,
      onOpenMap: (lat, lon) {
        final nav = FeedNavigation.of(context);
        nav?.goToMap(lat, lon);
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ── Navigation callback (injected by _RootShell) ─────────────────────────────

class FeedNavigation extends InheritedWidget {
  const FeedNavigation({
    super.key,
    required this.goToMap,
    required super.child,
  });

  final void Function(double lat, double lon) goToMap;

  static FeedNavigation? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FeedNavigation>();
  }

  @override
  bool updateShouldNotify(FeedNavigation old) => false;
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.status});
  final ConnectionStatus status;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _opacity =
        Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
    if (widget.status == ConnectionStatus.reconnecting) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.status == ConnectionStatus.reconnecting) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (widget.status) {
      ConnectionStatus.connected => ('LIVE', Colors.green),
      ConnectionStatus.disconnected => ('OFF', Colors.red),
      ConnectionStatus.reconnecting => ('…', Colors.orange),
    };

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active filter chips strip ─────────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.filters});
  final FeedFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final notifier = ref.read(feedFiltersProvider.notifier);

    final magLabel = switch (filters.magFilter) {
      MagFilter.all => null,
      MagFilter.m2plus => 'M2+',
      MagFilter.m4plus => 'M4+',
      MagFilter.m6plus => 'M6+',
    };

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          if (magLabel != null)
            _ActiveChip(
              label: magLabel,
              onRemove: () => notifier.setMagFilter(MagFilter.all),
              theme: theme,
              cs: cs,
            ),
          if (filters.nearbyOnly) ...[
            if (magLabel != null) const SizedBox(width: 6),
            _ActiveChip(
              label: 'Nearby',
              onRemove: notifier.toggleNearby,
              theme: theme,
              cs: cs,
            ),
          ],
          if (filters.todayOnly) ...[
            const SizedBox(width: 6),
            _ActiveChip(
              label: 'Today',
              onRemove: notifier.toggleToday,
              theme: theme,
              cs: cs,
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: notifier.reset,
            child: Text(
              'Clear all',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({
    required this.label,
    required this.onRemove,
    required this.theme,
    required this.cs,
  });
  final String label;
  final VoidCallback onRemove;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

// ── Feed list ─────────────────────────────────────────────────────────────────

class _FeedList extends StatefulWidget {
  const _FeedList({
    required this.items,
    required this.scrollCtrl,
    required this.onTapItem,
  });

  final List<FeedItem> items;
  final ScrollController scrollCtrl;
  final void Function(FeedItem) onTapItem;

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  // Tracks which item keys are "new" (just inserted) for one frame highlight.
  final _newKeys = <int>{};
  List<FeedItem> _prev = [];

  @override
  void didUpdateWidget(_FeedList old) {
    super.didUpdateWidget(old);

    final prevKeys = _prev.map((i) => i.earthquake.time.millisecondsSinceEpoch).toSet();
    final nowKeys = widget.items.map((i) => i.earthquake.time.millisecondsSinceEpoch).toSet();
    final freshKeys = nowKeys.difference(prevKeys);

    if (freshKeys.isNotEmpty) {
      setState(() => _newKeys.addAll(freshKeys));
      // Remove "new" highlight after one second.
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _newKeys.removeAll(freshKeys));
      });
    }

    _prev = widget.items;
  }

  @override
  void initState() {
    super.initState();
    _prev = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: widget.items.length,
      itemBuilder: (context, i) {
        final item = widget.items[i];
        final key = item.earthquake.time.millisecondsSinceEpoch;
        final isNew = _newKeys.contains(key);

        return _AnimatedFeedItem(
          key: ValueKey(key),
          item: item,
          isNew: isNew,
          onTap: () => widget.onTapItem(item),
        );
      },
    );
  }
}

// ── Animated wrapper — slide in from top on insertion ────────────────────────

class _AnimatedFeedItem extends StatefulWidget {
  const _AnimatedFeedItem({
    super.key,
    required this.item,
    required this.isNew,
    required this.onTap,
  });

  final FeedItem item;
  final bool isNew;
  final VoidCallback onTap;

  @override
  State<_AnimatedFeedItem> createState() => _AnimatedFeedItemState();
}

class _AnimatedFeedItemState extends State<_AnimatedFeedItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
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
        child: EarthquakeFeedItem(
          item: widget.item,
          isNew: widget.isNew,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (icon, message) = switch (status) {
      ConnectionStatus.connected => (
          Icons.sensors,
          'Connected — waiting for events…',
        ),
      ConnectionStatus.disconnected => (
          Icons.wifi_off,
          'Disconnected from feed',
        ),
      ConnectionStatus.reconnecting => (
          Icons.sync,
          'Reconnecting to p2pquake…',
        ),
    };

    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to reset the feed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(feedFiltersProvider);
    final notifier = ref.read(feedFiltersProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Filter Feed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Magnitude threshold
          Text(
            'MAGNITUDE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _MagFilterRow(current: filters.magFilter, notifier: notifier),

          const SizedBox(height: 24),

          // Toggle filters
          Text(
            'MORE FILTERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Today only'),
            subtitle: Text(
              'Show events from today',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            value: filters.todayOnly,
            onChanged: (_) => notifier.toggleToday(),
            contentPadding: EdgeInsets.zero,
          ),

          SwitchListTile(
            title: const Text('Nearby only'),
            subtitle: Text(
              'Within 100 km of your location',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            value: filters.nearbyOnly,
            onChanged: (_) => notifier.toggleNearby(),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MagFilterRow extends StatelessWidget {
  const _MagFilterRow({
    required this.current,
    required this.notifier,
  });
  final MagFilter current;
  final FeedFiltersNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _MagChip(
          label: 'All',
          value: MagFilter.all,
          current: current,
          onTap: () => notifier.setMagFilter(MagFilter.all),
        ),
        _MagChip(
          label: 'M2+',
          value: MagFilter.m2plus,
          current: current,
          onTap: () => notifier.setMagFilter(MagFilter.m2plus),
          color: Colors.green,
        ),
        _MagChip(
          label: 'M4+',
          value: MagFilter.m4plus,
          current: current,
          onTap: () => notifier.setMagFilter(MagFilter.m4plus),
          color: Colors.orange,
        ),
        _MagChip(
          label: 'M6+',
          value: MagFilter.m6plus,
          current: current,
          onTap: () => notifier.setMagFilter(MagFilter.m6plus),
          color: Colors.red,
        ),
      ],
    );
  }
}

class _MagChip extends StatelessWidget {
  const _MagChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    this.color,
  });
  final String label;
  final MagFilter value;
  final MagFilter current;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = current == value;
    final activeColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : cs.onSurfaceVariant,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
