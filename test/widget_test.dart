import 'package:flutter_test/flutter_test.dart';
import 'package:location_alarm/main.dart';

void main() {
  testWidgets('app renders', (tester) async {
    await tester.pumpWidget(const LocationAlarmApp());
    expect(find.text('Location Alarm'), findsWidgets);
  });
}
