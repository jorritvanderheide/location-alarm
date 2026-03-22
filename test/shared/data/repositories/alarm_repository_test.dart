import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/database/app_database.dart';
import 'package:location_alarm/shared/data/models/alarm.dart';
import 'package:location_alarm/shared/data/repositories/alarm_repository.dart';

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
      final alarm = AlarmData(
        name: 'Test',
        location: const LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      final id = await repo.save(alarm);
      expect(id, greaterThan(0));
    });

    test('updates an existing alarm', () async {
      final alarm = AlarmData(
        name: 'Original',
        location: const LatLng(51.0, 5.0),
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
      final alarm = AlarmData(
        name: 'Find me',
        location: const LatLng(51.0, 5.0),
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
        AlarmData(
          name: 'Active',
          location: const LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      await repo.save(
        AlarmData(
          name: 'Inactive',
          location: const LatLng(52.0, 6.0),
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
        AlarmData(
          name: 'Delete me',
          location: const LatLng(51.0, 5.0),
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
        AlarmData(
          name: 'Toggle',
          location: const LatLng(51.0, 5.0),
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
        AlarmData(
          name: 'Timestamp',
          location: const LatLng(51.0, 5.0),
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
        AlarmData(
          name: 'First',
          location: const LatLng(51.0, 5.0),
          active: true,
          radius: 500,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      await repo.save(
        AlarmData(
          name: 'Second',
          location: const LatLng(52.0, 6.0),
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
      final a = AlarmData(
        id: 1,
        name: 'Test',
        location: const LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      final b = AlarmData(
        id: 1,
        name: 'Test',
        location: const LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different alarms are not equal', () {
      final a = AlarmData(
        id: 1,
        name: 'Test',
        location: const LatLng(51.0, 5.0),
        active: true,
        radius: 500,
      );
      final b = AlarmData(
        id: 2,
        name: 'Other',
        location: const LatLng(52.0, 6.0),
        active: false,
        radius: 1000,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
