import 'package:flutter_riverpod/flutter_riverpod.dart';

final bufferMinutesProvider = NotifierProvider<BufferMinutesNotifier, int>(
  BufferMinutesNotifier.new,
);

class BufferMinutesNotifier extends Notifier<int> {
  @override
  int build() => 5;

  void set(int minutes) => state = minutes.clamp(0, 120);
}
