import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

final alarmServiceProvider = NotifierProvider<AlarmServiceNotifier, AlarmData?>(
  AlarmServiceNotifier.new,
);

/// Relays alarm-fire events from the background isolate to the UI.
///
/// State is the currently ringing [AlarmData], or `null` when idle.
class AlarmServiceNotifier extends Notifier<AlarmData?> {
  @override
  AlarmData? build() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    ref.onDispose(() {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    });

    return null;
  }

  Future<void> _onTaskData(Object data) async {
    if (data is! String) return;

    final json = jsonDecode(data) as Map<String, dynamic>;
    final type = json['type'] as String?;

    if (type == 'alarm_fired') {
      final id = json['id'] as int;
      debugPrint('ALARM: received alarm_fired for $id in main isolate');

      // Look up the alarm data for the UI
      final alarms = ref.read(alarmsProvider).whenData((a) => a).value;
      final alarm = alarms?.where((a) => a.id == id).firstOrNull;
      if (alarm != null) {
        state = alarm;
      }
    }
  }

  /// Dismiss the currently ringing alarm by sending a command to the
  /// background isolate.
  void dismiss(int alarmId) {
    debugPrint('ALARM: sending dismiss for $alarmId to background');
    FlutterForegroundTask.sendDataToTask(
      jsonEncode({'type': 'dismiss', 'id': alarmId}),
    );
    state = null;
  }
}
