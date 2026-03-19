import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _subscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            forceLocationManager: true,
          ),
        ).listen((position) {
          FlutterForegroundTask.sendDataToMain(
            jsonEncode({'lat': position.latitude, 'lng': position.longitude}),
          );
        });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat — send last known position if available
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _subscription?.cancel();
  }
}
