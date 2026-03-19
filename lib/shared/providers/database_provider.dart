import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});
