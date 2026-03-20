import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/features/alarm_edit/widgets/alarm_type_selector.dart';
import 'package:location_alarm/features/alarm_edit/widgets/departure_settings.dart';
import 'package:location_alarm/features/alarm_edit/widgets/location_preview.dart';
import 'package:location_alarm/features/map_picker/screens/map_picker_screen.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/departure_calculator.dart';
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

  AlarmMode _mode = AlarmMode.proximity;
  late TextEditingController _labelController;
  LatLng? _location;
  double _radius = 500;
  TravelMode _travelMode = TravelMode.walk;
  int _bufferMinutes = 5;
  DateTime? _arrivalTime;
  Uint8List? _thumbnail;
  bool _wasActive = true;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
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

  Future<void> _loadAlarm() async {
    final repo = ref.read(alarmRepositoryProvider);
    final alarms = await repo.watchAll().first;
    final alarm = alarms.where((a) => a.id == widget.alarmId).firstOrNull;
    if (alarm == null) {
      if (mounted) context.pop();
      return;
    }

    // Load saved thumbnail
    final file = await AlarmThumbnail.get(widget.alarmId!);
    if (file != null) {
      _thumbnail = await file.readAsBytes();
    }

    if (!mounted) return;

    setState(() {
      _labelController.text = alarm.name;
      _location = alarm.location;
      _wasActive = alarm.active;
      switch (alarm) {
        case ProximityAlarmData(:final radius):
          _mode = AlarmMode.proximity;
          _radius = radius;
        case DepartureAlarmData(
          :final travelMode,
          :final bufferMinutes,
          :final arrivalTime,
        ):
          _mode = AlarmMode.departure;
          _travelMode = travelMode;
          _bufferMinutes = bufferMinutes;
          _arrivalTime = arrivalTime;
      }
      _loaded = true;
    });
  }

  Future<void> _save() async {
    // Validate first — before any async permission work
    if (_location == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a location')));
      return;
    }
    if (_mode == AlarmMode.departure && _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set an arrival time')),
      );
      return;
    }

    // Request permissions needed for alarm monitoring
    final permNotifier = ref.read(locationPermissionProvider.notifier);
    await permNotifier.requestBackground();
    if (!mounted) return;
    await permNotifier.requestNotification();
    if (!mounted) return;

    final repo = ref.read(alarmRepositoryProvider);

    final isInsideRadius =
        _isNew &&
        _mode == AlarmMode.proximity &&
        _isInsideProximity(_location!, _radius);
    final active = isInsideRadius ? false : _wasActive;
    final alarm = switch (_mode) {
      AlarmMode.proximity => ProximityAlarmData(
        id: widget.alarmId,
        name: _labelController.text,
        location: _location!,
        active: active,
        radius: _radius,
      ),
      AlarmMode.departure => DepartureAlarmData(
        id: widget.alarmId,
        name: _labelController.text,
        location: _location!,
        active: _wasActive,
        travelMode: _travelMode,
        bufferMinutes: _bufferMinutes,
        arrivalTime: _arrivalTime!,
      ),
    };

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
        ? (_mode == AlarmMode.proximity ? 'Proximity alarm' : 'Departure alarm')
        : _labelController.text;

    final message = switch (alarm) {
      DepartureAlarmData() => _departureMessage(alarm) ?? '$label saved',
      ProximityAlarmData() =>
        isInsideRadius
            ? '$label saved (inactive — you are in the alarm area)'
            : '$label saved',
    };

    // Pop first, then show snackbar on the parent scaffold
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

  bool _isInsideProximity(LatLng target, double radius) {
    final locationAsync = ref.read(locationProvider);
    final position = locationAsync.whenData((p) => p).value;
    if (position == null) return false;

    final distance = distanceInMeters(
      LatLng(position.latitude, position.longitude),
      target,
    );
    return distance <= radius;
  }

  String? _departureMessage(DepartureAlarmData alarm) {
    final locationAsync = ref.read(locationProvider);
    final position = locationAsync.whenData((p) => p).value;
    if (position == null) return null;

    final info = calculateDeparture(
      currentPosition: LatLng(position.latitude, position.longitude),
      destination: alarm.location,
      travelMode: alarm.travelMode,
      bufferMinutes: alarm.bufferMinutes,
      arrivalTime: alarm.arrivalTime,
    );
    if (info == null) return null;

    return formatDepartureInfo(info, context);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<MapPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: _location,
          initialRadius: _mode == AlarmMode.proximity ? _radius : null,
          mode: _mode,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _location = result.location;
        _thumbnail = result.thumbnail;
        if (result.radius != null) {
          _radius = result.radius!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final modeLabel = switch (_mode) {
      AlarmMode.proximity => 'Proximity alarm',
      AlarmMode.departure => 'Departure alarm',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New alarm' : modeLabel),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isNew) ...[
            AlarmTypeSelector(
              selected: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: 24),
          ],
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
            onTap: _pickLocation,
          ),
          if (_mode == AlarmMode.proximity && _location != null) ...[
            const SizedBox(height: 8),
            Text(
              'Radius: ${_radius.round()} m',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_mode == AlarmMode.departure) ...[
            const SizedBox(height: 24),
            DepartureSettings(
              travelMode: _travelMode,
              bufferMinutes: _bufferMinutes,
              arrivalTime: _arrivalTime,
              onTravelModeChanged: (m) => setState(() => _travelMode = m),
              onBufferChanged: (b) => setState(() => _bufferMinutes = b),
              onArrivalTimeChanged: (t) => setState(() => _arrivalTime = t),
            ),
          ],
          const SizedBox(height: 16),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.volume_up),
            title: Text('Sound'),
            subtitle: Text('Default alarm'),
            trailing: Icon(Icons.chevron_right),
            enabled: false,
          ),
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
    );
  }
}
