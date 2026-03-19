import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

class AlarmNotificationService {
  AlarmNotificationService._();

  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> fireAlarm(AlarmData alarm) async {
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

    final settings = AlarmSettings(
      id: alarm.id ?? 0,
      dateTime: DateTime.now(),
      assetAudioPath: 'assets/alarm.wav',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: const VolumeSettings.fixed(),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Dismiss',
        icon: 'notification_icon',
        iconColor: const Color(0xff6750a4),
      ),
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> dismissAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
  }
}
