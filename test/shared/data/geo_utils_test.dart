import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_alarm/shared/data/geo_utils.dart';

void main() {
  group('distanceInMeters', () {
    test('returns 0 for same point', () {
      final d = distanceInMeters(
        const LatLng(51.0, 5.0),
        const LatLng(51.0, 5.0),
      );
      expect(d, 0.0);
    });

    test('returns reasonable distance for known points', () {
      // Amsterdam to Utrecht is ~35km.
      final d = distanceInMeters(
        const LatLng(52.3676, 4.9041), // Amsterdam
        const LatLng(52.0907, 5.1214), // Utrecht
      );
      expect(d, greaterThan(30000));
      expect(d, lessThan(40000));
    });
  });

  group('formatDistance', () {
    test('formats meters below 1000', () {
      expect(formatDistance(500), '500 m');
      expect(formatDistance(100), '100 m');
      expect(formatDistance(999), '999 m');
    });

    test('formats kilometers', () {
      expect(formatDistance(1000), '1 km');
      expect(formatDistance(1500), '1.5 km');
      expect(formatDistance(2000), '2 km');
      expect(formatDistance(5000), '5 km');
    });

    test('rounds meters', () {
      expect(formatDistance(123.7), '124 m');
    });

    test('formats fractional km to one decimal', () {
      expect(formatDistance(1234), '1.2 km');
      expect(formatDistance(2750), '2.8 km');
    });
  });
}
