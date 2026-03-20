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
import 'package:location_alarm/shared/data/models/alarm_mode.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class MapPickerResult {
  const MapPickerResult({required this.location, this.radius, this.thumbnail});
  final LatLng location;
  final double? radius;
  final Uint8List? thumbnail;
}

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.initialRadius,
    this.mode = AlarmMode.proximity,
  });

  final LatLng? initialLocation;
  final double? initialRadius;
  final AlarmMode mode;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final _mapController = MapController();
  final _mapKey = GlobalKey();
  LatLng? _selectedLocation;
  double _radius = 500;
  bool _hasCenteredOnLocation = false;
  bool _confirming = false;

  bool get _isProximity => widget.mode == AlarmMode.proximity;

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
    if (_isProximity) {
      const dist = Distance();
      final offset = dist.offset(_selectedLocation!, _radius, 0);
      final latDiff =
          (offset.latitude - _selectedLocation!.latitude).abs() * 1.5;
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
    return null;
  }

  void _fitCircle({bool forCapture = false}) {
    if (_selectedLocation == null || !_isProximity) return;
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

  void _fitDeparturePoints() {
    if (_selectedLocation == null) return;
    final locationAsync = ref.read(locationProvider);
    locationAsync.whenData((position) {
      final curLatLng = LatLng(position.latitude, position.longitude);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_selectedLocation!, curLatLng]),
          padding: const EdgeInsets.all(24),
        ),
      );
    });
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
                if (_selectedLocation != null && _isProximity)
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
                if (_selectedLocation != null && !_isProximity)
                  Consumer(
                    builder: (context, ref, _) {
                      final locationAsync = ref.watch(locationProvider);
                      final position = locationAsync.whenData((p) => p).value;
                      if (position == null) return const SizedBox.shrink();
                      return PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(position.latitude, position.longitude),
                              _selectedLocation!,
                            ],
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            strokeWidth: 3,
                            pattern: const StrokePattern.dotted(),
                          ),
                        ],
                      );
                    },
                  ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    rotate: true,
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: _isProximity ? 18 : 48,
                        height: _isProximity ? 18 : 48,
                        alignment: _isProximity
                            ? Alignment.center
                            : Alignment.topCenter,
                        child: _isProximity
                            ? Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.place,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_selectedLocation == null)
            Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'Tap map to place alarm',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProximity)
                        Row(
                          children: [
                            Text(
                              '${_radius.round()} m',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Expanded(
                              child: Slider(
                                value: _radius,
                                min: 100,
                                max: 5000,
                                divisions: 49,
                                semanticFormatterCallback: (v) =>
                                    '${v.round()} metres radius',
                                onChanged: (v) {
                                  setState(() => _radius = v);
                                  _fitCircle();
                                },
                              ),
                            ),
                          ],
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _confirming
                              ? null
                              : () async {
                                  setState(() => _confirming = true);
                                  if (_isProximity) {
                                    _fitCircle(forCapture: true);
                                  } else {
                                    _fitDeparturePoints();
                                  }
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 500),
                                  );
                                  final thumbnail = await _captureMap();
                                  if (context.mounted) {
                                    Navigator.of(context).pop(
                                      MapPickerResult(
                                        location: _selectedLocation!,
                                        radius: _isProximity ? _radius : null,
                                        thumbnail: thumbnail,
                                      ),
                                    );
                                  }
                                },
                          icon: _confirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
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
