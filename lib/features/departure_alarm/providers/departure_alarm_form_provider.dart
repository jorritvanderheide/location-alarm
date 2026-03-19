import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

final travelModeProvider = NotifierProvider<TravelModeNotifier, TravelMode>(
  TravelModeNotifier.new,
);

class TravelModeNotifier extends Notifier<TravelMode> {
  @override
  TravelMode build() => TravelMode.walk;

  void set(TravelMode mode) => state = mode;
}
