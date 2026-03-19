import 'package:drift/drift.dart';
import 'package:location_alarm/shared/data/models/alarm_mode.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

part 'app_database.g.dart';

// Do not reorder enum members — ordinal values are stored in the database.

class Alarms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get mode => intEnum<AlarmMode>()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  RealColumn get radius => real().nullable()();
  IntColumn get travelMode => intEnum<TravelMode>().nullable()();
  IntColumn get bufferMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Alarms])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
