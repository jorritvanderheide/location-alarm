import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';

class AlarmCard extends ConsumerStatefulWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    this.activating = false,
  });

  final AlarmData alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
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

    final subtitle = '${widget.alarm.radius.round()} m radius';
    final title = widget.alarm.name.isEmpty
        ? 'Alarm #${widget.alarm.id}'
        : widget.alarm.name;

    final cardWidth = MediaQuery.of(context).size.width - 32;
    final thumbSize = cardWidth * 2 / 5;

    return SizedBox(
      height: thumbSize,
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: widget.alarm.active
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : null,
        child: InkWell(
          onTap: widget.activating ? null : widget.onTap,
          child: Row(
            children: [
              SizedBox(
                width: thumbSize,
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
                                Icons.notifications,
                                size: 24,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.notifications,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: widget.activating
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
