import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_map/widgets/alarm_settings_sheet.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/features/alarm_map/widgets/map_search_bar.dart';
import 'package:location_alarm/features/map/widgets/alarm_map.dart';
import 'package:location_alarm/features/map/widgets/center_on_location_fab.dart';
import 'package:location_alarm/features/map/widgets/compass_button.dart';
import 'package:location_alarm/features/map/widgets/current_location_marker.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/geocoding_provider.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';
import 'package:location_alarm/shared/providers/location_settings_provider.dart';
import 'package:location_alarm/shared/widgets/permission_dialogs.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmMapScreen extends ConsumerStatefulWidget {
  const AlarmMapScreen({super.key, this.alarmId});

  final int? alarmId;

  @override
  ConsumerState<AlarmMapScreen> createState() => _AlarmMapScreenState();
}

class _AlarmMapScreenState extends ConsumerState<AlarmMapScreen>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  final _mapKey = GlobalKey();
  bool _hasCenteredOnLocation = false;
  LatLng? _lastKnownLocation;

  bool _isNew = true;
  bool _loaded = false;
  bool _saving = false;
  bool _wasActive = true;

  late TextEditingController _labelController;
  final _labelFocusNode = FocusNode();
  LatLng? _selectedLocation;
  double _radius = 500;
  double _sheetHeight = 0;

  String _initialLabel = '';
  LatLng? _initialLocation;
  double _initialRadius = 500;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _labelController.addListener(() => setState(() {}));
    _isNew = widget.alarmId == null;
    if (!_isNew) {
      _loadAlarm();
    } else {
      _loaded = true;
    }
    _loadLastKnownLocation();
    Future.microtask(() {
      ref.read(locationPermissionProvider.notifier).request();
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _labelFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  EdgeInsets _mapPadding(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;
    return EdgeInsets.fromLTRB(
      48,
      80 + viewPadding.top, // search bar
      48,
      _sheetHeight + 16, // settings sheet + gap
    );
  }

  Future<void> _loadLastKnownLocation() async {
    if (_selectedLocation != null) return; // editing — already have a location
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null && !_hasCenteredOnLocation && mounted) {
        _lastKnownLocation = LatLng(pos.latitude, pos.longitude);
        setState(() {});
        _mapController.move(_lastKnownLocation!, 13);
      }
    } on Exception {
      // Best-effort — GPS stream will handle it
    }
  }

  bool get _hasUnsavedChanges {
    if (!_loaded) return false;
    return _labelController.text != _initialLabel ||
        _selectedLocation != _initialLocation ||
        _radius != _initialRadius;
  }

  // -- Data loading --

  Future<void> _loadAlarm() async {
    try {
      final repo = ref.read(alarmRepositoryProvider);
      final alarms = await repo.watchAll().first;
      final alarm = alarms.where((a) => a.id == widget.alarmId).firstOrNull;
      if (alarm == null) {
        if (mounted) context.pop();
        return;
      }

      if (!mounted) return;

      setState(() {
        _labelController.text = alarm.name;
        _selectedLocation = alarm.location;
        _wasActive = alarm.active;
        _radius = alarm.radius;
        _hasCenteredOnLocation = true;
        _initialLabel = alarm.name;
        _initialLocation = alarm.location;
        _initialRadius = alarm.radius;
        _loaded = true;
      });
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load alarm')));
        context.pop();
      }
    }
  }

  // -- Map helpers --

  CameraFit? _initialCameraFit(BuildContext context) {
    if (_selectedLocation == null) return null;
    return _boundsForCircle(padding: _mapPadding(context));
  }

  CameraFit _boundsForCircle({EdgeInsets padding = const EdgeInsets.all(48)}) {
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
      padding: padding,
    );
  }

  void _fitCircle() {
    if (_selectedLocation == null) return;
    _mapController.fitCamera(_boundsForCircle(padding: _mapPadding(context)));
  }

  Future<void> _centerOnGps() async {
    final perm = ref.read(locationPermissionProvider);
    if (perm != PermissionStatus.granted) {
      await ref.read(locationPermissionProvider.notifier).request();
      if (ref.read(locationPermissionProvider) != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required')),
          );
        }
        return;
      }
    }

    final locationAsync = ref.read(locationProvider);
    locationAsync.when(
      data: (position) {
        final loc = LatLng(position.latitude, position.longitude);
        const delta = 0.005;
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(
              LatLng(loc.latitude - delta, loc.longitude - delta),
              LatLng(loc.latitude + delta, loc.longitude + delta),
            ),
            padding: _mapPadding(context),
            maxZoom: 15,
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Getting location...')));
      },
      error: (_, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location unavailable')));
      },
    );
  }

  void _centerOnFirstLocation() {
    if (_hasCenteredOnLocation) return;
    final locationAsync = ref.read(locationProvider);
    locationAsync.whenData((_) {
      _hasCenteredOnLocation = true;
      _centerOnGps();
    });
  }

  /// Animates the camera to [target] over [duration].
  Future<void> _animateCamera(
    CameraFit target, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    final dest = target.fit(_mapController.camera);
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final endCenter = dest.center;
    final endZoom = dest.zoom;

    final controller = AnimationController(vsync: this, duration: duration);
    final completer = Completer<void>();

    controller.addListener(() {
      if (!mounted) return;
      final t = Curves.easeInOut.transform(controller.value);
      final lat =
          startCenter.latitude +
          (endCenter.latitude - startCenter.latitude) * t;
      final lng =
          startCenter.longitude +
          (endCenter.longitude - startCenter.longitude) * t;
      final zoom = startZoom + (endZoom - startZoom) * t;
      _mapController.move(LatLng(lat, lng), zoom);
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (!completer.isCompleted) completer.complete();
      }
    });

    controller.forward();
    return completer.future;
  }

  Future<Uint8List?> _captureMap() async {
    try {
      final boundary =
          _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // -- Save --

  Future<void> _save() async {
    if (_saving || _selectedLocation == null) return;
    setState(() => _saving = true);

    try {
      await _performSave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _performSave() async {
    // 1. Verify foreground location.
    if (!await ensureForegroundLocation(context, ref)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
      return;
    }
    if (!mounted) return;

    // 2. Require background location with rationale dialog.
    final bgGranted = await requestBackgroundWithRationale(context, ref);
    if (!mounted) return;
    if (!bgGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background location required to save alarm'),
        ),
      );
      return;
    }

    // 3. Request notification permission (warn but allow save).
    final permNotifier = ref.read(locationPermissionProvider.notifier);
    final notifGranted = await permNotifier.requestNotification();
    if (!mounted) return;
    if (!notifGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications disabled — you won\'t hear the alarm'),
        ),
      );
    }

    // Animate to nicely framed view, then capture thumbnail.
    await _animateCamera(_boundsForCircle());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final thumbnail = await _captureMap();
    if (!mounted) return;

    final repo = ref.read(alarmRepositoryProvider);

    final position = ref.read(locationProvider).whenData((p) => p).value;
    final hasLocationLock = position != null;
    final isInsideRadius =
        hasLocationLock &&
        distanceInMeters(
              LatLng(position.latitude, position.longitude),
              _selectedLocation!,
            ) <=
            _radius;

    final triggerInside = ref.read(triggerInsideRadiusProvider);
    if (isInsideRadius && !triggerInside) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inside alarm area'),
          content: const Text(
            'You are currently inside this alarm area. The alarm will be '
            'saved inactive and activate once you leave.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save inactive'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    // Always reverse geocode for location name (used as card subtitle).
    // Also use as alarm name fallback when no label was typed.
    final geocodingRepo = ref.read(geocodingRepositoryProvider);
    final locationName =
        await geocodingRepo.reverseGeocode(
          _selectedLocation!,
          radius: _radius,
        ) ??
        '';
    final alarmName = _labelController.text.isEmpty
        ? locationName
        : _labelController.text;

    final active = (!hasLocationLock || (isInsideRadius && !triggerInside))
        ? false
        : _wasActive;
    final alarm = AlarmData(
      id: widget.alarmId,
      name: alarmName,
      location: _selectedLocation!,
      active: active,
      radius: _radius,
      locationName: locationName,
    );

    if (thumbnail != null && widget.alarmId != null) {
      try {
        await AlarmThumbnail.save(widget.alarmId!, thumbnail);
      } on Exception {
        // non-critical
      }
    }

    final alarmId = await repo.save(alarm);
    AlarmServiceNotifier.refresh();

    if (thumbnail != null && widget.alarmId == null) {
      try {
        await AlarmThumbnail.save(alarmId, thumbnail);
      } on Exception {
        // non-critical
      }
    }

    if (!mounted) return;

    final label = _labelController.text.isEmpty
        ? 'Alarm'
        : _labelController.text;

    final String message;
    if (!hasLocationLock) {
      message = '$label saved (inactive — no GPS lock)';
    } else if (isInsideRadius) {
      message = '$label saved (inactive)';
    } else {
      message = '$label saved';
    }

    _initialLabel = _labelController.text;
    _initialLocation = _selectedLocation;
    _initialRadius = _radius;

    context.pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    ref.listen(locationProvider, (_, next) {
      next.whenData((_) => _centerOnFirstLocation());
    });

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your unsaved changes will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard != true || !mounted) return;
        if (context.mounted) context.pop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            RepaintBoundary(
              key: _mapKey,
              child: AlarmMap(
                mapController: _mapController,
                initialCenter: _selectedLocation ?? _lastKnownLocation,
                initialZoom: _selectedLocation != null
                    ? 15
                    : _lastKnownLocation != null
                    ? 13
                    : 7,
                initialCameraFit: _initialCameraFit(context),
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

            // Search bar with back button and location search
            MapSearchBar(
              onBack: () => Navigator.of(context).maybePop(),
              near: switch (ref.read(locationProvider)) {
                AsyncData(:final value) => LatLng(
                  value.latitude,
                  value.longitude,
                ),
                _ => null,
              },
              onLocationSelected: (location) {
                setState(() => _selectedLocation = location);
                _fitCircle();
              },
            ),

            // Map controls (bottom-right, above sheet)
            Positioned(
              right: 16,
              bottom: _sheetHeight + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompassButton(mapController: _mapController),
                  const SizedBox(height: 8),
                  CenterOnLocationButton(onPressed: _centerOnGps),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AlarmSettingsSheet(
                labelController: _labelController,
                labelFocusNode: _labelFocusNode,
                radius: _radius,
                canSave: _selectedLocation != null && _hasUnsavedChanges,
                onHeightChanged: (h) {
                  if (h != _sheetHeight) {
                    setState(() => _sheetHeight = h);
                    // Re-center map with updated padding.
                    if (_selectedLocation != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _fitCircle();
                      });
                    }
                  }
                },
                onRadiusChanged: (r) {
                  setState(() => _radius = r);
                  _fitCircle();
                },
                onSave: _save,
                saving: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
