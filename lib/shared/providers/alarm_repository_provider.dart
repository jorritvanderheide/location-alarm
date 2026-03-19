import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/repositories/alarm_repository.dart';
import 'package:location_alarm/shared/providers/database_provider.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository(ref.watch(databaseProvider));
});
