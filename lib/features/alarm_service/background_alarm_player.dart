import 'dart:async';

import 'package:flutter/services.dart';
import 'package:there_yet/shared/data/models/alarm.dart';

const _notificationChannel = MethodChannel(
  'nl.bw20.there_yet/alarm_notification',
);
const _audioChannel = MethodChannel('nl.bw20.there_yet/alarm_audio');

/// Isolate-safe alarm player. Works from the foreground service's background
/// isolate as well as the main isolate.
class BackgroundAlarmPlayer {
  /// Fire an alarm: play looping audio, vibrate, show notification.
  Future<void> fire(AlarmData alarm) async {
    if (alarm.id == null) return;

    // Start looping audio in the background without blocking notification.
    unawaited(_playLoop());

    final label = alarm.name.isNotEmpty ? alarm.name : null;
    final title = label ?? 'There Yet';
    final body = 'You are within ${alarm.radius.round()} m of your destination';

    try {
      await _notificationChannel.invokeMethod('showAlarm', {
        'alarmId': alarm.id,
        'title': title,
        'body': body,
      });
    } on Exception {
      // Non-critical. Audio is already playing.
    }
  }

  Future<void> _playLoop() async {
    try {
      await _audioChannel.invokeMethod('play');
    } on Exception {
      // Audio may not be available in all contexts.
    }
    try {
      await HapticFeedback.vibrate();
    } on Exception {
      // Not available in background isolate.
    }
  }

  /// Stop the currently ringing alarm.
  Future<void> stop({int alarmId = -1}) async {
    try {
      await _audioChannel.invokeMethod('stop');
    } on Exception {
      // Best-effort stop.
    }
    try {
      await _notificationChannel.invokeMethod('dismissAlarm', {
        'alarmId': alarmId,
      });
    } on Exception {
      // Best-effort dismiss.
    }
  }

  /// Release resources.
  Future<void> dispose() async {
    await stop();
  }
}
