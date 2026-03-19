import 'package:flutter_riverpod/flutter_riverpod.dart';

final arrivalTimeProvider = NotifierProvider<ArrivalTimeNotifier, DateTime?>(
  ArrivalTimeNotifier.new,
);

class ArrivalTimeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime time) => state = time;

  void clear() => state = null;
}
