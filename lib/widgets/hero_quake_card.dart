import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake.dart';
import 'earthquake_history_tile.dart';

/// Large hero card for the latest earthquake with pulse animation.
class HeroQuakeCard extends StatefulWidget {
  const HeroQuakeCard({
    super.key,
    required this.earthquake,
    this.distanceMeters,
    this.onTap,
  });

  final Earthquake earthquake;
  final double? distanceMeters;
  final VoidCallback? onTap;

  @override
  State<HeroQuakeCard> createState() => _HeroQuakeCardState();
}

class _HeroQuakeCardState extends State<HeroQuakeCard>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _HeroCardBody(
          earthquake: widget.earthquake,
          pulse: _pulse,
          distanceMeters: widget.distanceMeters,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _HeroCardBody extends StatelessWidget {
  const _HeroCardBody({
    required this.earthquake,
    required this.pulse,
    this.distanceMeters,
    this.onTap,
  });

  final Earthquake earthquake;
  final Animation<double> pulse;
  final double? distanceMeters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = EarthquakeHistoryTile.magnitudeColor(earthquake.magnitude);
    final scaleLabel = EarthquakeHistoryTile.maxScaleLabel(earthquake.maxScale);
    final time = DateFormat('MMM d, y  HH:mm:ss').format(earthquake.time.toLocal());

    final withinAlert =
        distanceMeters != null && distanceMeters! <= 2000;
    final distanceLabel = distanceMeters == null
        ? null
        : distanceMeters! >= 1000
            ? '${(distanceMeters! / 1000).toStringAsFixed(distanceMeters! >= 10000 ? 0 : 1)} km'
            : '${distanceMeters!.toStringAsFixed(0)} m';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            cs.surfaceContainerHigh,
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Label row
            Row(
              children: [
                AnimatedBuilder(
                  animation: pulse,
                  builder: (ctx, child) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: pulse.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: pulse.value * 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LATEST EVENT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Magnitude + location
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big magnitude display with pulse ring
                AnimatedBuilder(
                  animation: pulse,
                  builder: (_, child) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: pulse.value * 0.3),
                            width: 8,
                          ),
                        ),
                      ),
                      child!,
                    ],
                  ),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'M',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        Text(
                          earthquake.magnitude >= 0
                              ? earthquake.magnitude.toStringAsFixed(1)
                              : '—',
                          style: TextStyle(
                            color: color,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        earthquake.location,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${earthquake.latitude.toStringAsFixed(2)}°, '
                        '${earthquake.longitude.toStringAsFixed(2)}°',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: color.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 16),

            // Detail chips row
            Row(
              children: [
                _Chip(
                  icon: Icons.arrow_downward,
                  label: 'DEPTH',
                  value: '${earthquake.depth.toStringAsFixed(0)} km',
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                _Chip(
                  icon: Icons.bar_chart,
                  label: 'MAX SCALE',
                  value: scaleLabel == '—' ? '—' : scaleLabel,
                  color: earthquake.maxScale >= 50
                      ? Colors.orange
                      : cs.onSurfaceVariant,
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(width: 12),
                  _Chip(
                    icon: Icons.social_distance,
                    label: 'DISTANCE',
                    value: distanceLabel,
                    color: withinAlert ? Colors.red : cs.onSurfaceVariant,
                  ),
                ],
                const Spacer(),
                if (withinAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'ALERT ZONE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else if (earthquake.maxScale >= 50)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'HIGH INTENSITY',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),

            // View on Map affordance — only shown when onTap is wired up
            if (onTap != null) ...[
              const SizedBox(height: 16),
              Divider(color: color.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.map_outlined, size: 13,
                      color: color.withValues(alpha: 0.8)),
                  const SizedBox(width: 5),
                  Text(
                    'View on Map',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14,
                      color: color.withValues(alpha: 0.7)),
                ],
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
