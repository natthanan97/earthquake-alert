import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake.dart';

class EarthquakeHistoryTile extends StatelessWidget {
  const EarthquakeHistoryTile({super.key, required this.earthquake});

  final Earthquake earthquake;

  static Color magnitudeColor(double m) {
    if (m >= 6.0) return Colors.red;
    if (m >= 4.0) return Colors.orange;
    return Colors.green;
  }

  static String maxScaleLabel(int scale) {
    const labels = {
      10: '1', 20: '2', 30: '3', 40: '4', 45: '4強',
      50: '5弱', 55: '5強', 60: '6弱', 65: '6強', 70: '7',
    };
    return scale == -1 ? '—' : (labels[scale] ?? '$scale');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = magnitudeColor(earthquake.magnitude);
    final time = DateFormat('MMM d  HH:mm').format(earthquake.time.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Magnitude badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                earthquake.magnitude >= 0
                    ? earthquake.magnitude.toStringAsFixed(1)
                    : '—',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Location + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earthquake.location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right-side stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatLabel(
                  label: 'Depth',
                  value: '${earthquake.depth.toStringAsFixed(0)} km',
                  cs: cs,
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _StatLabel(
                  label: 'Scale',
                  value: maxScaleLabel(earthquake.maxScale),
                  cs: cs,
                  theme: theme,
                  valueColor: earthquake.maxScale >= 50 ? Colors.orange : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  const _StatLabel({
    required this.label,
    required this.value,
    required this.cs,
    required this.theme,
    this.valueColor,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final ThemeData theme;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}
