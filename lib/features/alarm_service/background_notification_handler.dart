import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location_alarm/features/alarm_service/background_alarm_player.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/repositories/alarm_repository.dart';

/// Top-level callback for notification actions received when the main isolate
/// is dead. Runs in a temporary background isolate spawned by the notification
/// plugin.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  if (response.actionId != dismissActionId) return;

  final alarmId = int.tryParse(response.payload ?? '');
  if (alarmId == null) return;

  debugPrint('ALARM: background dismiss for alarm $alarmId');

  // Open a temporary DB connection, deactivate the alarm, then close.
  final db = openDatabase();
  final repo = AlarmRepository(db);
  repo.toggleActive(alarmId, active: false).then((_) => db.close());
}
