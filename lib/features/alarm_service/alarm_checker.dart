import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:there_yet/shared/data/geo_utils.dart';
import 'package:there_yet/shared/data/models/alarm.dart';

/// Pure logic: checks if alarm trigger conditions are met.
/// Does not track state; the caller decides which alarms to check.
class AlarmChecker {
  /// Returns alarms whose trigger zone contains [position].
  ///
  /// Adds a safety margin based on GPS [accuracy] so that edge-of-radius
  /// positions with high uncertainty still trigger.
  List<AlarmData> check(
    List<AlarmData> alarms,
    LatLng position, {
    double accuracy = 0,
  }) {
    // Margin: at least 25m, or half the reported accuracy.
    final margin = max(25.0, accuracy / 2);
    return alarms
        .where(
          (alarm) =>
              distanceInMeters(position, alarm.location) <=
              alarm.radius + margin,
        )
        .toList();
  }
}
