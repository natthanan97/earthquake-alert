import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_feed_provider.dart';

void showEarthquakeDetailSheet(
  BuildContext context,
  FeedItem item, {
  required void Function(double lat, double lon) onOpenMap,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _DetailSheet(item: item, onOpenMap: onOpenMap),
  );
}

class _DetailSheet extends ConsumerWidget {
  const _DetailSheet({required this.item, required this.onOpenMap});

  final FeedItem item;
  final void Function(double lat, double lon) onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = item.earthquake;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = magnitudeColor(eq.magnitude);
    final scaleLabel = maxScaleLabel(eq.maxScale);
    final time = DateFormat('MMM d, y  HH:mm:ss').format(eq.time.toLocal());
    final coordStr =
        '${eq.latitude.toStringAsFixed(4)}°, ${eq.longitude.toStringAsFixed(4)}°';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Hero magnitude row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flag + magnitude stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2.5),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'M',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                          Text(
                            eq.magnitude >= 0
                                ? eq.magnitude.toStringAsFixed(1)
                                : '—',
                            style: TextStyle(
                              color: color,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Text(eq.countryFlag,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ],
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source + tsunami badges
                      Row(
                        children: [
                          _SourceBadge(source: eq.source, cs: cs),
                          if (eq.tsunami) ...[
                            const SizedBox(width: 6),
                            _TsunamiBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        eq.location,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eq.countryName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Divider(
              indent: 24,
              endIndent: 24,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),

          // ── Detail grid ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DetailTile(
                        icon: Icons.access_time,
                        label: 'TIME',
                        value: time,
                        cs: cs,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailTile(
                        icon: Icons.arrow_downward,
                        label: 'DEPTH',
                        value: eq.depth >= 0
                            ? '${eq.depth.toStringAsFixed(0)} km'
                            : '—',
                        cs: cs,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DetailTile(
                        icon: Icons.my_location,
                        label: 'COORDINATES',
                        value: coordStr,
                        cs: cs,
                        theme: theme,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: coordStr));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coordinates copied'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        trailingIcon: Icons.copy_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailTile(
                        icon: Icons.bar_chart,
                        label: 'MAX INTENSITY',
                        value: eq.source == EarthquakeSource.jma
                            ? scaleLabel
                            : 'N/A (USGS)',
                        cs: cs,
                        theme: theme,
                        valueColor: eq.maxScale >= 50 ? Colors.orange : null,
                      ),
                    ),
                  ],
                ),
                if (item.distanceMeters != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailTile(
                          icon: Icons.social_distance,
                          label: 'DISTANCE FROM YOU',
                          value: formatDistance(item.distanceMeters!),
                          cs: cs,
                          theme: theme,
                          valueColor: item.distanceMeters! <= 2000
                              ? Colors.red
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailTile(
                          icon: Icons.tsunami,
                          label: 'TSUNAMI',
                          value: eq.tsunami ? 'WARNING' : 'None',
                          cs: cs,
                          theme: theme,
                          valueColor:
                              eq.tsunami ? Colors.cyan : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOpenMap(eq.latitude, eq.longitude);
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('View on Map'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    final summary = _buildShareText(eq);
                    Clipboard.setData(ClipboardData(text: summary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Summary copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _buildShareText(Earthquake eq) {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(eq.time.toLocal());
    return '${eq.countryFlag} Earthquake Alert\n'
        'M${eq.magnitude.toStringAsFixed(1)} — ${eq.location}\n'
        'Depth: ${eq.depth.toStringAsFixed(0)} km\n'
        'Time: $time\n'
        'Coords: ${eq.latitude.toStringAsFixed(4)}°, '
        '${eq.longitude.toStringAsFixed(4)}°\n'
        'Source: ${eq.source.name.toUpperCase()}';
  }
}

// ── Detail tile ───────────────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.theme,
    this.valueColor,
    this.onTap,
    this.trailingIcon,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final ThemeData theme;
  final Color? valueColor;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const Spacer(),
                  Icon(trailingIcon, size: 12,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Source badge ──────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, required this.cs});
  final EarthquakeSource source;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (source) {
      EarthquakeSource.usgs => (
          'USGS',
          const Color(0xFF1565C0).withValues(alpha: 0.2),
          const Color(0xFF90CAF9),
        ),
      EarthquakeSource.jma => (
          'JMA',
          cs.primaryContainer.withValues(alpha: 0.6),
          cs.onPrimaryContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TsunamiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tsunami, size: 12, color: Colors.cyan),
          SizedBox(width: 4),
          Text(
            'TSUNAMI',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
