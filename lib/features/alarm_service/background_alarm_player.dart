import 'dart:async';

import 'package:flutter/services.dart';
import 'package:location_alarm/shared/data/alarm_log.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

const _notificationChannel = MethodChannel(
  'nl.bw20.location_alarm/alarm_notification',
);
const _audioChannel = MethodChannel('nl.bw20.location_alarm/alarm_audio');

/// Isolate-safe alarm player — works from the foreground service's background
/// isolate as well as the main isolate.
class BackgroundAlarmPlayer {
  /// Fire an alarm — play looping audio, vibrate, show notification.
  Future<void> fire(AlarmData alarm) async {
    if (alarm.id == null) return;

    // Start looping audio in the background — don't block notification.
    unawaited(_playLoop());

    final label = alarm.name.isNotEmpty ? alarm.name : null;
    final title = label ?? 'Location Alarm';
    final body = 'You are within ${alarm.radius.round()} m of your destination';

    try {
      await _notificationChannel.invokeMethod('showAlarm', {
        'alarmId': alarm.id,
        'title': title,
        'body': body,
      });
    } on Exception catch (e) {
      await AlarmLog.write('Notification failed: $e');
    }
  }

  Future<void> _playLoop() async {
    try {
      await _audioChannel.invokeMethod('play');
    } on Exception catch (e) {
      await AlarmLog.write('Audio playback failed: $e');
    }
    try {
      await HapticFeedback.vibrate();
    } on Exception {
      // Not available in background isolate
    }
  }

  /// Stop the currently ringing alarm.
  Future<void> stop({int alarmId = -1}) async {
    try {
      await _audioChannel.invokeMethod('stop');
    } on Exception catch (e) {
      await AlarmLog.write('Audio stop failed: $e');
    }
    try {
      await _notificationChannel.invokeMethod('dismissAlarm', {
        'alarmId': alarmId,
      });
    } on Exception catch (e) {
      await AlarmLog.write('Notification dismiss failed: $e');
    }
  }

  /// Release resources.
  Future<void> dispose() async {
    await stop();
  }
}
