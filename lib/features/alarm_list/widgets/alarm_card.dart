import 'dart:io';
import 'package:flutter/material.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

class AlarmCard extends StatefulWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    this.onLongPress,
    required this.onToggle,
    this.activating = false,
    this.selected = false,
    this.editMode = false,
  });

  final AlarmData alarm;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool> onToggle;
  final bool activating;
  final bool selected;
  final bool editMode;

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
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
      _loadThumbnail(evict: true);
    }
  }

  Future<void> _loadThumbnail({bool evict = false}) async {
    if (widget.alarm.id == null) return;
    final file = await AlarmThumbnail.get(widget.alarm.id!);
    if (file != null && evict) {
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

    final hasLocation = widget.alarm.locationName.isNotEmpty;
    final subtitle = hasLocation
        ? '${widget.alarm.locationName} · ${formatDistance(widget.alarm.radius)}'
        : '${formatDistance(widget.alarm.radius)} radius';
    final title = widget.alarm.name.isEmpty
        ? 'Alarm #${widget.alarm.id}'
        : widget.alarm.name;

    final cardWidth = MediaQuery.of(context).size.width - 32;
    final thumbSize = cardWidth * 2 / 5;

    final Color? cardColor;
    if (widget.selected) {
      cardColor = colorScheme.primaryContainer;
    } else if (widget.alarm.active) {
      cardColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
    } else {
      cardColor = null;
    }

    return SizedBox(
      height: thumbSize,
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: cardColor,
        child: InkWell(
          onTap: widget.activating ? null : widget.onTap,
          onLongPress: widget.activating ? null : widget.onLongPress,
          child: Row(
            children: [
              SizedBox(
                width: thumbSize,
                child: _thumbnailFile != null
                    ? Image.file(
                        _thumbnailFile!,
                        key: ValueKey(_thumbnailVersion),
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: widget.alarm.active
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              height: 1.2,
                              color: widget.alarm.active
                                  ? null
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: widget.editMode
                            ? Icon(
                                widget.selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: widget.selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              )
                            : widget.activating
                            ? Semantics(
                                label: '$title, getting location',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Getting location\u2026',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
