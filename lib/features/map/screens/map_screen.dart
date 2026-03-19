import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/map/providers/alarm_pin_provider.dart';
import 'package:location_alarm/features/map/widgets/alarm_bottom_sheet.dart';
import 'package:location_alarm/features/map/widgets/alarm_map.dart';
import 'package:location_alarm/features/map/widgets/center_on_location_fab.dart';
import 'package:location_alarm/features/map/widgets/compass_button.dart';
import 'package:location_alarm/features/map/widgets/current_location_marker.dart';
import 'package:location_alarm/features/map/widgets/draggable_pin.dart';
import 'package:location_alarm/features/map/widgets/osm_attribution.dart';
import 'package:location_alarm/features/map/widgets/permission_banner.dart';
import 'package:location_alarm/features/map/widgets/radius_circle_layer.dart';
import 'package:location_alarm/features/map/widgets/radius_drag_handle.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  bool _hasCenteredOnLocation = false;
  double _sheetHeight = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationPermissionProvider.notifier).request();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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

    final fabBottom = _sheetHeight + 16;

    return Scaffold(
      body: Stack(
        children: [
          AlarmMap(
            mapController: _mapController,
            onTap: (_, latLng) {
              ref.read(alarmPinProvider.notifier).place(latLng);
            },
            children: const [
              RadiusCircleLayer(),
              CurrentLocationMarker(),
              DraggablePin(),
            ],
          ),
          RadiusDragHandle(mapController: _mapController),
          OsmAttribution(bottomOffset: _sheetHeight),
          AlarmBottomSheet(
            onSheetHeightChanged: (height) {
              setState(() => _sheetHeight = height);
            },
          ),
          const PermissionBanner(),
          Positioned(
            right: 16,
            bottom: fabBottom + 56,
            child: CompassButton(mapController: _mapController),
          ),
          Positioned(
            right: 16,
            bottom: fabBottom,
            child: CenterOnLocationFab(mapController: _mapController),
          ),
        ],
      ),
    );
  }
}
