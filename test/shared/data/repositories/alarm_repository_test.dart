import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/shared/data/database/app_database.dart';
import 'package:there_yet/shared/data/models/alarm.dart';
import 'package:there_yet/shared/data/repositories/alarm_repository.dart';

AppDatabase _openTestDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory()));

void main() {
  late AppDatabase db;
  late AlarmRepository repo;

  setUp(() {
    db = _openTestDb();
    repo = AlarmRepository(db);
  });

  tearDown(() => db.close());

  group('save', () {
    test('inserts a new alarm and returns its ID', () async {
      const alarm = AlarmData(
        name: 'Test',
        location: LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      final id = await repo.save(alarm);
      expect(id, greaterThan(0));
    });

    test('updates an existing alarm', () async {
      const alarm = AlarmData(
        name: 'Original',
        location: LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      final id = await repo.save(alarm);
      final updated = AlarmData(
        id: id,
        name: 'Updated',
        location: const LatLng(52.0, 6.0),
        active: false,
        radius: 1000,
      );
      await repo.save(updated);

      final result = await repo.getById(id);
      expect(result, isNotNull);
      expect(result!.name, 'Updated');
      expect(result.radius, 1000);
      expect(result.active, false);
    });
  });

  group('getById', () {
    test('returns null for non-existent ID', () async {
      final result = await repo.getById(999);
      expect(result, isNull);
    });

    test('returns the alarm with matching ID', () async {
      const alarm = AlarmData(
        name: 'Find me',
        location: LatLng(51.0, 5.0),
        active: true,
        radius: 300,
      );
      final id = await repo.save(alarm);
      final result = await repo.getById(id);
      expect(result, isNotNull);
      expect(result!.name, 'Find me');
      expect(result.radius, 300);
    });
  });

  group('getActive', () {
    test('returns only active alarms', () async {
      await repo.save(
        const AlarmData(
          name: 'Active',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      await repo.save(
        const AlarmData(
          name: 'Inactive',
          location: LatLng(52.0, 6.0),
          active: false,
          radius: 500,
        ),
      );
      final active = await repo.getActive();
      expect(active.length, 1);
      expect(active.first.name, 'Active');
    });
  });

  group('delete', () {
    test('removes the alarm', () async {
      final id = await repo.save(
        const AlarmData(
          name: 'Delete me',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      await repo.delete(id);
      final result = await repo.getById(id);
      expect(result, isNull);
    });
  });

  group('toggleActive', () {
    test('toggles alarm active state', () async {
      final id = await repo.save(
        const AlarmData(
          name: 'Toggle',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );

      await repo.toggleActive(id, active: false);
      final result = await repo.getById(id);
      expect(result!.active, false);

      await repo.toggleActive(id, active: true);
      final result2 = await repo.getById(id);
      expect(result2!.active, true);
    });

    test('updates updatedAt timestamp', () async {
      final id = await repo.save(
        const AlarmData(
          name: 'Timestamp',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      final before = await repo.getById(id);
      await Future<void>.delayed(const Duration(seconds: 1));
      await repo.toggleActive(id, active: false);
      final after = await repo.getById(id);

      expect(after!.updatedAt, isNotNull);
      expect(
        after.updatedAt!.millisecondsSinceEpoch,
        greaterThan(before!.updatedAt!.millisecondsSinceEpoch),
      );
    });
  });

  group('watchAll', () {
    test('emits alarm list ordered by createdAt desc', () async {
      await repo.save(
        const AlarmData(
          name: 'First',
          location: LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      await repo.save(
        const AlarmData(
          name: 'Second',
          location: LatLng(52.0, 6.0),
          active: true,
          radius: 500,
        ),
      );

      final alarms = await repo.watchAll().first;
      expect(alarms.length, 2);
      expect(alarms.first.name, 'Second'); // newest first
      expect(alarms.last.name, 'First');
    });
  });

  group('AlarmData equality', () {
    test('equal alarms have same hashCode', () {
      const a = AlarmData(
        id: 1,
        name: 'Test',
        location: LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      const b = AlarmData(
        id: 1,
        name: 'Test',
        location: LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different alarms are not equal', () {
      const a = AlarmData(
        id: 1,
        name: 'Test',
        location: LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      const b = AlarmData(
        id: 2,
        name: 'Other',
        location: LatLng(52.0, 6.0),
        active: false,
        radius: 1000,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
