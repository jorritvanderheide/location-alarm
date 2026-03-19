import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/departure_alarm/providers/buffer_minutes_provider.dart';
import 'package:location_alarm/features/departure_alarm/providers/departure_alarm_form_provider.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

class DepartureAlarmForm extends ConsumerWidget {
  const DepartureAlarmForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelMode = ref.watch(travelModeProvider);
    final bufferMinutes = ref.watch(bufferMinutesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Travel mode', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<TravelMode>(
          segments: const [
            ButtonSegment(
              value: TravelMode.walk,
              label: Text('Walk'),
              icon: Icon(Icons.directions_walk),
            ),
            ButtonSegment(
              value: TravelMode.cycle,
              label: Text('Cycle'),
              icon: Icon(Icons.directions_bike),
            ),
            ButtonSegment(
              value: TravelMode.drive,
              label: Text('Drive'),
              icon: Icon(Icons.directions_car),
            ),
          ],
          selected: {travelMode},
          onSelectionChanged: (selection) {
            ref.read(travelModeProvider.notifier).set(selection.first);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Buffer: $bufferMinutes min',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: bufferMinutes.toDouble(),
          min: 0,
          max: 60,
          divisions: 12,
          label: '$bufferMinutes min',
          onChanged: (value) {
            ref.read(bufferMinutesProvider.notifier).set(value.round());
          },
        ),
      ],
    );
  }
}
