import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

const _channelId = 'location_alarm_v2';
const _channelName = 'Location Alarm';
const _notificationId = 9999;
const _dismissActionId = 'dismiss_alarm';

/// Callback for when the notification dismiss action is tapped.
/// Set by main.dart to bridge the notification action to the app.
typedef AlarmDismissCallback = Future<void> Function();

class AlarmPlayer {
  AlarmPlayer._();

  static final _audioPlayer = AudioPlayer();
  static final _notifications = FlutterLocalNotificationsPlugin();
  static AlarmData? _ringingAlarm;
  static final _ringingController = StreamController<AlarmData?>.broadcast();
  static AlarmDismissCallback? _onDismiss;

  /// Stream that emits the currently ringing alarm, or null when stopped.
  static Stream<AlarmData?> get ringing => _ringingController.stream;

  /// The currently ringing alarm, or null.
  static AlarmData? get currentRinging => _ringingAlarm;

  /// Set the callback for notification dismiss action.
  static void setDismissCallback(AlarmDismissCallback callback) {
    _onDismiss = callback;
  }

  /// Initialize the notification plugin. Call once at app startup.
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == _dismissActionId) {
      _onDismiss?.call();
    }
  }

  /// Fire an alarm — play audio, show notification, vibrate.
  static Future<void> fire(AlarmData alarm) async {
    if (alarm.id == null) return;

    debugPrint('ALARM: AlarmPlayer.fire(${alarm.id})');
    _ringingAlarm = alarm;
    _ringingController.add(alarm);

    // Start audio (don't await play — it completes when playback ends,
    // which is never with LoopMode.all)
    await _audioPlayer.setAsset('assets/alarm.wav');
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setVolume(1.0);
    unawaited(_audioPlayer.play());

    // Vibrate
    unawaited(HapticFeedback.vibrate());

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
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
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
              _dismissActionId,
              'Dismiss',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
    debugPrint('ALARM: notification shown');
  }

  /// Stop the currently ringing alarm.
  static Future<void> stop() async {
    _ringingAlarm = null;
    _ringingController.add(null);

    await _audioPlayer.stop();
    await _notifications.cancel(id: _notificationId);
  }
}
