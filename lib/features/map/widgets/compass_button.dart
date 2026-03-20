import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class CompassButton extends StatelessWidget {
  const CompassButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapEvent>(
      stream: mapController.mapEventStream,
      builder: (context, _) {
        final rotation = mapController.camera.rotation;
        final isNorth = rotation.abs() < 0.5;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            opacity: isNorth ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: isNorth
                ? const SizedBox.shrink()
                : FloatingActionButton.small(
                    heroTag: 'compass',
                    elevation: 6,
                    onPressed: () => mapController.rotate(0),
                    child: Transform.rotate(
                      angle: rotation * pi / 180,
                      child: const Icon(Icons.navigation),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
