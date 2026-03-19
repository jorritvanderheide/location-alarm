import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:location_alarm/shared/data/database/app_database.dart';

AppDatabase openDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'location_alarm.db'));
      return NativeDatabase.createInBackground(file);
    }),
  );
}
