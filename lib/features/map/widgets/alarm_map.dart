import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class AlarmMap extends StatelessWidget {
  const AlarmMap({
    super.key,
    required this.mapController,
    this.onTap,
    this.initialCenter,
    this.initialZoom = 7,
    this.initialCameraFit,
    this.children = const [],
  });

  final MapController mapController;
  final void Function(TapPosition, LatLng)? onTap;
  final LatLng? initialCenter;
  final double initialZoom;
  final CameraFit? initialCameraFit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const LatLng(52.0, 5.5),
        initialZoom: initialZoom,
        initialCameraFit: initialCameraFit,
        onTap: onTap,
        interactionOptions: const InteractionOptions(rotationThreshold: 25),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'nl.bw20.location_alarm',
        ),
        ...children,
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
