import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/departure_calculator.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

/// Pure logic — checks if alarm trigger conditions are met.
/// Does not track state; the caller decides which alarms to check.
class AlarmChecker {
  List<AlarmData> check(List<AlarmData> alarms, LatLng position) {
    return alarms.where((alarm) {
      return switch (alarm) {
        ProximityAlarmData() =>
          distanceInMeters(position, alarm.location) <= alarm.radius,
        DepartureAlarmData() => _shouldLeave(alarm, position),
      };
    }).toList();
  }

  bool _shouldLeave(DepartureAlarmData alarm, LatLng position) {
    final info = calculateDeparture(
      currentPosition: position,
      destination: alarm.location,
      travelMode: alarm.travelMode,
      bufferMinutes: alarm.bufferMinutes,
      arrivalTime: alarm.arrivalTime,
    );
    return info?.shouldLeaveNow ?? false;
  }
}
