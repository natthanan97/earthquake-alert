import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _channelId = 'quake_alerts';
  static const _channelName = 'QuakeWatch Alerts';
  static const _channelDesc = 'High-priority alerts for nearby earthquake events';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.max,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
    enableLights: true,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
    log('Initialized', name: 'NotificationService');
  }

  Future<void> requestPermission() async {
    // iOS / macOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      log(
        'iOS permission ${granted == true ? "granted" : "denied"}',
        name: 'NotificationService',
      );
      return;
    }

    // Android 13+ (API 33)
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      log(
        'Android permission ${granted == true ? "granted" : "denied"}',
        name: 'NotificationService',
      );
    }
  }

  Future<void> showEarthquakeAlert({
    required int id,
    required double magnitude,
    required String location,
    double? distanceMeters,
  }) async {
    assert(_initialized, 'Call init() before showEarthquakeAlert()');

    final mag = magnitude.toStringAsFixed(1);
    final body = distanceMeters != null
        ? '$location  •  ${(distanceMeters / 1000).toStringAsFixed(1)} km away'
        : location;

    await _plugin.show(
      id,
      '⚠ Earthquake — M$mag',
      body,
      _notificationDetails,
    );

    log(
      'Alert shown — M$mag at $location'
      '${distanceMeters != null ? ", ${(distanceMeters / 1000).toStringAsFixed(1)} km away" : ""}',
      name: 'NotificationService',
    );
  }
}
