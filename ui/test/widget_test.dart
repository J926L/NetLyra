import 'package:flutter_test/flutter_test.dart';
import 'package:netlyra_ui/main.dart';

void main() {
  testWidgets('Dashboard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NetLyraApp());

    // Verify NetLyra title is present
    expect(find.text('NETLYRA'), findsOneWidget);

    // Verify stat labels are present
    expect(find.text('PACKETS'), findsOneWidget);
    expect(find.text('ALERTS'), findsOneWidget);
    expect(find.text('CONNECTIONS'), findsOneWidget);
  });
}
