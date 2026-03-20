import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/map/widgets/alarm_map.dart';
import 'package:location_alarm/features/map/widgets/center_on_location_fab.dart';
import 'package:location_alarm/features/map/widgets/compass_button.dart';
import 'package:location_alarm/features/map/widgets/current_location_marker.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class MapPickerResult {
  const MapPickerResult({
    required this.location,
    required this.radius,
    this.thumbnail,
  });

  final LatLng location;
  final double radius;
  final Uint8List? thumbnail;
}

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key, this.initialLocation, this.initialRadius});

  final LatLng? initialLocation;
  final double? initialRadius;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

// Logarithmic radius slider: finer steps at low end, coarser at high end.
// t=0 → 100m, t=1 → 5000m
double _sliderToRadius(double t) => 100 * pow(50, t).toDouble();
double _radiusToSlider(double r) => log(r / 100) / log(50);

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final _mapController = MapController();
  final _mapKey = GlobalKey();
  LatLng? _selectedLocation;
  double _radius = 500;
  bool _hasCenteredOnLocation = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _radius = widget.initialRadius ?? 500;
    if (_selectedLocation != null) {
      _hasCenteredOnLocation = true;
    }
    Future.microtask(() {
      ref.read(locationPermissionProvider.notifier).request();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureMap() async {
    try {
      final boundary =
          _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  CameraFit? _initialCameraFit() {
    if (_selectedLocation == null) return null;
    const dist = Distance();
    final offset = dist.offset(_selectedLocation!, _radius, 0);
    final latDiff = (offset.latitude - _selectedLocation!.latitude).abs() * 1.5;
    return CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(
          _selectedLocation!.latitude - latDiff,
          _selectedLocation!.longitude - latDiff,
        ),
        LatLng(
          _selectedLocation!.latitude + latDiff,
          _selectedLocation!.longitude + latDiff,
        ),
      ),
      padding: const EdgeInsets.all(48),
    );
  }

  void _fitCircle({bool forCapture = false}) {
    if (_selectedLocation == null) return;
    const dist = Distance();
    final offset = dist.offset(_selectedLocation!, _radius, 0);
    final latDiff = (offset.latitude - _selectedLocation!.latitude).abs() * 1.5;

    final padding = forCapture
        ? EdgeInsets.symmetric(
            horizontal: 48,
            vertical: MediaQuery.of(context).size.height * 0.25,
          )
        : const EdgeInsets.all(48);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(
            _selectedLocation!.latitude - latDiff,
            _selectedLocation!.longitude - latDiff,
          ),
          LatLng(
            _selectedLocation!.latitude + latDiff,
            _selectedLocation!.longitude + latDiff,
          ),
        ),
        padding: padding,
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    _fitCircle(forCapture: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final thumbnail = await _captureMap();
    if (mounted) {
      Navigator.of(context).pop(
        MapPickerResult(
          location: _selectedLocation!,
          radius: _radius,
          thumbnail: thumbnail,
        ),
      );
    }
  }

  void _centerOnFirstLocation() {
    if (_hasCenteredOnLocation) return;
    final locationAsync = ref.read(locationProvider);
    locationAsync.whenData((position) {
      _hasCenteredOnLocation = true;
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(locationProvider, (_, next) {
      next.whenData((_) => _centerOnFirstLocation());
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick location')),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _mapKey,
            child: AlarmMap(
              mapController: _mapController,
              initialCenter: _selectedLocation,
              initialZoom: _selectedLocation != null ? 15 : 7,
              initialCameraFit: _initialCameraFit(),
              onTap: (_, latLng) {
                setState(() => _selectedLocation = latLng);
              },
              children: [
                const CurrentLocationMarker(),
                if (_selectedLocation != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _selectedLocation!,
                        radius: _radius,
                        useRadiusInMeter: true,
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        borderColor: colorScheme.primary,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    rotate: true,
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(28),
                      color: colorScheme.surface,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            '${_radius.round()} m',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Expanded(
                            child: Slider(
                              value: _radiusToSlider(_radius),
                              min: 0,
                              max: 1,
                              divisions: 100,
                              semanticFormatterCallback: (_) =>
                                  '${_radius.round()} metres radius',
                              onChanged: (t) {
                                setState(() => _radius = _sliderToRadius(t));
                                _fitCircle();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _confirming ? null : _confirm,
                      icon: _confirming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                CenterOnLocationButton(mapController: _mapController),
                const SizedBox(height: 8),
                CompassButton(mapController: _mapController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
