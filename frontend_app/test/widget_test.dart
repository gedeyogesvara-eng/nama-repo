import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> da0e86a6b9b4d28cbbbb7d93e01b295eae945c05
import 'package:frontend_app/main.dart';
import 'package:frontend_app/services/ai_service.dart';

void main() {
<<<<<<< HEAD
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test loads successfully and handles splash delay', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DepressionDetectionApp());
    expect(find.byType(DepressionDetectionApp), findsOneWidget);

    // Majukan waktu timer splash screen (1800 ms) agar timer selesai
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
  });

  test('AIService defaultEndpoint resolves to local IPv4 for mobile', () {
    expect(AIService.localIPv4, isNotEmpty);
    expect(AIService.defaultEndpoint, contains(':5000/api/detect'));
    expect(
      AIService.defaultEndpoint,
      equals('http://${AIService.localIPv4}:5000/api/detect'),
    );
=======
  testWidgets('App smoke test - Welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DepressionDetectionApp());
    await tester.pumpAndSettle();

    expect(find.text('AI HEALTH MONITORING'), findsOneWidget);
>>>>>>> da0e86a6b9b4d28cbbbb7d93e01b295eae945c05
  });
}
