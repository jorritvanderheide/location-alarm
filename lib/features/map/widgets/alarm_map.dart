import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _tileUrl = 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

class AlarmMap extends StatelessWidget {
  const AlarmMap({
    super.key,
    required this.mapController,
    this.onTap,
    this.onMapReady,
    this.initialCenter,
    this.initialZoom = 7,
    this.initialCameraFit,
    this.children = const [],
  });

  final MapController mapController;
  final void Function(TapPosition, LatLng)? onTap;
  final VoidCallback? onMapReady;
  final LatLng? initialCenter;
  final double initialZoom;
  final CameraFit? initialCameraFit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // OSM tile background color, visible while tiles load.
      color: const Color(0xFFF2EFE9),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: initialCenter ?? const LatLng(52.0, 5.5),
          initialZoom: initialZoom,
          initialCameraFit: initialCameraFit,
          onTap: onTap,
          onMapReady: onMapReady,
          interactionOptions: const InteractionOptions(
            enableMultiFingerGestureRace: true,
            pinchZoomThreshold: 0.3,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: _tileUrl,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'nl.bw20.there_yet',
            tileProvider: NetworkTileProvider(
              // Show cached tiles when offline instead of error widgets.
              silenceExceptions: true,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
