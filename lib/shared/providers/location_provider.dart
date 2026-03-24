import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/shared/providers/location_permission_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Live GPS stream. Requires foreground location permission.
final locationProvider = StreamProvider<Position>((ref) {
  final permission = ref.watch(locationPermissionProvider);
  if (permission != PermissionStatus.granted) {
    return Stream.error(
      const PermissionDeniedException('Location permission not granted'),
    );
  }
  return Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      forceLocationManager: true,
    ),
  );
});

/// Best available position as LatLng: live GPS > last known > null.
/// Pre-warm by watching on the list screen for instant map centering.
final bestPositionProvider = Provider<LatLng?>((ref) {
  // Live GPS has priority.
  final live = ref.watch(locationProvider);
  if (live case AsyncData(:final value)) {
    return LatLng(value.latitude, value.longitude);
  }
  // Fall back to last known (cached by the OS, no permission needed).
  final lastKnown = ref.watch(_lastKnownProvider);
  if (lastKnown case AsyncData(:final value) when value != null) {
    return LatLng(value.latitude, value.longitude);
  }
  return null;
});

/// Last known position. Fast, no hardware query, no permission needed.
final _lastKnownProvider = FutureProvider<Position?>((ref) {
  return Geolocator.getLastKnownPosition();
});
