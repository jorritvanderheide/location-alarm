import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_list/widgets/alarm_card.dart';
import 'package:location_alarm/features/alarm_service/providers/foreground_service_provider.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum AlarmSortMode {
  active('Active first'),
  created('Date created'),
  name('Name');

  const AlarmSortMode(this.label);
  final String label;
}

class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen> {
  AlarmSortMode _sortMode = AlarmSortMode.active;
  final Set<int> _activatingIds = {};

  List<AlarmData> _sortAlarms(List<AlarmData> alarms) {
    final sorted = [...alarms];
    switch (_sortMode) {
      case AlarmSortMode.active:
        sorted.sort((a, b) {
          if (a.active != b.active) return a.active ? -1 : 1;
          if (!a.active && !b.active) {
            final aTime = a.updatedAt ?? DateTime(0);
            final bTime = b.updatedAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          }
          return 0;
        });
      case AlarmSortMode.created:
        sorted.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
      case AlarmSortMode.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
    }
    return sorted;
  }

  Future<void> _showSortSheet() async {
    final result = await showModalBottomSheet<AlarmSortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sort by',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final mode in AlarmSortMode.values)
            ListTile(
              title: Text(mode.label),
              leading: mode == _sortMode
                  ? const Icon(Icons.check)
                  : const SizedBox(width: 24),
              onTap: () => Navigator.pop(context, mode),
            ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
    if (result != null) {
      setState(() => _sortMode = result);
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final serviceRunning = ref.watch(foregroundServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: [
          IconButton(
            icon: _sortMode != AlarmSortMode.active
                ? Icon(Icons.sort, color: colorScheme.primary)
                : const Icon(Icons.sort),
            tooltip: 'Sort alarms',
            onPressed: _showSortSheet,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.push('/settings');
                case 'about':
                  context.push('/about');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: alarmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Failed to load alarms')),
        data: (alarms) {
          if (alarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alarms yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first alarm',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final hasActive = alarms.any((a) => a.active);
          final sorted = _sortAlarms(alarms);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16,
              children: [
                // Warning banner when active alarms exist but service isn't running
                if (hasActive && !serviceRunning)
                  Card(
                    color: colorScheme.errorContainer,
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_amber,
                        color: colorScheme.onErrorContainer,
                      ),
                      title: Text(
                        'Alarms are not being monitored',
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                      subtitle: Text(
                        'Background location permission required',
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                      onTap: openAppSettings,
                    ),
                  ),
                for (final alarm in sorted)
                  AlarmCard(
                    key: ValueKey(alarm.id),
                    alarm: alarm,
                    activating: _activatingIds.contains(alarm.id),
                    onTap: () => context.push('/edit/${alarm.id}'),
                    onToggle: (active) => _handleToggle(alarm, active, ref),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_alarm',
        onPressed: () => context.push('/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleToggle(
    AlarmData alarm,
    bool active,
    WidgetRef ref,
  ) async {
    final id = alarm.id!;
    final alarmName = alarm.name.isEmpty ? 'Alarm #$id' : alarm.name;

    if (!active) {
      // Cancel any pending activation for this alarm.
      _activatingIds.remove(id);
      await ref.read(alarmRepositoryProvider).toggleActive(id, active: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$alarmName deactivated'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref
                    .read(alarmRepositoryProvider)
                    .toggleActive(id, active: true);
              },
            ),
          ),
        );
      }
      return;
    }

    // GPS check before activating
    setState(() => _activatingIds.add(id));

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!_activatingIds.contains(id)) return;
      if (!mounted) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);
      final distance = distanceInMeters(currentLatLng, alarm.location);
      if (distance <= alarm.radius) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Already inside alarm area'),
              content: Text(
                'You are ${_formatDistance(distance)} from "$alarmName". '
                'Move outside the ${alarm.radius.round()} m radius to activate.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!_activatingIds.contains(id)) return;

      await ref.read(alarmRepositoryProvider).toggleActive(id, active: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$alarmName activated — ${_formatDistance(distance)} away',
            ),
          ),
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS is disabled'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: Geolocator.openLocationSettings,
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not acquire location')),
        );
      }
    } finally {
      _activatingIds.remove(id);
      if (mounted) setState(() {});
    }
  }
}
