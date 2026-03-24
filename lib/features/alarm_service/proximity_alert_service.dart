import 'package:flutter/services.dart';
import 'package:there_yet/shared/data/models/alarm.dart';

/// Manages native Android proximity alerts via LocationManager.
///
/// Proximity alerts act as a coarse "wake-up net". The OS fires them
/// when the device enters a padded radius around the alarm location.
/// The existing GPS polling + AlarmChecker handles the precision trigger.
class ProximityAlertService {
  ProximityAlertService._();

  static const _channel = MethodChannel('nl.bw20.there_yet/proximity_alert');

  static Future<void> register(AlarmData alarm) async {
    if (alarm.id == null) return;
    try {
      await _channel.invokeMethod('register', {
        'id': alarm.id,
        'lat': alarm.location.latitude,
        'lng': alarm.location.longitude,
        'radius': alarm.radius,
      });
    } on MissingPluginException {
      // Running in a context where the channel isn't available (e.g. tests).
    } on Exception {
      // Non-critical. GPS polling acts as fallback.
    }
  }

  static Future<void> unregister(int alarmId) async {
    try {
      await _channel.invokeMethod('unregister', {'id': alarmId});
    } on MissingPluginException {
      // ignore
    } on Exception {
      // Non-critical.
    }
  }

  static Future<void> unregisterAll() async {
    try {
      await _channel.invokeMethod('unregisterAll');
    } on MissingPluginException {
      // ignore
    } on Exception {
      // Non-critical.
    }
  }

  static Future<void> syncAll(List<AlarmData> activeAlarms) async {
    await unregisterAll();
    for (final alarm in activeAlarms) {
      await register(alarm);
    }
  }
}
