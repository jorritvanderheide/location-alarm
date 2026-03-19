import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/app.dart';
import 'package:location_alarm/shared/data/database/connection.dart';
import 'package:location_alarm/shared/providers/database_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = openDatabase();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const LocationAlarmApp(),
    ),
  );
}
