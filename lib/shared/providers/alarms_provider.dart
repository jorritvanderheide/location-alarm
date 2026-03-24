import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:there_yet/shared/data/models/alarm.dart';
import 'package:there_yet/shared/providers/alarm_repository_provider.dart';

final alarmsProvider = StreamProvider<List<AlarmData>>((ref) {
  return ref.watch(alarmRepositoryProvider).watchAll();
});
