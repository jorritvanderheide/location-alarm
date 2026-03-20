import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/app.dart';
import 'package:location_alarm/features/alarm_service/background_notification_handler.dart';
import 'package:location_alarm/features/alarm_service/foreground_service_manager.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/features/alarm_service/providers/foreground_service_provider.dart';
import 'package:location_alarm/features/alarm_service/screens/alarm_ring_screen.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
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

  // Initialize notifications in main isolate for foreground responses.
  // Background responses are handled by onBackgroundNotificationResponse.
  final notifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
    onDidReceiveBackgroundNotificationResponse:
        onBackgroundNotificationResponse,
  );

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

  // Store container reference for the foreground notification callback
  _container = container;

  bool dismissScreenShowing = false;

  // Listen for alarm fires from the background isolate via the provider
  container.listen(alarmServiceProvider, (previous, next) {
    if (next == null || previous == next) return;

    _showDismissScreenIfNeeded(
      next,
      isDismissShowing: () => dismissScreenShowing,
      setDismissShowing: (value) => dismissScreenShowing = value,
      container: container,
    );
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: _AppWithServices(
        onScreenLocked: () {
          final alarm = container.read(alarmServiceProvider);
          if (alarm != null && !dismissScreenShowing) {
            dismissScreenShowing = true;
            _showDismissScreen(alarm, container, () {
              dismissScreenShowing = false;
            });
          }
        },
      ),
    ),
  );
}

ProviderContainer? _container;

/// Handle notification actions when the main isolate is alive.
void _onForegroundNotificationResponse(NotificationResponse response) {
  if (response.actionId == 'dismiss_alarm') {
    final alarmId = int.tryParse(response.payload ?? '');
    if (alarmId != null) {
      _container?.read(alarmServiceProvider.notifier).dismiss(alarmId);
    }
  }
}

Future<void> _showDismissScreenIfNeeded(
  AlarmData alarm, {
  required bool Function() isDismissShowing,
  required void Function(bool) setDismissShowing,
  required ProviderContainer container,
}) async {
  if (isDismissShowing()) return;

  final screenOff = await _isScreenOff();
  if (screenOff) {
    setDismissShowing(true);
    _showDismissScreen(alarm, container, () {
      setDismissShowing(false);
    });
  }
}

void _showDismissScreen(
  AlarmData alarm,
  ProviderContainer container,
  VoidCallback onDismissed,
) {
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
