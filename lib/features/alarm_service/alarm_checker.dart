import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

const _distanceCalc = Distance();

// Average speeds in meters per minute
const _speeds = {
  TravelMode.walk: 83.3, // ~5 km/h
  TravelMode.cycle: 250.0, // ~15 km/h
  TravelMode.drive: 833.3, // ~50 km/h
};

class AlarmChecker {
  final Set<int> _triggeredIds = {};

  List<AlarmData> check(List<AlarmData> activeAlarms, LatLng position) {
    final triggered = <AlarmData>[];

    for (final alarm in activeAlarms) {
      if (!alarm.active || alarm.id == null) continue;
      if (_triggeredIds.contains(alarm.id)) continue;

      final shouldTrigger = switch (alarm) {
        ProximityAlarmData() => _checkProximity(alarm, position),
        DepartureAlarmData() => _checkDeparture(alarm, position),
      };

      if (shouldTrigger) {
        _triggeredIds.add(alarm.id!);
        triggered.add(alarm);
      }
    }

    return triggered;
  }

  void resetTriggered(int alarmId) {
    _triggeredIds.remove(alarmId);
  }

  void clearAll() {
    _triggeredIds.clear();
  }

  bool _checkProximity(ProximityAlarmData alarm, LatLng position) {
    final distance = _distanceCalc.as(
      LengthUnit.Meter,
      position,
      alarm.location,
    );
    return distance <= alarm.radius;
  }

  bool _checkDeparture(DepartureAlarmData alarm, LatLng position) {
    final distance = _distanceCalc.as(
      LengthUnit.Meter,
      position,
      alarm.location,
    );
    final speed = _speeds[alarm.travelMode] ?? _speeds[TravelMode.walk]!;
    final travelMinutes = distance / speed;
    final totalMinutes = travelMinutes + alarm.bufferMinutes;
    final latestDeparture = alarm.arrivalTime.subtract(
      Duration(minutes: totalMinutes.ceil()),
    );
    return DateTime.now().isAfter(latestDeparture);
  }
}
