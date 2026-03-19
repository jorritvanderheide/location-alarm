import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/features/map/providers/alarm_mode_provider.dart';
import 'package:location_alarm/features/map/providers/alarm_pin_provider.dart';
import 'package:location_alarm/features/map/widgets/alarm_mode_selector.dart';
import 'package:location_alarm/features/proximity_alarm/widgets/proximity_alarm_form.dart';
import 'package:location_alarm/features/departure_alarm/widgets/departure_alarm_form.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/features/map/providers/save_alarm_provider.dart';
import 'package:location_alarm/features/map/widgets/saved_alarms_list.dart';

class AlarmBottomSheet extends ConsumerStatefulWidget {
  const AlarmBottomSheet({
    super.key,
    this.onSheetHeightChanged,
    this.mapController,
  });

  final ValueChanged<double>? onSheetHeightChanged;
  final MapController? mapController;

  @override
  ConsumerState<AlarmBottomSheet> createState() => _AlarmBottomSheetState();
}

class _AlarmBottomSheetState extends ConsumerState<AlarmBottomSheet> {
  final _key = GlobalKey();
  double _lastReportedHeight = 0;

  void _reportHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkHeight();
    });
  }

  Future<bool> _ensurePermissions(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(locationPermissionProvider.notifier);

    // Request notification permission (shows system dialog)
    await notifier.requestNotification();

    // Check if background location is already granted
    final bgStatus = await Permission.locationAlways.status;
    if (bgStatus.isGranted) return true;

    if (!context.mounted) return false;

    // Show explanation dialog before requesting background location
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background location'),
        content: const Text(
          'To monitor your alarm while the app is closed, '
          'Location Alarm needs "Allow all the time" location access. '
          'On the next screen, select "Allow all the time".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed != true) return false;

    await notifier.requestBackground();
    final result = await Permission.locationAlways.status;
    return result.isGranted;
  }

  void _checkHeight() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height != _lastReportedHeight) {
      _lastReportedHeight = box.size.height;
      widget.onSheetHeightChanged?.call(box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(alarmModeProvider);
    final hasPin = ref.watch(alarmPinProvider) != null;

    _reportHeight();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _reportHeight();
          return true;
        },
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: SizeChangedLayoutNotifier(
            child: Container(
              key: _key,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const AlarmModeSelector(),
                  const SizedBox(height: 16),
                  if (!hasPin)
                    Text(
                      'Tap the map to place an alarm',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    switch (mode) {
                      AlarmMode.proximity => const ProximityAlarmForm(),
                      AlarmMode.departure => const DepartureAlarmForm(),
                    },
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final permissionsGranted = await _ensurePermissions(
                          context,
                          ref,
                        );
                        if (!permissionsGranted || !context.mounted) return;

                        final saved = await ref
                            .read(saveAlarmProvider.notifier)
                            .save();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved ? 'Alarm saved' : 'Failed to save alarm',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.alarm_add),
                      label: const Text('Save Alarm'),
                    ),
                  ],
                  SavedAlarmsList(mapController: widget.mapController),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
