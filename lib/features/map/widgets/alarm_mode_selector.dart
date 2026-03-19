import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/map/providers/alarm_mode_provider.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';

class AlarmModeSelector extends ConsumerWidget {
  const AlarmModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(alarmModeProvider);

    return SegmentedButton<AlarmMode>(
      segments: const [
        ButtonSegment(
          value: AlarmMode.proximity,
          label: Text('Proximity'),
          icon: Icon(Icons.location_on),
        ),
        ButtonSegment(
          value: AlarmMode.departure,
          label: Text('Departure'),
          icon: Icon(Icons.directions_walk),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) {
        ref.read(alarmModeProvider.notifier).set(selection.first);
      },
    );
  }
}
