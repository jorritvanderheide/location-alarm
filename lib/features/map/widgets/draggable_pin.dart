import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/map/providers/alarm_mode_provider.dart';
import 'package:location_alarm/features/map/providers/alarm_pin_provider.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';

class DraggablePin extends ConsumerWidget {
  const DraggablePin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinLocation = ref.watch(alarmPinProvider);
    final mode = ref.watch(alarmModeProvider);
    if (pinLocation == null) return const SizedBox.shrink();

    final isProximity = mode == AlarmMode.proximity;
    final size = isProximity ? 32.0 : 20.0;

    return MarkerLayer(
      markers: [
        Marker(
          point: pinLocation,
          width: size,
          height: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              final camera = MapCamera.of(context);
              final currentOffset = camera.latLngToScreenOffset(pinLocation);
              final newOffset =
                  currentOffset + Offset(details.delta.dx, details.delta.dy);
              final newLatLng = camera.screenOffsetToLatLng(newOffset);
              ref.read(alarmPinProvider.notifier).place(newLatLng);
            },
            onLongPress: () {
              ref.read(alarmPinProvider.notifier).clear();
            },
            child: isProximity
                ? Icon(
                    Icons.notifications,
                    size: size,
                    color: Theme.of(context).colorScheme.primary,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
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
      ],
    );
  }
}
