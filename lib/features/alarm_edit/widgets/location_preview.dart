import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';

class LocationPreview extends StatelessWidget {
  const LocationPreview({
    super.key,
    this.location,
    this.thumbnail,
    this.mode = AlarmMode.proximity,
    required this.onTap,
  });

  final ({double latitude, double longitude})? location;
  final Uint8List? thumbnail;
  final AlarmMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Semantics(
          label: location != null
              ? 'Selected location, tap to change'
              : 'Tap to pick a location',
          button: true,
          child: Material(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: AspectRatio(
                aspectRatio: 2,
                child: thumbnail != null
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(thumbnail!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to pick location',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
