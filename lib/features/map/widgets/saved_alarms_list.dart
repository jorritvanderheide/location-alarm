import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

class SavedAlarmsList extends ConsumerWidget {
  const SavedAlarmsList({super.key, this.mapController});

  final MapController? mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);

    return alarmsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (alarms) {
        if (alarms.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            Text('Saved alarms', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...alarms.map(
              (alarm) => _AlarmTile(
                alarm: alarm,
                onTap: () {
                  mapController?.move(alarm.location, 15);
                },
                onDelete: () {
                  ref.read(deleteAlarmProvider)(alarm.id!);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.onTap,
    required this.onDelete,
  });

  final AlarmData alarm;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (icon, subtitle) = switch (alarm) {
      ProximityAlarmData(:final radius) => (
        Icons.notifications,
        '${radius.round()} m radius',
      ),
      DepartureAlarmData(:final travelMode, :final bufferMinutes) => (
        Icons.directions_walk,
        '${travelMode.name} · $bufferMinutes min buffer',
      ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon),
      title: Text(
        alarm.name.isEmpty
            ? switch (alarm) {
                ProximityAlarmData() => 'Proximity alarm',
                DepartureAlarmData() => 'Departure alarm',
              }
            : alarm.name,
      ),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
