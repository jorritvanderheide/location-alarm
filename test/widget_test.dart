import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/app.dart';

void main() {
  testWidgets('app renders with navigation', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LocationAlarmApp()));
    await tester.pumpAndSettle();
    expect(find.text('Proximity'), findsOneWidget);
    expect(find.text('Departure'), findsOneWidget);
  });
}
