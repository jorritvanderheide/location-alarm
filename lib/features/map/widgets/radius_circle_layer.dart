import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/map/providers/alarm_mode_provider.dart';
import 'package:location_alarm/features/map/providers/alarm_pin_provider.dart';
import 'package:location_alarm/features/proximity_alarm/providers/proximity_alarm_form_provider.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';

class RadiusCircleLayer extends ConsumerWidget {
  const RadiusCircleLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinLocation = ref.watch(alarmPinProvider);
    final mode = ref.watch(alarmModeProvider);
    final radius = ref.watch(proximityRadiusProvider);

    if (pinLocation == null || mode != AlarmMode.proximity) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return CircleLayer(
      circles: [
        CircleMarker(
          point: pinLocation,
          radius: radius,
          useRadiusInMeter: true,
          color: colorScheme.primary.withValues(alpha: 0.15),
          borderColor: colorScheme.primary.withValues(alpha: 0.6),
          borderStrokeWidth: 2,
        ),
      ],
    );
  }
}
