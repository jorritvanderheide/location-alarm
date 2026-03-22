import 'package:flutter/material.dart';
import 'package:location_alarm/features/alarm_map/widgets/radius_slider.dart';

class AlarmSettingsSheet extends StatelessWidget {
  const AlarmSettingsSheet({
    super.key,
    required this.labelController,
    required this.labelFocusNode,
    required this.radius,
    required this.onRadiusChanged,
    required this.onSave,
    required this.saving,
    this.canSave = true,
    this.radiusEnabled = true,
    this.onHeightChanged,
  });

  final TextEditingController labelController;
  final FocusNode labelFocusNode;
  final double radius;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onSave;
  final bool saving;
  final bool canSave;
  final bool radiusEnabled;
  final ValueChanged<double>? onHeightChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final liftForKeyboard = labelFocusNode.hasFocus && keyboardHeight > 0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: liftForKeyboard ? keyboardHeight : 0),
      child: _MeasuredBox(
        onHeightChanged: onHeightChanged,
        child: BottomSheet(
          onClosing: () {},
          enableDrag: false,
          showDragHandle: false,
          builder: (context) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              liftForKeyboard ? 16 : bottomPadding + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: labelController,
                  focusNode: labelFocusNode,
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: radiusEnabled ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !radiusEnabled,
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(28),
                      color: colorScheme.surfaceContainerHigh,
                      child: RadiusSlider(
                        radius: radius,
                        onChanged: onRadiusChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving || !canSave ? null : onSave,
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasuredBox extends StatefulWidget {
  const _MeasuredBox({required this.child, this.onHeightChanged});

  final Widget child;
  final ValueChanged<double>? onHeightChanged;

  @override
  State<_MeasuredBox> createState() => _MeasuredBoxState();
}

class _MeasuredBoxState extends State<_MeasuredBox> {
  final _key = GlobalKey();
  double _lastHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_MeasuredBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final height = box.size.height;
    if (height != _lastHeight) {
      _lastHeight = height;
      widget.onHeightChanged?.call(height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _key, child: widget.child);
  }
}
