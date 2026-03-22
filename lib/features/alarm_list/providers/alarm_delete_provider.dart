import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/alarm_thumbnail.dart';
import 'package:location_alarm/shared/providers/alarm_repository_provider.dart';

final alarmDeleteProvider =
    NotifierProvider<AlarmDeleteNotifier, AlarmDeleteState>(
      AlarmDeleteNotifier.new,
    );

sealed class AlarmDeleteState {
  const AlarmDeleteState();
}

final class AlarmDeleteIdle extends AlarmDeleteState {
  const AlarmDeleteIdle();
}

final class AlarmDeleteSuccess extends AlarmDeleteState {
  const AlarmDeleteSuccess(this.count);
  final int count;
}

final class AlarmDeleteError extends AlarmDeleteState {
  const AlarmDeleteError(this.message);
  final String message;
}

class AlarmDeleteNotifier extends Notifier<AlarmDeleteState> {
  @override
  AlarmDeleteState build() => const AlarmDeleteIdle();

  Future<void> deleteAlarms(Set<int> ids) async {
    try {
      final repo = ref.read(alarmRepositoryProvider);
      await Future.wait(
        ids.map((id) async {
          await repo.delete(id);
          // Thumbnail cleanup is non-critical.
          try {
            await AlarmThumbnail.delete(id);
          } on Exception {
            // ignore
          }
        }),
      );
      state = AlarmDeleteSuccess(ids.length);
    } on Exception catch (e) {
      state = AlarmDeleteError(e.toString());
    }
  }

  void reset() => state = const AlarmDeleteIdle();
}
