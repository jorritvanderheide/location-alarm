import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/providers/location_settings_provider.dart';
import 'package:location_alarm/shared/providers/theme_provider.dart';

const _playServicesChannel = MethodChannel(
  'nl.bw20.location_alarm/play_services',
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final amoled = ref.watch(amoledBlackProvider);
    final usePlayServices = ref.watch(usePlayServicesProvider);
    final triggerInside = ref.watch(triggerInsideRadiusProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(label: 'Appearance', colorScheme: colorScheme),
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
          _SectionHeader(label: 'Location', colorScheme: colorScheme),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: const Text('Google Play Services'),
            subtitle: const Text('More reliable location tracking'),
            value: usePlayServices,
            onChanged: (value) async {
              if (value) {
                final available = await _checkPlayServices();
                if (!available) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Google Play Services is not available on this device',
                        ),
                      ),
                    );
                  }
                  return;
                }
              }
              ref.read(usePlayServicesProvider.notifier).set(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restart the app for changes to take effect'),
                  ),
                );
              }
            },
          ),
          _SectionHeader(label: 'Debug', colorScheme: colorScheme),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: const Text('Trigger inside radius'),
            subtitle: const Text(
              'Allow activating alarms when already inside the radius',
            ),
            value: triggerInside,
            onChanged: (value) {
              ref.read(triggerInsideRadiusProvider.notifier).set(value);
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _checkPlayServices() async {
    try {
      final result = await _playServicesChannel.invokeMethod<bool>(
        'isAvailable',
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
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
