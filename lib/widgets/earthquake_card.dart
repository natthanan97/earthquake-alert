import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/earthquake.dart';

class EarthquakeCard extends StatefulWidget {
  const EarthquakeCard({super.key, required this.earthquake, this.highlight = false});

  final Earthquake earthquake;
  final bool highlight;

  @override
  State<EarthquakeCard> createState() => _EarthquakeCardState();
}

class _EarthquakeCardState extends State<EarthquakeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _CardBody(
          earthquake: widget.earthquake,
          highlight: widget.highlight,
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.earthquake, required this.highlight});

  final Earthquake earthquake;
  final bool highlight;

  Color _magColor(double m) {
    if (m >= 7.0) return Colors.red;
    if (m >= 5.0) return Colors.orange;
    if (m >= 3.0) return Colors.yellow;
    return Colors.green;
  }

  String _maxScaleLabel(int scale) {
    const labels = {
      10: '1',
      20: '2',
      30: '3',
      40: '4',
      45: '4強',
      50: '5弱',
      55: '5強',
      60: '6弱',
      65: '6強',
      70: '7',
    };
    return scale == -1 ? '—' : (labels[scale] ?? '$scale');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final magColor = _magColor(earthquake.magnitude);
    final time = DateFormat('MMM d, y  HH:mm:ss').format(earthquake.time.toLocal());

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: highlight ? 8 : 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlight
            ? BorderSide(color: magColor.withValues(alpha: 0.6), width: 1.5)
            : BorderSide.none,
      ),
      color: highlight ? cs.surfaceContainerHigh : cs.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MagnitudeBadge(magnitude: earthquake.magnitude, color: magColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (highlight)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'LATEST EVENT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: magColor,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        earthquake.location,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Detail grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DetailChip(
                  icon: Icons.straighten,
                  label: 'Depth',
                  value: '${earthquake.depth.toStringAsFixed(1)} km',
                ),
                _DetailChip(
                  icon: Icons.my_location,
                  label: 'Latitude',
                  value: earthquake.latitude.toStringAsFixed(3),
                ),
                _DetailChip(
                  icon: Icons.explore,
                  label: 'Longitude',
                  value: earthquake.longitude.toStringAsFixed(3),
                ),
                _DetailChip(
                  icon: Icons.bar_chart,
                  label: 'Max Scale',
                  value: _maxScaleLabel(earthquake.maxScale),
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

class _MagnitudeBadge extends StatelessWidget {
  const _MagnitudeBadge({required this.magnitude, required this.color});

  final double magnitude;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            magnitude >= 0 ? magnitude.toStringAsFixed(1) : '—',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'M',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
