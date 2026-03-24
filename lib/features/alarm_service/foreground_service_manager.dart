import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:there_yet/features/alarm_service/foreground_task_handler.dart';

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
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000), // 30 seconds
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
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
      notificationTitle: 'Monitoring your alarms',
      notificationText: 'You\'ll be notified when you arrive',
      callback: startCallback,
    );
  }

  static Future<bool> isRunning() async {
    return FlutterForegroundTask.isRunningService;
  }

  static Future<void> stop() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (!running) return;

    await FlutterForegroundTask.stopService();
  }
}
