import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake.dart';

class EarthquakeCard extends StatelessWidget {
  const EarthquakeCard({super.key, required this.earthquake});

  final Earthquake earthquake;

  Color _magnitudeColor(double mag) {
    if (mag >= 7.0) return Colors.red;
    if (mag >= 5.0) return Colors.orange;
    if (mag >= 3.0) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _magnitudeColor(earthquake.magnitude);
    final formattedTime =
        DateFormat('MMM d, y  HH:mm').format(earthquake.time.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                earthquake.magnitude.toStringAsFixed(1),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earthquake.place,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Depth: ${earthquake.depth.toStringAsFixed(1)} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
