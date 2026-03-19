import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

sealed class AlarmData {
  const AlarmData({
    this.id,
    required this.name,
    required this.location,
    required this.active,
    this.createdAt,
  });

  final int? id;
  final String name;
  final LatLng location;
  final bool active;
  final DateTime? createdAt;
}

final class ProximityAlarmData extends AlarmData {
  const ProximityAlarmData({
    super.id,
    required super.name,
    required super.location,
    required super.active,
    super.createdAt,
    required this.radius,
  });

  final double radius;
}

final class DepartureAlarmData extends AlarmData {
  const DepartureAlarmData({
    super.id,
    required super.name,
    required super.location,
    required super.active,
    super.createdAt,
    required this.travelMode,
    required this.bufferMinutes,
    required this.arrivalTime,
  });

  final TravelMode travelMode;
  final int bufferMinutes;
  final DateTime arrivalTime;
}
