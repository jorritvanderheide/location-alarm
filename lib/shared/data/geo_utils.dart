import 'package:latlong2/latlong.dart';

const _distanceCalc = Distance();

double distanceInMeters(LatLng from, LatLng to) {
  return _distanceCalc.as(LengthUnit.Meter, from, to);
}
