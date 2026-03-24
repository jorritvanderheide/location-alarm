import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/features/alarm_map/providers/alarm_form_provider.dart';
import 'package:there_yet/shared/data/database/app_database.dart';
import 'package:there_yet/shared/data/models/alarm.dart';
import 'package:there_yet/shared/providers/alarm_repository_provider.dart';
import 'package:there_yet/shared/providers/database_provider.dart';

void main() {
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

  group('AlarmFormProvider (new alarm)', () {
    test('starts with default state', () {
      final state = container.read(alarmFormProvider(null));
      expect(state.isLoaded, true);
      expect(state.isNew, true);
      expect(state.location, isNull);
      expect(state.radius, 500);
      expect(state.name, '');
      expect(state.hasUnsavedChanges, false);
      expect(state.canSave, false);
    });

    test('setLocation marks as changed', () {
      final notifier = container.read(alarmFormProvider(null).notifier);
      notifier.setLocation(const LatLng(51.0, 5.0));

      final state = container.read(alarmFormProvider(null));
      expect(state.location, const LatLng(51.0, 5.0));
      expect(state.hasUnsavedChanges, true);
      expect(state.canSave, true);
    });

    test('setRadius marks as changed', () {
      final notifier = container.read(alarmFormProvider(null).notifier);
      notifier.setLocation(const LatLng(51.0, 5.0));
      notifier.setRadius(1000);

      final state = container.read(alarmFormProvider(null));
      expect(state.radius, 1000);
      expect(state.hasUnsavedChanges, true);
    });

    test('setName marks as changed', () {
      final notifier = container.read(alarmFormProvider(null).notifier);
      notifier.setLocation(const LatLng(51.0, 5.0));
      notifier.setName('Test alarm');

      final state = container.read(alarmFormProvider(null));
      expect(state.name, 'Test alarm');
      expect(state.hasUnsavedChanges, true);
    });

    test('canSave is false without location', () {
      final notifier = container.read(alarmFormProvider(null).notifier);
      notifier.setName('Test');
      notifier.setRadius(1000);

      final state = container.read(alarmFormProvider(null));
      expect(state.canSave, false);
    });

    test('markSaved resets dirty tracking', () {
      final notifier = container.read(alarmFormProvider(null).notifier);
      notifier.setLocation(const LatLng(51.0, 5.0));
      notifier.setName('Saved');
      expect(container.read(alarmFormProvider(null)).hasUnsavedChanges, true);

      notifier.markSaved();
      expect(container.read(alarmFormProvider(null)).hasUnsavedChanges, false);
    });
  });

  group('AlarmFormProvider (edit alarm)', () {
    test('loads alarm from database', () async {
      final repo = container.read(alarmRepositoryProvider);
      final id = await repo.save(
        const AlarmData(
          name: 'Loaded',
          location: LatLng(52.0, 6.0),
          active: true,
          radius: 750,
          locationName: 'Test City',
        ),
      );

      // Reading the provider with the alarm ID triggers build() which loads.
      container.read(alarmFormProvider(id));
      // Give the async load time to complete.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(alarmFormProvider(id));
      expect(state.isLoaded, true);
      expect(state.isNew, false);
      expect(state.name, 'Loaded');
      expect(state.location, const LatLng(52.0, 6.0));
      expect(state.radius, 750);
      expect(state.hasUnsavedChanges, false);
    });

    test('sets loadError for non-existent ID', () async {
      container.read(alarmFormProvider(999));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(alarmFormProvider(999));
      expect(state.loadError, true);
      expect(state.isLoaded, false);
    });
  });
}
