import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:there_yet/features/alarm_service/foreground_service_manager.dart';
import 'package:there_yet/features/alarm_service/proximity_alert_service.dart';
import 'package:there_yet/shared/data/models/alarm.dart';
import 'package:there_yet/shared/providers/alarms_provider.dart';
import 'package:there_yet/shared/providers/location_permission_provider.dart';

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
    });

    return false;
  }

  bool _evaluating = false;

  Future<void> _evaluate(List<AlarmData> alarms) async {
    if (_evaluating) return;
    _evaluating = true;
    try {
      await _doEvaluate(alarms);
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _doEvaluate(List<AlarmData> alarms) async {
    final activeAlarms = alarms.where((a) => a.active).toList();
    final hasActive = activeAlarms.isNotEmpty;
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
        await ForegroundServiceManager.start();
        await ProximityAlertService.syncAll(activeAlarms);
        state = true;
        return;
      }
    }

    await _updateService(shouldRun, activeAlarms);
  }

  Future<void> _updateService(
    bool shouldRun,
    List<AlarmData> activeAlarms,
  ) async {
    if (shouldRun && !state) {
      await ForegroundServiceManager.start();
      await ProximityAlertService.syncAll(activeAlarms);
      state = true;
    } else if (shouldRun && state) {
      // Service already running. Sync proximity alerts in case
      // alarms were added/removed/edited.
      await ProximityAlertService.syncAll(activeAlarms);
    } else if (!shouldRun) {
      await ProximityAlertService.unregisterAll();
      await ForegroundServiceManager.stop();
      state = false;
    }
  }
}
