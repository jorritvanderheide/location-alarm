import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:there_yet/shared/data/repositories/alarm_repository.dart';
import 'package:there_yet/shared/providers/database_provider.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(ref.watch(databaseProvider));
});
