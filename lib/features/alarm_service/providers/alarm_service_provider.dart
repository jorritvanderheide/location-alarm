import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/alarm_checker.dart';
import 'package:location_alarm/features/alarm_service/alarm_player.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

final alarmServiceProvider = NotifierProvider<AlarmServiceNotifier, void>(
  AlarmServiceNotifier.new,
);

class AlarmServiceNotifier extends Notifier<void> {
  final _checker = AlarmChecker();
  final Set<int> _firedIds = {};

  @override
  void build() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onLocationData);

    // Clear _firedIds when alarms are deactivated
    ref.listen(alarmsProvider, (_, next) {
      next.whenData((alarms) {
        final activeIds = alarms
            .where((a) => a.active)
            .map((a) => a.id!)
            .toSet();
        _firedIds.retainAll(activeIds);
      });
    });

    ref.onDispose(() {
      FlutterForegroundTask.removeTaskDataCallback(_onLocationData);
    });
  }

  Future<void> _onLocationData(Object data) async {
    if (data is! String) return;

    final json = jsonDecode(data) as Map<String, dynamic>;
    final lat = json['lat'] as double;
    final lng = json['lng'] as double;
    final position = LatLng(lat, lng);

    final List<AlarmData>? alarms = ref
        .read(alarmsProvider)
        .whenData((a) => a)
        .value;
    if (alarms == null) return;

    final activeAlarms = alarms.where((a) => a.active).toList();

    // Check alarms that haven't been fired yet
    final checkable = activeAlarms
        .where((a) => !_firedIds.contains(a.id))
        .toList();
    final triggered = _checker.check(checkable, position);

    for (final alarm in triggered) {
      _firedIds.add(alarm.id!);
      debugPrint('ALARM: firing alarm ${alarm.id}');
      await AlarmPlayer.fire(alarm);
    }
  }
}
