import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

/// Pure logic — checks if alarm trigger conditions are met.
/// Does not track state; the caller decides which alarms to check.
class AlarmChecker {
  List<AlarmData> check(List<AlarmData> alarms, LatLng position) {
    return alarms
        .where(
          (alarm) => distanceInMeters(position, alarm.location) <= alarm.radius,
        )
        .toList();
  }
}
