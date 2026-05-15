import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import '../services/distance_service.dart';
import 'earthquake_history_tile.dart';

/// Computes nearest earthquake from the cached user position.
/// Rebuilds only when realtime list or user position changes.
class NearbyQuakeCard extends ConsumerWidget {
  const NearbyQuakeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLatLng = ref.watch(userPositionProvider);
    final earthquakes = ref.watch(realtimeEarthquakesProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (userLatLng == null) {
      return _Placeholder(
        icon: Icons.location_off_outlined,
        message: 'Enable location to see nearby earthquakes',
        cs: cs,
        theme: theme,
      );
    }

    if (earthquakes.isEmpty) {
      return _Placeholder(
        icon: Icons.sensors,
        message: 'Waiting for earthquake data…',
        cs: cs,
        theme: theme,
      );
    }

    final nearest = _findNearest(earthquakes, userLatLng);
    final distance = nearest.$2;
    final eq = nearest.$1;
    final color = EarthquakeHistoryTile.magnitudeColor(eq.magnitude);
    final time = DateFormat('MMM d  HH:mm').format(eq.time.toLocal());
    final withinAlert = distance <= DistanceService.defaultAlertRadiusMeters;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: withinAlert
              ? Colors.red.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.near_me,
                  size: 14,
                  color: withinAlert ? Colors.red : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'NEAREST EARTHQUAKE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: withinAlert ? Colors.red : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (withinAlert)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'ALERT ZONE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    eq.magnitude >= 0 ? eq.magnitude.toStringAsFixed(1) : '—',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eq.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDistance(distance),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: withinAlert ? Colors.red : cs.onSurface,
                      ),
                    ),
                    Text(
                      'from you',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Earthquake, double) _findNearest(List<Earthquake> list, LatLng user) {
    Earthquake? nearest;
    double minDist = double.infinity;

    for (final eq in list) {
      if (eq.latitude == -200 || eq.longitude == -200) continue;
      final d = Geolocator.distanceBetween(
        user.latitude, user.longitude, eq.latitude, eq.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearest = eq;
      }
    }

    return (nearest ?? list.first, minDist);
  }

  String _formatDistance(double meters) {
    if (meters == double.infinity) return '—';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.message,
    required this.cs,
    required this.theme,
  });
  final IconData icon;
  final String message;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
