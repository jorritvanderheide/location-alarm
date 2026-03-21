import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  const AlarmRingScreen({
    super.key,
    required this.alarmId,
    required this.title,
    required this.body,
    this.onDismissed,
  });

  final int alarmId;
  final String title;
  final String body;
  final VoidCallback? onDismissed;

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('nl.bw20.location_alarm/screen');
  bool _dismissed = false;

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
    if (_dismissed) return;
    _dismissed = true;

    // Send dismiss command to background isolate
    await ref.read(alarmServiceProvider.notifier).dismiss(widget.alarmId);

    await _clearLockScreenFlags();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-pop if alarm is deactivated externally
    ref.listen(alarmsProvider, (_, next) {
      next.whenData((alarms) {
        final alarm = alarms.where((a) => a.id == widget.alarmId).firstOrNull;
        if ((alarm == null || !alarm.active) && !_dismissed) {
          _dismissed = true;
          _clearLockScreenFlags();
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
          }
        }
      });
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications, size: 96, color: colorScheme.primary),
              const SizedBox(height: 32),
              Semantics(
                liveRegion: true,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  widget.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FilledButton.icon(
                  autofocus: true,
                  onPressed: _dismiss,
                  icon: const Icon(Icons.alarm_off, size: 28),
                  label: const Text('Dismiss'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(72),
                    textStyle: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
