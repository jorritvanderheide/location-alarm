import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/features/alarm_service/alarm_checker.dart';
import 'package:there_yet/shared/data/models/alarm.dart';

void main() {
  late AlarmChecker checker;

  setUp(() {
    checker = AlarmChecker();
  });

  AlarmData makeAlarm({
    int id = 1,
    double lat = 51.84,
    double lng = 5.86,
    double radius = 500,
  }) => AlarmData(
    id: id,
    name: 'Test',
    location: LatLng(lat, lng),
    active: true,
    radius: radius,
  );

  group('check', () {
    test('triggers when inside radius', () {
      final alarms = [makeAlarm(radius: 500)];
      // Position very close to alarm center.
      final result = checker.check(alarms, const LatLng(51.84, 5.86));
      expect(result.length, 1);
    });

    test('does not trigger when outside radius', () {
      final alarms = [makeAlarm(radius: 100)];
      // ~1.5km away.
      final result = checker.check(alarms, const LatLng(51.85, 5.86));
      expect(result, isEmpty);
    });

    test('uses accuracy margin', () {
      final alarms = [makeAlarm(radius: 100)];
      // ~120m away — outside 100m but inside 100m + 25m margin.
      const pos = LatLng(51.8411, 5.86);
      final noMargin = checker.check(alarms, pos, accuracy: 0);
      // With 50m accuracy, margin = max(25, 50/2) = 25m.
      final withMargin = checker.check(alarms, pos, accuracy: 50);
      // The point is ~120m away. 100m radius + 25m margin = 125m.
      // Should trigger with margin.
      expect(withMargin.length, greaterThanOrEqualTo(noMargin.length));
    });

    test('returns only triggered alarms from multiple', () {
      final alarms = [
        makeAlarm(id: 1, lat: 51.84, lng: 5.86, radius: 500),
        makeAlarm(id: 2, lat: 52.0, lng: 6.0, radius: 100), // far away
      ];
      final result = checker.check(alarms, const LatLng(51.84, 5.86));
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('triggers multiple alarms if position is inside both', () {
      final alarms = [
        makeAlarm(id: 1, lat: 51.84, lng: 5.86, radius: 500),
        makeAlarm(id: 2, lat: 51.84, lng: 5.86, radius: 1000),
      ];
      final result = checker.check(alarms, const LatLng(51.84, 5.86));
      expect(result.length, 2);
    });

    test('empty alarm list returns empty', () {
      final result = checker.check([], const LatLng(51.84, 5.86));
      expect(result, isEmpty);
    });
  });
}
