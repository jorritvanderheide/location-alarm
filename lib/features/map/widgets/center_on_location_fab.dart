import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class CenterOnLocationButton extends ConsumerWidget {
  const CenterOnLocationButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);

    final icon = locationAsync.when(
      data: (_) => Icons.my_location,
      loading: () => Icons.location_searching,
      error: (_, _) => Icons.location_disabled,
    );

    return FloatingActionButton.small(
      heroTag: 'center_location',
      elevation: 6,
      onPressed: () {
        final current = ref.read(locationProvider);
        current.when(
          data: (position) {
            mapController.move(
              LatLng(position.latitude, position.longitude),
              15,
            );
          },
          loading: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Getting location...')),
            );
          },
          error: (_, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location unavailable')),
            );
          },
        );
      },
      child: Icon(icon),
    );
  }
}
