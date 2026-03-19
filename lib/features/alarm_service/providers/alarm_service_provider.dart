import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/alarm_checker.dart';
import 'package:location_alarm/features/alarm_service/alarm_notification_service.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

final alarmServiceProvider = NotifierProvider<AlarmServiceNotifier, void>(
  AlarmServiceNotifier.new,
);

class AlarmServiceNotifier extends Notifier<void> {
  final _checker = AlarmChecker();
  final Set<int> _ringingIds = {};

  @override
  void build() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onLocationData);

    Alarm.ringing.listen(_onRingingChanged);

    ref.onDispose(() {
      FlutterForegroundTask.removeTaskDataCallback(_onLocationData);
    });
  }

  void _onRingingChanged(AlarmSet alarmSet) {
    final currentIds = alarmSet.alarms.map((a) => a.id).toSet();
    final stoppedIds = _ringingIds.difference(currentIds);

    for (final id in stoppedIds) {
      ref.read(alarmRepositoryProvider).toggleActive(id, active: false);
    }

    _ringingIds
      ..clear()
      ..addAll(currentIds);
  }

  void _onLocationData(Object data) {
    if (data is! String) return;

    final json = jsonDecode(data) as Map<String, dynamic>;
    final lat = json['lat'] as double;
    final lng = json['lng'] as double;
    final position = LatLng(lat, lng);

    final alarmsAsync = ref.read(alarmsProvider);
    alarmsAsync.whenData((alarms) {
      final activeAlarms = alarms.where((a) => a.active).toList();
      final triggered = _checker.check(activeAlarms, position);

      for (final alarm in triggered) {
        AlarmNotificationService.fireAlarm(alarm);
      }
    });
  }
}
