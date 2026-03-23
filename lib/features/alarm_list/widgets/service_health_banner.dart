import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/alarm_service/providers/foreground_service_provider.dart';
import 'package:location_alarm/l10n/app_localizations.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shows a warning when active alarms exist but the monitoring service
/// is not running (e.g. missing permissions).
class ServiceHealthBanner extends ConsumerWidget {
  const ServiceHealthBanner({super.key, required this.hasActiveAlarms});

  final bool hasActiveAlarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasActiveAlarms) return const SizedBox.shrink();

    final serviceRunning = ref.watch(foregroundServiceProvider);
    final bgPerm = ref.watch(backgroundPermissionProvider);

    // Don't show while permission state is still loading.
    if (bgPerm == null) return const SizedBox.shrink();

    // Service is running — all good.
    if (serviceRunning) return const SizedBox.shrink();

    // Permission is granted — service will start momentarily. Don't flash
    // the banner during the brief async startup window.
    if (bgPerm) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: colorScheme.onErrorContainer),
        title: Text(
          l10n.alarmsNotMonitored,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        subtitle: Text(
          bgPerm ? l10n.tapToCheckPermissions : l10n.backgroundLocationRequired,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        onTap: openAppSettings,
      ),
    );
  }
}
