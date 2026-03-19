import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';

final alarmModeProvider = NotifierProvider<AlarmModeNotifier, AlarmMode>(
  AlarmModeNotifier.new,
);

class AlarmModeNotifier extends Notifier<AlarmMode> {
  @override
  AlarmMode build() => AlarmMode.proximity;

  void set(AlarmMode mode) => state = mode;
}
