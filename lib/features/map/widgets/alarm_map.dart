import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Shared tile provider — created once, reused across all map instances.
/// Avoids recreating the HTTP client and cache provider on every rebuild.
final _tileProvider = NetworkTileProvider(
  silenceExceptions: true,
  cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
    overrideFreshAge: const Duration(days: 30),
    maxCacheSize: 500_000_000,
  ),
);

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
        interactionOptions: const InteractionOptions(
          enableMultiFingerGestureRace: true,
          rotationThreshold: 45,
          pinchZoomThreshold: 0.3,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'nl.bw20.location_alarm',
          tileProvider: _tileProvider,
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
