import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/proximity_alarm/providers/proximity_alarm_form_provider.dart';

class ProximityAlarmForm extends ConsumerWidget {
  const ProximityAlarmForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(proximityRadiusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Radius: ${radius.round()} m',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: radius,
          min: 100,
          max: 5000,
          divisions: 49,
          label: '${radius.round()} m',
          onChanged: (value) {
            ref.read(proximityRadiusProvider.notifier).set(value);
          },
        ),
      ],
    );
  }
}
