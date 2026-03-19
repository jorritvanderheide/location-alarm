import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/departure_alarm/providers/buffer_minutes_provider.dart';
import 'package:location_alarm/features/departure_alarm/providers/departure_alarm_form_provider.dart';
import 'package:location_alarm/features/map/providers/alarm_mode_provider.dart';
import 'package:location_alarm/features/map/providers/alarm_pin_provider.dart';
import 'package:location_alarm/features/proximity_alarm/providers/proximity_alarm_form_provider.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';

final saveAlarmProvider = NotifierProvider<SaveAlarmNotifier, AsyncValue<void>>(
  SaveAlarmNotifier.new,
);

class SaveAlarmNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save() async {
    final pin = ref.read(alarmPinProvider);
    if (pin == null) return false;

    final mode = ref.read(alarmModeProvider);
    final repo = ref.read(alarmRepositoryProvider);

    state = const AsyncLoading();

    try {
      final alarm = switch (mode) {
        AlarmMode.proximity => ProximityAlarmData(
          name: '',
          location: pin,
          active: true,
          radius: ref.read(proximityRadiusProvider),
        ),
        AlarmMode.departure => DepartureAlarmData(
          name: '',
          location: pin,
          active: true,
          travelMode: ref.read(travelModeProvider),
          bufferMinutes: ref.read(bufferMinutesProvider),
        ),
      };

      await repo.save(alarm);
      ref.read(alarmPinProvider.notifier).clear();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
