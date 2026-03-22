import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/alarm_service/foreground_service_manager.dart';
import 'package:location_alarm/shared/data/alarm_log.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';

final foregroundServiceProvider =
    NotifierProvider<ForegroundServiceNotifier, bool>(
      ForegroundServiceNotifier.new,
    );

class ForegroundServiceNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(alarmsProvider, (_, next) {
      next.whenData(_evaluate);
    });

    ref.listen(backgroundPermissionProvider, (_, _) {
      final alarmsAsync = ref.read(alarmsProvider);
      alarmsAsync.whenData(_evaluate);
    });

    final alarmsAsync = ref.read(alarmsProvider);
    alarmsAsync.whenData((alarms) {
      Future.microtask(() => _evaluate(alarms));
    }); // ignore: unnecessary_lambdas

    return false;
  }

  Future<void> _evaluate(List<AlarmData> alarms) async {
    final hasActive = alarms.any((a) => a.active);
    final bgPerm = ref.read(backgroundPermissionProvider);

    // Don't stop the service while permission status is still being checked
    // (null = not yet queried). Only act on definite true/false.
    if (bgPerm == null) return;

    final shouldRun = hasActive && bgPerm;

    // Self-healing: if service should be running but was killed by the OS,
    // restart it.
    if (shouldRun) {
      final actuallyRunning = await ForegroundServiceManager.isRunning();
      if (!actuallyRunning) {
        await AlarmLog.write(
          'Service self-heal: should be running but was killed, restarting',
        );
        await ForegroundServiceManager.start();
        state = true;
        return;
      }
    }

    await _updateService(shouldRun);
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
