import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/alarm_log.dart';
import 'package:location_alarm/shared/providers/location_settings_provider.dart';
import 'package:location_alarm/shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final amoled = ref.watch(amoledBlackProvider);
    final triggerInside = ref.watch(triggerInsideRadiusProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader(label: 'Appearance'),
          _ThemeListTile(
            themeMode: themeMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).set(mode);
            },
          ),
          if (isDark)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: const Text('True black'),
              subtitle: const Text('Pure black background for AMOLED displays'),
              value: amoled,
              onChanged: (value) {
                ref.read(amoledBlackProvider.notifier).set(value);
              },
            ),
          if (kDebugMode) ...[
            const _SectionHeader(label: 'Debug'),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: const Text('Activate while in area'),
              subtitle: const Text(
                'Allow activating alarms when already inside the area',
              ),
              value: triggerInside,
              onChanged: (value) {
                ref.read(triggerInsideRadiusProvider.notifier).set(value);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: const Text('Alarm service log'),
              subtitle: const Text('View background service diagnostics'),
              onTap: () => _showAlarmLog(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAlarmLog(BuildContext context) async {
    final log = await AlarmLog.read();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alarm service log'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            reverse: true,
            child: SelectableText(
              log.isEmpty ? 'No log entries yet.' : log,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeListTile extends StatelessWidget {
  const _ThemeListTile({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: const Text('Theme'),
      subtitle: Text(switch (themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      }),
      onTap: () async {
        final result = await showDialog<ThemeMode>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Theme'),
            children: [
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (value) => Navigator.pop(context, value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        value: mode,
                        title: Text(switch (mode) {
                          ThemeMode.system => 'System',
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        if (result != null) onChanged(result);
      },
    );
  }
}
