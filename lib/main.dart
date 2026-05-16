import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'providers/earthquake_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/earthquake_feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BackgroundMonitoringService.init();

  final notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermission();

  runApp(const ProviderScope(child: EarthquakeApp()));
}

class EarthquakeApp extends ConsumerWidget {
  const EarthquakeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.themeMode ?? ThemeMode.dark),
    );

    return MaterialApp(
      title: 'QuakeWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: WithForegroundTask(child: const _AppEntry()),
    );
  }
}

// Shows SplashScreen first, then switches to _RootShell.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return SplashScreen(onDone: () => setState(() => _ready = true));
    }
    return const _RootShell();
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) {
      _startBackgroundService();
      // Invalidate WebSocket provider so a fresh connection is established
      // after the app is killed and relaunched (fixes freeze/unresponsive UI).
      ref.invalidate(webSocketServiceProvider);
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
