import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/providers/preferences_provider.dart';

const usePlayServicesKey = 'use_play_services';
const triggerInsideRadiusKey = 'trigger_inside_radius';

final usePlayServicesProvider = NotifierProvider<UsePlayServicesNotifier, bool>(
  UsePlayServicesNotifier.new,
);

class UsePlayServicesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(preferencesProvider);
    return prefs.getBool(usePlayServicesKey) ?? false;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs.setBool(usePlayServicesKey, enabled);
  }
}

final triggerInsideRadiusProvider =
    NotifierProvider<TriggerInsideRadiusNotifier, bool>(
      TriggerInsideRadiusNotifier.new,
    );

class TriggerInsideRadiusNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(preferencesProvider);
    return prefs.getBool(triggerInsideRadiusKey) ?? false;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs.setBool(triggerInsideRadiusKey, enabled);
  }
}
