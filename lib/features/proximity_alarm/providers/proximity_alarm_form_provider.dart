import 'package:flutter_riverpod/flutter_riverpod.dart';

final proximityRadiusProvider =
    NotifierProvider<ProximityRadiusNotifier, double>(
      ProximityRadiusNotifier.new,
    );

class ProximityRadiusNotifier extends Notifier<double> {
  @override
  double build() => 500;

  void set(double radius) => state = radius.clamp(100, 5000);
}
