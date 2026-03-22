import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class CompassButton extends StatefulWidget {
  const CompassButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  State<CompassButton> createState() => _CompassButtonState();
}

class _CompassButtonState extends State<CompassButton>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  Timer? _hideTimer;
  StreamSubscription<MapEvent>? _mapEventSub;

  @override
  void initState() {
    super.initState();
    _mapEventSub = widget.mapController.mapEventStream.listen((_) {
      _onRotationChanged();
    });
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onRotationChanged() {
    final isNorth = widget.mapController.camera.rotation.abs() < 0.5;

    if (!isNorth && !_visible) {
      _hideTimer?.cancel();
      setState(() => _visible = true);
    } else if (isNorth && _visible) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  void _animateToNorth() {
    final startRotation = widget.mapController.camera.rotation;
    if (startRotation.abs() < 0.5) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    controller.addListener(() {
      if (!mounted) return;
      final t = Curves.easeOut.transform(controller.value);
      widget.mapController.rotate(startRotation * (1 - t));
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final rotation = widget.mapController.camera.rotation;

    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.small(
          heroTag: 'compass',
          elevation: 2,
          tooltip: 'Reset north',
          onPressed: _animateToNorth,
          child: Transform.rotate(
            angle: -rotation * pi / 180,
            child: const Icon(Icons.navigation),
          ),
        ),
      ),
    );
  }
}
