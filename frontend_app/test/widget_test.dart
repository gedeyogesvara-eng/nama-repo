import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';

void main() {
  testWidgets('App smoke test - Welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DepressionDetectionApp());
    await tester.pumpAndSettle();

    expect(find.text('AI HEALTH MONITORING'), findsOneWidget);
  });
}
