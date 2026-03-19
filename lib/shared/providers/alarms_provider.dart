import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';

final alarmsProvider = StreamProvider<List<AlarmData>>((ref) {
  return ref.watch(alarmRepositoryProvider).watchAll();
});

final deleteAlarmProvider = Provider<Future<void> Function(int)>((ref) {
  return (int id) => ref.read(alarmRepositoryProvider).delete(id);
});
