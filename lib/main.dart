import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'providers/earthquake_provider.dart';
import 'screens/earthquake_feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize foreground task config before any service calls.
  BackgroundMonitoringService.init();

  final notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermission();

  runApp(const ProviderScope(child: EarthquakeApp()));
}

class EarthquakeApp extends StatelessWidget {
  const EarthquakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earthquake Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      // WithForegroundTask ensures the service stays alive while the root
      // widget tree is alive and cleans up when it is destroyed.
      home: WithForegroundTask(child: const _RootShell()),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> with WidgetsBindingObserver {
  int _index = 0;

  void _goToMap(double lat, double lon) {
    ref.read(mapFocusProvider.notifier).state = LatLng(lat, lon);
    setState(() => _index = 2);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBackgroundService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The foreground service keeps the WebSocket alive when backgrounded.
    // We start it here if it somehow stopped (e.g. first launch after reboot).
    if (state == AppLifecycleState.resumed) {
      _startBackgroundService();
    }
  }

  Future<void> _startBackgroundService() async {
    final running = await BackgroundMonitoringService.isRunning;
    if (!running) {
      await BackgroundMonitoringService.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeNavigation(
            goToMap: () => setState(() => _index = 2),
            child: const HomeScreen(),
          ),
          FeedNavigation(
            goToMap: _goToMap,
            child: const EarthquakeFeedScreen(),
          ),
          const MapScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
