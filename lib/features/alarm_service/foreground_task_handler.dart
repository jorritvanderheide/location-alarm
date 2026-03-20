import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/alarm_checker.dart';
import 'package:location_alarm/features/alarm_service/background_alarm_player.dart';
import 'package:location_alarm/shared/data/database/app_database.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/repositories/alarm_repository.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;

  late AppDatabase _db;
  late AlarmRepository _repo;
  final _checker = AlarmChecker();
  final _player = BackgroundAlarmPlayer();
  final Set<int> _firedIds = {};
  LatLng? _lastPosition;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _db = openDatabase();
    _repo = AlarmRepository(_db);
    await _player.init();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true,
      ),
    ).listen(_onPosition);
  }

  Future<void> _onPosition(Position position) async {
    final latLng = LatLng(position.latitude, position.longitude);
    _lastPosition = latLng;

    // Send position to main isolate for UI
    FlutterForegroundTask.sendDataToMain(
      jsonEncode({
        'type': 'position',
        'lat': latLng.latitude,
        'lng': latLng.longitude,
      }),
    );

    await _checkAlarms(latLng);
  }

  Future<void> _checkAlarms(LatLng position) async {
    final activeAlarms = await _repo.getActive();

    // Clear firedIds for alarms that are no longer active
    final activeIds = activeAlarms.map((a) => a.id!).toSet();
    _firedIds.retainAll(activeIds);

    final checkable = activeAlarms
        .where((a) => !_firedIds.contains(a.id))
        .toList();
    final triggered = _checker.check(checkable, position);

    for (final alarm in triggered) {
      _firedIds.add(alarm.id!);
      debugPrint('ALARM: firing alarm ${alarm.id} from background');
      await _player.fire(alarm);

      // Notify main isolate for UI (AlarmRingScreen)
      FlutterForegroundTask.sendDataToMain(
        jsonEncode({'type': 'alarm_fired', 'id': alarm.id}),
      );
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Safety-net heartbeat: re-check with last known position
    final position = _lastPosition;
    if (position != null) {
      _checkAlarms(position);
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is! String) return;

    final json = jsonDecode(data) as Map<String, dynamic>;
    final type = json['type'] as String?;

    if (type == 'dismiss') {
      final id = json['id'] as int;
      debugPrint('ALARM: dismiss received for alarm $id');
      _player.stop();
      _firedIds.remove(id);
      _repo.toggleActive(id, active: false);
    } else if (type == 'refresh') {
      // Main isolate changed alarm state — re-check on next position update
      final position = _lastPosition;
      if (position != null) {
        _checkAlarms(position);
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSub?.cancel();
    await _player.stop();
    await _player.dispose();
    await _db.close();
  }
}
