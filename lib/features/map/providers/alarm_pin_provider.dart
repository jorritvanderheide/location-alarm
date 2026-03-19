import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final alarmPinProvider = NotifierProvider<AlarmPinNotifier, LatLng?>(
  AlarmPinNotifier.new,
);

class AlarmPinNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void place(LatLng location) => state = location;

  void clear() => state = null;
}
