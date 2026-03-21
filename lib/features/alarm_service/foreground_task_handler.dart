import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_service/alarm_checker.dart';
import 'package:location_alarm/features/alarm_service/background_alarm_player.dart';
import 'package:location_alarm/shared/data/database/app_database.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/repositories/alarm_repository.dart';
import 'package:location_alarm/shared/providers/location_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  LatLng? _lastPosition;
  bool _ready = false;
  bool _usePlayServices = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      _db = openDatabase();
      _repo = AlarmRepository(_db!);
      await _player.init();

      // Read Play Services preference from SharedPreferences directly
      // (Riverpod is not available in the background isolate).
      final prefs = await SharedPreferences.getInstance();
      _usePlayServices = prefs.getBool(usePlayServicesKey) ?? false;

      _ready = true;
    } on Exception catch (e) {
      debugPrint('ALARM: failed to initialize background task: $e');
      return;
    }

    _startPositionStream();

    // Seed initial position immediately so we don't wait for the stream.
    await _fetchInitialPosition();
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            forceLocationManager: !_usePlayServices,
          ),
        ).listen(
          _onPosition,
          onError: (Object e) {
            debugPrint('ALARM: position stream error: $e');
            _lastPosition = null;
            _resubscribeAfterDelay();
          },
        );
  }

  Future<void> _fetchInitialPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _lastPosition = latLng;
      await _checkAlarms(latLng);
    } on Exception catch (e) {
      debugPrint('ALARM: initial position check failed: $e');
    }
  }

  void _resubscribeAfterDelay() {
    Future<void>.delayed(const Duration(seconds: 30), () {
      if (!_ready) return;
      _startPositionStream();
    });
  }

  Future<void> _onPosition(Position position) async {
    if (!_ready) return;

    final latLng = LatLng(position.latitude, position.longitude);
    _lastPosition = latLng;

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
    try {
      final activeAlarms = await _repo!.getActive();

      final activeIds = activeAlarms.map((a) => a.id!).toSet();
      _firedIds.retainAll(activeIds);

      final checkable = activeAlarms
          .where((a) => !_firedIds.contains(a.id))
          .toList();
      final triggered = _checker.check(checkable, position);

      for (final alarm in triggered) {
        _firedIds.add(alarm.id!);

        FlutterForegroundTask.sendDataToMain(
          jsonEncode({'type': 'alarm_fired', 'id': alarm.id}),
        );

        await _player.fire(alarm);
      }
    } on Exception catch (e) {
      debugPrint('ALARM: error checking alarms: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_ready) return;
    final position = _lastPosition;
    if (position != null) {
      _checkAlarms(position);
    } else {
      _fetchInitialPosition();
    }
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
        FlutterForegroundTask.sendDataToMain(
          jsonEncode({'type': 'alarm_dismissed', 'id': id}),
        );
      } else if (type == 'refresh') {
        final position = _lastPosition;
        if (position != null) {
          await _checkAlarms(position);
        }
      }
    } on Exception catch (e) {
      debugPrint('ALARM: error handling received data: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _ready = false;
    await _positionSub?.cancel();
    await _player.stop();
    await _player.dispose();
    await _db?.close();
  }
}
