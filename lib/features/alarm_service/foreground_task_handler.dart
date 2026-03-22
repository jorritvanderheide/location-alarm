import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/alarm_checker.dart';
import 'package:location_alarm/features/alarm_service/background_alarm_player.dart';
import 'package:location_alarm/shared/data/alarm_log.dart';
import 'package:location_alarm/shared/data/database/app_database.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/repositories/alarm_repository.dart';

@pragma('vm:entry-point')
void startCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;

  AppDatabase? _db;
  AlarmRepository? _repo;
  final _checker = AlarmChecker();
  final _player = BackgroundAlarmPlayer();
  final Set<int> _firedIds = {};
  bool _ready = false;

  // Position tracking — deduplicate checks.
  LatLng? _lastPosition;
  DateTime? _lastCheckTime;
  double _lastAccuracy = 0;

  // Speed tracking — adaptive polling.
  LatLng? _previousPosition;
  DateTime? _previousPositionTime;
  double _speedMps = 0; // meters per second

  // Adaptive poll timer.
  Timer? _adaptivePollTimer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await AlarmLog.write('Service started (starter: ${starter.name})');
    try {
      _db = openDatabase();
      _repo = AlarmRepository(_db!);
      await _player.init();
      _ready = true;
      await AlarmLog.write('Initialized');
    } on Exception catch (e) {
      await AlarmLog.write('FATAL: failed to initialize: $e');
      return;
    }

    _startPositionStream();
    await _fetchPosition(source: 'init');
    await AlarmLog.trim();
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 10),
            forceLocationManager: true,
          ),
        ).listen(
          _onStreamPosition,
          onError: (Object e) {
            AlarmLog.write('Position stream error: $e');
            // Keep _lastPosition — stale position is better than none.
            _resubscribeAfterDelay();
          },
        );
  }

  /// Fetches a single position fix. Retries up to 3 times on failure.
  Future<void> _fetchPosition({required String source}) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final timeout = Duration(seconds: 15 + attempt * 10);
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
        await _processPosition(pos, source: source);
        return;
      } on Exception catch (e) {
        if (attempt == 2) {
          await AlarmLog.write('Position $source failed (3 attempts): $e');
        }
      }
    }
  }

  /// Central position handler — both stream and poll positions flow through
  /// here. Deduplicates checks and tracks speed.
  Future<void> _processPosition(Position pos, {required String source}) async {
    if (!_ready) return;

    final latLng = LatLng(pos.latitude, pos.longitude);
    final now = DateTime.now();

    // Skip check if position hasn't meaningfully changed.
    if (_lastPosition != null && _lastCheckTime != null) {
      final moved = distanceInMeters(_lastPosition!, latLng);
      final elapsed = now.difference(_lastCheckTime!).inSeconds;
      // Skip if moved less than accuracy AND checked within the last 5s.
      if (moved < max(10, pos.accuracy) && elapsed < 5) {
        return;
      }
    }

    // Update speed estimate.
    if (_previousPosition != null && _previousPositionTime != null) {
      final dt = now.difference(_previousPositionTime!).inMilliseconds / 1000;
      if (dt > 0.5) {
        final dist = distanceInMeters(_previousPosition!, latLng);
        _speedMps = dist / dt;
      }
    }
    _previousPosition = latLng;
    _previousPositionTime = now;

    _lastPosition = latLng;
    _lastAccuracy = pos.accuracy;
    _lastCheckTime = now;

    await AlarmLog.write(
      'Position ($source): ${latLng.latitude.toStringAsFixed(5)}, '
      '${latLng.longitude.toStringAsFixed(5)} '
      '(accuracy: ${pos.accuracy.round()}m, '
      'speed: ${(_speedMps * 3.6).round()} km/h)',
    );

    FlutterForegroundTask.sendDataToMain(
      jsonEncode({
        'type': 'position',
        'lat': latLng.latitude,
        'lng': latLng.longitude,
      }),
    );

    await _checkAlarms(latLng);
    _scheduleAdaptivePoll();
  }

  void _onStreamPosition(Position position) {
    _processPosition(position, source: 'stream');
  }

  void _resubscribeAfterDelay() {
    Future<void>.delayed(const Duration(seconds: 30), () {
      if (!_ready) return;
      AlarmLog.write('Resubscribing to position stream');
      _startPositionStream();
    });
  }

  /// Compute the adaptive poll interval based on speed and distance to
  /// the nearest alarm. Faster speed + closer distance = more frequent polls.
  void _scheduleAdaptivePoll() {
    _adaptivePollTimer?.cancel();

    final pos = _lastPosition;
    if (pos == null) return;

    _repo?.getActive().then((alarms) {
      var intervalSeconds = 60;

      final checkable = alarms.where((a) => !_firedIds.contains(a.id));
      if (checkable.isNotEmpty) {
        final minDist = checkable
            .map((a) => distanceInMeters(pos, a.location))
            .fold<double>(double.infinity, min);

        if (_speedMps > 1) {
          final eta = minDist / _speedMps;
          intervalSeconds = (eta / 3).clamp(5, 60).round();
        } else if (minDist < 500) {
          intervalSeconds = 10;
        } else if (minDist < 2000) {
          intervalSeconds = 30;
        }
      }

      _adaptivePollTimer = Timer(Duration(seconds: intervalSeconds), () {
        if (_ready) _fetchPosition(source: 'adaptive');
      });
    });
  }

  Future<void> _checkAlarms(LatLng position) async {
    try {
      final activeAlarms = await _repo!.getActive();

      final activeIds = activeAlarms.map((a) => a.id!).toSet();
      _firedIds.retainAll(activeIds);

      final checkable = activeAlarms
          .where((a) => !_firedIds.contains(a.id))
          .toList();

      if (checkable.isNotEmpty) {
        final distances = checkable
            .map((a) {
              final d = distanceInMeters(position, a.location);
              final loc = a.location;
              return '${a.id}@${loc.latitude.toStringAsFixed(4)},'
                  '${loc.longitude.toStringAsFixed(4)}'
                  ':${d.round()}/${a.radius.round()}m';
            })
            .join(', ');
        await AlarmLog.write('Check ${checkable.length} alarm(s) [$distances]');
      }

      final triggered = _checker.check(
        checkable,
        position,
        accuracy: _lastAccuracy,
      );

      for (final alarm in triggered) {
        _firedIds.add(alarm.id!);

        await AlarmLog.write(
          'TRIGGERED alarm ${alarm.id} "${alarm.name}" '
          '(radius: ${alarm.radius.round()}m)',
        );

        FlutterForegroundTask.sendDataToMain(
          jsonEncode({'type': 'alarm_fired', 'id': alarm.id}),
        );

        await _player.fire(alarm);
      }
    } on Exception catch (e) {
      await AlarmLog.write('Check alarms error: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_ready) return;
    // Fallback poll — adaptive timer handles the fast path,
    // this catches cases where adaptive timer didn't fire.
    _fetchPosition(source: 'poll');
  }

  @override
  void onReceiveData(Object data) {
    if (data is! String) return;
    _handleData(data);
  }

  Future<void> _handleData(String data) async {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'dismiss') {
        final id = json['id'] as int;
        await _player.stop();
        await _repo?.toggleActive(id, active: false);
        _firedIds.remove(id);
        await AlarmLog.write('Dismissed alarm $id');
        FlutterForegroundTask.sendDataToMain(
          jsonEncode({'type': 'alarm_dismissed', 'id': id}),
        );
      } else if (type == 'refresh') {
        await AlarmLog.write('Refresh requested');
        final position = _lastPosition;
        if (position != null) {
          await _checkAlarms(position);
        }
      }
    } on Exception catch (e) {
      await AlarmLog.write('Handle data error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await AlarmLog.write('Service destroyed (isTimeout: $isTimeout)');
    _ready = false;
    _adaptivePollTimer?.cancel();
    await _positionSub?.cancel();
    await _player.stop();
    await _player.dispose();
    await _db?.close();
  }
}
