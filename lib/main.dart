import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/app.dart';
import 'package:location_alarm/features/alarm_service/foreground_service_manager.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/features/alarm_service/providers/foreground_service_provider.dart';
import 'package:location_alarm/features/alarm_service/screens/alarm_ring_screen.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/connectivity_provider.dart';
import 'package:location_alarm/shared/providers/database_provider.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
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

  ForegroundServiceManager.init();
  FlutterForegroundTask.initCommunicationPort();

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

  final shownDismissIds = <int>{};

  // Listen for alarm fires from the background isolate via the provider.
  // Only show the ring screen if the screen is off (case D).
  // When screen is on, the native notification handles it (cases B, C).
  container.listen(alarmServiceProvider, (previous, next) {
    if (next.isEmpty) return;

    for (final alarm in next) {
      if (alarm.id == null) continue;
      if (shownDismissIds.contains(alarm.id)) continue;
      shownDismissIds.add(alarm.id!);
      _showDismissIfScreenOff(
        alarm,
        () => shownDismissIds.remove(alarm.id),
      ).then((shown) {
        if (!shown) shownDismissIds.remove(alarm.id);
      });
    }
  });

  // Check if launched via full-screen alarm intent (case A: app was closed).
  unawaited(
    _checkLaunchIntent(
      tryAcquire: (alarmId) {
        if (shownDismissIds.contains(alarmId)) return false;
        shownDismissIds.add(alarmId);
        return true;
      },
      onDismissed: shownDismissIds.remove,
    ),
  );

  // Listen for alarm intents arriving while the app is already running.
  // This fires when the full-screen intent targets an already-running activity.
  // Only show ring screen if screen is off; otherwise the notification suffices.
  _screenChannel.setMethodCallHandler((call) async {
    if (call.method == 'onAlarmRing') {
      final args = call.arguments as Map<Object?, Object?>;
      final alarmId = args['alarm_id'] as int?;
      if (alarmId != null && !shownDismissIds.contains(alarmId)) {
        final screenOff = await _isScreenOff();
        if (screenOff) {
          final title = args['title'] as String? ?? '';
          final body = args['body'] as String? ?? '';
          shownDismissIds.add(alarmId);
          _showDismissScreenFromIntent(
            alarmId: alarmId,
            title: title,
            body: body,
            launchedByIntent: false, // app was already running
            onDismissed: () => shownDismissIds.remove(alarmId),
          );
        }
      }
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: _AppWithServices(
        onScreenLocked: () {
          // User locked the screen while alarm is ringing. Show ring screen
          // over lock screen so they can dismiss without unlocking.
          final alarms = container.read(alarmServiceProvider);
          for (final alarm in alarms) {
            if (alarm.id == null) continue;
            if (shownDismissIds.contains(alarm.id)) continue;
            shownDismissIds.add(alarm.id!);
            _showDismissScreen(
              alarm,
              launchedByIntent: false,
              onDismissed: () => shownDismissIds.remove(alarm.id),
            );
          }
        },
      ),
    ),
  );
}

/// Returns `true` if the dismiss screen was shown.
Future<bool> _showDismissIfScreenOff(
  AlarmData alarm,
  VoidCallback onDismissed,
) async {
  final screenOff = await _isScreenOff();
  if (screenOff) {
    _showDismissScreen(
      alarm,
      launchedByIntent: false,
      onDismissed: onDismissed,
    );
    return true;
  }
  // Screen on: the native notification handles dismiss via AlarmDismissReceiver
  return false;
}

Future<void> _checkLaunchIntent({
  required bool Function(int alarmId) tryAcquire,
  required void Function(int alarmId) onDismissed,
}) async {
  try {
    final data = await _screenChannel.invokeMethod<Map<Object?, Object?>>(
      'getLaunchAlarmData',
    );
    if (data == null) return;

    final alarmId = data['alarm_id'] as int?;
    if (alarmId == null) return;
    if (!tryAcquire(alarmId)) return;

    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';

    // Wait for the navigator to be ready (runApp may not have completed yet)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDismissScreenFromIntent(
        alarmId: alarmId,
        title: title,
        body: body,
        launchedByIntent: true, // app was cold-launched by alarm
        onDismissed: () => onDismissed(alarmId),
      );
    });
  } on MissingPluginException {
    // ignore
  }
}

void _showDismissScreenFromIntent({
  required int alarmId,
  required String title,
  required String body,
  required bool launchedByIntent,
  required VoidCallback onDismissed,
}) {
  navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => AlarmRingScreen(
        alarmId: alarmId,
        title: title,
        body: body,
        launchedByIntent: launchedByIntent,
        onDismissed: onDismissed,
      ),
    ),
  );
}

void _showDismissScreen(
  AlarmData alarm, {
  required bool launchedByIntent,
  required VoidCallback onDismissed,
}) {
  if (alarm.id == null) return;
  final label = alarm.name.isNotEmpty ? alarm.name : null;
  final title = label ?? 'Location Alarm';
  final body = 'You are within ${alarm.radius.round()} m of your destination';

  navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => AlarmRingScreen(
        alarmId: alarm.id!,
        title: title,
        body: body,
        launchedByIntent: launchedByIntent,
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
    if (state == AppLifecycleState.resumed) {
      ref.read(locationPermissionProvider.notifier).checkAll();
      ref.read(connectivityProvider.notifier).check();
    }
    if (_previousState == AppLifecycleState.resumed &&
        state == AppLifecycleState.paused) {
      // Only show the ring screen if the screen is actually off, not when
      // the user just pressed home or switched apps.
      _isScreenOff().then((isOff) {
        if (isOff) widget.onScreenLocked();
      });
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
