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
import 'package:location_alarm/l10n/app_localizations.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/widgets/permission_dialogs.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/providers/alarms_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

enum AlarmSortMode { created, name }

class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen> {
  AlarmSortMode _sortMode = AlarmSortMode.created;

  bool _editMode = false;
  final Set<int> _selectedIds = {};

  String _sortLabel(AlarmSortMode mode) {
    final l10n = AppLocalizations.of(context)!;
    return switch (mode) {
      AlarmSortMode.created => l10n.sortDateCreated,
      AlarmSortMode.name => l10n.sortName,
    };
  }

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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.sortBy,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final mode in AlarmSortMode.values)
            ListTile(
              title: Text(_sortLabel(mode)),
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

  Future<void> _confirmDeleteSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNAlarms(count)),
        content: Text(l10n.deleteNAlarmsBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(alarmDeleteProvider.notifier).deleteAlarms(_selectedIds);
  }

  Future<void> _onActivationEvent(AlarmActivationEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(alarmActivationProvider.notifier);

    switch (event) {
      case AlarmActivationIdle():
        break;

      case AlarmDeactivated(:final alarmName):
        _showSnackBar(l10n.alarmDeactivated(alarmName));
        notifier.consumeEvent();

      case AlarmActivated(:final alarmName, :final distance):
        _showSnackBar(l10n.alarmActivated(alarmName, formatDistance(distance)));
        notifier.consumeEvent();

      case AlarmActivationNeedsForeground():
        _showSnackBar(l10n.locationPermissionRequired);
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
        _showSnackBar(l10n.notificationsDisabled);
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
            title: Text(l10n.alreadyInsideAlarmArea),
            content: Text(
              l10n.alreadyInsideAlarmAreaBody(
                formatDistance(distance),
                alarmName,
                formatDistance(radius),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );

      case AlarmActivationGpsDisabled():
        notifier.consumeEvent();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gpsDisabled),
            action: SnackBarAction(
              label: l10n.openSettings,
              onPressed: Geolocator.openLocationSettings,
            ),
            duration: const Duration(seconds: 6),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alarmsAsync = ref.watch(alarmsProvider);
    final activationState = ref.watch(alarmActivationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Pre-warm GPS so the map opens fast.
    ref.watch(bestPositionProvider);

    ref.listen(alarmActivationProvider, (_, next) {
      if (next.lastEvent is! AlarmActivationIdle) {
        _onActivationEvent(next.lastEvent);
      }
    });

    ref.listen(alarmDeleteProvider, (_, next) {
      switch (next) {
        case AlarmDeleteSuccess(:final count):
          _exitEditMode();
          _showSnackBar(l10n.nAlarmsDeleted(count));
          ref.read(alarmDeleteProvider.notifier).reset();
        case AlarmDeleteError(:final message):
          _showSnackBar(l10n.deleteFailed(message));
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
                title: Text(l10n.nSelected(_selectedIds.length)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.deleteSelected,
                    onPressed: _selectedIds.isNotEmpty
                        ? _confirmDeleteSelected
                        : null,
                  ),
                ],
              )
            : AppBar(
                title: Text(l10n.alarmsTitle),
                actions: [
                  IconButton(
                    icon: _sortMode != AlarmSortMode.created
                        ? Icon(Icons.sort, color: colorScheme.primary)
                        : const Icon(Icons.sort),
                    tooltip: l10n.sortAlarms,
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
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: const Icon(Icons.settings),
                          title: Text(l10n.settings),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'about',
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l10n.about),
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
                tooltip: l10n.createAlarm,
                onPressed: () => context.push('/create'),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
