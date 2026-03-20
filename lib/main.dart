import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/app.dart';
import 'package:location_alarm/features/alarm_service/alarm_player.dart';
import 'package:location_alarm/features/alarm_service/foreground_service_manager.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/features/alarm_service/providers/foreground_service_provider.dart';
import 'package:location_alarm/features/alarm_service/screens/alarm_ring_screen.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/database_provider.dart';
import 'package:location_alarm/shared/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _screenChannel = MethodChannel('nl.bw20.location_alarm/screen');

Future<bool> _isScreenOff() async {
  try {
    final result = await _screenChannel.invokeMethod<bool>('isScreenOff');
    return result ?? true;
  } on MissingPluginException {
    return true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openDatabase();
  final prefs = await SharedPreferences.getInstance();
  await AlarmPlayer.init();
  ForegroundServiceManager.init();

  // Clear any leftover lock screen flags
  try {
    await _screenChannel.invokeMethod('clearLockScreenFlags');
  } on MissingPluginException {
    // ignore
  }

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      preferencesProvider.overrideWithValue(prefs),
    ],
  );

  bool dismissScreenShowing = false;

  // Handle notification dismiss action
  AlarmPlayer.setDismissCallback(() async {
    final alarm = AlarmPlayer.currentRinging;
    if (alarm?.id == null) return;
    await AlarmPlayer.stop();
    await container
        .read(alarmRepositoryProvider)
        .toggleActive(alarm!.id!, active: false);
  });

  // Listen for alarm fires — show full-screen dismiss
  AlarmPlayer.ringing.listen((alarm) async {
    if (alarm == null) return;
    if (dismissScreenShowing) return;

    final screenOff = await _isScreenOff();
    if (screenOff) {
      dismissScreenShowing = true;
      _showDismissScreen(alarm, () {
        dismissScreenShowing = false;
      });
    }
    // Screen on: notification is already shown by AlarmPlayer.fire()
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: _AppWithServices(
        onScreenLocked: () {
          final alarm = AlarmPlayer.currentRinging;
          if (alarm != null && !dismissScreenShowing) {
            dismissScreenShowing = true;
            _showDismissScreen(alarm, () {
              dismissScreenShowing = false;
            });
          }
        },
      ),
    ),
  );
}

void _showDismissScreen(AlarmData alarm, VoidCallback onDismissed) {
  final (title, body) = switch (alarm) {
    ProximityAlarmData(:final radius) => (
      'Location Alarm',
      'You are within ${radius.round()} m of your destination',
    ),
    DepartureAlarmData(:final travelMode) => (
      'Time to Leave',
      'Leave now by ${travelMode.name} to arrive on time',
    ),
  };

  navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => AlarmRingScreen(
        alarmId: alarm.id!,
        isProximity: alarm is ProximityAlarmData,
        title: title,
        body: body,
        onDismissed: onDismissed,
      ),
    ),
  );
}

class _AppWithServices extends ConsumerStatefulWidget {
  const _AppWithServices({required this.onScreenLocked});

  final VoidCallback onScreenLocked;

  @override
  ConsumerState<_AppWithServices> createState() => _AppWithServicesState();
}

class _AppWithServicesState extends ConsumerState<_AppWithServices>
    with WidgetsBindingObserver {
  AppLifecycleState? _previousState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_previousState == AppLifecycleState.resumed &&
        state == AppLifecycleState.paused) {
      widget.onScreenLocked();
    }
    _previousState = state;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(alarmServiceProvider);
    ref.watch(foregroundServiceProvider);
    return const LocationAlarmApp();
  }
}
