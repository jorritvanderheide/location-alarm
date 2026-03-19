import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  const AlarmRingScreen({
    super.key,
    required this.alarmSettings,
    this.onDismissed,
  });

  final AlarmSettings alarmSettings;
  final VoidCallback? onDismissed;

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('nl.bw20.location_alarm/screen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showOverLockScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearLockScreenFlags();
    widget.onDismissed?.call();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showOverLockScreen();
    }
  }

  Future<void> _showOverLockScreen() async {
    try {
      await _channel.invokeMethod('showOverLockScreen');
    } on MissingPluginException {
      // ignore
    }
  }

  Future<void> _clearLockScreenFlags() async {
    try {
      await _channel.invokeMethod('clearLockScreenFlags');
    } on MissingPluginException {
      // ignore
    }
  }

  Future<void> _dismiss() async {
    await Alarm.stop(widget.alarmSettings.id);
    await ref
        .read(alarmRepositoryProvider)
        .toggleActive(widget.alarmSettings.id, active: false);
    await _clearLockScreenFlags();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isProximity =
        widget.alarmSettings.notificationSettings.title == 'Location Alarm';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProximity ? Icons.notifications : Icons.directions_walk,
                size: 96,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                widget.alarmSettings.notificationSettings.title,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.alarmSettings.notificationSettings.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              FilledButton.icon(
                onPressed: _dismiss,
                icon: const Icon(Icons.alarm_off),
                label: const Text('Dismiss'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 56),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
