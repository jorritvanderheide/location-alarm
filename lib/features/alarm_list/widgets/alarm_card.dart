import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/departure_calculator.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class AlarmCard extends ConsumerStatefulWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    this.onLongPress,
    this.selected = false,
    this.editMode = false,
    this.activating = false,
  });

  final AlarmData alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool editMode;
  final bool activating;

  @override
  ConsumerState<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends ConsumerState<AlarmCard> {
  File? _thumbnailFile;
  int _thumbnailVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(AlarmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alarm != widget.alarm) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.alarm.id == null) return;
    final file = await AlarmThumbnail.get(widget.alarm.id!);
    if (file != null) {
      final provider = FileImage(file);
      await provider.evict();
    }
    if (mounted) {
      setState(() {
        _thumbnailFile = file;
        _thumbnailVersion++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, subtitle) = switch (widget.alarm) {
      ProximityAlarmData(:final radius) => (
        Icons.notifications,
        '${radius.round()} m radius',
      ),
      DepartureAlarmData(
        :final travelMode,
        :final bufferMinutes,
        :final arrivalTime,
      ) =>
        (
          switch (travelMode) {
            TravelMode.walk => Icons.directions_walk,
            TravelMode.cycle => Icons.directions_bike,
            TravelMode.drive => Icons.directions_car,
          },
          _departureSubtitle(context, travelMode, bufferMinutes, arrivalTime),
        ),
    };

    final alarmTime = switch (widget.alarm) {
      DepartureAlarmData() when widget.alarm.active => _departureTime(
        widget.alarm as DepartureAlarmData,
      ),
      _ => null,
    };

    final title = widget.alarm.name.isEmpty
        ? switch (widget.alarm) {
            ProximityAlarmData() => 'Proximity alarm',
            DepartureAlarmData() => 'Departure alarm',
          }
        : widget.alarm.name;

    final cardHeight = ((MediaQuery.of(context).size.width - 32) / 2).clamp(
      140.0,
      200.0,
    );

    return Opacity(
      opacity: widget.alarm.active ? 1.0 : 0.6,
      child: SizedBox(
        height: cardHeight,
        child: Card.outlined(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: widget.selected ? colorScheme.primaryContainer : null,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _thumbnailFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _thumbnailFile!,
                              key: ValueKey(_thumbnailVersion),
                              fit: BoxFit.cover,
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(
                                    alpha: 0.7,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.alarm is ProximityAlarmData
                                      ? Icons.notifications
                                      : Icons.place,
                                  size: 24,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          icon,
                          color: widget.alarm.active
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: widget.alarm.active
                                    ? null
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        if (alarmTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            alarmTime,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: widget.editMode
                              ? const SizedBox(width: 60, height: 48)
                              : widget.activating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Semantics(
                                  label:
                                      '$title, ${widget.alarm.active ? "active" : "inactive"}',
                                  excludeSemantics: true,
                                  child: Switch(
                                    value: widget.alarm.active,
                                    onChanged: (active) {
                                      widget.onToggle(active);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _departureTime(DepartureAlarmData alarm) {
    final locationAsync = ref.watch(locationProvider);
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

  String _departureSubtitle(
    BuildContext context,
    TravelMode travelMode,
    int bufferMinutes,
    DateTime arrivalTime,
  ) {
    final timeStr = TimeOfDay.fromDateTime(arrivalTime).format(context);
    return 'Arrive by $timeStr · ${travelMode.name} · +$bufferMinutes min';
  }
}
