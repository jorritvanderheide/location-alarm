import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Alarms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  RealColumn get radius => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Alarms])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // v2 originally added arrival_time column.
        await customStatement(
          'ALTER TABLE alarms ADD COLUMN arrival_time INTEGER',
        );
      }
      if (from < 3) {
        await migrator.addColumn(alarms, alarms.updatedAt);
      }
      // v4: removed departure columns (mode, travelMode, bufferMinutes,
      // arrivalTime) from the Drift schema. SQLite keeps them in the table
      // but we no longer read or write them. No migration action needed.
    },
  );
}
