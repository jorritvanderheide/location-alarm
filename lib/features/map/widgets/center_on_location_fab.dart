import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class CenterOnLocationFab extends ConsumerWidget {
  const CenterOnLocationFab({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      heroTag: 'center_location',
      onPressed: () {
        final locationAsync = ref.read(locationProvider);
        locationAsync.whenData((position) {
          mapController.move(LatLng(position.latitude, position.longitude), 15);
        });
      },
      child: const Icon(Icons.my_location),
    );
  }
}
