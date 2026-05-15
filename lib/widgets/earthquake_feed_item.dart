import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_feed_provider.dart';

/// Compact feed row. Stateless — animation is handled by the list wrapper.
class EarthquakeFeedItem extends StatelessWidget {
  const EarthquakeFeedItem({
    super.key,
    required this.item,
    this.onTap,
    this.isNew = false,
  });

  final FeedItem item;
  final VoidCallback? onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final eq = item.earthquake;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = magnitudeColor(eq.magnitude);
    final time = DateFormat('MM/dd HH:mm').format(eq.time.toLocal());
    final withinAlert =
        item.distanceMeters != null && item.distanceMeters! <= 2000;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isNew
              ? color.withValues(alpha: 0.08)
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNew
                ? color.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.25),
            width: isNew ? 1.0 : 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              // Flag + magnitude badge
              _MagBadge(magnitude: eq.magnitude, color: color, flag: eq.countryFlag),
              const SizedBox(width: 10),

              // Location + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eq.location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _SourceBadge(source: eq.source),
                        if (eq.tsunami) ...[
                          const SizedBox(width: 3),
                          const _TinyBadge(
                              label: '🌊', color: Colors.cyan),
                        ],
                        if (withinAlert) ...[
                          const SizedBox(width: 3),
                          const _TinyBadge(
                              label: 'NEAR', color: Colors.red),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    _MetaLine(
                      eq: eq,
                      distanceMeters: item.distanceMeters,
                      cs: cs,
                      theme: theme,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Time + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Magnitude + flag badge ────────────────────────────────────────────────────

class _MagBadge extends StatelessWidget {
  const _MagBadge({
    required this.magnitude,
    required this.color,
    required this.flag,
  });
  final double magnitude;
  final Color color;
  final String flag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'M',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  magnitude >= 0 ? magnitude.toStringAsFixed(1) : '—',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -2,
            right: 0,
            child: Text(flag, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Compact meta line ─────────────────────────────────────────────────────────

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.eq,
    required this.distanceMeters,
    required this.cs,
    required this.theme,
  });

  final Earthquake eq;
  final double? distanceMeters;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 10,
    );
    final boldStyle = style?.copyWith(fontWeight: FontWeight.w600);

    final parts = <InlineSpan>[
      TextSpan(text: 'D ', style: style?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
      TextSpan(
          text: eq.depth >= 0 ? '${eq.depth.toStringAsFixed(0)}km' : '—',
          style: boldStyle),
      TextSpan(text: '  Lat ', style: style?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
      TextSpan(text: eq.latitude.toStringAsFixed(2), style: boldStyle),
      TextSpan(text: '  Lon ', style: style?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
      TextSpan(text: eq.longitude.toStringAsFixed(2), style: boldStyle),
      if (eq.source == EarthquakeSource.jma && eq.maxScale != -1) ...[
        TextSpan(text: '  I ', style: style?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        TextSpan(text: maxScaleLabel(eq.maxScale), style: boldStyle),
      ],
      if (distanceMeters != null) ...[
        TextSpan(text: '  📍', style: style),
        TextSpan(
          text: formatDistance(distanceMeters!),
          style: boldStyle?.copyWith(
              color: distanceMeters! <= 2000 ? Colors.red : null),
        ),
      ],
    ];

    return Text.rich(TextSpan(children: parts));
  }
}

// ── Tiny inline badges ────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final EarthquakeSource source;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (source) {
      EarthquakeSource.usgs => (
          'USGS',
          const Color(0xFF1565C0).withValues(alpha: 0.18),
          const Color(0xFF90CAF9),
        ),
      EarthquakeSource.jma => (
          'JMA',
          cs.primaryContainer.withValues(alpha: 0.5),
          cs.onPrimaryContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
