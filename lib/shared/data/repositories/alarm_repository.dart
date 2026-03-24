import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/shared/data/database/app_database.dart' as db;
import 'package:there_yet/shared/data/models/alarm.dart';

class AlarmRepository {
  AlarmRepository(this._db);

  final db.AppDatabase _db;

  Stream<List<AlarmData>> watchAll() {
    final query = _db.select(_db.alarms)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_rowToAlarm).toList());
  }

  Future<AlarmData?> getById(int id) async {
    final query = _db.select(_db.alarms)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToAlarm(row) : null;
  }

  Future<List<AlarmData>> getActive() async {
    final query = _db.select(_db.alarms)..where((t) => t.active.equals(true));
    final rows = await query.get();
    return rows.map(_rowToAlarm).toList();
  }

  Future<int> save(AlarmData alarm) {
    final companion = _alarmToCompanion(alarm);
    if (alarm.id != null) {
      return (_db.update(_db.alarms)..where((t) => t.id.equals(alarm.id!)))
          .write(companion)
          .then((_) => alarm.id!);
    }
    return _db.into(_db.alarms).insert(companion);
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.alarms)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleActive(int id, {required bool active}) {
    return (_db.update(_db.alarms)..where((t) => t.id.equals(id))).write(
      db.AlarmsCompanion(
        active: Value(active),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  AlarmData _rowToAlarm(db.Alarm row) {
    return AlarmData(
      id: row.id,
      name: row.name,
      location: LatLng(row.latitude, row.longitude),
      active: row.active,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      radius: row.radius ?? 500,
      locationName: row.locationName,
    );
  }

  db.AlarmsCompanion _alarmToCompanion(AlarmData alarm) {
    final now = DateTime.now();
    return db.AlarmsCompanion(
      id: alarm.id != null ? Value(alarm.id!) : const Value.absent(),
      createdAt: alarm.id != null ? const Value.absent() : Value(now),
      updatedAt: Value(now),
      name: Value(alarm.name),
      latitude: Value(alarm.location.latitude),
      longitude: Value(alarm.location.longitude),
      active: Value(alarm.active),
      radius: Value(alarm.radius),
      locationName: Value(alarm.locationName),
    );
  }
}
