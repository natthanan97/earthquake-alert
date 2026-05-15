import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import '../services/location_service.dart';

// ── Providers scoped to this screen ──────────────────────────────────────────

// Accumulates earthquake overlays keyed by unique id, newest-first.
// Capped at 50 to mirror realtimeEarthquakesProvider.
final _eqOverlayProvider =
    NotifierProvider<_EqOverlayNotifier, Map<String, Earthquake>>(
  _EqOverlayNotifier.new,
);

class _EqOverlayNotifier extends Notifier<Map<String, Earthquake>> {
  @override
  Map<String, Earthquake> build() {
    ref.listen<List<Earthquake>>(realtimeEarthquakesProvider, (prev, next) {
      final prevKeys = prev?.map(_key).toSet() ?? {};
      final newOnes = next.where((e) => !prevKeys.contains(_key(e)));
      if (newOnes.isEmpty) return;

      final updated = Map<String, Earthquake>.from(state);
      for (final eq in newOnes) {
        updated[_key(eq)] = eq;
      }
      // Keep newest 50 — iterate insertion order, drop oldest from front.
      if (updated.length > 50) {
        final keys = updated.keys.toList();
        for (var i = 0; i < updated.length - 50; i++) {
          updated.remove(keys[i]);
        }
      }
      state = updated;
    });
    return {};
  }

  static String _key(Earthquake eq) =>
      '${eq.location}_${eq.time.millisecondsSinceEpoch}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _locationService = LocationService();

  late final AnimationController _animCtrl;
  late LatLngTween _cameraTween;
  bool _animating = false;

  StreamSubscription? _locationSub;
  bool _centeredOnUser = false; // animate to user once on first fix

  static const _initialZoom = 5.0;
  static const _defaultCenter = LatLng(35.6762, 139.6503);

  @override
  void initState() {
    super.initState();

    _cameraTween = LatLngTween(begin: _defaultCenter, end: _defaultCenter);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(_onAnimTick)
     ..addStatusListener((s) {
       if (s == AnimationStatus.completed) _animating = false;
     });

    _startLocationStream();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _animCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Camera animation ──────────────────────────────────────────────────────

  void _animateTo(LatLng target) {
    if (_animating) _animCtrl.stop();

    _cameraTween = LatLngTween(
      begin: _mapController.camera.center,
      end: target,
    );
    _animating = true;
    _animCtrl.forward(from: 0);
  }

  void _onAnimTick() {
    final pos = _cameraTween.evaluate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _mapController.move(pos, _mapController.camera.zoom);
  }

  // ── Location stream ───────────────────────────────────────────────────────

  Future<void> _startLocationStream() async {
    try {
      final stream = await _locationService.getPositionStream();
      if (!mounted) return;

      _locationSub = stream.listen((pos) {
        if (!mounted) return;
        final latLng = LatLng(pos.latitude, pos.longitude);

        // Write to provider — _CircleLayer and _MarkerLayer rebuild automatically.
        ref.read(userPositionProvider.notifier).state = latLng;

        // Animate to user only on the first GPS fix.
        if (!_centeredOnUser) {
          _centeredOnUser = true;
          _animateTo(latLng);
        }
      });
    } catch (_) {
      // Permission denied — map works without user location.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen for new earthquakes and animate camera.
    ref.listen<List<Earthquake>>(
      realtimeEarthquakesProvider,
      (prev, next) {
        if (next.isEmpty) return;
        final prevKeys =
            prev?.map((e) => e.time.millisecondsSinceEpoch).toSet() ?? {};
        final hasNew =
            next.any((e) => !prevKeys.contains(e.time.millisecondsSinceEpoch));
        if (hasNew) _animateTo(LatLng(next.first.latitude, next.first.longitude));
      },
    );

    // External focus request — e.g. tapping hero card on dashboard.
    ref.listen<LatLng?>(mapFocusProvider, (prev, target) {
      if (target == null) return;
      _animateTo(target);
      // Reset so subsequent taps on the same quake still fire.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapFocusProvider.notifier).state = null;
      });
    });

    final latest = ref.watch(
      realtimeEarthquakesProvider.select((l) => l.firstOrNull),
    );
    final userLatLng = ref.watch(userPositionProvider);

    final initialCenter =
        userLatLng ?? (latest != null
            ? LatLng(latest.latitude, latest.longitude)
            : _defaultCenter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'My location',
            onPressed: () {
              if (userLatLng != null) _animateTo(userLatLng);
            },
          ),
          if (latest != null)
            IconButton(
              icon: const Icon(Icons.crisis_alert),
              tooltip: 'Latest earthquake',
              onPressed: () =>
                  _animateTo(LatLng(latest.latitude, latest.longitude)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: _initialZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: const [
              // Tile layer is fully static — never rebuilds.
              _TileLayer(),
              // Each layer watches its own provider slice — independent rebuilds.
              _CircleLayer(),
              _MarkerLayer(),
            ],
          ),
          if (latest != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _EpicentreInfoCard(earthquake: latest),
            ),
        ],
      ),
    );
  }
}

// ── Isolated tile layer (never rebuilds) ──────────────────────────────────────

class _TileLayer extends StatelessWidget {
  const _TileLayer();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.example.earthquake_alert',
      retinaMode: true,
    );
  }
}

// ── Circle layer — rebuilds only when overlays or user location changes ───────

class _CircleLayer extends ConsumerWidget {
  const _CircleLayer();

  static const _alertRadius = 2000.0;

  static Color _magColor(double m) {
    if (m >= 6.0) return Colors.red;
    if (m >= 4.0) return Colors.orange;
    return Colors.green;
  }

  static double _magRadius(double m) {
    if (m >= 7.0) return 500000;
    if (m >= 6.0) return 200000;
    if (m >= 4.0) return 50000;
    return 20000;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlays = ref.watch(_eqOverlayProvider);
    final userLatLng = ref.watch(userPositionProvider);

    return CircleLayer(
      circles: [
        if (userLatLng != null)
          CircleMarker(
            point: userLatLng,
            radius: _alertRadius,
            useRadiusInMeter: true,
            color: Colors.blue.withValues(alpha: 0.08),
            borderColor: Colors.blue.withValues(alpha: 0.5),
            borderStrokeWidth: 1.5,
          ),
        for (final eq in overlays.values)
          CircleMarker(
            point: LatLng(eq.latitude, eq.longitude),
            radius: _magRadius(eq.magnitude),
            useRadiusInMeter: true,
            color: _magColor(eq.magnitude).withValues(alpha: 0.06),
            borderColor: _magColor(eq.magnitude).withValues(alpha: 0.4),
            borderStrokeWidth: 1,
          ),
      ],
    );
  }
}

// ── Marker layer — rebuilds only when overlays or user location changes ───────

class _MarkerLayer extends ConsumerWidget {
  const _MarkerLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlays = ref.watch(_eqOverlayProvider);
    final userLatLng = ref.watch(userPositionProvider);

    return MarkerLayer(
      markers: [
        if (userLatLng != null)
          Marker(
            point: userLatLng,
            width: 32,
            height: 32,
            child: const _UserDot(),
          ),
        for (final eq in overlays.values)
          Marker(
            point: LatLng(eq.latitude, eq.longitude),
            width: 48,
            height: 48,
            child: _EpicentrePin(eq: eq),
          ),
      ],
    );
  }
}

// ── User dot ──────────────────────────────────────────────────────────────────

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

// ── Epicentre pin ─────────────────────────────────────────────────────────────

class _EpicentrePin extends StatelessWidget {
  const _EpicentrePin({required this.eq});
  final Earthquake eq;

  @override
  Widget build(BuildContext context) {
    final color = eq.magnitude >= 6.0
        ? Colors.red
        : eq.magnitude >= 4.0
            ? Colors.orange
            : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        eq.magnitude >= 0 ? eq.magnitude.toStringAsFixed(1) : '?',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _EpicentreInfoCard extends StatelessWidget {
  const _EpicentreInfoCard({required this.earthquake});
  final Earthquake earthquake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mag = earthquake.magnitude;
    final color = mag >= 6.0
        ? Colors.red
        : mag >= 4.0
            ? Colors.orange
            : Colors.green;

    return Card(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                mag.toStringAsFixed(1),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    earthquake.location,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Depth ${earthquake.depth.toStringAsFixed(0)} km'
                    '  ·  ${earthquake.latitude.toStringAsFixed(2)}°,'
                    ' ${earthquake.longitude.toStringAsFixed(2)}°',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
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
