import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({
    super.key,
    required this.alarmSettings,
    this.onDismissed,
  });

  final AlarmSettings alarmSettings;
  final VoidCallback? onDismissed;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  static const _channel = MethodChannel('nl.bw20.location_alarm/screen');

  @override
  void initState() {
    super.initState();
    _showOverLockScreen();
  }

  @override
  void dispose() {
    _clearLockScreenFlags();
    widget.onDismissed?.call();
    super.dispose();
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
