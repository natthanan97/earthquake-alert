import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/earthquake_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earthquakesAsync = ref.watch(earthquakesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Alerts'),
        actions: [
          const ConnectionStatusBadge(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(earthquakesProvider),
          ),
        ],
      ),
      body: earthquakesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load data',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(earthquakesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (earthquakes) {
          if (earthquakes.isEmpty) {
            return const Center(child: Text('No significant earthquakes found'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(earthquakesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: earthquakes.length,
              itemBuilder: (_, i) => EarthquakeCard(earthquake: earthquakes[i]),
            ),
          );
        },
      ),
    );
  }
}
