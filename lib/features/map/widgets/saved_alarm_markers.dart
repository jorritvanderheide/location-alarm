import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

class SavedAlarmMarkers extends ConsumerWidget {
  const SavedAlarmMarkers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);

    return alarmsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (alarms) {
        if (alarms.isEmpty) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;

        return Stack(
          children: [
            CircleLayer(
              circles: [
                for (final alarm in alarms)
                  if (alarm is ProximityAlarmData)
                    CircleMarker(
                      point: alarm.location,
                      radius: alarm.radius,
                      useRadiusInMeter: true,
                      color: colorScheme.tertiary.withValues(alpha: 0.1),
                      borderColor: colorScheme.tertiary.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                    ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final alarm in alarms)
                  Marker(
                    point: alarm.location,
                    width: 24,
                    height: 24,
                    child: Icon(
                      switch (alarm) {
                        ProximityAlarmData() => Icons.notifications,
                        DepartureAlarmData() => Icons.directions_walk,
                      },
                      size: 24,
                      color: alarm.active
                          ? colorScheme.tertiary
                          : colorScheme.tertiary.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
