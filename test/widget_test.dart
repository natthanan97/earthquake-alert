import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earthquake_alert/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EarthquakeApp()),
    );
    expect(find.text('Earthquake Alert'), findsNothing); // title is in MaterialApp, not rendered directly
  });
}
