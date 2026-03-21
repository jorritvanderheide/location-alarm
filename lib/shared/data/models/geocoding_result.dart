import 'package:latlong2/latlong.dart';

final class GeocodingResult {
  const GeocodingResult({
    required this.displayName,
    required this.location,
    this.type,
  });

  final String displayName;
  final LatLng location;
  final String? type;
}
