import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location_alarm/features/alarm_service/foreground_task_handler.dart';

class ForegroundServiceManager {
  ForegroundServiceManager._();

  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'monitoring_channel',
        channelName: 'Monitoring',
        channelDescription: 'Background location monitoring',
        channelImportance: NotificationChannelImportance.MIN,
        priority: NotificationPriority.MIN,
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(), // required param
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> start() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (running) return;

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Location Alarm',
      notificationText: 'Monitoring active alarms',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (!running) return;

    await FlutterForegroundTask.stopService();
  }
}
