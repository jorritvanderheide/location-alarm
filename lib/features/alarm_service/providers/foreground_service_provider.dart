import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/alarm_service/foreground_service_manager.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

final foregroundServiceProvider =
    NotifierProvider<ForegroundServiceNotifier, bool>(
      ForegroundServiceNotifier.new,
    );

class ForegroundServiceNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(alarmsProvider, (_, next) {
      next.whenData((alarms) {
        final hasActive = alarms.any((a) => a.active);
        _updateService(hasActive);
      });
    });

    final alarmsAsync = ref.read(alarmsProvider);
    alarmsAsync.whenData((alarms) {
      final hasActive = alarms.any((a) => a.active);
      if (hasActive) {
        Future.microtask(() => _updateService(true));
      }
    });

    return false;
  }

  Future<void> _updateService(bool shouldRun) async {
    if (shouldRun && !state) {
      await ForegroundServiceManager.start();
      state = true;
    } else if (!shouldRun && state) {
      await ForegroundServiceManager.stop();
      state = false;
    }
  }
}
