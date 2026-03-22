import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _tileUrl = 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png';

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
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const LatLng(52.0, 5.5),
        initialZoom: initialZoom,
        initialCameraFit: initialCameraFit,
        onTap: onTap,
        onMapReady: onMapReady,
        interactionOptions: const InteractionOptions(rotationThreshold: 45),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'nl.bw20.location_alarm',
          tileProvider: NetworkTileProvider(
            // Show cached tiles when offline instead of errors.
            silenceExceptions: true,
            cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
              // Keep tiles fresh for 30 days — reduces network requests.
              overrideFreshAge: const Duration(days: 30),
              // 2 GB cache — enough for a country at high zoom.
              maxCacheSize: 2_000_000_000,
            ),
          ),
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
