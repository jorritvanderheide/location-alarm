import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:location_alarm/features/alarm_list/providers/alarm_activation_provider.dart';
import 'package:location_alarm/features/alarm_list/providers/alarm_delete_provider.dart';
import 'package:location_alarm/features/alarm_list/widgets/alarm_card.dart';
import 'package:location_alarm/features/alarm_list/widgets/alarm_list_empty_state.dart';
import 'package:location_alarm/features/alarm_list/widgets/alarm_list_error_state.dart';
import 'package:location_alarm/features/alarm_list/widgets/service_health_banner.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/widgets/permission_dialogs.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

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

  // -- Sort --

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

  Future<void> _confirmDeleteSelected() async {
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

    await ref.read(alarmDeleteProvider.notifier).deleteAlarms(_selectedIds);
  }

  // -- Activation event handling --

  Future<void> _onActivationEvent(AlarmActivationEvent event) async {
    final notifier = ref.read(alarmActivationProvider.notifier);

    switch (event) {
      case AlarmActivationIdle():
        break;

      case AlarmDeactivated(:final alarmName):
        _showSnackBar('$alarmName deactivated');
        notifier.consumeEvent();

      case AlarmActivated(:final alarmName, :final distance):
        _showSnackBar(
          '$alarmName activated — ${formatDistance(distance)} away',
        );
        notifier.consumeEvent();

      case AlarmActivationNeedsForeground():
        _showSnackBar('Location permission required');
        notifier.consumeEvent();

      case AlarmActivationNeedsBackgroundRationale(:final alarmId):
        notifier.consumeEvent();
        if (!mounted) return;
        final confirmed = await showBackgroundRationaleDialog(context);
        await notifier.continueWithBackground(alarmId, confirmed);

      case AlarmActivationNeedsBatteryRationale(:final alarmId):
        notifier.consumeEvent();
        if (!mounted) return;
        final confirmed = await showBatteryRationaleDialog(context);
        await notifier.continueWithBattery(alarmId, confirmed);

      case AlarmActivationNotificationDenied():
        _showSnackBar('Notifications disabled — you won\'t hear the alarm');
        notifier.consumeEvent();

      case AlarmActivationInsideRadius(
        :final alarmName,
        :final distance,
        :final radius,
      ):
        notifier.consumeEvent();
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Already inside alarm area'),
            content: Text(
              'You are ${formatDistance(distance)} from "$alarmName". '
              'Move outside the ${formatDistance(radius)} radius to activate.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

      case AlarmActivationGpsDisabled():
        notifier.consumeEvent();
        if (!mounted) return;
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

      case AlarmActivationError(:final message):
        _showSnackBar(message);
        notifier.consumeEvent();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final activationState = ref.watch(alarmActivationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Pre-warm GPS so location is cached when user opens the map screen.
    ref.watch(locationProvider);

    // React to activation events.
    ref.listen(alarmActivationProvider, (_, next) {
      if (next.lastEvent is! AlarmActivationIdle) {
        _onActivationEvent(next.lastEvent);
      }
    });

    // React to delete events.
    ref.listen(alarmDeleteProvider, (_, next) {
      switch (next) {
        case AlarmDeleteSuccess(:final count):
          _exitEditMode();
          _showSnackBar('$count alarm${count > 1 ? 's' : ''} deleted');
          ref.read(alarmDeleteProvider.notifier).reset();
        case AlarmDeleteError(:final message):
          _showSnackBar('Delete failed: $message');
          ref.read(alarmDeleteProvider.notifier).reset();
        case AlarmDeleteIdle():
          break;
      }
    });

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
                    onPressed: _selectedIds.isNotEmpty
                        ? _confirmDeleteSelected
                        : null,
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
          error: (_, _) => AlarmListErrorState(
            onRetry: () => ref.invalidate(alarmsProvider),
          ),
          data: (alarms) {
            if (alarms.isEmpty) return const AlarmListEmptyState();

            final sorted = _sortAlarms(alarms);
            final hasActive = alarms.any((a) => a.active);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              child: Column(
                spacing: 16,
                children: [
                  ServiceHealthBanner(hasActiveAlarms: hasActive),
                  for (final alarm in sorted)
                    AlarmCard(
                      key: ValueKey(alarm.id),
                      alarm: alarm,
                      activating: activationState.activatingIds.contains(
                        alarm.id,
                      ),
                      selected: _selectedIds.contains(alarm.id),
                      editMode: _editMode,
                      onTap: _editMode
                          ? () => _toggleSelection(alarm.id!)
                          : () => context.push('/edit/${alarm.id}'),
                      onLongPress: _editMode
                          ? null
                          : () => _enterEditMode(alarm.id!),
                      onToggle: (active) {
                        final notifier = ref.read(
                          alarmActivationProvider.notifier,
                        );
                        if (active) {
                          notifier.activate(alarm);
                        } else {
                          notifier.deactivate(alarm);
                        }
                      },
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
                tooltip: 'Create alarm',
                onPressed: () => context.push('/create'),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
