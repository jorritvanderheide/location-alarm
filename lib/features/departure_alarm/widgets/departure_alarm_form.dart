import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/departure_alarm/providers/arrival_time_provider.dart';
import 'package:location_alarm/features/departure_alarm/providers/buffer_minutes_provider.dart';
import 'package:location_alarm/features/departure_alarm/providers/departure_alarm_form_provider.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

class DepartureAlarmForm extends ConsumerWidget {
  const DepartureAlarmForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelMode = ref.watch(travelModeProvider);
    final bufferMinutes = ref.watch(bufferMinutesProvider);
    final arrivalTime = ref.watch(arrivalTimeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Arrive by', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: arrivalTime ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: arrivalTime != null
                        ? TimeOfDay.fromDateTime(arrivalTime)
                        : TimeOfDay.fromDateTime(
                            now.add(const Duration(hours: 1)),
                          ),
                  );
                  if (time == null) return;
                  ref
                      .read(arrivalTimeProvider.notifier)
                      .set(
                        DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                },
                icon: const Icon(Icons.schedule),
                label: Text(
                  arrivalTime != null
                      ? _formatDateTime(arrivalTime)
                      : 'Set arrival time',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final today = DateTime.now();
    final isToday =
        dt.year == today.year && dt.month == today.month && dt.day == today.day;
    if (isToday) return 'Today $hour:$minute';
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow =
        dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
    if (isTomorrow) return 'Tomorrow $hour:$minute';
    return '${dt.day}/${dt.month} $hour:$minute';
  }
}
