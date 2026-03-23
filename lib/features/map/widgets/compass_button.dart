import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location_alarm/l10n/app_localizations.dart';

class CompassButton extends StatefulWidget {
  const CompassButton({super.key, required this.mapController});

  final MapController mapController;

  @override
  State<CompassButton> createState() => _CompassButtonState();
}

class _CompassButtonState extends State<CompassButton>
    with TickerProviderStateMixin {
  bool _visible = false;
  Timer? _hideTimer;
  StreamSubscription<MapEvent>? _mapEventSub;
  AnimationController? _rotateController;

  @override
  void initState() {
    super.initState();
    _mapEventSub = widget.mapController.mapEventStream.listen((_) {
      _onRotationChanged();
      if (_visible && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _hideTimer?.cancel();
    _rotateController?.dispose();
    super.dispose();
  }

  void _onRotationChanged() {
    final isNorth = widget.mapController.camera.rotation.abs() < 0.5;

    if (!isNorth && !_visible) {
      _hideTimer?.cancel();
      _visible = true;
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

    _rotateController?.dispose();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateController!.addListener(() {
      if (!mounted) return;
      final t = Curves.easeOut.transform(_rotateController!.value);
      widget.mapController.rotate(startRotation * (1 - t));
    });

    _rotateController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _rotateController?.dispose();
        _rotateController = null;
      }
    });

    _rotateController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rotation = widget.mapController.camera.rotation;

    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.small(
          heroTag: 'compass',
          elevation: 2,
          tooltip: l10n.resetNorth,
          onPressed: _animateToNorth,
          child: Transform.rotate(
            angle: rotation.abs() < 0.5 ? 0 : rotation * pi / 180,
            child: const Icon(Icons.navigation),
          ),
        ),
      ),
    );
  }
}
