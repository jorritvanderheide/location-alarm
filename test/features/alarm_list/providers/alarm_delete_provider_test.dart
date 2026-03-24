import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/features/alarm_list/providers/alarm_delete_provider.dart';
import 'package:there_yet/shared/data/database/app_database.dart';
import 'package:there_yet/shared/data/models/alarm.dart';
import 'package:there_yet/shared/providers/alarm_repository_provider.dart';
import 'package:there_yet/shared/providers/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  group('AlarmDeleteProvider', () {
    test('starts idle', () {
      final state = container.read(alarmDeleteProvider);
      expect(state, isA<AlarmDeleteIdle>());
    });

    test('deletes alarms and transitions to success', () async {
      // Note: AlarmThumbnail.delete may fail in tests (no path_provider)
      // but the AlarmDeleteNotifier catches exceptions from thumbnail
      // deletion. The DB delete still succeeds.
      final repo = container.read(alarmRepositoryProvider);
      final id1 = await repo.save(
        const AlarmData(
          name: 'A',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      final id2 = await repo.save(
        const AlarmData(
          name: 'B',
          location: LatLng(52.0, 6.0),
          active: true,
          radius: 500,
        ),
      );

      await container.read(alarmDeleteProvider.notifier).deleteAlarms({
        id1,
        id2,
      });

      final state = container.read(alarmDeleteProvider);
      expect(state, isA<AlarmDeleteSuccess>());
      expect((state as AlarmDeleteSuccess).count, 2);
      expect(await repo.getById(id1), isNull);
      expect(await repo.getById(id2), isNull);
    });

    test('reset returns to idle', () async {
      final notifier = container.read(alarmDeleteProvider.notifier);
      final repo = container.read(alarmRepositoryProvider);
      final id = await repo.save(
        const AlarmData(
          name: 'C',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );

      await notifier.deleteAlarms({id});
      notifier.reset();
      expect(container.read(alarmDeleteProvider), isA<AlarmDeleteIdle>());
    });
  });
}
