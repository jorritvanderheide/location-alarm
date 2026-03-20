import 'package:latlong2/latlong.dart';

final class AlarmData {
  const AlarmData({
    this.id,
    required this.name,
    required this.location,
    required this.active,
    this.createdAt,
    this.updatedAt,
    required this.radius,
  });

  final int? id;
  final String name;
  final LatLng location;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double radius;
}
