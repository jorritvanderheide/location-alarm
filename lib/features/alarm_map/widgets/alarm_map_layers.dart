import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AlarmMapLayers extends StatelessWidget {
  const AlarmMapLayers({
    super.key,
    required this.location,
    required this.radius,
  });

  final LatLng location;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        CircleLayer(
          circles: [
            CircleMarker(
              point: location,
              radius: radius,
              useRadiusInMeter: true,
              color: colorScheme.primary.withValues(alpha: 0.25),
              borderColor: colorScheme.primary,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          rotate: true,
          markers: [
            Marker(
              point: location,
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.location_on,
                size: 40,
                color: colorScheme.primary,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
