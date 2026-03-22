import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/providers/preferences_provider.dart';

const triggerInsideRadiusKey = 'trigger_inside_radius';

final triggerInsideRadiusProvider =
    NotifierProvider<TriggerInsideRadiusNotifier, bool>(
      TriggerInsideRadiusNotifier.new,
    );

class TriggerInsideRadiusNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (!kDebugMode) return false;
    final prefs = ref.read(preferencesProvider);
    return prefs.getBool(triggerInsideRadiusKey) ?? false;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs.setBool(triggerInsideRadiusKey, enabled);
  }
}
