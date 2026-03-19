import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

const _distanceCalc = Distance();

const _speeds = {
  TravelMode.walk: 83.3,
  TravelMode.cycle: 250.0,
  TravelMode.drive: 833.3,
};

class SavedAlarmsList extends ConsumerWidget {
  const SavedAlarmsList({super.key, this.mapController});

  final MapController? mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final locationAsync = ref.watch(locationProvider);

    return alarmsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (alarms) {
        if (alarms.isEmpty) return const SizedBox.shrink();

        final currentPosition = locationAsync.whenData((p) => p).value;

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
                currentPosition: currentPosition != null
                    ? LatLng(
                        currentPosition.latitude,
                        currentPosition.longitude,
                      )
                    : null,
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
    this.currentPosition,
  });

  final AlarmData alarm;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final LatLng? currentPosition;

  @override
  Widget build(BuildContext context) {
    final (icon, subtitle) = switch (alarm) {
      ProximityAlarmData(:final radius) => (
        Icons.notifications,
        '${radius.round()} m radius',
      ),
      DepartureAlarmData(
        :final travelMode,
        :final bufferMinutes,
        :final arrivalTime,
      ) =>
        (
          Icons.directions_walk,
          _departureSubtitle(travelMode, bufferMinutes, arrivalTime),
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

  String _departureSubtitle(
    TravelMode travelMode,
    int bufferMinutes,
    DateTime arrivalTime,
  ) {
    final arriveBy =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';

    if (currentPosition == null) {
      return 'Arrive by $arriveBy · ${travelMode.name} · +$bufferMinutes min';
    }

    final distance = _distanceCalc.as(
      LengthUnit.Meter,
      currentPosition!,
      alarm.location,
    );
    final speed = _speeds[travelMode] ?? _speeds[TravelMode.walk]!;
    final travelMinutes = distance / speed;
    final totalMinutes = travelMinutes + bufferMinutes;
    final departureTime = arrivalTime.subtract(
      Duration(minutes: totalMinutes.ceil()),
    );
    final leaveAt =
        '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';

    return 'Leave at $leaveAt · arrive by $arriveBy';
  }
}
