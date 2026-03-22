import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_map/providers/alarm_form_provider.dart';
import 'package:location_alarm/features/alarm_map/providers/alarm_save_provider.dart';
import 'package:location_alarm/features/alarm_map/widgets/alarm_map_layers.dart';
import 'package:location_alarm/features/alarm_map/widgets/alarm_settings_sheet.dart';
import 'package:location_alarm/features/alarm_map/widgets/map_search_bar.dart';
import 'package:location_alarm/features/map/widgets/alarm_map.dart';
import 'package:location_alarm/features/map/widgets/center_on_location_fab.dart';
import 'package:location_alarm/features/map/widgets/compass_button.dart';
import 'package:location_alarm/features/map/widgets/current_location_marker.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';
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
  final _labelController = TextEditingController();
  final _labelFocusNode = FocusNode();

  bool _hasCenteredOnLocation = false;
  bool _mapReady = false;
  LatLng? _lastKnownLocation;
  double _sheetHeight = 0;

  @override
  void initState() {
    super.initState();
    _labelController.clear();
    _labelController.addListener(_syncNameToProvider);
    _loadLastKnownLocation();
    // Invalidate forces the provider to rebuild fresh — avoids stale state
    // from a previous screen and avoids modifying providers during build.
    ref.invalidate(alarmFormProvider);
    Future.microtask(() {
      if (widget.alarmId != null) {
        ref.read(alarmFormProvider.notifier).loadAlarm(widget.alarmId!);
      }
      ref.read(locationPermissionProvider.notifier).request();
    });
  }

  @override
  void dispose() {
    _labelController.removeListener(_syncNameToProvider);
    _labelController.dispose();
    _labelFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _syncNameToProvider() {
    ref.read(alarmFormProvider.notifier).setName(_labelController.text);
  }

  // -- Map helpers --

  EdgeInsets _mapPadding(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;
    return EdgeInsets.fromLTRB(48, 80 + viewPadding.top, 48, _sheetHeight + 16);
  }

  Future<void> _loadLastKnownLocation() async {
    final form = ref.read(alarmFormProvider);
    if (form.location != null) return;
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null && !_hasCenteredOnLocation && mounted) {
        _lastKnownLocation = LatLng(pos.latitude, pos.longitude);
        setState(() {});
      }
    } on Exception {
      // Best-effort
    }
  }

  CameraFit? _initialCameraFit(BuildContext context) {
    final form = ref.read(alarmFormProvider);
    if (form.location == null) return null;
    return _boundsForCircle(
      form.location!,
      form.radius,
      padding: _mapPadding(context),
    );
  }

  CameraFit _boundsForCircle(
    LatLng center,
    double radius, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) {
    const dist = Distance();
    final offset = dist.offset(center, radius, 0);
    final latDiff = (offset.latitude - center.latitude).abs() * 1.5;

    return CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(center.latitude - latDiff, center.longitude - latDiff),
        LatLng(center.latitude + latDiff, center.longitude + latDiff),
      ),
      padding: padding,
    );
  }

  void _fitCircle() {
    if (!_mapReady) return;
    final form = ref.read(alarmFormProvider);
    if (form.location == null) return;
    _mapController.fitCamera(
      _boundsForCircle(
        form.location!,
        form.radius,
        padding: _mapPadding(context),
      ),
    );
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

    if (!_mapReady) return;

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

  Future<void> _animateCamera(
    CameraFit target, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    if (!_mapReady) return Future.value();
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

  void _save() {
    final form = ref.read(alarmFormProvider);
    if (form.location == null) return;
    ref
        .read(alarmSaveProvider.notifier)
        .save(
          alarmId: widget.alarmId,
          name: _labelController.text,
          location: form.location!,
          radius: form.radius,
        );
  }

  Future<void> _onSaveEvent(AlarmSaveState saveState) async {
    final notifier = ref.read(alarmSaveProvider.notifier);

    switch (saveState) {
      case AlarmSaveIdle() || AlarmSaveBusy():
        break;

      case AlarmSaveNeedsConfirmation(:final step):
        switch (step) {
          case BackgroundLocationRationale():
            final confirmed = await _showBackgroundRationaleDialog();
            await notifier.confirmStep(confirmed);
          case BatteryOptimizationRationale():
            final confirmed = await _showBatteryRationaleDialog();
            await notifier.confirmStep(confirmed);
          case InsideRadiusWarning():
            final confirmed = await _showInsideRadiusDialog();
            await notifier.confirmStep(confirmed);
        }

      case AlarmSaveNeedsThumbnail():
        final form = ref.read(alarmFormProvider);
        if (form.location != null) {
          await _animateCamera(_boundsForCircle(form.location!, form.radius));
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        final thumbnail = await _captureMap();
        await notifier.provideThumbnail(thumbnail);

      case AlarmSaveNotificationDenied():
        _showSnackBar('Notifications disabled — you won\'t hear the alarm');

      case AlarmSaved(:final message):
        ref.read(alarmFormProvider.notifier).markSaved();
        notifier.reset();
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }

      case AlarmSaveFailed(:final message):
        _showSnackBar(message);
        notifier.reset();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showBackgroundRationaleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background location needed'),
        content: const Text(
          'Location Alarm needs to monitor your location in the background '
          'to trigger alarms when you arrive.\n\n'
          'On the next screen, select "Allow all the time".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showBatteryRationaleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable battery optimization'),
        content: const Text(
          'To reliably monitor your location in the background, '
          'Location Alarm needs to be excluded from battery optimization.\n\n'
          'Without this, Android may stop the alarm service to save battery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable optimization'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showInsideRadiusDialog() async {
    final result = await showDialog<bool>(
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
    return result ?? false;
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(alarmFormProvider);
    final saveState = ref.watch(alarmSaveProvider);
    final saving = saveState is AlarmSaveBusy;

    ref.listen(locationProvider, (_, next) {
      next.whenData((_) => _centerOnFirstLocation());
    });

    // Sync loaded alarm data into text controller (one-time on load).
    ref.listen(alarmFormProvider, (prev, next) {
      if (prev?.isLoaded != true && next.isLoaded && next.name.isNotEmpty) {
        _labelController.text = next.name;
      }
    });

    // React to save state changes.
    ref.listen(alarmSaveProvider, (_, next) {
      _onSaveEvent(next);
    });

    if (!form.isLoaded) {
      if (form.loadError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load alarm')),
            );
            context.pop();
          }
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: !form.hasUnsavedChanges && !saving,
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
                onMapReady: () {
                  _mapReady = true;
                  // Center on last known location if we got it before map was ready.
                  if (_lastKnownLocation != null && !_hasCenteredOnLocation) {
                    _mapController.move(_lastKnownLocation!, 13);
                  }
                },
                initialCenter: form.location ?? _lastKnownLocation,
                initialZoom: form.location != null
                    ? 15
                    : _lastKnownLocation != null
                    ? 13
                    : 7,
                initialCameraFit: _initialCameraFit(context),
                onTap: (_, latLng) {
                  ref.read(alarmFormProvider.notifier).setLocation(latLng);
                },
                children: [
                  const CurrentLocationMarker(),
                  if (form.location != null)
                    AlarmMapLayers(
                      location: form.location!,
                      radius: form.radius,
                    ),
                ],
              ),
            ),

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
                ref.read(alarmFormProvider.notifier).setLocation(location);
                _fitCircle();
              },
            ),

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
                radius: form.radius,
                canSave: form.canSave,
                onHeightChanged: (h) {
                  if (h != _sheetHeight) {
                    final wasZero = _sheetHeight == 0;
                    setState(() => _sheetHeight = h);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (form.location != null) {
                        _fitCircle();
                      } else if (wasZero && _hasCenteredOnLocation) {
                        _centerOnGps();
                      }
                    });
                  }
                },
                onRadiusChanged: (r) {
                  ref.read(alarmFormProvider.notifier).setRadius(r);
                  _fitCircle();
                },
                onSave: _save,
                saving: saving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
