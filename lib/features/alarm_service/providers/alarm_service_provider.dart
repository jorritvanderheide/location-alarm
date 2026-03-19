import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/alarm_checker.dart';
import 'package:location_alarm/features/alarm_service/alarm_notification_service.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

final alarmServiceProvider = NotifierProvider<AlarmServiceNotifier, void>(
  AlarmServiceNotifier.new,
);

class AlarmServiceNotifier extends Notifier<void> {
  final _checker = AlarmChecker();

  @override
  void build() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onLocationData);
    ref.onDispose(() {
      FlutterForegroundTask.removeTaskDataCallback(_onLocationData);
    });
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
