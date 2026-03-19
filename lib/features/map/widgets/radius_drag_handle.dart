import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/map/providers/alarm_mode_provider.dart';
import 'package:location_alarm/features/map/providers/alarm_pin_provider.dart';
import 'package:location_alarm/features/proximity_alarm/providers/proximity_alarm_form_provider.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';

const _handleVisualSize = 14.0;
const _handleTouchSize = 44.0;
const _distanceCalc = Distance();

class RadiusDragHandle extends ConsumerWidget {
  const RadiusDragHandle({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinLocation = ref.watch(alarmPinProvider);
    final mode = ref.watch(alarmModeProvider);
    final radius = ref.watch(proximityRadiusProvider);

    if (pinLocation == null || mode != AlarmMode.proximity) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, _) {
        final handleLatLng = _distanceCalc.offset(pinLocation, radius, 90);
        final screenOffset = mapController.camera.latLngToScreenOffset(
          handleLatLng,
        );

        final colorScheme = Theme.of(context).colorScheme;

        return Positioned(
          left: screenOffset.dx - _handleTouchSize / 2,
          top: screenOffset.dy - _handleTouchSize / 2,
          width: _handleTouchSize,
          height: _handleTouchSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              final currentOffset = mapController.camera.latLngToScreenOffset(
                handleLatLng,
              );
              final newOffset =
                  currentOffset + Offset(details.delta.dx, details.delta.dy);
              final newLatLng = mapController.camera.screenOffsetToLatLng(
                newOffset,
              );
              final newRadius = _distanceCalc.as(
                LengthUnit.Meter,
                pinLocation,
                newLatLng,
              );
              ref.read(proximityRadiusProvider.notifier).set(newRadius);
            },
            child: Center(
              child: Container(
                width: _handleVisualSize,
                height: _handleVisualSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
