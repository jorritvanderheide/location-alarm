import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_edit/widgets/location_preview.dart';
import 'package:location_alarm/features/map_picker/screens/map_picker_screen.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, this.alarmId});

  final int? alarmId;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  bool _isNew = true;
  bool _loaded = false;
  bool _saving = false;
  bool _saveAttempted = false;

  late TextEditingController _labelController;
  LatLng? _location;
  double _radius = 500;
  Uint8List? _thumbnail;
  bool _wasActive = true;

  // Initial values for unsaved-changes detection.
  String _initialLabel = '';
  LatLng? _initialLocation;
  double _initialRadius = 500;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _labelController.addListener(() => setState(() {}));
    _isNew = widget.alarmId == null;
    if (!_isNew) {
      _loadAlarm();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (!_loaded) return false;
    return _labelController.text != _initialLabel ||
        _location != _initialLocation ||
        _radius != _initialRadius;
  }

  Future<void> _loadAlarm() async {
    try {
      final repo = ref.read(alarmRepositoryProvider);
      final alarms = await repo.watchAll().first;
      final alarm = alarms.where((a) => a.id == widget.alarmId).firstOrNull;
      if (alarm == null) {
        if (mounted) context.pop();
        return;
      }

      // Load saved thumbnail (non-critical)
      try {
        final file = await AlarmThumbnail.get(widget.alarmId!);
        if (file != null) {
          _thumbnail = await file.readAsBytes();
        }
      } on Exception {
        // Thumbnail load failure is non-critical
      }

      if (!mounted) return;

      setState(() {
        _labelController.text = alarm.name;
        _location = alarm.location;
        _wasActive = alarm.active;
        _radius = alarm.radius;
        _initialLabel = alarm.name;
        _initialLocation = alarm.location;
        _initialRadius = alarm.radius;
        _loaded = true;
      });
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load alarm')));
        context.pop();
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saveAttempted = true);

    if (_location == null) {
      return;
    }
    setState(() => _saving = true);

    try {
      await _performSave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _performSave() async {
    final permNotifier = ref.read(locationPermissionProvider.notifier);
    final bgGranted = await permNotifier.requestBackground();
    if (!mounted) return;

    if (!bgGranted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Background location required'),
          content: const Text(
            'Without background location permission, the alarm will not '
            'trigger. You can grant it later in system settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    await permNotifier.requestNotification();
    if (!mounted) return;

    final repo = ref.read(alarmRepositoryProvider);

    final position = ref.read(locationProvider).whenData((p) => p).value;
    final hasLocationLock = position != null;
    final isInsideRadius =
        hasLocationLock &&
        distanceInMeters(
              LatLng(position.latitude, position.longitude),
              _location!,
            ) <=
            _radius;

    // Show dialog before saving if user is inside the radius.
    if (isInsideRadius) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inside alarm area'),
          content: const Text(
            'You are currently inside this alarm area. The alarm will be '
            'saved inactive and activate once you leave.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save inactive'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final active = (!hasLocationLock || isInsideRadius) ? false : _wasActive;
    final alarm = AlarmData(
      id: widget.alarmId,
      name: _labelController.text,
      location: _location!,
      active: active,
      radius: _radius,
    );

    // Save thumbnail before DB write for existing alarms,
    // so the card shows the updated thumbnail when the stream emits
    if (_thumbnail != null && widget.alarmId != null) {
      try {
        await AlarmThumbnail.save(widget.alarmId!, _thumbnail!);
      } on Exception {
        // non-critical
      }
    }

    final alarmId = await repo.save(alarm);

    // Save thumbnail after DB write for new alarms (need the generated ID)
    if (_thumbnail != null && widget.alarmId == null) {
      try {
        await AlarmThumbnail.save(alarmId, _thumbnail!);
      } on Exception {
        // non-critical
      }
    }

    if (!mounted) return;

    final label = _labelController.text.isEmpty
        ? 'Alarm'
        : _labelController.text;

    final String message;
    if (!bgGranted) {
      message = '$label saved — enable background location to monitor';
    } else if (!hasLocationLock) {
      message = '$label saved (inactive — no GPS lock)';
    } else if (isInsideRadius) {
      message = '$label saved (inactive)';
    } else {
      message = '$label saved';
    }

    context.pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete() async {
    if (widget.alarmId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alarm?'),
        content: const Text('This alarm will be permanently removed.'),
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

    await ref.read(alarmRepositoryProvider).delete(widget.alarmId!);
    await AlarmThumbnail.delete(widget.alarmId!);
    if (mounted) context.pop();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<MapPickerResult>(
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLocation: _location, initialRadius: _radius),
      ),
    );
    if (result != null) {
      setState(() {
        _location = result.location;
        _thumbnail = result.thumbnail;
        _radius = result.radius;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = _isNew
        ? 'New alarm'
        : (_labelController.text.isEmpty
              ? 'Edit alarm'
              : _labelController.text);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your unsaved changes will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard != true || !mounted) return;
        if (context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
              controller: _labelController,
            ),
            const SizedBox(height: 24),
            LocationPreview(
              location: _location != null
                  ? (
                      latitude: _location!.latitude,
                      longitude: _location!.longitude,
                    )
                  : null,
              thumbnail: _thumbnail,
              hasError: _saveAttempted && _location == null,
              onTap: _pickLocation,
            ),
            if (_location != null) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _pickLocation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Radius: ${_radius.round()} m',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!_isNew) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete alarm'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
