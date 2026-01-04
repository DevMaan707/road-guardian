import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:road_guardian_pro/main.dart';

void main() {
  testWidgets('Road Guardian Pro app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RoadGuardianApp(),
      ),
    );

    // Verify app loads with Safety Score label
    expect(find.text('SAFETY SCORE'), findsOneWidget);
    expect(find.text('LIVE / HYDERABAD'), findsOneWidget);
  });
}
