import 'dart:async';
import 'dart:developer';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'notification_service.dart';
import 'websocket_service.dart';
import '../models/earthquake.dart';

// Entry point called by the foreground task isolate — must be top-level.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_EarthquakeTaskHandler());
}

class _EarthquakeTaskHandler extends TaskHandler {
  WebSocketService? _wsService;
  NotificationService? _notificationService;
  StreamSubscription<Earthquake>? _eqSub;

  // Dedup set — lives for the lifetime of the task.
  final _alerted = <String>{};

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    log('Background task started', name: 'EarthquakeTaskHandler');

    _notificationService = NotificationService();
    await _notificationService!.init();

    _wsService = WebSocketService();

    _eqSub = _wsService!.earthquakeStream.listen(_onEarthquake);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat — WebSocket is passive, nothing to poll.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    log('Background task destroyed', name: 'EarthquakeTaskHandler');
    await _eqSub?.cancel();
    _wsService?.dispose();
  }

  void _onEarthquake(Earthquake eq) {
    final key = '${eq.location}_${eq.time.millisecondsSinceEpoch ~/ 1000}';
    if (_alerted.contains(key)) return;

    // Background task has no GPS — notify for any significant earthquake.
    // Only fire for M4.0+ to reduce noise when there's no distance context.
    if (eq.magnitude < 4.0) return;

    _alerted.add(key);

    _notificationService?.showEarthquakeAlert(
      id: key.hashCode.abs(),
      magnitude: eq.magnitude,
      location: eq.location,
      // No GPS available in background isolate — distance omitted.
    );

    log(
      'Background alert: M${eq.magnitude.toStringAsFixed(1)} ${eq.location}',
      name: 'EarthquakeTaskHandler',
    );
  }
}

/// Initializes and manages the foreground service lifecycle.
class BackgroundMonitoringService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'eq_monitor',
        channelName: 'Earthquake Monitor',
        channelDescription: 'Monitoring for nearby earthquakes in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // 1-min heartbeat
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<ServiceRequestResult> start() {
    return FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'QuakeWatch',
      notificationText: 'Monitoring for earthquakes…',
      callback: startCallback,
    );
  }

  static Future<ServiceRequestResult> stop() {
    return FlutterForegroundTask.stopService();
  }

  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
