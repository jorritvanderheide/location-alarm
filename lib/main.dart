import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/app.dart';
import 'package:location_alarm/features/alarm_service/alarm_notification_service.dart';
import 'package:location_alarm/features/alarm_service/foreground_service_manager.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/features/alarm_service/providers/foreground_service_provider.dart';
import 'package:location_alarm/features/alarm_service/screens/alarm_ring_screen.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/providers/database_provider.dart';

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
  await AlarmNotificationService.init();
  ForegroundServiceManager.init();

  // Clear any leftover lock screen flags from a previous alarm
  try {
    await _screenChannel.invokeMethod('clearLockScreenFlags');
  } on MissingPluginException {
    // ignore
  }

  // Track ringing alarms for lock screen detection
  AlarmSet currentlyRinging = AlarmSet.empty();
  bool dismissScreenShowing = false;

  Alarm.ringing.listen((alarmSet) async {
    currentlyRinging = alarmSet;

    if (alarmSet.alarms.isEmpty) return;
    if (dismissScreenShowing) return;

    final screenOff = await _isScreenOff();
    if (screenOff) {
      _showDismissScreen(alarmSet.alarms.first, () {
        dismissScreenShowing = false;
      });
      dismissScreenShowing = true;
    }
  });

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: _AppWithServices(
        onScreenLocked: () {
          if (currentlyRinging.alarms.isNotEmpty && !dismissScreenShowing) {
            _showDismissScreen(currentlyRinging.alarms.first, () {
              dismissScreenShowing = false;
            });
            dismissScreenShowing = true;
          }
        },
      ),
    ),
  );
}

void _showDismissScreen(AlarmSettings settings, VoidCallback onDismissed) {
  navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) =>
          AlarmRingScreen(alarmSettings: settings, onDismissed: onDismissed),
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.onScreenLocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(alarmServiceProvider);
    ref.watch(foregroundServiceProvider);
    return const LocationAlarmApp();
  }
}
