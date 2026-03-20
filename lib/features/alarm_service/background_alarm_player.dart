import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

const backgroundAlarmChannelId = 'location_alarm_v2';
const backgroundAlarmChannelName = 'Location Alarm';
const backgroundAlarmNotificationId = 9999;
const dismissActionId = 'dismiss_alarm';

/// Isolate-safe alarm player — works from the foreground service's background
/// isolate as well as the main isolate.
class BackgroundAlarmPlayer {
  final _audioPlayer = AudioPlayer();
  final _notifications = FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin. Call once per isolate.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings: initSettings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        backgroundAlarmChannelId,
        backgroundAlarmChannelName,
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  /// Fire an alarm — play looping audio, vibrate, show notification.
  Future<void> fire(AlarmData alarm) async {
    if (alarm.id == null) return;

    debugPrint('ALARM: BackgroundAlarmPlayer.fire(${alarm.id})');

    // Start looping audio
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('alarm.wav'), volume: 1.0);

    // Vibrate
    try {
      await HapticFeedback.vibrate();
    } on MissingPluginException {
      // May not be available in background isolate
    }

    // Show notification with dismiss action
    final (title, body) = switch (alarm) {
      ProximityAlarmData(:final radius) => (
        'Location Alarm',
        'You are within ${radius.round()} m of your destination',
      ),
      DepartureAlarmData(:final travelMode) => (
        'Time to Leave',
        'Leave now by ${travelMode.name} to arrive on time',
      ),
    };

    debugPrint('ALARM: showing notification');
    await _notifications.show(
      id: backgroundAlarmNotificationId,
      title: title,
      body: body,
      payload: alarm.id.toString(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          backgroundAlarmChannelId,
          backgroundAlarmChannelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          category: AndroidNotificationCategory.alarm,
          actions: [
            AndroidNotificationAction(
              dismissActionId,
              'Dismiss',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Stop the currently ringing alarm.
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _notifications.cancel(id: backgroundAlarmNotificationId);
  }

  /// Release resources.
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
