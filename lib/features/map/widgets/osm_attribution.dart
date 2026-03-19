import 'package:flutter/material.dart';

class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key, required this.bottomOffset});

  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      bottom: bottomOffset + 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '\u00a9 OpenStreetMap contributors',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.black54),
        ),
      ),
    );
  }
}
