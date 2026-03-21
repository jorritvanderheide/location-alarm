import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_list/widgets/alarm_card.dart';
import 'package:location_alarm/features/alarm_service/providers/alarm_service_provider.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/widgets/permission_dialogs.dart';

enum AlarmSortMode {
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
  AlarmSortMode _sortMode = AlarmSortMode.created;
  final Set<int> _activatingIds = {};

  // Multi-select state
  bool _editMode = false;
  final Set<int> _selectedIds = {};

  List<AlarmData> _sortAlarms(List<AlarmData> alarms) {
    final sorted = [...alarms];
    switch (_sortMode) {
      case AlarmSortMode.created:
        sorted.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
      case AlarmSortMode.name:
        sorted.sort((a, b) {
          if (a.name.isEmpty != b.name.isEmpty) {
            return a.name.isEmpty ? 1 : -1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
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

  // -- Multi-select --

  void _enterEditMode(int alarmId) {
    setState(() {
      _editMode = true;
      _selectedIds.add(alarmId);
    });
  }

  void _exitEditMode() {
    setState(() {
      _editMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int alarmId) {
    setState(() {
      if (_selectedIds.contains(alarmId)) {
        _selectedIds.remove(alarmId);
        if (_selectedIds.isEmpty) _editMode = false;
      } else {
        _selectedIds.add(alarmId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count alarm${count > 1 ? 's' : ''}?'),
        content: Text(
          '$count alarm${count > 1 ? 's' : ''} will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final repo = ref.read(alarmRepositoryProvider);
    await Future.wait(
      _selectedIds.map((id) async {
        await repo.delete(id);
        await AlarmThumbnail.delete(id);
      }),
    );
    _exitEditMode();
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_editMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitEditMode();
      },
      child: Scaffold(
        appBar: _editMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitEditMode,
                ),
                title: Text('${_selectedIds.length} selected'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete selected',
                    onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
                  ),
                ],
              )
            : AppBar(
                title: const Text('Alarms'),
                actions: [
                  IconButton(
                    icon: _sortMode != AlarmSortMode.created
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
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load alarms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(alarmsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
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

            final sorted = _sortAlarms(alarms);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              child: Column(
                spacing: 16,
                children: [
                  for (final alarm in sorted)
                    AlarmCard(
                      key: ValueKey(alarm.id),
                      alarm: alarm,
                      activating: _activatingIds.contains(alarm.id),
                      selected: _selectedIds.contains(alarm.id),
                      editMode: _editMode,
                      onTap: _editMode
                          ? () => _toggleSelection(alarm.id!)
                          : () => context.push('/edit/${alarm.id}'),
                      onLongPress: _editMode
                          ? null
                          : () => _enterEditMode(alarm.id!),
                      onToggle: (active) => _handleToggle(alarm, active, ref),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: _editMode
            ? null
            : FloatingActionButton(
                heroTag: 'create_alarm',
                onPressed: () => context.push('/create'),
                child: const Icon(Icons.add),
              ),
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
      _activatingIds.remove(id);
      await ref.read(alarmRepositoryProvider).toggleActive(id, active: false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$alarmName deactivated')));
      }
      return;
    }

    if (_activatingIds.contains(id)) return;
    setState(() => _activatingIds.add(id));

    try {
      // 1. Check foreground location.
      if (!await ensureForegroundLocation(context, ref)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required')),
          );
        }
        return;
      }
      if (!mounted) return;

      // 2. Check background location with rationale dialog.
      final bgGranted = await requestBackgroundWithRationale(context, ref);
      if (!mounted) return;
      if (!bgGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background location required')),
        );
        return;
      }

      // 3. Request notification permission (warn but allow activation).
      final permNotifier = ref.read(locationPermissionProvider.notifier);
      final notifGranted = await permNotifier.requestNotification();
      if (!mounted) return;
      if (!notifGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications disabled — you won\'t hear the alarm'),
          ),
        );
      }

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
                'Move outside the ${_formatDistance(alarm.radius)} radius to activate.',
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
      AlarmServiceNotifier.refresh();

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
