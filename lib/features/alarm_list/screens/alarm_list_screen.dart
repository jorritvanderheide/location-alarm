import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_list/widgets/alarm_card.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/departure_calculator.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

enum AlarmSortMode {
  active('Active first'),
  created('Date created'),
  name('Name'),
  type('Type');

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
  bool _editMode = false;
  final Set<int> _activatingIds = {};
  final Set<int> _selectedIds = {};

  List<AlarmData> _sortAlarms(List<AlarmData> alarms) {
    final sorted = [...alarms];
    switch (_sortMode) {
      case AlarmSortMode.active:
        sorted.sort((a, b) {
          if (a.active != b.active) return a.active ? -1 : 1;
          // Within inactive group: most recently updated first
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
      case AlarmSortMode.type:
        sorted.sort((a, b) {
          final aType = a is ProximityAlarmData ? 0 : 1;
          final bType = b is ProximityAlarmData ? 0 : 1;
          return aType.compareTo(bType);
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

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(alarmsProvider);

    return PopScope(
      canPop: !_editMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitEditMode();
      },
      child: Scaffold(
        appBar: _editMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
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
                    icon: const Icon(Icons.sort),
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
                      PopupMenuItem(value: 'settings', child: Text('Settings')),
                      PopupMenuItem(value: 'about', child: Text('About')),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No alarms yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first alarm',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final sorted = _sortAlarms(alarms);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                  if (!_editMode)
                    Text(
                      'Long press to select and delete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
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
    if (!active) {
      await ref
          .read(alarmRepositoryProvider)
          .toggleActive(alarm.id!, active: false);
      return;
    }

    // GPS check before activating — needed for proximity (area check) and
    // departure (travel time calculation).
    setState(() => _activatingIds.add(alarm.id!));

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted || !_activatingIds.contains(alarm.id)) return;

      if (alarm is ProximityAlarmData) {
        final currentLatLng = LatLng(position.latitude, position.longitude);
        final distance = distanceInMeters(currentLatLng, alarm.location);
        if (distance <= alarm.radius) {
          setState(() => _activatingIds.remove(alarm.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already in the alarm area')),
          );
          return;
        }
      }

      if (alarm is DepartureAlarmData &&
          alarm.arrivalTime.isBefore(DateTime.now())) {
        setState(() => _activatingIds.remove(alarm.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrival time is in the past')),
        );
        return;
      }

      await ref
          .read(alarmRepositoryProvider)
          .toggleActive(alarm.id!, active: true);

      if (!mounted) return;
      setState(() => _activatingIds.remove(alarm.id));

      final message = switch (alarm) {
        DepartureAlarmData() => _departureActivatedMessage(alarm, ref),
        _ => 'Alarm activated',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() => _activatingIds.remove(alarm.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS is disabled — enable it in Settings'),
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _activatingIds.remove(alarm.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not acquire location')),
      );
    }
  }

  String _departureActivatedMessage(DepartureAlarmData alarm, WidgetRef ref) {
    final locationAsync = ref.read(locationProvider);
    final position = locationAsync.whenData((p) => p).value;
    if (position == null) return 'Alarm activated';

    final info = calculateDeparture(
      currentPosition: LatLng(position.latitude, position.longitude),
      destination: alarm.location,
      travelMode: alarm.travelMode,
      bufferMinutes: alarm.bufferMinutes,
      arrivalTime: alarm.arrivalTime,
    );
    if (info == null) return 'Alarm activated';

    return formatDepartureInfo(info, context);
  }
}
