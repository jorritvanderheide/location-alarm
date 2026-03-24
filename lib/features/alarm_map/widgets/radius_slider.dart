import 'package:flutter/material.dart';
import 'package:there_yet/shared/data/geo_utils.dart';

// Fixed radius steps: 25m increments up to 500m, 50m to 1000m,
// 100m to 2000m, 250m to 5000m. ~40 values total.
const List<double> radiusSteps = [
  // 100–500m in 25m steps
  100.0, 125, 150, 175, 200, 225, 250, 275, 300, 325, 350, 375, 400, 425, 450,
  475, 500,
  // 500–1000m in 50m steps
  550.0, 600, 650, 700, 750, 800, 850, 900, 950, 1000,
  // 1000–2000m in 100m steps
  1100.0, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000,
  // 2000–5000m in 250m steps
  2250.0, 2500, 2750, 3000, 3250, 3500, 3750, 4000, 4250, 4500, 4750, 5000,
];

int _radiusToIndex(double radius) {
  var closest = 0;
  var minDiff = (radiusSteps[0] - radius).abs();
  for (var i = 1; i < radiusSteps.length; i++) {
    final diff = (radiusSteps[i] - radius).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = i;
    }
  }
  return closest;
}

/// Alias for backward compatibility. Use [formatDistance] from geo_utils.
String formatRadius(double radius) => formatDistance(radius);

class RadiusSlider extends StatelessWidget {
  const RadiusSlider({
    super.key,
    required this.radius,
    required this.onChanged,
  });

  final double radius;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = _radiusToIndex(radius);

    return Row(
      children: [
        const SizedBox(width: 16),
        Text(
          formatRadius(radius),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Expanded(
          child: Slider(
            value: index.toDouble(),
            min: 0,
            max: (radiusSteps.length - 1).toDouble(),
            divisions: radiusSteps.length - 1,
            semanticFormatterCallback: (_) => '${formatRadius(radius)} radius',
            onChanged: (v) => onChanged(radiusSteps[v.round()]),
          ),
        ),
      ],
    );
  }
}
