import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class CurrentLocationMarker extends ConsumerWidget {
  const CurrentLocationMarker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return locationAsync.when(
      data: (position) => MarkerLayer(
        rotate: true,
        markers: [
          Marker(
            point: LatLng(position.latitude, position.longitude),
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Accuracy ring
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                // Center dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
