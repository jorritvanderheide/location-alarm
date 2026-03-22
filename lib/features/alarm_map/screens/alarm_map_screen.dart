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
    _labelController.addListener(_syncNameToProvider);
    Future.microtask(() {
      // Invalidate to get a fresh form state — the family key (null for new
      // alarms) is reused across screens, so stale state persists otherwise.
      ref.invalidate(alarmFormProvider(widget.alarmId));
      ref.invalidate(alarmSaveProvider);
      _labelController.clear();
      ref.read(locationPermissionProvider.notifier).request();
      _loadLastKnownLocation();
    });
  }

  @override
  void dispose() {
    _cameraAnimController?.dispose();
    _labelController.removeListener(_syncNameToProvider);
    _labelController.dispose();
    _labelFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _syncNameToProvider() {
    ref
        .read(alarmFormProvider(widget.alarmId).notifier)
        .setName(_labelController.text);
  }

  // -- Map helpers --

  EdgeInsets _mapPadding(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;
    return EdgeInsets.fromLTRB(48, 80 + viewPadding.top, 48, _sheetHeight + 16);
  }

  Future<void> _loadLastKnownLocation() async {
    final form = ref.read(alarmFormProvider(widget.alarmId));
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
    final form = ref.read(alarmFormProvider(widget.alarmId));
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

  void _fitCircle({bool animate = true}) {
    if (!_mapReady) return;
    final form = ref.read(alarmFormProvider(widget.alarmId));
    if (form.location == null) return;
    final target = _boundsForCircle(
      form.location!,
      form.radius,
      padding: _mapPadding(context),
    );
    if (animate) {
      _animateCamera(target);
    } else {
      _mapController.fitCamera(target);
    }
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
        _animateCamera(
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
    // When editing, the alarm's location is already set via initialCameraFit.
    // Don't override it with the GPS position.
    final form = ref.read(alarmFormProvider(widget.alarmId));
    if (form.location != null) {
      _hasCenteredOnLocation = true;
      return;
    }
    final locationAsync = ref.read(locationProvider);
    locationAsync.whenData((_) {
      _hasCenteredOnLocation = true;
      _centerOnGps();
    });
  }

  AnimationController? _cameraAnimController;

  Future<void> _animateCamera(
    CameraFit target, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    if (!_mapReady) return Future.value();

    // Cancel any in-progress animation.
    _cameraAnimController?.stop();
    _cameraAnimController?.dispose();

    final dest = target.fit(_mapController.camera);
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final endCenter = dest.center;
    final endZoom = dest.zoom;

    final controller = AnimationController(vsync: this, duration: duration);
    _cameraAnimController = controller;
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
        if (_cameraAnimController == controller) {
          _cameraAnimController = null;
        }
        controller.dispose();
        if (!completer.isCompleted) completer.complete();
      }
    });

    controller.forward();
    return completer.future;
  }

  /// Captures the map and crops symmetrically around the alarm pin so it
  /// appears centered in the resulting thumbnail.
  Future<Uint8List?> _captureAndCropMap() async {
    try {
      final boundary =
          _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final viewPadding = MediaQuery.of(context).viewPadding;
      const pixelRatio = 1.5;
      final fullImage = await boundary.toImage(pixelRatio: pixelRatio);

      // The map padding positions the pin in the visual center between the
      // search bar (top) and the sheet (bottom). Crop both top and bottom
      // by the larger of the two paddings so the pin is centered.
      final topPad = ((80 + viewPadding.top) * pixelRatio).round();
      final bottomPad = ((_sheetHeight + 16) * pixelRatio).round();
      final cropEach = topPad > bottomPad ? topPad : bottomPad;

      final cropTop = cropEach;
      final cropHeight = fullImage.height - cropEach - cropEach;
      if (cropHeight <= 0) {
        fullImage.dispose();
        return null;
      }

      final srcWidth = fullImage.width.toDouble();
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        fullImage,
        Rect.fromLTWH(0, cropTop.toDouble(), srcWidth, cropHeight.toDouble()),
        Rect.fromLTWH(0, 0, srcWidth, cropHeight.toDouble()),
        Paint(),
      );
      fullImage.dispose();

      final croppedPicture = recorder.endRecording();
      final croppedImage = await croppedPicture.toImage(
        srcWidth.round(),
        cropHeight,
      );
      croppedPicture.dispose();

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      croppedImage.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // -- Save --

  void _save() {
    final form = ref.read(alarmFormProvider(widget.alarmId));
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
        final form = ref.read(alarmFormProvider(widget.alarmId));
        if (form.location != null) {
          // Use the same offset padding as the normal view so the camera
          // doesn't jump. We'll crop the bottom to center the dot.
          await _animateCamera(
            _boundsForCircle(
              form.location!,
              form.radius,
              padding: _mapPadding(context),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        final thumbnail = await _captureAndCropMap();
        await notifier.provideThumbnail(thumbnail);

      case AlarmSaveNotificationDenied():
        _showSnackBar('Notifications disabled — you won\'t hear the alarm');

      case AlarmSaved(:final message):
        ref.read(alarmFormProvider(widget.alarmId).notifier).markSaved();
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
    final form = ref.watch(alarmFormProvider(widget.alarmId));
    final saveState = ref.watch(alarmSaveProvider);
    final saving = saveState is AlarmSaveBusy;

    ref.listen(locationProvider, (_, next) {
      next.whenData((_) => _centerOnFirstLocation());
    });

    // Sync loaded alarm data into UI (one-time on load).
    ref.listen(alarmFormProvider(widget.alarmId), (prev, next) {
      if (prev?.isLoaded != true && next.isLoaded) {
        if (next.name.isNotEmpty) _labelController.text = next.name;
        // Center on the alarm's location once loaded (edit mode).
        if (next.location != null && _mapReady) {
          _hasCenteredOnLocation = true;
          _fitCircle();
        }
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
                    _animateCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds(
                          LatLng(
                            _lastKnownLocation!.latitude - 0.005,
                            _lastKnownLocation!.longitude - 0.005,
                          ),
                          LatLng(
                            _lastKnownLocation!.latitude + 0.005,
                            _lastKnownLocation!.longitude + 0.005,
                          ),
                        ),
                        padding: _mapPadding(context),
                        maxZoom: 13,
                      ),
                    );
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
                  ref
                      .read(alarmFormProvider(widget.alarmId).notifier)
                      .setLocation(latLng);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fitCircle();
                  });
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
                ref
                    .read(alarmFormProvider(widget.alarmId).notifier)
                    .setLocation(location);
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
                showRadius: form.location != null,
                onHeightChanged: (h) {
                  if (h != _sheetHeight) {
                    final wasZero = _sheetHeight == 0;
                    setState(() => _sheetHeight = h);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (form.location != null) {
                        _fitCircle(animate: false);
                      } else if (wasZero && _hasCenteredOnLocation) {
                        _centerOnGps();
                      }
                    });
                  }
                },
                onRadiusChanged: (r) {
                  ref
                      .read(alarmFormProvider(widget.alarmId).notifier)
                      .setRadius(r);
                  _fitCircle(animate: false);
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
